#!/usr/bin/env bash
set -uo pipefail

MIN_LINES=10
MAX_CONSECUTIVE_DENIALS=2

. "$(dirname "${BASH_SOURCE[0]}")/lib/judge.sh"

payload="$(cat)"

judge_is_reentrant && exit 0

session_id="$(printf '%s' "$payload" | jq -r '.session_id // "unknown"' 2>/dev/null)" || fail_open

tool="$(printf '%s' "$payload" | jq -r '.tool_name // ""' 2>/dev/null)" || fail_open

case "$tool" in
  Write)
    path="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // ""' 2>/dev/null)" || fail_open
    case "$path" in
      *.md) ;;
      *) exit 0 ;;
    esac
    content="$(printf '%s' "$payload" | jq -r '.tool_input.content // ""' 2>/dev/null)" || fail_open
    target="$path"
    header="DOCUMENT"
    scope_note=""
    ;;
  Bash)
    content="$(printf '%s' "$payload" | jq -r '.tool_input.command // ""' 2>/dev/null)" || fail_open
    case "$content" in
      *"gh pr create"*|*"gh pr edit"*) ;;
      *) exit 0 ;;
    esac
    body_file="$(printf '%s' "$content" | sed -n "s/.*--body-file[ =]*[\"']*\([^ \"']*\).*/\1/p")"
    target="gh-pr"
    if [ -n "$body_file" ] && [ -r "$body_file" ]; then
      content="$(cat "$body_file")"
      header="PULL REQUEST BODY"
      scope_note="The body may follow a repository template; keep that template's scaffolding."
    else
      header="SHELL COMMAND CARRYING A PULL REQUEST BODY"
      scope_note="Judge only the pull request body text inside the command. Ignore the command
itself, its flags, and shell quoting. The body may follow a repository template;
keep that template's scaffolding."
    fi
    ;;
  *) exit 0 ;;
esac

[ -n "$content" ] || fail_open

lines="$(printf '%s\n' "$content" | grep -c '[^[:space:]]')"
[ "$lines" -ge "$MIN_LINES" ] || exit 0

state_dir="${TMPDIR:-/tmp}/claude-doc-slop-gate"
mkdir -p "$state_dir" 2>/dev/null || fail_open
state_file="$state_dir/$session_id-$(printf '%s' "$target" | cksum | cut -d' ' -f1)"
denials="$(cat "$state_file" 2>/dev/null || printf '0')"
case "$denials" in ''|*[!0-9]*) denials=0 ;; esac
[ "$denials" -ge "$MAX_CONSECUTIVE_DENIALS" ] && fail_open "gave up after $MAX_CONSECUTIVE_DENIALS denials on this document"

read -r -d '' prompt <<PROMPT
You are auditing text an AI coding assistant is about to write.

$header:
---
$content
---
$scope_note

Work in two steps.

1. State in one sentence what this text is trying to convey to its reader.
2. Decide which sentences are needed to convey that. Every sentence that is not
   needed is a cut: a restatement of something already said, background the
   reader did not ask for, narration of the author's own process, decoration, or
   a heading with nothing under it that earns the heading.

Quote each cut EXACTLY as it appears in the text so the author can find it.
Never cut information the reader needs, template scaffolding the author must
keep (unchecked boxes, HTML comments, details blocks), or code. When in doubt,
keep it.

Reply with JSON only:
{"intent":"<step 1>","ok":true} if every sentence earns its place, otherwise
{"intent":"<step 1>","ok":false,"cut":["<exact sentence>"]}
PROMPT

verdict="$(judge_ask "$prompt")"
case $? in
  0) ;;
  2) fail_open "no judge is installed" ;;
  *)
    printf '%s\n' "$((denials + 1))" >"$state_file" 2>/dev/null
    {
      printf 'The slop gate could not reach its judge, so nothing checked this text.\n'
      printf 'Do it yourself: say in one sentence what this text must convey, cut every\n'
      printf 'sentence that does not serve it, then write it again.\n'
    } >&2
    exit 2
    ;;
esac

intent="$(printf '%s' "$verdict" | jq -r '.intent // ""' 2>/dev/null)" || fail_open
cuts="$(printf '%s' "$verdict" | jq -r 'if .ok == false then ((.cut // []) | join("\n")) else "" end' 2>/dev/null)" || fail_open

if [ -z "$cuts" ]; then
  rm -f "$state_file" 2>/dev/null
  exit 0
fi

printf '%s\n' "$((denials + 1))" >"$state_file" 2>/dev/null

reason="$({
  printf 'Judged intent: %s\n' "$intent"
  printf 'These sentences do not serve it:\n'
  printf '%s\n' "$cuts" | sed 's/^/  - /'
  printf 'Cut them, or say why the intent was misread.\n'
})"

jq -nc --arg r "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $r
  }
}'
exit 0
