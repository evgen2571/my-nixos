#!/usr/bin/env bash
# Permanent masks also protect boots of generations predating the shared gateway.
set -euo pipefail
[[ $(id -u) == 0 && $# -le 1 ]] || { echo "Usage (root): $0 [NAMESPACE]" >&2; exit 2; }
name=${1:-vpn}
[[ "$name" =~ ^[a-zA-Z][a-zA-Z0-9_-]{0,31}$ ]] || exit 2
install -d -m 0755 /etc/systemd/system.control

for unit in "hide-me-$name.service" "netns-$name-underlay.service"; do
  mask=/etc/systemd/system.control/$unit
  if [[ -e "$mask" || -L "$mask" ]]; then
    [[ -L "$mask" && $(readlink "$mask") == /dev/null ]] || { echo "Refusing to replace $mask" >&2; exit 1; }
  else
    ln -s /dev/null "$mask"
  fi
done

# Boot activation runs before PID 1 is systemd; the masks apply when it starts.
if [[ ! -d /run/systemd/system ]]; then exit 0; fi
systemctl daemon-reload
for unit in "hide-me-$name.service" "netns-$name-underlay.service"; do
  [[ $(systemctl show "$unit" -p LoadState --value) == masked ]]
  systemctl stop "$unit"
done
