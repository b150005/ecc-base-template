# ADR-001 "Proposed (stabilized)" Status Resolution

## Status

Approved

**Owner:** product-manager
**Target release:** next patch after architect decision

## Problem

ADR-001 (`001-developer-growth-mode.md`) carries a Status line reading
`Proposed (stabilized). Supersedes earlier drafts...` — a value that is
non-standard in two distinct ways. First, `Proposed (stabilized)` is
outside the vocabulary defined in `.claude/templates/adr-template.md`,
which allows exactly `Proposed | Accepted | Deprecated | Superseded by
ADR-NNN`. Second, `Proposed` misrepresents the current state: ADR-001's
architectural decisions shipped in v1.1.0 and were stabilized through
v1.2.1 (documented in ADR-003 Consequences/Neutral). Every other ADR in
the repository (ADR-002 through ADR-021) uses `Accepted`. The
`(stabilized)` parenthetical is a historical note about stabilization
but is not a recognized status token. This mismatch makes automated
vocabulary checks and human review harder, and misleads any reader who
takes `Proposed` at face value. No other file is affected by this
milestone — ADR-001's body, rationale, alternatives, and existing
partially-superseded blockquote all remain authoritative and are not in
scope.

## Goals

- Bring ADR-001's Status line (`001-developer-growth-mode.md`) into
  conformance with the ADR template vocabulary.
- Bring the JA sibling (`001-developer-growth-mode.ja.md`) into the
  same conformance on the corresponding Status line, mirroring the EN
  change per-line.
- Preserve the full historical narrative of ADR-001: body text,
  rationale, alternatives, Metadata, and the existing "Partially
  superseded by ADR-003" blockquote are untouched.
- The acceptance date recorded in the corrected Status line must agree
  with the owner decisions recorded in ADR-001's own Metadata (`Date:
  2026-04-22`).

## Non-goals

- **CHANGELOG synchronization** — syncing CHANGELOG entries to ADR
  acceptance dates, or back-filling acceptance date metadata for
  ADR-002 through ADR-005, is the scope of Roadmap #17
  (`specs/17-changelog-adr-sync.md`). Roadmap #16 does not touch
  CHANGELOG.
- **ADR Status format normalization across the repository** — ADR-002
  through ADR-004 use `Accepted. YYYY-MM-DD.` (period-separated) while
  ADR-005 through ADR-021 use `Accepted — YYYY-MM-DD` (em-dash). This
  two-format inconsistency exists across the full ADR set and is out of
  scope for this milestone. Only ADR-001's Status line is changed here.
- **New CI detector for ADR vocabulary** — adding a CI check that
  enforces the ADR template vocabulary across all ADRs is not required
  to satisfy this milestone. If the architect judges a CI guard
  necessary as a structural decision, a new ADR may introduce it, but
  it is not part of this spec's acceptance criteria.
- **ADR-001 body rewrite** — the v1.x path references, design
  rationale, alternatives, and "Partially superseded by ADR-003"
  blockquote in ADR-001 are historical records intentionally preserved
  per ADR-003 Consequences/Neutral. They are out of scope.
- **JA heading-tree parity enforcement** — structural parity of the
  `001-developer-growth-mode.ja.md` heading tree with its EN sibling is
  owned by Roadmap #06. This milestone only changes the Status line
  content of the JA file.

## User stories

| As a...                         | I want to...                                                   | So that...                                               |
|---------------------------------|----------------------------------------------------------------|----------------------------------------------------------|
| contributor reading ADR-001     | see a Status that matches the actual shipped state             | I am not misled into thinking decisions are still open   |
| agent or tooling parsing ADRs   | find a standard-vocabulary Status token in ADR-001             | vocabulary checks do not flag a false-positive on ADR-001|
| technical-writer maintaining JA | mirror the Status fix in the JA sibling without extra research | bilingual parity is maintained without double-guessing   |

## Acceptance criteria

- **AC-1 — EN Status line conforms to template vocabulary:**
  Given `.claude/meta/adr/001-developer-growth-mode.md` is read,
  when the `## Status` section is inspected,
  then the first non-blank line under `## Status` is exactly
  `Accepted — 2026-04-22` (em-dash format, matching ADR-005 through
  ADR-021 convention, with the date from ADR-001 Metadata `Date:`
  field) and contains no parenthetical qualifier such as
  `(stabilized)`.

- **AC-2 — EN Status line is the only change in ADR-001 EN:**
  Given a diff of `001-developer-growth-mode.md` against the previous
  committed version,
  when the diff is examined,
  then only the Status line (line 5 in the current file) is modified;
  no other line is added, removed, or changed.

- **AC-3 — JA sibling Status line conforms to template vocabulary:**
  Given `.claude/meta/adr/001-developer-growth-mode.ja.md` is read,
  when the `## ステータス` (or `## Status`) section is inspected,
  then the first non-blank line under that heading is the JA-equivalent
  standard token (`承認済み — 2026-04-22` or the equivalent localized
  form used consistently in other JA ADR siblings in the repository)
  and contains no parenthetical qualifier.

- **AC-4 — JA sibling Status line is the only change in ADR-001 JA:**
  Given a diff of `001-developer-growth-mode.ja.md` against the
  previous committed version,
  when the diff is examined,
  then only the JA Status line is modified; no other line is added,
  removed, or changed.

- **AC-5 — Existing blockquote is preserved:**
  Given `.claude/meta/adr/001-developer-growth-mode.md` after the
  change,
  when the file is read,
  then the "Partially superseded 2026-04-24 by ADR-003" blockquote
  (currently lines 7-9) is present verbatim and unmodified.

- **AC-6 — No other ADR files are modified:**
  Given a diff of the entire `.claude/meta/adr/` directory,
  when the diff is examined,
  then only `001-developer-growth-mode.md` and
  `001-developer-growth-mode.ja.md` appear as changed files.

- **AC-7 — Template vocabulary compliance:**
  Given the ADR template at `.claude/templates/adr-template.md`,
  when the allowed Status values (`Proposed | Accepted | Deprecated |
  Superseded by ADR-NNN`) are compared against ADR-001's new Status
  line,
  then `Accepted` is present as the leading token, satisfying the
  template constraint.

## Key interactions

The implementer edits exactly two files:
`001-developer-growth-mode.md` (line 5) and
`001-developer-growth-mode.ja.md` (the corresponding Status line).
The architect decides before implementation whether the change warrants
a new ADR or can be applied as a direct amendment with no ADR. If a new
ADR is created, the architect adds its link to the Roadmap #16 row's
`adr:` column; this Spec does not prescribe that decision.

The partially-superseded blockquote in ADR-001 (lines 7-9) is retained
unchanged; the Status fix does not conflict with it because the blockquote
describes the ADR-003 supersession scope, not the acceptance status of
ADR-001 itself.

## Metrics

- **Leading:** diff of `001-developer-growth-mode.md` shows exactly one
  changed line matching the AC-1 pattern.
- **Lagging:** no tooling or contributor report flags ADR-001 Status as
  non-standard after the fix is merged.

## Risks and open questions

- **Date choice:** ADR-001 Metadata records `Date: 2026-04-22`. This is
  the owner-decision date and is used as the acceptance date in AC-1.
  If the architect's review surfaces a reason to prefer a different
  date (e.g., the date the last stabilizing decision was recorded in
  a separate context), the architect should document the rationale in
  the implementation commit or a new ADR before merging.
- **JA localized token:** the JA standard token for `Accepted` in other
  JA ADR siblings should be verified by the implementer at edit time.
  If no JA ADR siblings exist yet that use a localized Status token,
  `Accepted — 2026-04-22` (EN) may be used in the JA file to maintain
  consistency with the EN file, pending a future JA style decision.
  **Resolution:** the architect confirmed `Accepted — 2026-04-22` (EN
  em-dash form) for the JA Status line, on three converging grounds:
  (1) dominant corpus pattern — 17 of the 20 JA ADR siblings
  (ADR-005.ja through ADR-021.ja) already use `Accepted — YYYY-MM-DD`
  (EN token, em-dash); the localized Japanese token `採択済み。` appears
  in only 2 files (ADR-003.ja and ADR-004.ja) and is not used
  consistently, so no "consistently-used localized equivalent" exists
  in practice; (2) per-line EN mirroring — EN line 5 is
  `Accepted — 2026-04-22` (AC-1), making the JA value byte-identical
  maximizes EN/JA structural parity per ADR-018 and eliminates
  double-guessing; (3) Spec sanction — AC-3 explicitly permits the EN
  form as the "equivalent localized form used consistently in other JA
  ADR siblings", which the corpus evidence confirms to be the EN
  em-dash form; adopting `承認済み — 2026-04-22` would add a fourth
  style variant without matching any consistent corpus pattern, counter
  to the Non-goal of repo-wide ADR Status normalization.
- **Whether a new ADR is needed:** the architect decides this. Changing
  a single Status line in an existing ADR is a mechanical correction;
  it may not meet the threshold for a new structural-decision ADR. This
  Spec is neutral on that choice.

## Out of scope

- CHANGELOG updates (Roadmap #17)
- ADR-002 through ADR-021 Status format normalization
- New CI vocabulary gate for ADR Status fields
- Any change to ADR-001 body text, rationale, or alternatives

## References

- Roadmap row: #16
- ADR-001: `.claude/meta/adr/001-developer-growth-mode.md`
- ADR-003: `.claude/meta/adr/003-learning-mode-relocate-and-rename.md` (partial supersession scope)
- ADR template: `.claude/templates/adr-template.md` (Status vocabulary)
- Roadmap #17: `specs/17-changelog-adr-sync.md` (CHANGELOG sync — out of scope for #16)
