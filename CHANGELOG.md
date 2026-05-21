# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [5.0.0] - 2026-05-22

### BREAKING

- **`develop` branch retired and the template is now `main`-only.**
  The two-branch model introduced in v3.x is removed. All template-
  internal artifacts (ADRs, Specs, internal Skills, internal CI gates,
  the Roadmap index) have been deleted from the repository. Forks that
  were tracking `develop` should switch their upstream remote to `main`.
- **`.claude/meta/`, `specs/`, `.claude/skills/learn`,
  `.claude/skills/claude-md-authoring`, `.claude/skills/verification-layer`,
  `.claude/skills/compliance-checklist`, `.claude/ROADMAP.md`,
  `.claude/payload-manifest.txt`, `.claude/hooks/`,
  `.claude/output-styles/`, `.claude/learn/`, `.claude/verification.yml`,
  `.claude/compliance.yml`** are gone.
- **Developer Learning Mode** is removed (knowledge + coaching pillars).
- **Verification layer** (research / implementation / design Generator-
  Critic protocols) is removed.
- **Upstream-workaround tracking infrastructure** (`.github/workaround-tracker.yml`,
  the registry directory contract, the `workaround-check.yml` CI workflow)
  is removed. The `WORKAROUND-UPSTREAM(...)` marker comment convention
  remains as a code-side breadcrumb; the registry layer does not.
- **Compliance-checklist Skill** is removed.
- **Roadmap index** (`.claude/ROADMAP.md`) and the orchestrator's
  Roadmap row-guard / `specs/NN-progress.md` cross-session persistence
  are removed.
- **Verification-layer agents** (`docs-researcher`, `research-critic`,
  `adversarial-implementer`, `architecture-critic`) are removed. The
  agent team now ships 14 agents.
- **Template-internal CI workflows** are removed:
  `bilingual-parity-check`, `dangling-ref-check`, `docs-freshness`,
  `ecc-delegation-consistency-check`, `learn-invariants`,
  `research-tier-auth-check`, `roadmap-drift-check`, `skill-invariants`,
  `coverage-gate`, `workaround-check`, `ci-base`, `security`,
  `payload-manifest-check`. Their tracker configs (`coverage-tracker.yml`,
  `ecc-delegation-tracker.yml`, `research-tier-auth-tracker.yml`,
  `workaround-tracker.yml`, `docs-freshness.yml`) are removed too.

### Changed

- **`.claude/CLAUDE.md`** is now a slim payload-only template. The
  `## Plan-First Default`, `## Subagent dispatch contract`, and
  `## Worktree advisory protocol` sections are now inlined (no external
  references). Internal-meta sections are removed.
- **`.claude/agents/*.md`** are trimmed: dead references to
  internal-meta paths are removed, and the per-agent Learning Domains /
  Developer Learning Mode contract / Coaching pillar blocks are gone.
- **`README.md` / `README.ja.md`** are rewritten as a fork-facing
  payload-only template description.
- **`.claude/init.sh`** moved from `.claude/meta/scripts/init.sh`. The
  payload-manifest-check removal prompt is gone. The Next-steps
  checklist no longer mentions `.devcontainer/` or the upstream
  `develop` branch.

### Added

- **`.claude/init.sh`** at its new location.

### Migration

- For the historical design rationale of features removed in v5.0.0,
  read `git log v4.0.0..` on the v4.x history and the ADRs that lived
  in `.claude/meta/adr/` up through ADR-028. The v4.0.0 tag remains
  pinned to the last commit on `main` before this BREAKING change.
- Forks that genuinely used Roadmap, Learning Mode, verification-layer,
  upstream-workaround tracking, or any of the removed CI gates should
  stay on v4.x and not upgrade. v5.0.0 is intentionally a different
  product surface.
