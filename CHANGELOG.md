# Changelog

All notable changes to this project are documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) (`MAJOR.MINOR.PATCH`):
- `MAJOR`: incompatible changes to skill names, CLI script flags, or required workflow outputs.
- `MINOR`: new skills, workflow modes, or helper scripts that preserve backward compatibility.
- `PATCH`: bug fixes, template refinements, and documentation updates.

## [1.0.0] - 2026-11-03

### Added

- [`gh-issue`](./gh-issue/SKILL.md) skill and [DoR templates](./gh-issue/references/dor-and-templates.md) for resolving existing issues or creating Definition-of-Ready issues from active work before opening a pull request.
- [`gh-pr`](./gh-pr/SKILL.md) skill, [PR templates](./gh-pr/references/pr-templates-and-replies.md), [`pr-route.sh`](./gh-pr/scripts/pr-route.sh), and [`diff-budget.sh`](./gh-pr/scripts/diff-budget.sh) covering Mode 1 (new PR), Mode 2 (incremental open-PR update), Mode 3 (inline review fix and SHA reply), and Mode 4 (merge-order rebase).
- [`gh-review`](./gh-review/SKILL.md) skill, [review and coordinator formats](./gh-review/references/review-and-coordinator-formats.md), [`find-last-review.sh`](./gh-review/scripts/find-last-review.sh), and [`check-sibling-conflicts.sh`](./gh-review/scripts/check-sibling-conflicts.sh) covering triage, 5-part inline findings, incremental revert-tested re-reviews, and pre-merge coordinator records.
- [`AGENTS.md`](./AGENTS.md) defining the work-first GitHub workflow, the `/gh-issue`, `/gh-pr`, and `/gh-review` skillset from `https://github.com/huyle-gradion/skills`, and Semantic Versioning rules.
- [`scripts/validate-skills.sh`](./scripts/validate-skills.sh) and [`install.sh`](./install.sh) for validating frontmatter, markdown links, SemVer consistency, and helper script unit tests.
