#!/usr/bin/env bash
input=$(cat)

repo=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""' | xargs basename)
model=$(echo "$input" | jq -r '.model.display_name // empty')
pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | awk '{printf "%.0f", $1}')
tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
five_h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')

# Context bar
filled=$(( pct * 10 / 100 ))
empty=$(( 10 - filled ))
bar=""
for i in $(seq 1 $filled 2>/dev/null); do bar="${bar}▓"; done
for i in $(seq 1 $empty 2>/dev/null); do bar="${bar}░"; done

# Token format
tok_fmt=$(awk "BEGIN{ t=$tokens; if(t>=1000) printf \"%.1fk\", t/1000; else printf \"%d\", t }")

# Cost format
cost_fmt=$(awk "BEGIN{ printf \"\$%.3f\", $cost }")

# Colors
CYAN=$'\033[1;36m'
DIM=$'\033[2;37m'
BLUE=$'\033[0;34m'
YELLOW=$'\033[0;33m'
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
RESET=$'\033[0m'

# Bar color based on usage
if   [ "$pct" -ge 80 ]; then BARCOLOR=$RED
elif [ "$pct" -ge 50 ]; then BARCOLOR=$YELLOW
else                         BARCOLOR=$GREEN
fi

# Build output
out="${CYAN}⚡ ${repo}${RESET}"
[ -n "$model" ] && out="$out | ${DIM}${model}${RESET}"
out="$out | ${BARCOLOR}${bar} ${pct}%${RESET}"
[ "$tokens" -gt 0 ] 2>/dev/null && out="$out | ${BLUE}${tok_fmt} tok${RESET}"
[ "$cost" != "0" ]               && out="$out | ${YELLOW}${cost_fmt}${RESET}"
[ -n "$five_h" ]                 && out="$out | ${RED}⚠ 5h:$(printf '%.0f' "$five_h")%${RESET}"

printf "%b\n" "$out"
