#!/usr/bin/env bash
# Run from an approved host-side root terminal BEFORE temporary activation.
# This only arms rollback; it never activates the candidate.
set -euo pipefail
[[ $# == 2 && $(id -u) == 0 ]] || { echo "Usage (root): $0 CANDIDATE_SYSTEM SSH_PEER_IP" >&2; exit 2; }
candidate=$(readlink -f "$1")
host=$(hostname)
case "$host" in nixos-server|nixos-pc|nixos-lp) ;; *) echo 'Unexpected host' >&2; exit 1;; esac
[[ "$candidate" == /nix/store/*-nixos-system-"$host"-* && -x "$candidate/bin/switch-to-configuration" ]]
[[ "$2" =~ ^[0-9a-fA-F:.]+$ ]]
old=$(readlink -f /run/current-system)
[[ "$old" == /nix/store/* && -x "$old/bin/switch-to-configuration" ]]

# Refuse to replace an already armed rollback.
if systemctl is-active --quiet shared-vpn-rollback.timer; then
  echo 'Rollback already armed' >&2; exit 1
fi
snapshot=$(mktemp -d /run/shared-vpn-rollback.XXXXXX)
chmod 0700 "$snapshot"
printf '%s\n' "$old" > "$snapshot/old-system"
printf '%s\n' "$candidate" > "$snapshot/candidate-system"
ip -4 route show table all > "$snapshot/routes4"
ip -6 route show table all > "$snapshot/routes6"
ip rule show > "$snapshot/rules4"
ip -6 rule show > "$snapshot/rules6"
ip route get "$2" > "$snapshot/ssh-route"
sha256sum /etc/resolv.conf > "$snapshot/resolver"

# Keep the old system rooted even if garbage collection runs during the test.
nix-store --add-root "$snapshot/old-root" --indirect -r "$old" >/dev/null
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
install -m 0700 "$source_dir/rollback.sh" "$source_dir/desktop-provider-guard.sh" "$snapshot/"
systemd-run --unit=shared-vpn-rollback --on-active=20m --timer-property=AccuracySec=1s \
  --property=Type=oneshot --property=TimeoutStartSec=5min --setenv="PATH=$old/sw/bin" \
  "$old/sw/bin/bash" "$snapshot/rollback.sh" "$old" "$host"
systemctl is-active --quiet shared-vpn-rollback.timer
printf 'Rollback armed. Snapshot: %s\nCandidate NOT activated: %s\n' "$snapshot" "$candidate"
