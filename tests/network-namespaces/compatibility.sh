#!/usr/bin/env bash
# Native Linux compatibility gate. No sudo, host routes/firewall/DNS changes,
# credentials, or persistent namespaces. Supply Nix-built client/tools paths.
set -euo pipefail
if [[ ${1:-} == --inside ]]; then
  probe_dir=$2
  client=$3
  export PATH="$4/bin:$PATH"
  token_file=${5:-}
  server=${6:-free-nl}
  mount --make-rprivate /
  printf 'nameserver 127.0.0.1\noptions timeout:1 attempts:1\n' > "$probe_dir/resolv.conf"
  mount --bind "$probe_dir/resolv.conf" /etc/resolv.conf
  # Resolver configuration alone does not isolate host NSS/cache IPC.
  sed 's/^hosts:.*/hosts: files dns/' /etc/nsswitch.conf > "$probe_dir/nsswitch.conf"
  mount --bind "$probe_dir/nsswitch.conf" /etc/nsswitch.conf
  mkdir "$probe_dir/empty-nscd"
  if [[ -d /run/nscd ]]; then
    mount --bind "$probe_dir/empty-nscd" /run/nscd
  fi
  echo "$$" > "$probe_dir/pid"
  for ((i=0; i<100; i++)); do
    [[ -s $probe_dir/ready ]] && break
    sleep 0.1
  done
  [[ -s $probe_dir/ready ]]
  # Give IPv6 a route too: absence of an IPv6 default must not be the only guard.
  ip -6 address add fd00::100/64 dev tap0 nodad
  ip -6 route add default dev tap0
  nft -f - <<'NFT'
table inet hide_me_probe {
  chain output {
    type filter hook output priority 0; policy drop;
    oifname "lo" accept
    oifname "hm0" accept
    oifname "tap0" meta mark 0x486d meta l4proto { tcp, udp } accept
    counter drop
  }
  chain input {
    type filter hook input priority 0; policy drop;
    iifname "lo" accept
    ct state established,related accept
  }
}
NFT
  # Root only inside this user namespace. Drop every capability for app probes.
  blocked() {
    if setpriv --bounding-set=-all --inh-caps=-all --ambient-caps=-all \
      --no-new-privs curl --noproxy '*' --silent --show-error \
      --connect-timeout 2 --max-time 3 "$1"; then
      echo "FAIL: ordinary traffic escaped: $1" >&2
      exit 1
    fi
    echo "PASS: ordinary traffic blocked: $1"
  }
  ip -brief address
  ip route
  blocked http://1.1.1.1
  blocked 'http://[2606:4700:4700::1111]'
  # The client itself must create a WireGuard interface on this kernel. It
  # currently exits zero even on failure, so inspect diagnostics and link state.
  "$client/bin/hide.me" --firewall-mark 18541 --interface hm0 \
    --tokenFile "$probe_dir/missing-token" connect free-nl.hideservers.net \
    > "$probe_dir/missing-token.log" 2>&1
  cat "$probe_dir/missing-token.log"
  grep -q 'no Access-Token' "$probe_dir/missing-token.log"
  grep -q 'Wireguard device hm0 configured' "$probe_dir/missing-token.log"
  # Upstream cleans up its interface after initialization fails.
  if ip link show hm0 >/dev/null 2>&1; then
    echo 'FAIL: client left its interface behind after failed initialization' >&2
    exit 1
  fi
  blocked http://1.1.1.1
  echo 'PASS: WireGuard creation and missing-token isolation'
  "$client/bin/hide.me" --firewall-mark 18541 --rest-timeout 25s list free \
    > "$probe_dir/servers.log" 2>&1
  cat "$probe_dir/servers.log"
  grep -Eq '\|.*\|.*free' "$probe_dir/servers.log"
  echo 'PASS: Free server discovery through marked underlay'
  # Deliberately fake, non-secret credential. Never use the real token for an
  # arbitrary endpoint. Upstream connect retries, so bound each failure test.
  printf 'aW52YWxpZA==' > "$probe_dir/invalid-token"
  for endpoint in "$server" 192.0.2.1; do
    result=0
    timeout --signal=TERM --kill-after=3 8 \
      "$client/bin/hide.me" --firewall-mark 18541 --interface hm0 \
      --tokenFile "$probe_dir/invalid-token" --rest-timeout 3s connect "$endpoint" \
      > "$probe_dir/invalid.log" 2>&1 || result=$?
    cat "$probe_dir/invalid.log"
    [[ $result == 124 || $result == 0 ]]
    if [[ $endpoint == 192.0.2.1 ]]; then
      grep -q 'REST failed: context deadline exceeded' "$probe_dir/invalid.log"
    else
      grep -q 'REST failed: bad HTTP status 401' "$probe_dir/invalid.log"
    fi
    blocked http://1.1.1.1
    blocked 'http://[2606:4700:4700::1111]'
    echo "PASS: failed connection to $endpoint has no underlay fallback"
  done
  if [[ -n $token_file ]]; then
    vpn_pid=
    # shellcheck disable=SC2329 # Called by the EXIT trap in this live-test branch.
    stop_vpn() {
      [[ -z $vpn_pid ]] || kill "$vpn_pid" 2>/dev/null || true
      [[ -z $vpn_pid ]] || wait "$vpn_pid" 2>/dev/null || true
      vpn_pid=
    }
    trap stop_vpn EXIT
    start_vpn() {
      "$client/bin/hide.me" --firewall-mark 18541 --interface hm0 \
        --tokenFile "$token_file" --rest-timeout 25s connect "$server" \
        > "$probe_dir/connect.log" 2>&1 &
      vpn_pid=$!
      connected=false
      for ((i=0; i<60; i++)); do
        kill -0 "$vpn_pid" || break
        if grep -q '^Link: Up' "$probe_dir/connect.log"; then
          connected=true
          break
        fi
        sleep 1
      done
      cat "$probe_dir/connect.log"
      [[ $connected == true ]]
    }
    start_vpn
    ip route show table 55555
    ip -6 route show table 55555
    ip rule
    ip -6 rule
    cat /etc/resolv.conf
    app() {
      setpriv --bounding-set=-all --inh-caps=-all --ambient-caps=-all \
        --no-new-privs "$@"
    }
    vpn_ip=$(app curl --noproxy '*' -4fsS --max-time 15 https://api.ipify.org)
    echo "VPN IPv4: $vpn_ip"
    [[ $vpn_ip != "$(cat "$probe_dir/host-ip")" ]]
    echo 'PASS: ordinary IPv4 and DNS use the tunnel; egress differs from host'
    if vpn_ipv6=$(app curl --noproxy '*' -6fsS --max-time 10 https://api64.ipify.org); then
      echo "VPN IPv6: $vpn_ipv6"
    else
      echo 'IPv6 VPN egress unavailable; no host IPv6 fallback allowed'
    fi
    cp "$probe_dir/resolv.conf" "$probe_dir/vpn-resolv.conf"
    printf 'nameserver 127.0.0.1\noptions timeout:1 attempts:1\n' > "$probe_dir/resolv.conf"
    blocked https://api.ipify.org
    cat "$probe_dir/vpn-resolv.conf" > "$probe_dir/resolv.conf"
    echo 'PASS: resolver failure has no host fallback'
    stop_vpn
    blocked http://1.1.1.1
    blocked 'http://[2606:4700:4700::1111]'
    echo 'PASS: clean client stop has no underlay fallback'
    ip link set tap0 down
    blocked http://1.1.1.1
    ip link set tap0 up
    # Linux deletes non-kernel routes when the link goes down. Reapply the
    # underlay configuration, as a fresh slirp --configure start would do.
    ip -4 route replace default via 10.0.2.2 dev tap0
    ip -6 route replace default dev tap0
    start_vpn
    recovered_ip=$(app curl --noproxy '*' -4fsS --max-time 15 https://api.ipify.org)
    [[ $recovered_ip != "$(cat "$probe_dir/host-ip")" ]]
    echo 'PASS: VPN reconnects after clean stop and underlay link cycle'
    # Removing the tunnel leaves a valid underlay default route in main.
    # Independent nft rules must still prevent application escape.
    ip link delete hm0
    blocked http://1.1.1.1
    blocked 'http://[2606:4700:4700::1111]'
    echo 'PASS: removed tunnel has no underlay fallback'
    kill -KILL "$vpn_pid"
    wait "$vpn_pid" 2>/dev/null || true
    vpn_pid=
    blocked http://1.1.1.1
    echo 'PASS: crashed client has no underlay fallback'
  fi
  nft list table inet hide_me_probe
  exit
fi
if [[ $# -lt 2 || $# -gt 4 ]]; then
  echo "Usage: $0 CLIENT TOOLS [TOKEN_FILE [SERVER]]" >&2
  exit 2
fi
client=$1
probe_tools=$2
token_file=${3:-}
server=${4:-free-nl}
if [[ -n $token_file ]]; then
  [[ $token_file == /* && -f $token_file && ! -L $token_file ]]
  [[ $(stat -c %a "$token_file") == 600 ]]
  [[ $(stat -c %u "$token_file") == "$UID" ]]
fi
export PATH="$probe_tools/bin:$PATH"
probe_dir=$(mktemp -d)
namespace_pid=
slirp_pid=
cleanup() {
  [[ -z $slirp_pid ]] || kill "$slirp_pid" 2>/dev/null || true
  [[ -z $namespace_pid ]] || kill "$namespace_pid" 2>/dev/null || true
  wait 2>/dev/null || true
  rm -rf -- "$probe_dir"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
ip route > "$probe_dir/host-routes-before"
sha256sum /etc/resolv.conf > "$probe_dir/host-dns-before"
if [[ -n $token_file ]]; then
  curl --noproxy '*' -4fsS --max-time 15 https://api.ipify.org > "$probe_dir/host-ip"
  echo "Host IPv4: $(cat "$probe_dir/host-ip")"
fi
unshare --user --map-root-user --net --mount \
  bash "$0" --inside "$probe_dir" "$client" "$probe_tools" "$token_file" "$server" &
namespace_pid=$!
for ((i=0; i<100; i++)); do
  [[ -s $probe_dir/pid ]] && break
  kill -0 "$namespace_pid"
  sleep 0.1
done
inner_pid=$(cat "$probe_dir/pid")
slirp4netns --configure --disable-host-loopback --disable-dns \
  --enable-seccomp --netns-type=path \
  --userns-path="/proc/$inner_pid/ns/user" --ready-fd=3 \
  "/proc/$inner_pid/ns/net" tap0 3> "$probe_dir/ready" \
  > "$probe_dir/slirp.log" 2>&1 &
slirp_pid=$!
if ! wait "$namespace_pid"; then
  cat "$probe_dir/slirp.log" >&2
  exit 1
fi
namespace_pid=
ip route > "$probe_dir/host-routes-after"
sha256sum /etc/resolv.conf > "$probe_dir/host-dns-after"
cmp "$probe_dir/host-routes-before" "$probe_dir/host-routes-after"
cmp "$probe_dir/host-dns-before" "$probe_dir/host-dns-after"
echo 'PASS: host routes and resolver content unchanged'
