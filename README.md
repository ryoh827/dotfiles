# dotfiles (chezmoi)

このリポジトリは chezmoi の sourceDir です。

## セットアップ

```sh
# 初回（リモートから）
chezmoi init https://github.com/ryoh827/dotfiles.git

# 反映
chezmoi apply -v
```

## 日常の使い方

```sh
# 変更（編集）
chezmoi edit ~/.zshrc

# 反映
chezmoi apply -v

# 変更の確認
chezmoi diff
```

## Claude Code のフック

`dot_claude/hooks/` は `chezmoi apply` で `~/.claude/hooks/` に配置され、`run_after_install-claude-hooks.sh` が `hooks.json` を `~/.claude/settings.json` に jq でマージする。`settings.json` 自体は `.chezmoiignore` にあり chezmoi 管理外なので、マシンごとに他の設定を変えられる。

パスを絞って apply すると `run_after` は走らないため、その場合は手動で実行する。

```sh
chezmoi apply ~/.claude
bash ~/.local/share/chezmoi/run_after_install-claude-hooks.sh
```

フックを変更したらテストを実行する。

```sh
bash dot_claude/hooks/test/executable_run-tests.sh
```

`session-sync-global-memory.sh` が各プロジェクトの memory に同期する `~/.claude/memory-global/` は、このリポジトリには含まれない。存在しないマシンでは何もしない。

## Homebrew パッケージ

新しいマシンで一括インストールする場合。

```sh
brew install bat chezmoi eza fd fzf gh ghq git-delta jq mise neovim powerlevel10k ripgrep tree-sitter-cli zsh-syntax-highlighting
brew install --cask 1password-cli fig ghostty kiro kiro-cli
```
