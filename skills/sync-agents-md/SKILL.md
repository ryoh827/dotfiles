---
name: sync-agents-md
description: Use this skill when ryoh827's dotfiles repo AGENTS.ja.md has been edited, or the user asks to sync/translate/regenerate AGENTS.md, to translate the Japanese source into the English AGENTS.md that gets deployed to Claude and Codex.
---

# Sync AGENTS.md from Japanese source

`AGENTS.ja.md`（リポジトリルート）がこのdotfilesの指示書の正となる日本語ソースであり、`AGENTS.md`はそれを英語に翻訳した配布用ファイル。両者の内容は常に意味的に一致させる。`AGENTS.md`は`dot_claude/CLAUDE.md.tmpl`と`dot_codex/AGENTS.md.tmpl`からincludeされ、`~/.claude/CLAUDE.md`と`~/.codex/AGENTS.md`に配信される。

## いつ使うか

- `AGENTS.ja.md` を編集した後
- 「AGENTS.mdを同期して」「翻訳を反映して」のように依頼されたとき
- `AGENTS.md` を直接編集してほしいと依頼された場合も、まず `AGENTS.ja.md` を編集してから本スキルで反映する

## 手順

1. `AGENTS.ja.md` を読む。
2. 見出し・箇条書きの構造と順序を保ったまま、内容を過不足なく英語に翻訳する。
   - コマンド、ファイルパス、コード例、コミットメッセージ例（日本語の例文）はそのまま残す。
   - 意訳しすぎず、指示のニュアンス（禁止・推奨・例外条件など）を正確に保つ。
3. 翻訳結果で `AGENTS.md` を上書きする。
4. `chezmoi diff` で差分を確認し、`chezmoi apply` を実行して `~/.claude/CLAUDE.md` と `~/.codex/AGENTS.md` に反映する。
5. 変更内容をユーザーに提示し、必要であればコミットする。

## 制約

- `AGENTS.ja.md` と `AGENTS.md` の見出し数・箇条書き数は一致させる（訳漏れ・過剰翻訳を防ぐ）。
- `AGENTS.md` を直接編集しない。常に `AGENTS.ja.md` が先。
