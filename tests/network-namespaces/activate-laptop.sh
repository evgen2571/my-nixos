#!/usr/bin/env bash
# Run locally on nixos-lp ONLY after reviewing/approving temporary activation.
# Usage: sudo bash activate-laptop.sh LAPTOP_SYSTEM_PATH PRIVATE_BOOTSTRAP_TOKEN SSH_PEER_IP
set -euo pipefail
[[ $# == 3 && $EUID == 0 && $(hostname) == nixos-lp ]] || {
  echo 'Requires root on nixos-lp, laptop system path, bootstrap token path, and SSH peer IP' >&2
  exit 2
}
target=$(readlink -f -- "$1")
token=$2
peer=$3
[[ $target == /nix/store/*-nixos-system-nixos-lp-* && -x $target/bin/switch-to-configuration ]]
[[ $peer != -* ]]
old=$(readlink -f /run/current-system)
unit=my-nixos-vpn-rollback
snapshot=/run/my-nixos-vpn-activation
if systemctl is-active --quiet "$unit.timer"; then
  echo 'An existing rollback is armed; resolve it before another activation' >&2
  exit 1
fi
install -d -m 0700 "$snapshot"
printf '%s\n' "$old" > "$snapshot/old-system"
printf '%s\n' "$target" > "$snapshot/test-system"
ip -4 route show table all > "$snapshot/routes-v4"
ip -6 route show table all > "$snapshot/routes-v6"
ip -4 route show default > "$snapshot/default-v4"
ip -6 route show default > "$snapshot/default-v6"
sha256sum /etc/resolv.conf > "$snapshot/resolver-checksum"
ip route get "$peer" | tee "$snapshot/ssh-route"
systemctl is-active tailscaled sshd
install -d -o root -g root -m 0700 /var/lib/hide-me-vpn
if [[ ! -e /var/lib/hide-me-vpn/accessToken.txt ]]; then
  [[ -s $token && ! -L $token && $(stat -c %a -- "$token") == 600 ]]
  install -o root -g root -m 0600 -- "$token" /var/lib/hide-me-vpn/accessToken.txt
fi

# Pin the old system against GC; the root timer survives SSH loss.
ln -sfn "$old" /nix/var/nix/gcroots/my-nixos-vpn-rollback
systemd-run --unit="$unit" --on-active=20min --timer-property=AccuracySec=1s \
  "$old/bin/switch-to-configuration" test
systemctl is-active --quiet "$unit.timer"
echo "Rollback armed for 20 minutes to $old"
if ! "$target/bin/switch-to-configuration" test; then
  systemctl start "$unit.service"
  exit 1
fi
ip -4 route show default > "$snapshot/default-v4-after"
ip -6 route show default > "$snapshot/default-v6-after"

if ! cmp "$snapshot/default-v4" "$snapshot/default-v4-after" ||
   ! cmp "$snapshot/default-v6" "$snapshot/default-v6-after" ||
   ! sha256sum --status -c "$snapshot/resolver-checksum" ||
   ! systemctl is-active --quiet tailscaled sshd; then
  echo 'Host network invariant changed; starting rollback' >&2
  systemctl start "$unit.service"
  exit 1
fi

echo 'Temporary activation finished; rollback remains armed.'
echo 'After verification, cancel with: sudo systemctl stop my-nixos-vpn-rollback.timer'
echo 'For immediate recovery: sudo systemctl start my-nixos-vpn-rollback.service'
