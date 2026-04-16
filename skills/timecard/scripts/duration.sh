#!/usr/bin/env bash
# Usage: duration.sh <start_iso> <stop_iso>
# Both timestamps in format: 2026-04-10T14:30:00
# Prints elapsed time as "2h 15m" or "45m"

START_ISO="$1"
STOP_ISO="$2"

if [[ "$(uname)" == "Darwin" ]]; then
  start_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$START_ISO" +%s)
  stop_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$STOP_ISO" +%s)
else
  start_epoch=$(date -d "$START_ISO" +%s)
  stop_epoch=$(date -d "$STOP_ISO" +%s)
fi

elapsed=$(( stop_epoch - start_epoch ))
hours=$(( elapsed / 3600 ))
minutes=$(( (elapsed % 3600) / 60 ))

if (( hours > 0 )); then
  echo "${hours}h ${minutes}m"
else
  echo "${minutes}m"
fi
