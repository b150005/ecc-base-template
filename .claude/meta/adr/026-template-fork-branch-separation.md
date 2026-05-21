# ADR-026: Template/fork branch separation strategy

## Status

Accepted — 2026-05-21

## Context

Phase A (Roadmap #22, shipped 2026-05-20) emptied `CLAUDE.md` of volatile state and relocated the Roadmap index to `.claude/ROADMAP.md`. The remaining problem: every fork user who clicks "Use this template" on GitHub still inherits 38 Specs, 46 ADRs, 2 PRDs, 15 template-internal scripts under `.claude/meta/scripts/`, and 8 template-internal CI workflows. That payload is noise — sometimes hostile noise — for downstream projects, and it conflates "template development history" with "fork starter kit." A single-branch repo cannot serve both audiences. GitHub's template-repo feature copies only the **default branch** into the new repository (docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-template-repository), which gives us a clean separation primitive if we cooperate with it.

## Decision

Adopt a two-branch model. `main` becomes the **fork-clean payload**: only the files a downstream project needs on day one (templates, agents, skills, hooks, settings, README, CHANGELOG, CLAUDE.md skeleton, and the 4 fork-reusable CI workflows: ci-base.yml, security.yml, coverage-gate.yml, workaround-check.yml). `develop` becomes the **template-development branch** carrying Specs, ADRs, PRDs, `.claude/meta/`, `.claude/ROADMAP.md`, and the 8 template-internal CI workflows (bilingual-parity-check, dangling-ref-check, docs-freshness, ecc-delegation-consistency-check, learn-invariants, research-tier-auth-check, roadmap-drift-check, skill-invariants). `main` is set as the GitHub default branch so the "Use this template" button copies only the payload. Template-development work happens on `develop` (or feature branches off `develop`) and lands in `main` via a gated `develop → main` merge whose diff is constrained by a payload allowlist enforced by a new `payload-manifest-check.yml` CI workflow on `develop`. That workflow fails any PR whose `base` is `main` and whose diff touches a path matching the template-internal glob set.

## Consequences

### Positive

- "Use this template" produces a clean repo with no template-internal noise.
- The payload-manifest workflow is the single mechanical source of truth for fork-visible scope; drift cannot land silently.
- Template-dev iteration (new ADRs, Specs, meta scripts) no longer pollutes fork history.

### Negative

- Two long-lived branches to maintain; some changes (e.g., a new agent that also needs a Spec) require coordinated commits on both sides of the merge.
- Existing forks created from pre-#23 `main` carry the old payload; they must opt into the cleanup manually.

### Neutral

- CI matrix doubles for paths that exist on both branches (agents, skills, hooks).
- Rollback path: revert `main` to the pre-cutover SHA (tagged `pre-phase-b`) and reset the default branch — `develop` is unaffected.

## Alternatives considered

| Alternative | Pros | Cons | Why not chosen |
|---|---|---|---|
| Amend ADR-014 with a "fork-clean" clause | One fewer ADR | ADR-014 keys *Roadmap index location*, not branch topology — orthogonal contract | Fails all 3 triad axes |
| `.gitattributes export-ignore` only | No branch split needed | Only affects `git archive`, not template-button clones | Wrong primitive — GitHub template clone is a branch copy |
| Separate template-dev repo | Hardest isolation | Loses PR cross-reference, doubles infra | Cost exceeds benefit at current scale |

## References

- `.claude/meta/adr/014-roadmap-index-single-entry-point.md` — Roadmap index residency (precedent for relocating template-internal state)
- `.claude/meta/adr/018-bilingual-parity-detector.md` — CI-enforced structural invariant (precedent for the payload-manifest gate)
- GitHub Docs: docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-template-repository (default-branch copy semantics)
- GitHub Docs: docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/managing-a-branch-protection-rule (branch protection for multi-branch model)
- `specs/22-claude-md-invariant-refactor.md` — Phase A (precedent for the invariant-only refactor that enables this branch split)
- `specs/23-template-fork-branch-separation.md` — Spec authoring this milestone (drafted in parallel by product-manager)
- Roadmap row: #23

## Amendment 2026-05-21

**Trigger.** User clarification (2026-05-21) during Roadmap #23 implementation kickoff: GitHub workflows are a per-fork opt-in concern, not a template-owned default. Forks diverge sharply on whether they want CI scaffolding (some have organization-level reusable workflows, some target air-gapped CI, some adopt a different runner stack entirely), so shipping even a "minimal" 4-workflow baseline on `main` imposes a choice on every downstream user that they did not ask the template to make.

**Decision revision.** `main` carries **0 workflows**. The previously specified 4 fork-reusable workflows (`ci-base.yml`, `security.yml`, `coverage-gate.yml`, `workaround-check.yml`) are removed from the `main` payload. A single `.github/workflows/.gitkeep` placeholder preserves the directory so that fork users see the slot exists and remember to populate it — the empty folder is itself the affordance. The same "leaner main" principle applies to `.claude/meta/scripts/`, which is reduced on `main` to **only** `init.sh` (the fork-facing bootstrap script); every other script under that directory is template-internal and lives on `develop`. The 5 orphan tracker configs (`.github/coverage-tracker.yml`, `.github/docs-freshness-tracker.yml`, `.github/ecc-delegation-tracker.yml`, `.github/research-tier-auth-tracker.yml`, `.github/workaround-tracker.yml`) — orphan in the sense that their corresponding workflows now live only on `develop` — are removed from `main` for the same reason: they configure behaviors the fork has not opted in to.

**Eliminated tension.** The original Decision implicitly required `coverage-gate.yml` to retain a runtime dependency on `.claude/meta/scripts/coverage-threshold.sh` (the gate's threshold-loader). That dependency contradicted Spec AC-2's invariant ("`.claude/meta/` absent on `main`") because the workflow could not run without re-introducing one meta script. Removing the workflow from `main` removes the dependency cleanly: the `coverage-threshold.sh` script and its sibling meta scripts stay on `develop` where they belong, and `coverage-gate.yml` is available to forks via the `develop` branch (or by copy-paste) when they actively want it. No exception, no carve-out — the AC-2 invariant holds as written.

### Consequences addendum

**Negative.** Forks who want CI scaffolding (lint, test, security scan, coverage gate, workaround tracker) must opt in by copying the workflows from `develop` or writing their own. The `.github/workflows/.gitkeep` placeholder on `main` is the affordance that reminds fork users this layer exists and is intentionally empty — without it, a fresh template clone would have no `.github/workflows/` directory at all and the omission would read as accidental rather than chosen.

**Neutral.** Branch protection on `main` still requires `payload-manifest-check` (per AC-12 of the Spec). That workflow runs on the PR head ref (`develop` or feature branches off `develop`), where the workflow file does live. `main`-side workflow absence therefore does not break the gate: GitHub evaluates required status checks against the PR's head commit, not the base branch's file tree. The enforcement mechanism is unaffected by the leaner-main decision.

**Spec counterpart.** Spec AC-2 / AC-4 / AC-5 carry the matching amendment on the requirements side: AC-2 reasserts `.claude/meta/` absence (now unambiguous, no script-dependency carve-out), AC-4 lists `.github/workflows/.gitkeep` as the sole expected payload under that directory, and AC-5 names `init.sh` as the only expected file under `.claude/meta/scripts/` on `main`.

## Amendment 2026-05-21 (second)

**Trigger.** Empirical discovery during AC-6/AC-12 verification: GitHub Actions resolves `pull_request` workflow files from the **PR head ref**, not the base ref. The original "Neutral" Consequence above asserted that `payload-manifest-check.yml` could live exclusively on `develop` because "branch protection on `main` still requires `payload-manifest-check`... that workflow runs on the PR head ref (`develop` or feature branches off `develop`)". This is only true for PRs whose head ref *includes the workflow file*. A feature branch created from `main` (the standard cherry-pick flow for landing payload updates) has only `main`'s file tree — no workflow file — so the check never triggers. Test PR #10 (head: feature branch off `main`, no workflow file in head) confirmed: after 128 seconds only the external GitGuardian status posted; `payload-manifest-check` never ran, leaving the required-check ruleset permanently unsatisfied.

**Decision revision.** `main` carries **one** workflow: `.github/workflows/payload-manifest-check.yml`. This is the single deliberate exception to "0 fork-facing workflows on `main`" — it is template-internal infrastructure (a boundary-enforcement gate), not fork CI. The "fork CI is opt-in" intent is preserved because the workflow:

1. Uses a dual-checkout pattern: it tries to checkout the `develop` branch to fetch the manifest from its canonical location (`.claude/payload-manifest.txt` on `develop`).
2. Gracefully skips with a Notice (conclusion: SUCCESS) when no `develop` branch exists — which is the default state for any fork that has not opted in to the leaner-main pattern. Forks that delete the workflow file see no behavior change; forks that keep it see a no-op success on every PR.
3. Validates each changed path against the manifest's glob patterns when active, failing the PR's required status check on any mismatch.

The `.claude/payload-manifest.txt` on `develop` now lists `.github/workflows/payload-manifest-check.yml` as an allowed payload path so future PRs touching the workflow itself can land. Manifest stays single-source on `develop`; the workflow on `main` fetches it at runtime.

**Eliminated tension.** The original "Neutral" claim about workflow-on-develop sufficiency was wrong — fixed by relocating the workflow file to `main` (with the fork-gracefully-skipping checkout pattern preserving the no-fork-cost invariant). The leaner-main intent ("fork CI is opt-in") survives because the file is template-enforcement, not fork-scaffolding CI.

**Also fixed under this amendment.** The original workflow's sed pipeline converted `**` (recursive glob) as if it were `*` (single-segment), breaking nested-path matches like `.claude/agents/nested/foo.md`. Replaced with a placeholder-protect approach (`**` → marker → single `*` substitution → restore marker as `.*`); unit-tested with 20 paths covering nested cases.

### Consequences addendum (second)

**Negative.** `main` now ships one workflow file. Forks that want zero workflows must delete `.github/workflows/payload-manifest-check.yml` (the file is harmless if kept — it skips on absent `develop`). This is a one-line `git rm` for the fork maintainer.

**Positive.** AC-12 ruleset enforcement actually works. Verified end-to-end:
- Positive test (PR #11 / merge `d287480`): payload-only diff → check SUCCESS → merge unblocked.
- Negative test (PR #12, closed without merge): diff including `specs/test-manifest-negative.md` → check FAILURE with offending path named → merge blocked by ruleset.
- Both checks completed in ~6 seconds.

**Neutral.** No change to the fork-CI-opt-in intent: forks still get `.gitkeep` as the affordance for fork-CI scaffolding; the single workflow shipped is template infrastructure that is no-op for them.

**Spec counterpart.** Spec `specs/23-template-fork-branch-separation.md` carries Amendment 2026-05-21 (second) with the matching AC-4 wording revision.

## Amendment 2026-05-21 (third)

**Trigger.** User feedback (2026-05-21): the second-amendment "graceful-skip on missing `develop`" guarantee covered *correctness* (no fork PR fails) but not *invisibility*. Forks that inherit the workflow file still see a "Payload Manifest Check" entry in their Actions tab on every PR (skipped or 6-second SUCCESS), consume billable runner-startup time, and pay a cognitive tax: the workflow's purpose is opaque without reading ADR-026 itself. The "fork CI is opt-in" principle established by Amendment 2026-05-21 (first) is violated in spirit — fork users must reverse-opt-out via `git rm` rather than receive an opt-in surface.

**Decision revision.** Defense in depth via two orthogonal layers:

1. **Job-level repository guard.** Add `if: github.repository == 'b150005/ecc-base-template'` to the `payload-manifest-check` job. On any non-upstream repository the job evaluates to `skipped` before runner allocation — 0 runner minutes, 0 Actions billing, no tab noise beyond the skip marker. Forks that take no action see the workflow file but never see it run.
2. **Interactive removal in `init.sh`.** Add a prompt to `.claude/meta/scripts/init.sh` ("Remove template-internal payload-manifest-check.yml? (y/N)") so fork users who run `init.sh` can physically remove the file. `--non-interactive` mode preserves the file (safe no-op); `--dry-run` mode prints the intended removal without writing.

The two layers are orthogonal: layer (1) protects users who do not run `init.sh`; layer (2) offers cleanup for users who do. Together they convert the workflow from "opt-out" to "ignorable by default, removable on request."

**Eliminated tension.** The second-amendment graceful-skip mechanism preserved correctness but did not preserve the fork-clean-by-default UX intent of Amendment 2026-05-21 (first). Layer (1) re-aligns runtime visibility with the first-amendment intent; layer (2) re-aligns the fork-customization story with the `init.sh` ergonomic surface.

**Trade-off accepted.** The hardcoded `b150005/ecc-base-template` guard becomes fail-silent if the upstream repository is renamed or transferred between accounts/orgs — upstream itself silently stops running the check. Mitigated by (a) the second-amendment graceful-skip remaining as a second-layer defense and (b) an inline comment in the workflow file flagging the rename dependency. The risk is upstream-only (forks are not affected); rename is a planned, infrequent operation where updating the guard is one of several mechanical steps.

### Consequences addendum (third)

**Positive.** Fork users see zero Actions-tab noise from this workflow by default. Users who run `init.sh` can additionally elect physical removal. The graceful-skip fallback remains for any path the guard might miss (legacy forks, name-collision repositories).

**Negative.** The upstream repo name is hardcoded in the workflow; renaming requires a one-line edit (flagged by an inline comment). The init.sh prompt is one additional interactive question for fork users (mitigated by `--non-interactive` mode keeping the file silently).

**Neutral.** No change to AC-2, AC-4, or AC-12 outcomes. AC-6 verification gains a fork-context check (job evaluates to `skipped` on non-upstream repos).

**Spec counterpart.** `specs/23-template-fork-branch-separation.md` carries Amendment 2026-05-21 (third) with the matching AC-6 verification refinement.
