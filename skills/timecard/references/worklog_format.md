# Worklog Format

Use this template when writing a worklog entry on `/timecard stop`.

## Filename

```
worklog/YYYYMMDD_HHMMSS_<git_user>.md
```

Where the timestamp is the **stop time**, and `git_user` comes from `~/.claude/timecard_active.json`.

## Template

```markdown
# Session Worklog — YYYY-MM-DD

**Started:** YYYY-MM-DD HH:MM:SS
**Ended:** YYYY-MM-DD HH:MM:SS
**Duration:** Xh Ym

## Summary

[Plain-language summary of what was done this session and why. Focus on decisions and reasoning, not just file names.]

### What was done

[One subsection per meaningful area of work. Be concrete and specific.]

## Commits

- `abc1234` commit message here
- `def5678` another commit message

## Open items going into next session

- Item one
- Item two
```

## How to fill it in

1. Run `git log --oneline --after="<start_iso>"` to get commits made during the session.
2. Review the conversation history to reconstruct what was done and why.
3. Write the summary the way the existing worklogs in this project are written — concrete, explains reasoning, not a changelog.
4. List anything unresolved or deferred as open items.
