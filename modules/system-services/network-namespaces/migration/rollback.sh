#!/usr/bin/env bash
# Called by the independent root rollback timer; never enables desktop providers.
set -euo pipefail
[[ $(id -u) == 0 && $# == 2 ]] || exit 2
old=$1 host=$2
[[ "$old" == /nix/store/* && -x "$old/bin/switch-to-configuration" ]]
case "$host" in nixos-server|nixos-pc|nixos-lp) ;; *) exit 2;; esac
if [[ "$host" != nixos-server ]]; then
  bash "$(dirname -- "${BASH_SOURCE[0]}")/desktop-provider-guard.sh" block
fi
# A manual trigger must not cause a second rollback when the timer later expires.
if [[ $(systemctl show shared-vpn-rollback.timer -p LoadState --value) != not-found ]]; then
  systemctl stop shared-vpn-rollback.timer
fi
# Stop probes first, then egress/transport, then the retained namespace unit.
for unit in netns-vpn-health.timer netns-vpn-health.service hide-me-vpn.service \
  netns-vpn-dns.service netns-vpn-shared.service netns-vpn-underlay.service netns-vpn.service; do
  if [[ $(systemctl show "$unit" -p LoadState --value) != not-found ]]; then
    systemctl stop "$unit"
  fi
done
# An adopted or orphaned named namespace may outlive its systemd unit.
if ip netns list | grep -q '^vpn\( \|$\)'; then
  for link in shared0 hm0 tap0; do
    if ip -n vpn link show "$link" >/dev/null 2>&1; then
      ip -n vpn link delete "$link"
    fi
  done
  ip netns delete vpn
fi
rm -rf /run/network-namespaces/vpn
"$old/bin/switch-to-configuration" test
# Explicitly start restored lifecycle units; generation switching can retain them.
for unit in netns-vpn.service netns-vpn-underlay.service netns-vpn-shared.service \
  netns-vpn-dns.service hide-me-vpn.service netns-vpn-health.timer; do
  if [[ $(systemctl show "$unit" -p LoadState --value) == loaded ]]; then
    systemctl start "$unit"
  fi
done
if [[ "$host" != nixos-server ]]; then
  [[ $(systemctl show hide-me-vpn.service -p LoadState --value) == masked ]]
  if systemctl is-active --quiet hide-me-vpn.service; then exit 1; fi
fi
