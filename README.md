# Skills

Agent skills for GitHub engineering workflows, built for Claude Code, Google Antigravity, and compatible coding agents.

## Included skills

| Skill | Role | Trigger scenarios |
| :--- | :--- | :--- |
| [`gh-issue`](./gh-issue/SKILL.md) | Issue gate and Definition of Ready | Confirm the active branch's linked issue (`<type>/issue-<N>-<slug>`) or search open and closed issues before starting work; create or audit bugs, features, and backlog items with verified `Dev notes` and `FS impact`. |
| [`gh-pr`](./gh-pr/SKILL.md) | Pull request author lifecycle | Detect whether an open PR already exists on the current branch, then route to opening a new PR (Mode 1), committing and pushing incremental updates on the fast path (Mode 2), fixing `F1 · P1` review findings with inline SHA replies (Mode 3), or rebasing in a merge order (Mode 4). |
| [`gh-review`](./gh-review/SKILL.md) | Code reviewer and merge coordinator | Detect sibling PR conflicts and post `@author` merge order, submit structured inline findings (`Problem`, `How it fails`, `Fix`, `Sibling sites`) with `F1 · P1` index summaries, fast-forward re-reviews to `<prev_sha>..<head_sha>` with revert testing, approve, and post the pre-merge `## Coordinator record`. |

## End-to-end workflow

```
1. Issue gate (gh-issue)
   Check branch <type>/issue-<N>-<slug> or search open/closed issues
   Verify or create DoR-compliant issue (#1975)
        |
        v
2. Author or update PR (gh-pr Step 0 state router)
   +-- Mode 1 (NO_OPEN_PR): Branch -> full gates -> DCO commits (-s) -> gh pr create (#2051)
   +-- Mode 2 (OPEN_PR update): Targeted tests -> git commit -s -> check ${UPSTREAM}..HEAD & behind -> git push -> surgical gh pr edit if metadata changed
        |
        v
3. Coordinate and review (gh-review)
   Check sibling PR conflicts (@author merge order)
   Post F1 · P1 review summary + 5-part inline findings (REQUEST_CHANGES / COMMENT)
        |
        v
4. Fix and reply loop (gh-pr Mode 3 <-> gh-review Stage 3)
   Author fixes with fail-before tests -> pushes -> replies inline ("Fixed in <sha>...")
   Reviewer diffs <prev-sha>..<head-sha> + revert-tests new assertions + re-checks sibling overlaps if new files touched
        |
        v
5. Rebase in merge order when needed (gh-pr Mode 4)
   Rebase/merge origin/main after sibling PR lands -> re-verify tests -> @reviewer comment
        |
        v
6. Approve and pre-merge record (gh-review Stage 4)
   Submit "Approved. / Reviewed, nothing to raise."
   Post "## Coordinator record" (Status: MERGE-READY at <sha>) -> Merge
```

## Installation

Clone this repository and symlink each skill into `~/.agents/skills/` and `~/.claude/skills/`:

```bash
git clone https://github.com/huyle-gradion/skills.git ~/Projects/skills

for skill in gh-issue gh-pr gh-review; do
  ln -sfn "$HOME/Projects/skills/$skill" "$HOME/.agents/skills/$skill"
  ln -sfn "../../.agents/skills/$skill" "$HOME/.claude/skills/$skill"
done
```
