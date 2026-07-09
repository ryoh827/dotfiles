# Global AGENTS.md Instructions

## Project Organization
- Keep only permanently useful information in `docs/` or another appropriate long-lived location

### What to save:
- Long-lived operational rules and agreed plans
- Solutions that may be useful for future reference
- Project-specific configurations and workflows
- API and library usage examples
- Fixes for issues likely to recur

### What not to save:
- Passwords, secret keys, and sensitive information
- Completely trivial operations like simple cd commands
- Temporary execution logs, interim investigation notes, disposable plans

## Coding Behavior Guidelines
(Use judgment to skip these for trivial tasks. By default, bias toward caution over speed.)

### Think Before Coding
- State your assumptions explicitly. If uncertain, stop and ask.
- If multiple interpretations exist, present them instead of silently picking one.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop, name what's confusing, and ask.

### Simplicity First
- Write only the minimum code that solves the problem. Nothing speculative.
- Don't add features, abstractions, or configurability that weren't requested.
- Don't create abstractions for single-use code.
- Don't write error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it. Ask yourself "would a senior engineer call this overcomplicated?"

### Surgical Changes
- Touch only what you must. Clean up only your own mess.
- Don't "improve" adjacent code, comments, or formatting. Don't refactor things that aren't broken.
- Match the existing style even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.
- Remove only the imports/variables/functions your changes made unused. Don't remove pre-existing dead code unless asked.
- Every changed line should trace directly to the user's request.

### Goal-Driven Execution
- Transform tasks into verifiable goals ("Add validation" → "Write tests for invalid inputs, then make them pass"; "Fix the bug" → "Write a test that reproduces it, then make it pass").
- For multi-step tasks, state a brief plan with each step and its verification.
- Strong success criteria let you loop independently; weak criteria ("make it work") require constant clarification.

## General Guidelines
- Always prefer editing existing files over creating new ones
- Never create temporary documentation files unless explicitly requested
- Persistent documentation in `docs/` (or an existing long-lived location) is allowed when it provides ongoing value
- Follow existing code conventions and patterns in each project
- Use TodoWrite tool to track complex tasks and provide visibility into progress
- Do not use mocks when generating tests wherever possible
  - Per-language guidance: Ruby uses WebMock only; JavaScript/TypeScript uses jest.fn() or MSW only when needed; Python uses the minimum necessary unittest.mock; Go uses minimal mocking via interfaces
  - Limit mocks to cases that require isolating external I/O or unstable dependencies

## Response Conciseness
- Before writing each sentence, ask "is this truly necessary" and cut it if not
- Do not write preambles or postambles (play-by-play like "I'll do X" / "I did X", or restating what you already did)
- Answer questions conclusion-first; explain background or history only when asked
- Limit explanations of changes or code to the non-obvious points; do not narrate every trivial change
- When applying a correction, output only the corrected result; do not write the edit history or excuses in the deliverable (e.g. "(was originally ~)", "(because it was wrong)")
- Do not push unsolicited suggestions (e.g. "other things you could do", "additional notes")
- Use bullet lists and headings only when they add information, not for decoration

## Code Generation Rules
- Do not write any comments when generating code
- Only add comments when explicitly requested by the user
- This applies to all programming languages and file types
- Add a trailing newline at the end of files

## Language Selection
- Do not use Python for ad-hoc scripts/tools unless explicitly requested or already the project's language
- Use Ruby, Go, Rust, or Bun (TypeScript/JavaScript) instead
- If an existing project is already written in Python, continue using Python for that project

## File Management
- Check existing project structure before making changes
- Use appropriate search tools to understand codebase before implementing changes
- Run lint and typecheck commands after making code changes (if available)

## Security
- Never commit secrets or keys to repositories
- Follow security best practices in all implementations
- Only assist with defensive security tasks

## Git Commit Rules
- Write commit messages in Japanese
- Use prefixes like feat:, fix:, docs:, refactor:
- Require signed commits
- Default to a single summary line; do not itemize every change in the body
- Only add a body when there's a non-obvious reason/background the summary alone can't convey
- Example: "feat: ユーザー認証機能を追加"
