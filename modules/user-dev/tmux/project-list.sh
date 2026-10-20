#!/usr/bin/env bash
projects_dir="$HOME/dev"
[[ -d "$projects_dir" ]] || exit 0

declare -A scores=()

while IFS= read -r entry; do
  if [[ "$entry" =~ ^[[:space:]]*([0-9]+([.][0-9]+)?)[[:space:]]+(.*)$ ]]; then
    scores["${BASH_REMATCH[3]}"]="${BASH_REMATCH[1]}"
  fi
done < <(zoxide query --list --score 2>/dev/null || true)

while IFS= read -r -d "" project; do
  [[ -d "$project" ]] || continue
  printf '%s %s\n' "${scores["$project"]:-0}" "$project"

# Follow ~/dev when it is a symlink, retaining ~/dev paths in the output.
done < <(find -H "$projects_dir" -mindepth 1 -maxdepth 1 \( -type d -o -type l \) -print0) | sort -k1,1nr -k2,2
