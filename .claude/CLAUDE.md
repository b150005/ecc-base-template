# Project Context

## About This Project

<!-- TODO(init): Replace this entire section before your first agent session.
     The agents read this block on every turn. Vague context = vague output.

     Minimum viable description (1–3 sentences):
       - What does this application do, and for whom?
       - What is the primary tech stack? (language, framework, database)
       - Any hard constraints? (mobile-first, offline-capable, GDPR, etc.)

     Example:
       TaskFlow is a team task management API built with Go + Gin and PostgreSQL.
       It is consumed by a React SPA and an iOS client.
       All data must remain within the EU (GDPR).
-->

[YOUR PROJECT NAME] — [one-line description].

**Stack:** [language] / [framework] / [database]
**Target users:** [who uses this]
**Key constraints:** [performance, compliance, platform, etc.]

## Architecture Principles

- Layered architecture with clear separation of concerns
- Repository pattern for data access abstraction
- Immutable data structures preferred; copy-on-write for state updates
- Dependency injection for testability

## Agent Team

This project uses an agent team for structured development. The **orchestrator** agent coordinates the following specialists:

| Agent | Role |
|-------|------|
| orchestrator | Analyzes issues, creates plans, delegates to specialists |
| product-manager | Product planning, PRD, user stories, acceptance criteria |
| market-analyst | Market research, competitor analysis |
| monetization-strategist | Business model, pricing, revenue strategy |
| ui-ux-designer | UI/UX design, accessibility, usability review |
| docs-researcher | Documentation research, API verification, freshness-safe search (verification-layer / research Generator) |
| research-critic | Adversarial review of external research with primary-source-only citation (verification-layer / research Critic) |
| adversarial-implementer | Parallel-implementation Critic for behavioural-delta verification (verification-layer / implementation Critic, default-off) |
| architecture-critic | Counter-proposal Critic that takes rejected ADR alternatives seriously (verification-layer / design Critic, default-off) |
| architect | System architecture, technology decisions |
| implementer | Code implementation following architecture and TDD |
| code-reviewer | Meta-reviewer: delegates language depth to ECC `*-reviewer`, owns template cross-cutting checks |
| test-runner | Test execution, coverage reporting |
| linter | Static analysis, code style enforcement |
| security-reviewer | Vulnerability detection, OWASP Top 10 |
| performance-engineer | Profiling, bottleneck identification, optimization |
| devops-engineer | CI/CD, deployment strategy, release management |
| technical-writer | Documentation, changelog, bilingual docs |

All agents detect the project ecosystem at runtime by reading this file and project manifest files (package.json, pubspec.yaml, go.mod, etc.).

## Document Templates

- ADR template: `.claude/templates/adr-template.md` (`.ja.md` for Japanese)
- Spec/PRD template: `.claude/templates/spec-template.md` (`.ja.md` for Japanese)

**Forks** decide their own layout: a single-language fork under any top-level
directory (e.g. `adr/001-foo.md`), a bilingual fork split by language (e.g.
`adr/en/001-foo.md`, `adr/ja/001-foo.md`). The template imposes no layout on
forks — only the templates. **This repository is pinned** (dogfooding posture,
a different audience — not in tension with the fork freedom above): Spec files
live in `specs/`, ADR files in `.claude/meta/adr/` (three-digit zero-padded
prefix), both at the repo root. Not a free choice here — `specs/` is fixed by
ADR-014's reservation rule (every row's reserved `spec:` link is
`specs/NN-slug.md`) and `.claude/meta/adr/` is where every ADR to date lives;
`product-manager` authors a Spec at the row's reserved path, `architect` a new
ADR in `.claude/meta/adr/`. An EN Spec and its JA sibling co-exist in the
**same** `specs/` directory (`specs/NN-slug.md`, `specs/NN-slug.ja.md`) — not
split by language (the `adr/en/` / `adr/ja/` example is fork-illustrative);
heading-tree parity of the pair is owned by Roadmap #06.

## CLAUDE.md authoring guidance

When creating or significantly restructuring this file (or `README.md` or
`.claude/agents/*.md`), invoke the **claude-md-authoring** Skill at
`.claude/skills/claude-md-authoring/SKILL.md`. The Skill provides a
Pre/Post checklist, four invariant rules verified against Anthropic's
official docs, and a runtime protocol for volatile values. Routine
small edits (typo, single bullet, version bump) do not need the Skill.
See `.claude/meta/adr/007-claude-md-authoring-skill.md` for the design
rationale.

**Sanctioned line-budget exception (per ADR-014 amendment 2026-05-16).** The `## Roadmap` section is exempt from the ~200-line CLAUDE.md guidance. The Roadmap is the single always-read entry point for design artifacts and must survive compaction (Invariant 2), so it cannot be relocated to a subdirectory `CLAUDE.md` or a Skill without defeating its purpose. The "around 200" rule is a volatile guideline, never a hard CI failure; it yields to the Roadmap by design. Reclaim budget by compressing Roadmap row text (index-only) and trimming non-compaction-durable sections elsewhere — not by moving the Roadmap.

## Developer Learning Mode

Default-off learning layer with two orthogonal pillars: the **knowledge pillar**
(agents contribute teaching moments to a domain-organized knowledge base) and the
**coaching pillar** (agents change how they work during implementation based on a
chosen coaching style). At session start, read `.claude/learn/config.json`; if
absent or `"enabled": false`, skip all learning behavior entirely. If
`"enabled": true`, read `.claude/skills/learn/preamble.md` for the enrichment
contract. Also read `coach.style` from `.claude/learn/config.json`; if non-`default`
and the style file exists at `.claude/skills/learn/coach-styles/<style>.md`, load
and apply the `behavior-rule` for this turn.

Toggled only via the `/learn` Skill. Use `/learn coach <style>` to set the coaching
style; `/learn coach list` to see available styles. The complete design lives in
`.claude/meta/` (template-internal):

- `.claude/meta/adr/001-developer-growth-mode.md` — original Learning Mode design
- `.claude/meta/adr/003-learning-mode-relocate-and-rename.md` — Learning Mode rename and relocation
- `.claude/meta/adr/004-coaching-pillar.md` — coaching pillar design
- `.claude/meta/prd/developer-learning-mode.md` — full functional specification
- `.claude/meta/references/domain-taxonomy.md` — domain definitions

## Plan-First & Learning-Aware Defaults

This template ships with `permissions.defaultMode: "plan"` in
`.claude/settings.json` (per ADR-009). New sessions therefore boot in
**Plan Mode**: Claude proposes a plan and waits for explicit approval
before any write or shell side effect. Toggle off for the current
session with Shift+Tab, or override per developer in
`.claude/settings.local.json`.

A learning-aware custom output style is shipped at
`.claude/output-styles/ecc-learn.md`. It builds on the built-in
`Learning` style — Claude inserts `TODO(human)` markers so you write
small fragments yourself — and adds short `Insight:` notes that explain
*why* a non-obvious choice was made. Selection is opt-in: choose it
once via `/output-style ecc-learn`.

The coaching hook is implemented in `.claude/hooks/coaching-context.sh`
(self-documenting inline docblock) and registered in
`.claude/settings.json` under `UserPromptSubmit`; the coaching pillar
design rationale is in `.claude/meta/adr/004-coaching-pillar.md`.

## Roadmap

Single entry point mapping each milestone to its authoritative design source. Each row is one milestone; the linked Spec/ADR is the source of truth for content — this table is an index only, never duplicating acceptance criteria or rationale. See `.claude/meta/adr/014-roadmap-index-single-entry-point.md` for the rationale.

**Spec reservation rule:** Every row carries a `spec:` link at row-creation time using the deterministic path `specs/NN-slug.md`. The Spec *file* is authored by `product-manager` when the milestone is picked up (status moves to `◐ in-progress`). The reserved link satisfies ADR-014's 1:1 mandatory mapping without requiring all 21 Spec files to exist upfront; the `implementer`/`test-runner` contract is triggered only after the file is authored.

| # | Milestone | Status | Design source |
|---|-----------|--------|---------------|
| 01 | Commit `verification.yml` as active default | ☑ done | spec: `specs/01-ship-verification-yml-committed.md` |
| 02 | CodeQL single-switch activation via repository variable | ☑ done | spec: `specs/02-codeql-single-switch-activation.md` |
| 03 | Cross-session milestone progress persistence | ☑ done | spec: `specs/03-cross-session-progress-persistence.md`<br>adr: `.claude/meta/adr/016-cross-session-progress-persistence.md` |
| 04 | CI detector for dangling ADR/skill cross-references | ☑ done | spec: `specs/04-dangling-reference-detector.md`<br>adr: `.claude/meta/adr/015-dangling-reference-detector.md` |
| 05 | Roadmap drift-detection CI | ☑ done | spec: `specs/05-roadmap-drift-detection-ci.md`<br>adr: `.claude/meta/adr/017-roadmap-drift-detector.md` |
| 06 | EN/JA bilingual parity detector | ☑ done | spec: `specs/06-bilingual-parity-detector.md`<br>adr: `.claude/meta/adr/018-bilingual-parity-detector.md` |
| 07 | Roadmap status-transition ownership assignment | ☑ done | spec: `specs/07-roadmap-status-transitions.md` |
| 08 | Orchestrator Analyze row-guard | ☑ done | spec: `specs/08-orchestrator-row-guard.md` |
| 09 | Spec filename convention alignment (`NN-slug.md`) | ☑ done | spec: `specs/09-spec-filename-convention.md` |
| 10 | Spec/ADR directory location pin in CLAUDE.md | ☑ done | spec: `specs/10-spec-adr-directory-pinning.md` |
| 11 | Opt-in trigger guidance for implementation/design verification domains | ☑ done | spec: `specs/11-verification-domain-opt-in-guidance.md` |
| 12 | CI coverage gate (80% hard check) | ☑ done | spec: `specs/12-coverage-ci-gate.md`<br>adr: `.claude/meta/adr/019-coverage-ci-gate.md` |
| 13 | ECC-absent degraded-review signal | ☑ done | spec: `specs/13-ecc-absent-signal.md`<br>adr: `.claude/meta/adr/020-ecc-absent-signal.md` |
| 14 | Research-tier validation for auth→T2 mis-classifications | ☑ done | spec: `specs/14-research-tier-validation.md`<br>adr: `.claude/meta/adr/021-research-tier-auth-validation.md` |
| 15 | `init.sh` Roadmap placeholder cleanup at fork time | ☑ done | spec: `specs/15-init-sh-roadmap-cleanup.md` |
| 16 | ADR-001 "Proposed (stabilized)" status resolution | ☑ done | spec: `specs/16-adr-001-status-resolution.md` |
| 17 | CHANGELOG↔ADR-acceptance sync and ADR-001–005 back-fill | ☑ done | spec: `specs/17-changelog-adr-sync.md` |
| 18 | CI exemption allowlist expiry/review mechanism | ☑ done | spec: `specs/18-ci-exemption-allowlist-expiry.md`<br>adr: `.claude/meta/adr/022-ci-exemption-expiry.md` |
| 19 | Workaround tracking default-on | ☑ done | spec: `specs/19-workaround-tracking-default-on.md`<br>adr: `.claude/meta/adr/006-upstream-workaround-tracking.md` (amended 2026-05-20) |
| 20 | Commit `compliance.yml` as active default | ☑ done | spec: `specs/20-ship-compliance-yml-committed.md`<br>adr: `.claude/meta/adr/011-compliance-checklist-skill.md` (amended 2026-05-20) |
| 21 | Quality-gate loop re-entry anchored to Roadmap row | ☐ todo | spec: `specs/21-quality-gate-row-anchor.md` |

**Rules:**
- One row per milestone; row number stable, never reused (follows ADR-number convention). A split = new row + note on old row.
- `Design source` names the type explicitly: `spec:` and/or `adr:` links. `spec:` paths are reserved at row-creation even if the file does not yet exist on disk.
- Spec filename convention: a Spec file is `specs/NN-slug.md` where `NN` is the row number zero-padded to a two-digit minimum (`1→01`; rows ≥100 written without extra padding) and `slug` is the kebab-case slug already fixed in the row's reserved `spec:` path (copy it from the row, do not re-derive). The JA sibling is `specs/NN-slug.ja.md` (same `NN`/`slug`, `.ja` before `.md`); its heading-tree parity is owned by #06. `specs/NN-progress.md` is excluded — `progress` is ADR-016's reserved suffix, governed by ADR-016's lifecycle, not by this convention. #10 pins the directory; #09 pins the filename — MECE; see `## Document Templates` for the pinned `specs/` and `.claude/meta/adr/` directories.
- Milestone ↔ Spec is 1:1 mandatory; Milestone → ADR is 0:1 or 1:N (only when a structural decision occurred; the ADR's `## References` back-links the row number).
- Status = implementation state: ☐ todo / ◐ in-progress / ☑ done / ✗ dropped. Dropped rows stay (history not rewritten).
- Index only — never duplicate acceptance criteria or rationale; the linked Spec/ADR is the source of truth.
- Write-ownership: `product-manager` creates/updates the row + `spec:` link; `architect` adds the `adr:` link; `orchestrator` only reads.
- Status glyph transitions: `product-manager` flips `☐→◐` atomically with authoring the Spec at pickup, and `◐→☑` after the step-6 quality gate passes (deleting `specs/NN-progress.md` in the same change per ADR-016); drops (`◐→✗`, `☑→✗`) are decided by `orchestrator` at Analyze and written by `product-manager`, row retained (history not rewritten). #05 checks glyph *value* well-formedness; #07 governs *who* flips and *when* — no CI enforces #07.
- At 100+ milestones, split into `### Phase N` sub-tables under `## Roadmap`.

## Development Workflow

1. **Issue Analysis**: Feed issues to the orchestrator via GitHub MCP or copy-paste. For defect reports, the orchestrator runs the **ours vs. upstream triage** (3-step protocol via docs-researcher) before deciding the workflow path
2. **Product Planning**: The product-manager creates a spec, user stories, and acceptance criteria using `.claude/templates/spec-template.md`
3. **Research & Reuse**: Search GitHub, package registries, and docs before writing new code. When the result will inform a decision (architecture, library selection, API usage, version pin), invoke the **verification-layer** Skill — research domain (`.claude/skills/verification-layer/research/protocol.md`; shared invariants in `.claude/skills/verification-layer/SKILL.md`). The `docs-researcher` (Generator) declares a Tier and the `research-critic` (Critic) reviews using a different tool family with primary-source-only citation. Default config in `.claude/verification.yml`; opt out via `research.enabled: false`. The same Skill also covers the **implementation** and **design** domains (default-off; opt in per domain). See ADR-008 (research) and ADR-010 (generalization) for rationale.
4. **Architecture**: The architect designs the solution; significant decisions are recorded as ADRs using `.claude/templates/adr-template.md`
5. **Implementation**: The implementer writes code following TDD (RED → GREEN → IMPROVE). When the implementation is a workaround for an upstream defect, the implementer also places a `WORKAROUND-UPSTREAM(<owner>/<repo>#<issue>, fixed=>=<version>)` marker and copies `.claude/templates/workaround-template.md` to `workarounds/NNN-*.md` (the default `registry_dir`; or `docs/workarounds/NNN-*.md` if you keep a `docs/` tree — match `registry_dir` in `.github/workaround-tracker.yml`)
6. **Quality Gate**: The code-reviewer (delegates language depth to the matching ECC `<lang>-reviewer`, owns template cross-cutting checks), linter, security-reviewer, and performance-engineer validate the implementation
   - **6a. Compliance check (opt-in)**: When `.claude/compliance.yml` has `compliance.enabled: true` and a non-empty `target_jurisdictions`, the **compliance-checklist** Skill (`.claude/skills/compliance-checklist/SKILL.md`, per ADR-011, default-off) is invoked by `product-manager` / `security-reviewer` / `technical-writer` for capabilities that may have legal exposure (chat, payments, PII collection, data egress). The Skill produces a checklist with primary-source citations and a mandatory disclaimer; it never marks items as "complied with" — only the human reviewer can
7. **Documentation**: The technical-writer updates docs and changelog. When a workaround is removed, the technical-writer maps `user_impact` to the appropriate CHANGELOG category (`internal` / `changed` / `fixed`)
8. **Release**: The devops-engineer manages deployment and release
9. **Commit**: Conventional commits format (feat, fix, refactor, docs, test, chore, perf, ci)

When an `◐ in-progress` milestone crosses a session or compaction boundary, its in-flight workflow state persists to `specs/NN-progress.md` (`NN` = the Roadmap row number) per ADR-016 — created/updated by `product-manager`/`implementer` at the boundary, read by `orchestrator` at the Analyze step, deleted on the `◐ → ☑`/`✗` flip, and composable with (not a replacement for) `/save-session`.

### Ref-allow expiry review cadence

**Ref-allow expiry review cadence (ADR-022).** ref-allow markers in
template artifacts may carry an optional `| expires: YYYY-MM-DD`
clause. Expired markers produce a WARN (not FAIL) from
`.claude/meta/scripts/check-ref-allow-expiry.sh`. Review ownership is
three-tier: (a) template maintainers review template-internal markers
in `specs/`, `.claude/meta/adr/`, `.claude/CLAUDE.md`, and
`.claude/agents/`; (b) fork maintainers review markers authored in
their derived repositories; (c) the `technical-writer` removes markers
that have become over-suppressions (i.e., the referenced artifact now
exists on disk) as part of step 7 documentation work for each
milestone. The pre-#18 reason-only form remains permanent grandfather.

### Upstream workaround lifecycle

When a defect is traced to an upstream library or framework, follow the
lifecycle defined in ADR-006: triage → search → record → track → remove.
See `.claude/meta/references/upstream-workaround-tracking.md` for the
day-to-day usage details and `.claude/meta/adr/006-upstream-workaround-tracking.md`
for the rationale. The CI scaffold lives at
`.github/workflows/workaround-check.yml` and ships **default-on**
(per Roadmap #19 / ADR-006 amendment 2026-05-20). Deactivation is a
single switch — set `enabled: false` in
`.github/workaround-tracker.yml`. There is no second toggle to remove
from the workflow file. Forks that wish to opt out flip the single
switch off; the `annotate_dependabot_prs` and `fail_on_marker_drift`
overlays remain `false` by default and are unaffected by this change.

## Testing Requirements

- Minimum 80% test coverage
- Unit tests for individual functions
- Integration tests for API/database operations
- E2E tests for critical user flows

## Code Quality Standards

- Functions: < 50 lines
- Files: 200-400 lines typical, 800 max
- Validate all inputs at system boundaries
- Handle errors explicitly at every level
- Never hardcode secrets; use environment variables

## Extending This File

Derived projects should:

1. Replace the "About This Project" section with project-specific context.
   The fastest way is to run `.claude/meta/scripts/init.sh` once after forking;
   it interactively replaces the placeholder. Manual editing is fine too.
2. Add framework-specific architecture details (e.g., state management, routing).
3. Add framework-specific testing tools (e.g., Jest, pytest, go test).
4. Add framework-specific code style rules (e.g., Biome, Ruff, gofmt).
5. Keep the universal sections (workflow, testing requirements, code quality).
6. Fill the Roadmap section as you plan milestones; let `product-manager` own row creation.
7. To activate CodeQL scanning, create a repository variable `CODEQL_ENABLED=true` in GitHub Settings > Secrets and variables > Actions > Variables tab; absent or any other value keeps the job skipped.
8. If you do not plan to use Developer Learning Mode, delete `.claude/meta/`,
   `.github/workflows/learn-invariants.yml`, and the
   `## Developer Learning Mode` section above.
