---
name: gh-issue
description: Resolve or create the GitHub issue for active work before opening a PR. Searches the current branch, open issues, and closed issues for an existing match; if found, returns its issue number to cite in the PR; if not found, creates a Definition-of-Ready (DoR) compliant issue from the verified code changes. Use after starting or completing work on a feature, bug fix, or chore, or when asked to check, file, groom, or audit a GitHub issue.
---

# GitHub issue resolution (`gh-issue`)

Start by working on the task in the repository. Before opening a pull request, look up whether a matching GitHub issue already exists. If an issue exists, use its `#<N>` when creating the PR. If no issue exists, create a Definition-of-Ready (DoR) compliant issue grounded in the verified code and return `#<N>` for the PR.

## Steps

### 1. Check current branch state, then search existing issues and PRs

1. **Fast path on an existing feature branch.**
   - Inspect `git branch --show-current`. If the branch already follows `<type>/issue-<N>-<slug>`, fetch `#<N>` directly instead of running broad keyword searches:
     ```bash
     gh issue view <N> --json number,title,state,labels,body,comments,url
     ```
   - If the operator only needs the linked issue confirmed for an in-flight branch, return `#<N>` immediately once verified so `gh-pr` can mention it (`Closes #<N>` or `Refs #<N>`). Otherwise, audit `#<N>` against the DoR checklist in [references/dor-and-templates.md](./references/dor-and-templates.md) and update any missing sections or labels via `gh issue edit <N>`.

2. **Search open and closed issues plus open PRs when no branch issue is known.**
   - Run both queries before drafting anything:
     ```bash
     gh issue list --state all --search "<keywords>" --limit 20 --json number,title,state,labels,url
     gh pr list --state open --search "<keywords>" --limit 10 --json number,title,headRefName,url
     ```
   - **Open issue found.** Fetch it with `gh issue view <number> --comments`. Audit its body and labels against the DoR checklist in [references/dor-and-templates.md](./references/dor-and-templates.md). If required sections or `Dev notes` are missing, update the issue via `gh issue edit <number>`. Return `#<number>` to mention in the pull request (`Closes #<number>` or `Refs #<number>`).
   - **Closed issue found.** Check whether the current work is a regression or a partial follow-up (`Refs #<old>`). Create a new issue that cites `#<old>` in `Dev notes` under `Dupes`.
   - **No issue found.** Proceed to Step 2 to create a new issue for the work.

### 2. Verify codebase facts from the active work

Never guess source paths, symbols, or line numbers. Before writing a new issue body:

1. Inspect the working tree diff (`git status -sb`, `git diff`) or search the codebase (`rg` or `grep`) to confirm the exact `path:line`, function or component name, and mechanism from the work in progress.
2. Check sibling platforms or packages (for example, check `gw-mobile` when fixing a `gw-web` bug, or check shared contracts in `gw-contracts` and `gw-ui`).
3. If the repository contains `docs/functional-spec/INDEX.md`, look up the matching area file (`docs/functional-spec/areas/<area>.md`) and highest requirement ID (`<PREFIX>-NNN`) to populate `### FS impact`.

### 3. Draft the issue body

Write the issue using the matching template in [references/dor-and-templates.md](./references/dor-and-templates.md) (`Bug`, `Feature`, or `Chore / backlog item`). Follow these rules:

1. **Title.**
   - Bug: `[Bug] <Plain symptom and affected surface>` (for example, `[Bug] Composer grows to 61% of the window, hiding the conversation`).
   - Feature: `[Feature] <Capability in user terms>`.
   - Chore or backlog: `[Chore] <Outcome>` or `[Backlog] <Outcome>`.
2. **Main body in product, BA, and QA language.**
   - Keep `### Summary`, `### Steps to reproduce`, `### Expected vs actual`, `### Acceptance criteria`, and `### Impact` free of file paths, line numbers, and internal variable names.
   - For bugs, write numbered reproduction steps starting from a concrete screen or state and ending with the observable failure.
   - For features and backlog items, cover all five state categories in `### Acceptance criteria`: `Happy path`, `Error / failure`, `Empty / zero state`, `Edge inputs`, and `Platform behavior`.
3. **Functional spec impact (`### FS impact`).**
   - State `Area: areas/<name>.md` and `ADDED`, `MODIFIED`, `REMOVED`, or `DOCUMENT` requirement IDs, `none (<reason>)`, or `area not yet specified (<PREFIX>)`.
4. **Collapsible developer notes at the bottom.**
   - Put all verified code references inside `<details><summary>Dev notes (code-read, not run)</summary>` with bullets for `Cause`, `Code` (`path:line`), `Fix direction`, `Mobile check`, and `Dupes`.
5. **Footer metadata.**
   - Include `_Open question: none._` (or list blocking product questions) and `_Source: <origin>._`.

### 4. Create the issue and apply labels

Create the issue with its required labels:

```bash
gh issue create \
  --title "<title>" \
  --label "type:<bug|feature|chore>,platform:<web|mobile-app|all>,area:<area>" \
  --body-file <tmp-body-file>
```

When working in a repository that uses default GitHub labels (`bug`, `enhancement`), check available labels once with `gh label list` and map accordingly.

## Completion criteria

- Current branch name was checked first, or open and closed issues plus open PRs were searched before creating a new issue.
- Main issue sections contain no raw code file paths or line numbers; all code pointers live inside `<details><summary>Dev notes (code-read, not run)</summary>`.
- Every `path:line` and symbol cited in `Dev notes` was verified in the repository working tree.
- Bug issues include numbered reproduction steps, `Expected`, `Actual`, and `Impact`.
- Feature and chore issues include state-complete acceptance criteria covering happy path, error, empty, edge inputs, and platform behavior.
- `### FS impact` is filled whenever the repository tracks `docs/functional-spec/`.
- Matching `type:*`, `platform:*`, and `area:*` labels (or repo-equivalent labels) are attached.
- The existing or newly created issue number `#<N>` is returned so `gh-pr` mentions it (`Closes #<N>` or `Refs #<N>`) when creating the pull request.
