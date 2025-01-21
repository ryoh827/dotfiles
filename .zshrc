# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.pre.zsh"
# License : MIT
# http://mollifier.mit-license.org/

########################################
# 環境変数
export LANG=ja_JP.UTF-8
export PATH="/usr/local/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"
export GOPATH=$HOME/go

# 色を使用出来るようにする
autoload -Uz colors
colors

# vim 風キーバインドにする
bindkey -v

# ヒストリの設定
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000

# 単語の区切り文字を指定する
autoload -Uz select-word-style
select-word-style default
# ここで指定した文字は単語区切りとみなされる
# / も区切りと扱うので、^W でディレクトリ１つ分を削除できる
zstyle ':zle:*' word-chars " /=;@:{},|"
zstyle ':zle:*' word-style unspecified

########################################
# 補完
# 補完機能を有効にする
autoload -Uz compinit
compinit

# 補完で小文字でも大文字にマッチさせる
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# ../ の後は今いるディレクトリを補完しない
zstyle ':completion:*' ignore-parents parent pwd ..

# sudo の後ろでコマンド名を補完する
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin \
                   /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin

# ps コマンドのプロセス名補完
zstyle ':completion:*:processes' command 'ps x -o pid,s,args'

########################################
# オプション
# 日本語ファイル名を表示可能にする
setopt print_eight_bit

# beep を無効にする
setopt no_beep

# フローコントロールを無効にする
setopt no_flow_control

# '#' 以降をコメントとして扱う
setopt interactive_comments

# ディレクトリ名だけでcdする
setopt auto_cd

# cd したら自動的にpushdする
setopt auto_pushd
# 重複したディレクトリを追加しない
setopt pushd_ignore_dups

# 同時に起動したzshの間でヒストリを共有する
setopt share_history

# 同じコマンドをヒストリに残さない
setopt hist_ignore_all_dups

# コマンドを随時追加する
setopt inc_append_history

# スペースから始まるコマンド行はヒストリに残さない
setopt hist_ignore_space

# ヒストリに保存するときに余分なスペースを削除する
setopt hist_reduce_blanks

# 高機能なワイルドカード展開を使用する
setopt extended_glob

setopt nonomatch

########################################
# エイリアス

alias ll='ls -lh'
alias la='ls -alh'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias mkdir='mkdir -p'

alias diff='diff -u'
if [[ -x `which delta` ]]; then
  alias diff='delta'
fi

alias h='history'

# sudo の後のコマンドでエイリアスを有効にする
alias sudo='sudo '

# グローバルエイリアス
alias -g L='| less'
alias -g G='| grep'

# vim to nvim
alias vim='nvim'
alias v='nvim'

alias g='git'
alias t='tig'
alias m='make'
alias b="brew"
alias d="docker"

# C で標準出力をクリップボードにコピーする
# mollifier delta blog : http://mollifier.hatenablog.com/entry/20100317/p1
if which pbcopy >/dev/null 2>&1 ; then
    # Mac
    alias -g C='| pbcopy'
elif which xsel >/dev/null 2>&1 ; then
    # Linux
    alias -g C='| xsel --input --clipboard'
elif which putclip >/dev/null 2>&1 ; then
    # Cygwin
    alias -g C='| putclip'
fi

# 補完
# for zsh-completions
fpath=(/usr/local/share/zsh-completions $fpath)
# 補完機能を有効にする
autoload -Uz compinit
compinit -u

########################################
# OS 別の設定
case ${OSTYPE} in
    darwin*)
        #Mac用の設定
        export CLICOLOR=1
        export LSCOLORS=gxfxcxdxbxegedabagacfd

        eval "$(/opt/homebrew/bin/brew shellenv)"
        eval "$(direnv hook zsh)"
        
        # alias
        if [[ -x `which trash` ]]; then
          alias rm="trash"
        fi

        export GO111MODULE=on
        export PATH="/opt/homebrew/opt/openssl/bin:$PATH"
        export PATH="/opt/homebrew/bin:$PATH"
        export PATH="$(brew --prefix openssl)/bin:$PATH"
        export PATH="$(brew --prefix readline)/bin:$PATH"
        export PATH="/Users/ryoh827/bin:$PATH"
        export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl)"

        eval "$(starship init zsh)"

        # plugins config
        source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

        # タブ名をカレントデュレクトリにする
        function chpwd() { echo -ne "\033]0;$(pwd | rev | awk -F \/ '{print $1}'| rev)\007"}
        ;;
    linux*)
        #Linux用の設定
        
        # brew
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

        # starship
        eval "$(starship init zsh)"

        # alias
        ;;
esac

if which mise >/dev/null 2>&1 ; then
  eval "$(mise activate zsh)"
fi

# 環境変数
export PATH="$(go env GOPATH)/bin:$PATH"

# alias
if [[ -x `which eza` ]]; then
  alias ls='eza --smart-group -F'
else
  alias ls='ls -G -F'
fi
if [[ -x `which bat` ]]; then
  alias cat="bat"
fi
if [[ -x `which rg` ]]; then
  alias grep='rg'
fi

function ghq-open() {
  local repo=$(ghq list --full-path | fzf --reverse)
  if [[ -n $repo ]]; then
    cd "$repo" || echo "Failed to cd into repository"
  fi
}
alias r='ghq-open'

function git-branch-switch() {
  # 現在のディレクトリが Git リポジトリか確認
  if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    # リモート/ローカル両方のブランチをリスト化
    local branch=$(git branch -a --sort=-committerdate | sed 's/^[* ] //' | fzf --reverse)
    if [[ -n $branch ]]; then
      # リモートブランチの場合、refs/remotes/origin/ を削除
      branch=$(echo $branch | sed 's#^remotes/origin/##')
      git checkout "$branch" || echo "Failed to switch to branch $branch"
    fi
  else
    echo "Not inside a Git repository."
  fi
}
alias br='git-branch-switch'

function fzf-select-history() {
  BUFFER=$(history -n -r 1 | fzf --query "$LBUFFER" --reverse)
  CURSOR=$#BUFFER
  zle reset-prompt
}
zle -N fzf-select-history
bindkey '^r' fzf-select-history

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.post.zsh"
