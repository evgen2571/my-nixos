#!/usr/bin/env bash
# Exercise the real generated service scripts in disposable user/net/mount namespaces.
set -euo pipefail

if [[ ${1:-} != --inside ]]; then
  [[ $# == 4 ]] || { echo "Usage: $0 TOOLS INIT PREPARE CLEANUP" >&2; exit 2; }
  export PATH="$1/bin:$PATH"
  exec unshare --user --map-auto --map-root-user --mount --net bash "$0" --inside "$@"
fi

shift
tools=$1 init=$2 prepare=$3 cleanup=$4
export PATH="$tools/bin:$PATH"
[[ $(id -u) == 0 && $(readlink /proc/self/ns/user) != 'user:[4026531837]' ]]
mount --make-rprivate /
mount -t tmpfs tmpfs /run
mount -t tmpfs tmpfs /var/lib
"$init"
before=$(stat -Lc %i /run/netns/vpn)
"$init"
[[ $(stat -Lc %i /run/netns/vpn) == "$before" ]]
[[ $(ip netns exec vpn nft list chain inet agent_workspace output) == *'policy drop'* ]]
[[ $(ip netns exec vpn nft list chain inet agent_workspace output) == *'meta mark 0x0000486d'* ]]
ip -n vpn link add hm0 type wireguard
ip -n vpn -4 rule add not fwmark 18541 priority 10 table 55555
ip -n vpn -6 rule add not fwmark 18541 priority 10 table 55555
ip -n vpn -4 route add unreachable default table 55555
ip -n vpn -6 route add unreachable default table 55555
install -d -m 0700 /var/lib/hide-me-vpn
if ip netns exec vpn "$prepare"; then
  echo 'Missing token was incorrectly accepted' >&2; exit 1
fi
if ip -n vpn link show hm0 2>/dev/null; then
  echo 'Stale WireGuard interface survived cleanup' >&2; exit 1
fi
[[ $(ip -n vpn -4 rule show) != *'10:'* ]]
[[ $(ip -n vpn -6 rule show) != *'10:'* ]]
[[ -z $(ip -n vpn -4 route show table 55555 2>/dev/null || true) ]]
[[ -z $(ip -n vpn -6 route show table 55555 2>/dev/null || true) ]]
printf 'fixture-only-not-a-credential\n' > /var/lib/hide-me-vpn/accessToken.txt
chmod 0644 /var/lib/hide-me-vpn/accessToken.txt
ip netns exec vpn "$prepare"
[[ $(stat -c %a /var/lib/hide-me-vpn/accessToken.txt) == 600 ]]
[[ $(</run/network-namespaces/vpn/resolv.conf) == 'nameserver 127.0.0.1'* ]]
[[ $(ip netns exec vpn nft list chain inet agent_workspace output) == *'policy drop'* ]]
"$cleanup"
"$cleanup"
[[ ! -e /run/netns/vpn && ! -e /run/network-namespaces/vpn ]]
echo 'PASS: repeated init, stale crash state, missing token, token permissions, closed filter, repeated cleanup'
