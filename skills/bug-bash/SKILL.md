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

### 3. Create a GitHub issue

```sh
gh issue create --title "..." --body "..."
```

Body should include: Description, Expected behavior, Actual behavior, Steps to reproduce.

Note the issue number — you'll use it throughout.

### 4. Create a branch

```sh
git checkout -b fix/<short-description>
```

Branch naming: `fix/` prefix, lowercase, hyphen-separated. Example: `fix/onboarding-cache-clear`.

### 5. Diagnose before coding

**Read the relevant source files first.** Check git history to see if the bug was already fixed:

```sh
git log --oneline --all --grep="<keyword>" -i
git show <commit> --stat
```

If it was already fixed, verify with a smoke test, then close the issue and move on.

If it needs a fix, understand the root cause fully before writing any code.

### 6. Post diagnosis to GitHub issue

Before writing any code, post your diagnosis as a comment on the issue:

```sh
gh issue comment <N> --body "## Diagnosis\n\n..."
```

Include: root cause, affected file(s) and line numbers, proposed fix approach.

### 7. Check BUGS.md for related issues

Scan the remaining open items in `BUGS.md`. If any share the same root cause as the bug you just diagnosed:

- Update the GitHub issue title and body to reflect the broader scope
- List the related bugs explicitly in the issue
- Fix them all in this branch

```sh
gh issue edit <N> --title "..." --body "..."
```

This way all related bugs are tracked together and fixed atomically rather than discovered after the fact.

### 8. Fix the bug(s)

Make the minimum change needed. Do not add features, refactor surrounding code, or add speculative abstractions. Fix the specific bug.

Iterate with the user as needed.

### 9. Write a Playwright smoke test

**All tests go in `tests/playwright/`** — never in `/tmp` or anywhere else.

Each test file should:
- Have a descriptive name (`test_<what_it_tests>.py`)
- Include a docstring with description, usage, and install instructions
- Use `python3 -m playwright install chromium` (not the bare `playwright` command)
- Be self-contained and runnable independently

After writing the test, add a row to the test table in the project's developer documentation.

### 10. Confirm the fix

Run the smoke test:

```sh
python3 tests/playwright/<test_file>.py
```

All checks must pass before proceeding.

### 11. Lint and build

Both must be clean before committing. Run whatever lint and build commands the project uses (e.g. `npm run format && npm run build`).

### 12. Commit

```sh
git add <specific files>
git commit -m "fix: <description>

Closes #<N>

Co-Authored-By: ..."
```

Use conventional commit format: `fix:`, `feat:`, `docs:`, `refactor:`, `style:`.
Always include `Closes #<issue-number>` in the commit body.

### 13. Update BUGS.md

Mark fixed items inline — **do not move them to a separate section**.

For bugs that required a code fix:
```markdown
- [FIXED IN PR#<N>] ~~original bug description~~
```

For bugs that were investigated and found to already be working:
```markdown
- [CANNOT REPRODUCE #<N>] original bug description
```

The `[FIXED IN PR#N]` / `[CANNOT REPRODUCE #N]` tag is NOT struck through. For fixed bugs, only the description gets strikethrough.

Commit this change:

```sh
git add BUGS.md && git commit -m "docs: mark bug(s) fixed in PR#<M>"
```

### 14. Push and file PR

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
- **BUGS.md uses inline markers** — `[FIXED IN PR#N] ~~description~~` for fixed bugs, `[CANNOT REPRODUCE #N]` (no strikethrough) for bugs that were already working
- **Branch off main** — never off another feature branch
- **One branch per bug** (or per tightly related cluster of bugs with the same root cause)
- **Push only when creating a PR** — commit locally otherwise
- **Playwright install**: `python3 -m playwright install chromium` (the bare `playwright` command may not be on PATH)
