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

## Homebrew パッケージ

新しいマシンで一括インストールする場合。

```sh
brew install bat chezmoi eza fd fzf gh ghq git-delta jq mise neovim powerlevel10k ripgrep tree-sitter-cli zsh-syntax-highlighting
brew install --cask 1password-cli fig ghostty kiro kiro-cli
```
