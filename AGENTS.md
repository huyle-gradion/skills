# Agent workflow rules

Use the `/gh-issue`, `/gh-pr`, and `/gh-review` skillset stored in [`https://github.com/huyle-gradion/skills`](https://github.com/huyle-gradion/skills) when working in this repository or any repository configured with these skills.

## Engineering workflow

1. **Start by working on the task.** Investigate the code, implement the change, and run local verification first.
2. **Look up or create the issue (`/gh-issue`).** Before opening a pull request, run [`/gh-issue`](./gh-issue/SKILL.md) to search the active branch, open issues, and closed issues for a match:
   - If a matching issue exists, record its `#<N>` and mention it (`Closes #<N>` or `Refs #<N>`) when creating the pull request.
   - If no matching issue exists, create a new Definition-of-Ready (DoR) compliant issue grounded in the verified code changes and mention the new `#<N>` when creating the pull request.
3. **Create or update the pull request (`/gh-pr`).** Run [`/gh-pr`](./gh-pr/SKILL.md) to route by branch and PR state:
   - Mode 1 opens a new pull request on `<type>/issue-<N>-<slug>` citing `Closes #<N>` or `Refs #<N>`.
   - Mode 2 commits and pushes incremental updates to an existing open pull request.
   - Mode 3 fixes inline review findings with fail-before test proof and replies inline with `Fixed in <short-sha>.`.
   - Mode 4 rebases or merges `origin/main` in a coordinator merge order.
4. **Review and coordinate merges (`/gh-review`).** Run [`/gh-review`](./gh-review/SKILL.md) to check sibling PR file conflicts, post `F1 · P1` 5-part inline findings, fast-forward incremental re-reviews with revert testing, approve, and post the pre-merge `## Coordinator record`.

## Semantic Versioning (SemVer)

This project follows [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html), tracked in [`VERSION`](./VERSION), [`CHANGELOG.md`](./CHANGELOG.md), and `v<MAJOR>.<MINOR>.<PATCH>` git tags:

- Increment `MAJOR` when making incompatible changes to skill names, required workflow gates, or helper script CLI interfaces.
- Increment `MINOR` when adding a new skill, workflow mode, or backward-compatible helper script.
- Increment `PATCH` when fixing defects, refining templates, or updating documentation.
- Run `./scripts/validate-skills.sh` before every commit and release to verify that [`VERSION`](./VERSION) and [`CHANGELOG.md`](./CHANGELOG.md) stay synchronized.

## Local environment

- Run GitHub CLI commands through `mise` (`mise exec -- gh ...`). The helper scripts in `gh-pr/scripts/` and `gh-review/scripts/` invoke `mise exec -- gh` automatically when `mise` is installed.
