#!/usr/bin/env bash
set -euo pipefail

fail() { echo "Provisioning refused: $*" >&2; exit 1; }
[[ $# == 3 ]] || fail 'Usage: provision-disk preview|apply pc|laptop|server /dev/disk/by-id/WHOLE-DISK'
action=$1 host=$2 device=$3
case "$action" in preview|apply) ;; *) fail 'Usage: provision-disk preview|apply HOST DEVICE' ;; esac
case "$host" in pc|laptop|server) ;; *) fail 'unknown host; select pc, laptop or server' ;; esac
[[ $device =~ ^/dev/disk/by-id/[a-zA-Z0-9._:+-]+$ ]] || fail 'select an explicit whole-disk /dev/disk/by-id/ path'
resolved=$(readlink -e -- "$device") || fail 'device does not exist'

check_disk() {
    local current kind read_only mounts
    current=$(readlink -e -- "$device") || fail 'cannot resolve device'
    [[ $current == "$resolved" ]] || fail 'device identity changed'
    kind=$(lsblk -dnro TYPE -- "$device") || fail 'cannot inspect disk type'
    [[ $kind == disk ]] || fail 'target must be a whole disk'
    read_only=$(lsblk -dnro RO -- "$device") || fail 'cannot inspect read-only state'
    [[ $read_only == 0 ]] || fail 'target is read-only'
    mounts=$(lsblk -nr -o MOUNTPOINTS -- "$device") || fail 'cannot inspect disk usage'
    [[ ! $mounts =~ [^[:space:]] ]] || fail 'disk or a descendant is in use (mounted or active swap)'
}
check_disk
args=(--mode 'destroy,format,mount' --argstr host "$host" --argstr device "$device" @layout@)
if [[ $action == preview ]]; then
    exec @disko@ --dry-run "${args[@]}"
fi

[[ $(id -u) == 0 ]] || fail 'apply requires root from installation media'
echo "DESTROYS ALL PARTITIONS AND DATA on $device ($resolved) for $host." >&2
echo 'Fresh/replacement system disk only. Windows and data partitions are NOT preserved.' >&2
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS -- "$device" >&2
echo "Type exactly: ERASE $host $device" >&2
read -r confirmation || fail 'confirmation missing'
[[ $confirmation == "ERASE $host $device" ]] || fail 'confirmation did not match'
check_disk
exec @disko@ --yes-wipe-all-disks "${args[@]}"
