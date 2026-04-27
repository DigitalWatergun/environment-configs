---
allowed-tools: Bash, Read, Glob, Grep
description: Stage, commit, and open PRs for all repos with changes
---

Ship the current work across all modified repositories.

## Step 1: Discover modified repos

Find all git repositories under the current directory that have uncommitted changes:

```
for dir in */; do
  if [ -d "$dir/.git" ]; then
    changes=$(git -C "$dir" status --porcelain)
    if [ -n "$changes" ]; then
      echo "$dir"
    fi
  fi
done
```

If no repos have changes, report that and stop.

## Step 2: Confirm scope

Present the list of repos with changes and ask the user to confirm which ones to include. Show a brief summary for each:

- Repo name
- Branch
- Number of changed files
- A one-line description of the changes

Wait for confirmation before proceeding. The user may remove repos from the list or say "all" to continue with everything.

## Step 3: For each confirmed repo

Working inside each repo directory (using `git -C <repo>` or `cd <repo>`):

1. Run `git status` and `git diff --stat` to understand what changed
2. Generate a commit message following Conventional Commits:
   - Format: `type(scope): description` or `type: description`
   - Valid types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
   - Subject line MUST be 72 characters or fewer
   - Verify length by running: `echo -n "<subject line>" | wc -c`
   - If over 72, rewrite it shorter and re-verify
   - If more detail is needed, add a blank line then a body (wrap at 72 chars per line)
3. Stage changes with `git add`
4. Commit with the generated message
5. Push the current branch to origin
6. Use `gh pr create` to open a pull request with:
   - Title matching the commit subject line
   - Body summarizing what changed and why

## Step 4: Summary

After processing all repos, present a summary table:

- Repo name
- Branch
- Commit message
- PR link

If $ARGUMENTS is provided, use it as additional context for all commit messages and PR descriptions. If $ARGUMENTS specifies repo names, skip discovery and only ship those repos.
