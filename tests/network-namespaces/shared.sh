#!/usr/bin/env bash
# Run real generated scripts in disposable user/net/mount namespaces only.
set -euo pipefail
if [[ ${1:-} != --inside ]]; then
  [[ $# == 2 ]] || { echo "Usage: $0 TOOLS FIXTURES" >&2; exit 2; }
  export PATH="$1/bin:$PATH"
  exec unshare --user --map-current-user --keep-caps --mount --net bash "$0" --inside "$@"
fi
shift
umask 077
export PATH="$1/bin:$2/bin:$PATH"
[[ $(readlink /proc/self/ns/user) != 'user:[4026531837]' ]]
mount --make-rprivate /
mount -t tmpfs tmpfs /run
mount -t tmpfs tmpfs /var/lib
ip link set lo up
routes=$(ip route show table all)
routes6=$(ip -6 route show table all)
resolver=$(sha256sum /etc/resolv.conf)
for name in gateway pc laptop; do
  "$name-init"
  "$name-init"
  install -d -m 0700 "/var/lib/netns-$name-shared"
done
# Missing peers must refuse startup but generate a persistent private key.
if gateway-start; then echo 'Missing peer key accepted' >&2; exit 1; fi
for name in gateway pc laptop; do
  state="/var/lib/netns-$name-shared"
  if [[ ! -s "$state/private-key" ]]; then wg genkey > "$state/private-key"; fi
  chmod 0600 "$state/private-key"
  wg pubkey < "$state/private-key" > "$state/public-key"
  [[ $(stat -c %a "$state/private-key") == 600 ]]
done
for name in gateway pc laptop; do "$name-start"; done
ip netns add external
ip -n gateway link add hm0 type veth peer name outside
ip -n gateway link set outside netns external
ip -n gateway addr add 203.0.113.2/24 dev hm0
ip -n gateway -6 addr add fd99::2/64 dev hm0
ip -n gateway link set hm0 address 02:00:00:00:00:02
ip -n gateway link set hm0 up
ip -n external link set lo up
ip -n external addr add 203.0.113.1/24 dev outside
ip -n external -6 addr add fd99::1/64 dev outside
ip -n external link set outside address 02:00:00:00:00:01
ip -n external link set outside up
# Mock Ethernet needs static NDP: production hm0 is point-to-point WireGuard.
ip -n gateway -6 neigh add fd99::1 lladdr 02:00:00:00:00:01 nud permanent dev hm0
ip -n external -6 neigh add fd99::2 lladdr 02:00:00:00:00:02 nud permanent dev outside
ip -n gateway route add default dev hm0
ip -n gateway -6 route add default dev hm0
# Model Hide.me's policy route: local client return routes must win.
for family in -4 -6; do
  ip -n gateway "$family" route add default dev hm0 table 55555
  ip -n gateway "$family" rule add priority 10 table 55555
done
printf 'nameserver 203.0.113.1\n' > /run/network-namespaces/gateway/resolv.conf
ip netns exec external dnsmasq --keep-in-foreground --conf-file=/dev/null --no-resolv --no-hosts --address=/egress.test/203.0.113.1  --log-facility=- --pid-file= &
dns_upstream=$!
ip netns exec gateway dnsmasq --keep-in-foreground --conf-file=/dev/null --interface=shared0 --bind-interfaces --listen-address=10.77.0.1 --resolv-file=/run/network-namespaces/gateway/resolv.conf --no-hosts --cache-size=0  --log-facility=- --pid-file= &
dns_gateway=$!
ip netns exec external python3 -m http.server 8080 --bind :: > /run/http.log 2>&1 &
http=$!
trap 'kill "$dns_upstream" "$dns_gateway" "$http" 2>/dev/null || true' EXIT
probe() { ip netns exec "$1" curl --noproxy '*' -fsS --connect-timeout 2 --max-time 4 "$2" >/dev/null; }
for _ in {1..5}; do
  if probe pc http://203.0.113.1:8080 && probe laptop 'http://[fd99::1]:8080'; then break; fi
  sleep 0.2
done
# Simultaneous IPv4/IPv6 clients and VPN-only DNS.
probe pc http://203.0.113.1:8080 & first=$!
probe laptop 'http://[fd99::1]:8080' & second=$!
wait "$first"; wait "$second"
for name in pc laptop; do
  [[ $(ip netns exec "$name" dig +short +time=2 +tries=1 @10.77.0.1 egress.test) == 203.0.113.1 ]]
  probe "$name" http://203.0.113.1:8080
  probe "$name" 'http://[fd99::1]:8080'
done
# A regular underlay default must never become a forwarding fallback.
ip -n gateway link add tap0 type dummy
ip -n gateway addr add 192.0.2.2/24 dev tap0
ip -n gateway link set tap0 up
ip -n gateway route add default dev tap0 metric 100
ip -n gateway -6 route add default dev tap0 metric 100
ip -n gateway link set hm0 down
ip -n gateway -4 route replace 203.0.113.1/32 dev tap0
ip -n gateway -4 route flush table 55555
ip -n gateway -6 route flush table 55555
for name in pc laptop; do
  if probe "$name" http://203.0.113.1:8080 || probe "$name" 'http://[fd99::1]:8080'; then
    echo 'Egress survived lost VPN' >&2; exit 1
  fi
  if [[ $(ip netns exec "$name" dig +short +time=1 +tries=1 @10.77.0.1 egress.test) == 203.0.113.1 ]]; then
    echo 'DNS survived lost VPN' >&2; exit 1
  fi
done
ip -n gateway link set hm0 up
# Model the provider reapplying tunnel state after link-down.
ip -n gateway -4 route del 203.0.113.1/32 dev tap0
ip -n gateway -4 route replace default dev hm0
ip -n gateway -4 route replace default dev hm0 table 55555
ip -n gateway -6 addr replace fd99::2/64 dev hm0
ip -n gateway -6 route replace default dev hm0
ip -n gateway -6 route replace default dev hm0 table 55555
ip -n gateway -6 neigh replace fd99::1 lladdr 02:00:00:00:00:01 nud permanent dev hm0
for _ in {1..5}; do
  if probe pc http://203.0.113.1:8080 && probe laptop 'http://[fd99::1]:8080'; then break; fi
  sleep 0.5
done
probe pc http://203.0.113.1:8080
probe laptop 'http://[fd99::1]:8080'
ip -n pc link delete shared0
if probe pc http://203.0.113.1:8080; then echo 'Missing transport leaked' >&2; exit 1; fi
pc-start
probe pc http://203.0.113.1:8080
[[ $(ip route show table all) == "$routes" ]]
[[ $(ip -6 route show table all) == "$routes6" ]]
[[ $(sha256sum /etc/resolv.conf) == "$resolver" ]]
echo 'PASS: simultaneous clients, IPv4/IPv6, DNS, fail-closed VPN/transport loss, recovery, unchanged host routes/resolver'
