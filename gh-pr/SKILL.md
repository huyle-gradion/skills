---
name: gh-pr
description: Author and manage GitHub pull requests end-to-end. Detects whether an open PR already exists on the current branch to route between opening a new PR, committing and pushing incremental updates to an open PR, addressing F1/P1 review findings with inline SHA replies, or rebasing in a merge order. Use when opening a PR, committing and pushing new changes to an existing PR, fixing review comments, or rebasing a PR.
---

# GitHub pull request author workflow (`gh-pr`)

Run the author side of a GitHub pull request by inspecting branch and PR state first, then executing the matching mode:
- **Mode 1. Open a new pull request** when no open PR exists for the current branch.
- **Mode 2. Commit and push updates to an open pull request** when an open PR already exists and new local changes or commits need to land on it.
- **Mode 3. Address review findings and reply inline** when an open PR has `F1 · P1` inline findings or `CHANGES_REQUESTED`.
- **Mode 4. Rebase or merge after a sibling PR lands** when an open PR is queued in a reviewer's merge order or has a `DIRTY` merge state.

## Step 0. Detect branch and PR state

Run this single probe before choosing a mode:

```bash
git status -sb
git branch --show-current
gh pr view --json number,state,title,body,labels,baseRefName,headRefName,headRefOid,reviewDecision,mergeStateStatus,url 2>/dev/null || echo "NO_OPEN_PR"
```

Route to one mode based on the probe output and operator intent:

| Open PR on branch? | Operator intent or PR state | Mode |
| :--- | :--- | :--- |
| No (`NO_OPEN_PR`, or `state` is `CLOSED` or `MERGED`) | Open a pull request for current work | **Mode 1. Open a new pull request** |
| Yes (`state == "OPEN"`) | Commit and push new code changes, tests, or refinements to update the PR | **Mode 2. Commit and push updates to an open pull request** |
| Yes (`state == "OPEN"`) | Address inline review findings (`F1 · P1`, `F2 · P2`, or `CHANGES_REQUESTED`) | **Mode 3. Address review findings and reply inline** |
| Yes (`state == "OPEN"`) | Rebase or merge after a sibling PR in a merge order lands, or resolve `DIRTY` merge state | **Mode 4. Rebase or merge after a sibling PR lands** |

---

## Mode 1. Open a new pull request

1. **Confirm the linked issue.**
   - Extract `#<N>` from the branch name `<type>/issue-<N>-<slug>` if already on a feature branch, and verify it with `gh issue view <N> --json number,title,state`.
   - If on `main` or no issue number is known, run the [`gh-issue`](../gh-issue/SKILL.md) skill first to find or create a Definition-of-Ready issue.
   - Choose `Closes #<N>` when this PR completes the issue, or `Refs #<N>` when splitting an `L` or `XL` issue across multiple PRs.

2. **Enforce branch, commit, DCO, and diff-size policies.**
   - **Branch name.** Use `<type>/issue-<number>-<slug>` branched off `origin/main` (for example, `fix/issue-1975-composer-height`).
   - **Commits and PR title.** Use Conventional Commits format `type(scope): subject` with an allowed type (`feat`, `fix`, `perf`, `refactor`, `style`, `test`, `docs`, `build`, `ops`, `chore`, `revert`).
   - **DCO sign-off.** Include `Signed-off-by: Name <email>` on every commit (`git commit -s`). If any commit on the branch lacks sign-off, run `git rebase --signoff origin/main`.
   - **Diff size budget.** Keep counted changed lines under the 500-line soft limit and 1000-line hard limit, excluding `*_test.go`, `*.test.{ts,tsx}`, `*.stories.{ts,tsx}`, `e2e/`, `docs/plans/`, generated files, and lockfiles:
     ```bash
     git diff --numstat "$(git merge-base origin/main HEAD)"
     ```

3. **Run verification gates and record evidence.**
   - Run unit tests, component or Storybook tests, e2e specs, typechecks, and repository quality gates (`make check-q` or language equivalents).
   - For bug fixes, confirm the new regression test fails before the fix and passes with the fix.
   - If `make check-q` has pre-existing unrelated failures on `origin/main`, record the exact failing test names and verify they do not touch files in this PR.

4. **Push the branch and create the PR.**
   - Format the PR body using the template in [references/pr-templates-and-replies.md](./references/pr-templates-and-replies.md).
   - Derive required `area:*` labels from changed top-level directory prefixes (`area:web`, `area:mobile`, `area:server`, `area:core`, `area:ai`, `area:admin`, `area:ui`, `area:contracts`, `area:infra`, `area:docs`).
   - Push and create the PR:
     ```bash
     git push -u origin HEAD
     gh pr create \
       --base main \
       --title "<type>(<scope>): <subject> (#<N>)" \
       --label "area:<area>" \
       --body-file <tmp-pr-body.md>
     ```

---

## Mode 2. Commit and push updates to an open pull request

Use this fast path when an open PR already exists on the current branch. Do not re-run `gh-issue` or `gh pr create`.

1. **Inspect incremental changes, remote tracking state, and cumulative diff budget.**
   - Fetch the remote PR branch and check working-tree changes, staged files, upstream divergence (`ahead X, behind Y`), and cumulative diff size against the merge-base (so both committed and uncommitted changes are counted):
     ```bash
     git fetch origin
     git status -sb
     git diff --stat HEAD
     git diff --numstat "$(git merge-base origin/main HEAD)"
     ```
   - Verify the cumulative PR diff (including uncommitted changes) still respects the 500-line soft limit and 1000-line hard limit.

2. **Run targeted verification on the touched files.**
   - Run the unit, component, or e2e tests covering the files modified in this update first.
   - Run the typecheck and lint gate for the touched package (or `make check-q` when the change crosses packages).
   - If the update fixes a bug or edge case, confirm the added test assertion fails without the code change and passes with it.

3. **Commit with DCO sign-off, reconcile upstream if behind, and push to the PR branch.**
   - If the working tree or index has uncommitted changes, stage the intended files (`git add <paths>`) and create a DCO-signed Conventional Commit:
     ```bash
     git commit -s -m "<type>(<scope>): <concise description of the update>"
     ```
   - Resolve the remote tracking reference and confirm every unpushed local commit carries `Signed-off-by:` without rewriting already-pushed commits:
     ```bash
     UPSTREAM=$(git rev-parse --abbrev-ref @{u} 2>/dev/null || echo "origin/$(git branch --show-current)")
     git log "${UPSTREAM}..HEAD" --format='%h %B'
     ```
     If any unpushed commit in `"${UPSTREAM}..HEAD"` lacks `Signed-off-by:`, run `git rebase --signoff "${UPSTREAM}"`.
   - If `git status -sb` shows the local branch is `behind` its upstream tracking branch (for example, a teammate or bot pushed to the PR branch), rebase local unpushed commits onto the upstream branch (`git pull --rebase origin "$(git branch --show-current)"`) before pushing.
   - Push directly to the open PR branch:
     ```bash
     git push
     ```

4. **Reconcile PR body and labels only when metadata changed.**
   - Compare the newly committed changes against the existing PR `title`, `body`, and `labels` from Step 0:
     - **No metadata drift.** If the existing `## Summary`, `FS:` line, `## Acceptance criteria`, `## Tests`, and `area:*` labels already cover the change, skip `gh pr edit`. The push completes the update.
     - **Labels or body sections changed.** Update any new `area:*` label and any modified PR body sections (`## Summary`, `## Measured`, `FS:`, or `## Tests`) in a single `gh pr edit` call using the incremental update rules in [references/pr-templates-and-replies.md](./references/pr-templates-and-replies.md):
       ```bash
       gh pr edit <pr> --add-label "area:<new-area>" --body-file <tmp-updated-pr-body.md>
       ```
       Omit `--add-label` when labels are unchanged, or omit `--body-file` when only a label is added.

---

## Mode 3. Address review findings and reply inline

When a reviewer posts findings (`F1 · P1`, `F2 · P2`) or submits `CHANGES_REQUESTED`:

1. **Fetch review summaries and unresolved inline comment threads in parallel.**
   ```bash
   gh api repos/{owner}/{repo}/pulls/{pr}/reviews --jq '.[] | {id, user: .user.login, state, commit_id, body}'
   gh api repos/{owner}/{repo}/pulls/{pr}/comments --jq '.[] | {id, in_reply_to_id, path, line, user: .user.login, body}'
   ```
   - Identify root inline comments (`in_reply_to_id == null`) that do not yet have a `Fixed in <sha>.` reply.

2. **Fix each finding with fail-before test proof, then push via Mode 2.**
   - Read each finding's `Problem`, `How it fails`, `Fix`, and `Sibling sites`.
   - Check every path in `Sibling sites`. When multiple files share the flawed logic, extract a shared helper so the fix and its unit tests live in one module.
   - Add or extend a unit, integration, or e2e test that reproduces the failure step and verify it fails before applying the fix.
   - Follow **Mode 2 Steps 3 and 4** to commit with DCO sign-off (`git commit -s -m "fix(<scope>): <concise fix description>"`), verify unpushed sign-offs and upstream state, push to the PR branch, and update `## Tests`, `## Measured`, or `area:*` labels if the fix changed test counts or touched new areas.

3. **Reply inline to each finding thread.**
   - Reply to the root `comment_id` for each finding using the format in [references/pr-templates-and-replies.md](./references/pr-templates-and-replies.md):
     ```bash
     gh api repos/{owner}/{repo}/pulls/{pr}/comments/{comment_id}/replies \
       -f body="Fixed in <short-sha>. <Explanation of fix, shared helper consolidation if any, and exact unit/e2e tests added that fail without the fix and pass with it>."
     ```

---

## Mode 4. Rebase or merge after a sibling PR lands

When a reviewer defines a merge order across conflicting PRs (`Merge order: #A, then #B, then #C`) or `mergeStateStatus` is `DIRTY`:

1. Fetch `origin/main` after the preceding PR merges and rebase or merge `origin/main` into the current branch according to the repository's convention.
2. Resolve conflicts while preserving both the sibling PR's behavior and this PR's changes.
3. Re-run the affected unit, integration, and e2e test suites and `make check-q` (or `tsc` / `go test`).
4. Push the updated branch (use `git push --force-with-lease` when rebased onto `origin/main`, or `git push` when merged) and post a top-level PR comment `@`-mentioning the reviewer (see [references/pr-templates-and-replies.md](./references/pr-templates-and-replies.md)):
   ```bash
   # After git rebase origin/main:
   git push --force-with-lease
   # Or after git merge origin/main:
   git push
   gh pr comment <pr> --body "@<reviewer> #<prev-pr> has merged, and main is merged/rebased into this branch (<short-sha>). The <K> conflicts were in <files> (<what was kept>). After the merge: <test suite pass counts and check status>."
   ```

## Completion criteria

- **Step 0 state routing.** Branch and open PR status were checked before running issue searches or PR creation commands.
- **Mode 1 (Open a new PR).** Branch follows `<type>/issue-<number>-<slug>`, commits carry `Signed-off-by:`, PR title follows `type(scope): subject`, PR body includes `Closes #<N>` or `Refs #<N>` plus all required template sections, and matching `area:*` labels are attached.
- **Mode 2 (Update an open PR).** New changes were verified with targeted tests, committed with `git commit -s`, checked for unpushed DCO sign-off (`${UPSTREAM}..HEAD`) and upstream divergence, and pushed to the existing PR branch without re-running `gh pr create`. PR body and `area:*` labels were updated via `gh pr edit` if and only if scope, metrics, tests, or touched areas changed.
- **Mode 3 (Address review findings).** Every inline finding (`F1`, `F2`, ...) has a committed fix, a regression test proven to fail without the fix, a pushed commit (with PR metadata reconciled via Mode 2), and a direct inline reply starting with `Fixed in <short-sha>.`.
- **Mode 4 (Rebase in a merge order).** Branch is clean against `origin/main`, tests pass after conflict resolution, the branch is pushed (`--force-with-lease` if rebased), and an `@<reviewer>` comment records the new SHA, resolved files, and test counts.
