if which mise >/dev/null 2>&1 ; then
  eval "$(mise activate zsh)"
fi

export PATH="$GOPATH/bin:$PATH"

if command -v eza >/dev/null 2>&1; then
  alias ls='eza --smart-group -F'
else
  case ${OSTYPE} in
    darwin*) alias ls='ls -G -F' ;;
    linux*) alias ls='ls --color=auto -F' ;;
  esac
fi
