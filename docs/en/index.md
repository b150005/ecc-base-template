# Documentation

## Bilingual Convention

This project maintains documentation in two languages:

- **English** (`docs/en/`) — Source of truth. All changes start here.
- **Japanese** (`docs/ja/`) — Maintained translation for Japanese-speaking contributors.

Claude Code reads English documentation only to minimize context window usage. Human contributors may read either language.

## Documents

| Document | Description |
|----------|-------------|
| [ECC Overview](ecc-overview.md) | What is Everything Claude Code and how it works |
| [TDD Workflow](tdd-workflow.md) | Test-driven development methodology with ECC agents |
| [CI/CD Pipeline](ci-cd-pipeline.md) | GitHub Actions workflows and automation |
| [DevContainer](devcontainer.md) | Development container setup and customization |
| [GitHub Features](github-features.md) | CODEOWNERS, Dependabot, templates, Actions, branch protection |
| [Template Usage](template-usage.md) | How to create a project from this template |
| [ADR Template](adr/000-template.md) | Architecture Decision Record format |

## Developer Learning Mode

Developer Learning Mode is the template's flagship opt-in learning layer (renamed from "Developer Growth Mode" in v2.0.0; see [ADR-003](adr/003-learning-mode-relocate-and-rename.md)). When enabled, the 15-agent team enriches a domain-organized knowledge base while shipping real features. The authoritative specs live under these files:

| Document | Description |
|----------|-------------|
| [Learning Mode Explained](learning-mode-explained.md) | Learner-facing explainer: what changes when you enable the mode, how the knowledge base accumulates, and how to read your own `learn/knowledge/` files |
| [PRD: Developer Learning Mode](prd/developer-learning-mode.md) | Product requirements, user segments, functional and non-functional requirements, acceptance criteria |
| [ADR-001: Developer Growth Mode](adr/001-developer-growth-mode.md) | Architecture decision — toggle as a Skill, the enrichment protocol, privacy posture, 19-domain taxonomy (partially superseded by ADR-003) |
| [ADR-002: Growth Domains Location](adr/002-growth-domains-location.md) | Why domain declaration lives in the agent prompt body rather than frontmatter (section marker renamed to `## Learning Domains` in ADR-003) |
| [ADR-003: Relocate and Rename](adr/003-learning-mode-relocate-and-rename.md) | v2.0.0 breaking change: rename "Growth Mode" → "Learning Mode", relocate `.claude/growth/` → `learn/`, rename "notes" → "knowledge", lazy-materialize |
| [ADR-004: Coaching Pillar](adr/004-coaching-pillar.md) | v2.1.0 coaching pillar: six coaching styles (`default` plus five active modes — hints, socratic, pair, review-only, silent) in Output Styles–compatible file format, dispatched from Learning Mode config state |
| [Domain Taxonomy](learn/domain-taxonomy.md) | Canonical list of 19 domains, per-agent ownership matrix, worked examples of agent-written knowledge entries |
| [v1 → v2 Migration Guide](migration/v1-to-v2.md) | Upgrade instructions for forks that enabled Developer Growth Mode before v2.0.0 |
