# claude-skills

Custom Claude Code skills.

## Install

```
/plugin marketplace add zenkat/claude-skills
```

Then reload:

```
/reload-plugins
```

## Skills

### bug-bash

Structured bug-fixing workflow — one bug at a time, with GitHub issues, dedicated branches, diagnosis before coding, Playwright smoke tests, and PRs.

Invoke with `/bug-bash` or just say "next bug" or "bug bash".

Expects a `BUGS.md` in the project root listing open bugs. Works with any project that uses GitHub and has a `tests/playwright/` directory for smoke tests.

### timecard

Track work session time and write worklog entries.

- `/timecard start` — start a session
- `/timecard stop` — end the session and write a worklog entry
- `/timecard restart` — stop and immediately start a new session

Worklogs are written to the `worklog/` folder in the current working directory.

Requires `scripts/duration.sh` (bundled) for cross-platform time calculation.
