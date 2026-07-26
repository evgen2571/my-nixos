{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.system.services.vpnbookWireguardFailover;

  vpnbook-wg = pkgs.writeShellApplication {
    name = "vpnbook-wg";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      findutils
      gnugrep
      iproute2
      wireguard-tools
    ];
    text = ''
      set -euo pipefail

      config_dir="${cfg.configDir}"
      state_dir="${cfg.stateDir}"
      runtime_dir="/run/vpnbook-wireguard"
      interface="${cfg.interfaceName}"
      active_link="$state_dir/active.conf"
      runtime_config="$runtime_dir/$interface.conf"
      check_url="${cfg.checkUrl}"
      connect_timeout="${toString cfg.connectTimeoutSeconds}"
      max_time="${toString cfg.checkMaxTimeSeconds}"

      mkdir -p "$state_dir" "$runtime_dir"
      chmod 700 "$state_dir" "$runtime_dir"

      configs() {
        ${pkgs.findutils}/bin/find "$config_dir" -maxdepth 1 -type f -name '*.conf' | sort
      }

      is_usable_config() {
        local file="$1"
        grep -q '^\[Interface\]' "$file" && grep -q '^\[Peer\]' "$file"
      }

      is_online() {
        curl --interface "$interface" \
          --connect-timeout "$connect_timeout" \
          --max-time "$max_time" \
          --silent \
          --show-error \
          --fail \
          --output /dev/null \
          "$check_url"
      }

      current_config=""
      if [ -L "$active_link" ] || [ -f "$active_link" ]; then
        current_config="$(readlink -f "$active_link" || true)"
      fi

      up_config() {
        local source_config="$1"
        if ! is_usable_config "$source_config"; then
          echo "Skipping unusable WireGuard config: $source_config" >&2
          return 1
        fi

        if ip link show "$interface" >/dev/null 2>&1; then
          wg-quick down "$runtime_config" >/dev/null 2>&1 || true
        fi

        install -m 600 "$source_config" "$runtime_config"
        ln -sfn "$source_config" "$active_link"
        wg-quick up "$runtime_config"
      }

      pick_first_config() {
        local first=""
        first="$(configs | head -n 1 || true)"
        if [ -z "$first" ]; then
          echo "No WireGuard configs found in $config_dir" >&2
          exit 1
        fi
        up_config "$first"
      }

      switch_config() {
        local next=""
        local after_current=false

        while IFS= read -r candidate; do
          [ -n "$candidate" ] || continue
          if [ -z "$current_config" ]; then
            next="$candidate"
            break
          fi
          if [ "$after_current" = true ]; then
            next="$candidate"
            break
          fi
          if [ "$(readlink -f "$candidate")" = "$current_config" ]; then
            after_current=true
          fi
        done < <(configs)

        if [ -z "$next" ]; then
          next="$(configs | head -n 1 || true)"
        fi

        if [ -z "$next" ]; then
          echo "No WireGuard configs found in $config_dir" >&2
          exit 1
        fi

        echo "Switching VPNBook WireGuard config to: $next"
        up_config "$next"
      }

      command="''${1:-check}"
      case "$command" in
        start)
          if [ -n "$current_config" ] && [ -f "$current_config" ]; then
            up_config "$current_config"
          else
            pick_first_config
          fi
          ;;
        check)
          if ! ip link show "$interface" >/dev/null 2>&1; then
            echo "WireGuard interface $interface is down; starting VPN"
            if [ -n "$current_config" ] && [ -f "$current_config" ]; then
              up_config "$current_config"
            else
              pick_first_config
            fi
          fi

          if is_online; then
            echo "VPNBook WireGuard check passed on $interface"
            exit 0
          fi

          echo "VPNBook WireGuard check failed; trying next config"
          switch_config
          if is_online; then
            echo "VPNBook WireGuard recovered on $interface"
            exit 0
          fi

          echo "VPNBook WireGuard still failed after switching" >&2
          exit 1
          ;;
        switch)
          switch_config
          ;;
        stop)
          if ip link show "$interface" >/dev/null 2>&1; then
            wg-quick down "$runtime_config" || true
          fi
          ;;
        status)
          if ip link show "$interface" >/dev/null 2>&1; then
            wg show "$interface" || true
          else
            echo "Interface $interface is down"
            exit 1
          fi
          if [ -e "$active_link" ]; then
            echo "Active config: $(readlink -f "$active_link")"
          fi
          ;;
        *)
          echo "Usage: vpnbook-wg {start|check|switch|stop|status}" >&2
          exit 2
          ;;
      esac
    '';
  };
in
{
  options.my.system.services.vpnbookWireguardFailover = {
    enable = lib.mkEnableOption "VPNBook WireGuard client with simple failover";

    configDir = lib.mkOption {
      type = lib.types.str;
      default = "/etc/wireguard/vpnbook";
      description = "Directory containing VPNBook WireGuard .conf files. Do not store these secrets in Git.";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/vpnbook-wireguard";
      description = "Directory used to remember the active VPNBook config.";
    };

    interfaceName = lib.mkOption {
      type = lib.types.str;
      default = "vpnbook0";
      description = "Runtime WireGuard interface name used by wg-quick.";
    };

    checkUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://1.1.1.1/cdn-cgi/trace";
      description = "URL checked through the WireGuard interface to decide whether failover is needed.";
    };

    checkInterval = lib.mkOption {
      type = lib.types.str;
      default = "1min";
      description = "systemd timer interval for health checks.";
    };

    connectTimeoutSeconds = lib.mkOption {
      type = lib.types.int;
      default = 5;
      description = "curl connect timeout used by health checks.";
    };

    checkMaxTimeSeconds = lib.mkOption {
      type = lib.types.int;
      default = 15;
      description = "curl max time used by health checks.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ vpnbook-wg ];

    networking.firewall.checkReversePath = "loose";

    systemd.tmpfiles.rules = [
      "d ${cfg.configDir} 0700 root root -"
      "d ${cfg.stateDir} 0700 root root -"
    ];

    systemd.services.vpnbook-wireguard = {
      description = "VPNBook WireGuard client with failover";
      after = [
        "network-online.target"
        "tailscaled.service"
      ];
      wants = [
        "network-online.target"
        "tailscaled.service"
      ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${lib.getExe vpnbook-wg} start";
        ExecStop = "${lib.getExe vpnbook-wg} stop";
      };
    };

    systemd.services.vpnbook-wireguard-check = {
      description = "Check VPNBook WireGuard and fail over if needed";
      after = [ "vpnbook-wireguard.service" ];
      wants = [ "vpnbook-wireguard.service" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe vpnbook-wg} check";
      };
    };

    systemd.timers.vpnbook-wireguard-check = {
      description = "Periodic VPNBook WireGuard health check";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "30s";
        OnUnitActiveSec = cfg.checkInterval;
        Unit = "vpnbook-wireguard-check.service";
      };
    };
  };
}
