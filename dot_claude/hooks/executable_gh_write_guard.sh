#!/bin/bash
cmd="$(jq -r '.tool_input.command // empty')"
if echo "$cmd" | grep -Eq '(^|[;&|]|&&)[[:space:]]*gh[[:space:]]+api[[:space:]].*/comments([[:space:]/]|$).*(-f[[:space:]]|-F[[:space:]]|--method[[:space:]]+(POST|PATCH|DELETE|PUT)|--method=(POST|PATCH|DELETE|PUT))' \
  || echo "$cmd" | grep -Eq '(^|[;&|]|&&)[[:space:]]*gh[[:space:]]+pr[[:space:]]+comment([[:space:]]|$)' \
  || echo "$cmd" | grep -Eq '(^|[;&|]|&&)[[:space:]]*gh[[:space:]]+pr[[:space:]]+review([[:space:]]|$)' \
  || echo "$cmd" | grep -Eq '(^|[;&|]|&&)[[:space:]]*gh[[:space:]]+pr[[:space:]]+edit[[:space:]].*--body'; then
  jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:"GitHub PRへの投稿/編集系コマンドを検知。事前にユーザーへ確認してから実行する（memory: ask-before-proceeding-with-open-questions）"}}'
fi
