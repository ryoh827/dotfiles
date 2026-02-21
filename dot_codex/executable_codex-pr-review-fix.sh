#!/usr/bin/env bash
set -euo pipefail

COMMIT_MESSAGE="${CODEX_PR_REVIEW_FIX_COMMIT_MESSAGE:-fix: レビュー指摘に対応}"
PR_NUMBER=""

ensure_tool() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "required command not found: $name" >&2
    exit 1
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --pr)
        PR_NUMBER="${2:-}"
        shift 2
        ;;
      *)
        echo "unknown option: $1" >&2
        exit 1
        ;;
    esac
  done
}

ensure_clean_worktree() {
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "working tree is dirty; commit or stash before running codex-pr-review-fix" >&2
    exit 1
  fi
}

resolve_pr_number() {
  if [[ -n "$PR_NUMBER" ]]; then
    return
  fi
  PR_NUMBER="$(gh pr view --json number -q '.number' 2>/dev/null || true)"
  if [[ -z "$PR_NUMBER" || "$PR_NUMBER" == "null" ]]; then
    echo "failed to resolve PR number from current branch; pass --pr <number>" >&2
    exit 1
  fi
}

load_pr_meta() {
  local pr_json
  pr_json="$(gh pr view "$PR_NUMBER" --json number,title,url,headRefName,reviewDecision)"
  PR_URL="$(jq -r '.url' <<<"$pr_json")"
  PR_TITLE="$(jq -r '.title // ""' <<<"$pr_json")"
  HEAD_REF_NAME="$(jq -r '.headRefName // ""' <<<"$pr_json")"
  REVIEW_DECISION="$(jq -r '.reviewDecision // ""' <<<"$pr_json")"
  REPO_PATH="$(sed -E 's#https://github.com/([^/]+/[^/]+)/pull/[0-9]+#\1#' <<<"$PR_URL")"
  OWNER="${REPO_PATH%%/*}"
  REPO="${REPO_PATH##*/}"
  if [[ -z "$OWNER" || -z "$REPO" || "$OWNER" == "$REPO_PATH" ]]; then
    echo "failed to parse owner/repo from PR url: $PR_URL" >&2
    exit 1
  fi
}

ensure_branch_matches_pr() {
  local current_branch
  current_branch="$(git rev-parse --abbrev-ref HEAD)"
  if [[ "$current_branch" != "$HEAD_REF_NAME" ]]; then
    echo "current branch ($current_branch) does not match PR head ($HEAD_REF_NAME)" >&2
    exit 1
  fi
}

fetch_review_snapshot() {
  gh api graphql \
    -f query='
      query($owner: String!, $name: String!, $number: Int!) {
        repository(owner: $owner, name: $name) {
          pullRequest(number: $number) {
            reviewDecision
            comments(last: 30) {
              nodes {
                body
                createdAt
                author {
                  login
                }
              }
            }
            reviews(last: 40) {
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
                comments(last: 20) {
                  nodes {
                    body
                    createdAt
                    path
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
    -F number="$PR_NUMBER"
}

build_review_text() {
  local snapshot="$1"
  jq -r '
    .data.repository.pullRequest as $pr
    | [
        "PR review decision: " + ($pr.reviewDecision // "UNDECIDED"),
        "",
        "Issue comments:",
        (
          $pr.comments.nodes
          | map(select((.body // "") != ""))
          | sort_by(.createdAt)
          | map("- @" + (.author.login // "unknown") + ": " + ((.body // "") | gsub("[\r\n]+"; " ")))
          | if length == 0 then ["- (none)"] else . end
        )[],
        "",
        "Reviews:",
        (
          $pr.reviews.nodes
          | sort_by(.submittedAt)
          | map("- [" + (.state // "UNKNOWN") + "] @" + (.author.login // "unknown") + ": " + ((.body // "") | gsub("[\r\n]+"; " ")))
          | if length == 0 then ["- (none)"] else . end
        )[],
        "",
        "Review thread comments:",
        (
          $pr.reviewThreads.nodes
          | map(.comments.nodes[]?)
          | sort_by(.createdAt)
          | map("- @" + (.author.login // "unknown") + " (" + (.path // "no-path") + "): " + ((.body // "") | gsub("[\r\n]+"; " ")))
          | if length == 0 then ["- (none)"] else . end
        )[]
      ]
    | join("\n")
  ' <<<"$snapshot"
}

build_prompt() {
  local review_text="$1"
  cat <<EOF
You are addressing GitHub PR review feedback.
Repository: $OWNER/$REPO
Pull request: #$PR_NUMBER
Title: $PR_TITLE

Requirements:
- Review all comments below and apply only necessary fixes.
- Keep changes minimal and focused on review findings.
- Preserve existing project style and conventions.
- If a finding is already satisfied, leave code unchanged.

Review context:
$review_text
EOF
}

run_fix() {
  local prompt="$1"
  codex exec "$prompt"
}

commit_and_push_if_needed() {
  if git diff --quiet && git diff --cached --quiet; then
    echo "no changes produced"
    return 0
  fi
  git add -A
  if git diff --cached --quiet; then
    echo "no staged changes produced"
    return 0
  fi
  local current_branch
  current_branch="$(git rev-parse --abbrev-ref HEAD)"
  git commit -m "$COMMIT_MESSAGE"
  git push origin "$current_branch"
}

main() {
  ensure_tool gh
  ensure_tool jq
  ensure_tool codex
  ensure_tool git
  parse_args "$@"
  ensure_clean_worktree
  resolve_pr_number
  load_pr_meta
  ensure_branch_matches_pr
  local snapshot
  if ! snapshot="$(fetch_review_snapshot)"; then
    echo "failed to fetch review comments for PR #$PR_NUMBER" >&2
    exit 1
  fi
  local review_text
  review_text="$(build_review_text "$snapshot")"
  local prompt
  prompt="$(build_prompt "$review_text")"
  run_fix "$prompt"
  commit_and_push_if_needed
}

main "$@"
