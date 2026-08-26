#!/usr/bin/env bash
set -uo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_DIR="$(dirname "$TEST_DIR")"
STOP_HOOK="$HOOK_DIR/executable_stop-verify-claims.sh"

pass=0
fail=0

report() {
  if [ "$1" = "ok" ]; then
    pass=$((pass + 1))
    printf 'ok   %s\n' "$2"
  else
    fail=$((fail + 1))
    printf 'FAIL %s\n     %s\n' "$2" "$3"
  fi
}

assert_eq() {
  if [ "$2" = "$3" ]; then
    report ok "$1"
  else
    report fail "$1" "expected [$3], got [$2]"
  fi
}

assert_contains() {
  case "$2" in
    *"$3"*) report ok "$1" ;;
    *) report fail "$1" "expected to contain [$3], got [$2]" ;;
  esac
}

assert_not_contains() {
  case "$2" in
    *"$3"*) report fail "$1" "expected NOT to contain [$3], got [$2]" ;;
    *) report ok "$1" ;;
  esac
}

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

make_stub_claude() {
  mkdir -p "$WORK/bin"
  cat >"$WORK/bin/claude" <<'STUB'
#!/usr/bin/env bash
{ printf '%s\n' "$@"; cat; } >"$STUB_INPUT_FILE"
printf '%s' "$STUB_OUTPUT"
exit "${STUB_EXIT:-0}"
STUB
  chmod +x "$WORK/bin/claude"
  mkdir -p "$WORK/empty-bin"
}

transcript_unsupported_claim() {
  local f="$WORK/unsupported.jsonl"
  cat >"$f" <<'JSON'
{"type":"user","message":{"role":"user","content":[{"type":"text","text":"前の話"}]}}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","name":"Grep","input":{"pattern":"old"}}]}}
{"type":"user","message":{"role":"user","content":[{"type":"text","text":"メモリに書いておいて"}]}}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"メモリに書きました。"}]}}
JSON
  printf '%s' "$f"
}

run_stop_hook() {
  printf '%s' "$1" | TMPDIR="$WORK" "$STOP_HOOK" 2>"$WORK/stderr"
}

# 1. judge reports an unsupported claim -> exit 2, claim on stderr
make_stub_claude
export STUB_INPUT_FILE="$WORK/judge-input.txt"
export STUB_OUTPUT='{"ok":false,"claims":["メモリに書きました"]}'
export STUB_EXIT=0
transcript="$(transcript_unsupported_claim)"
payload="$(jq -nc --arg t "$transcript" \
  '{hook_event_name:"Stop",session_id:"s-block",transcript_path:$t,last_assistant_message:"メモリに書きました。"}')"

PATH="$WORK/bin:$PATH" run_stop_hook "$payload"
assert_eq "unsupported claim blocks the turn" "$?" "2"
assert_contains "blocked turn names the claim" "$(cat "$WORK/stderr")" "メモリに書きました"

# 2. judge reports clean -> exit 0
export STUB_OUTPUT='{"ok":true}'
PATH="$WORK/bin:$PATH" run_stop_hook "$payload"
assert_eq "clean verdict ends the turn" "$?" "0"

# 3. claude not on PATH -> fail open
export STUB_OUTPUT='{"ok":false,"claims":["x"]}'
PATH="/usr/bin:/bin" run_stop_hook "$payload"
assert_eq "missing judge fails open" "$?" "0"

# 4. third consecutive block in one session -> fail open
export STUB_OUTPUT='{"ok":false,"claims":["繰り返し"]}'
loop_payload="$(jq -nc --arg t "$transcript" \
  '{hook_event_name:"Stop",session_id:"s-loop",transcript_path:$t,last_assistant_message:"やりました。"}')"
PATH="$WORK/bin:$PATH" run_stop_hook "$loop_payload"
assert_eq "first block still blocks" "$?" "2"
PATH="$WORK/bin:$PATH" run_stop_hook "$loop_payload"
assert_eq "second block still blocks" "$?" "2"
PATH="$WORK/bin:$PATH" run_stop_hook "$loop_payload"
assert_eq "third consecutive block fails open" "$?" "0"

# 5. evidence covers this turn's tool calls and excludes earlier turns
cat >"$WORK/scoped.jsonl" <<'JSON'
{"type":"user","message":{"role":"user","content":[{"type":"text","text":"前の話"}]}}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","name":"Grep","input":{"pattern":"STALE_MARKER"}}]}}
{"type":"user","message":{"role":"user","content":[{"type":"text","text":"設定を読んで"}]}}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","name":"Read","input":{"file_path":"/etc/FRESH_MARKER"}}]}}
{"type":"user","message":{"role":"user","content":[{"type":"tool_result","content":"contents of FRESH_MARKER"}]}}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"読みました。"}]}}
JSON
export STUB_OUTPUT='{"ok":true}'
scoped_payload="$(jq -nc --arg t "$WORK/scoped.jsonl" \
  '{hook_event_name:"Stop",session_id:"s-scope",transcript_path:$t,last_assistant_message:"読みました。"}')"
PATH="$WORK/bin:$PATH" run_stop_hook "$scoped_payload"
judge_input="$(cat "$STUB_INPUT_FILE")"
assert_contains "evidence includes this turn's tool call" "$judge_input" "FRESH_MARKER"
assert_contains "evidence includes this turn's tool result" "$judge_input" "TOOL_RESULT"
assert_not_contains "evidence excludes earlier turns" "$judge_input" "STALE_MARKER"

# 6. unreadable transcript -> fail open
no_transcript="$(jq -nc '{hook_event_name:"Stop",session_id:"s-none",transcript_path:"/nonexistent/x.jsonl",last_assistant_message:"やりました。"}')"
export STUB_OUTPUT='{"ok":false,"claims":["x"]}'
PATH="$WORK/bin:$PATH" run_stop_hook "$no_transcript"
assert_eq "unreadable transcript fails open" "$?" "0"

SYNC_HOOK="$HOOK_DIR/executable_session-sync-global-memory.sh"

run_sync_hook() {
  printf '%s' "$2" | CLAUDE_CONFIG_DIR="$1" "$SYNC_HOOK" 2>"$WORK/sync-stderr"
}

# 7. global memories land in the project store without disturbing local entries
CFG="$WORK/cfg"
mkdir -p "$CFG/memory-global"
cat >"$CFG/memory-global/no-unverified-claims.md" <<'MEM'
---
name: no-unverified-claims
description: 検証していないことを断定で書かない
---
body
MEM
cat >"$CFG/memory-global/verify-before-relaying.md" <<'MEM'
---
name: verify-before-relaying
description: Open the cited file before repeating a finding
---
body
MEM

WT_CWD="/Users/x/ghq/github.com/acme/widget/.claude/worktrees/wt1"
WT_SLUG="-Users-x-ghq-github-com-acme-widget--claude-worktrees-wt1"
STORE="$CFG/projects/$WT_SLUG/memory"
mkdir -p "$STORE"
printf 'local memory body\n' >"$STORE/project-local-fact.md"
printf -- '- [project-local-fact](project-local-fact.md) — a local fact\n' >"$STORE/MEMORY.md"

sync_payload="$(jq -nc --arg c "$WT_CWD" '{hook_event_name:"SessionStart",session_id:"s1",cwd:$c}')"
run_sync_hook "$CFG" "$sync_payload"
assert_eq "sync exits cleanly" "$?" "0"
assert_eq "global memory is symlinked into the store" \
  "$([ -L "$STORE/no-unverified-claims.md" ] && echo yes || echo no)" "yes"
index="$(cat "$STORE/MEMORY.md")"
assert_contains "local index line survives" "$index" "project-local-fact.md"
assert_contains "global index line added" "$index" "no-unverified-claims.md"
assert_contains "global index carries the description" "$index" "検証していないことを断定で書かない"

run_sync_hook "$CFG" "$sync_payload"
rerun_index="$(cat "$STORE/MEMORY.md")"
assert_eq "sync is idempotent" "$rerun_index" "$index"

# 8. no global store -> silent no-op
EMPTY_CFG="$WORK/empty-cfg"
mkdir -p "$EMPTY_CFG"
run_sync_hook "$EMPTY_CFG" "$sync_payload"
assert_eq "missing global store exits cleanly" "$?" "0"
assert_eq "missing global store is silent" "$(cat "$WORK/sync-stderr")" ""

GUARD_HOOK="$HOOK_DIR/executable_guard-claude-md.sh"

# 9. CLAUDE.md edits escalate; every other path passes through untouched
guard_payload() {
  jq -nc --arg p "$1" \
    '{hook_event_name:"PreToolUse",tool_name:"Edit",tool_input:{file_path:$p}}'
}

out="$(guard_payload "/Users/x/.claude/CLAUDE.md" | "$GUARD_HOOK")"
assert_eq "CLAUDE.md edit escalates" \
  "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision')" "escalate"
assert_contains "escalation points at memory-global" "$out" "memory-global"

out="$(guard_payload "/Users/x/project/src/main.go" | "$GUARD_HOOK")"
assert_eq "unrelated edit passes through" "$?" "0"
assert_eq "unrelated edit stays silent" "$out" ""

out="$(guard_payload "/Users/x/project/docs/CLAUDE.md.tmpl" | "$GUARD_HOOK")"
assert_eq "CLAUDE.md template also escalates" \
  "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision')" "escalate"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
