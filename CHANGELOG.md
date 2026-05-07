# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [3.2.0] - 2026-05-07

### Added

- `claude-md-authoring` Skill at `.claude/skills/claude-md-authoring/`
  for writing and reviewing `CLAUDE.md`, `README.md`, and
  `.claude/agents/*.md`. Hybrid design (per ADR-007): four invariant
  rules are inlined and dated; volatile values (numeric thresholds,
  UI surfaces) are looked up at runtime via a Context7 → URL →
  `llms.txt` chain with graceful degradation. Progressive Disclosure
  (`SKILL.md` + `invariants.md` + `docs-protocol.md` + `examples.md`)
  keeps the entry point under the Anthropic-recommended 500-line
  cap. Manual-invoke only (`disable-model-invocation: true`) — zero
  context cost unless explicitly invoked. All Anthropic-sourced facts
  in the Skill were verified on 2026-05-06 via two independent paths
  (Context7 MCP and direct URL fetch) against
  `code.claude.com/docs/en/{memory,best-practices,skills,features-overview}`.
- `.claude/meta/scripts/check-skill-invariants.sh` — CI script
  enforcing structural invariants on Skills (line cap, required
  frontmatter fields, local link resolution).
- `.github/workflows/skill-invariants.yml` — default-on workflow
  running the script on Skill changes.
- `.github/workflows/docs-freshness.yml` — default-off, monthly
  workflow that diffs `code.claude.com/docs/llms.txt` against the
  previous snapshot for re-verification triggers.
- `.github/docs-freshness.yml` — configuration for the freshness
  workflow (`enabled: false` default).
- ADR-007 (`.claude/meta/adr/007-claude-md-authoring-skill.md` and
  `.ja.md`) documenting the hybrid design decision and the
  invariant/volatile classification.
- Responsibility additions to seven agent files
  (`technical-writer`, `docs-researcher`, `architect`,
  `devops-engineer`, `code-reviewer`, `implementer`,
  `orchestrator`) anchoring the Skill into the existing workflow.
- README and `.claude/CLAUDE.md` discoverability sections.

## [3.1.0] - 2026-05-06

### Added

- Upstream-workaround tracking layer (default-off, single-switch opt-in).
  When a defect is traced to a library or framework, the template now
  codifies the lifecycle: 3-step triage (`orchestrator` +
  `docs-researcher`), code marker (`WORKAROUND-UPSTREAM(...)` placed by
  `implementer`), per-entry registry under `workarounds/NNN-*.md` (or a
  configured `registry_dir`), and a language-agnostic CI scaffold that
  flags marker/registry drift in both directions, scans expiry dates,
  and posts an idempotent (sticky) comment on Dependabot PRs touching
  tracked packages. Activation is a single config flip — no second
  toggle to remove from the workflow.
  - New: `.claude/templates/workaround-template.md`
  - New: `.github/workflows/workaround-check.yml` (config-gated)
  - New: `.github/workaround-tracker.yml` (`enabled: false` by default;
    all settings are honored — `registry_dir`, `fail_on_marker_drift`,
    `annotate_dependabot_prs`, `expiry_warning_days`)
  - New: `.claude/meta/adr/006-upstream-workaround-tracking.md` (and
    `.ja.md`)
  - New: `.claude/meta/references/upstream-workaround-tracking.md`
    (English-only by design; deliberate exception to the bilingual
    convention, consistent with `domain-taxonomy.md`)
  - Updated: seven agent files with workaround-tracking responsibilities
    (`orchestrator`, `docs-researcher`, `architect`, `implementer`,
    `code-reviewer`, `devops-engineer`, `technical-writer`)
  - Updated: `.claude/CLAUDE.md` Development Workflow with workaround
    lifecycle step and single-switch activation note
  - Updated: `README.md` and `README.ja.md` with discoverability section
  - Note: the `dependabot-annotate` job uses `pull_request_target` with
    strict actor + same-repo gates and does not check out PR head code,
    per the security discipline in ADR-006. Other jobs use the
    `pull_request` trigger.
