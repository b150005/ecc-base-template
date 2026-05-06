# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
