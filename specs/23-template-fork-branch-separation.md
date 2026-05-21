# Template / Fork Structural Separation

## Status

Approved

## Amendment 2026-05-21

**Trigger:** User clarification of fork CI ownership boundary during Roadmap #23
implementation. The original spec assumed the template `main` branch would carry
four fork-reusable CI workflows (`ci-base.yml`, `security.yml`,
`coverage-gate.yml`, `workaround-check.yml`). The revised position is that
fork CI is entirely opt-in: forks copy workflows from `develop` or write their
own. The template `main` carries **zero** workflows by design.

**Changes from original spec:**

- AC-2 absent-from-main list expanded to explicitly include all
  `.github/workflows/*.yml`, the five tracker YAMLs under `.github/`, and the
  `.claude/meta/scripts/` subtree except `init.sh`.
- AC-4 workflow inventory revised: the four formerly keep-on-main workflows
  (`ci-base`, `security`, `coverage-gate`, `workaround-check`) are removed from
  `main`; the `.github/workflows/` folder is preserved with a `.gitkeep` file so
  that contributors do not accidentally re-add workflow files without noticing
  that the folder is intentionally empty.
- AC-5 revised: no per-workflow execution validation on `main` (no workflows to
  validate). Fork CI is opt-in by copy-from-develop or custom authoring.
- **Eliminated design conflict:** The original design created a latent competition
  between `coverage-gate.yml` (which was to enforce a threshold on `main`) and
  `coverage-threshold.sh` (a develop-only meta-script managing the same value).
  Removing `coverage-gate.yml` from `main` eliminates that competition entirely.

References ADR-026 amendment 2026-05-21.

## Amendment 2026-05-21 (second)

**Trigger:** Discovery during AC-6/AC-12 verification. GitHub Actions resolves
`pull_request` workflow files from the **PR head ref** (not the base ref). Since
main-derived feature branches inherit only main's tree, a `payload-manifest-check`
workflow that lives only on `develop` never triggers on PRs to `main` — making
the required status check unsatisfiable and blocking all PRs to `main` indefinitely.

**Changes:**

- AC-4 wording refined: `main` carries `.github/workflows/.gitkeep` **plus
  `.github/workflows/payload-manifest-check.yml`** — the single template-internal
  enforcement workflow shipped on `main` (1 workflow, not 0). All other CI is
  fork-opt-in (the original intent is preserved — fork CI scaffolding is opt-in
  and ships as `.gitkeep` only).
- The shipped workflow uses a dual-checkout pattern: it tries to checkout the
  `develop` branch to fetch the manifest, and gracefully skips with a Notice
  (conclusion: SUCCESS) when no `develop` branch exists (forks). This means the
  workflow is harmless to fork CI — it costs essentially zero on forks and runs
  effectively only in the template repository.
- AC-2 entry for `.github/workflows/*.yml` clarified: the absent list excludes
  `.gitkeep` AND `payload-manifest-check.yml` (these two files are payload, all
  other workflow YAMLs remain absent).
- `.claude/payload-manifest.txt` extended on `develop` to allow
  `.github/workflows/payload-manifest-check.yml` (so future PRs touching the
  workflow itself can land).

**Verified:**

- Positive test: PR with payload-only changes → `payload-manifest-check` =
  SUCCESS, merge unblocked (PR #11, merge `d287480`).
- Negative test: PR with `specs/test-manifest-negative.md` (not on manifest) → <!-- ref-allow: specs/test-manifest-negative.md was a transient test file in PR #12 (closed without merge); intentional historical reference for verification trace -->
  `payload-manifest-check` = FAILURE with the offending path named in the error
  message, merge blocked by ruleset (PR #12, closed without merge).
- Both checks completed in ~6 seconds.

**Also fixed under this amendment:** the workflow's original sed-based glob
pattern treated `**` as `*` (single-segment) due to ordering of substitutions.
Fixed via a placeholder-protect approach (`**` → `__GG_RECURSIVE__` → single
`*` substitution → restore as `.*`); unit-tested with 20 paths covering
nested-glob cases.

References ADR-026 amendment 2026-05-21 (second).

**Owner:** product-manager / implementer
**Target release:** template v3.12.0

## Problem

The template repository currently uses a single `main` branch that carries
both the fork-reusable payload (agent prompts, workflows, settings) and the
template-internal development infrastructure (ADRs, specs, learning-mode
scaffolding, CI meta-scripts). When a team forks the template, they inherit
every template-internal artifact — over a hundred files that are irrelevant to
their project and must be deleted by hand. This creates a high-friction fork
experience and makes future template upgrades noisier because payload changes
are entangled with template-internal history. There is no structural guarantee
that `main` stays clean; each new internal artifact requires another manual
purge step in fork instructions.

## Goals

- **G1 — Payload-only `main`.** `main` carries only the fork-reusable payload:
  agent definitions, fork-facing workflows, settings, and templates. Template-
  internal development artifacts (ADRs, specs, CI meta-scripts, learning mode)
  live exclusively on `develop`.
- **G2 — `develop` as the template-dev branch.** All template-internal work
  (Roadmap row authoring, ADR authoring, spec authoring, quality-gate work,
  CI meta-script updates) happens on `develop`. Payload changes flow from
  `develop` → `main` via a merge or cherry-pick protocol.
- **G3 — Verified payload boundary.** A CI workflow (`payload-manifest-check.yml`)
  on `develop` validates that every file merged or proposed for `main` is on
  the approved payload manifest. PRs targeting `main` cannot land without it.
- **G4 — Clean fork experience.** A team forking `main` gets only fork-relevant
  files; they do not need to delete template-internal artifacts.
- **G5 — Workflow inventory correctly partitioned.** Each GitHub Actions
  workflow is explicitly classified as keep-on-main or develop-only, and the
  classification is documented in ADR-026.

## Non-goals

- Migrating existing forks already derived from the old single-branch `main`.
  This spec covers the template repository itself; fork migration guidance is
  deferred.
- Automated cherry-pick tooling from `develop` to `main`. The v1 protocol is
  manual (PR or git cherry-pick with a review step).
- Shrinking `init.sh` beyond removing the `develop`-only initialisation steps
  that are now irrelevant for payload forks. A deeper `init.sh` redesign is
  deferred to a follow-on milestone.
- Re-running the full agent-team workflow on `main`. The quality gate, ADR
  authoring, and Roadmap management all happen on `develop`.
- Adding a CI check that enforces agent-team workflow steps (e.g., that a spec
  exists before an ADR). The payload-manifest check is structural, not
  process-oriented.

## User stories

| As a...                        | I want to...                                          | So that...                                           |
|-------------------------------|-------------------------------------------------------|------------------------------------------------------|
| team forking the template     | fork `main` and get only fork-relevant files          | I do not spend time deleting template internals      |
| template maintainer           | work on ADRs and specs on `develop`                   | `main` stays clean without manual purge steps        |
| template maintainer           | have CI block non-payload files from reaching `main`  | the boundary is enforced, not just documented        |
| fork maintainer               | pull updates from template `main`                     | I receive only payload changes, not internal noise   |
| devops-engineer               | see a clear list of which workflows stay on `main`    | I can configure branch protection rules correctly    |

## Acceptance criteria

**AC-1.** `develop` branch exists in the template repository and is set as the
default branch for development work. `main` remains the default for forks (the
branch from which `git clone` and GitHub "Use this template" derive). Verified
by: `git branch -r` lists `origin/develop`; repository default branch setting
is `develop` (or `main`, per the chosen convention — ADR-026 Decision governs).

**AC-2.** All template-internal artifacts are present on `develop` and absent
from `main`. Specifically: `specs/`, `.claude/meta/`, `.claude/ROADMAP.md`,
`.claude/learn/`, `.claude/output-styles/`, `.claude/skills/`, `.claude/hooks/`, <!-- ref-allow: .claude/learn/ is intentionally absent (opt-in/default-off per ADR-015 amendment) -->
`workarounds/` (if non-empty), `.github/workflows/*.yml` (all workflow files —
`main` carries no workflows by design; the folder itself is present with a
`.gitkeep`), `.github/coverage-tracker.yml`, `.github/docs-freshness-tracker.yml`,
`.github/ecc-delegation-tracker.yml`, `.github/research-tier-auth-tracker.yml`,
`.github/workaround-tracker.yml`, `.claude/meta/scripts/` entries other than
`init.sh` (specifically: all `check-*.sh`, `test-check-*.sh` scripts and the
`lib/` subdirectory) are not present on `main`. Verified by: `git ls-tree
--name-only main` does not list those paths; `git ls-tree -r --name-only main
.github/workflows/` returns only `.github/workflows/.gitkeep`.

**AC-3.** The payload manifest file exists at `.claude/payload-manifest.txt` <!-- ref-allow: payload-manifest.txt is created in Phase B implementation - forward reference -->
on `develop`. It enumerates every file and directory that is allowed on `main`,
one entry per line. Verified by: the file exists with at least one entry and
all currently keep-on-main files are listed.

**AC-4.** The workflow inventory is partitioned as follows and matches the
classification in ADR-026 (as amended 2026-05-21):

- **Keep on `main`** (0 workflows — folder preserved with `.gitkeep`):
  - *(none — fork CI is opt-in; forks copy workflows from `develop` or write their own)*
- **Keep on `develop`, runs against `main`-bound PRs** (1 enforcement workflow):
  - `.github/workflows/payload-manifest-check.yml`
- **Develop-only** (8 template-internal workflows, not present on `main`):
  - `.github/workflows/bilingual-parity-check.yml`
  - `.github/workflows/dangling-ref-check.yml`
  - `.github/workflows/docs-freshness.yml`
  - `.github/workflows/ecc-delegation-consistency-check.yml`
  - `.github/workflows/learn-invariants.yml`
  - `.github/workflows/research-tier-auth-check.yml`
  - `.github/workflows/roadmap-drift-check.yml`
  - `.github/workflows/skill-invariants.yml`

The four formerly keep-on-main workflows (`ci-base.yml`, `security.yml`,
`coverage-gate.yml`, `workaround-check.yml`) are removed from the template
`main` branch. Forks that want these adopt them by copying from `develop` or
authoring their own.

Verified by: `git ls-tree -r --name-only main .github/workflows/` returns only
`.github/workflows/.gitkeep` (zero `.yml` files on `main`).

**AC-5.** `main` carries no workflows by design; fork CI is entirely opt-in.
Forks that want CI (e.g., `ci-base.yml`, `security.yml`, `coverage-gate.yml`,
`workaround-check.yml`) copy the relevant workflow files from `develop` or write
their own — neither copying nor custom authoring is required for a valid fork.
There is no per-workflow execution validation on `main` (there are no workflows
to validate). Verified by: `git ls-tree -r --name-only main .github/workflows/`
returns only `.github/workflows/.gitkeep`.

**AC-6.** `.github/workflows/payload-manifest-check.yml` exists on `develop`,
triggers on `pull_request` with `base: main`, and exits non-zero if any file in
the PR diff is not listed in `.claude/payload-manifest.txt`. <!-- ref-allow: payload-manifest.txt is created in Phase B implementation - forward reference --> Verified by:
opening a test PR to `main` that contains a develop-only path causes the check
to fail; a PR containing only payload paths passes.

**AC-7.** `CLAUDE.md` on `main` is a reduced payload-facing version. It retains
the Agent Team table, Document Templates section, Development Workflow overview,
Testing Requirements, Code Quality Standards, and Extending This File section.
It does not carry the `## Developer Learning Mode`, `## Subagent dispatch
contract`, `## Worktree advisory protocol`, `## Roadmap`, or `## Plan-First &
Learning-Aware Defaults` sections (those are develop-only guidance). Verified
by: `git show main:.claude/CLAUDE.md` does not contain the string
`## Developer Learning Mode`.

**AC-8.** `.github/workflows/payload-manifest-check.yml` matches the filename
convention `<purpose>-check.yml` adopted by the template (consistent with
`dangling-ref-check.yml`, `bilingual-parity-check.yml`, etc.). Verified by:
the file is named exactly `.github/workflows/payload-manifest-check.yml` on
`develop`.

**AC-9.** `init.sh` on `develop` is updated to remove any steps that reference
develop-only paths (e.g., steps that modify `specs/` or `.claude/meta/`). The
fork-facing `init.sh` on `main` guides the forking team through payload-only
setup. Verified by: `bash -n init.sh` passes (no syntax errors) and the script
does not reference `.claude/meta/` or `specs/` paths.

**AC-10.** The `README.md` on `main` is updated to describe the two-branch
model: `main` = fork payload, `develop` = template development. It includes a
"Forking" section explaining that teams should fork `main`, and a "Contributing
to the template" section explaining that PRs should target `develop`. Verified
by: `git show main:README.md | grep -q 'develop'` exits 0.

**AC-11.** Roadmap row #23 status is flipped to `☑` on `develop` after the
quality-gate pass. `main` carries no `ROADMAP.md` (it is a develop-only
artifact). Verified by: `git ls-tree --name-only main .claude/` does not list
`ROADMAP.md`; `git show develop:.claude/ROADMAP.md | grep '| 23 |'` shows `☑ done`.

**AC-12.** The branch protection rules on the template repository are updated
so that PRs to `main` require the `payload-manifest-check` status check to
pass. Verified by: repository Settings > Branches > `main` protection rule
lists `payload-manifest-check` as a required status check.

## Key interactions

1. **Template maintainer authors a new ADR or spec.** Work happens entirely on
   `develop`. The ADR and spec files are created in `.claude/meta/adr/` and
   `specs/` respectively — paths that are develop-only and never flow to `main`.

2. **Template maintainer updates an agent prompt.** The agent file is in
   `.claude/agents/`, which is on the payload manifest and present on both
   branches. The maintainer edits on `develop`, then opens a PR targeting `main`.
   The `payload-manifest-check` workflow on `develop` validates the PR diff;
   all changed files are on the manifest, so the check passes and the PR merges.

3. **Team forks the template.** They fork from `main`. They receive only
   payload-manifest files. They run `init.sh` which guides them through
   project-specific setup without referencing any develop-only paths.

4. **Fork maintainer pulls a template update.** They add the template repository
   as a remote, fetch `main`, and merge or cherry-pick the payload delta. Because
   `main` carries no develop-only history, the diff is small and conflict-free.

## Metrics

- **Leading:** Number of files on `main` at branch-separation milestone
  completion (target: equal to `wc -l .claude/payload-manifest.txt`). <!-- ref-allow: payload-manifest.txt is created in Phase B implementation - forward reference -->
- **Leading:** `payload-manifest-check` pass rate on PRs to `main` (target: 100%
  within 2 weeks of branch separation landing).
- **Lagging:** Reduction in "delete template internals" issues or questions from
  fork users after v3.12.0 ships (target: zero such issues in the first 60 days).

## Risks and open questions

- **Merge protocol complexity.** A manual cherry-pick / PR flow from `develop`
  to `main` requires discipline. If maintainers forget, `main` drifts behind.
  Mitigation: `payload-manifest-check` CI on `develop` fails fast on any PR
  that would introduce a develop-only file, making the boundary self-enforcing.
- **`docs-freshness.yml` reclassification.** This workflow was initially
  considered for keep-on-main but reclassified as develop-only because its
  snapshot file lives inside `.claude/` (absent from `main`). The reclassification
  is captured in ADR-026. If a fork wants freshness checking, they add their
  own workflow.
- **Open question:** Should `main` carry its own minimal `CHANGELOG.md` tracking
  only payload-facing changes, separate from the full `develop` changelog? Deferred
  to ADR-026 Decision; default is no separate `main` changelog in v1.

## Out of scope

- Migrating existing forks to the new branch model.
- Automated `develop` → `main` cherry-pick tooling.
- Deep redesign of `init.sh` (only the develop-only step removal is in scope).
- Adding a payload-manifest editor UI or generator script (the manifest is
  maintained manually by template maintainers in v1).
- CI enforcement of the agent-team workflow sequence on `develop`.

## References

- `.claude/meta/adr/026-template-fork-branch-separation.md` — architectural
  decision record for this milestone (branch model, payload-manifest schema,
  workflow inventory classification, ADR-026 Decision).
- `.claude/ROADMAP.md` — Roadmap row: #23
