# CI Coverage Gate (80% Hard Check)

## Status

Approved

**Owner:** product-manager / implementer
**Target release:** template v3.13.0

## Problem

The template's `.claude/CLAUDE.md` `## Testing Requirements` section mandates "Minimum 80% test coverage" as a written rule. No CI job enforces this requirement. The existing reusable workflow, `.github/workflows/ci-base.yml`, accepts a `test-command` input from derived repositories and runs their tests — but it imposes no threshold, emits no coverage metric, and does not fail the build when coverage falls below 80%. A derived repo can ship with 10% coverage and pass CI today.

The gap is compounded by the template's structural position: the template repository itself has no application code. Its only executable artifacts are the bash detector scripts (`.claude/meta/scripts/check-*.sh`) and their companion test suites (`.claude/meta/scripts/test-check-*.sh`). Any CI coverage check authored for milestone #12 is therefore not a check run against the template's own bash scripts — it is a **forkable scaffold** that derived repositories wire to their own test suite and coverage toolchain. This mirrors the structural posture of `.github/workflows/ci-base.yml` (parameterized `workflow_call`) and `.github/workflows/workaround-check.yml` (default-off single-switch scaffold).

Milestone #12 closes this gap: it delivers a CI scaffold that, when wired by a derived repository, causes the build to fail when test coverage is below 80%, making the written rule in `## Testing Requirements` an enforceable contract rather than a suggestion.

## Goals

- Deliver a CI scaffold — a GitHub Actions workflow file or an extension to an existing one — that enforces an 80% coverage threshold as a build-failing check for derived repositories.
- Ensure the 80% threshold traces to a single source of truth: the `## Testing Requirements` section of `.claude/CLAUDE.md`. The CI scaffold must not introduce a second, competing numeric definition of that threshold.
- Allow a derived repository to supply its own language-specific coverage tool and output format without modifying template-owned logic — matching `ci-base.yml`'s parameterized `workflow_call` approach.
- Make the activation posture explicit and single-point-of-control, so a fork maintainer can enable or disable the gate at one location without editing the workflow file itself (the exact posture — always-on, default-off-single-switch, or repository-variable-gated — is deferred to the architect; see Risk R-01).
- Ensure the gate does not cause a failing CI job in the template repository itself, where there is no application coverage to measure.
- Establish a MECE boundary between this milestone's owned question ("Does the project's test coverage meet 80%, enforced at CI time?") and the four existing detectors, none of which owns a coverage-threshold check.

## Non-goals

- Checking path resolution, ADR textual references, or `.claude/`-rooted path mentions — that is milestone #04 (`check-dangling-refs.sh`, ADR-015).
- Checking Roadmap bidirectional-link contract or status-glyph well-formedness — that is milestone #05 (`check-roadmap-drift.sh`, ADR-017).
- Checking EN/JA heading-tree parity — that is milestone #06 (`check-bilingual-parity.sh`, ADR-018).
- Providing opt-in guidance for verification domains — that is milestone #11 (documentation/convention layer per ADR-014:1800). Milestone #12 is NOT a documentation/convention milestone and does not occupy a pre-reserved slot in ADR-014's §(d) MECE table, which names #04, #05, #09, #10, and #11 but does not include #12. This is a substantive distinction the architect must weigh when applying the ADR-018 Alternative-B discriminator (see Risk R-01).
- Running the coverage gate against the template's own bash detector scripts or their test suites — those scripts have no coverage instrumentation, and adding one is outside the scope of this milestone.
- Auto-repairing coverage gaps — the gate reports and fails; humans and agents remediate.
- Specifying the exact CI structural form (parameterized workflow, `ci-base.yml` extension, standalone file). That is the architect's structural decision (see Risk R-01).
- Translating the scaffold to CI providers other than GitHub Actions.
- Changing the four existing detector scripts (`.claude/meta/scripts/check-dangling-refs.sh`, `check-roadmap-drift.sh`, `check-skill-invariants.sh`, `check-bilingual-parity.sh`) or their three test suites (`test-check-dangling-refs.sh`, `test-check-roadmap-drift.sh`, `test-check-bilingual-parity.sh`). Milestone #12 introduces no changes to those artifacts.

## Target users

| Persona | Description | Primary Need |
|---------|-------------|--------------|
| Fork maintainer (human) | Sets up a derived project that inherits the template CI scaffold | A single activation step that makes the 80% coverage rule enforceable in their CI pipeline without writing custom threshold logic |
| Template adopter team lead | Reviews CI configuration at project inception or quarterly | Confidence that the written 80% rule in `## Testing Requirements` is actually enforced, and that the single source of truth for that number has not drifted into a second location |
| Orchestrator / test-runner (agent) | Evaluates whether the quality gate at step 6 of the development workflow passed | A CI job named deterministically that fails with a message attributing the failure to coverage < 80%, so the agent can report it without ambiguity |
| Implementer (agent) | Writes code and needs to know if their changes degraded coverage | A failing CI job with output that names the measured coverage and the threshold, enabling targeted remediation |

## User stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| Fork maintainer | Activate the coverage gate with a single configuration change | I do not have to write custom threshold logic or vendor a coverage library into my workflow file |
| Fork maintainer | Supply my own language-specific coverage command and report format | The gate is language-agnostic and does not constrain my test framework or coverage tool |
| Template adopter team lead | Confirm the 80% threshold comes from one canonical location | A future change to the threshold requires editing exactly one place, with no risk of the CI threshold and the documented rule drifting apart |
| Implementer (agent) | See a CI failure message that names the measured coverage and the 80% threshold | I can remediate without navigating to a separate dashboard |
| Orchestrator (agent) | Read a deterministic CI job name that unambiguously signals a coverage failure | I can map the failure to the "test coverage below 80%" root cause without guessing |

## Acceptance criteria

- **Given** a derived repository has activated the coverage gate scaffold (by whatever activation mechanism the architect selects) **when** the test suite runs and produces measured coverage below 80% **then** the CI job named by the scaffold fails with a non-zero exit code and a human-readable message that names both the measured coverage and the 80% threshold — making the gate a hard build-failing check, not an advisory warning.

- **Given** the threshold value enforced by the CI scaffold **when** a reviewer traces it back to its declared source **then** the threshold can be resolved to a single location: the `## Testing Requirements` section of `.claude/CLAUDE.md`, which states "Minimum 80% test coverage." The scaffold must not introduce a competing hardcoded numeric threshold in a second file that could drift from the canonical declaration.

- **Given** a derived repository using a language-specific coverage tool (for example: a Go `go test -coverprofile` report, a Python `coverage.py` XML output, a JavaScript `lcov.info` file, or a JVM JaCoCo report) **when** the fork maintainer wires the scaffold **then** they can supply the coverage command and report format via an input or configuration parameter without modifying the template-owned workflow file, mirroring `ci-base.yml`'s `workflow_call` `test-command` input pattern.

- **Given** the activation posture chosen by the architect (always-on, default-off-single-switch in the style of `workaround-check.yml`, or repository-variable-gated in the style of `.github/workflows/security.yml` and the CodeQL milestone #02) **when** a fork maintainer reads the scaffold file and its companion configuration document **then** the activation mechanism is documented in exactly one place and toggled by exactly one change — no second `if: false` guard, no second config key, matching the "single switch" discipline of `workaround-check.yml` and ADR-002.

- **Given** the template repository's own CI runs the scaffold **when** the gate evaluates **then** no new failing job is introduced. The gate must be green-by-construction or correctly inert for the template itself — either by the activation switch being off by default (opt-in posture), or by the scaffold detecting the absence of application coverage artifacts and exiting zero explicitly. The template repo must not require a coverage exemption exception or a `ref-allow`-style suppression to remain green.

- **Given** the four existing detector scripts (`.claude/meta/scripts/check-dangling-refs.sh`, `check-roadmap-drift.sh`, `check-skill-invariants.sh`, `check-bilingual-parity.sh`) and their three test suites (`test-check-dangling-refs.sh`, `test-check-roadmap-drift.sh`, `test-check-bilingual-parity.sh`) **when** milestone #12 ships **then** none of those seven files has been modified — confirming #12 introduces no scope bleed into the existing detector layer.

- **Given** a future milestone author evaluating where to route a coverage-threshold concern **when** they read the MECE boundary established by milestone #12 **then** the owned question is unambiguous: "Does the project's test coverage meet the 80% minimum, enforced at CI time?" This question is distinct from #04's ("Does a prose path reference resolve to a real file?"), #05's ("Are the Roadmap's adr:/Roadmap-row back-links bidirectionally consistent and glyphs well-formed?"), #06's ("Do the EN and JA spec heading trees match?"), and #11's ("Under what project characteristics should a fork enable the implementation or design verification domain?"). No existing detector owns coverage-threshold enforcement; a coverage concern must be routed to #12 or a successor milestone, not appended to an existing detector.

- **Given** the `.claude/CLAUDE.md` `## Testing Requirements` section after milestone #12 ships **when** a reviewer reads it **then** it still contains the canonical statement "Minimum 80% test coverage" and has not been duplicated into, or replaced by, a threshold defined solely in the CI scaffold. The CLAUDE.md section is the authoritative definition; the scaffold enforces it. The two must remain consistent: one canonical declaration, one enforcement artifact.

## Key interactions

1. **Interaction with `.github/workflows/ci-base.yml`.** The existing `ci-base.yml` reusable workflow accepts a `test-command` input and runs it with no threshold. Milestone #12's scaffold may extend `ci-base.yml` with a `coverage-threshold` input (or a companion step), ship as a standalone `workflow_call` file, or take another structural form — all deferred to the architect. The key constraint is that the existing `test-command` input and its behavior must remain unchanged for derived repos that have not opted into the coverage gate.

2. **Interaction with `.github/workflows/workaround-check.yml`.** The workaround-check workflow ships default-off via a single switch (`enabled: true` in `.github/workaround-tracker.yml`). If the architect selects a default-off-single-switch posture for #12, this is the closest structural precedent. The activation mechanism — a YAML config file read at CI runtime, a repository variable, or a workflow input — is the architect's structural decision.

3. **Interaction with the CodeQL activation pattern (milestone #02).** Milestone #02 gates the CodeQL job behind a repository variable `CODEQL_ENABLED=true`. If the architect selects a repository-variable posture for #12, this is the precedent. The Spec does not prescribe either posture; AC-4 only asserts that whichever posture is chosen is documented and single-point-of-control.

4. **Interaction with `.claude/CLAUDE.md` `## Testing Requirements`.** The scaffold must not introduce a second numeric threshold. The single-source-of-truth constraint (AC-2, AC-8) is a binding requirement on the implementation: the scaffold reads or references the 80% number from the canonical location, or is documented as enforcing the same threshold with an explicit cross-reference, so a future threshold change requires editing exactly one file.

5. **Interaction with existing detector scripts.** The four existing detectors (`.claude/meta/scripts/check-dangling-refs.sh`, `check-roadmap-drift.sh`, `check-skill-invariants.sh`, `check-bilingual-parity.sh`) are not modified by this milestone. The MECE boundary between the coverage gate and those detectors is stated in the Non-goals section and in AC-6 and AC-7.

6. **Structural HOW deferred to architect.** Whether #12 ships as (a) a new parameterized reusable `workflow_call` file that extends `ci-base.yml` with a `coverage-threshold` input, (b) a standalone default-off single-switch workflow analogous to `workaround-check.yml`, (c) a repository-variable-gated workflow analogous to the CodeQL pattern in #02, or some combination — all deferred to the architect's forthcoming decision. The architect applies the ADR-018 Alternative-B discriminator: milestone #12 introduces a new CI hard-check enforcing a coverage threshold (a new keying: the 80% number; a new MECE boundary: "does test coverage meet threshold at CI time?", a question no existing detector owns). The #04/#05/#06 precedent — each of which introduced a new detector, a new MECE boundary, and a new structural keying, and each of which received a new ADR — points toward ADR-019 being warranted. ADR-019 is the next unused ADR number (016/017/018 are consumed; the five ADR-014 amendments at #07–#11 do not consume new numbers). The architect decides; this Spec does not. <!-- ref-allow: ADR-019 is a forthcoming reserved number cited as a possible outcome of the architect's decision; it does not yet exist by design -->

## Metrics

- **Leading:** After milestone #12 ships, a fork maintainer can activate the coverage gate with a single configuration change, verifiable by reading the activation documentation.
- **Leading:** CI job passes on the template's own `main` branch immediately after the milestone ships — with no new failing job introduced (AC-5).
- **Leading:** Zero modifications to existing detector scripts or their test suites (AC-6), verifiable via `git diff` against the four scripts and three test-suite files.
- **Lagging:** Reduction in derived-repo CI pipelines that pass with test coverage below 80%, observable through fork audit over time once the scaffold is adopted.

## Risks and open questions

### Risk R-01: Structural decision deferred to architect — CI form, activation posture, ADR strategy

**Description.** This Spec states *what* the coverage gate must guarantee: 80% is enforced as a build-failing check, the threshold traces to a single canonical source, derived repos can wire their own language/coverage-tool without modifying template logic, the activation posture is single-point-of-control, and the template's own CI remains green. It explicitly defers the structural *how*: whether the scaffold is a new standalone workflow, an extension of `ci-base.yml`, or another form; whether the activation posture is always-on (as with ADR-015's subject-matter-presence rule for the always-on detectors), default-off-single-switch (as with `workaround-check.yml`), or repository-variable-gated (as with the CodeQL milestone #02); and whether any of the accepted ACs require a new ADR or an amendment to an existing one.

**ADR-018 Alternative-B discriminator, handed to architect explicitly.** The architect must apply the ADR-018 Alternative-B discriminator. Milestone #12 introduces a new CI hard-check that enforces a coverage threshold — a new keying (the 80% number), a new MECE boundary ("does coverage meet threshold at CI time?"), and a new structural artifact none of the existing detectors owns. This pattern matches the #04/#05/#06 precedent: each introduced a new detector, a new MECE boundary, and a new structural keying, and each warranted a new ADR. Furthermore, #12 does NOT occupy a pre-reserved "documentation/convention" slot in ADR-014's §(d) MECE table (which names #04, #05, #09, #10, #11 — not #12). This distinction points toward a new ADR-019 rather than an ADR-014 amendment, but the architect decides. ADR-019 is the next unused number (ADRs 016, 017, 018 are consumed; milestones #07–#11 produced ADR-014 amendments, not new ADR numbers). <!-- ref-allow: ADR-019 is a forthcoming reserved number cited as a possible outcome of the architect's decision; it does not yet exist by design -->

**Mitigation constraint handed to architect.** The architect's forthcoming decision must specify: (a) the exact workflow file(s) or script(s) that implement the gate; (b) the activation posture and its single-point-of-control mechanism; (c) how the 80% threshold is referenced rather than re-declared to satisfy AC-2 and AC-8; (d) how the template repo stays green under AC-5; (e) whether a new ADR-019 is warranted or an amendment to an existing ADR suffices. Until that decision exists, the gap (80% rule exists in writing, is not enforced by CI) remains the operating state. <!-- ref-allow: ADR-019 is a forthcoming reserved number cited as a possible outcome of the architect's decision; it does not yet exist by design -->

**Note:** The `<!-- ref-allow: -->` suppressions on lines referencing the forthcoming architect decision live only in this Spec file (`specs/12-coverage-ci-gate.md`), following the precedent set by `specs/11-verification-domain-opt-in-guidance.md`, `specs/05-roadmap-drift-detection-ci.md`, and `specs/10-spec-adr-directory-pinning.md`. They do NOT appear in `.claude/CLAUDE.md`.

### Risk R-02: Single-source-of-truth drift

**Description.** If the CI scaffold hardcodes "80" as a numeric literal (e.g., `if [ "$coverage" -lt 80 ]`) independently of any reference to `CLAUDE.md`, then a future threshold change (say, raising it to 85%) requires editing both the CLAUDE.md rule and the CI script — and the two can drift. The #11 Spec precedent for documentation/convention alignment does not prevent this; it must be an explicit implementation constraint.

**Mitigation.** AC-2 and AC-8 bind the implementer to keep the threshold in one place. The implementer satisfies this by either: (a) having the scaffold read the threshold dynamically from a configuration file that CLAUDE.md treats as its enforcement artifact; (b) encoding the threshold in a single configuration parameter with an explicit CLAUDE.md cross-reference in the workflow's comment block; or (c) another mechanism the architect specifies. The architect's structural decision (R-01) must account for this constraint explicitly.

### Risk R-03: Template-repo green guarantee

**Description.** The template repository has no application code. If the coverage gate runs against the template itself and finds no coverage artifacts, it must exit zero — not fail with "coverage report not found." A naive implementation that fails on missing coverage reports would break the template's own CI immediately.

**Mitigation.** AC-5 is a binding acceptance criterion. The architect's structural decision must include an explicit mechanism for the template itself to remain green: either the activation switch is off by default (opt-in posture), or the scaffold detects the absence of coverage artifacts and exits zero with a log message, or the gate is scoped to derived repos only. The implementer must verify this with a test against the template repo before marking the milestone as done.

### Risk R-04: Language-agnosticism

**Description.** Coverage output formats vary by language and toolchain: `coverage.py` XML, Go `coverprofile`, JavaScript `lcov.info`, JVM JaCoCo XML, Rust `llvm-cov`, Swift coverage JSON, and others. A scaffold that only handles one format forces derived repos to translate their native output, negating the forkability goal.

**Mitigation.** AC-3 requires that derived repos can wire their own language and format without editing template-owned logic, mirroring `ci-base.yml`'s `test-command` input. The architect's structural decision must specify how the scaffold accepts the derived repo's coverage percentage as an already-computed input (so the template does not need to parse multiple formats), or accepts a coverage command whose output is parsed by a minimal language-agnostic extractor. The exact mechanism is the architect's decision.

## Out of scope

- Auto-repair of coverage gaps — the gate reports and fails; humans and agents remediate.
- Enforcing coverage on the template's own bash detector scripts or their test suites.
- Translating the scaffold to CI providers other than GitHub Actions.
- Changing the four existing detector scripts or their three test suites.
- Adding a per-file or per-package coverage breakdown — the gate is a single project-level threshold check.
- Specifying the exact file name, job name, or structural form of the CI artifact — those are architect decisions per R-01.
- Authoring the JA sibling (`specs/12-coverage-ci-gate.ja.md`) — that is technical-writer's responsibility, sequenced after implementation, with heading-tree parity owned by Roadmap #06. <!-- ref-allow: the JA sibling is a forthcoming file authored by technical-writer after implementation; its absence at Spec-authoring time is by design (JA parity owned by #06) -->

## References

- ADR-010 (verification-layer generalization) — establishes the default-off posture for `implementation` and `design` domains; cited as the opt-in precedent the architect may draw on when selecting the activation posture for #12
- ADR-014 (Roadmap index as single entry point) — §(d) MECE table at approximately line 1800 names #04, #05, #09, #10, #11 but NOT #12; this absence is the substantive distinction that points toward ADR-019 per the Alternative-B discriminator; the Spec reservation rule provides the `spec:` link used in the Roadmap row <!-- ref-allow: ADR-019 is a forthcoming reserved number cited as a possible outcome of the architect's decision; it does not yet exist by design -->
- ADR-017 (Roadmap drift detector) — the closest detector-precedent ADR; its MECE boundary statements in §2 and its "no back-link" carve-out pattern are the model for #12's MECE boundary framing
- ADR-018 (Bilingual parity detector) — the source of the Alternative-B discriminator the architect must apply when deciding whether #12 warrants ADR-019 or an amendment; also the most recently consumed ADR number, confirming 019 is unused <!-- ref-allow: ADR-019 is a forthcoming reserved number cited as a possible outcome of the architect's decision; it does not yet exist by design -->
- `.claude/CLAUDE.md` `## Testing Requirements` — the canonical single source of truth for the 80% coverage rule that #12's CI scaffold enforces; AC-2 and AC-8 bind the implementation to this location
- `.github/workflows/ci-base.yml` — the existing reusable workflow scaffold; #12 either extends it or ships alongside it; its `workflow_call` input pattern is the forkability model for AC-3
- `.github/workflows/workaround-check.yml` — the default-off-single-switch posture precedent the architect may follow for #12's activation mechanism
- `specs/05-roadmap-drift-detection-ci.md` — the closest structural sibling: a detector-plus-CI-workflow milestone with a two-session design-then-implement split; its R-01 and R-04 ref-allow pattern is the model for #12's ref-allow discipline
- `specs/11-verification-domain-opt-in-guidance.md` — the immediate house-style sibling; its Status block format, R-01 deferral pattern, and ref-allow note pattern in R-01 are the direct models for #12
- Roadmap row: #12
