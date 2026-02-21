---
name: pr-review-fix
description: Use this skill when you explicitly want to fetch current PR review comments, apply fixes, and commit/push in one run.
---

# PR Review Fix

Use this skill for manual, one-shot review handling.

## Workflow

1. Ensure the current branch is the PR head branch.
2. Ensure the working tree is clean.
3. Run:
   - `codex-pr-review-fix --pr <number>`
4. If PR number is omitted, run:
   - `codex-pr-review-fix`
5. Review the resulting commit and pushed branch.

## Behavior

1. Fetches review comments from the target PR.
2. Uses `codex-pr-review-fetch` as the fixed review-fetch entrypoint.
3. Calls `codex exec` with consolidated review context.
4. Commits and pushes only if code changes are produced.
5. Exits with an error when the working tree is dirty.

## Optional Env Vars

- `CODEX_PR_REVIEW_FETCH_COMMENTS_LIMIT`
- `CODEX_PR_REVIEW_FETCH_REVIEWS_LIMIT`
- `CODEX_PR_REVIEW_FETCH_THREADS_LIMIT`
