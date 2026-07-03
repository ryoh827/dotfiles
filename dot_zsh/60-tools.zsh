if which mise >/dev/null 2>&1 ; then
  eval "$(mise activate zsh)"
fi

export PATH="$(go env GOPATH)/bin:$PATH"

if [[ -x `which eza` ]]; then
  alias ls='eza --smart-group -F'
else
  alias ls='ls -G -F'
fi
