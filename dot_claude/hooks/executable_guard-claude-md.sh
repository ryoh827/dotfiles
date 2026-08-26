#!/usr/bin/env bash
set -uo pipefail

payload="$(cat)"
path="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // ""' 2>/dev/null)" || exit 0

case "$(basename "$path")" in
  CLAUDE.md|CLAUDE.md.tmpl) ;;
  *) exit 0 ;;
esac

jq -nc '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "escalate",
    permissionDecisionReason: "CLAUDE.md is not the place for behavioral rules — those belong in memory-global/, which syncs to every project. Confirm only if this genuinely belongs in CLAUDE.md."
  }
}'
exit 0
