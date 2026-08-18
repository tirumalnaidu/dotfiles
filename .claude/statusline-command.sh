#!/bin/bash
# Claude Code status line: uncommitted diff totals, context used %, rate
# limits, and the PR/MR for the current branch (as a clickable OSC 8 link).
input=$(cat)

ESC=$'\033'
RESET="${ESC}[0m"

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')

added=0
deleted=0
if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # Diff against HEAD covers staged + unstaged edits to tracked files; binary
  # files report "-" for line counts and are skipped rather than miscounted.
  read -r added deleted <<< "$(git -C "$cwd" --no-optional-locks diff HEAD --numstat 2>/dev/null \
    | awk '{a+=($1=="-"?0:$1); d+=($2=="-"?0:$2)} END {print a+0, d+0}')"
fi

used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_hr=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_day=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

pr_num=$(echo "$input" | jq -r '.pr.number // empty')
pr_url=$(echo "$input" | jq -r '.pr.url // empty')
pr_kind=$(echo "$input" | jq -r '.pr.kind // empty')
pr_state=$(echo "$input" | jq -r '.pr.review_state // empty')

out=""
if [ "$added" != "0" ] || [ "$deleted" != "0" ]; then
  diffstat="${ESC}[32m+${added}${RESET}/${ESC}[31m-${deleted}${RESET}"
  [ -n "$out" ] && out="$out | $diffstat" || out="$diffstat"
fi
if [ -n "$used" ]; then
  ctx="${ESC}[2mctx $(printf '%.0f' "$used")%${RESET}"
  [ -n "$out" ] && out="$out | $ctx" || out="$ctx"
fi
if [ -n "$five_hr" ]; then
  five="${ESC}[2m5h $(printf '%.0f' "$five_hr")%${RESET}"
  [ -n "$out" ] && out="$out | $five" || out="$five"
fi
if [ -n "$seven_day" ]; then
  week="${ESC}[2m7d $(printf '%.0f' "$seven_day")%${RESET}"
  [ -n "$out" ] && out="$out | $week" || out="$week"
fi
if [ -n "$pr_num" ]; then
  if [ "$pr_kind" = "mr" ]; then label="MR !${pr_num}"; else label="PR #${pr_num}"; fi
  case "$pr_state" in
    approved) color="${ESC}[32m" ;;
    changes_requested) color="${ESC}[31m" ;;
    draft) color="${ESC}[2m" ;;
    *) color="${ESC}[33m" ;;
  esac
  # OSC 8 hyperlink: label is all that shows, click opens the PR/MR page.
  # Terminals without OSC 8 support just swallow the escapes and print the label.
  link="${color}${ESC}]8;;${pr_url}${ESC}\\${label}${ESC}]8;;${ESC}\\${RESET}"
  [ -n "$out" ] && out="$out | $link" || out="$link"
fi

printf '%s' "$out"
