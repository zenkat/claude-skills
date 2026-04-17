---
name: pr-review
description: Address review comments on an open PR. Read all comments, engage in dialog with the author on points of disagreement, then implement agreed-upon fixes and update the PR. Use when the user says "address PR comments", "respond to review", or invokes /pr-review.
argument-hint: <PR number>
---

The user wants to address review comments on a pull request.

Take the role of a **respectful Staff SWE**: listen carefully to the reviewer's feedback, but do not accept it uncritically. Engage in dialog on points of disagreement or nuance. If you agree with a comment, just do the fix. If you disagree or see important tradeoffs, explain your reasoning and propose an alternative. Only implement changes after reaching agreement.

## Step-by-step workflow

### 1. Verify clean state

Before reading anything, make sure you are on the right branch and there are no surprises:

```sh
git checkout <branch>
git status
git log origin/main..main --oneline   # must be empty — no unpushed main commits
```

If `git log origin/main..main` shows unpushed commits on main (e.g. a formatting cleanup), push them first:

```sh
git push origin main
```

An unpushed main commit becomes part of the PR's diff if you branch before pushing it. This is the root cause of "noisy diff" issues — prevent it here, not after the fact.

### 2. Read all comments

Pull both top-level review comments and inline file comments:

```sh
gh pr view <N> --comments
gh api repos/<owner>/<repo>/pulls/<N>/comments --jq '.[] | {id, path, line, body, diff_hunk}'
```

Also check the PR's current diff to understand exactly what the reviewer sees:

```sh
git diff origin/main...<branch> --stat
gh api repos/<owner>/<repo>/pulls/<N>/files --jq '.[] | {filename, additions, deletions}'
```

The API diff is authoritative — it shows exactly what GitHub computed, regardless of what you expect locally. If the diff contains unexpected content (e.g. formatting changes from a separate commit), diagnose why before assuming it's a reviewer error.

### 3. Categorize comments before responding to any

Read all comments as a group. For each one, decide:

- **Agree — straightforward fix**: note it, implement after dialog is complete
- **Agree — but not in this PR**: push back on scope, propose a follow-up issue/branch
- **Disagree or nuance needed**: engage in dialog before touching any code
- **Red herring / misread diff**: explain what the reviewer is actually seeing

Do not respond to comments one by one in isolation — read the full set first so related comments can be addressed coherently.

### 4. Engage in dialog

For any comment that isn't a straightforward fix, reply inline before making any changes:

```sh
cat > /tmp/gh_body.md << 'EOF'
...your response...
EOF
gh api repos/<owner>/<repo>/pulls/comments/<comment_id>/replies -f body="$(cat /tmp/gh_body.md)"
```

**Always use `--body-file` or `-f body=` for multi-line content** — never `--body "..."` with inline text. Backticks, special characters, and newlines in inline `--body` strings are interpreted by the shell, corrupting the output.

Be direct. If you disagree, say why. If the reviewer's concern is valid but the fix belongs in a different PR, say so and propose a concrete follow-up (e.g. a dedicated refactor issue).

Wait for the user to respond before implementing anything that's under discussion.

### 5. Implement agreed-upon fixes

After all dialog is resolved, make the minimum changes needed. Follow the project's CLAUDE.md conventions. Run format and build before committing:

```sh
npm run format && npm run build
```

Commit with a clear message referencing the PR:

```sh
git add <specific files>
git commit -m "fix: address PR#<N> review feedback — <short description>"
```

Push:

```sh
git push origin <branch>
```

### 6. Resolve each comment

For comments that required code changes, reply inline confirming what was done. For comments resolved by discussion (no code change needed), a reply explaining the resolution is sufficient — not every comment requires a code change.

```sh
cat > /tmp/gh_body.md << 'EOF'
...confirmation or explanation...
EOF
gh api repos/<owner>/<repo>/pulls/comments/<comment_id>/replies -f body="$(cat /tmp/gh_body.md)"
```

## Key conventions

- **Read all comments before responding to any** — batch your understanding, then engage
- **Dialog before code** — never implement a disputed change before reaching agreement
- **Inline replies only** — respond on the specific comment thread, not as a new top-level comment
- **Not every comment requires a code change** — explanation is a valid and complete resolution
- **Always use `--body-file`** for any `gh` command with multi-line content
- **Verify clean main before starting** — `git log origin/main..main` must be empty
- **Check the API diff** — `gh api .../pulls/<N>/files` tells you exactly what GitHub computed; use it when a reviewer sees something unexpected

## Common situations

**Reviewer flags something that's already in main:**
The diff is noisy because the PR's stored base SHA predates a commit that was pushed to main after the PR was created. Explain this. The fix is prevention (push main before branching), not surgery after the fact.

**Reviewer asks for a refactor that's out of scope:**
Agree with the end goal, push back on doing it in this PR. Propose a dedicated follow-up branch/issue with a clear name (e.g. `refactor/consolidate-photo-fields`).

**Reviewer is factually wrong:**
Point it out directly but respectfully, with evidence (line numbers, git log, API output). Don't just silently implement what they asked.
