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

## 自動生成ファイルの更新例（Brewfile）

```sh
brew bundle dump --file=~/Brewfile --force
chezmoi add ~/Brewfile
chezmoi apply -v
```

## iTerm2 フォント

Dynamic Profile で以下のフォントを前提にしています。未インストールの場合は iTerm2 がフォールバックします。

- SauceCodeProNFM 14
- SauceCodeProNF 14

インストール例（macOS / Homebrew）:

```sh
brew tap homebrew/cask-fonts
brew install --cask font-sauce-code-pro-nerd-font
```
