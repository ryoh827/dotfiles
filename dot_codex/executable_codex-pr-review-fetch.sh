#!/usr/bin/env bash
set -euo pipefail

OWNER=""
REPO=""
PR_NUMBER=""

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
}

main() {
  parse_args "$@"
  validate_inputs
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

main "$@"
