---
name: gh-pr
description: Author and manage GitHub pull requests end-to-end. Creates policy-compliant branches and DCO-signed commits, opens structured PRs linked to an issue, addresses inline review findings (F1/P1) with fail-before tests and inline SHA replies, and posts @-mention rebase/conflict updates. Use when opening or updating a PR, fixing review comments, or rebasing a PR in a merge queue.
---

# GitHub Pull Request Author Workflow (`gh-pr`)

Manage the author side of a GitHub pull request across three modes:
- **Mode 1: Open or update a PR**
- **Mode 2: Address review findings and reply inline**
- **Mode 3: Rebase after a sibling PR merges and notify the reviewer**

## Steps

### Mode 1: Open or update a pull request

1. **Confirm the linked issue exists**:
   - Check that an issue `#<N>` exists for this work. If none exists, run the `gh-issue` workflow first to find or create one.
   - Decide the issue-link keyword:
     - Use `Closes #<N>` when this PR completes the issue.
     - Use `Refs #<N>` when splitting an `L`/`XL` issue across multiple PRs (only the final PR uses `Closes #<N>`).

2. **Enforce branch, commit, DCO, and diff-size policies**:
   - **Branch name**: `<type>/issue-<number>-<slug>` (for example, `fix/issue-1975-composer-height` or `feat/issue-1840-channel-read-state`), branched off `origin/main`.
   - **Commits and PR title**: Conventional Commits format `type(scope): subject` (allowed types: `feat`, `fix`, `perf`, `refactor`, `style`, `test`, `docs`, `build`, `ops`, `chore`, `revert`).
   - **DCO sign-off**: Every commit must carry `Signed-off-by: Name <email>` (`git commit -s`). If any commit on the branch lacks sign-off, run `git rebase --signoff origin/main`.
   - **Diff size budget**: Counted changed lines (excluding `*_test.go`, `*.test.{ts,tsx}`, `*.stories.{ts,tsx}`, `e2e/`, `docs/plans/`, generated files, and lockfiles) must stay within the **500-line soft limit** and **1000-line hard limit**:
     ```bash
     git diff --numstat origin/main...HEAD
     ```

3. **Run verification gates and record evidence**:
   - Run unit tests, component/Storybook tests, e2e specs, typechecks, and repository quality gates (`make check-q` or language equivalents).
   - For bug fixes, verify that the new regression test **fails before the fix** and **passes with the fix**.
   - If `make check-q` has pre-existing unrelated failures on `origin/main`, record the exact failing test names and confirm they do not touch files in this PR.

4. **Create or update the PR**:
   - Format the PR body using the template in [references/pr-templates-and-replies.md](./references/pr-templates-and-replies.md) (`## Summary`, `## Measured`, `FS:` declaration, `## Acceptance criteria`, `## Known limits`, `## Tests`, `## Definition of Done`).
   - Apply the required `area:*` label(s) matching the changed directory prefixes (`area:web`, `area:mobile`, `area:server`, `area:core`, `area:ai`, `area:admin`, `area:ui`, `area:contracts`, `area:infra`, `area:docs`):
     ```bash
     gh pr create \
       --base main \
       --title "<type>(<scope>): <subject> (#<N>)" \
       --label "area:<area>" \
       --body-file <tmp-pr-body.md>
     ```

---

### Mode 2: Address review findings and reply inline

When a reviewer posts findings (`F1 · P1`, `F2 · P2`, etc.) or submits `CHANGES_REQUESTED`:

1. **Fetch all review summaries and inline comment threads**:
   ```bash
   gh api repos/{owner}/{repo}/pulls/{pr}/reviews --jq '.[] | {id, user: .user.login, state, body}'
   gh api repos/{owner}/{repo}/pulls/{pr}/comments --jq '.[] | {id, in_reply_to_id, path, line, user: .user.login, body}'
   ```

2. **Fix each finding with fail-before test proof**:
   - Read the finding's `Problem`, `How it fails`, `Fix`, and `Sibling sites` sections.
   - Inspect all listed `Sibling sites`. If multiple files or components share the logic, extract a shared helper so the fix and its tests live in one place.
   - Write or extend a unit/integration/e2e test that reproduces the exact failure step and confirm it **fails without the fix** before applying the code change.
   - Commit with DCO sign-off (`git commit -s -m "fix(<scope>): <concise fix description>"`) and push to the PR branch. Pushing a new commit automatically removes the `changes-requested` label.

3. **Reply inline to each finding thread**:
   - Reply directly to the root inline comment ID (`comment_id`) for every finding using the template in [references/pr-templates-and-replies.md](./references/pr-templates-and-replies.md):
     ```bash
     gh api repos/{owner}/{repo}/pulls/{pr}/comments/{comment_id}/replies \
       -f body="Fixed in <short-sha>. <Explanation of fix, shared helper consolidation if any, and exact unit/e2e tests added that fail without the fix and pass with it>."
     ```

---

### Mode 3: Rebase / merge after a sibling PR merges and `@`-mention the reviewer

When a reviewer defines a merge order across conflicting PRs (`Merge order: #A, then #B, then #C`):

1. After the preceding PR merges into `main`, fetch `origin/main` and rebase (or merge `origin/main` into the branch, matching the repo's convention).
2. Resolve conflicts carefully, keeping both the sibling PR's behavior and this PR's changes intact.
3. Re-run the affected unit/integration/e2e test suites and `make check-q` (or `tsc` / `go test`).
4. Post a top-level PR comment `@`-mentioning the reviewer (see [references/pr-templates-and-replies.md](./references/pr-templates-and-replies.md)):
   ```bash
   gh pr comment <pr> --body "@<reviewer> #<prev-pr> has merged, and main is merged/rebased into this branch (<short-sha>). The <K> conflicts were in <files> (<what was kept>). After the merge: <test suite pass counts and check status>."
   ```

## Completion criteria

- **Opening a PR**:
  - Branch follows `<type>/issue-<number>-<slug>` and all commits have `Signed-off-by:` DCO lines.
  - PR title follows `type(scope): subject` and body contains `Closes #<N>` or `Refs #<N>`.
  - PR body includes `## Summary`, `FS:` declaration, `## Acceptance criteria`, `## Tests` (with fail-before evidence and check-gate status), and `##Measured` when layout/perf metrics apply.
  - Matching `area:*` labels are applied.
- **Addressing review findings**:
  - Every inline finding (`F1`, `F2`, ...) has a committed fix, a regression test proven to fail without the fix, and a direct inline reply starting with `Fixed in <short-sha>.`.
- **Rebasing in a merge order**:
  - Branch is clean against `origin/main`, tests are re-verified after conflict resolution, and an `@<reviewer>` comment documents the new SHA, resolved files, and test counts.
