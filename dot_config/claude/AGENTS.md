# Global AGENTS.md Instructions

## Project Organization
- 実行内容のサマリなどは適宜プロジェクトディレクトリの `.scratch` ディレクトリに残すようにする
- Keep execution summaries and project-specific notes in the `.scratch` directory within each project

### 保存すべきもの (What to save):
- 実行したコマンドとその結果 (Executed commands and their results)
- ファイルの作成・編集・削除の履歴 (File creation, modification, and deletion history)
- 調査や検索の過程と結果 (Investigation and search processes and results)
- 設定変更やインストール作業 (Configuration changes and installation tasks)
- エラー対応やトラブルシューティング履歴 (Error handling and troubleshooting history)
- 今後の参考になる解決策 (Solutions that may be useful for future reference)
- プロジェクト固有の設定やワークフロー (Project-specific configurations and workflows)
- APIやライブラリの使用例 (API and library usage examples)
- デバッグプロセスと解決方法 (Debugging processes and solutions)

### 保存不要なもの (What not to save):
- パスワードや秘密鍵などの機密情報 (Passwords, secret keys, and sensitive information)
- 完全に自明な操作（例：単純なcdコマンドのみ）(Completely trivial operations like simple cd commands)

## General Guidelines
- Always prefer editing existing files over creating new ones
- Never create documentation files unless explicitly requested
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
- Example: "feat: ユーザー認証機能を追加"
