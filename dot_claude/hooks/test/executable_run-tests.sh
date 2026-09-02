#!/usr/bin/env bash
set -uo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_DIR="$(dirname "$TEST_DIR")"

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

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

SYNC_HOOK="$HOOK_DIR/executable_session-sync-global-memory.sh"

run_sync_hook() {
  printf '%s' "$2" | CLAUDE_CONFIG_DIR="$1" "$SYNC_HOOK" 2>"$WORK/sync-stderr"
}

# 1. global memories land in the project store without disturbing local entries
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

# 2. no global store -> silent no-op
EMPTY_CFG="$WORK/empty-cfg"
mkdir -p "$EMPTY_CFG"
run_sync_hook "$EMPTY_CFG" "$sync_payload"
assert_eq "missing global store exits cleanly" "$?" "0"
assert_eq "missing global store is silent" "$(cat "$WORK/sync-stderr")" ""

GUARD_HOOK="$HOOK_DIR/executable_gh_write_guard.sh"

run_guard_hook() {
  jq -nc --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}' | "$GUARD_HOOK"
}

# 3. gh write commands trigger an ask decision
for cmd in \
  'gh api repos/x/y/pulls/1/comments/1/replies -f body=test' \
  'gh pr comment 1 --body test' \
  'gh pr review 1 --approve' \
  'gh pr edit 1 --body-file x.md'
do
  out="$(run_guard_hook "$cmd")"
  assert_contains "guard asks before: $cmd" "$out" '"permissionDecision": "ask"'
done

# 4. read-only gh calls and unrelated commands pass through silently
for cmd in \
  'gh api repos/x/y/pulls/1/comments' \
  'ls -la'
do
  out="$(run_guard_hook "$cmd")"
  assert_eq "guard is silent for: $cmd" "$out" ""
done

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
