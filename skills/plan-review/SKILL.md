---
name: plan-review
description: Review and improve a plan document by applying inline feedback markers (XXX:), adding targeted clarification questions as AI-ASK:, and producing a concise change summary. Use when a user asks to refine planning docs before implementation without writing code.
---

# Plan Review

Use this skill when the user wants plan-only refinement.

## Workflow

1. Read the specified `filename` and understand the full plan.
2. Apply all `XXX:` feedback in the file:
   - Revise design when comments raise concerns or objections.
   - Evaluate alternatives, then adopt or reject with rationale reflected in the plan.
   - Incorporate added requirements or constraints.
   - Add missing perspectives when noted.
   - Remove resolved `XXX:` comments.
   - If a comment cannot be resolved now, replace it with `TODO:`.
3. Perform critical analysis from these perspectives:
   - ambiguous descriptions
   - overlooked considerations (edge cases, error handling, consistency)
   - implicit assumptions
   - unjustified design choices where alternatives exist
   - unclear in-scope and out-of-scope boundaries
4. Insert each issue immediately after the relevant section as:
   - `AI-ASK: {question}`
5. Provide a summary of edits and added questions.
6. If there are no unresolved markers (`XXX:`, `TODO:`, `AI-ASK:`), respond exactly:
   - `No unclear points in the plan. Ready for implementation.`

## Constraints

- Never start implementation.
- Update only the plan file.
- Do not edit or create code files.
- Preserve existing plan format and structure.
