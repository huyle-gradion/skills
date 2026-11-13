---
name: factory-spec
description: Write a GitHub issue that a turbo-12f software factory can deliver without asking anyone. The agent drafts the spec with the human, grills them until no decision is open, runs the factory's `spec-check`, splits a large story into sub-issues, and files it. Use when writing, splitting, or fixing an issue for the factory, or before applying the `factory` label.
---

# Factory spec (`factory-spec`)

The factory turns each acceptance criterion into a failing test and writes code until the tests pass. It cannot ask the issue's author anything. You and the human co-write a spec that is **small, detailed and correct**: a person holding only the repository and the issue could name the first failing test for every criterion.

The factory owns the rules; this skill owns the process. Every rule comes from the factory's standard, read fresh each run, so the two never drift.

## Steps

### 1. Load the rules

1. Find the factory checkout: the current repository when it has `docs/spec-standard.md` and `adapters/common.py`, otherwise `$T12_FACTORY`, otherwise ask the human for its path.
2. Read `docs/spec-standard.md` in full, and the template it names (`.github/ISSUE_TEMPLATE/factory-task.md`).
3. Note the approval label: `intake.label` in the product's `.t12/project.json`, or `factory`.

Done when you can state the required, warned and recommended rules and the cage list from the file you just read.

### 2. Find what exists

Run `gh-issue` Step 1 (branch, then open and closed issues and open PRs) so you extend an existing issue instead of filing a duplicate. Read the code the work changes and verify every path, function and test you will name. Facts are your job: look them up; never ask the human for one.

Done when every pointer you plan to write was opened in the working tree.

### 3. Grill

Run the `grilling` skill on the draft, with the standard as the design tree. The frontier always includes:

- each criterion: is it one behavior, written "given X, when Y, then Z", and checkable by a local test inside the cage?
- every choice the builder would otherwise ask about. Each answer goes under **Decisions**;
- `Touches:`: the files the change and its test file will touch;
- size: one issue is proven by one test file. At 7 to 10 criteria, propose a split and let the human choose. Above 10, the split is required.
- live checks: anything that needs the network, a live model, git transport, or the user's home is a **follow-up**, not a criterion.

Done when the frontier is empty and the human confirms the shared understanding. An "Open questions" section with anything in it means you're not done.

### 4. Draft and check

1. Write the body from the factory template. It replaces the `gh-issue` DoR body, but `gh-issue` title rules still apply. Pointers and `Touches:` live in the body. A comment (`<!--`) is refused, so the body has none.
2. Save it to a file and run:
   ```bash
   python3 <factory>/adapters/common.py spec-check <body-file> --forge github --repo-root <product checkout>
   ```
3. Each entry in `refusals` sends you back to step 3 for that point. Show the human each `warnings` entry and each `new_files` path (new files are allowed; confirm they're intended).

Done when `spec-check` exits 0 for every issue you will label.

### 5. File

Create issues with `gh issue create --body-file`, labels per `gh-issue` Step 4, **without** the approval label.

- **Split story:** file the parent (the story, no approval label), then each part, and link them natively. A parent never runs, and intake refuses a labeled one.
  ```bash
  gh api -X POST repos/<o>/<r>/issues/<parent>/sub_issues -F sub_issue_id=$(gh api repos/<o>/<r>/issues/<child> -q .id)
  gh api -X POST repos/<o>/<r>/issues/<later>/dependencies/blocked_by -F issue_id=$(gh api repos/<o>/<r>/issues/<earlier> -q .id)
  ```
  Order lives only in "blocked by" links on GitHub; intake refuses a `Depends on:` line there.
- **Live check:** file a separate follow-up issue with no approval label. It names the issue it verifies and the exact command a person runs after that issue merges.

### 6. Hand over the approval

The approval label is the human's sign-off on the text. Show each issue's link and its `spec-check` result, then apply the label only on their explicit yes, one issue at a time.

## Completion criteria

- Every labeled issue passed `spec-check` with exit 0, and the human approved each label.
- Every decision is under Decisions; no issue has an open question.
- A split story has an unlabeled parent, labeled native sub-issues, and "blocked by" links for every order between them.
- Every live check is an unlabeled follow-up issue.
