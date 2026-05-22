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
- **`.claude/payload-manifest.txt`** and the payload-manifest-check
  workflow are removed — they enforced the now-defunct main/develop
  payload boundary.
- **All GitHub Actions workflows are removed.** `.github/workflows/`
  ships empty (only `.gitkeep`). The 12 template-internal workflows
  (bilingual-parity, dangling-ref, skill-invariants, learn-invariants,
  roadmap-drift, coverage-gate, ecc-delegation, research-tier-auth,
  workaround-check, docs-freshness, ci-base, security) and their 5
  `.github/*-tracker.yml` configs are gone. Forks add their own CI.
- **`.claude/meta/` is removed entirely** — the reference docs
  (`references/`) and helper scripts (`scripts/`) are deleted. The only
  surviving script is `.claude/init.sh` (the one-shot post-fork
  initializer), relocated from `.claude/meta/scripts/init.sh`.

### Changed

- **`.claude/init.sh`** drops the payload-manifest-check removal prompt
  and the upstream-`develop` reference note from its Next-steps checklist.
- **`README.md` / `README.ja.md`** rewritten: single-branch "Using this
  template"; the CI section states the template ships no workflows.
- **`.claude/CLAUDE.md` and `.claude/agents/*.md`** keep all fork-facing
  features (Roadmap mechanism, Learning Mode, verification layer,
  dispatch contract, worktree advisory, upstream-workaround marker
  convention) as inline rules, but drop dead references to the deleted
  ADR/Spec history, references, scripts, and workflows.
- **Learning Mode runs in a lighter form**: the `learn` Skill keeps the
  enrichment contract and coaching styles, but the deleted
  `domain-taxonomy.md` and worked-`examples/` are no longer referenced —
  each agent's `## Learning Domains` section is the authoritative
  domain list.

### Retained (fork-facing payload)

- All 18 agents, all 10 document templates, all skills
  (`learn` / `verification-layer` / `claude-md-authoring` /
  `compliance-checklist` / `quiet`), hooks, and output styles.
  Learning Mode and the Roadmap mechanism remain opt-in features.

### Migration

- For the historical design rationale of the removed ADR/Spec records,
  read the upstream git history at or before the `v4.0.0` tag, which
  stays pinned to the last commit before this change.
