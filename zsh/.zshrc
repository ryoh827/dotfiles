# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.pre.zsh"
# License : MIT
# http://mollifier.mit-license.org/

########################################
# 環境変数
export LANG=ja_JP.UTF-8
export PATH="/usr/local/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"

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
# vcs_info
#autoload -Uz vcs_info
#autoload -Uz add-zsh-hook

#zstyle ':vcs_info:*' formats '%F{green}(%s)-[%b]%f'
#zstyle ':vcs_info:*' actionformats '%F{red}(%s)-[%b|%a]%f'

#function _update_vcs_info_msg() {
#    LANG=en_US.UTF-8 vcs_info
#    RPROMPT="${vcs_info_msg_0_}"
#}
#add-zsh-hook precmd _update_vcs_info_msg


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
# キーバインド

# ^R で履歴検索をするときに * でワイルドカードを使用出来るようにする
# bindkey '^R' history-incremental-pattern-search-backward

########################################
# エイリアス

alias ll='ls -lh'
alias la='ls -alh'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias mkdir='mkdir -p'

alias diff='diff -u'
if [[ -x `which colordiff` ]]; then
  alias diff='colordiff -u'
fi

alias h='history'

alias atssh='ssh -i ~/.ssh/atfreaks/id_rsa'
alias atscp='scp -i ~/.ssh/atfreaks/id_rsa'

# sudo の後のコマンドでエイリアスを有効にする
alias sudo='sudo '

# グローバルエイリアス
alias -g L='| less'
alias -g G='| grep'

# vim to nvim
alias vim='nvim'

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

#alias brew="env PATH=${${PATH/\/Users\/ryota\/anaconda\/bin:/}/\/Users\/ryota\/.anyenv\/envs\/pyenv\/shims:/} brew"

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
        #export LSCOLORS=gxfxcxdxbxegexabagacad
        export LSCOLORS=gxfxcxdxbxegedabagacfd
        export PATH="/usr/local/opt/icu4c/bin:$PATH"
        export PATH="/usr/local/opt/icu4c/sbin:$PATH"
        export PATH="/usr/local/texlive/2018/bin/x86_64-darwin:$PATH"

        eval "$(/opt/homebrew/bin/brew shellenv)"
        eval "$(direnv hook zsh)"
        
        # alias
        alias ls='ls -G -F'
        alias rm="trash"

        export PHP_BUILD_CONFIGURE_OPTS="--with-openssl=$(brew --prefix openssl) --with-libxml-dir=$(brew --prefix libxml2)"
        export GOPATH="$HOME/work/go"
        export PATH="$PATH:$GOPATH/bin"
        export GO111MODULE=on
        export PATH="/opt/homebrew/opt/openssl@1.1/bin:$PATH"
        export PATH="/opt/homebrew/bin:$PATH"
        export PATH="$(brew --prefix openssl@1.1)/bin:$PATH"
        export PATH="$(brew --prefix readline)/bin:$PATH"
        export PATH="/Users/ryoh827/bin:$PATH"
        export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"
        export LDFLAGS="-L/opt/homebrew/opt/libedit/lib"
        export CPPFLAGS="-I/opt/homebrew/opt/libedit/include"
        export PKG_CONFIG_PATH="/opt/homebrew/opt/libedit/lib/pkgconfig"

        eval "$(anyenv init -)"
        [[ -e ~/.phpbrew/bashrc ]] && source ~/.phpbrew/bashrc

        #autoload -U promptinit; promptinit
        #prompt pure
        eval "$(starship init zsh)"

        function peco-select-history() {
            BUFFER=$(\history -n -r 1 | peco --query "$LBUFFER")
            CURSOR=$#BUFFER
            zle clear-screen
        }
        zle -N peco-select-history
        bindkey '^r' peco-select-history

        function peco-src () {
          local selected_dir=$(ghq list -p | peco --query "$LBUFFER")
          if [ -n "$selected_dir" ]; then
            BUFFER="cd ${selected_dir}"
            zle accept-line
          fi
          zle clear-screen
        }
        zle -N peco-src
        bindkey '^G' peco-src

        # pnpm
        export PNPM_HOME="/Users/ryoh827/Library/pnpm"
        case ":$PATH:" in
          *":$PNPM_HOME:"*) ;;
          *) export PATH="$PNPM_HOME:$PATH" ;;
        esac
        # pnpm end
        
        # Fig post block. Keep at the bottom of this file.
        [[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.post.zsh"

        # plugins config
        source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

        # asdf
        . $(brew --prefix asdf)/libexec/asdf.sh

        # タブ名をカレントデュレクトリにする
        function chpwd() { echo -ne "\033]0;$(pwd | rev | awk -F \/ '{print $1}'| rev)\007"}

        ;;
    linux*)
        #Linux用の設定
        alias ls='ls -F --color=auto'
        PROMPT="%{${fg[green]}%}[%n@%m]%{${reset_color}%} %~
%# "
        . "$HOME/.asdf/asdf.sh"
        # append completions to fpath
        fpath=(${ASDF_DIR}/completions $fpath)
        # initialise completions with ZSH's compinit
        autoload -Uz compinit && compinit
        ;;
esac


