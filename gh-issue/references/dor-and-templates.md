# Definition of Ready (DoR) and Issue Templates

## Definition of Ready checklist

An issue is ready for implementation when all applicable checks pass:

1. **Template sections present**: All required `### <Heading>` sections from `.github/ISSUE_TEMPLATE/{bug,feature,backlog-item}.yml` are present and non-empty.
2. **Deduplicated**: Open and closed issues were searched; related or prior issues are cited under `Dupes` in `Dev notes`.
3. **Code claims verified**: Every file path, line number, and function name in `Dev notes` was verified with `rg` / `read` in the repository and placed inside `<details><summary>Dev notes (code-read, not run)</summary>`.
4. **Repro or state-complete AC**:
   - Bugs have numbered steps from a concrete starting screen to the observed failure, plus `Expected:` and `Actual:`.
   - Features and backlog items cover `Happy path`, `Error / failure`, `Empty / zero state`, `Edge inputs`, and `Platform behavior`.
5. **Edge states explicit**: Long text, empty state, rapid/concurrent actions, permission boundaries, and viewport constraints are stated rather than left implicit.
6. **Sizing and priority (when using GitHub Projects)**:
   - `Size`: `XS` (< 2h), `S` (0.5-1d), `M` (2-3d), `L` (4-5d), `XL` (> 1w, must be split before sprint entry).
   - `Score`: `User value (1-5) + (Exposure (1-5) * Severity (1-5)) + Roadmap fit (1-5) - Effort risk (1-5)`.
   - `Priority`: `Urgent` (>= 25), `High` (18-24), `Medium` (10-17), `Low` (< 10).
7. **Platform label**: Exactly one `platform:web`, `platform:mobile-app`, or `platform:all` label when the repo uses platform labels.
8. **Open question marker**: `_Open question: none._` (or explicit blocking questions).
9. **Functional spec impact**: `### FS impact` block naming the spec area and requirement IDs (`ADDED`, `MODIFIED`, `REMOVED`, `DOCUMENT`), `none (<reason>)`, or `area not yet specified (<PREFIX>)`.

---

## Bug issue template (modeled on `#1975`)

```markdown
### Summary

<1-3 sentences describing the user-visible defect, when it happens, and how it degrades the experience.>

### Steps to reproduce

1. Open <surface/screen> in a <viewport or state condition>.
2. Perform <user action 1>.
3. Perform <user action 2>.
4. Observe <broken result>.

### Expected vs actual

**Expected:** <Concrete target behavior, including visual, scroll, or state expectations.>

**Actual:** <Measured or observed broken behavior.>

### Impact

<Severity: Critical / High / Medium / Low> (<who is affected, how often, and whether a workaround exists>).

### Area

<web / mobile / server / core / ai / admin / infra>

### Environment

<Browser/OS/viewport or runtime environment, e.g. Web app, desktop viewport (1440 x 900)>

### FS impact

Area: areas/<area>.md
- MODIFIED `<PREFIX>-NNN`: <One-sentence requirement update.>
- ADDED `<PREFIX>-NNN`: <One-sentence new requirement.>

_Open question: none._
_Source: <user report / dogfooding / audit>._

<details>
<summary>Dev notes (code-read, not run)</summary>

- **Cause:** <Plain technical explanation of why the current code produces the bug.>
- **Code:** `<path/to/file.tsx:line>` (`<symbol>`), `<second/path.ts:line>`.
- **Fix direction:** <1-2 sentences describing the structural fix without writing the full patch.>
- **Mobile check:** <Whether `gw-mobile` or sibling clients share the bug or already handle it (`path:line`).>
- **Dupes:** none (or `related to #<N>`).

</details>
```

---

## Feature issue template

```markdown
### Summary

<1-3 sentences stating what capability is being added and for whom.>

### User / business value

<Why this matters to users or the business, and what problem it solves.>

### Acceptance criteria

**Happy path**
- [ ] <Observable behavior when the user completes the primary flow.>

**Error / failure**
- [ ] <What happens on network failure, validation error, or permission denial.>

**Empty / zero state**
- [ ] <What renders when there are zero items or no prior state.>

**Edge inputs**
- [ ] <Behavior on long text, rapid clicks, large attachments, or boundary counts.>

**Platform behavior**
- [ ] <Web vs mobile behavior, keyboard shortcuts, and viewport rules.>

### Out of scope

- <Explicitly excluded items to keep the PR under the 500-line soft limit.>

### Area

<web / mobile / server / core / ai / admin / infra>

### FS impact

Area: areas/<area>.md
- ADDED `<PREFIX>-NNN`: <One-sentence requirement.>

_Open question: none._
_Source: <roadmap / customer request / dogfooding>._

<details>
<summary>Dev notes (code-read, not run)</summary>

- **Code:** `<path/to/file:line>` (`<symbol>`).
- **Fix direction:** <Architectural approach and key integration points.>
- **Mobile check:** <Impact on mobile or shared packages.>
- **Dupes:** none.

</details>
```

---

## Chore / backlog item template

```markdown
### Summary

<What needs to be refactored, upgraded, or cleaned up, and why.>

### Scope

- <Concrete deliverable 1>
- <Concrete deliverable 2>

### Acceptance criteria

- [ ] <Verifiable completion condition 1>
- [ ] <Verifiable completion condition 2>
- [ ] All existing unit, integration, and e2e tests pass without regression.

### Area

<web / mobile / server / core / ai / admin / infra>

### FS impact

none (<internal refactor / CI / tooling with no user-visible behavior change>)

_Open question: none._
_Source: <tech debt / review follow-up from #N>._

<details>
<summary>Dev notes (code-read, not run)</summary>

- **Code:** `<path/to/file:line>`.
- **Direction:** <Implementation notes.>
- **Dupes:** none.

</details>
```
