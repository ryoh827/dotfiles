#!/bin/bash
cmd="$(jq -r '.tool_input.command // empty')"

deny() {
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

reason_env="環境変数をまとめて出力するコマンド。トークンなどの値がツール結果としてLLMのコンテキストに入る"

if printf '%s' "$cmd" | grep -Eq '/proc/[^[:space:]]*/environ'; then
  deny "$reason_env"
fi

reason_pgrep="pgrep -f -l は macOS でプロセスの引数の後ろに環境変数まで出力する。PID だけなら pgrep -f <pattern>、名前だけなら pgrep -l <name>（-f なし）を使う。詳細は ps -o pid,command -p <pid>"
reason_ps="ps の e 修飾子 / -E は環境変数を出力する。ps -o pid,command -p <pid>、ps aux、ps -ef は環境変数を出さない"

while IFS= read -r seg; do
  read -ra t <<<"$seg"
  i=0
  while [ "$i" -lt "${#t[@]}" ]; do
    case "${t[$i]##*/}" in
      sudo) argopts=ugUChprtaD ;;
      exec) argopts=a ;;
      command | builtin | time | nohup | then | do | else | '!' | '{' | '\') argopts=' ' ;;
      [A-Za-z_]*=*)
        i=$((i + 1))
        continue
        ;;
      *) break ;;
    esac
    i=$((i + 1))
    while [ "$i" -lt "${#t[@]}" ]; do
      case "${t[$i]}" in
        -["$argopts"]) i=$((i + 2)) ;;
        -*) i=$((i + 1)) ;;
        *) break ;;
      esac
    done
  done
  [ "$i" -lt "${#t[@]}" ] || continue
  prog="${t[$i]##*/}"
  args=("${t[@]:$((i + 1))}")

  case "$prog" in
    printenv)
      deny "$reason_env"
      ;;
    env)
      has_cmd=0
      skip=0
      for a in "${args[@]}"; do
        if [ "$skip" -eq 1 ]; then
          skip=0
          continue
        fi
        case "$a" in
          -u | -C | --unset | --chdir) skip=1 ;;
          -S* | --split-string*) has_cmd=1 ;;
          -* | *=*) ;;
          *) has_cmd=1 ;;
        esac
      done
      [ "$has_cmd" -eq 1 ] || deny "$reason_env"
      ;;
    export | typeset | declare | readonly)
      has_name=0
      for a in "${args[@]}"; do
        case "$a" in
          -*[fF]*) has_name=1 ;;
          -*) ;;
          *) has_name=1 ;;
        esac
      done
      [ "$has_name" -eq 1 ] || deny "$reason_env"
      ;;
    set)
      [ "${#args[@]}" -gt 0 ] || deny "$reason_env"
      ;;
    pgrep)
      f=0
      l=0
      for a in "${args[@]}"; do
        case "$a" in
          --*) ;;
          -*)
            case "$a" in *f*) f=1 ;; esac
            case "$a" in *l*) l=1 ;; esac
            ;;
        esac
      done
      [ "$f" -eq 1 ] && [ "$l" -eq 1 ] && deny "$reason_pgrep"
      ;;
    ps)
      skip=0
      for a in "${args[@]}"; do
        if [ "$skip" -eq 1 ]; then
          skip=0
          continue
        fi
        case "$a" in
          --*) ;;
          -*E*) deny "$reason_ps" ;;
          -*[oOptuUgGCDMNW]) skip=1 ;;
          -*) ;;
          *[!A-Za-z]*) ;;
          *e*) deny "$reason_ps" ;;
        esac
      done
      ;;
  esac
done < <(printf '%s\n' "$cmd" | perl -0777 -pe 's/("(?:[^"\\]|\\.)*")|\x27[^\x27]*\x27/my $d = $1; defined $d && $d =~ m{\$\(|`} ? $d : "Q"/gse' | tr ';&|`()\n' '\n\n\n\n\n\n')
