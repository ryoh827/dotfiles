alias ll='ls -lh'
alias la='ls -alh'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias mkdir='mkdir -p'

alias diff='diff -u'

alias h='history'

# グローバルエイリアス
alias -g L='| less'
alias -g G='| grep'

# vim to nvim
alias vim='nvim'
alias v='nvim'

alias g='git'
alias m='make'
alias b="brew"
alias d="docker"
alias c="claude"
alias cds='cd $(chezmoi source-path)'
alias dc='docker compose'
alias be='bundle exec'

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

if which rg >/dev/null 2>&1 ; then
  alias rg="rg --hidden -g '!.git/*' --glob '!node_modules/*' --glob '!vendor/*' --glob '!bower_components/*'"
fi
