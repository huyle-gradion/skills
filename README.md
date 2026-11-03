# Skills

Agent skills for GitHub engineering workflows (`https://github.com/huyle-gradion/skills`), built for Claude Code, Google Antigravity, and compatible coding agents. Current version: [`1.0.0`](./VERSION) ([`CHANGELOG.md`](./CHANGELOG.md)).

## Included skills

| Skill | Role | Trigger scenarios |
| :--- | :--- | :--- |
| [`gh-issue`](./gh-issue/SKILL.md) | Issue resolution and Definition of Ready | After starting or completing work, check the active branch or search open and closed issues for an existing match. If found, return `#<N>` to mention in the PR; if not found, create a DoR-compliant issue with verified `Dev notes` and `FS impact`. |
| [`gh-pr`](./gh-pr/SKILL.md) | Pull request author lifecycle | Detect whether an open PR already exists on the current branch, then route to opening a new PR citing `Closes #<N>` or `Refs #<N>` (Mode 1), committing and pushing incremental updates on the fast path (Mode 2), fixing `F1 · P1` review findings with inline SHA replies (Mode 3), or rebasing in a merge order (Mode 4). |
| [`gh-review`](./gh-review/SKILL.md) | Code reviewer and merge coordinator | Detect sibling PR conflicts and post `@author` merge order, submit structured inline findings (`Problem`, `How it fails`, `Fix`, `Sibling sites`) with `F1 · P1` index summaries, fast-forward re-reviews to `<prev_sha>..<head_sha>` with revert testing, approve, and post the pre-merge `## Coordinator record`. |

## End-to-end workflow

```
1. Work on the task first (implement and verify locally)
        |
        v
2. Resolve or create the issue (/gh-issue)
   Search branch <type>/issue-<N>-<slug> and open/closed issues
   +-- Issue exists -> mention #<N> when creating the PR
   +-- No issue exists -> create DoR issue (#1975) and mention #<N> in the PR
        |
        v
3. Author or update PR (/gh-pr Step 0 state router)
   +-- Mode 1 (NO_OPEN_PR): Branch -> full gates -> DCO commits (-s) -> gh pr create citing Closes/Refs #<N> (#2051)
   +-- Mode 2 (OPEN_PR update): Targeted tests -> git commit -s -> check ${UPSTREAM}..HEAD & behind -> git push -> surgical gh pr edit if metadata changed
        |
        v
4. Coordinate and review (/gh-review)
   Check sibling PR conflicts (@author merge order)
   Post F1 · P1 review summary + 5-part inline findings (REQUEST_CHANGES / COMMENT)
        |
        v
5. Fix and reply loop (/gh-pr Mode 3 <-> /gh-review Stage 3)
   Author fixes with fail-before tests -> pushes -> replies inline ("Fixed in <sha>...")
   Reviewer diffs <prev-sha>..<head-sha> + revert-tests new assertions + re-checks sibling overlaps if new files touched
        |
        v
6. Rebase in merge order (/gh-pr Mode 4) -> Approve and pre-merge "## Coordinator record" (/gh-review Stage 4) -> Merge
```

## Reusable rule (`AGENTS.md` / `CLAUDE.md`)

Add this rule to any repository (see [`AGENTS.md`](./AGENTS.md)):

```markdown
Always start by working on the task first, then look for an existing GitHub issue with `/gh-issue`. If an issue exists, mention it (`Closes #<N>` or `Refs #<N>`) when creating the PR; if not, create a new issue and mention it. Use the `/gh-issue`, `/gh-pr`, and `/gh-review` skillset from https://github.com/huyle-gradion/skills and follow SemVer (`VERSION` and `CHANGELOG.md`).
```

## Automation scripts and levers

Helper scripts located in `scripts/` compute diff budgets, route PR modes, and extract review state deterministically:

| Script | Skill | Purpose |
| :--- | :--- | :--- |
| [`gh-pr/scripts/diff-budget.sh`](./gh-pr/scripts/diff-budget.sh) | `gh-pr` | Deterministically calculates changed lines against base ref, applying exclusions (`tests`, `stories`, `e2e`, `plans`, `lockfiles`) with soft (500) and hard (1000) limit verdicts. |
| [`gh-pr/scripts/pr-route.sh`](./gh-pr/scripts/pr-route.sh) | `gh-pr` | Inspects branch and open PR state with minimal token overhead and routes directly to Mode 1, 2, 3, or 4. |
| [`gh-review/scripts/check-sibling-conflicts.sh`](./gh-review/scripts/check-sibling-conflicts.sh) | `gh-review` | Computes pairwise file conflicts across open PRs locally and generates the ready-to-post `@author` merge order comment. |
| [`gh-review/scripts/find-last-review.sh`](./gh-review/scripts/find-last-review.sh) | `gh-review` | Detects whether an open PR requires fresh review (Stage 2), incremental diff re-review (Stage 3), or approval record (Stage 4). |
| [`scripts/validate-skills.sh`](./scripts/validate-skills.sh) | Repo | Validates frontmatter, resolves all internal markdown links, verifies SemVer (`VERSION` and `CHANGELOG.md`), checks script syntax/permissions, and runs unit tests. |

## Semantic Versioning (SemVer)

This repository uses [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html) tracked in [`VERSION`](./VERSION), [`CHANGELOG.md`](./CHANGELOG.md), and `v<MAJOR>.<MINOR>.<PATCH>` git tags:

- `MAJOR`: incompatible changes to skill names, CLI script flags, or required workflow outputs.
- `MINOR`: new skills, workflow modes, or backward-compatible helper scripts.
- `PATCH`: bug fixes, template refinements, and documentation updates.

## Installation

Run `./install.sh` or link manually into `~/.agents/skills/`, `~/.claude/skills/`, and `~/.gemini/config/skills/`:

```bash
git clone https://github.com/huyle-gradion/skills.git ~/Projects/skills
cd ~/Projects/skills
./install.sh
```
