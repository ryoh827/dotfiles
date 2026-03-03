---
name: plan-go
description: Execute an approved implementation plan file step by step, enforce unresolved-marker gate checks (XXX:/TODO:/AI-ASK:), run verification commands in defined priority, and remove the plan file after successful completion.
---

# Plan Go

Use this skill to execute an approved plan document step by step.

## Workflow

1. Read the specified `filename` and understand the full plan.
2. Before any implementation, scan for unresolved markers:
   - `XXX:`
   - `TODO:`
   - `AI-ASK:`
3. If any unresolved markers remain, stop and ask the user to confirm how to proceed.
4. Determine execution order:
   - Follow explicit TDD order if the plan defines it.
   - Otherwise follow the plan structure from top to bottom.
5. Implement each step:
   - Briefly state what you will do before starting each step.
   - If tests are present, apply Red, then Green, then Refactor.
   - Keep changes minimal and within the plan scope.
   - After each step, run verification with this priority:
     1. Use the plan-defined verification command for that step.
     2. Use `bun run typecheck && bun test`.
     3. Use project-standard verification commands if bun commands do not apply.
6. After all steps, run the final verification defined in the plan.
7. After successful completion, delete the plan file.

## Constraints

- Do not do anything outside the plan.
- Do not add out-of-scope improvements or refactors.
- If implementation contradicts the plan, stop and confirm with the user.
- Do not leave existing tests broken. Identify and fix failures caused by your changes.
