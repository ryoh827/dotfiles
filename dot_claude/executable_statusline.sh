#!/usr/bin/env bash
set -uo pipefail

input=$(cat)

workspace_dir=$(printf '%s' "$input" | jq -r '.workspace.project_dir // .cwd')
current_dir=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd')
session_cost=$(printf '%s' "$input" | jq -r '.cost.total_cost_usd // 0')
context_pct=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // 0')

location=$(basename "$workspace_dir")
branch=$(git -C "$current_dir" branch --show-current 2>/dev/null)
if [ -n "$branch" ]; then
  location="$location ⎇ $branch"
fi

month_cost=$(ccusage monthly --json --offline --since "$(date +%Y%m01)" 2>/dev/null | jq -r '.totals.totalCost // empty')

if [ -n "$month_cost" ]; then
  month_display=$(printf '$%.2f' "$month_cost")
else
  month_display='n/a'
fi

printf '📁 %s | 💰 $%.2f | 📅 %s | %s%% context used\n' "$location" "$session_cost" "$month_display" "$context_pct"
