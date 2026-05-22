# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [5.0.0] - 2026-05-22

### BREAKING

- **`develop` branch retired; the template is now `main`-only.** The
  two-branch model is removed. The template's own design history —
  ADR files (`.claude/meta/adr/`), internal Specs (`specs/`), the PRD
  (`.claude/meta/prd/`), the template CHANGELOG (`.claude/meta/CHANGELOG*.md`),
  and the Roadmap index (`.claude/ROADMAP.md`) — is no longer shipped.
  These are template-internal records with no relevance to fork users;
  they remain in the upstream git history if a decision needs tracing.
- **`.claude/payload-manifest.txt`** and
  **`.github/workflows/payload-manifest-check.yml`** are removed — they
  enforced the now-defunct main/develop payload boundary.

### Changed

- **`.claude/init.sh`** moved from `.claude/meta/scripts/init.sh`. The
  payload-manifest-check removal prompt and the upstream-`develop`
  reference workflow note are gone from its Next-steps checklist.
- **`README.md` / `README.ja.md`** rewritten: the two-branch "Forking"
  section becomes a single-branch "Using this template" note; the CI
  section now documents the bundled workflows instead of pointing at
  `develop`.
- **`.claude/CLAUDE.md` and `.claude/agents/*.md`** keep all
  fork-facing features (Roadmap mechanism, Learning Mode, verification
  layer, dispatch contract, worktree advisory, upstream-workaround
  tracking) but drop dead references to the deleted ADR/Spec history.

### Retained (fork-facing payload — unchanged in scope)

- All 18 agents, all 10 document templates, all skills
  (`learn` / `verification-layer` / `claude-md-authoring` /
  `compliance-checklist`), hooks, output styles, and the CI workflows.
  Learning Mode and the Roadmap mechanism remain available as opt-in
  features for fork users.

### Migration

- For the historical design rationale of the removed ADR/Spec records,
  read the upstream git history at or before the `v4.0.0` tag, which
  stays pinned to the last commit before this change.
