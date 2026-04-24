# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [2.0.0] — 2026-04-24

### Breaking Changes

Developer Growth Mode has been renamed to **Developer Learning Mode** with a full
directory relocation and terminology change. See
[ADR-003](docs/en/adr/003-learning-mode-relocate-and-rename.md) for rationale and
[docs/en/migration/v1-to-v2.md](docs/en/migration/v1-to-v2.md) for upgrade
instructions.

Breaking changes (exhaustive):

- Feature renamed: Growth Mode → Learning Mode
- Skill command: `/growth` → `/learn`
- Directory relocated: `.claude/growth/` → `learn/` (project root)
- Knowledge output: `.claude/growth/notes/<domain>.md` → `learn/knowledge/<domain>.md`
- Skill moved: `.claude/skills/growth/` → `.claude/skills/learn/`
- Terminology: "notes" / "notebook" → "knowledge"
- Trailer labels: `## Growth: taught this session` → `## Learning: taught this session`,
  `## Growth: notebook diff` → `## Learning: knowledge diff`
- Agent section marker: `## Growth Domains` → `## Learning Domains`
- Config path: `.claude/growth/config.json` → `learn/config.json`
- Preamble path: `.claude/growth/preamble.md` → `learn/preamble.md`
- CI script renamed: `scripts/check-growth-invariants.sh` → `scripts/check-learn-invariants.sh`

Migration impact: forks that have never enabled Learning Mode (default-off) require
zero action. Forks that have enabled the feature run a one-command `git mv` plus a
project-wide search/replace — see the migration guide.

### Added

- ADR-003: Rename Growth Mode to Learning Mode, relocate output, lazy-materialize
  (`docs/en/adr/003-learning-mode-relocate-and-rename.md`)
- Migration guide at `docs/en/migration/v1-to-v2.md` (and Japanese mirror
  `docs/ja/migration/v1-to-v2.md`)
- Lazy-materialize behavior for `learn/knowledge/<domain>.md` — no placeholder files
  ship on install; files are created on first teaching moment only

### Changed

- All 15 agent files updated: `## Growth Domains` section marker renamed to
  `## Learning Domains`; Developer Growth Mode contract blocks rewritten for new
  paths and vocabulary
- `learn/preamble.md` (formerly `.claude/growth/preamble.md`) fully rewritten for
  new paths, directory layout, and knowledge vocabulary
- `.claude/skills/learn/SKILL.md` (formerly `.claude/skills/growth/SKILL.md`)
  rewritten for `/learn` command and new paths
- `docs/en/learning-mode-explained.md` (renamed from `growth-mode-explained.md`)
  rewritten
- `docs/en/prd/developer-learning-mode.md` (renamed from
  `developer-growth-mode.md`) rewritten
- `docs/en/learn/domain-taxonomy.md` (moved from `docs/en/growth/`) rewritten
- All Japanese mirrors under `docs/ja/` updated accordingly
- `README.md` and `README.ja.md` updated with v2.0.0 breaking-change banner and
  migration guide link
- `.claude/CLAUDE.md`: `## Developer Growth Mode` block rewritten as
  `## Developer Learning Mode` with new paths
- `scripts/check-learn-invariants.sh` (renamed from `check-growth-invariants.sh`)
  updated for new grep targets (`learn/knowledge/`, `## Learning Domains`)
- `.gitignore` and `.gitignore.example` updated to point at `learn/knowledge/` and
  `learn/config.json`

### Removed

- `.claude/growth/notes/` — 19 placeholder files removed (were untracked under
  `.gitignore`); lazy-materialize replaces pre-seeding
- `.claude/growth/` directory (superseded by `learn/` at project root)

### Notes

- Default-off byte-identity invariant preserved: fresh installs with Learning Mode
  disabled produce output byte-identical to agent behavior before Learning Mode
  existed
- The three CI invariant checks in `scripts/check-learn-invariants.sh` continue to
  enforce: (1) `disable-model-invocation: true` on the `/learn` Skill, (2)
  `learn/config.json` path reference in every learning-aware agent, (3)
  `learn/knowledge/` is gitignored by default
- Deferred to v2.1.0: coaching styles mechanism (`hints` / `socratic` / `pair` /
  `review-only` / `silent`) — ADR-004 pending; 19 Meridian-grounded worked examples
  at `docs/en/learn/examples/<domain>.md` and Japanese mirrors — technical-writer
  batch in PR1b

---

## [1.2.2] — 2026-04-23

### Changed

- Removed explicit Claude model version numbers (Opus 4.5, Sonnet 4.6, Haiku 4.5)
  from README Model tiers section; pinned versions drifted immediately after v1.2.1
  shipped (Opus family had already moved to 4.7). Replaced with a link to the
  [Anthropic model overview](https://docs.claude.com/en/docs/about-claude/models/overview)
  so the README never needs a manual sync on Anthropic releases. Agent frontmatter
  aliases (`opus` / `sonnet` / `haiku`) are unchanged and continue resolving to the
  latest version automatically. English and Japanese README updated.

---

## [1.2.1] — 2026-04-23

### Changed

- Raised docs-researcher and technical-writer from Haiku to Sonnet tier. Both
  agents produce authoritative long-form prose (citations, user-facing documentation,
  translations, knowledge entries) where Haiku's quality regression is not caught by
  a cheap downstream oracle. linter and test-runner remain on Haiku because their
  output is the deterministic tool result itself, re-verified by CI.
- Added Model tiers subsection to README (English and Japanese) below the agent
  table, grouping all 15 agents by tier (Opus / Sonnet / Haiku / inherit) with the
  rule of thumb that drives each assignment.

---

## [1.2.0] — 2026-04-23

Resolves Issues #3, #4, and #5.

### Added

- ADR-002: Growth Domains location (`docs/en/adr/002-growth-domains-location.md`
  and Japanese mirror)
- Long-form explainer moved from README to `docs/en/growth-mode-explained.md`
  (and `docs/ja/`) with full philosophy, three-level model, side-by-side example,
  and notebook rationale

### Changed

- All 15 agent files: `growth_domains:` YAML frontmatter key removed; declaration
  moved into a `## Growth Domains` body section to stay within the documented
  Claude Code sub-agent schema. Substance unchanged (#5)
- `scripts/check-growth-invariants.sh` re-anchored to grep for `## Growth Domains`
  in agent bodies instead of frontmatter
- `learn/preamble.md`, ADR-001, PRD, README (English and Japanese) updated for
  frontmatter-to-body migration
- README restructured from 412 to 146 lines; reframed as a template-consumer
  README (what you get / quick start / agent table / project structure / license).
  Detail moved to the new explainer doc (#3)
- PRD §14 Phase 1 rewritten to distinguish files shipped with the template from
  runtime-created files (`config.json` only); resolves contradiction with FR-005 (#4)

---

## [1.1.1] — 2026-04-23

### Fixed

- Corrected README drift against the shipped v1.1.0 specification: config.json
  `scope` key replaced with `focus_domains` and `updatedAt`; false claim about
  per-agent `scope=false` toggles removed; all seven `/growth` subcommands
  documented; runtime vs. shipped file descriptions corrected; `skills/quiet/` added
  to project structure diagram; `growth_domains:` clarified as a template-local
  convention
- Shrunk `## Developer Growth Mode` block in `CLAUDE.md` to a short pointer per
  ADR-001 and PRD FR-008, eliminating context bloat in default-off sessions

---

## [1.1.0] — 2026-04-23

### Added

- Developer Growth Mode: opt-in learning layer that augments the 15-agent team
  (default-off; byte-identical output when disabled)
- `/growth` Skill (`disable-model-invocation: true` — user-only toggle)
- `/quiet` Skill (per-invocation trailer suppression, independent of Growth Mode)
- `.claude/growth/` runtime directory: `preamble.md`, `notes/` (19 domain
  placeholders), `config.json` schema
- `.gitignore.example` documenting the team-sharing opt-in inversion pattern
- `scripts/check-growth-invariants.sh` — three deterministic CI checks: Skill
  flag, agent guard branches, gitignore posture
- `.github/workflows/growth-invariants.yml`
- ADR-001: Developer Growth Mode architecture (`docs/en/adr/001-developer-growth-mode.md`
  and Japanese mirror)
- PRD: Developer Growth Mode (`docs/en/prd/developer-growth-mode.md` and Japanese
  mirror)
- Domain taxonomy — 19 canonical domains with per-agent ownership matrix
  (`docs/en/growth/domain-taxonomy.md` and Japanese mirror)
- `README.ja.md` — Japanese project README

### Changed

- All 15 agents gained `growth_domains:` frontmatter declaring primary and
  secondary domain ownership
- `CLAUDE.md` updated with a Developer Growth Mode pointer block

---

## [1.0.6] — 2026-04-22

### Added

- Per-agent model tier declarations via YAML frontmatter (`name`, `description`,
  `model` fields on all 15 agents under `.claude/agents/`)

### Changed

- Opus: architect, security-reviewer, performance-engineer, monetization-strategist
- Sonnet: implementer, code-reviewer, product-manager, market-analyst,
  ui-ux-designer, devops-engineer
- Haiku: docs-researcher, technical-writer, test-runner, linter
- inherit: orchestrator

---

## [1.0.5] — 2026-04-08

### Added

- docs-researcher agent with freshness-safe search guidelines (uses "latest" /
  "current" keywords instead of year numbers in searches to prevent stale-year
  injection into documentation lookups)

---

## [1.0.4] — 2026-04-08

### Fixed

- Added `.gitignore` to prevent committing user-specific and OS-generated files
  (`.claude/settings.local.json`, OS temp files, editor temp files)

---

## [1.0.3] — 2026-04-08

### Fixed

- Skipped CodeQL job in template repository with `if: false` to prevent GitHub
  Actions from treating the empty language matrix as an error. Derived repositories
  should remove the guard and set their own language matrix.

---

## [1.0.2] — 2026-04-08

### Changed

- Bumped `actions/checkout` from v4 to v6 (Dependabot)
- Bumped `github/codeql-action` from v3 to v4 (Dependabot)

---

## [1.0.1] — 2026-04-08

### Fixed

- Removed default `javascript` language from CodeQL matrix. The template repository
  has no JS/TS source, which caused CodeQL to fail with "no source code seen during
  build". Derived repositories should set their own language list.

---

## [1.0.0] — 2026-04-08

Initial release of ECC Base Template.

### Added

- Framework-agnostic base repository template powered by Everything Claude Code
  (ECC)
- 14-agent team: orchestrator, product-manager, market-analyst,
  monetization-strategist, ui-ux-designer, architect, implementer, code-reviewer,
  test-runner, linter, security-reviewer, performance-engineer, devops-engineer,
  technical-writer
- `.claude/` configuration: `CLAUDE.md`, `settings.json`, all 14 agent definitions
- `.github/`: reusable CI workflow, CodeQL security scanning, Dependabot
  configuration, issue and PR templates
- `.devcontainer/`: commented template for any framework
- `docs/`: bilingual documentation structure (English source under `docs/en/`,
  Japanese translations under `docs/ja/`) with cross-reference headers
- MIT License

---

[Unreleased]: https://github.com/b150005/ecc-base-template/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/b150005/ecc-base-template/compare/v1.2.2...v2.0.0
[1.2.2]: https://github.com/b150005/ecc-base-template/compare/v1.2.1...v1.2.2
[1.2.1]: https://github.com/b150005/ecc-base-template/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/b150005/ecc-base-template/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/b150005/ecc-base-template/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/b150005/ecc-base-template/compare/v1.0.6...v1.1.0
[1.0.6]: https://github.com/b150005/ecc-base-template/compare/v1.0.5...v1.0.6
[1.0.5]: https://github.com/b150005/ecc-base-template/compare/v1.0.4...v1.0.5
[1.0.4]: https://github.com/b150005/ecc-base-template/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/b150005/ecc-base-template/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/b150005/ecc-base-template/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/b150005/ecc-base-template/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/b150005/ecc-base-template/releases/tag/v1.0.0
