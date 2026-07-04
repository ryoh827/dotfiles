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

## General Guidelines
- Always prefer editing existing files over creating new ones
- Never create temporary documentation files unless explicitly requested
- Persistent documentation in `docs/` (or an existing long-lived location) is allowed when it provides ongoing value
- Follow existing code conventions and patterns in each project
- Use TodoWrite tool to track complex tasks and provide visibility into progress
- Do not use mocks when generating tests wherever possible
  - Per-language guidance: Ruby uses WebMock only; JavaScript/TypeScript uses jest.fn() or MSW only when needed; Python uses the minimum necessary unittest.mock; Go uses minimal mocking via interfaces
  - Limit mocks to cases that require isolating external I/O or unstable dependencies

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
