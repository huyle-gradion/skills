---
name: gh-review
description: Conduct GitHub pull request reviews, sibling conflict coordination, approval, and pre-merge coordinator records. Checks open PRs for overlapping file conflicts (@author merge order), posts structured inline findings (Problem, How it fails, Fix diff, Sibling sites) with F1/P1 review summaries, verifies incremental fix rounds via revert testing, approves PRs, and leaves the pre-merge Coordinator record comment. Use when reviewing a PR, requesting changes, re-reviewing fixes, approving, or preparing a PR to merge.
---

# GitHub PR review and merge coordinator (`gh-review`)

Execute the reviewer and merge-coordinator workflow across four stages. Start by inspecting the PR's review history to jump directly to Stage 3 when re-reviewing incremental commits pushed after a prior review round:
1. **Stage 1. Triage and sibling PR conflict coordination (`@`-mention)**
2. **Stage 2. Deep review and structured inline findings (`F1 · P1`)**
3. **Stage 3. Incremental re-review and revert-test verification**
4. **Stage 4. Approval and pre-merge `## Coordinator record` comment**

## Steps

### Stage 1. Triage and sibling PR conflict check

1. **Inspect the PR and its review history first.**
   ```bash
   gh pr view <pr> --json number,title,author,baseRefName,headRefName,headRefOid,mergeStateStatus,labels,body,files,commits,reviews,comments
   ```
   - **Fast-forward to Stage 3 on re-review.** Extract the commit SHA of the last review that requested changes or posted structured findings (`- F<N> · P<1|2|3>`):
     ```bash
     gh pr view <pr> --json reviews --jq '[.reviews[] | select(.state == "CHANGES_REQUESTED" or (.body | test("(^|\n)- F[0-9]+ · P[123]")))][-1].commit.oid // empty'
     ```
     If `<prev-reviewed-sha>` is non-empty and differs from `headRefOid`, jump directly to **Stage 3** to diff `<prev-reviewed-sha>..<headRefOid>`.
   - **Verify policy compliance on initial review.** Check Conventional Commit title, `Closes #<N>` or `Refs #<N>`, `FS:` line, `area:*` label matching touched directory prefixes, DCO sign-off on commits, and diff size budget.

2. **Coordinate overlapping sibling PR conflicts on initial review.**
   ```bash
   gh pr list --state open --json number,title,author,files
   ```
   - Compare the changed file paths of `<pr>` against other open PRs from `gh pr list`.
   - When two or more open PRs modify overlapping files and will conflict after the first merges, post a top-level comment `@`-mentioning the author using the template in [references/review-and-coordinator-formats.md](./references/review-and-coordinator-formats.md):
     - Name each pair of conflicting PRs and the exact overlapping file count and paths.
     - State the explicit merge sequence: `Merge order: #<first>, then #<second>, then #<third>. After each merge, rebase the next PR onto main.`

---

### Stage 2. Deep code review and structured inline findings

1. **Audit the diff and sibling call sites.**
   - Read the full changed functions and their callers and callees in the repository, not only the 3-line diff hunk.
   - Whenever you spot a candidate defect in one component or handler, check all sibling sites (for example, `MessageComposer` vs `ThreadPanel`, create vs edit mode, web vs mobile, or parallel API handlers).
   - Trace the exact runtime steps to verify whether the defect fires (`verified` vs `not verified`).

2. **Classify findings by severity.**
   - `P1`: Blocking defect (broken layout or interaction, runtime error, security or auth bypass, race condition, data corruption, or regression).
   - `P2`: Moderate edge-case bug, incomplete state reset, or missing regression test for a key failure mode.
   - `P3`: Minor improvement, naming or style cleanup, or non-blocking suggestion.

3. **Compose inline comments and the review summary.**
   - Format every inline comment using the 5-part structure in [references/review-and-coordinator-formats.md](./references/review-and-coordinator-formats.md):
     1. Header: `**<Bug|Suggestion> · <category> · <verified|not verified>** <One-sentence defect statement.>`
     2. Trigger metadata: `` `<symbol>` · fires when <condition> · <N> call site(s) ``
     3. `**Problem**`: `<file:line>`, fenced code snippet, and 1-2 sentence explanation.
     4. `**How it fails**`: numbered step-by-step walkthrough ending in `Result: <user-visible failure>`.
     5. `**Fix**`: target behavior sentence, code change sentence, and minimal `diff` block.
     6. `**Sibling sites**`: bullet list of related locations (`- <path:line> · <same bug | checked, fine> · <reason>`).
   - Format the top-level review `body` as a one-line-per-finding index:
     ```markdown
     - F1 · P1 · `path/to/file.tsx:120` · <One-sentence defect statement>.
     - F2 · P2 · `path/to/other.ts:45` · <One-sentence defect statement>.
     ```

4. **Submit the review on GitHub.**
   - Use `event: "REQUEST_CHANGES"` when any `P1` (or blocking `P2`) finding is present. Use `event: "COMMENT"` for non-blocking findings or when GitHub blocks self-review state transitions:
     ```bash
     gh api repos/{owner}/{repo}/pulls/{pr}/reviews \
       --input <tmp-review-payload.json>
     ```

---

### Stage 3. Incremental re-review and revert-test verification

When the author pushes new commits (via `gh-pr` Mode 2 or Mode 3) or replies inline (`Fixed in <sha>...`):

1. **Inspect only the incremental diff since `<prev-reviewed-sha>` from Stage 1.**
   - Fetch both `<prev-reviewed-sha>` and the PR branch head (in case the branch was rebased since the prior review) and diff the range:
     ```bash
     git fetch origin <prev-reviewed-sha> <headRefName>
     git diff --stat <prev-reviewed-sha>..<current-head-sha>
     git diff <prev-reviewed-sha>..<current-head-sha>
     ```
2. **Audit each fix or incremental update for secondary regressions and new sibling overlaps.**
   - Verify that each change resolves the reported issue or delivers the incremental update without introducing a new edge case (such as clipping a child element inside a scroll container, breaking edit mode layout, or skipping unmount cleanup).
   - Compare `git diff --name-only <prev-reviewed-sha>..<current-head-sha>` against `git diff --name-only origin/main...<prev-reviewed-sha>`. If the incremental commits touch files that were not in the previously reviewed PR diff, run `gh pr list --state open --json number,title,author,files` to check for newly introduced sibling PR overlaps.
3. **Verify test discrimination via revert testing.**
   - In a clean worktree or scratch copy, revert each production fix hunk while keeping the new test, then run the targeted test file. Confirm that each new test fails when its production fix is reverted and passes when restored.
4. **Route based on remaining findings.**
   - If new or unresolved defects remain, submit the next review round (`- F1 · P1 · ...` or `- F1 · P2 · ...`) using Stage 2.
   - If zero defects remain, proceed to Stage 4.

---

### Stage 4. Approval and pre-merge `## Coordinator record` comment

Before merging a ready PR:

1. **Submit the approval review.**
   - Post the standard sign-off body (use `gh pr review <pr> --approve` when reviewing another author's PR, or `--comment` when coordinating on your own PR):
     ```text
     Approved.

     Reviewed, nothing to raise.

     -- <Reviewer Name>
     ```

2. **Post the pre-merge `## Coordinator record` comment.**
   - Leave a top-level PR comment documenting merge readiness, review rounds, incremental diff stats, revert-test verification, accepted trade-offs, and open follow-ups using the template in [references/review-and-coordinator-formats.md](./references/review-and-coordinator-formats.md):
     ```bash
     gh pr comment <pr> --body-file <tmp-coordinator-record.md>
     ```

## Completion criteria

- Initial triage checked policy compliance and open sibling PRs for overlapping file changes, posting an `@<author>` merge-order comment if conflicts exist.
- Re-reviews extracted `<prev-reviewed-sha>` (`commit.oid`) from Stage 1's `reviews` array, jumped directly to Stage 3 to inspect `<prev-reviewed-sha>..<current-head-sha>`, and queried `gh pr list` only if incremental commits touched files outside the previously reviewed diff.
- Every review finding includes the top-level `- F<N> · P<1|2|3> · \`path:line\` · <summary>` index bullet and an inline comment with `Problem`, `How it fails`, `Fix` (with diff), and `Sibling sites`.
- Incremental fix rounds were verified by reverting production fix hunks against the new tests.
- Once clean, the PR received the `Approved. / Reviewed, nothing to raise.` review and the pre-merge `## Coordinator record` comment before merge.
