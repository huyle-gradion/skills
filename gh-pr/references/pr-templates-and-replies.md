# Pull request body, update, and reply templates

## Pull request body template (modeled on `#2051`)

```markdown
## Summary

<1-2 sentence explanation of the root cause and how this PR fixes it.>

- **<Component or layer 1>.** <Concrete change and mechanism.>
- **<Component or layer 2>.** <Concrete change and mechanism.>
- **<Component or layer 3>.** <Concrete change and mechanism.>

Design and plan: `docs/plans/YYYY-MM-DD-<issue>-<slug>.md` (when applicable).

Closes #<issue-number>

## Measured

_Include when fixing layout, performance, bundle size, contrast, or quantifiable behavior._

| Case (`<viewport / environment>`) | Before | After |
| --- | --- | --- |
| <Scenario 1> | <Measured before> | <Measured after> |
| <Scenario 2> | <Measured before> | <Measured after> |

FS: updated `<PREFIX>-NNN`, `<PREFIX>-NNM` in `docs/functional-spec/areas/<area>.md`
<!-- Or: FS: no behaviour change (<reason>) -->
<!-- Or: FS: area not yet specified (<PREFIX>) -->

## Acceptance criteria

- [x] <Criterion 1 from the issue>
- [x] <Criterion 2 from the issue>
- [x] <Criterion 3 from the issue>

## Known limits

- <Explicit edge case or non-goal left out of scope, with technical reason.>

## Tests

- `<path/to/test_file>`: <N> unit/integration tests covering <scenarios>. Fail-before verified: <exact assertion that failed before the fix>.
- `<path/to/stories_or_component_test>`: <Storybook play: or component test coverage>.
- `<path/to/e2e_spec>`: <Playwright e2e spec and measured assertions>.
- `make check-q`: <Pass status, or exact list of any pre-existing unrelated failures on `origin/main` verified not touched by this PR>.

## Definition of Done

- [x] Self-reviewed the diff before requesting review
- [x] Acceptance criteria from the linked issue are met
- [x] Unit tests and integration tests added or updated
- [x] `make check-q` (lint + typecheck + unit tests) passes locally
- [x] No secrets, credentials, or `.env` values committed
```

---

## Incremental PR update matrix (Mode 2)

When pushing new commits to an existing open PR in Mode 2, decide whether `gh pr edit` is needed using this table:

| What changed in the new commit(s) | Action on PR metadata |
| --- | --- |
| Internal refactor, cleanup, or fix within existing summary and test files | Do not run `gh pr edit`. Pushing the commit is sufficient. |
| New component or layer touched, or mechanism changed | Update the matching bullet in `## Summary` via `gh pr edit <pr> --body-file <file>`. |
| New test file or changed test pass count | Update the matching line in `## Tests` via `gh pr edit <pr> --body-file <file>`. |
| Layout, latency, or bundle metric changed | Update the `After` column in `## Measured`. |
| Functional spec requirement added or modified | Update the `FS:` declaration line. |
| Acceptance criteria status or items updated | Update the matching checklist items in `## Acceptance criteria`. |
| Files in a new top-level area prefix modified | Run `gh pr edit <pr> --add-label "area:<area>"` (combine with `--body-file` when body sections also changed). |

To patch the PR body safely without losing existing sections or colliding across concurrent sessions, dump the current body to a unique scratch file, edit the affected section in place, and pass it back to `gh pr edit`:

```bash
TMP_BODY=$(mktemp /tmp/pr-body.XXXXXX)
gh pr view <pr> --json body --jq '.body' > "$TMP_BODY"
# Edit "$TMP_BODY" in place to update ## Summary, ## Measured, FS:, ## Acceptance criteria, or ## Tests
gh pr edit <pr> --add-label "area:<new-area>" --body-file "$TMP_BODY"
rm -f "$TMP_BODY"
```
(Omit `--add-label` when labels are unchanged.)

---

## Inline review reply templates (modeled on `#2051` Rounds 1-4)

### Standard inline fix reply

Reply directly to the reviewer's inline comment thread (`POST /repos/{owner}/{repo}/pulls/{pr}/comments/{comment_id}/replies`):

```markdown
Fixed in <short-sha>.

<1-3 sentences explaining the exact code change. If multiple sibling sites were affected, note the shared helper extracted and how each call site now uses it.>

<If any part of the reviewer's failure walkthrough needed adjustment, note it briefly and factually.>

Tests:
- Unit: `<test name 1>` and `<test name 2>` in `<test file>` (<N/N> pass; verified to fail without the fix).
- E2E: `<e2e test name>` in `<e2e spec file>` (<assertion verified>).
```

### Real examples from `#2051`

- **Round 1 (`3f3bc4df9`).**
  > Fixed in 3f3bc4df9. Both `MessageComposer` and `ThreadPanel` now call a shared `focusEditorPreservingScroll(editor, scrollEl)` helper (`gw-web/src/components/composer/composerScroll.ts`), which captures `scrollEl.scrollTop` before `editor.commands.focus()` and restores it immediately after when the scroll container has overflow (`scrollHeight > clientHeight`). Unit tests in `composerScroll.test.ts`, `MessageComposer.height.test.tsx`, and `ThreadPanel.composer-height.test.tsx` plus the Playwright e2e check in `e2e/tests/composer-height.spec.ts` fail without the restore and pass with it.

- **Round 2 (`df2261dd0`).**
  > Fixed in df2261dd0. Moved the remove button inside the scrollable `.composer-gif-preview` container (`top-1.5 right-1.5`) instead of negative offsets (`-top-2 -right-2`) that were clipped by `.composer-scroll-body`'s `overflow-y: auto`. Added a bounding-box assertion in `e2e/tests/composer-height.spec.ts` verifying that all 4 corners of the remove button sit inside `.composer-scroll-body`'s visible rect (`top >= body.top`, `right <= body.right`).

---

## Merge-order and conflict resolution reply (`@`-mention comment)

When a sibling PR from the reviewer's merge order lands on `main` and you rebase or merge `main` into the current PR:

```markdown
@<reviewer-login> #<merged-pr-number> has merged, and `main` is merged into this branch (`<short-sha>`). The <N> conflicts were in `<file-1>`, `<file-2>`, and `<file-3>` (kept #<merged-pr-number>'s <feature A> alongside this PR's <feature B>).

After the merge:
- `<test-command-1>`: <X/X> tests pass.
- `<test-command-2>`: <Y/Y> tests pass.
- `make check-q` / `tsc`: <clean / status>.
```
