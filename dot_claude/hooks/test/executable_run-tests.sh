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
{ printf '%s\n' "$@"; printf 'ENV_JUDGE=%s\n' "${CLAUDE_HOOK_JUDGE:-}"; cat; } >"$STUB_INPUT_FILE"
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

# 7. the hook does not re-enter itself through the session it spawns to judge
export STUB_OUTPUT='{"ok":false,"claims":["再帰"]}'
nested_payload="$(jq -nc --arg t "$transcript" \
  '{hook_event_name:"Stop",session_id:"s-nested",transcript_path:$t,last_assistant_message:"やりました。"}')"
export CLAUDE_HOOK_JUDGE=1
PATH="$WORK/bin:$PATH" run_stop_hook "$nested_payload"
assert_eq "a judge session does not run the hook again" "$?" "0"
unset CLAUDE_HOOK_JUDGE

# 8. the judge is spawned with the re-entry marker set, so it stops the recursion
PATH="$WORK/bin:$PATH" run_stop_hook "$nested_payload"
assert_contains "the judge call carries the re-entry marker" \
  "$(cat "$STUB_INPUT_FILE")" "ENV_JUDGE=1"

# 9. the judge fencing its JSON does not silently disarm the gate
export STUB_OUTPUT='```json
{"ok":false,"claims":["フェンス付きの主張"]}
```'
fenced_payload="$(jq -nc --arg t "$transcript" \
  '{hook_event_name:"Stop",session_id:"s-fenced",transcript_path:$t,last_assistant_message:"やりました。"}')"
PATH="$WORK/bin:$PATH" run_stop_hook "$fenced_payload"
assert_eq "fenced verdict still blocks" "$?" "2"
assert_contains "fenced verdict names the claim" "$(cat "$WORK/stderr")" "フェンス付きの主張"

# 10. a judge that hangs is killed instead of stalling the turn
cat >"$WORK/bin/claude" <<'STUB'
#!/usr/bin/env bash
sleep 5
printf '%s' '{"ok":false,"claims":["おそい"]}'
STUB
chmod +x "$WORK/bin/claude"
hang_payload="$(jq -nc --arg t "$transcript" \
  '{hook_event_name:"Stop",session_id:"s-hang",transcript_path:$t,last_assistant_message:"やりました。"}')"
hang_start=$SECONDS
JUDGE_TIMEOUT=1 PATH="$WORK/bin:$PATH" run_stop_hook "$hang_payload"
assert_eq "a hanging judge fails open" "$?" "0"
assert_eq "a hanging judge is killed promptly" \
  "$([ $((SECONDS - hang_start)) -lt 4 ] && echo fast || echo slow)" "fast"
make_stub_claude

SYNC_HOOK="$HOOK_DIR/executable_session-sync-global-memory.sh"

run_sync_hook() {
  printf '%s' "$2" | CLAUDE_CONFIG_DIR="$1" "$SYNC_HOOK" 2>"$WORK/sync-stderr"
}

# 11. global memories land in the project store without disturbing local entries
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

# 12. no global store -> silent no-op
EMPTY_CFG="$WORK/empty-cfg"
mkdir -p "$EMPTY_CFG"
run_sync_hook "$EMPTY_CFG" "$sync_payload"
assert_eq "missing global store exits cleanly" "$?" "0"
assert_eq "missing global store is silent" "$(cat "$WORK/sync-stderr")" ""

GUARD_HOOK="$HOOK_DIR/executable_guard-claude-md.sh"

# 13. CLAUDE.md edits escalate; every other path passes through untouched
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

JUDGE_HOOK="$HOOK_DIR/executable_judge-doc-slop.sh"

long_doc() {
  printf '# %s\n\n' "$1"
  for i in 1 2 3 4 5 6 7 8 9 10 11 12; do printf '本文の行 %s。\n' "$i"; done
}

judge_payload() {
  jq -nc --arg s "$1" --arg p "$2" --arg c "$3" \
    '{hook_event_name:"PreToolUse",session_id:$s,tool_name:"Write",tool_input:{file_path:$p,content:$c}}'
}

run_judge_hook() {
  printf '%s' "$1" | TMPDIR="$WORK" "$JUDGE_HOOK" 2>"$WORK/judge-stderr"
}

# 14. a verbose document is denied, naming the judged intent and the sentences to cut
make_stub_claude
export STUB_INPUT_FILE="$WORK/judge-input.txt"
export STUB_OUTPUT='{"intent":"hook の導入手順を伝える","ok":false,"cut":["この節は前段の繰り返しです。"]}'
export STUB_EXIT=0
verbose_payload="$(judge_payload "s-verbose" "/Users/x/docs/plan.md" "$(long_doc plan)")"
out="$(PATH="$WORK/bin:$PATH" run_judge_hook "$verbose_payload")"
assert_eq "verbose document is denied" \
  "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision')" "deny"
assert_contains "denial names the sentence to cut" "$out" "この節は前段の繰り返しです。"
assert_contains "denial states the judged intent" "$out" "hook の導入手順を伝える"

# 15. a non-markdown write never reaches the judge
export STUB_OUTPUT='{"intent":"x","ok":false,"cut":["y"]}'
rm -f "$STUB_INPUT_FILE"
code_payload="$(judge_payload "s-code" "/Users/x/project/main.go" "$(long_doc code)")"
out="$(PATH="$WORK/bin:$PATH" run_judge_hook "$code_payload")"
assert_eq "non-markdown write passes through" "$out" ""
assert_eq "non-markdown write never invokes the judge" \
  "$([ -e "$STUB_INPUT_FILE" ] && echo called || echo skipped)" "skipped"

# 16. a short document is not worth a judge call
export STUB_OUTPUT='{"intent":"x","ok":false,"cut":["y"]}'
rm -f "$STUB_INPUT_FILE"
short_payload="$(judge_payload "s-short" "/Users/x/docs/note.md" "$(printf '# Note\n\n一行だけ。\n')")"
out="$(PATH="$WORK/bin:$PATH" run_judge_hook "$short_payload")"
assert_eq "short document passes through" "$out" ""
assert_eq "short document never invokes the judge" \
  "$([ -e "$STUB_INPUT_FILE" ] && echo called || echo skipped)" "skipped"

bash_payload() {
  jq -nc --arg s "$1" --arg c "$2" \
    '{hook_event_name:"PreToolUse",session_id:$s,tool_name:"Bash",tool_input:{command:$c}}'
}

# 17. a verbose PR body is denied, and the judge is shown the body text
export STUB_OUTPUT='{"intent":"変更の要点を伝える","ok":false,"cut":["この行は本文の繰り返しです。"]}'
rm -f "$STUB_INPUT_FILE"
pr_cmd="gh pr create --base main --title 'feat: x' --body '$(long_doc Summary)'"
out="$(PATH="$WORK/bin:$PATH" run_judge_hook "$(bash_payload "s-pr" "$pr_cmd")")"
assert_eq "verbose PR body is denied" \
  "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision')" "deny"
assert_contains "judge is shown the PR body" "$(cat "$STUB_INPUT_FILE" 2>/dev/null)" "本文の行 7。"

# 18. an unrelated shell command never reaches the judge
rm -f "$STUB_INPUT_FILE"
out="$(PATH="$WORK/bin:$PATH" run_judge_hook "$(bash_payload "s-sh" "git status --porcelain")")"
assert_eq "unrelated command passes through" "$out" ""
assert_eq "unrelated command never invokes the judge" \
  "$([ -e "$STUB_INPUT_FILE" ] && echo called || echo skipped)" "skipped"

# 19. a third consecutive denial on one document fails open
export STUB_OUTPUT='{"intent":"x","ok":false,"cut":["繰り返し"]}'
loop_doc="$(judge_payload "s-judge-loop" "/Users/x/docs/loop.md" "$(long_doc loop)")"
out="$(PATH="$WORK/bin:$PATH" run_judge_hook "$loop_doc")"
assert_eq "first denial still denies" \
  "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision')" "deny"
out="$(PATH="$WORK/bin:$PATH" run_judge_hook "$loop_doc")"
assert_eq "second denial still denies" \
  "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision')" "deny"
out="$(PATH="$WORK/bin:$PATH" run_judge_hook "$loop_doc")"
assert_eq "third consecutive denial fails open" "$out" ""

# 20. a document whose every sentence earns its place passes through untouched
export STUB_OUTPUT='{"intent":"x","ok":true}'
out="$(PATH="$WORK/bin:$PATH" run_judge_hook "$(judge_payload "s-clean" "/Users/x/docs/clean.md" "$(long_doc clean)")")"
assert_eq "clean document passes through" "$out" ""

# 21. giving up on one document does not disarm the gate for the next one
export STUB_OUTPUT='{"intent":"x","ok":false,"cut":["a"]}'
capped_doc="$(judge_payload "s-cap" "/Users/x/docs/capped.md" "$(long_doc capped)")"
PATH="$WORK/bin:$PATH" run_judge_hook "$capped_doc" >/dev/null
PATH="$WORK/bin:$PATH" run_judge_hook "$capped_doc" >/dev/null
out="$(PATH="$WORK/bin:$PATH" run_judge_hook "$capped_doc")"
assert_eq "the capped document is let through" "$out" ""
out="$(PATH="$WORK/bin:$PATH" run_judge_hook "$(judge_payload "s-cap" "/Users/x/docs/other.md" "$(long_doc other)")")"
assert_eq "a different document in the same session is still judged" \
  "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision')" "deny"

# 22. the judge being unavailable never blocks a write
export STUB_OUTPUT='{"intent":"x","ok":false,"cut":["a"]}'
out="$(PATH="/usr/bin:/bin" run_judge_hook "$(judge_payload "s-nojudge" "/Users/x/docs/n.md" "$(long_doc n)")")"
assert_eq "missing judge fails open" "$out" ""

# 23. an unparseable verdict never blocks a write
export STUB_OUTPUT='not json at all'
out="$(PATH="$WORK/bin:$PATH" run_judge_hook "$(judge_payload "s-garbage" "/Users/x/docs/g.md" "$(long_doc g)")")"
assert_eq "unparseable verdict fails open" "$out" ""

# 24. the doc gate does not run inside the session it spawns to judge
export STUB_OUTPUT='{"intent":"x","ok":false,"cut":["a"]}'
export CLAUDE_HOOK_JUDGE=1
out="$(PATH="$WORK/bin:$PATH" run_judge_hook "$(judge_payload "s-doc-nested" "/Users/x/docs/n2.md" "$(long_doc n2)")")"
assert_eq "a judge session does not run the doc gate" "$out" ""
unset CLAUDE_HOOK_JUDGE

# 25. the judge fencing its JSON does not silently disarm the doc gate
export STUB_OUTPUT='```json
{"intent":"手順を伝える","ok":false,"cut":["フェンス越しの一文。"]}
```'
out="$(PATH="$WORK/bin:$PATH" run_judge_hook "$(judge_payload "s-doc-fenced" "/Users/x/docs/f.md" "$(long_doc f)")")"
assert_eq "fenced verdict still denies the write" \
  "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision')" "deny"
assert_contains "fenced verdict names the sentence to cut" "$out" "フェンス越しの一文。"

# 26. prose trailing the verdict does not silently disarm the doc gate
export STUB_OUTPUT='{"intent":"手順を伝える","ok":false,"cut":["末尾に散文がある場合の一文。"]}

The document restates its own purpose twice.'
out="$(PATH="$WORK/bin:$PATH" run_judge_hook "$(judge_payload "s-doc-trailing" "/Users/x/docs/t.md" "$(long_doc t)")")"
assert_eq "trailing prose still denies the write" \
  "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision')" "deny"
assert_contains "trailing prose names the sentence to cut" "$out" "末尾に散文がある場合の一文。"

# 27. a preamble before the verdict does not silently disarm the doc gate
export STUB_OUTPUT='Here is my assessment:

{"intent":"手順を伝える","ok":false,"cut":["前置きがある場合の一文。"]}'
out="$(PATH="$WORK/bin:$PATH" run_judge_hook "$(judge_payload "s-doc-preamble" "/Users/x/docs/p.md" "$(long_doc p)")")"
assert_eq "a preamble still denies the write" \
  "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision')" "deny"

# 28. a verdict carrying a brace inside a quoted sentence survives extraction
export STUB_OUTPUT='```json
{"intent":"手順を伝える","ok":false,"cut":["この行の { と } は本文の一部です。"]}
```'
out="$(PATH="$WORK/bin:$PATH" run_judge_hook "$(judge_payload "s-doc-brace" "/Users/x/docs/b.md" "$(long_doc b)")")"
assert_contains "a braced sentence survives extraction" "$out" "この行の { と } は本文の一部です。"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
