# Roadmap Drift-Detection CI

## Status

Approved

**Owner:** product-manager / implementer
**Target release:** template v3.7.0

## Problem

The Roadmap table in `CLAUDE.md` mandates a bidirectional link contract (ADR-014): every row's `spec:` and `adr:` cells must resolve to real artifacts, and every ADR that back-links a Roadmap row must be reflected in that row's `adr:` cell. Neither direction of this contract is verified automatically. A Roadmap row whose `adr:` cell names an ADR that does not back-link it, or an ADR whose `Roadmap row:` back-link names a row whose `adr:` cell does not list that ADR, silently breaks the index. A row's status glyph can be set to an unsanctioned character by a hand-edit with no CI failure. The #04 dangling-reference detector (milestone #04, ADR-015) catches broken ADR/path references in document prose but explicitly does not check the Roadmap-specific bidirectional-link and status-glyph contracts — its Non-goals section explicitly names this milestone as the responsible detector.

ADR-014 §Consequences → Negative acknowledges this gap verbatim: "Index↔reality drift. A Spec or ADR can be created without the Roadmap row being updated, leaving the index stale. There is no automated enforcement in this ADR. Mitigation is *deferred* to a possible future … CI check." This milestone is that deferred mitigation.

## Goals

- Detect Roadmap rows whose `adr:` cell names an ADR file whose `## References` section does NOT carry a `Roadmap row: #NN` back-link matching that row number — the forward direction of the ADR-014 bidirectional-link contract.
- Detect ADRs whose `## References` section carries a `Roadmap row: #NN` back-link where row `#NN`'s `adr:` cell does NOT list that ADR — the reverse direction of the same contract.
- Detect Roadmap rows whose Status cell contains a glyph other than the four sanctioned values (☐ / ◐ / ☑ / ✗).
- Run automatically on every push and pull request to `main` with no per-fork configuration step — always-on, matching the posture inherited from ADR-015's subject-matter-presence rule.
- The template repository's own artifacts pass the check at the time this milestone ships.

## Non-goals

- Checking whether a Roadmap row's `spec:` reserved link resolves to a file on disk. Reserved links (`specs/NN-slug.md`) are explicitly valid-by-design before the Spec is authored (ADR-014 Spec reservation rule); that carve-out is owned by the #04 detector.
- Detecting broken ADR-NNN textual references or `.claude/`-rooted path mentions in prose — those are #04's scope (ADR-015 §Decision point 1).
- Enforcing that any given ADR *must* have a Roadmap back-link. Many ADRs (001–013) predate the Roadmap dogfooding effort and legitimately carry no `Roadmap row:` entry; the template also has ADRs that record design decisions for the Roadmap mechanism itself (ADR-014) rather than for a discrete milestone. The detector checks *consistency when a back-link claim exists*, not *universality of back-links*.
- Auto-repairing any inconsistency — the detector reports; humans and agents remediate.
- Checking external URLs or references inside `workarounds/` registry files.
- Validating the textual content of a Spec file against its Roadmap row one-liner (semantic match is a human judgement, not a mechanical check).

## Target users

| Persona | Description | Primary Need |
|---------|-------------|--------------|
| Template maintainer | Developer updating the Roadmap or authoring ADRs | Catch a missed `adr:` update or back-link before it misleads an agent |
| Agent (orchestrator) | Reads the Roadmap at the Analyze step to locate design artifacts | Trust that `adr:` links in the Roadmap and `Roadmap row:` back-links in ADRs are mutually consistent |
| Agent (architect) | Checks existing `adr:` links before forking a new ADR | Rely on the Roadmap as a sound index rather than re-verifying it by file scan |
| Template adopter | Forks the template and inherits CI | Start from a structurally consistent Roadmap baseline with no configuration step |

## User stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| Template maintainer | Get a CI failure when I add an `adr:` link to a Roadmap row but forget to add a `Roadmap row: #NN` back-link in the ADR | The missing back-link is caught before any agent follows the one-sided reference |
| Agent (orchestrator) | Read a Roadmap `adr:` link knowing it is bidirectionally consistent | I do not navigate to an ADR that does not acknowledge its Roadmap row |
| Template maintainer | Get a CI failure when an ADR carries a `Roadmap row: #NN` back-link but row `#NN` does not list that ADR | A stale ADR back-link is caught before it misleads an agent reading the Roadmap |
| Template maintainer | Get a CI failure when a Roadmap Status cell contains an unsanctioned glyph | Hand-edits that break the four-glyph contract are caught immediately |

## Acceptance criteria

- **Given** a Roadmap row's `Design source` column carries an `adr:` link (e.g. `adr: .claude/meta/adr/015-foo.md`) **when** the detector runs **then** it fails if the named ADR file exists on disk but its `## References` section does not contain a `Roadmap row: #NN` entry where `NN` matches the row number. <!-- ref-allow: fictional example path illustrating the acceptance criterion, not a real reference -->
- **Given** a file under `.claude/meta/adr/` contains a `Roadmap row: #NN` line in its `## References` section **when** the detector runs **then** it fails if row `#NN` in the CLAUDE.md Roadmap table does not include an `adr:` link pointing to that ADR file.
- **Given** a Roadmap row's Status cell contains a character other than ☐, ◐, ☑, or ✗ **when** the detector runs **then** it fails with a message naming the row number and the invalid glyph found.
- **Given** an `adr:` link in a Roadmap row points to a path that does not exist on disk **when** the detector runs **then** it fails — a non-existent `adr:` target is not covered by any reservation-rule carve-out (unlike `spec:` links) and is always a broken reference.
- **Given** an ADR carries no `Roadmap row:` back-link at all **when** the detector runs **then** it does NOT fail — the absence of a back-link is valid for ADRs that predate Roadmap dogfooding or that record design decisions for the Roadmap mechanism itself, not for a discrete milestone.
- **Given** the template repository's own artifacts at the time this milestone ships **when** the detector runs **then** all checks pass — establishing the template as its own baseline.
- **Given** a push or pull request to `main` that introduces a Roadmap `adr:` link without a matching ADR back-link **when** the workflow runs **then** the CI job named `roadmap-drift-check` fails and the summary output names the row number and the specific inconsistency.
- **Given** the workflow file is present with no per-fork configuration variable or config file **when** a derived repo's CI runs **then** the check executes automatically with no additional setup (always-on default, per the inherited posture from ADR-015).
- **Given** a line in any scanned file contains the comment `<!-- ref-allow: -->` **when** the detector runs **then** it skips validation for that line — the #04 escape hatch is reused by this detector without modification.

## Key interactions

1. `implementer` authors `.claude/meta/scripts/check-roadmap-drift.sh` following the structure established by `.claude/meta/scripts/check-dangling-refs.sh` (the reusable pattern from #04): `set -euo pipefail`, repo-root resolution via `git rev-parse`, `pass`/`warn`/`fail_check` helpers, `fail=0` accumulator, `exit "$fail"`. The script parses the Roadmap table from `CLAUDE.md` to extract row numbers and their `adr:` cell values, then cross-checks each ADR's `## References` section for the matching `Roadmap row: #NN` entry — and vice versa for all ADR back-links. <!-- ref-allow: .claude/meta/scripts/check-roadmap-drift.sh is the deliverable artifact this milestone authorizes; it does not exist yet at Spec authoring time -->
2. `implementer` authors `.github/workflows/roadmap-drift-check.yml` following the structure of `.github/workflows/dangling-ref-check.yml`: `on: push/pull_request` to `main` path-scoped to `.claude/CLAUDE.md`, `.claude/meta/adr/`, and the script/workflow themselves; a single `check` job running `bash .claude/meta/scripts/check-roadmap-drift.sh`; `permissions: contents: read`; `timeout-minutes: 5`. <!-- ref-allow: .claude/meta/scripts/check-roadmap-drift.sh is the deliverable artifact this milestone authorizes; it does not exist yet at Spec authoring time -->
3. The script documents the Non-goal carve-outs explicitly in a header block: ADRs without any `Roadmap row:` back-link are exempt; `spec:` reserved links carry their own carve-out in the #04 detector; this script's scope is the `adr:` ↔ back-link bidirectionality and status-glyph well-formedness only.
4. The precise keying logic for distinguishing ADRs that legitimately carry no back-link (pre-Roadmap ADRs, Roadmap-mechanism ADRs) from those that should — and the exact regex or parsing strategy for extracting Roadmap table rows and ADR `## References` sections — is deferred to the architect (ADR-017 or an amendment to an existing ADR). The Spec states the *what* (bidirectional consistency when a claim exists); the ADR records the structural *how*. <!-- ref-allow: ADR-017 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->
5. No changes to agent prompts are required by this milestone; the detector is a CI layer only.

## Metrics

- **Leading:** CI job `roadmap-drift-check` passes on the template's own `main` branch immediately after the milestone ships.
- **Leading:** Zero `<!-- ref-allow: -->` suppressions required in the template's own artifacts at ship time (the template's artifacts should be consistent; the escape hatch exists for forward-looking work in derived repos).
- **Lagging:** Reduction in "agent follows a stale Roadmap `adr:` link to an ADR that does not acknowledge its row" incidents (observable via session transcripts if teams track it; not a hard metric gate for this milestone).

## Risks and open questions

### Risk R-01: False positives from parsing the Roadmap table

**Description.** The Roadmap table in `CLAUDE.md` is Markdown; parsing it with `grep`/`awk` or a simple regex may misparse multi-line `Design source` cells (e.g., rows using `<br>` for multiple `adr:` links). A naive parser may fail to extract all ADR references for a row.

**Mitigation constraint handed to architect.** The ADR must specify the parsing strategy — whether a line-by-line greedy match, a multiline block parser, or a structured extraction approach is used. The Spec's acceptance criteria state *what* must be detected; the architect decides *how* the table is parsed to avoid mis-keying. This is the primary structural keying decision deferred to ADR-017. <!-- ref-allow: ADR-017 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->

### Risk R-02: Posture inherited without re-litigation

**Description.** ADR-015 §Decision point 3 explicitly states: "Treating #05/#06 as default-off would contradict the subject-matter-presence rule (Roadmap drift and EN/JA parity are also always-present structural contracts), so the rule fixes their posture too." The always-on posture for this milestone is **inherited**, not a new decision. Documenting it as inherited here prevents a future reviewer from re-litigating it without reading the establishing decision.

**This Spec states:** The CI posture for this milestone is always-on, inheriting the subject-matter-presence rule established by ADR-015. No new posture decision is required or appropriate; the rule is binding.

### Risk R-03: Scope overlap with #04 detector

**Description.** The #04 dangling-reference detector catches broken `adr:` path references (pointing to a non-existent file) in the document prose scope. This detector catches *bidirectional-link inconsistency* even when both files exist. There is a narrow overlap: a Roadmap `adr:` link pointing to a non-existent ADR file is caught by both detectors.

**Mitigation.** The overlap is acceptable — a single broken link producing two CI failures is a stronger signal than one, and the two checks serve different conceptual owners (the #04 detector owns "does the file exist?"; this detector owns "is the bidirectional contract satisfied?"). The architect should document this in the script header if the overlap becomes a false-positive source.

### Risk R-04: ADR-017 forward reference <!-- ref-allow: ADR-017 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->

**Description.** This Spec names ADR-017 as the forthcoming architect decision for structural keying. ADR-017 does not exist at Spec authoring time and the `<!-- ref-allow: -->` markers in this file suppress the #04 detector's false positives for those lines.

**Note:** The `<!-- ref-allow: -->` suppressions live only in this Spec file (`specs/05-roadmap-drift-detection-ci.md`), following the precedent set by `specs/03-cross-session-progress-persistence.md` for ADR-016. They do NOT appear in `CLAUDE.md` (which would violate ADR-015's amendment restricting `ref-allow` suppressions in the single always-read artifact).

## Out of scope

- Auto-repair of detected drift — the detector reports only.
- Enforcing that all ADRs carry a Roadmap back-link — absence of a back-link is valid for pre-Roadmap and Roadmap-mechanism ADRs.
- Checking `spec:` reserved links for on-disk existence — that is the #04 detector's ADR-014-reservation carve-out domain.
- Validating bilingual parity — that is milestone #06.
- Checking references inside `workarounds/` registry files.
- Translating the check to CI providers other than GitHub Actions.

## References

- ADR-014 (Roadmap index as single entry point) — establishes the bidirectional `adr:` ↔ `Roadmap row:` contract this detector enforces; §Consequences → Negative names this milestone as the deferred mitigation; the Spec reservation rule carve-out (Amendment 2026-05-16) is out of this detector's scope
- ADR-015 (Dangling-reference detector — always-on, subject-matter-keyed CI posture) — §Decision point 3 fixes this milestone's always-on posture as inherited, not new; §Decision point 1 defines the #04 scope boundary that this detector complements without duplicating
- `specs/04-dangling-reference-detector.md` — the structural sibling this milestone models; the #04 Non-goals section explicitly names #05 as the responsible detector for Roadmap drift
- `.claude/meta/scripts/check-dangling-refs.sh` — the reusable script pattern (#04) this milestone's script follows
- `.github/workflows/dangling-ref-check.yml` — the reusable workflow pattern (#04) this milestone's workflow follows
- ADR-017 — the forthcoming architect decision for structural keying of the bidirectionality check and table-parsing strategy (to be authored when this milestone moves to implementation) <!-- ref-allow: ADR-017 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->
- Roadmap row: #05
