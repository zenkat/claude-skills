#!/usr/bin/env bash
# UserPromptSubmit hook: injects current time into context.
# If an active timecard session exists and >30 min has passed since
# the last prompt, injects a gap alert asking the user if they want
# to close the session using the last-prompt time as the end time.

ACTIVE="$HOME/.claude/timecard_active.json"
LAST_PROMPT="$HOME/.claude/timecard_last_prompt.json"
NOW_ISO=$(date "+%Y-%m-%dT%H:%M:%S")
NOW_DISPLAY=$(date "+%Y-%m-%d %H:%M:%S")
CONTEXT="Current time: $NOW_DISPLAY"

if [ -f "$ACTIVE" ] && [ -f "$LAST_PROMPT" ]; then
  LAST_ISO=$(cat "$LAST_PROMPT")

  if [[ "$(uname)" == "Darwin" ]]; then
    LAST_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$LAST_ISO" +%s 2>/dev/null)
  else
    LAST_EPOCH=$(date -d "$LAST_ISO" +%s 2>/dev/null)
  fi

  NOW_EPOCH=$(date +%s)

  if [ -n "$LAST_EPOCH" ]; then
    GAP=$(( NOW_EPOCH - LAST_EPOCH ))
    if [ "$GAP" -gt 1800 ]; then
      H=$(( GAP / 3600 ))
      M=$(( (GAP % 3600) / 60 ))
      if [ "$H" -gt 0 ]; then
        GAP_STR="${H}h ${M}m"
      else
        GAP_STR="${M}m"
      fi
      LAST_DISPLAY="${LAST_ISO/T/ }"
      CONTEXT="Current time: $NOW_DISPLAY. GAP ALERT: The active timecard session has been idle for $GAP_STR (last prompt: $LAST_DISPLAY). Before responding to the user's message, ask them: \"You've been away for $GAP_STR (last active: $LAST_DISPLAY). Want to close out the current session using that time as the end time?\""
    fi
  fi
fi

# Update last-prompt timestamp
echo "$NOW_ISO" > "$LAST_PROMPT"

# Emit context injection
jq -n --arg ctx "$CONTEXT" \
  '{"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": $ctx}}'
