#!/usr/bin/env bash
set -euo pipefail

if [ -z "${SLACK_WEBHOOK_URL:-}" ]; then
  exit 0
fi

payload="${1:-}"
if [ -z "$payload" ]; then
  exit 0
fi

event_type="$(printf '%s' "$payload" | jq -r '.type // ""' 2>/dev/null || true)"
if [ "$event_type" != "approval-requested" ]; then
  exit 0
fi

message_json="$(printf '%s' "$payload" | jq -c '
  . as $e
  | [
      "Codex approval requested",
      ($e.title // empty),
      ($e.message // empty),
      (if ($e.cwd // "") != "" then "wd: \($e.cwd)" else empty end),
      (if ($e.session_id // "") != "" then "session: \($e.session_id)" else empty end)
    ]
  | map(select(. != ""))
  | { text: join("\n") }
' 2>/dev/null || true)"

if [ -z "$message_json" ]; then
  exit 0
fi

curl -fsS -X POST \
  -H "Content-Type: application/json" \
  --data "$message_json" \
  "$SLACK_WEBHOOK_URL" >/dev/null 2>&1 || true
