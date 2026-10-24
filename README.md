# Skills

Personal agent skills for GitHub engineering workflows, authored for Claude Code, Google Antigravity, and compatible coding agents.

## Included skills

| Skill | Role | Trigger scenarios |
| :--- | :--- | :--- |
| [`gh-issue`](./gh-issue/SKILL.md) | Issue gate & Definition of Ready | Check if a GitHub issue exists before starting work; create or audit bugs, features, and backlog items with verified `Dev notes` and `FS impact`. |
| [`gh-pr`](./gh-pr/SKILL.md) | Pull request author lifecycle | Create policy-compliant branches and DCO-signed commits, open structured PRs (`Summary`, `Measured`, `FS`, `Tests`), reply inline to `F1 · P1` review findings with fix SHAs and test proof, and report rebase/conflict resolution. |
| [`gh-review`](./gh-review/SKILL.md) | Code reviewer & merge coordinator | Detect sibling PR conflicts and post `@author` merge order, submit structured inline findings (`Problem`, `How it fails`, `Fix`, `Sibling sites`) with `F1 · P1` index summaries, verify incremental fix rounds, approve, and post the pre-merge `## Coordinator record`. |

## End-to-end workflow

```
1. Issue gate (gh-issue)
   Search open/closed issues -> Verify or create DoR-compliant issue (#1975)
        |
        v
2. Author PR (gh-pr)
   Branch <type>/issue-<N>-<slug> -> DCO commits (-s) -> Open PR (#2051)
        |
        v
3. Coordinate & review (gh-review)
   Check sibling PR conflicts (@author merge order)
   Post F1 · P1 review summary + 5-part inline findings (REQUEST_CHANGES / COMMENT)
        |
        v
4. Fix & reply loop (gh-pr <-> gh-review)
   Author fixes with fail-before tests -> Replies inline ("Fixed in <sha>...")
   Reviewer checks incremental diff + revert-tests new assertions
        |
        v
5. Approve & pre-merge record (gh-review)
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
