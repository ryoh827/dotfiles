#!/bin/bash
cmd="$(jq -r '.tool_input.command // empty')"

deny() {
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

if printf '%s' "$cmd" | grep -Eq '/proc/[^[:space:]]*/environ'; then
  deny "/proc/*/environ は環境変数（トークン等）を出力する。必要な変数名の有無は [ -n \"\${NAME:-}\" ] && echo set のように値を出さずに確認する"
fi

if printf '%s' "$cmd" | grep -Eq '(^|[^[:alnum:]_])(echo|printf)[[:space:]][^;&|]*\$\{?[A-Za-z0-9_]*(TOKEN|SECRET|PASSWORD|PASSWD|API_KEY|PRIVATE_KEY|CREDENTIAL)[A-Za-z0-9_]*'; then
  deny "秘密情報を含む変数の値を出力するコマンド。値は出さず [ -n \"\${NAME:-}\" ] && echo set のように有無だけ確認する"
fi

reason_env="環境変数（トークン等）がツール結果としてLLMのコンテキストに入る。変数の有無は [ -n \"\${NAME:-}\" ] && echo set で値を出さずに確認する"
reason_pgrep="pgrep -f -l は macOS でプロセスの引数の後ろに環境変数まで出力する。PID だけなら pgrep -f <pattern>、名前だけなら pgrep -l <name>（-f なし）を使う。詳細は ps -o pid,command -p <pid>"
reason_ps="ps の e 修飾子 / -E は環境変数を出力する。ps -o pid,command -p <pid>、ps aux、ps -ef は環境変数を出さない"

while IFS= read -r seg; do
  read -ra t <<<"$seg"
  i=0
  while [ "$i" -lt "${#t[@]}" ]; do
    case "${t[$i]##*/}" in
      sudo | command | builtin | exec | time | nohup | '\') i=$((i + 1)) ;;
      *) break ;;
    esac
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
      for a in "${args[@]}"; do
        case "$a" in
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
done < <(printf '%s\n' "$cmd" | tr ';&|`()\n' '\n\n\n\n\n\n')
