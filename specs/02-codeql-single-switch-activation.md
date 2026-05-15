# CodeQL Single-Switch Activation

## Status

Approved

**Owner:** product-manager / devops-engineer
**Target release:** template v3.7.0

## Problem

`.github/workflows/security.yml` ships with `if: false` hardcoded on the `codeql` job. This means the workflow runs on every push and PR trigger, parses the job definition, and then immediately skips it — producing no vulnerability scanning, no security-events write, and no signal to the repository owner that scanning is inactive. A developer who forks the template and does not notice the `# TODO: Remove this line` comment gets zero CodeQL coverage indefinitely. The comment is the only protection against this outcome. The `if: false` guard was a reasonable "do not run on the template itself" measure, but it should not survive into derived repos as the silent default.

Note: an earlier draft of this spec proposed replacing `if: false` with a workflow-level `env:` key (`CODEQL_ENABLED: 'false'`) read via `${{ env.CODEQL_ENABLED == 'true' }}` in a job-level `if:`. That mechanism is broken: the `env` context is NOT available in `jobs.<job_id>.if` conditionals — the allowed set is `github, needs, vars, inputs` (plus status functions). An `env.X` reference in a job-level `if:` resolves to empty string and the expression is always false, meaning CodeQL would silently never run regardless of the value set. The correct mechanism is the `vars` context (repository configuration variable), confirmed via the verification layer — see Risks section and References.

## Goals

- A derived repo can activate CodeQL scanning with a single documented change: creating one repository configuration variable in the GitHub UI.
- The template's own CI does not run CodeQL (template has no application language to analyze).
- The mechanism for activation is obvious enough that a developer does not need to edit workflow YAML to enable it; the switch is in GitHub Settings.
- The activated state scans on `push` to `main`, `pull_request` to `main`, and the existing weekly `schedule`.

## Non-goals

- Pre-populating the language matrix for derived repos — language selection remains a fork-time configuration step (the matrix comment already lists supported values).
- Adding CodeQL to the template's own CI runs (the template has no application source to analyze).
- Changing the workflow trigger schedule.
- Replacing CodeQL with a different scanner.

## User stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| Template adopter | Activate CodeQL in one step after forking | I do not accidentally ship with no vulnerability scanning |
| Template maintainer | Prevent CodeQL from running on the template itself | CI stays green without spurious analysis of template scaffolding |
| Security reviewer | Confirm CodeQL is active on a derived repo | I can check one canonical location rather than reading raw YAML |

## Acceptance criteria

- **Given** a fresh fork of the template **when** the developer creates a repository variable `CODEQL_ENABLED` with value `true` in Settings > Secrets and variables > Actions > Variables tab **then** the CodeQL job runs on the next `push` or `pull_request` to `main` without editing any workflow YAML.
- **Given** a fresh fork where the repository variable `CODEQL_ENABLED` is absent (not set) **when** CI runs **then** the CodeQL job is skipped; the skip is visible in the Actions log as a skipped job, not a silent no-op or an error.
- **Given** a fresh fork where the repository variable `CODEQL_ENABLED` is set to any value other than `true` (e.g. `false`, empty) **when** CI runs **then** the CodeQL job is skipped.
- **Given** `.github/workflows/security.yml` **when** reviewed by a developer unfamiliar with the template **then** the activation instruction appears as a visible comment at the top of the `codeql` job explaining the `vars.CODEQL_ENABLED` mechanism and pointing to GitHub Settings.
- **Given** a derived repo where `CODEQL_ENABLED=true` is set **when** a push occurs to `main` **then** the job completes without error for the configured language matrix entry.
- **Given** the template repository itself (no `CODEQL_ENABLED` variable set) **when** CI runs **then** the CodeQL job is skipped — the default-off state is preserved without any YAML change required on the template.

## Key interactions

The implementation replaces the bare `if: false` + inline TODO comment with a job-level `if` expression that reads a **repository configuration variable** via the `vars` context:

```yaml
jobs:
  codeql:
    # Activation: create a repository variable CODEQL_ENABLED=true in
    # GitHub Settings > Secrets and variables > Actions > Variables tab.
    # Absent or any value other than 'true' → job is skipped (default-off).
    # Supported languages: javascript, python, go, ruby, java, csharp, cpp, swift, actions
    # Configure the language matrix in the steps below once the switch is set.
    if: ${{ vars.CODEQL_ENABLED == 'true' }}
```

The `env` context is NOT allowed in `jobs.<job_id>.if` conditionals (allowed set: `github, needs, vars, inputs`). A workflow-level `env:` key referenced as `env.X` in a job-level `if:` resolves to empty string, making the condition always false — a silent permanent skip. The `vars` context is the correct and officially supported mechanism.

The single action a fork takes: go to Settings > Secrets and variables > Actions > Variables tab, create `CODEQL_ENABLED` with value `true`. No YAML editing required. Deleting the variable or setting it to any other value returns the job to skipped state.

**Implementer note:** Also add a brief description of the `CODEQL_ENABLED` repository variable mechanism to the `## Extending This File` section of `CLAUDE.md` — one sentence pointing to GitHub Settings > Variables. This keeps the activation path discoverable without reading raw YAML.

## Metrics

- **Leading:** Post-merge, verify the template's own CI skips the CodeQL job (no `CODEQL_ENABLED` variable set on the template repo); the skip must be visible in the Actions log.
- **Lagging:** Derived repos that fork after this change should show CodeQL results in GitHub Security tab once they set `CODEQL_ENABLED=true` in their repository variables (externally observable by maintainers reviewing fork health).

## Risks and open questions

- **Resolved — verification-layer finding (2026-05-16):** The `env` context is NOT available in `jobs.<job_id>.if` conditionals. This was confirmed via docs-researcher (Tier 1, GitHub primary docs) and independently validated by research-critic (PASS verdict). An `env.X` reference in a job-level `if:` silently resolves to empty string, making the expression always false — CodeQL would never run with no error surfaced. The `vars` context (repository configuration variable) is the correct mechanism and is used in this spec. This is a real example of the verification layer preventing a silent-failure bug from reaching implementation.
- **Risk:** Existing forks that already copied `security.yml` with `if: false` are not auto-upgraded. This milestone only fixes the template; derived repos must pull the change manually. Acceptable — the template cannot push to forks.
- **Risk:** Repository variables require repository admin access to set. Developers with only write access to a fork cannot activate CodeQL without requesting admin rights. Acceptable trade-off: the activation is a one-time setup step, not a workflow-day activity.
- **Implementer instruction:** Add a brief description of the `CODEQL_ENABLED` repository variable to `## Extending This File` in `CLAUDE.md` — one sentence pointing to GitHub Settings > Secrets and variables > Actions > Variables tab.

## Out of scope

- Editing the workflow YAML as the activation step — the `vars`-context mechanism removes the need for any YAML change in derived repos.
- Notifying existing forks of the change.
- Enabling other security workflows (Dependabot, secret scanning) — separate concerns.

## References

- `.github/workflows/security.yml` — the file being modified
- G1 (Spec `specs/01-ship-verification-yml-committed.md`) — companion CRIT milestone; both ship in the same release
- GitHub Actions context availability docs — `vars` context is valid in `jobs.<job_id>.if`; `env` context is not
- Verification: research-layer T1 review 2026-05-16 — env-context refuted, vars-context confirmed (GitHub Actions context-availability docs, docs-researcher T1 + research-critic PASS)
- Roadmap row: #02
