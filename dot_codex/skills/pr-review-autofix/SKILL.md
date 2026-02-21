---
name: pr-review-autofix
description: Use this skill when creating a PR in Codex and you want to auto-start session-scoped review fix handling with codex-pr-autofix.
---

# PR Review Autofix

Use this flow when the user wants review feedback to be handled automatically only within the current Codex session.

## Workflow

1. Ensure current branch changes are ready and run `git push`.
2. Create PR if not already created:
   - `gh pr create -w`
3. Resolve PR number:
   - `gh pr view --json number -q '.number'`
4. Start session-scoped autofix:
   - `codex-pr-autofix start --pr <number> --session-scoped`
5. Show current status:
   - `codex-pr-autofix status --pr <number>`

## Stop

Stop watcher manually when requested:

- `codex-pr-autofix stop --pr <number>`

## Operational Rules

1. This skill never creates a global daemon.
2. This skill targets only one PR at start time.
3. Trigger handling is for `CHANGES_REQUESTED`.
4. If `APPROVED` is detected, watcher exits.
