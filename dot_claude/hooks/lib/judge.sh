JUDGE_MODEL="${JUDGE_MODEL:-claude-haiku-4-5-20251001}"
JUDGE_TIMEOUT="${JUDGE_TIMEOUT:-45}"

fail_open() {
  printf '%s skipped its check: %s\n' "$(basename "$0")" "${1:-reason unknown}" >&2
  exit 1
}

judge_is_reentrant() {
  [ -n "${CLAUDE_HOOK_JUDGE:-}" ]
}

judge_run_with_timeout() {
  local seconds="$1"
  shift
  local out
  out="$(mktemp)" || return 1
  set -m
  "$@" >"$out" 2>/dev/null &
  local pid=$!
  set +m
  local waited=0
  while kill -0 "$pid" 2>/dev/null; do
    if [ "$waited" -ge "$seconds" ]; then
      kill -KILL "-$pid" 2>/dev/null
      rm -f "$out"
      return 124
    fi
    sleep 1
    waited=$((waited + 1))
  done
  wait "$pid"
  local code=$?
  cat "$out"
  rm -f "$out"
  return "$code"
}

judge_ask() {
  command -v claude >/dev/null 2>&1 || return 1
  local out
  out="$(CLAUDE_HOOK_JUDGE=1 judge_run_with_timeout "$JUDGE_TIMEOUT" \
    claude -p --model "$JUDGE_MODEL" "$1")" || return 1
  [ -n "$out" ] || return 1
  out="$(printf '%s' "$out" | perl -0777 -ne 'print $1 if /(\{(?:[^{}"]|"(?:\\.|[^"\\])*"|(?1))*\})/s')"
  [ -n "$out" ] || return 1
  printf '%s\n' "$out"
}
