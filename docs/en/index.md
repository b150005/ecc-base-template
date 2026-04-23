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

## Developer Growth Mode

Developer Growth Mode is the template's flagship opt-in learning layer. When enabled, the 15-agent team enriches a domain-organized knowledge base while shipping real features. The authoritative specs live under these three files:

| Document | Description |
|----------|-------------|
| [PRD: Developer Growth Mode](prd/developer-growth-mode.md) | Product requirements, user segments, functional and non-functional requirements, acceptance criteria |
| [ADR-001: Developer Growth Mode](adr/001-developer-growth-mode.md) | Architecture decision — toggle as a Skill, the enrichment protocol, privacy posture, 19-domain taxonomy |
| [Domain Taxonomy](growth/domain-taxonomy.md) | Canonical list of 19 domains, per-agent ownership matrix, worked examples of agent-written notes |
