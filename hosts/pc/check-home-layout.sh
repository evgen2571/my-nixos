# Read-only: refuse migration conflicts before Home Manager can back them up.
set -euo pipefail
home=$1
data=$2
pictures=$3
games=$4
fail() { echo "PC home layout: $*. See docs/pc-btrfs-migration.md before activation." >&2; exit 1; }
mountpoint -q "$games" || fail "$games is not mounted"
for path in "$home/dev" "$home/downloads" "$pictures" "$pictures/wallpapers" \
    "$home/.local" "$home/.steam" "$data" "$data/Steam" "$data/PrismLauncher"; do
    [[ ! -L $path && ( ! -e $path || -d $path ) ]] || fail "expected a real directory at $path; preserve and relocate existing data manually"
done
if [[ -d $home/dev ]]; then
    ! mountpoint -q "$home/dev" || fail "dev must be a directory inside @home"
    ! btrfs subvolume show "$home/dev" >/dev/null 2>&1 || fail "dev must not be a subvolume"
fi
for pair in "$home/games:$games" "$data/Steam/steamapps:$games/steam/steamapps" \
    "$data/PrismLauncher/instances:$games/minecraft/instances"; do
    path=${pair%%:*}
    target=${pair#*:}
    if [[ -e $path || -L $path ]]; then
        [[ -L $path && $(readlink -m "$path") == "$target" ]] || fail "conflicting game storage at $path"
    fi
done
for path in "$home/.steam/steam" "$home/.steam/root" "$home/Steam"; do
    if [[ -e $path || -L $path ]]; then
        [[ -L $path && $(readlink -m "$path") == "$data/Steam" ]] || fail "legacy Steam root at $path"
    fi
done
cfg="$data/PrismLauncher/prismlauncher.cfg"
if [[ -f $cfg ]]; then
    instances=$(awk 'BEGIN { path="instances" } /^InstanceDir=/ { sub(/\r$/, ""); path=substr($0,13) } END { print path }' "$cfg")
    [[ $instances == instances || $instances == "$data/PrismLauncher/instances" || $instances == "$games/minecraft/instances" ]] \
        || fail "custom Prism InstanceDir; restore instances and reset this setting manually"
fi
# Regular wallpapers and local additions are safe. The wallpaper module
# only replaces its own managed files during activation.
