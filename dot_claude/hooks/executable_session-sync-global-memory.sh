#!/usr/bin/env bash
set -uo pipefail

START_MARKER='<!-- global:start -->'
END_MARKER='<!-- global:end -->'

config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
global_dir="$config_dir/memory-global"
[ -d "$global_dir" ] || exit 0

payload="$(cat)"
cwd="$(printf '%s' "$payload" | jq -r '.cwd // ""' 2>/dev/null)" || exit 0
[ -n "$cwd" ] || exit 0

slug="$(printf '%s' "$cwd" | tr '/.' '--')"
store="$config_dir/projects/$slug/memory"
mkdir -p "$store" 2>/dev/null || exit 0

index="$store/MEMORY.md"
block="$START_MARKER"

for source in "$global_dir"/*.md; do
  [ -f "$source" ] || continue
  base="$(basename "$source")"
  [ "$base" = "MEMORY.md" ] && continue

  ln -sfn "$source" "$store/$base" 2>/dev/null || continue

  name="$(sed -n 's/^name: *//p' "$source" | head -1)"
  desc="$(sed -n 's/^description: *//p' "$source" | head -1)"
  desc="${desc%\"}"
  desc="${desc#\"}"
  [ -n "$name" ] || name="${base%.md}"

  if [ -n "$desc" ]; then
    block="$block"$'\n'"- [$name]($base) — $desc"
  else
    block="$block"$'\n'"- [$name]($base)"
  fi
done

block="$block"$'\n'"$END_MARKER"

local_lines=''
if [ -f "$index" ]; then
  local_lines="$(sed "/$START_MARKER/,/$END_MARKER/d" "$index")"
fi

{
  [ -n "$local_lines" ] && printf '%s\n' "$local_lines"
  printf '%s\n' "$block"
} >"$index" 2>/dev/null

exit 0
