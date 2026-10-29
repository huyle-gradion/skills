# Review, conflict coordination, approval, and coordinator record formats

## 1. Sibling PR conflict and merge-order comment (`@`-mention)

Post as a top-level PR comment when two or more open PRs touch overlapping files:

```markdown
@<author-login> These <N> <subsystem> PRs conflict with each other after the first one merges:
- #<pr-A> and #<pr-B> conflict in <K> files (`<path-1>`, `<path-2>`, `<path-3>`).
- #<pr-B> and #<pr-C> conflict in <M> files (`<path-1>`, `<path-4>`).

Merge order: #<pr-A>, then #<pr-B>, then #<pr-C>. After each merge, rebase the next PR onto `main`.
```

---

## 2. Top-level review summary body (`REQUEST_CHANGES` / `COMMENT`)

The review body lists each inline finding as a single-line index entry:

```markdown
- F1 · P1 · `gw-web/src/components/composer/MessageComposer.tsx:555` · Clicking the editor body scrolls a tall composer back to the bottom, hiding the cursor.
- F2 · P2 · `gw-web/src/components/composer/MessageComposer.tsx:2182` · The GIF remove button is clipped on the top and right edges by the scroll container.
```

---

## 3. Inline review comment anatomy (5-part structure)

Attach to the exact file `path` and `line` in the PR diff:

````markdown
**<Bug | Suggestion> · <layout | interaction | scroll | ui-state | auth | data | concurrency | api> · <verified | not verified>** <One-sentence summary of the defect.>

`<symbol or CSS selector>` · fires when <trigger condition> · <N> call site(s)

**Problem**
`<path/to/file.tsx:line>`
```<lang>
<exact 3-12 line code snippet from the PR>
```
<1-2 sentences explaining why this code causes the flaw.>

**How it fails**
1. <Step 1: initial state or user setup>
2. <Step 2: user action or event trigger>
3. <Step 3: code path executed (`file:line`)>
4. Result: <concrete user-visible failure>

**Fix**
<One sentence stating the target behavior.>
<One sentence stating the code change.>
```diff
- <old line(s)>
+ <new line(s)>
```

**Sibling sites**
- `<path/to/sibling1.tsx:line>` · <same bug | checked, fine> · <one-line reason>
- `<path/to/sibling2.tsx:line>` · <same bug | checked, fine> · <one-line reason>
````

### JSON payload format for `gh api repos/{owner}/{repo}/pulls/{pr}/reviews`

```json
{
  "commit_id": "<head-sha>",
  "event": "REQUEST_CHANGES",
  "body": "- F1 · P1 · `path/to/file.tsx:120` · <One-sentence defect statement>.",
  "comments": [
    {
      "path": "path/to/file.tsx",
      "line": 120,
      "side": "RIGHT",
      "body": "**Bug · scroll · verified** <One-sentence summary.>\n\n`<symbol>` · fires when <condition> · 2 call sites\n\n**Problem**\n..."
    }
  ]
}
```

---

## 4. Approval review body

When all findings across review rounds are resolved and verified:

```text
Approved.

Reviewed, nothing to raise.

-- <Reviewer Name>
```

---

## 5. Pre-merge `## Coordinator record` comment (modeled on `#2205` and `#2186`)

Post as a top-level comment on the PR immediately before merging:

```markdown
## Coordinator record

Status: MERGE-READY at `<short-head-sha>`. Merge state is CLEAN on `main`.

Review:
- Round 1 (`<round1-sha>`): NEEDS-FIX. <Summary of Round 1 findings by severity: e.g., High/P1: <issue>; Medium/P2: <issue>; Low/P3: <issue>.>
- Round 2 (incremental diff `<round1-sha>..<head-sha>`): MERGE-READY. 0 new findings. The coordinator read the diff stat (<N> files, +<A>/-<D>) and verified it matches the reviewer report.
- Revert-test verification: the reviewer reverted each fix hunk in a scratch copy. Without the F1 fix, `<test-name-1>` fails on its assertion. Without the F2 fix, `<test-name-2>` fails.
- Verification gates: `<test suite names>` (<X> of <X> pass). `tsc` / `go vet` / `make ds-purity` exit 0.

Decisions:
- <Document any intentional design trade-offs or accepted Info/P3 points, or write "None.">

Open points:
- <Note any un-rerun baseline suites unrelated to this PR's touched files, partial-fix follow-ups (`Refs #N`), or old remote branches to delete after merge.>
```
