#!/usr/bin/env bash
set -euo pipefail

OWNER=""
REPO=""
PR_NUMBER=""
COMMENTS_LIMIT="${CODEX_PR_REVIEW_FETCH_COMMENTS_LIMIT:-30}"
REVIEWS_LIMIT="${CODEX_PR_REVIEW_FETCH_REVIEWS_LIMIT:-40}"
THREADS_LIMIT="${CODEX_PR_REVIEW_FETCH_THREADS_LIMIT:-80}"

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --owner)
        if [[ $# -lt 2 || -z "${2:-}" || "${2:-}" == --* ]]; then
          echo "--owner requires a value" >&2
          exit 1
        fi
        OWNER="$2"
        shift 2
        ;;
      --repo)
        if [[ $# -lt 2 || -z "${2:-}" || "${2:-}" == --* ]]; then
          echo "--repo requires a value" >&2
          exit 1
        fi
        REPO="$2"
        shift 2
        ;;
      --pr)
        if [[ $# -lt 2 || -z "${2:-}" || "${2:-}" == --* ]]; then
          echo "--pr requires a number" >&2
          exit 1
        fi
        PR_NUMBER="$2"
        shift 2
        ;;
      *)
        echo "unknown option: $1" >&2
        exit 1
        ;;
    esac
  done
}

validate_inputs() {
  if [[ -z "$OWNER" || -z "$REPO" || -z "$PR_NUMBER" ]]; then
    echo "required: --owner <owner> --repo <repo> --pr <number>" >&2
    exit 1
  fi
  if [[ ! "$PR_NUMBER" =~ ^[0-9]+$ ]]; then
    echo "--pr must be a numeric pull request number" >&2
    exit 1
  fi
  if [[ ! "$COMMENTS_LIMIT" =~ ^[0-9]+$ ]] || (( COMMENTS_LIMIT < 1 )); then
    echo "CODEX_PR_REVIEW_FETCH_COMMENTS_LIMIT must be a positive integer" >&2
    exit 1
  fi
  if [[ ! "$REVIEWS_LIMIT" =~ ^[0-9]+$ ]] || (( REVIEWS_LIMIT < 1 )); then
    echo "CODEX_PR_REVIEW_FETCH_REVIEWS_LIMIT must be a positive integer" >&2
    exit 1
  fi
  if [[ ! "$THREADS_LIMIT" =~ ^[0-9]+$ ]] || (( THREADS_LIMIT < 1 )); then
    echo "CODEX_PR_REVIEW_FETCH_THREADS_LIMIT must be a positive integer" >&2
    exit 1
  fi
}

main() {
  parse_args "$@"
  validate_inputs
  gh api graphql \
    -f query='
      query($owner: String!, $name: String!, $number: Int!, $commentsLimit: Int!, $reviewsLimit: Int!, $threadsLimit: Int!) {
        repository(owner: $owner, name: $name) {
          pullRequest(number: $number) {
            reviewDecision
            comments(last: $commentsLimit) {
              nodes {
                body
                createdAt
                author {
                  login
                }
              }
            }
            reviews(last: $reviewsLimit) {
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
            reviewThreads(last: $threadsLimit) {
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
    -F number="$PR_NUMBER" \
    -F commentsLimit="$COMMENTS_LIMIT" \
    -F reviewsLimit="$REVIEWS_LIMIT" \
    -F threadsLimit="$THREADS_LIMIT"
}

main "$@"
