# Global AGENTS.md Instructions

## Project Organization
- 永続的に必要な情報のみ、`docs/` など既存の適切な場所に残す
- Keep only permanently useful information in `docs/` or another appropriate long-lived location

### 保存すべきもの (What to save):
- 長期的に参照する運用ルールや合意済みプラン (Long-lived operational rules and agreed plans)
- 今後の参考になる解決策 (Solutions that may be useful for future reference)
- プロジェクト固有の設定やワークフロー (Project-specific configurations and workflows)
- APIやライブラリの使用例 (API and library usage examples)
- 再発しうる問題の対処方法 (Fixes for issues likely to recur)

### 保存不要なもの (What not to save):
- パスワードや秘密鍵などの機密情報 (Passwords, secret keys, and sensitive information)
- 完全に自明な操作（例：単純なcdコマンドのみ）(Completely trivial operations like simple cd commands)
- 一時的な実行ログ、途中経過の調査メモ、使い捨てのプラン (Temporary execution logs, interim investigation notes, disposable plans)

## General Guidelines
- Always prefer editing existing files over creating new ones
- Never create temporary documentation files unless explicitly requested
- Persistent documentation in `docs/` (or an existing long-lived location) is allowed when it provides ongoing value
- Follow existing code conventions and patterns in each project
- Use TodoWrite tool to track complex tasks and provide visibility into progress
- テストを生成するときに可能な限り、Mockを使用しないでください
  - 言語別の指針: Ruby は WebMock のみ、JavaScript/TypeScript は jest.fn() や MSW は必要時のみ、Python は unittest.mock の必要最小限、Go は interface を使った最小限のモック
  - モックは外部I/Oや不安定な依存の隔離が必要な場合に限定する

## Code Generation Rules
- コード生成時はコメントを一切書かない (DO NOT write any comments when generating code)
- ユーザーから明示的に要求された場合のみコメントを追加する (Only add comments when explicitly requested by the user)
- This applies to all programming languages and file types
- ファイル末尾に改行をいれる

## Language Selection
- 明示的な指定や既存プロジェクトの言語がない限り、Python は使用しない (Do not use Python for ad-hoc scripts/tools unless explicitly requested or already the project's language)
- 代わりに Ruby, Go, Rust, Bun (TypeScript/JavaScript) のいずれかを使う (Use Ruby, Go, Rust, or Bun instead)
- 既存プロジェクトが Python の場合はそのまま Python で作業してよい (If an existing project is already written in Python, continue using Python for that project)

## File Management
- Check existing project structure before making changes
- Use appropriate search tools to understand codebase before implementing changes
- Run lint and typecheck commands after making code changes (if available)

## Security
- Never commit secrets or keys to repositories
- Follow security best practices in all implementations
- Only assist with defensive security tasks

## Git Commit Rules
- コミットメッセージは日本語で記述する (Write commit messages in Japanese)
- feat:, fix:, docs:, refactor: などのプレフィックスを付ける (Use prefixes like feat:, fix:, docs:, refactor:)
- コミット時は署名を必須にする (Require signed commits)
- 基本は要約1行のみにする。本文で変更点を逐一列挙しない (Default to a single summary line; do not itemize every change in the body)
- 本文が必要なのは、要約だけでは伝わらない非自明な理由・背景がある場合のみ (Only add a body when there's a non-obvious reason/background the summary alone can't convey)
- Example: "feat: ユーザー認証機能を追加"
