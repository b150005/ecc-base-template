# CI Detector for Dangling ADR/Skill Cross-References

## Status

Approved

**Owner:** product-manager / implementer
**Target release:** template v3.7.0

## Problem

The template ships design artifacts — CLAUDE.md, ADRs, Specs, Skills — that cross-reference each other heavily: ADRs cite sibling ADRs by number ("see ADR-007", "per ADR-012"), CLAUDE.md names script paths and skill directories by path, Specs carry `spec:` and `adr:` links back-referencing Roadmap rows, and Skills link to sibling files with relative paths. None of these references are verified automatically. A rename, move, deletion, or typo in a number silently creates a dangling reference that misleads agents reading the document (the orchestrator resolves design artifacts through CLAUDE.md; the implementer resolves the Spec through the Roadmap row; the architect reads prior ADRs for consistency before creating a new one). The existing `check-skill-invariants.sh` Check 4 validates relative-path links inside `SKILL.md` files only; it does not validate ADR-NNN textual references in any file, nor path mentions in CLAUDE.md, ADRs, or Specs. This gap was identified as the highest-leverage correction in the template gap analysis because milestones #05 (Roadmap drift CI) and #06 (bilingual parity CI) follow the same detector pattern — closing #04 first establishes the infrastructure both later milestones can reuse or mirror.

## Goals

- Detect ADR-NNN textual references (e.g. "ADR-007", "ADR-012") in CLAUDE.md, ADR files, Spec files, and Skill files that name a number for which no corresponding `.claude/meta/adr/NNN-*.md` file exists.
- Detect explicit `.claude/`-rooted or relative path mentions in CLAUDE.md, ADR files, and Spec files that resolve to no file on disk — catching renamed or deleted artifacts before agents consume the stale reference.
- Provide a deliberate escape-hatch comment syntax (`<!-- ref-allow: -->`) so that intentionally forward-looking references (beyond the reservation rule) can be suppressed per-line without disabling the entire check.
- Run automatically on every push and pull request to `main` with no per-fork configuration step required — always-on, like `skill-invariants.yml`, not default-off like `workaround-check.yml`.
- The template repository's own artifacts pass the check at the time this milestone ships.

## Non-goals

- Validating **reserved Spec links** (`spec: specs/NN-slug.md` in the Roadmap table) where the `specs/NN-slug.md` file does not yet exist on disk. The ADR-014 Spec reservation rule explicitly permits these as valid-by-design; a reserved link whose file has not yet been authored is intentionally allowed to dangle. The detector must recognize and skip Roadmap `spec:` links whose target matches the deterministic `specs/NN-slug.md` pattern, treating them as in-reservation references rather than errors. This carve-out must be clearly documented in the script.
- Validating hyperlinks to external URLs (GitHub, docs sites, etc.) — network-dependent checks belong in a separate optional job, not an always-on structural linter.
- Catching broken Roadmap `adr:` back-links (that is milestone #05, Roadmap drift detection CI).
- Validating bilingual parity (that is milestone #06).
- Fixing or auto-correcting any dangling reference — the detector reports; humans and agents remediate.
- Validating references inside generated or vendored files outside the `.claude/` tree and `specs/` directory.

## User stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| Template maintainer | Get a CI failure when an ADR rename leaves a stale "see ADR-NNN" reference in another document | The refactor is caught before it misleads any agent in a derived repo |
| Template adopter | Fork the template knowing its internal cross-references are structurally sound | I start from a baseline where agents can trust the document index they read |
| Agent (orchestrator) | Read CLAUDE.md and follow `spec:` / `adr:` links knowing they resolve | I do not waste context budget tracing a path that does not exist |
| Implementer | Add a forward reference to an ADR not yet written and suppress the false positive in one line | I can document intent without a CI red before the artifact exists |

## Acceptance criteria

- **Given** a file under `.claude/meta/adr/`, `.claude/agents/`, `specs/`, or `.claude/CLAUDE.md` contains the text `ADR-NNN` (three or more digits) **when** the detector runs **then** it fails with a descriptive message if no file matching `.claude/meta/adr/NNN-*.md` exists on disk, where NNN is the same zero-padded number.
- **Given** a file under `.claude/meta/adr/`, `specs/`, or `.claude/CLAUDE.md` contains an explicit `.claude/`-rooted path string (e.g. `.claude/meta/scripts/foo.sh`, `.claude/skills/bar/SKILL.md`) **when** the detector runs **then** it fails if that path does not resolve to a real file or directory at repo root. <!-- ref-allow: fictional example paths illustrating the acceptance criterion, not real references -->
- **Given** a Roadmap `spec:` link of the form `specs/NN-slug.md` exists in CLAUDE.md **when** the detector runs **then** it does NOT fail if that file does not yet exist on disk, treating the link as an in-reservation reference (ADR-014 Spec reservation rule).
- **Given** a line in any scanned file contains the comment `<!-- ref-allow: -->` (the escape-hatch marker) **when** the detector runs **then** it skips reference validation for that line and emits no warning or failure for references on that line alone.
- **Given** the template repository's own artifacts at the time this milestone ships **when** the detector runs **then** all checks pass (zero dangling ADR references, zero dangling paths) — establishing the template as its own baseline.
- **Given** a push or pull request to `main` that introduces a new file with a dangling ADR reference **when** the workflow runs **then** the CI job named `dangling-ref-check` fails and the summary output names the file, line number, and the specific reference that is dangling.
- **Given** the workflow file is present with no per-fork configuration variable or config file **when** a derived repo's CI runs **then** the check executes automatically with no additional setup (always-on default).
- **Given** a relative-path link inside a `SKILL.md` file that already passes `check-skill-invariants.sh` Check 4 **when** the dangling-reference detector runs **then** the detector does not double-report that same link — its scope is CLAUDE.md, ADRs, Specs, and top-level agent files only, avoiding overlap with the existing Skill invariant check.

## Key interactions

1. `implementer` authors `.claude/meta/scripts/check-dangling-refs.sh` following the structure of `check-skill-invariants.sh`: `set -euo pipefail`, repo-root resolution via `git rev-parse`, `pass` / `warn` / `fail_check` helpers, `fail=0` accumulator, `exit "$fail"`.
2. `implementer` authors `.github/workflows/dangling-ref-check.yml` following the structure of `skill-invariants.yml`: `on: push/pull_request` scoped to the relevant paths, a single `check` job running `bash .claude/meta/scripts/check-dangling-refs.sh`, `permissions: contents: read`, `timeout-minutes: 5`.
3. The script comments document the reservation-rule carve-out explicitly: a prominent block comment names ADR-014's Spec reservation rule and explains why `specs/NN-slug.md` targets are exempt from the existence check.
4. The script documents the `<!-- ref-allow: -->` escape hatch with an example in a comment block near the top.
5. No changes to agent prompts are required by this milestone; the detector is purely a CI layer.

## Metrics

- **Leading:** CI job `dangling-ref-check` passes on the template's own `main` branch immediately after the milestone ships.
- **Leading:** Zero `<!-- ref-allow: -->` suppressions required in the template's own artifacts at ship time (the template's references should be clean; the escape hatch exists for forward-looking work in derived repos).
- **Lagging:** Reduction in "agent follows a broken ADR/path reference" incidents in derived repos (observable if teams track it; not a hard metric gate for this milestone).

## Risks and open questions

- **Risk: false positives from prose text.** An ADR-NNN pattern in a commit message excerpt, a code snippet showing a variable name, or a code block could trigger a false positive. Mitigation: scope the check to known document files (`.claude/meta/adr/`, `specs/`, `CLAUDE.md`, `.claude/agents/`) rather than all files; exclude fenced code blocks if they are a source of noise (a `<!-- ref-allow: -->` escape hatch handles remaining edge cases).
- **Risk: reservation-rule carve-out is too broad.** If the `specs/NN-slug.md` exemption pattern is written loosely, it could suppress real dangling Spec links. Mitigation: the carve-out must be keyed to the exact deterministic path pattern (`specs/` prefix, two-digit `NN`, hyphen, slug, `.md` suffix) and applied only to references found in the Roadmap `Design source` column — not to all `specs/` mentions.
- **Open question: Should the check cover `.claude/agents/` files?** Agent files reference ADR numbers and paths frequently. Recommended: yes, include agent files in the ADR-NNN check but exclude them from the path-mention check (agent files name conceptual paths that may not be repo-local). The implementer resolves this during authoring; an ADR is not required for this scoping decision.
- **Open question: Zero-padding convention for ADR numbers.** Current ADRs use three-digit zero-padding (`001`, `007`, `014`). The detector must handle both `ADR-7` and `ADR-007` as references to the same file; normalization to three digits before lookup is the recommended approach.

## Out of scope

- Auto-remediation of broken references.
- Checking references inside `workarounds/` registry files.
- Validating that the linked Spec file's *content* matches the Roadmap row's one-liner (that is #05 territory).
- Checking external URLs.
- Translating the check to other CI providers (GitHub Actions only for this milestone).

## References

- `.claude/meta/scripts/check-skill-invariants.sh` — structural model for the new script
- `.github/workflows/skill-invariants.yml` — structural model for the new workflow
- `specs/01-ship-verification-yml-committed.md` — companion milestone in the same release
- `specs/02-codeql-single-switch-activation.md` — companion milestone in the same release
- ADR-014 (Roadmap index as single entry point) — defines the Spec reservation rule and the `spec:`/`adr:` link contract that the detector must respect; Amendment 2026-05-16 defines the reservation-rule carve-out
- ADR-007 (CLAUDE.md Authoring Skill) — referenced by ADR-014; the Skill invariant check (`check-skill-invariants.sh` Check 4) this milestone complements
- Roadmap row: #04
