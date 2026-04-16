---
name: timecard
description: Track work session time and write worklog entries. Use this skill whenever the user invokes /timecard start, /timecard stop, or /timecard restart — or asks to start a timer, clock in, stop tracking time, end a session, or restart the current session.
argument-hint: start | stop | restart
---

The user has invoked /timecard with arguments: $ARGUMENTS

## Active session file

The active session is stored at `~/.claude/timecard_active.json`. The schema is:

```json
{
  "start_iso": "<ISO timestamp, e.g. 2026-01-01T09:00:00>",
  "start_display": "<human-readable timestamp, e.g. 2026-01-01 09:00:00>",
  "git_user": "<output of git config user.name>",
  "project_dir": "<output of pwd -P>"
}
```

> ⚠️ **This is a schema example only — not real data.** Always read the actual file with the Read tool to get real values. Never use the values above as if they were live session data.

---

## /timecard start

1. Run `/compact` to compress the conversation context before starting the session.
2. Check whether `~/.claude/timecard_active.json` exists.
   - If it does, read it and output the following warning **as a prominent standalone message** — do not bury it in a paragraph:

     > **⚠️ Active session already exists**
     > Started: [start_display]
     > Project: [project_dir]
     >
     > **Keep the current session, or stop it and start a new one? (keep / stop)**

   - **STOP HERE.** Do not proceed until the user replies with "keep" or "stop". Do not interpret any other message as an answer — re-prompt if the response is ambiguous.
   - If they say **keep**: stop here, do nothing else.
   - If they say **stop**: run the stop flow (steps 1–6 of /timecard stop), then continue with step 3 below.
3. Get the current time: run `date '+%Y-%m-%dT%H:%M:%S'` (ISO) and `date '+%Y-%m-%d %H:%M:%S'` (readable).
4. Get the git user: `git config user.name`. If not in a git repo, use the system username.
5. Get the current directory: `pwd -P`.
6. Write `~/.claude/timecard_active.json` with those four values.
7. Confirm to the user: "Timecard started at [start_display]."

---

## /timecard stop

1. Check whether `~/.claude/timecard_active.json` exists. If not, tell the user there is no active session and stop.
2. Read the active session file.
3. Get the stop time: run `date '+%Y-%m-%dT%H:%M:%S'` and `date '+%Y-%m-%d %H:%M:%S'`.
4. Calculate elapsed time in hours and minutes (see Duration section below).
5. Write the worklog entry (see Worklog entry section below).
6. Delete `~/.claude/timecard_active.json`.
7. Confirm: "Session closed. Duration: [Xh Ym]. Worklog written to [filename]."

---

## /timecard restart

Run the stop flow (steps 1–6), then immediately run the start flow (steps 1–6). No confirmation prompt needed — the intent is clear. If there is no active session, skip the stop step and just start.

---

## Duration calculation

Use the bundled script: `scripts/duration.sh <start_iso> <stop_iso>`

It handles the macOS/Linux date difference and returns a formatted string like "2h 15m" or "45m".

---

## Worklog entry

Read `references/worklog_format.md` for the full template and instructions. Write the entry to the current working directory's `worklog/` folder.
