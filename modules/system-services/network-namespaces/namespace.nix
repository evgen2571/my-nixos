{
  config,
  lib,
  pkgs,
  name,
  ns,
}:
let
  doctor = import ./doctor.nix {
    inherit
      config
      lib
      pkgs
      name
      ns
      ;
  };
  shared = ns.shared.role != "standalone";
  isClient = ns.shared.role == "client";
  runtime = "/run/network-namespaces/${name}";
  state = "/var/lib/hide-me-${name}";
  netns = "netns-${name}";
  underlay = "${netns}-underlay";
  vpn = "hide-me-${name}";
  client = pkgs.callPackage ../../../packages/hide-me { };
  tools = with pkgs; [
    coreutils
    gnugrep
    gnused
    gawk
    iproute2
    nftables
    wireguard-tools
    systemd
  ];
  policy = pkgs.writeText "${netns}-firewall.nft" ''
    table inet agent_workspace {
      chain output {
        type filter hook output priority 0; policy drop;
        oifname "lo" accept
        ${lib.optionalString (!isClient) ''oifname "hm0" accept''}
        ${lib.optionalString shared ''oifname "shared0" accept''}
        ${lib.optionalString (
          !isClient
        ) ''oifname "tap0" meta mark 0x486d meta l4proto { tcp, udp } accept''}
        counter drop
      }
      chain input {
        type filter hook input priority 0; policy drop;
        iifname "lo" accept
        ${lib.optionalString (ns.shared.role == "gateway") ''
          iifname "shared0" tcp dport 53 accept
                  iifname "shared0" udp dport 53 accept''}
        ct state established,related accept
      }
      chain forward {
        type filter hook forward priority 0; policy drop;
        ${lib.optionalString (ns.shared.role == "gateway") ''
          iifname "shared0" oifname "hm0" accept
                  iifname "hm0" oifname "shared0" ct state established,related accept''}
      }
    }
    ${lib.optionalString (ns.shared.role == "gateway") ''
      table inet shared_vpn_nat {
        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;
          oifname "hm0" masquerade
        }
      }
    ''}
  '';
  init = pkgs.writeShellApplication {
    name = "${netns}-init";
    runtimeInputs = tools;
    text = ''
      install -d -m 0755 /run/netns /run/network-namespaces ${runtime} ${runtime}/empty-nscd
      # Adopt an existing namespace, including one retained by active sessions.
      if ! ip netns list | grep -q '^${name}\( \|$\)'; then
        ip netns add ${name}
      fi
      ip -n ${name} link set lo up
      if [[ ! -f ${runtime}/resolv.conf ]]; then
        printf 'nameserver 127.0.0.1\noptions timeout:1 attempts:1\n' > ${runtime}/resolv.conf
        chmod 0644 ${runtime}/resolv.conf
      fi
      sed 's/^hosts:.*/hosts: files dns/' /etc/nsswitch.conf > ${runtime}/nsswitch.conf
      chmod 0644 ${runtime}/nsswitch.conf
      # Flush and repopulate in ONE nft transaction; no open-filter interval.
      if ip netns exec ${name} nft list table inet agent_workspace >/dev/null 2>&1; then
        { echo 'flush table inet agent_workspace'; ${
          lib.optionalString (ns.shared.role == "gateway")
            "if ip netns exec ${name} nft list table inet shared_vpn_nat >/dev/null 2>&1; then echo 'flush table inet shared_vpn_nat'; fi;"
        } cat ${policy}; } |
          ip netns exec ${name} nft -f -
      else
        ip netns exec ${name} nft -f ${policy}
      fi
    '';
  };
  cleanup = pkgs.writeShellApplication {
    name = "${netns}-cleanup";
    runtimeInputs = tools;
    text = ''
      rm -f ${runtime}/ready
      if ip netns list | grep -q '^${name}\( \|$\)'; then
        # Deleting the name does not kill processes holding the old namespace.
        # They retain its fail-closed filter until their final process exits.
        ip netns delete ${name}
      fi
      rm -rf ${runtime}
    '';
  };
  waitUnderlay = pkgs.writeShellApplication {
    name = "${netns}-wait-underlay";
    runtimeInputs = tools;
    text = ''
      for ((attempt=0; attempt<100; attempt++)); do
        if ip -n ${name} -4 route show default | grep -q 'via 10.0.2.2 dev tap0'; then
          exit 0
        fi
        sleep 0.1
      done
      echo 'Namespace underlay did not become ready' >&2
      exit 1
    '';
  };
  prepare = pkgs.writeShellApplication {
    name = "${vpn}-prepare";
    runtimeInputs = tools;
    text = ''
      rm -f ${runtime}/ready
      # Recover from SIGKILL, which cannot unwind upstream's routes/rules.
      # This only touches the dedicated namespace; independent nft stays active.
      ip link delete hm0 2>/dev/null || true
      for family in -4 -6; do
        while ip "$family" rule show | grep -q '^10:.*lookup 55555'; do
          ip "$family" rule delete priority 10 table 55555
        done
        ip "$family" route flush table 55555 2>/dev/null || true
      done
      printf 'nameserver 127.0.0.1\noptions timeout:1 attempts:1\n' > ${runtime}/resolv.conf
      ${lib.optionalString (ns.bootstrapTokenFile != null) ''
        if [[ ! -s ${lib.escapeShellArg ns.bootstrapTokenFile} ]]; then
          echo 'Provision a nonempty Hide.me bootstrap token in SOPS before starting the gateway.' >&2
          exit 1
        fi
        digest=$(sha256sum ${lib.escapeShellArg ns.bootstrapTokenFile} | cut -d ' ' -f 1)
        if [[ ! -s ${state}/bootstrap-digest || "$(cat ${state}/bootstrap-digest)" != "$digest" ]]; then
          install -m 0600 ${lib.escapeShellArg ns.bootstrapTokenFile} ${state}/accessToken.new
          mv ${state}/accessToken.new ${state}/accessToken.txt
          printf '%s\n' "$digest" > ${state}/bootstrap-digest
        fi
      ''}
      if [[ ! -s ${state}/accessToken.txt || -L ${state}/accessToken.txt ]]; then
        echo 'No hide.me access token. Run the documented private bootstrap procedure.' >&2
        exit 1
      fi
      chmod 0600 ${state}/accessToken.txt
    '';
  };
  localCheck = pkgs.writeShellApplication {
    name = "${netns}-local-check";
    runtimeInputs = tools;
    text = ''
      reject() { echo "VPN local readiness: $1" >&2; exit 1; }
      systemctl is-active --quiet ${
        if isClient then "netns-${name}-shared" else vpn
      }.service || reject SERVICE_UNAVAILABLE
      for chain in output input forward; do
        ip netns exec ${name} nft list chain inet agent_workspace "$chain" | grep -q 'policy drop;' || reject FIREWALL_ERROR
      done
      ip -n ${name} -4 route get 1.1.1.1 | grep -q 'dev ${
        if isClient then "shared0" else "hm0"
      }' || reject IPV4_ROUTE_ERROR
      ip -n ${name} -6 route get 2606:4700:4700::1111 | grep -q 'dev ${
        if isClient then "shared0" else "hm0"
      }' || reject IPV6_ROUTE_ERROR
      ip netns exec ${name} wg show ${if isClient then "shared0" else "hm0"} latest-handshakes |
        awk -v now="$(date +%s)" '$2 > 0 && now >= $2 && now - $2 < 180 { ok = 1 } END { exit !ok }' || reject WG_HANDSHAKE_STALE
      awk '$1 == "nameserver" && $2 != "127.0.0.1" && $2 != "::1" { ok = 1 } END { exit !ok }' ${runtime}/resolv.conf || reject DNS_UNAVAILABLE
    '';
  };
  # Agent entry requires both local tunnel readiness and a recent HTTPS probe.
  # The network probe runs on the timer, never per Codex invocation.
  check = pkgs.writeShellApplication {
    name = "${netns}-check";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      diagnose() {
        ${lib.optionalString shared "${lib.getExe doctor.status} --entry-failed >&2"}
        exit 1
      }
      ${lib.getExe localCheck} || diagnose
      [[ -s ${runtime}/ready ]] || diagnose
      read -r checkedAt < ${runtime}/ready || diagnose
      [[ "$checkedAt" =~ ^[0-9]+$ ]] || diagnose
      now=$(date +%s)
      (( now >= checkedAt && now - checkedAt <= 90 )) || diagnose
    '';
  };

in
{
  systemd.services.${netns} = {
    description = "Persistent isolated network namespace ${name}";
    wantedBy = [ "multi-user.target" ];
    before = [
      "${underlay}.service"
      "${vpn}.service"
    ];
    # Changing a package elsewhere must not destroy active app namespaces.
    restartIfChanged = shared;
    stopIfChanged = shared;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = lib.getExe init;
      ExecStop = lib.getExe cleanup;
      # ip netns must publish its bind mount into the host mount namespace.
      # Do not add PrivateTmp/ProtectSystem here: they create private mounts.
      CapabilityBoundingSet = [
        "CAP_SYS_ADMIN"
        "CAP_NET_ADMIN"
      ];
      NoNewPrivileges = true;
    };
  };

  systemd.services.${underlay} = lib.mkIf (!isClient) {
    description = "Restricted userspace underlay for ${name}";
    unitConfig = {
      StartLimitIntervalSec = 300;
      StartLimitBurst = 3;
    };
    wantedBy = [ "multi-user.target" ];
    requires = [ "${netns}.service" ];
    after = [
      "${netns}.service"
      "network-online.target"
    ];
    wants = [ "network-online.target" ];
    bindsTo = [ "${netns}.service" ];
    partOf = [ "${netns}.service" ];
    restartIfChanged = false;
    stopIfChanged = false;
    serviceConfig = {
      Type = "exec";
      ExecStart = "${lib.getExe pkgs.slirp4netns} --configure --disable-host-loopback --disable-dns --enable-seccomp --netns-type=path /run/netns/${name} tap0";
      ExecStartPost = lib.getExe waitUnderlay;
      # Closing the nonpersistent TAP may already have removed the interface.
      ExecStopPost = "-${pkgs.iproute2}/bin/ip -n ${name} link delete tap0";
      Restart = "always";
      RestartSec = 3;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
      InaccessiblePaths = [
        "-/run/secrets"
        "-/etc/shadow"
        "-/etc/ssh"
      ];
    };
  };

  systemd.services.${vpn} = lib.mkIf (!isClient) {
    description = "hide.me Free VPN in namespace ${name}";
    wantedBy = [ "multi-user.target" ];
    # Keep the provider alive through underlay process restarts; its gate waits
    # for tap0 at startup, and the monitor repairs failed prerequisites.
    requires = lib.optional (!shared) "${underlay}.service";
    wants = lib.optional shared "${underlay}.service";
    after = [ "${underlay}.service" ] ++ lib.optional (config ? sops) "sops-install-secrets.service";
    bindsTo = [ "${netns}.service" ];
    partOf = [ "${netns}.service" ];
    unitConfig = {
      StartLimitIntervalSec = 300;
      StartLimitBurst = 3;
    };
    # Underlay restart should not force namespace teardown. The client's DPD
    # handles short outages and retries; systemd handles a crashed client.
    serviceConfig = {
      Type = "notify";
      NotifyAccess = "main";
      User = "root";
      Group = "root";
      StateDirectory = vpn;
      StateDirectoryMode = "0700";
      WorkingDirectory = state;
      UMask = "0077";
      ExecCondition = lib.optional shared doctor.gate;
      ExecStartPre = lib.getExe prepare;
      ExecStart = "${client}/bin/hide.me --firewall-mark 18541 --interface hm0 --tokenFile ${state}/accessToken.txt --kill-switch=true connect ${ns.server}";
      ExecStopPost = "${pkgs.coreutils}/bin/rm -f ${runtime}/ready";
      NetworkNamespacePath = "/run/netns/${name}";
      BindPaths = [ "${runtime}/resolv.conf:/etc/resolv.conf" ];
      BindReadOnlyPaths = [ "${runtime}/nsswitch.conf:/etc/nsswitch.conf" ];
      InaccessiblePaths = [ "-/run/nscd" ];
      ProtectSystem = "strict";
      ReadWritePaths = [
        state
        runtime
      ];
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
      CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
      TimeoutStartSec = 120;
      TimeoutStopSec = 30;
      Restart = "always";
      RestartSec = 10;
    };
  };

  systemd.services."${netns}-health" = {
    description = "Verify external HTTPS egress through VPN ${name}";
    after = [ "${if isClient then "netns-${name}-shared" else vpn}.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = doctor.probe;
      NetworkNamespacePath = "/run/netns/${name}";
      BindReadOnlyPaths = [
        "${runtime}/resolv.conf:/etc/resolv.conf"
        "${runtime}/nsswitch.conf:/etc/nsswitch.conf"
      ];
      InaccessiblePaths = [ "-/run/nscd" ];
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      ReadWritePaths = [ runtime ];
      NoNewPrivileges = true;
      CapabilityBoundingSet = [ ];
      TimeoutStartSec = 60;
    };
  };
  systemd.timers."${netns}-health" = {
    wantedBy = lib.optional (!shared) "timers.target";
    timerConfig = {
      OnBootSec = 15;
      OnUnitActiveSec = 30;
      AccuracySec = 1;
    };
  };
  systemd.services."${netns}-recovery" = lib.mkIf shared {
    description = "Diagnose and cautiously recover VPN ${name}";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = doctor.reconcile;
      StateDirectory = "network-namespaces-${name}";
      StateDirectoryMode = "0755";
      UMask = "0022";
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
      ReadWritePaths = [ "-${runtime}" ];
      TimeoutStartSec = 240;
    };
  };
  systemd.timers."${netns}-recovery" = lib.mkIf shared {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = 15;
      OnUnitInactiveSec = 30;
      AccuracySec = 1;
    };
  };
  environment.systemPackages = lib.optional shared doctor.status;
  environment.etc."network-namespaces/${name}-recovery-reset" = lib.mkIf shared {
    source = doctor.reset;
  };
  # Used by the restricted entry helper; never a user-selectable command path.
  environment.etc."network-namespaces/${name}-check".source = lib.getExe check;
}
