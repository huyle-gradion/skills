---
name: gh-review
description: Conduct GitHub pull request reviews, sibling conflict coordination, approval, and pre-merge coordinator records. Checks open PRs for overlapping file conflicts (@author merge order), posts structured inline findings (Problem, How it fails, Fix diff, Sibling sites) with F1/P1 review summaries, verifies incremental fix rounds via revert testing, approves PRs, and leaves the pre-merge Coordinator record comment. Use when reviewing a PR, requesting changes, re-reviewing fixes, approving, or preparing a PR to merge.
---

# GitHub PR Review and Merge Coordinator (`gh-review`)

Execute the reviewer and merge-coordinator workflow across four stages:
1. **Stage 1: Triage & sibling PR conflict coordination (`@`-mention)**
2. **Stage 2: Deep review & structured inline findings (`F1 · P1`)**
3. **Stage 3: Incremental re-review & revert-test verification**
4. **Stage 4: Approval & pre-merge `## Coordinator record` comment**

## Steps

### Stage 1: Triage and sibling PR conflict check

1. **Inspect the PR and its linked issue**:
   ```bash
   gh pr view <pr> --json number,title,author,baseRefName,headRefName,headRefOid,mergeStateStatus,body,files,commits,reviews,comments
   ```
   - Verify policy compliance: Conventional Commit title, `Closes #<N>` or `Refs #<N>`, `FS:` line, `area:*` label, and diff size.

2. **Check open sibling PRs for overlapping file conflicts**:
   ```bash
   gh pr list --state open --json number,title,author,files
   ```
   - Compare the changed file paths of `<pr>` against other open PRs.
   - If two or more open PRs modify the same files and will conflict once the first one merges, post a top-level comment `@`-mentioning the author using the template in [references/review-and-coordinator-formats.md](./references/review-and-coordinator-formats.md):
     - Name each pair of conflicting PRs and the exact overlapping file count and paths.
     - State the explicit merge sequence: `Merge order: #<first>, then #<second>, then #<third>. After each merge, rebase the next PR onto main.`

---

### Stage 2: Deep code review and structured inline findings

1. **Audit the diff and sibling call sites**:
   - Read the full changed functions and their callers/callees in the repository, not just the 3-line diff context.
   - Whenever you spot a candidate defect in one component or handler, check all **sibling sites** (for example, `MessageComposer` vs `ThreadPanel`, create vs edit mode, web vs mobile, or parallel API handlers).
   - Trace the exact runtime steps to verify whether the defect can fire (`verified` vs `not verified`).

2. **Classify findings by severity**:
   - `P1`: Blocking defect (broken layout/interaction, runtime error, security/auth bypass, race condition, data corruption, or regression).
   - `P2`: Moderate edge-case bug, incomplete state reset, or missing regression test for a key failure mode.
   - `P3`: Minor improvement, naming/style cleanup, or non-blocking suggestion.

3. **Compose inline comments and the review summary**:
   - Format every inline comment using the 5-part anatomy in [references/review-and-coordinator-formats.md](./references/review-and-coordinator-formats.md):
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

4. **Submit the review on GitHub**:
   - Use `event: "REQUEST_CHANGES"` when any `P1` (or blocking `P2`) finding is present; use `event: "COMMENT"` for non-blocking findings or when GitHub blocks self-review state transitions:
     ```bash
     gh api repos/{owner}/{repo}/pulls/{pr}/reviews \
       --input <tmp-review-payload.json>
     ```

---

### Stage 3: Incremental re-review and revert-test verification

When the author pushes fix commits and replies inline (`Fixed in <sha>...`):

1. **Inspect the incremental diff**:
   ```bash
   git diff <prev-reviewed-sha>..<current-head-sha>
   ```
2. **Audit each fix for secondary regressions**:
   - Verify that the fix resolves the reported failure without introducing a new edge case (for example, clipping a child element inside a new scroll container, changing layout in edit mode, or skipping cleanup on unmount).
3. **Verify test discrimination via revert testing**:
   - In a clean worktree or scratch copy, revert each fix hunk while keeping the new test, and run the test suite. Confirm that each new test **fails when its corresponding production fix is reverted** and **passes when restored**.
4. **If new or remaining defects exist**:
   - Submit the next review round (`- F1 · P1 · ...` or `- F1 · P2 · ...`) using Stage 2.
5. **If zero defects remain**:
   - Proceed to Stage 4.

---

### Stage 4: Approval and pre-merge `## Coordinator record` comment

Before merging a ready PR:

1. **Submit the approval review**:
   - Post the standard sign-off body (use `gh pr review <pr> --approve` when reviewing another author's PR, or `--comment` if coordinating on your own PR):
     ```text
     Approved.

     Reviewed, nothing to raise.

     -- <Reviewer Name>
     ```

2. **Post the pre-merge `## Coordinator record` comment**:
   - Leave a top-level PR comment documenting merge readiness, review rounds, revert-test verification, accepted trade-offs, and open follow-ups using the template in [references/review-and-coordinator-formats.md](./references/review-and-coordinator-formats.md):
     ```bash
     gh pr comment <pr> --body-file <tmp-coordinator-record.md>
     ```

## Completion criteria

- Open sibling PRs were checked for overlapping file changes, and an `@<author>` merge-order comment was posted if conflicts exist.
- Every review finding includes the top-level `- F<N> · P<1|2|3> · \`path:line\` · <summary>` index bullet and an inline comment with `Problem`, `How it fails`, `Fix` (with diff), and `Sibling sites`.
- Incremental fix rounds were checked across `<prev_sha>..<head_sha>` and verified by reverting fix hunks against the new tests.
- Once clean, the PR received the `Approved. / Reviewed, nothing to raise.` review and the pre-merge `## Coordinator record` comment before merge.
