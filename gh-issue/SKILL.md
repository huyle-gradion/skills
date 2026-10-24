---
name: gh-issue
description: Ensure every task starts with a GitHub issue. Searches open and closed issues first; if none exists, investigates the codebase for verified root-cause notes and creates or updates a Definition-of-Ready (DoR) compliant issue. Use before starting any feature, bug fix, or chore, or when asked to check, file, groom, or audit a GitHub issue.
---

# GitHub Issue Gate (`gh-issue`)

Every piece of engineering work starts with a GitHub issue. Before creating a branch or writing implementation code, check whether a matching issue exists. If it does not exist, investigate the codebase read-only and create a Definition-of-Ready (DoR) compliant issue.

## Steps

### 1. Search for an existing issue and in-flight PRs

Run both searches against the target repository before drafting anything:

```bash
gh issue list --state all --search "<keywords>" --limit 20 --json number,title,state,labels,url
gh pr list --state open --search "<keywords>" --limit 10 --json number,title,headRefName,url
```

- **If an open issue exists**: Fetch it with `gh issue view <number> --comments`. Audit its body and labels against the DoR checklist in [references/dor-and-templates.md](./references/dor-and-templates.md). If sections or `Dev notes` are missing, offer to update the issue via `gh issue edit <number>`; otherwise report the issue number `#<number>` as ready for branching.
- **If a closed issue exists**: Check whether this is a regression or a partial follow-up (`Refs #<old>`). Create a new issue that cites `#<old>` in `Dev notes` under `Dupes`.
- **If no issue exists**: Proceed to Step 2.

### 2. Verify codebase facts read-only

Never guess source paths, symbols, or line numbers. Before writing the issue body:

1. Search the codebase (`rg` / `grep`) and read the relevant lines to confirm the exact `path:line`, function/component name, and mechanism.
2. Check sibling platforms or packages (for example, check `gw-mobile` when filing a `gw-web` bug, or check shared contracts in `gw-contracts` / `gw-ui`).
3. If the repository contains `docs/functional-spec/INDEX.md`, look up the matching area file (`docs/functional-spec/areas/<area>.md`) and highest requirement ID (`<PREFIX>-NNN`) to populate `### FS impact`.

### 3. Draft the issue body

Write the issue using the matching template in [references/dor-and-templates.md](./references/dor-and-templates.md) (`Bug`, `Feature`, or `Chore / Backlog item`). Follow these structural rules:

1. **Title**:
   - Bug: `[Bug] <Plain symptom and affected surface>` (for example, `[Bug] Composer grows to 61% of the window, hiding the conversation`).
   - Feature: `[Feature] <Capability in user terms>`.
   - Chore / Backlog: `[Chore] <Outcome>` or `[Backlog] <Outcome>`.
2. **Main body in product/BA/QA language**:
   - Keep `### Summary`, `### Steps to reproduce`, `### Expected vs actual`, `### Acceptance criteria`, and `### Impact` free of file paths, line numbers, and internal variable names.
   - For bugs, write numbered reproduction steps starting from a concrete screen/state and ending with the observable failure.
   - For features and backlog items, cover all five state categories in `### Acceptance criteria`: `Happy path`, `Error / failure`, `Empty / zero state`, `Edge inputs`, and `Platform behavior`.
3. **Functional spec impact (`### FS impact`)**:
   - State `Area: areas/<name>.md` and `ADDED` / `MODIFIED` / `REMOVED` / `DOCUMENT` requirement IDs, or `none (<reason>)`, or `area not yet specified (<PREFIX>)`.
4. **Collapsible developer notes at the bottom**:
   - Put all verified code references inside `<details><summary>Dev notes (code-read, not run)</summary>` with bullets for `Cause`, `Code` (`path:line`), `Fix direction`, `Mobile check`, and `Dupes`.
5. **Footer metadata**:
   - Include `_Open question: none._` (or list blocking product questions) and `_Source: <origin>._`.

### 4. Create the issue and apply labels

Present the drafted title, labels, and body (or create directly when the user asked to file it immediately):

```bash
gh issue create \
  --title "<title>" \
  --label "type:<bug|feature|chore>,platform:<web|mobile-app|all>,area:<area>" \
  --body-file <tmp-body-file>
```

When working in a repository that uses only default GitHub labels (`bug`, `enhancement`), check available labels first with `gh label list` and map accordingly.

## Completion criteria

- Open and closed issues (plus open PRs) were searched before creating a new issue.
- Main issue sections contain no raw code file paths or line numbers; all code pointers live inside `<details><summary>Dev notes (code-read, not run)</summary>`.
- Every `path:line` and symbol cited in `Dev notes` was verified in the repository working tree.
- Bug issues include numbered reproduction steps, `Expected`, `Actual`, and `Impact`.
- Feature and chore issues include state-complete acceptance criteria covering happy path, error, empty, edge inputs, and platform behavior.
- `### FS impact` is filled whenever the repository tracks `docs/functional-spec/`.
- Matching `type:*`, `platform:*`, and `area:*` labels (or repo-equivalent labels) are attached.
- The resulting issue number `#<N>` is returned so `gh-pr` can create `<type>/issue-<N>-<slug>`.
