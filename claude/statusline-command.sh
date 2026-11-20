#!/usr/bin/env bash
input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // empty')
dir="${cwd:-$PWD}"

model_id=$(echo "$input" | jq -r '.model.id // empty')
ctx_total=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')

ctx_part=""
if [ -n "$ctx_total" ] && [ -n "$ctx_size" ] && [ "$ctx_size" -gt 0 ] 2>/dev/null; then
  # Cap: env var > settings.json > unset (use raw model window)
  if [ -n "$CLAUDE_CODE_AUTO_COMPACT_WINDOW" ]; then
    cap="$CLAUDE_CODE_AUTO_COMPACT_WINDOW"
  else
    cap=$(jq -r '.autoCompactWindow // empty' ~/.claude/settings.json 2>/dev/null)
  fi

  if [ -n "$cap" ] && [ "$cap" -gt 0 ] 2>/dev/null && [ "$cap" -lt "$ctx_size" ] 2>/dev/null; then
    budget="$cap"
  else
    budget="$ctx_size"
  fi

  # Percentage against capped budget; not clamped — overshoot is real information.
  pct=$(echo "$ctx_total $budget" | awk '{printf "%.0f", $1 * 100 / $2}')

  apct="${CLAUDE_AUTOCOMPACT_PCT_OVERRIDE:-85}"
  headroom=20000
  compact_at=$(echo "$budget $headroom $apct" | awk '{
    b = $1 - $2
    opt1 = int(b * $3 / 100)
    opt2 = b - 13000
    print (opt1 < opt2) ? opt1 : opt2
  }')
  red_at=$(echo "$compact_at $budget" | awk '{printf "%.0f", $1 * 100 / $2}')
  yellow_at=$(( red_at - 15 ))

  # Color ONLY the number; no color below the yellow band.
  if   [ "$pct" -ge "$red_at" ] 2>/dev/null;    then num=$'\033[1;31m'"${pct}%"$'\033[0m'
  elif [ "$pct" -ge "$yellow_at" ] 2>/dev/null; then num=$'\033[1;33m'"${pct}%"$'\033[0m'
  else                                               num="${pct}%"
  fi
  ctx_part="ctx:${num}"
else
  # Fall back to pre-computed used_percentage for older CLI payloads.
  ctx_used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
  if [ -n "$ctx_used" ]; then
    pct=$(printf '%.0f' "$ctx_used")
    compact="${CLAUDE_AUTOCOMPACT_PCT_OVERRIDE:-92}"
    yellow_at=$(( compact - 20 ))
    red_at=$(( compact - 8 ))
    if   [ "$pct" -ge "$red_at" ];    then num=$'\033[1;31m'"${pct}%"$'\033[0m'
    elif [ "$pct" -ge "$yellow_at" ]; then num=$'\033[1;33m'"${pct}%"$'\033[0m'
    else                                   num="${pct}%"
    fi
    ctx_part="ctx:${num}"
  fi
fi

# Fetch enterprise spending limit utilization from /api/oauth/usage
spend_label=""
creds=$(security find-generic-password -s "Claude Code-credentials" -a "$(whoami)" -w 2>/dev/null)
if [ -n "$creds" ]; then
  spend_label=$(python3 -c "
import json, urllib.request
data = json.loads('''$creds''')
token = data['claudeAiOauth']['accessToken']
req = urllib.request.Request('https://claude.ai/api/oauth/usage')
req.add_header('Authorization', f'Bearer {token}')
req.add_header('User-Agent', 'claude-code/1.0')
req.add_header('Accept', 'application/json')
resp = urllib.request.urlopen(req, timeout=3)
result = json.loads(resp.read())
eu = result.get('extra_usage', {})
if eu.get('is_enabled'):
    used = eu.get('used_credits', 0) / 100
    limit = eu.get('monthly_limit', 0) / 100
    pct = eu.get('utilization', 0)
    print(f'{used:.0f}/{limit:.0f} ({pct:.0f}%)')
" 2>/dev/null)
fi

parts=""

parts="$ctx_part"
[ -n "$model_id" ]   && parts="${parts:+$parts  }model:${model_id}"
[ -n "$spend_label" ] && parts="${parts:+$parts  }spend:${spend_label}"

# Abbreviate $HOME as ~
case "$dir" in
  "$HOME")   disp="~" ;;
  "$HOME"/*) disp="~/${dir#$HOME/}" ;;
  *)         disp="$dir" ;;
esac

# Visible width, stripping ANSI color escapes
vis_len() {
  local stripped
  stripped=$(printf '%s' "$1" | sed $'s/\033\[[0-9;]*m//g')
  printf '%s' "${#stripped}"
}

max_width="${CLAUDE_STATUSLINE_WIDTH:-90}"
tail_w=$(vis_len "$parts")
[ -n "$parts" ] && sep_w=2 || sep_w=0
path_budget=$(( max_width - tail_w - sep_w ))

disp=$(awk -v path="$disp" -v budget="$path_budget" '
  # Extra params after seg are locals (awk convention) so they cannot
  # collide with the BEGIN-block variables of the same name below.
  function initial(seg,    out, slen, i, c, is_alnum, prev_alnum, keep, off, rest, s, e, digits) {
    # Mark Jira ticket keys (e.g. ABC-1234, under 7 digits) to keep whole.
    off = 0
    rest = seg
    while (match(rest, /[A-Z]+-[0-9]+/)) {
      s = off + RSTART
      e = s + RLENGTH - 1
      digits = RLENGTH - index(substr(rest, RSTART, RLENGTH), "-")
      # s == 1 tested explicitly: BSD awk returns the first char for substr(seg, 0, 1).
      if (digits < 7 && (s == 1 || substr(seg, s - 1, 1) !~ /[[:alnum:]]/) && substr(seg, e + 1, 1) !~ /[[:alnum:]]/)
        for (i = s; i <= e; i++) keep[i] = 1
      off = e
      rest = substr(seg, e + 1)
    }

    out = ""
    slen = length(seg)
    prev_alnum = 0
    for (i = 1; i <= slen; i++) {
      c = substr(seg, i, 1)
      if (i in keep) { out = out c; prev_alnum = 1; continue }
      is_alnum = (c ~ /[[:alnum:]]/)
      if (is_alnum) {
        if (!prev_alnum) out = out c
      } else {
        out = out c
      }
      prev_alnum = is_alnum
    }
    return out
  }
  function join(segs, from, to,    cur, j) {
    cur = segs[from]
    for (j = from + 1; j <= to; j++) cur = cur "/" segs[j]
    return cur
  }
  BEGIN {
    n = split(path, segs, "/")
    # Progressively initial segments left to right until it fits.
    for (k = 1; k <= n; k++) {
      cur = join(segs, 1, n)
      if (length(cur) <= budget) { print cur; exit }
      if (segs[k] != "" && segs[k] != "~") segs[k] = initial(segs[k])
    }
    cur = join(segs, 1, n)
    if (length(cur) <= budget) { print cur; exit }

    # Still too long: drop leftmost segments, prefix with an ellipsis.
    for (drop = 1; drop < n; drop++) {
      rest = join(segs, drop + 1, n)
      candidate = "\xe2\x80\xa6/" rest
      # Count the ellipsis glyph as 1 column, not its 3 UTF-8 bytes.
      visible_len = length(candidate) - 2
      if (visible_len <= budget || drop == n - 1) { print candidate; exit }
    }
    print cur
  }
')

if [ -n "$parts" ]; then
  printf "%s  %s" "$disp" "$parts"
else
  printf "%s" "$disp"
fi
