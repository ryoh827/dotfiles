#!/usr/bin/env bash
set -euo pipefail

DEFAULT_POLL_INTERVAL_SEC=180
DEFAULT_MAX_RETRY_PER_REVIEW=3
DEFAULT_COMMIT_MESSAGE="fix: レビュー指摘に対応"
DEFAULT_CONFIG_PATH="${HOME}/.codex/pr-autofix.toml"
DEFAULT_STATE_DIR="${HOME}/.codex/session-pr-autofix"

CONFIG_PATH="${CODEX_PR_AUTOFIX_CONFIG:-$DEFAULT_CONFIG_PATH}"
STATE_DIR="${CODEX_PR_AUTOFIX_STATE_DIR:-$DEFAULT_STATE_DIR}"
mkdir -p "$STATE_DIR"

command="${1:-}"
if [[ -z "$command" ]]; then
  echo "usage: codex-pr-autofix <start|status|stop|run-loop> [options]" >&2
  exit 1
fi
shift || true

now_iso() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

ensure_tool() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "required command not found: $name" >&2
    exit 1
  fi
}

read_toml_value() {
  local key="$1"
  local path="$2"
  if [[ ! -f "$path" ]]; then
    return 0
  fi
  awk -F'=' -v key="$key" '
    $1 ~ "^[[:space:]]*" key "[[:space:]]*$" {
      val=$2
      sub(/^[[:space:]]*/, "", val)
      sub(/[[:space:]]*$/, "", val)
      if (val ~ /^".*"$/) {
        sub(/^"/, "", val)
        sub(/"$/, "", val)
      }
      print val
      exit
    }
  ' "$path"
}

load_config() {
  POLL_INTERVAL_SEC="$(read_toml_value "poll_interval_sec" "$CONFIG_PATH")"
  MAX_RETRY_PER_REVIEW="$(read_toml_value "max_retry_per_review" "$CONFIG_PATH")"
  COMMIT_MESSAGE="$(read_toml_value "commit_message" "$CONFIG_PATH")"

  POLL_INTERVAL_SEC="${POLL_INTERVAL_SEC:-$DEFAULT_POLL_INTERVAL_SEC}"
  MAX_RETRY_PER_REVIEW="${MAX_RETRY_PER_REVIEW:-$DEFAULT_MAX_RETRY_PER_REVIEW}"
  COMMIT_MESSAGE="${COMMIT_MESSAGE:-$DEFAULT_COMMIT_MESSAGE}"

  if [[ ! "$POLL_INTERVAL_SEC" =~ ^[0-9]+$ ]] || (( POLL_INTERVAL_SEC < 10 )); then
    echo "invalid poll_interval_sec: $POLL_INTERVAL_SEC" >&2
    exit 1
  fi
  if [[ ! "$MAX_RETRY_PER_REVIEW" =~ ^[0-9]+$ ]] || (( MAX_RETRY_PER_REVIEW < 1 )); then
    echo "invalid max_retry_per_review: $MAX_RETRY_PER_REVIEW" >&2
    exit 1
  fi
}

state_path() {
  local pr="$1"
  echo "${STATE_DIR}/pr-${pr}.json"
}

pid_path() {
  local pr="$1"
  echo "${STATE_DIR}/pr-${pr}.pid"
}

log_path() {
  local pr="$1"
  echo "${STATE_DIR}/pr-${pr}.log"
}

write_state_raw() {
  local path="$1"
  local content="$2"
  local tmp
  tmp="$(mktemp "${STATE_DIR}/state.XXXXXX")"
  printf '%s\n' "$content" > "$tmp"
  mv "$tmp" "$path"
}

update_state() {
  local path="$1"
  shift
  if [[ ! -f "$path" ]]; then
    return 0
  fi
  local tmp
  tmp="$(mktemp "${STATE_DIR}/state.XXXXXX")"
  jq "$@" "$path" > "$tmp"
  mv "$tmp" "$path"
}

append_processed_review() {
  local path="$1"
  local review_id="$2"
  local ts="$3"
  local tmp
  tmp="$(mktemp "${STATE_DIR}/state.XXXXXX")"
  jq --arg rid "$review_id" --arg ts "$ts" '
    .processed_review_ids = ((.processed_review_ids // []) + [$rid] | unique) |
    .last_processed_review_id = $rid |
    .last_processed_at = $ts |
    .last_error = ""
  ' "$path" > "$tmp"
  mv "$tmp" "$path"
}

set_retry_count() {
  local path="$1"
  local review_id="$2"
  local retry="$3"
  local ts="$4"
  local tmp
  tmp="$(mktemp "${STATE_DIR}/state.XXXXXX")"
  jq --arg rid "$review_id" --argjson retry "$retry" --arg ts "$ts" '
    .retry_counts = (.retry_counts // {}) |
    .retry_counts[$rid] = $retry |
    .updated_at = $ts
  ' "$path" > "$tmp"
  mv "$tmp" "$path"
}

get_retry_count() {
  local path="$1"
  local review_id="$2"
  jq -r --arg rid "$review_id" '.retry_counts[$rid] // 0' "$path"
}

is_processed_review() {
  local path="$1"
  local review_id="$2"
  jq -e --arg rid "$review_id" '.processed_review_ids // [] | index($rid) != null' "$path" >/dev/null
}

parse_args_common() {
  PR_NUMBER=""
  SESSION_SCOPED="false"
  INTERVAL_OVERRIDE=""
  PARENT_PID_OVERRIDE=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --pr)
        PR_NUMBER="${2:-}"
        shift 2
        ;;
      --session-scoped)
        SESSION_SCOPED="true"
        shift
        ;;
      --interval)
        INTERVAL_OVERRIDE="${2:-}"
        shift 2
        ;;
      --parent-pid)
        PARENT_PID_OVERRIDE="${2:-}"
        shift 2
        ;;
      *)
        echo "unknown option: $1" >&2
        exit 1
        ;;
    esac
  done
  if [[ -z "$PR_NUMBER" ]]; then
    echo "--pr is required" >&2
    exit 1
  fi
}

ensure_pr_exists() {
  local pr="$1"
  gh pr view "$pr" --json number,url,headRefName,reviewDecision >/dev/null
}

resolve_repo_from_pr() {
  local pr="$1"
  local pr_json
  pr_json="$(gh pr view "$pr" --json url,headRefName,reviewDecision,number,title)"
  PR_URL="$(jq -r '.url' <<<"$pr_json")"
  HEAD_REF_NAME="$(jq -r '.headRefName' <<<"$pr_json")"
  REVIEW_DECISION="$(jq -r '.reviewDecision // ""' <<<"$pr_json")"
  PR_TITLE="$(jq -r '.title' <<<"$pr_json")"
  REPO_PATH="$(sed -E 's#https://github.com/([^/]+/[^/]+)/pull/[0-9]+#\1#' <<<"$PR_URL")"
  OWNER="${REPO_PATH%%/*}"
  REPO="${REPO_PATH##*/}"
  if [[ -z "$OWNER" || -z "$REPO" || "$OWNER" == "$REPO_PATH" ]]; then
    echo "failed to parse owner/repo from PR url: $PR_URL" >&2
    exit 1
  fi
}

generate_prompt() {
  local pr="$1"
  local review_body="$2"
  local unresolved="$3"
  cat <<EOF
You are fixing GitHub PR review feedback for pull request #$pr.
Repository: $OWNER/$REPO
Constraints:
- Address only requested review feedback.
- Keep changes minimal and scoped.
- Run tests or checks if obvious for changed area.
- Do not introduce unrelated refactors.
- Follow repository conventions.

Latest changes requested review body:
$review_body

Unresolved review thread comments:
$unresolved

After code changes, ensure git diff only includes required fixes.
EOF
}

fetch_review_snapshot() {
  local pr="$1"
  gh api graphql \
    -f query='
      query($owner: String!, $name: String!, $number: Int!) {
        repository(owner: $owner, name: $name) {
          pullRequest(number: $number) {
            state
            merged
            reviewDecision
            reviews(last: 30) {
              nodes {
                id
                state
                body
                submittedAt
                author {
                  login
                }
              }
            }
            reviewThreads(last: 80) {
              nodes {
                isResolved
                comments(last: 10) {
                  nodes {
                    body
                    createdAt
                    author {
                      login
                    }
                  }
                }
              }
            }
          }
        }
      }
    ' \
    -F owner="$OWNER" \
    -F name="$REPO" \
    -F number="$pr"
}

extract_latest_changes_requested_review() {
  local snapshot="$1"
  jq -c '
    .data.repository.pullRequest.reviews.nodes
    | map(select(.state == "CHANGES_REQUESTED"))
    | sort_by(.submittedAt)
    | last // empty
  ' <<<"$snapshot"
}

extract_unresolved_comments() {
  local snapshot="$1"
  jq -r '
    .data.repository.pullRequest.reviewThreads.nodes
    | map(select(.isResolved == false))
    | map(.comments.nodes[]?)
    | map("- @" + (.author.login // "unknown") + ": " + ((.body // "") | gsub("[\r\n]+"; " ")))
    | if length == 0 then "(none)" else join("\n") end
  ' <<<"$snapshot"
}

apply_fix_for_review() {
  local pr="$1"
  local state_file="$2"
  local review_id="$3"
  local review_body="$4"
  local unresolved="$5"
  local ts
  ts="$(now_iso)"
  update_state "$state_file" --arg ts "$ts" --arg rid "$review_id" '
    .status = "processing" |
    .current_review_id = $rid |
    .updated_at = $ts
  '
  local prompt
  prompt="$(generate_prompt "$pr" "$review_body" "$unresolved")"
  if ! codex exec "$prompt"; then
    return 1
  fi
  if git diff --quiet && git diff --cached --quiet; then
    append_processed_review "$state_file" "$review_id" "$(now_iso)"
    update_state "$state_file" --arg ts "$(now_iso)" '
      .status = "running" |
      .updated_at = $ts |
      .last_action = "no_changes"
    '
    return 0
  fi
  git add -A
  if git diff --cached --quiet; then
    append_processed_review "$state_file" "$review_id" "$(now_iso)"
    update_state "$state_file" --arg ts "$(now_iso)" '
      .status = "running" |
      .updated_at = $ts |
      .last_action = "no_staged_changes"
    '
    return 0
  fi
  git commit -m "$COMMIT_MESSAGE"
  git push
  append_processed_review "$state_file" "$review_id" "$(now_iso)"
  update_state "$state_file" --arg ts "$(now_iso)" '
    .status = "running" |
    .updated_at = $ts |
    .last_action = "pushed_fix"
  '
}

start_command() {
  ensure_tool gh
  ensure_tool jq
  ensure_tool codex
  parse_args_common "$@"
  load_config
  if [[ -n "$INTERVAL_OVERRIDE" ]]; then
    POLL_INTERVAL_SEC="$INTERVAL_OVERRIDE"
  fi
  if [[ ! "$POLL_INTERVAL_SEC" =~ ^[0-9]+$ ]] || (( POLL_INTERVAL_SEC < 10 )); then
    echo "invalid --interval: $POLL_INTERVAL_SEC" >&2
    exit 1
  fi
  ensure_pr_exists "$PR_NUMBER"
  resolve_repo_from_pr "$PR_NUMBER"
  local current_branch
  current_branch="$(git rev-parse --abbrev-ref HEAD)"
  if [[ "$current_branch" != "$HEAD_REF_NAME" ]]; then
    echo "current branch ($current_branch) does not match PR head ($HEAD_REF_NAME)" >&2
    exit 1
  fi
  local pid_file
  pid_file="$(pid_path "$PR_NUMBER")"
  if [[ -f "$pid_file" ]]; then
    local existing_pid
    existing_pid="$(cat "$pid_file")"
    if [[ -n "$existing_pid" ]] && kill -0 "$existing_pid" >/dev/null 2>&1; then
      echo "already running for PR #$PR_NUMBER (pid=$existing_pid)"
      exit 0
    fi
    rm -f "$pid_file"
  fi
  local parent_pid
  if [[ "$SESSION_SCOPED" == "true" ]]; then
    parent_pid="${PARENT_PID_OVERRIDE:-${CODEX_SESSION_PID:-$PPID}}"
  else
    parent_pid=""
  fi
  local log_file
  log_file="$(log_path "$PR_NUMBER")"
  local loop_args
  loop_args=(run-loop --pr "$PR_NUMBER" --interval "$POLL_INTERVAL_SEC")
  if [[ "$SESSION_SCOPED" == "true" ]]; then
    loop_args+=(--session-scoped)
    if [[ -n "$parent_pid" ]]; then
      loop_args+=(--parent-pid "$parent_pid")
    fi
  fi
  "$0" "${loop_args[@]}" >>"$log_file" 2>&1 &
  local child_pid=$!
  echo "$child_pid" > "$pid_file"
  local state_file
  state_file="$(state_path "$PR_NUMBER")"
  local initial_state
  initial_state="$(jq -n \
    --arg pr "$PR_NUMBER" \
    --arg owner "$OWNER" \
    --arg repo "$REPO" \
    --arg head_ref "$HEAD_REF_NAME" \
    --arg started_at "$(now_iso)" \
    --arg updated_at "$(now_iso)" \
    --arg pid "$child_pid" \
    --arg parent_pid "$parent_pid" \
    --argjson session_scoped "$( [[ "$SESSION_SCOPED" == "true" ]] && echo true || echo false )" \
    --arg review_decision "$REVIEW_DECISION" \
    --arg title "$PR_TITLE" \
    '{
      pr_number: $pr,
      owner: $owner,
      repo: $repo,
      pr_title: $title,
      head_ref: $head_ref,
      pid: ($pid|tonumber),
      parent_pid: (if $parent_pid == "" then null else ($parent_pid|tonumber) end),
      session_scoped: $session_scoped,
      started_at: $started_at,
      updated_at: $updated_at,
      status: "running",
      review_decision: $review_decision,
      processed_review_ids: [],
      retry_counts: {},
      last_processed_review_id: null,
      last_processed_at: null,
      last_action: "started",
      last_error: ""
    }')"
  write_state_raw "$state_file" "$initial_state"
  echo "started codex-pr-autofix for PR #$PR_NUMBER (pid=$child_pid)"
}

run_loop_command() {
  ensure_tool gh
  ensure_tool jq
  ensure_tool codex
  parse_args_common "$@"
  load_config
  if [[ -n "$INTERVAL_OVERRIDE" ]]; then
    POLL_INTERVAL_SEC="$INTERVAL_OVERRIDE"
  fi
  local parent_pid="$PARENT_PID_OVERRIDE"
  resolve_repo_from_pr "$PR_NUMBER"
  local state_file
  state_file="$(state_path "$PR_NUMBER")"
  local pid_file
  pid_file="$(pid_path "$PR_NUMBER")"
  if [[ ! -f "$state_file" ]]; then
    local bootstrap
    bootstrap="$(jq -n \
      --arg pr "$PR_NUMBER" \
      --arg owner "$OWNER" \
      --arg repo "$REPO" \
      --arg started_at "$(now_iso)" \
      --arg updated_at "$(now_iso)" \
      --arg pid "$$" \
      --arg parent_pid "$parent_pid" \
      --argjson session_scoped "$( [[ "$SESSION_SCOPED" == "true" ]] && echo true || echo false )" \
      '{
        pr_number: $pr,
        owner: $owner,
        repo: $repo,
        pid: ($pid|tonumber),
        parent_pid: (if $parent_pid == "" then null else ($parent_pid|tonumber) end),
        session_scoped: $session_scoped,
        started_at: $started_at,
        updated_at: $updated_at,
        status: "running",
        processed_review_ids: [],
        retry_counts: {},
        last_error: ""
      }')"
    write_state_raw "$state_file" "$bootstrap"
  fi
  echo "$$" > "$pid_file"
  while true; do
    local ts
    ts="$(now_iso)"
    if [[ "$SESSION_SCOPED" == "true" && -n "$parent_pid" ]]; then
      if ! kill -0 "$parent_pid" >/dev/null 2>&1; then
        update_state "$state_file" --arg ts "$ts" '
          .status = "stopped" |
          .updated_at = $ts |
          .last_action = "parent_session_ended"
        '
        rm -f "$pid_file"
        exit 0
      fi
    fi
    local snapshot
    if ! snapshot="$(fetch_review_snapshot "$PR_NUMBER" 2>/dev/null)"; then
      update_state "$state_file" --arg ts "$ts" '
        .status = "running" |
        .updated_at = $ts |
        .last_error = "failed_to_fetch_review_snapshot"
      '
      sleep "$POLL_INTERVAL_SEC"
      continue
    fi
    local review_decision
    review_decision="$(jq -r '.data.repository.pullRequest.reviewDecision // ""' <<<"$snapshot")"
    local pr_state
    pr_state="$(jq -r '.data.repository.pullRequest.state // ""' <<<"$snapshot")"
    local pr_merged
    pr_merged="$(jq -r '.data.repository.pullRequest.merged // false' <<<"$snapshot")"
    update_state "$state_file" --arg ts "$ts" --arg rd "$review_decision" '
      .status = "running" |
      .updated_at = $ts |
      .review_decision = $rd
    '
    if [[ "$pr_state" == "CLOSED" || "$pr_merged" == "true" ]]; then
      update_state "$state_file" --arg ts "$ts" --arg st "$pr_state" --arg mg "$pr_merged" '
        .status = "stopped" |
        .updated_at = $ts |
        .last_action = "pr_closed_or_merged" |
        .last_error = "" |
        .pr_state = $st |
        .pr_merged = ($mg == "true")
      '
      rm -f "$pid_file"
      exit 0
    fi
    if [[ "$review_decision" == "APPROVED" ]]; then
      update_state "$state_file" --arg ts "$ts" '
        .status = "stopped" |
        .updated_at = $ts |
        .last_action = "approved_detected" |
        .last_error = ""
      '
      rm -f "$pid_file"
      exit 0
    fi
    local processed_count
    processed_count="$(jq -r '.processed_review_ids | length' "$state_file")"
    if (( processed_count > 0 )) && [[ "$review_decision" != "CHANGES_REQUESTED" ]]; then
      update_state "$state_file" --arg ts "$ts" --arg rd "$review_decision" '
        .status = "stopped" |
        .updated_at = $ts |
        .last_action = "changes_request_cleared" |
        .last_error = "" |
        .review_decision = $rd
      '
      rm -f "$pid_file"
      exit 0
    fi
    local review_json
    review_json="$(extract_latest_changes_requested_review "$snapshot")"
    if [[ -z "$review_json" ]]; then
      sleep "$POLL_INTERVAL_SEC"
      continue
    fi
    local review_id
    review_id="$(jq -r '.id' <<<"$review_json")"
    if is_processed_review "$state_file" "$review_id"; then
      sleep "$POLL_INTERVAL_SEC"
      continue
    fi
    local review_body
    review_body="$(jq -r '.body // ""' <<<"$review_json")"
    local unresolved
    unresolved="$(extract_unresolved_comments "$snapshot")"
    if apply_fix_for_review "$PR_NUMBER" "$state_file" "$review_id" "$review_body" "$unresolved"; then
      sleep "$POLL_INTERVAL_SEC"
      continue
    fi
    local retry
    retry="$(get_retry_count "$state_file" "$review_id")"
    retry="$((retry + 1))"
    set_retry_count "$state_file" "$review_id" "$retry" "$(now_iso)"
    if (( retry >= MAX_RETRY_PER_REVIEW )); then
      update_state "$state_file" --arg ts "$(now_iso)" --arg rid "$review_id" --argjson retry "$retry" '
        .status = "failed" |
        .updated_at = $ts |
        .last_action = "retry_exhausted" |
        .last_failed_review_id = $rid |
        .last_error = ("retry_exhausted_for_review:" + $rid + ":count=" + ($retry|tostring))
      '
      rm -f "$pid_file"
      exit 1
    fi
    update_state "$state_file" --arg ts "$(now_iso)" --arg rid "$review_id" --argjson retry "$retry" '
      .status = "running" |
      .updated_at = $ts |
      .last_action = "retry_scheduled" |
      .last_failed_review_id = $rid |
      .last_error = ("fix_failed_for_review:" + $rid + ":retry=" + ($retry|tostring))
    '
    sleep "$POLL_INTERVAL_SEC"
  done
}

status_command() {
  local pr=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --pr)
        pr="${2:-}"
        shift 2
        ;;
      *)
        echo "unknown option: $1" >&2
        exit 1
        ;;
    esac
  done
  if [[ -n "$pr" ]]; then
    local state_file
    state_file="$(state_path "$pr")"
    if [[ ! -f "$state_file" ]]; then
      echo "no state for PR #$pr"
      exit 0
    fi
    cat "$state_file"
    exit 0
  fi
  local found=0
  local f
  for f in "${STATE_DIR}"/pr-*.json; do
    if [[ -f "$f" ]]; then
      found=1
      jq -c '{pr_number,status,review_decision,pid,parent_pid,session_scoped,last_processed_review_id,last_processed_at,last_action,last_error,updated_at}' "$f"
    fi
  done
  if (( found == 0 )); then
    echo "no running or recorded state"
  fi
}

stop_command() {
  local pr=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --pr)
        pr="${2:-}"
        shift 2
        ;;
      *)
        echo "unknown option: $1" >&2
        exit 1
        ;;
    esac
  done
  if [[ -z "$pr" ]]; then
    echo "--pr is required for stop" >&2
    exit 1
  fi
  local pid_file
  pid_file="$(pid_path "$pr")"
  local state_file
  state_file="$(state_path "$pr")"
  if [[ -f "$pid_file" ]]; then
    local pid
    pid="$(cat "$pid_file")"
    if [[ -n "$pid" ]] && kill -0 "$pid" >/dev/null 2>&1; then
      kill "$pid" >/dev/null 2>&1 || true
    fi
    rm -f "$pid_file"
  fi
  if [[ -f "$state_file" ]]; then
    update_state "$state_file" --arg ts "$(now_iso)" '
      .status = "stopped" |
      .updated_at = $ts |
      .last_action = "manual_stop"
    '
  fi
  echo "stopped PR #$pr"
}

case "$command" in
  start)
    start_command "$@"
    ;;
  run-loop)
    run_loop_command "$@"
    ;;
  status)
    status_command "$@"
    ;;
  stop)
    stop_command "$@"
    ;;
  *)
    echo "unknown command: $command" >&2
    exit 1
    ;;
esac
