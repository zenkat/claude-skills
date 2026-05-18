---
name: partner-update
description: Summarizes what your project partner has been doing on GitHub since the last time this skill was called (or the last 24 hours on first call). Use this skill whenever the user types /partner-update or asks "what has Janine been up to?" or "what has Brian been up to?" or "any updates from my partner?" or similar. Reports PRs waiting for review and merged PRs separately, in 2–3 sentences.
---

## What this skill does

Queries GitHub for the partner's recent activity on the BeFriendDev/befriend-app repo — commits, issues filed, PRs opened, PRs merged — since the last time the skill was called. Writes the current timestamp to `~/.claude/partner_last_check.json` after each run so the next call picks up exactly where this one left off.

---

## Partner mapping

The skill is symmetrical. Detect who is calling it, then look up the other person:

| Caller (gh login) | Partner (gh login) | Partner display name |
|---|---|---|
| `zenkat` | `BeFriendDev` | Janine |
| `BeFriendDev` | `zenkat` | Brian |

To get the caller's GitHub login:
```sh
gh api user --jq '.login'
```

If the login doesn't match either entry above, tell the user the skill isn't configured for their account and stop.

---

## State file

```
~/.claude/partner_last_check.json
```

Schema:
```json
{
  "last_check_iso": "2026-04-24T09:00:00Z"
}
```

- If the file doesn't exist or is missing `last_check_iso`, use **24 hours ago** as the default window.
- After generating the report, write the current UTC time to the file.

---

## Gathering activity

Use `gh` to query GitHub. All queries are scoped to `BeFriendDev/befriend-app` and filtered to actions by the partner's login since `<since_iso>`.

```sh
# Commits (across all branches, by partner)
gh api "repos/BeFriendDev/befriend-app/commits?author=<partner_login>&since=<since_iso>&per_page=100" \
  --jq '[.[] | {sha: .sha[0:7], message: .commit.message | split("\n")[0], date: .commit.author.date}]'

# Issues filed by partner
gh api "repos/BeFriendDev/befriend-app/issues?creator=<partner_login>&state=all&since=<since_iso>&per_page=100" \
  --jq '[.[] | select(.pull_request == null) | {number, title, state}]'

# PRs opened by partner (all states)
gh api "repos/BeFriendDev/befriend-app/pulls?state=all&per_page=100" \
  --jq '[.[] | select(.user.login == "<partner_login>" and .created_at >= "<since_iso>") | {number, title, state, merged_at}]'
```

From the PR list, derive two counts:
- **Waiting for review**: `state == "open"`
- **Merged**: `merged_at != null`

For the short summary, read the commit messages and PR titles — infer 1–3 words capturing the theme (e.g., "the matching algorithm", "onboarding flow fixes", "the auth refactor").

---

## Output format

**If there is activity:**
> Since you last connected, [Name] was primarily working on [SHORT_SUMMARY]. She/He filed [N] issue(s) and has [N] PR(s) waiting for your review and [N] PR(s) merged.

- Omit the issues clause if N=0.
- Omit either PR clause if its count is 0.
- Use "She" for Janine, "He" for Brian.

**If there is no activity:**
> [Name] hasn't done anything since your last session.

Keep the output to 2–3 sentences maximum. Don't list individual commits or PRs — just the counts and theme.

---

## After generating the report

Write the current UTC time to `~/.claude/partner_last_check.json`:

```sh
date -u '+%Y-%m-%dT%H:%M:%SZ'
```

Then output the report to the user.
