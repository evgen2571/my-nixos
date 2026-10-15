#!/usr/bin/env bash
# Persistent, higher-priority mask survives activation of pre-migration generations.
set -euo pipefail
[[ $(id -u) == 0 && $# -ge 1 && $# -le 2 ]] || { echo "Usage (root): $0 block|unblock [hide-me-NAME.service]" >&2; exit 2; }
unit=${2:-hide-me-vpn.service}
[[ "$unit" =~ ^hide-me-[a-zA-Z][a-zA-Z0-9_-]{0,31}\.service$ ]] || exit 2
mask=/etc/systemd/system.control/$unit
case "$1" in
  block)
    install -d -m 0755 /etc/systemd/system.control
    if [[ -e "$mask" || -L "$mask" ]]; then
      [[ -L "$mask" && $(readlink "$mask") == /dev/null ]] || { echo "Refusing to replace $mask" >&2; exit 1; }
    else
      ln -s /dev/null "$mask"
    fi
    systemctl daemon-reload
    [[ $(systemctl show "$unit" -p LoadState --value) == masked ]]
    ;;
  unblock)
    [[ -L "$mask" && $(readlink "$mask") == /dev/null ]]
    rm -- "$mask"
    systemctl daemon-reload
    ;;
  *) exit 2 ;;
esac
