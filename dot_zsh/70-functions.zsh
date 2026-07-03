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

function git-worktree-switch() {
  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Not inside a Git repository."
    return 1
  fi
  local wt=$(git worktree list --porcelain | awk '/^worktree /{print substr($0, 10)}' | fzf --header 'switch worktree')
  [[ -n $wt ]] && cd "$wt"
}
alias gw='git-worktree-switch'

function git-worktree-new() {
  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Not inside a Git repository."
    return 1
  fi
  local branch=$(git branch -a --format='%(refname:short)' | grep -v '/HEAD$' | sed 's#^origin/##' | sort -u | fzf --header 'branch (未一致なら新規作成)' --print-query | tail -1)
  [[ -z $branch ]] && return

  # git-common-dir はどの worktree から実行しても本体リポジトリを指すので、
  # worktree の中から実行しても命名が本体基準でぶれない
  local common_dir=$(git rev-parse --git-common-dir)
  [[ "$common_dir" != /* ]] && common_dir="$(pwd)/$common_dir"
  local repo_root=$(dirname "$common_dir")
  local dir="${repo_root}-${branch//\//-}"

  if git show-ref --verify --quiet "refs/heads/${branch}"; then
    git worktree add "$dir" "$branch" || return 1
  elif git show-ref --verify --quiet "refs/remotes/origin/${branch}"; then
    git worktree add --track -b "$branch" "$dir" "origin/${branch}" || return 1
  else
    git worktree add -b "$branch" "$dir" || return 1
  fi
  cd "$dir"
}
alias gwn='git-worktree-new'

function git-worktree-remove() {
  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Not inside a Git repository."
    return 1
  fi
  local main_dir=$(git worktree list --porcelain | awk '/^worktree /{print substr($0, 10); exit}')
  local current_dir=$(pwd)
  local wts=$(git worktree list --porcelain | awk '/^worktree /{print substr($0, 10)}' | tail -n +2 | fzf -m --header 'remove worktree(s)')
  [[ -z $wts ]] && return

  local removed_current=0
  local w
  for w in ${(f)wts}; do
    if git worktree remove "$w"; then
      echo "removed: $w"
      [[ "$current_dir" == "$w" || "$current_dir" == "$w"/* ]] && removed_current=1
    else
      echo "failed to remove: $w" >&2
    fi
  done

  # 今いた worktree を削除できた場合のみ本体リポジトリに戻る
  [[ $removed_current -eq 1 ]] && cd "$main_dir"
}
alias gwrm='git-worktree-remove'

function fzf-select-history() {
  BUFFER=$(history -n -r 1 | fzf --no-sort --query "$LBUFFER" --reverse)
  CURSOR=$#BUFFER
  zle reset-prompt
}
zle -N fzf-select-history
bindkey '^r' fzf-select-history
