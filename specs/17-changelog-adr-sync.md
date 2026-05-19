# CHANGELOG↔ADR-Acceptance Sync and ADR-001–005 Back-fill

## Status

Approved

**Owner:** product-manager
**Target release:** next patch after implementer completes back-fill edits

## Problem

Two related consistency gaps exist in the repository's document corpus:

**Gap 1 — ADR-002/003/004 Status format deviation.** The ADR template
(`adr-template.md`) defines the canonical Status format as
`Accepted — YYYY-MM-DD` (U+2014 em-dash). Roadmap #16 corrected ADR-001
and established the em-dash form as the confirmed template standard.
ADR-005 already uses the em-dash form. However, ADR-002, ADR-003, and
ADR-004 still use a period-separated format (`Accepted. YYYY-MM-DD.`)
in both their EN and JA siblings — six lines total. This means any
reader or tooling that attempts to parse the Status line of ADR-002
through ADR-004 encounters a format inconsistent with the template and
inconsistent with ADR-001 and ADR-005. As of today there is no CI gate
enforcing format uniformity across all ADR Status lines, so the
inconsistency persists silently.

**Gap 2 — No CHANGELOG entry for ADR Status back-fill milestones.** The
CHANGELOG records notable changes milestone by milestone. The ADR-001
Status fix (#16) shipped without a corresponding CHANGELOG entry; the
same gap exists for the ADR-002/003/004 back-fill once it is done. The
CHANGELOG needs one entry under `## [Unreleased]` that records the
back-fill of ADR-001–005 Status format normalization (treating #16's fix
as already-landed background context and #17's fix as the current
entry). Neither gap is user-facing in a product sense; both are
contributor-facing correctness issues that slow down any future tooling
that relies on a uniformly parseable Status line.

## Goals

- Normalize the Status format of ADR-002, ADR-003, and ADR-004 EN files
  to `Accepted — YYYY-MM-DD` (em-dash, matching the template standard
  confirmed by #16).
- Normalize the Status format of the JA siblings of ADR-002, ADR-003,
  and ADR-004 to `Accepted — YYYY-MM-DD` (EN em-dash form, matching the
  dominant corpus pattern confirmed by #16's §Risks resolution).
- Add one CHANGELOG entry under `## [Unreleased]` recording the
  ADR-002/003/004 Status format normalization, with a reference to the
  already-completed ADR-001 fix (#16) as background context.
- Preserve all historical body text, rationale, alternatives, and
  Metadata sections of ADR-002/003/004 (EN and JA) verbatim; only the
  Status line changes in each file.

## Non-goals

- **ADR-001 Status modification** — ADR-001's Status line was corrected
  to `Accepted — 2026-04-22` by Roadmap #16 and is already in template
  standard format. No further change to ADR-001 is required or permitted
  by this milestone.
- **ADR-005 Status modification** — ADR-005 already uses `Accepted —
  2026-04-25` (em-dash form) in both EN and JA. It is already compliant
  and is not touched.
- **ADR-006 through ADR-021 Status format audit** — scanning and
  normalizing the full remaining ADR set (ADR-006 to ADR-021) is
  explicitly out of scope. The three-file back-fill target is
  ADR-002/003/004 only. If ADR-006+ files have format deviations, they
  are a separate future milestone. This milestone is MECE-bounded to the
  five ADRs that existed before the em-dash standard was confirmed (#16);
  of those five, ADR-001 and ADR-005 are already compliant, leaving
  exactly ADR-002/003/004.
- **New CI gate for ADR Status format** — adding a CI check that enforces
  the Status format pattern across all ADR files is not required to
  satisfy this milestone. The back-fill is a one-time mechanical
  correction; a CI gate would be a structural decision warranting its own
  ADR (ADR-018 triad) and is a separate future milestone if the architect
  judges it necessary.
- **CHANGELOG back-fill for milestones prior to #16** — adding CHANGELOG
  entries for ADR-001 through ADR-004's original acceptance dates
  (2026-04-22 through 2026-04-25) is not within scope. The CHANGELOG
  entry added by this milestone covers the Status-format normalization
  event (#17), not the original ADR acceptance events.
- **JA CHANGELOG entry** — a JA CHANGELOG sibling does not currently
  exist in the repository. Creating one is not part of this milestone.
- **Spec JA sibling authoring** — `specs/17-changelog-adr-sync.ja.md` is
  authored by the technical-writer in a later step. This Spec covers EN
  only.
- **ADR-001 vocabulary/concept changes (covered by #16)** — #16 owned
  the ADR-001 Status vocabulary correction (removing `Proposed
  (stabilized)` and correcting to `Accepted — 2026-04-22`). This
  milestone owns the ADR-002/003/004 *format* normalization (period-
  separated → em-dash). The two milestones are MECE: #16 changed the
  vocabulary token in one file; #17 changes the punctuation/separator in
  three files.

## User stories

| As a...                              | I want to...                                                    | So that...                                                      |
|--------------------------------------|-----------------------------------------------------------------|-----------------------------------------------------------------|
| contributor reading any ADR          | see a consistent `Accepted — YYYY-MM-DD` Status format          | I can compare acceptance dates and history without format noise |
| agent or tooling parsing ADR Status  | find a uniform em-dash format in all five early ADRs            | regex or pattern-based tooling does not need special cases      |
| CHANGELOG reader tracking milestones | see a concise entry recording the ADR-001–005 normalization      | the milestone is traceable in the release history               |

## Acceptance criteria

- **AC-1 — ADR-002 EN Status line normalized:**
  Given `.claude/meta/adr/002-growth-domains-location.md` is read,
  when the `## Status` section is inspected,
  then the first non-blank line under `## Status` is exactly
  `Accepted — 2026-04-23` (U+2014 em-dash, date from ADR-002 Metadata
  `Date:` field).

- **AC-2 — ADR-002 EN Status line is the only change:**
  Given a diff of `002-growth-domains-location.md` against the previous
  committed version,
  when the diff is examined,
  then only the Status line is modified; no other line is added, removed,
  or changed.

- **AC-3 — ADR-002 JA Status line normalized:**
  Given `.claude/meta/adr/002-growth-domains-location.ja.md` is read,
  when the `## Status` section is inspected,
  then the first non-blank line under `## Status` is exactly
  `Accepted — 2026-04-23` (EN em-dash form, matching the dominant JA ADR
  corpus pattern established in the #16 §Risks resolution).

- **AC-4 — ADR-002 JA Status line is the only change:**
  Given a diff of `002-growth-domains-location.ja.md` against the
  previous committed version,
  when the diff is examined,
  then only the JA Status line is modified; no other line is added,
  removed, or changed.

- **AC-5 — ADR-003 EN Status line normalized:**
  Given `.claude/meta/adr/003-learning-mode-relocate-and-rename.md` is
  read, when the `## Status` section is inspected,
  then the first non-blank line under `## Status` is exactly
  `Accepted — 2026-04-24`.

- **AC-6 — ADR-003 EN Status line is the only change:**
  Given a diff of `003-learning-mode-relocate-and-rename.md` against the
  previous committed version,
  when the diff is examined,
  then only the Status line is modified; no other line is added, removed,
  or changed.

- **AC-7 — ADR-003 JA Status line normalized:**
  Given `.claude/meta/adr/003-learning-mode-relocate-and-rename.ja.md`
  is read, when the `## ステータス` section is inspected,
  then the first non-blank line under `## ステータス` is exactly
  `Accepted — 2026-04-24` (EN em-dash form, replacing `採択済み。
  2026-04-24。`).

- **AC-8 — ADR-003 JA Status line is the only change:**
  Given a diff of `003-learning-mode-relocate-and-rename.ja.md` against
  the previous committed version,
  when the diff is examined,
  then only the JA Status line is modified; no other line is added,
  removed, or changed.

- **AC-9 — ADR-004 EN Status line normalized:**
  Given `.claude/meta/adr/004-coaching-pillar.md` is read,
  when the `## Status` section is inspected,
  then the first non-blank line under `## Status` is exactly
  `Accepted — 2026-04-25`.

- **AC-10 — ADR-004 EN Status line is the only change:**
  Given a diff of `004-coaching-pillar.md` against the previous committed
  version,
  when the diff is examined,
  then only the Status line is modified; no other line is added, removed,
  or changed.

- **AC-11 — ADR-004 JA Status line normalized:**
  Given `.claude/meta/adr/004-coaching-pillar.ja.md` is read,
  when the `## ステータス` section is inspected,
  then the first non-blank line under `## ステータス` is exactly
  `Accepted — 2026-04-25` (EN em-dash form, replacing `採択済み。
  2026-04-25。`).

- **AC-12 — ADR-004 JA Status line is the only change:**
  Given a diff of `004-coaching-pillar.ja.md` against the previous
  committed version,
  when the diff is examined,
  then only the JA Status line is modified; no other line is added,
  removed, or changed.

- **AC-13 — ADR-001 and ADR-005 are not modified:**
  Given a diff of the entire `.claude/meta/adr/` directory,
  when the diff is examined,
  then `001-developer-growth-mode.md`, `001-developer-growth-mode.ja.md`,
  `005-template-restructure.md`, and `005-template-restructure.ja.md` do
  not appear as changed files.

- **AC-14 — No other ADR files (ADR-006 through ADR-021) are modified:**
  Given a diff of `.claude/meta/adr/`,
  when the diff is examined,
  then only the six target files (ADR-002 EN + JA, ADR-003 EN + JA,
  ADR-004 EN + JA) appear as changed files.

- **AC-15 — CHANGELOG entry added:**
  Given `CHANGELOG.md` is read,
  when the `## [Unreleased]` section is inspected,
  then it contains a new entry under `### Documentation` (or an
  appropriate existing subsection) recording that ADR-002, ADR-003, and
  ADR-004 Status lines (EN and JA) were normalized to the em-dash
  template standard, with a back-reference to the already-completed
  ADR-001 fix in #16.

- **AC-16 — CHANGELOG existing entries are preserved verbatim:**
  Given a diff of `CHANGELOG.md`,
  when the diff is examined,
  then only lines in the new CHANGELOG entry (AC-15) are added; no
  existing CHANGELOG line is removed or modified.

- **AC-17 — Historical narrative preserved:**
  Given each of the six changed ADR files after normalization,
  when the full file is read,
  then all body text, rationale, Alternatives, Consequences, Metadata,
  and any blockquotes are present verbatim and unmodified, identical to
  the pre-change version except for the single Status line.

## Key interactions

The implementer edits exactly six files in `.claude/meta/adr/`:
`002-growth-domains-location.md` (line 5), `002-growth-domains-location.ja.md`
(line 9), `003-learning-mode-relocate-and-rename.md` (line 5),
`003-learning-mode-relocate-and-rename.ja.md` (line 7, currently
`採択済み。2026-04-24。`), `004-coaching-pillar.md` (line 5), and
`004-coaching-pillar.ja.md` (line 7, currently `採択済み。2026-04-25。`).

The implementer also adds one entry to `CHANGELOG.md` under
`## [Unreleased]`. The entry is additive only (no existing CHANGELOG text
is touched). No other files change.

The technical-writer step handles: (a) authoring
`specs/17-changelog-adr-sync.ja.md` (JA Spec sibling, heading-tree parity
owned by #06); and (b) reviewing whether the four `<!-- ref-allow: Roadmap
#17 reserved, not yet authored — intentional MECE-boundary forward-ref -->`
suppressions placed in `specs/16-adr-001-status-resolution.md` (lines 48,
200) and `specs/16-adr-001-status-resolution.ja.md` (lines 25, 146) have
become over-suppressions now that `specs/17-changelog-adr-sync.md` is
a real on-disk file. The technical-writer removes any ref-allow comment
that is now over-suppressing a valid resolved reference.

No new CI detectors or test suites are introduced by this milestone.
The back-fill is a one-time mechanical correction; the existing six
detectors (`check-research-tier-auth`, `check-dangling-refs`,
`check-roadmap-drift`, `check-skill-invariants`, `check-bilingual-parity`,
`check-ecc-delegation-consistency`) and seven test suites are sufficient
to guard the affected artifacts post-normalization. Any future CI gate
for ADR Status format uniformity is a separate milestone and ADR.

## Metrics

- **Leading:** diff of the six target ADR files shows exactly one changed
  line each, matching the `Accepted — YYYY-MM-DD` em-dash pattern.
- **Leading:** CHANGELOG diff shows exactly the new additive entry with no
  deletions or modifications to existing lines.
- **Lagging:** no future tooling or contributor report flags ADR-002,
  ADR-003, or ADR-004 Status lines as non-standard after this fix ships.

## Risks and open questions

- **JA localized token choice:** the #16 §Risks resolution confirmed that
  the EN em-dash form (`Accepted — YYYY-MM-DD`) is the dominant JA ADR
  corpus pattern (17 of 20 JA ADR siblings; `採択済み。` appears in only 2
  files and is not consistent). This Spec mandates the EN em-dash form for
  the three JA targets (AC-7, AC-11) based on that confirmed precedent.
  The implementer should verify at edit time that no new JA ADR siblings
  with a different localized token have been added between #16 and now;
  if the corpus has changed materially, the implementer should flag it
  before committing.
- **ref-allow over-suppression:** now that `specs/17-changelog-adr-sync.md`
  is a real on-disk file, the four `ref-allow` suppressions in #16's Spec
  files (`specs/16-adr-001-status-resolution.md` lines 48 and 200, and
  `specs/16-adr-001-status-resolution.ja.md` lines 25 and 146) may be
  over-suppressing valid resolved references. The technical-writer step
  owns this adjudication and removal (see §Key interactions).
- **CHANGELOG entry category:** the CHANGELOG uses `### Documentation`
  as the subsection for contributor-facing structural changes (ADR
  additions, Spec additions). The new entry for ADR-002/003/004 Status
  normalization fits `### Documentation`; if the existing `## [Unreleased]`
  already has a `### Documentation` block at implementation time, the new
  entry is appended to that block rather than creating a duplicate
  subsection.

## Out of scope

- ADR-001 Status modification (completed by #16; see §Non-goals)
- ADR-005 Status modification (already compliant; see §Non-goals)
- ADR-006 through ADR-021 Status format audit (separate future milestone)
- New CI gate for ADR Status format uniformity (separate future milestone)
- JA CHANGELOG sibling creation
- Any change to ADR body text, rationale, alternatives, or Metadata sections

## References

- Roadmap row: #17
- ADR-002: `.claude/meta/adr/002-growth-domains-location.md`
- ADR-003: `.claude/meta/adr/003-learning-mode-relocate-and-rename.md`
- ADR-004: `.claude/meta/adr/004-coaching-pillar.md`
- ADR-005: `.claude/meta/adr/005-template-restructure.md` (already compliant; not changed)
- ADR template: `.claude/templates/adr-template.md` (Status vocabulary)
- Roadmap #16: `specs/16-adr-001-status-resolution.md` (ADR-001 Status fix — completed prior milestone; MECE boundary for this milestone)
- CHANGELOG: `CHANGELOG.md`
