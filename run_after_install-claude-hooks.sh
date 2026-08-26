#!/usr/bin/env bash
set -euo pipefail

settings="$HOME/.claude/settings.json"
hooks="$HOME/.claude/hooks/hooks.json"

[ -f "$hooks" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

if [ -f "$settings" ]; then
  jq --slurpfile new "$hooks" '.hooks = ((.hooks // {}) * $new[0])' "$settings" >"$tmp"
else
  mkdir -p "$(dirname "$settings")"
  jq -n --slurpfile new "$hooks" '{hooks: $new[0]}' >"$tmp"
fi

if ! cmp -s "$tmp" "$settings" 2>/dev/null; then
  cat "$tmp" >"$settings"
  printf 'claude hooks merged into %s\n' "$settings"
fi
