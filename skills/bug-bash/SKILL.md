---
name: bug-bash
description: Work through bugs in BUGS.md one at a time using a structured workflow — GitHub issue, branch, diagnose, fix, smoke test, PR. Use when the user says "next bug", "bug bash", or invokes /bug-bash.
argument-hint: next | <bug description>
---

The user wants to work through a bug using the bug-bash workflow.

## Overview

Work through bugs in `BUGS.md` one at a time. Each bug gets:
- A GitHub issue for tracking
- A dedicated branch off main
- A diagnosis posted to the issue before any code is written
- Related bugs with the same root cause identified and bundled in
- A fix developed iteratively with the user
- A Playwright smoke test in `tests/playwright/`
- A clean lint + build
- A PR linked to the issue

## Step-by-step workflow

### 1. Start clean

```sh
git checkout main && git pull && npm install
```

If there are unstaged changes on main that are just formatting (Prettier), commit them before branching:
```sh
git add <files> && git commit -m "style: prettier formatting from remote main"
```

### 2. Pick the next bug

Read `BUGS.md`. Take the **first item that is not marked `[FIXED IN PRxx]`**. If the user specifies a bug, use that instead.

### 3. Check for in-flight work

Before claiming the bug, verify it isn't already being worked on:

```sh
gh issue list --state open
gh pr list --state open
```

If an open issue or PR already covers this bug, skip it and pick the next one. The issue is the canonical "claimed" signal — it exists before a branch is made, so checking issues catches the full window. This prevents two people from picking up the same bug when BUGS.md on `main` hasn't been updated yet (because the fix is still in a feature branch).

### 4. Create a GitHub issue

```sh
gh issue create --title "..." --body "..."
```

Body should include: Description, Expected behavior, Actual behavior, Steps to reproduce.

Note the issue number — you'll use it throughout.

### 5. Create a branch

```sh
git checkout -b fix/<short-description>
```

Branch naming: `fix/` prefix, lowercase, hyphen-separated. Example: `fix/onboarding-cache-clear`.

### 6. Diagnose before coding

**Read the relevant source files first.** Check git history to see if the bug was already fixed:

```sh
git log --oneline --all --grep="<keyword>" -i
git show <commit> --stat
```

If it was already fixed, verify with a smoke test, then close the issue and move on.

If it needs a fix, understand the root cause fully before writing any code.

### 7. Post diagnosis to GitHub issue

Before writing any code, post your diagnosis as a comment on the issue:

```sh
gh issue comment <N> --body "## Diagnosis\n\n..."
```

Include: root cause, affected file(s) and line numbers, proposed fix approach.

### 8. Check BUGS.md for related issues

Scan the remaining open items in `BUGS.md`. If any share the same root cause as the bug you just diagnosed:

- Update the GitHub issue title and body to reflect the broader scope
- List the related bugs explicitly in the issue
- Fix them all in this branch

```sh
gh issue edit <N> --title "..." --body "..."
```

This way all related bugs are tracked together and fixed atomically rather than discovered after the fact.

### 9. Fix the bug(s)

Make the minimum change needed. Follow all CLAUDE.md conventions:
- No `as any`, no `@ts-ignore`
- Types go in `src/types/index.ts`
- Mock data must match types
- No speculative abstractions

Iterate with the user as needed.

### 10. Write a Playwright smoke test

**All tests go in `tests/playwright/`** — never in `/tmp` or anywhere else.

Each test file should:
- Have a descriptive name (`test_<what_it_tests>.py`)
- Include a docstring with description, usage, and install instructions
- Use `python3 -m playwright install chromium` (not the bare `playwright` command)
- Be self-contained and runnable independently
- Assume the dev server is running at `http://localhost:5173`

After writing the test, add a row to the test table in `docs/DEVELOPER_BRIEF.md`:

```markdown
| `test_<name>.py` | What it covers |
```

### 11. Confirm the fix

Run the smoke test:

```sh
python3 tests/playwright/<test_file>.py
```

All checks must pass before proceeding.

### 12. Lint and build

Both must be clean before committing:

```sh
npm run format && npm run build
```

The chunk size warning is expected — ignore it.

### 13. Commit

```sh
git add <specific files>
git commit -m "fix: <description>\n\nCloses #<N>\n\nCo-Authored-By: ..."
```

Use conventional commit format: `fix:`, `feat:`, `docs:`, `refactor:`, `style:`.
Always include `Closes #<issue-number>` in the commit body.

### 14. Update BUGS.md

Mark the fixed item(s) inline — **do not move them to a separate section**:

```markdown
- [FIXED IN PR#<N>] ~~original bug description~~
```

The `[FIXED IN PR#N]` tag is NOT struck through — only the description is.

Commit this change:

```sh
git add BUGS.md && git commit -m "docs: mark bug(s) fixed in PR#<M>"
```

### 15. Push and file PR

```sh
git push -u origin fix/<branch-name>

gh pr create --title "fix: ..." --body "..."
```

PR body template:
```markdown
## Summary

- <bullet 1>
- <bullet 2>

Closes #<N>

## Test plan

- [ ] `python3 tests/playwright/<test>.py` passes
- [ ] <manual check if needed>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## Key conventions

- **Never write code before posting a diagnosis to the issue**
- **Always check git history before assuming the bug is unfixed**
- **Scan for related bugs right after diagnosis** — bundle them into the same issue and branch
- **Tests always go in `tests/playwright/`** — never `/tmp` or anywhere else
- **BUGS.md uses inline strikethrough** — `[FIXED IN PR#N] ~~description~~` — not a separate Fixed section
- **Branch off main** — never off another feature branch
- **One branch per bug** (or per tightly related cluster of bugs with the same root cause)
- **The `bugfix-workflow` branch** is a meta-branch for developing this skill — it is not a bug fix branch
- **Push only when creating a PR** — commit locally otherwise
- **Playwright install**: `python3 -m playwright install chromium` (the bare `playwright` command may not be on PATH)

## Project-specific notes (BeFriend app)

- Dev server: `npm run dev` at `http://localhost:5173`
- Mock mode: `VITE_USE_MOCK=true` in `.env` (currently `false` — real Supabase)
- Tests allowed without prompting: `python3 tests/playwright/*` (set in `.claude/settings.json`)
- Playwright test table lives in `docs/DEVELOPER_BRIEF.md` under "UI Smoke Tests (Playwright)"
- `BUGS.md` is in the project root
