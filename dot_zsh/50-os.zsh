case ${OSTYPE} in
    darwin*)
        export CLICOLOR=1
        export LSCOLORS=gxfxcxdxbxegedabagacfd

        eval "$(/opt/homebrew/bin/brew shellenv)"

        if [[ -x `which trash` ]]; then
          alias rm="trash"
        fi

        export GO111MODULE=on
        export PATH="/opt/homebrew/opt/openssl/bin:$PATH"
        export PATH="/opt/homebrew/bin:$PATH"
        export PATH="$(brew --prefix openssl)/bin:$PATH"
        export PATH="$(brew --prefix readline)/bin:$PATH"
        export PATH="$HOME/bin:$PATH"
        export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl)"

        if [[ -r "$(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
          source "$(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme"
        fi
        if [[ -r "$HOME/.p10k.zsh" ]]; then
          source "$HOME/.p10k.zsh"
        fi

        # plugins config
        source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

        # タブ名をカレントデュレクトリにする
        function chpwd() { echo -ne "\033]0;$(pwd | rev | awk -F \/ '{print $1}'| rev)\007"}
        ;;
    linux*)
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

        if [[ -r "$(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
          source "$(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme"
        fi
        if [[ -r "$HOME/.p10k.zsh" ]]; then
          source "$HOME/.p10k.zsh"
        fi
        ;;
esac
