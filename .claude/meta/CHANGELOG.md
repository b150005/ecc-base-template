# Changelog — ecc-base-template (template itself)

All notable changes to **the template** are recorded here. This file is for
maintainers of the template, not for derived projects. Derived projects have
their own `/CHANGELOG.md` at the repo root.

Full history prior to v3.0.0 lives in [`CHANGELOG.legacy.md`](CHANGELOG.legacy.md).

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [3.0.0] — 2026-04-25

### Breaking

- **Repository structure fully restructured for template-repository UX.** The
  root directory now contains zero visible directories. All template-internal
  metadata (ADRs, PRDs, references, scripts, the Learning Mode runtime state)
  moved under `.claude/`. Derived projects inherit a clean slate. The complete
  v2.x → v3.0 path mapping is recorded in
  [`adr/005-template-restructure.md`](adr/005-template-restructure.md).
- ADR and spec templates moved to `.claude/templates/adr-template.md` and
  `spec-template.md` (each with a `.ja.md` bilingual counterpart). Derived
  projects decide where to place filled-in copies — the template no longer
  reserves `adr/`, `prd/`, `specs/`, or any other directory.
- The root-level `docs/` directory was removed. Derived projects are free to
  create or omit a `docs/` directory as their project demands.
- Bilingual docs now follow the `filename.md` (EN source-of-truth) +
  `filename.ja.md` (JA translation) convention throughout `.claude/meta/`,
  matching the existing `README.md` / `README.ja.md` pattern.

### Changed

- `CHANGELOG.md` at the repo root now starts from `[Unreleased]` for derived
  projects. The template's own history lives here in `.claude/meta/CHANGELOG.md`
  and the pre-v3 history in `.claude/meta/CHANGELOG.legacy.md`.
- `README.md` and `README.ja.md` rewritten from the adopter's perspective:
  release banners removed, quick-start rewritten for a new derived project, and
  the template-maintainer sections relocated to `.claude/meta/references/`.
- `.gitignore` gained language-agnostic starter patterns (OS, editor, env, logs)
  with commented hints for Node / Python / Go / Rust / Java / Kotlin stacks.
- `.github/workflows/learn-invariants.yml` updated to the new script path and
  documents the expectation that projects not using Learning Mode delete both
  this workflow and `.claude/meta/`.
- The Learning Mode runtime state moved from `learn/config.json` and
  `learn/knowledge/` to `.claude/learn/config.json` and `.claude/learn/knowledge/`
  to free the root `learn/` namespace for adopter use.

### Added

- `.claude/meta/scripts/init.sh` — interactive post-fork initializer. Replaces
  the `## About This Project` placeholder in `.claude/CLAUDE.md`, copies
  `.env.example` to `.env`, and prints a next-steps checklist.
- `.claude/templates/spec-template.md` (+ `.ja.md`) — feature spec template
  for product-manager output, complementing `adr-template.md`.
- `.claude/meta/adr/005-template-restructure.md` — records the v3 restructure
  rationale and the template-layer vs consumer-layer separation principle.

### Removed

- Root-level `learn/`, `scripts/`, and `docs/` directories. All contents
  relocated as documented in ADR-005.
- Pre-v3 release announcement banners from `README.md` and `README.ja.md`.

### Note on historical paths

ADRs and other documents under `.claude/meta/` written before v3.0.0 reference
v2.x-era paths (`docs/en/...`, `learn/...`, `scripts/...`). Those references
are preserved as historical record. The current canonical locations are listed
in [`adr/005-template-restructure.md`](adr/005-template-restructure.md).
