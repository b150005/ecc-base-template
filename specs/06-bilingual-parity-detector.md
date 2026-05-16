# EN/JA Bilingual Parity Detector

## Status

Approved

**Owner:** product-manager / implementer
**Target release:** template v3.7.0

## Problem

The template ships bilingual paired artifacts — ADRs, Specs, agent files, and templates exist in both English (`<name>.md`) and Japanese (`<name>.ja.md`). Humans and agents depend on these pairs being structurally consistent: an agent reading the canonical EN file should be able to trust that the JA translation covers the same sections in the same order, and a human reviewer should be able to verify parity without manually diffing heading trees. No CI check enforces this today. Heading count or order drift between a `.md` and its `.ja.md` counterpart silently misleads Japanese-language readers and agents that prefer the JA artifact. Non-ASCII parentheses in JA files (`（` U+FF08 / `）` U+FF09) violate the template's ADR house style — ASCII `(` `)` are required even in Japanese prose — and creep in when a translator applies full-width typography by reflex. A `.md` with no `.ja.md` counterpart in an in-scope tree (or vice versa) is a parity break that leaves one language without coverage. The #04 and #05 detectors explicitly exclude bilingual parity from their scope; the template's own `check-roadmap-drift.sh` already deliberately excludes `.ja.md` files from its reverse-scan — citing #06 as the contract owner — making the boundary real and load-bearing before this milestone ships.

## Goals

- Detect heading-tree parity breaks: every heading (`#` / `##` / `###` / `####`) in the EN canonical file must have a 1:1 positional counterpart in the JA file and vice versa (same count, same order). A mismatch of count or order — even if individual headings translate correctly — is a parity failure.
- Detect full-width parentheses in JA files: `（` U+FF08 or `）` U+FF09 appearing anywhere in a `.ja.md` file is a style violation that must be reported with the file path and line number.
- Detect presence parity breaks: a `.md` file in an in-scope tree with no corresponding `.ja.md` counterpart (or a `.ja.md` with no `.md` counterpart) is a parity break.
- Run automatically on every push and pull request to `main` with no per-fork configuration step — always-on, matching the posture inherited from ADR-015's subject-matter-presence rule (explicitly naming #06).
- The template repository's own artifacts pass the check at the time this milestone ships (self-baseline / green-by-construction).

## Non-goals

- Auto-generating or auto-correcting any JA translation — the detector reports; humans and `technical-writer` remediate.
- Validating the *semantic content* of JA translations against EN originals — machine translation quality, factual accuracy of translation, and meaning equivalence are human-judgement concerns, not mechanical checks.
- Checking bilingual parity inside files that are intentionally EN-only by design in a carve-out tree. The architect determines which trees are EN-only and codifies the exemption rule in ADR-018; EN-only carve-outs do NOT fail the presence-parity check. The precise definition of in-scope versus carve-out tree sets is an architect decision deferred to ADR-018. <!-- ref-allow: ADR-018 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->
- Checking cross-reference integrity or Roadmap link validity in JA files — that is #04 and #05 scope. The boundary is already enforced: `check-roadmap-drift.sh` excludes `.ja.md` from its reverse-scan precisely because EN/JA back-link parity is this milestone's contract.
- Validating external URLs in either EN or JA files.
- Checking parity inside `workarounds/` registry files.
- Translating the check to CI providers other than GitHub Actions.

## Target users

| Persona | Description | Primary Need |
|---------|-------------|--------------|
| Template maintainer | Developer authoring or updating bilingual design artifacts | Catch heading drift or a missing JA counterpart before the template ships a structurally inconsistent bilingual pair |
| Technical writer | `technical-writer` agent responsible for JA translations | Know immediately when a full-width parenthesis or heading mismatch is introduced, rather than discovering it at human review |
| Agent (orchestrator) | Reads CLAUDE.md and follows artifact links | Trust that a JA artifact referenced anywhere covers the same structural sections as the EN canonical, so reading either is sufficient |
| Template adopter | Forks the template and inherits CI | Start from a bilingual baseline verified structurally consistent, with no configuration step required |

## User stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| Template maintainer | Get a CI failure when a JA translation has fewer or more headings than its EN canonical | Heading drift is caught before any agent or reader is misled by a structurally incomplete translation |
| Technical writer | Get a CI failure naming the file and line when a full-width parenthesis (`（` or `）`) appears in a `.ja.md` file | I fix the style violation immediately rather than accumulating JA-file typography debt |
| Template maintainer | Get a CI failure when a `.md` is added to an in-scope tree without a `.ja.md` counterpart | Presence parity breaks are caught before a single-language artifact reaches main |
| Template adopter | Fork the template knowing every in-scope bilingual pair was structurally verified at the time of forking | I inherit a sound bilingual baseline rather than discovering heading drift after my own translations diverge |

## Acceptance criteria

- **Given** a `.ja.md` file in an in-scope tree has fewer headings (`#`/`##`/`###`/`####`) than its EN `.md` canonical **when** the detector runs **then** it fails with a message naming the file pair and the count mismatch (EN count vs JA count).
- **Given** a `.ja.md` file in an in-scope tree has more headings than its EN `.md` canonical **when** the detector runs **then** it fails with a message naming the file pair and the count mismatch.
- **Given** a `.ja.md` file has the same heading count as its EN canonical but in a different order (positional mismatch) **when** the detector runs **then** it fails naming the first mismatched heading position.
- **Given** a `.ja.md` file contains the character `（` (U+FF08) or `）` (U+FF09) on any line **when** the detector runs **then** it fails naming the file path and the line number of each occurrence.
- **Given** a `.md` file in an in-scope tree has no corresponding `.ja.md` counterpart **when** the detector runs **then** it fails naming the unpaired `.md` file.
- **Given** a `.ja.md` file in an in-scope tree has no corresponding `.md` counterpart **when** the detector runs **then** it fails naming the orphaned `.ja.md` file.
- **Given** a `.md` file resides in a tree the architect has designated as an EN-only carve-out in ADR-018 **when** the detector runs **then** it does NOT fail for the absence of a `.ja.md` counterpart — intentionally EN-only files are exempt from presence-parity. <!-- ref-allow: ADR-018 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->
- **Given** a line in any scanned file contains the comment `<!-- ref-allow: -->` **when** the detector runs **then** it skips validation for that line — the #04/#05 escape hatch is reused by this detector without modification.
- **Given** the template repository's own artifacts at the time this milestone ships **when** the detector runs **then** all checks pass — establishing the template as its own baseline (green-by-construction).
- **Given** the workflow file is present with no per-fork configuration variable or config file **when** a derived repo's CI runs **then** the check executes automatically with no additional setup (always-on default, per the posture inherited from ADR-015).
- **Given** a push or pull request to `main` that introduces a heading-count mismatch between a `.md` and its `.ja.md` **when** the workflow runs **then** the CI job named `bilingual-parity-check` fails and the summary output names the file pair and the specific parity dimension that failed.

## Key interactions

1. `implementer` authors `.claude/meta/scripts/check-bilingual-parity.sh` following the structure established by `.claude/meta/scripts/check-dangling-refs.sh` and `.claude/meta/scripts/check-roadmap-drift.sh` (the reusable pattern from #04/#05): `set -euo pipefail`, repo-root resolution via `git rev-parse`, `pass`/`warn`/`fail_check` helpers, `fail=0` accumulator, `exit "$fail"`. The script implements three checks in sequence: (1) presence-parity scan across in-scope trees, (2) heading-tree parity for each EN/JA pair found, (3) full-width-parenthesis scan of every `.ja.md` in scope. <!-- ref-allow: .claude/meta/scripts/check-bilingual-parity.sh is the deliverable artifact this milestone authorizes; it does not exist yet at Spec authoring time -->
2. `implementer` authors `.github/workflows/bilingual-parity-check.yml` following the structure of `.github/workflows/dangling-ref-check.yml` and `.github/workflows/roadmap-drift-check.yml`: `on: push/pull_request` to `main` path-scoped to the in-scope trees and the script/workflow themselves; a single `check` job running `bash .claude/meta/scripts/check-bilingual-parity.sh`; `permissions: contents: read`; `timeout-minutes: 5`; job name `bilingual-parity-check`. <!-- ref-allow: .claude/meta/scripts/check-bilingual-parity.sh is the deliverable artifact this milestone authorizes; it does not exist yet at Spec authoring time -->
3. The MECE boundary against #04 and #05 must be stated explicitly in the script header: #04 owns cross-reference integrity (ADR-NNN textual references and `.claude/`-rooted path mentions); #05 owns Roadmap bidirectional-link and status-glyph consistency; #06 owns EN/JA translation parity (heading-tree, full-width-parentheses, and presence). The concrete proof the boundary is load-bearing: `check-roadmap-drift.sh` already deliberately excludes `.ja.md` from its reverse-scan loop (citing #06 as the contract owner), so the partition is in force before this script ships.
4. A TDD suite is authored by `implementer` following the `test-check-*.sh` convention used for #04 and #05, covering at least: heading-count mismatch (EN fewer, EN more), positional heading mismatch (same count, different order), full-width paren in a JA file, missing JA counterpart, orphaned JA file, and the green-by-construction baseline (all template artifacts pass).
5. The precise file-set keying (which trees are in-scope vs. EN-only carve-out), the heading-normalization strategy (e.g., whether numbered prefixes or localized heading text requires special handling), and the parsing approach for heading extraction are explicitly deferred to ADR-018 (architect), exactly as specs/05 R-01 deferred structural keying to ADR-017. The Spec states the *what* (the three parity dimensions and their acceptance criteria); the ADR records the structural *how*. <!-- ref-allow: ADR-018 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->
6. No changes to agent prompts are required by this milestone; the detector is a CI layer only.

## Metrics

- **Leading:** CI job `bilingual-parity-check` passes on the template's own `main` branch immediately after the milestone ships.
- **Leading:** Zero `<!-- ref-allow: -->` suppressions required in the template's own artifacts at ship time (the template's bilingual pairs should be structurally clean at baseline; the escape hatch exists for forward-looking work in derived repos).
- **Lagging:** Reduction in "agent or reader encounters a JA artifact with structurally fewer sections than its EN counterpart" incidents in derived repos (observable via session transcripts if teams track it; not a hard metric gate for this milestone).

## Risks and open questions

### Risk R-01: File-set keying and EN-only carve-out definition deferred to ADR-018 <!-- ref-allow: ADR-018 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->

**Description.** This Spec defines the three parity dimensions (heading-tree, full-width-parentheses, presence) but explicitly defers to ADR-018 the question of which directory trees are in-scope and which are EN-only by design. The analog of specs/05 R-01 deferring structural keying to ADR-017. Without ADR-018, the implementer must make ad-hoc in-scope judgements that may contradict later architectural intent. <!-- ref-allow: ADR-018 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->

**Mitigation constraint handed to architect.** ADR-018 must specify: (a) the authoritative list of in-scope trees (or the rule by which in-scope trees are determined), (b) the EN-only carve-out rule (exempting files/trees the template designates as never requiring a JA pair), and (c) the heading-normalization strategy for heading-tree comparison (e.g., whether to strip numbered prefixes before comparison). Until ADR-018 exists, the implementer uses a conservative default: all `.claude/meta/adr/`, `.claude/templates/`, `.claude/agents/`, and `specs/` trees are in-scope; no trees are carved out until the architect rules otherwise. <!-- ref-allow: ADR-018 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->

**Note:** The `<!-- ref-allow: -->` suppression on the Risk R-01 heading line lives only in this Spec file (`specs/06-bilingual-parity-detector.md`), following the precedent set by `specs/05-roadmap-drift-detection-ci.md` for ADR-017 and `specs/03-cross-session-progress-persistence.md` for ADR-016. The suppression does NOT appear in `CLAUDE.md`.

### Risk R-02: Posture inherited without re-litigation

**Description.** ADR-015 §Decision point 3 explicitly states: "Treating #05/#06 as default-off would contradict the subject-matter-presence rule (Roadmap drift and EN/JA parity are also always-present structural contracts), so the rule fixes their posture too." The always-on posture for this milestone is **inherited**, not a new decision. Documenting it as inherited here prevents a future reviewer from re-litigating it without reading the establishing decision.

**This Spec states:** The CI posture for this milestone is always-on, inheriting the subject-matter-presence rule established by ADR-015. No new posture decision is required or appropriate; the rule is binding. ADR-015 names #06 explicitly in §Decision point 3.

### Risk R-03: Heading-normalization edge cases

**Description.** Heading text in JA files is a translation of EN heading text; positional comparison must compare headings by level and position, not by text content. However, numbered prefixes (e.g., `## 1. Context` in EN vs. `## 1. コンテキスト` in JA) or heading-level changes introduced during translation could produce false positives or false negatives if the normalization strategy is wrong.

**Mitigation constraint handed to architect.** ADR-018 must specify the heading-normalization strategy (compare level+position only; strip numeric prefixes before comparison; or another approach). The Spec's acceptance criteria are written in terms of count and order — the architect decides the exact comparison form that satisfies them without false positives. <!-- ref-allow: ADR-018 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->

### Risk R-04: Scope overlap with #04 and #05 detectors

**Description.** #04 catches broken cross-references (path mentions, ADR-NNN textual references) in files including JA files. #05 excludes `.ja.md` from its reverse-scan explicitly (the load-bearing boundary). #06 owns heading/parity/presence. The overlap zone: a JA file with a broken `ADR-NNN` reference in heading text would be caught by #04. This is acceptable — two different failures producing two distinct CI reports for two distinct owners.

**Mitigation.** The script header must state the MECE partition explicitly so a future maintainer never assigns a check to the wrong script. The concrete boundary: `check-roadmap-drift.sh` excluding `.ja.md` from reverse-scan is the existing evidence the partition is enforced before #06 ships.

## Out of scope

- Auto-generating, auto-correcting, or machine-translating JA counterparts.
- Validating semantic translation quality or factual accuracy of JA content.
- Checking parity inside `workarounds/` registry files.
- Checking cross-reference integrity within JA files — that remains #04 scope.
- Translating the check to CI providers other than GitHub Actions.
- Enforcing that non-in-scope trees (as determined by ADR-018) carry JA counterparts. <!-- ref-allow: ADR-018 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->

## References

- ADR-015 (Dangling-reference detector — always-on, subject-matter-keyed CI posture) — §Decision point 3 explicitly names #05 and #06 and fixes their always-on posture as inherited from the subject-matter-presence rule, not a new decision; §Decision point 1 defines the #04 scope boundary that this detector complements without duplicating
- `specs/04-dangling-reference-detector.md` — structural sibling; its Non-goals section explicitly names #06 as the responsible detector for bilingual parity
- `specs/05-roadmap-drift-detection-ci.md` — direct structural sibling; its Non-goals section names #06; its Out-of-scope section names #06; its Risks section (R-04) describes the ADR-017 forward-reference pattern this Spec mirrors for ADR-018; `check-roadmap-drift.sh` already excludes `.ja.md` from its reverse-scan, citing #06 as the contract owner — the concrete proof the scope boundary is load-bearing before this milestone ships <!-- ref-allow: ADR-018 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->
- `.claude/meta/scripts/check-dangling-refs.sh` / `.claude/meta/scripts/check-roadmap-drift.sh` — the reusable script pattern (#04/#05) this milestone's script follows
- `.github/workflows/dangling-ref-check.yml` / `.github/workflows/roadmap-drift-check.yml` — the reusable workflow pattern (#04/#05) this milestone's workflow follows
- ADR-018 — the forthcoming architect decision for this milestone's structural keying: in-scope tree set, EN-only carve-out rule, heading-normalization strategy, and parsing approach (to be authored when this milestone moves to implementation) <!-- ref-allow: ADR-018 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->
- Roadmap row: #06
