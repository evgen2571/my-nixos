#!/usr/bin/env bash
set -euo pipefail

script=$(realpath "$1")
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
export HOME="$scratch/home"
mkdir -p "$HOME" "$scratch/bin"
export PATH="$scratch/bin:$PATH"

# A machine without ~/dev has no project sessions.
test -z "$(bash -euo pipefail "$script")"

# Keep ~/dev paths even when the directory and a project are symlinks.
mkdir -p "$scratch/projects/visited project/nested" "$scratch/projects/new" "$scratch/linked"
ln -s "$scratch/projects" "$HOME/dev"
ln -s "$scratch/linked" "$HOME/dev/linked"
ln -s "$scratch/missing" "$HOME/dev/broken"
touch "$HOME/dev/file"
printf '#!%s\n' "$(command -v bash)" > "$scratch/bin/zoxide"
cat >> "$scratch/bin/zoxide" <<'SH'
printf '12.5 %s\n2 %s\n' "$HOME/dev/visited project" "$HOME/dev/linked"
SH
chmod +x "$scratch/bin/zoxide"

printf '12.5 %s\n2 %s\n0 %s\n' \
  "$HOME/dev/visited project" "$HOME/dev/linked" "$HOME/dev/new" > "$scratch/expected"
bash -euo pipefail "$script" > "$scratch/actual"
diff -u "$scratch/expected" "$scratch/actual"

# Projects remain available when zoxide has no usable database.
printf '#!%s\nexit 1\n' "$(command -v bash)" > "$scratch/bin/zoxide"
printf '0 %s\n' "$HOME/dev/linked" "$HOME/dev/new" "$HOME/dev/visited project" > "$scratch/expected"
bash -euo pipefail "$script" > "$scratch/actual"
diff -u "$scratch/expected" "$scratch/actual"
