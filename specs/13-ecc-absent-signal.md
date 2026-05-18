# ECC-absent Degraded-review Signal

## Status

Approved

**Owner:** product-manager / implementer
**Target release:** template v3.14.0

## Problem

ADR-012 made `code-reviewer` a meta-reviewer that delegates language-specific depth to ECC's `*-reviewer` agents (`typescript-reviewer`, `python-reviewer`, `go-reviewer`, …). ADR-012's own Negative section records two costs it deliberately left unmitigated: (1) "Forks that never install ECC permanently operate at reduced review quality" and (2) "The contract with ECC reviewers is **unversioned**. If ECC renames `typescript-reviewer` or substantially changes its prompt contract, the dispatcher's delegation rows go stale silently. There is no CI check on the existence of the target agents."

Today the only ECC-absent / degraded-review signals are: the per-review verdict-line note inside `code-reviewer.md` (three-case delegation rule, lines 66–87 — fires only when a review actually runs), and one static prose paragraph in `README.md` `## Prerequisites` (read by humans browsing the README, not propagated to any agent or CI surface). Neither makes the *standing* degraded-review posture — "this fork's `code-reviewer` delegation table names ECC agents that may not exist in the operator environment, and the language-specific review layer will silently be weaker" — discoverable at a deterministic, non-review-time checkpoint. The delegation table in `code-reviewer.md` (the nine `manifest → ECC reviewer` rows) can also drift out of sync with the agent names it references without anything noticing, which is the precise "rows go stale silently" failure ADR-012 named and left open.

## Goals

- Make the standing degraded-review posture an explicit, deterministic signal that is observable without first running a code review — closing ADR-012's recorded "no CI check on the existence of the target agents" / "rows go stale silently" gap to the extent the template environment allows.
- Keep the signal correct in the template's own CI, where ECC is by construction never present in-repository (ECC installs at the user level, `~/.claude/`, outside any repository). The signal must not produce a false "something is broken" failure for the normal, expected ECC-absent CI condition; it reports posture, it does not fail the build for the expected case.
- Establish a MECE boundary between this milestone's owned question and the four existing detectors and the per-change/runtime signals already owned by `code-reviewer.md` and `README.md`, so a future milestone author can route scope unambiguously.
- Leave `code-reviewer`'s three-case delegation rule and its conservative "pick case 3 by default" posture unchanged. ADR-012's runtime behavior is correct; #13 adds a standing, non-review-time signal, it does not alter the per-review one.
- Place the signal so that the artifact a fork maintainer or agent already consults at the relevant checkpoint surfaces it — without requiring a new always-read file or a third lookup beyond what that checkpoint already mandates (the exact placement and mechanism are deferred to the architect; see Risk R-01).

## Non-goals

- Checking path resolution, ADR textual references, or `.claude/`-rooted path mentions — that is milestone #04 (`check-dangling-refs.sh`, ADR-015).
- Checking the Roadmap bidirectional-link contract or status-glyph well-formedness — that is milestone #05 (`check-roadmap-drift.sh`, ADR-017).
- Checking EN/JA heading-tree parity — that is milestone #06 (`check-bilingual-parity.sh`, ADR-018).
- Enforcing a coverage threshold — that is milestone #12 (`coverage-gate.yml`, ADR-019).
- Detecting whether ECC *is installed in the operator's `~/.claude/`*. That is impossible from inside a repository and from CI by construction (ECC is user-level, outside the repo). #13 must not attempt filesystem introspection of the operator environment; doing so would reproduce exactly the unreliable runtime introspection `code-reviewer.md` lines 84–87 explicitly forbids ("The agent does not introspect the filesystem … Pick case 3 by default when in doubt").
- Changing `code-reviewer`'s three-case delegation rule, its delegation table semantics, or its "pick case 3 by default when in doubt" conservative posture. ADR-012's runtime contract is correct and is not in scope for this milestone.
- Vendoring ECC's language-specific reviewers into `.claude/agents/` to remove the dependency. That is ADR-012's deliberately-rejected Counter-proposal (Alternative B); #13 makes the *existing* dependency's degraded posture visible, it does not eliminate the dependency.
- Failing the template's own CI for the expected ECC-absent condition. The signal is a posture report, not a hard gate, for the normal case. (Whether it can additionally hard-fail on a genuine internal inconsistency — e.g. the delegation table referencing a name that the template itself contradicts — is a structural decision deferred to the architect; see Risk R-01.)
- Specifying the exact mechanism (a new detector script + workflow, an extension of an existing detector, a documentation/convention statement, an agent-prompt change, or a combination) and whether it warrants a new ADR-020 or an ADR-012 amendment. That is the architect's structural decision (see Risk R-01).
- Changing the four existing detector scripts (`.claude/meta/scripts/check-dangling-refs.sh`, `check-roadmap-drift.sh`, `check-skill-invariants.sh`, `check-bilingual-parity.sh`) or their test suites. #13 introduces no changes to those artifacts.

## Target users

| Persona | Description | Primary Need |
|---------|-------------|--------------|
| Fork maintainer (human) | Sets up a derived project that inherits the ECC-dependent `code-reviewer` dispatcher | To know, at a deterministic checkpoint and without first running a review, that the language-specific review layer depends on ECC and is degraded if ECC is absent — not to discover it only buried in a verdict line after a review already ran |
| Template adopter team lead | Reviews the template's review posture at project inception or quarterly | A single, discoverable statement of the standing degraded-review posture and of whether the delegation table is internally consistent — not a per-review note that only appears when someone happens to run `code-reviewer` |
| Orchestrator / code-reviewer (agent) | Coordinates the step-6 quality gate and the delegation hand-off | An unambiguous standing signal about the degraded posture, so the agent does not have to re-derive ADR-012's three-case logic from scratch to know the posture applies |
| Template maintainer (this repo) | Edits `code-reviewer.md`'s delegation table | A signal that fires when the delegation table drifts (a row names an agent the template's own contract no longer supports), catching the "rows go stale silently" failure ADR-012 named |

## User stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| Fork maintainer | Encounter the degraded-review posture at a deterministic checkpoint before running a review | I can decide to install ECC (or accept the degraded posture knowingly) at adoption time, not discover the degradation only inside a verdict line afterward |
| Template adopter team lead | See one discoverable statement of the standing degraded posture and the delegation table's internal consistency | I do not have to run a code review and read its verdict to learn whether my fork's review depth is degraded |
| Orchestrator / code-reviewer | Read a standing signal that the degraded posture applies | I report it without re-deriving ADR-012's three-case rule from first principles each time |
| Template maintainer | Be alerted when `code-reviewer.md`'s delegation table references an agent name inconsistent with the template's own contract | The "delegation rows go stale silently" failure ADR-012 left open is caught instead of going unnoticed |

## Acceptance criteria

- **Given** a fork maintainer or agent consults the artifact #13 places its signal in (the exact artifact and section are determined by the architect) **when** they look for the review posture **then** the standing degraded-review posture is stated explicitly: that `code-reviewer`'s language-specific layer delegates to ECC `*-reviewer` agents and is degraded (template cross-cutting checks only) when ECC is absent — discoverable without first running a code review.

- **Given** the signal **when** a reader compares it to `code-reviewer.md` lines 66–87 (the three-case delegation rule) **then** it is unambiguous that #13's signal is the *standing, non-review-time* posture signal and the three-case rule is the *per-review, runtime* signal — the two are complementary, not duplicative, and #13's text does not restate the three-case mechanics.

- **Given** the template's own repository running its CI **when** the #13 signal evaluates **then** it does not produce a CI failure for the normal, expected condition that ECC is absent in-repository (ECC is user-level by construction). The signal reports posture for the expected case; it does not hard-fail the build for it.

- **Given** `code-reviewer.md`'s delegation table **when** #13's mechanism evaluates it **then** the mechanism detects a drift where a delegation-table row references an ECC agent name that is inconsistent with the template's own delegation contract (the "rows go stale silently" failure ADR-012 named), to the extent the chosen mechanism can determine internal consistency without operator-environment introspection.

- **Given** the #13 signal **when** examined for operator-environment filesystem introspection **then** it performs none — confirming #13 does not attempt to detect whether ECC is installed in `~/.claude/`, consistent with `code-reviewer.md` lines 84–87 forbidding unreliable runtime introspection.

- **Given** `code-reviewer.md`'s three-case delegation rule and "pick case 3 by default" posture **when** a reviewer diffs them after #13 ships **then** they are unchanged — confirming #13 added a standing signal and did not alter ADR-012's runtime contract.

- **Given** the signal placement **when** a fork maintainer evaluates the review posture at adoption **then** they encounter it without reading a file that is not already part of the checkpoint at which the posture is relevant (no new always-read file; no third lookup beyond what that checkpoint already mandates — the exact co-location is the architect's decision).

- **Given** the #13 mechanism **when** a future milestone author examines it for scope routing **then** the MECE boundary between #13 (degraded-review posture / delegation-table consistency), #04 (path resolution), #05 (Roadmap structural), #06 (EN/JA parity), #12 (coverage threshold), and the per-review signals already owned by `code-reviewer.md`/`README.md` is unambiguous — #13 owns a question none of those own.

## Key interactions

1. **Interaction with `code-reviewer.md` lines 66–87 (three-case delegation rule).** That rule answers, *at review time*, "for this review, did delegation succeed / fail / not get attempted, and is this review degraded?" #13 answers the prior, *standing* question: "does this fork operate under a degraded-review posture at all, and is the delegation table internally consistent?" The two are complementary. #13's signal must not restate the three-case mechanics; it should direct the reader to `code-reviewer.md` for the per-review question.

2. **Interaction with `README.md` `## Prerequisites` (lines 11–24).** That paragraph states the degraded posture in prose for a human browsing the README. It is not surfaced at any agent or CI checkpoint. #13 closes the gap that the posture is not discoverable at the checkpoint where it is actionable — the architect's placement decision (R-01) determines whether the gap is closed by a detector, an agent-prompt/CLAUDE.md statement, an extension of an existing detector, or a combination, and how it relates to the existing README prose.

3. **Interaction with ADR-012 (Code Reviewer as Dispatcher).** ADR-012's Negative section explicitly records "no CI check on the existence of the target agents" and "delegation rows go stale silently" as costs it left unmitigated, and its Counter-proposal (Alternative B, vendor reviewers locally) was deliberately rejected. #13 addresses the *recorded-but-unmitigated cost*; it does not revisit the rejected Counter-proposal and does not eliminate the ECC dependency. Whether #13's resolution is a new ADR-020 or an ADR-012 amendment is the architect's call (R-01).

4. **Interaction with the detector family (#04/#05/#06) and #12.** If the architect's chosen mechanism is a new detector, it joins the `check-*.sh` family that #04 established and #05/#06 mirrored. Whether that is the right shape, and whether it draws a new MECE contract boundary requiring a new ADR (the ADR-018 Alternative-B discriminator), is the architect's structural decision. #13's Non-goals fix that #13 does not modify the four existing detectors or their suites regardless of mechanism.

5. **Interaction with ADR-014 §(d) MECE boundary.** ADR-014's §(d) MECE table names #04, #05, #09, #10, #11 (and is amended for #12 via ADR-019's reasoning); it does **not** pre-reserve a slot for #13. #13 therefore does not occupy a pre-reserved documentation/convention slot — a substantive distinction the architect must weigh when applying the ADR-018 Alternative-B discriminator (mirrors `specs/12-coverage-ci-gate.md` R-01's identical observation for #12).

6. **Structural HOW deferred to architect.** Whether #13 ships as (a) a new default-off detector script + workflow analogous to `workaround-check.yml`/`coverage-gate.yml` that checks `code-reviewer.md`'s delegation-table internal consistency, (b) a documentation/convention statement co-located with `code-reviewer.md`/`README.md`/CLAUDE.md that makes the standing posture discoverable at the right checkpoint, (c) an extension of an existing detector, or (d) some combination — all deferred to the architect's forthcoming decision. The architect applies the ADR-018 Alternative-B discriminator verbatim: *does #13 introduce a NEW detector + a NEW MECE contract boundary + a NEW keying/mechanism (⇒ new ADR-020), or is it a consequence-clarification / extension of ADR-012's already-recorded-but-unmitigated Negative (⇒ ADR-012 amendment)?* ADR-020 is the next unused ADR number (016/017/018/019 are consumed by #03/#05/#06/#12; the ADR-014 amendments at #07–#11 do not consume new numbers). The architect decides; this Spec does not.

## Metrics

- **Leading:** After #13 ships, a fork maintainer or agent encounters the standing degraded-review posture at a deterministic checkpoint without first running a code review — verifiable from the placed signal.
- **Leading:** CI on the template's own `main` branch does not gain a failing job for the expected ECC-absent condition immediately after the milestone ships (AC-3), verifiable by running the template CI.
- **Leading:** Zero modifications to the four existing detector scripts or their test suites, verifiable via `git diff` against those artifacts (Non-goals).
- **Lagging:** Reduction in derived repos that silently operate under a degraded review posture without the maintainer having made an informed decision, observable through fork audit over time.

## Risks and open questions

### Risk R-01: Structural decision deferred to architect — signal mechanism, placement, ADR strategy

**Description.** This Spec states *what* the signal must achieve (the standing degraded-review posture is discoverable at a deterministic non-review-time checkpoint; delegation-table internal-consistency drift is caught; no operator-environment introspection; no CI failure for the expected ECC-absent case; the three-case runtime rule is unchanged) and the acceptance criteria for a conformant signal. It explicitly defers the structural *how*: whether the mechanism is a new default-off detector script + workflow, a documentation/convention statement, an extension of an existing detector, an agent-prompt/CLAUDE.md change, or a combination; where the signal is placed so a fork maintainer/agent encounters it at the relevant checkpoint without an extra file read; and whether the resolution warrants a new ADR-020 or an ADR-012 amendment (applying the ADR-018 Alternative-B discriminator: NEW detector + NEW MECE contract boundary + NEW keying/mechanism ⇒ new ADR-020; consequence-clarification / extension of ADR-012's already-recorded-but-unmitigated Negative ⇒ ADR-012 amendment; ADR-019 is the latest consumed number, ADR-020 is unused). This mirrors the R-01 pattern used by `specs/12-coverage-ci-gate.md`, `specs/11-verification-domain-opt-in-guidance.md`, `specs/10-spec-adr-directory-pinning.md`, and prior structural Specs.

**Mitigation constraint handed to architect.** The architect's forthcoming decision must specify: (a) the exact mechanism and the exact file(s)/section(s) where the standing signal lands, such that a fork maintainer or agent encounters it at the checkpoint where the degraded posture is actionable without opening a file not already part of that checkpoint; (b) whether the resolution is a new ADR-020 or an ADR-012 amendment (the Alternative-B discriminator), with the clause-by-clause reasoning recorded; (c) if the mechanism is a detector, how it determines delegation-table internal consistency without operator-environment introspection and how it stays green for the template's own expected ECC-absent CI condition; (d) the explicit statement of where #13 sits in the MECE boundary against #04/#05/#06/#12 and the per-review signals, and whether it adds a new contract partition. Until that decision exists, the gap identified in this Spec (degraded posture discoverable only via post-review verdict line or README prose; delegation rows can go stale silently) remains the operating state.

**Note:** The `<!-- ref-allow: -->` suppressions on lines referencing the forthcoming architect decision live only in this Spec file (`specs/13-ecc-absent-signal.md`), following the precedent set by `specs/12-coverage-ci-gate.md` and `specs/11-verification-domain-opt-in-guidance.md`. They do NOT appear in `CLAUDE.md`.

### Risk R-02: Scope creep toward eliminating the ECC dependency

**Description.** A future author or reviewer may conflate "make the degraded posture visible" with "remove the degraded posture by vendoring ECC reviewers locally." The latter is ADR-012's deliberately-rejected Counter-proposal (Alternative B).

**Mitigation.** The Non-goals and Key interaction 3 draw the boundary explicitly: #13 makes the *existing* dependency's degraded posture visible; it does not eliminate the dependency. If a future author proposes vendoring reviewers, the correct response is to route that to a re-litigation of ADR-012's Counter-proposal as its own milestone, not to fold it into #13.

### Risk R-03: Scope creep toward operator-environment introspection

**Description.** "Signal when ECC is absent" can be misread as "detect whether ECC is installed in `~/.claude/`." That detection is impossible reliably from a repository and from CI by construction, and `code-reviewer.md` lines 84–87 explicitly forbid the unreliable runtime introspection it would require.

**Mitigation.** AC-5 is specifically verifiable for the no-introspection constraint; the Non-goals codify it. The signal is about the *standing posture and delegation-table internal consistency*, not a live probe of the operator's machine. The implementer must frame the mechanism so it never reads outside the repository.

## Out of scope

- Modifying the four existing detector scripts (`check-dangling-refs.sh`, `check-roadmap-drift.sh`, `check-skill-invariants.sh`, `check-bilingual-parity.sh`) or their test suites — #13 introduces no changes to those artifacts.
- Changing `code-reviewer`'s three-case delegation rule, delegation table semantics, or "pick case 3 by default" posture — ADR-012's runtime contract is correct and is not in scope.
- Detecting whether ECC is installed in the operator's `~/.claude/` — impossible from a repository/CI by construction and forbidden by `code-reviewer.md` lines 84–87.
- Vendoring ECC's language-specific reviewers into `.claude/agents/` — ADR-012's deliberately-rejected Counter-proposal; out of scope for #13.
- Authoring the JA sibling (`specs/13-ecc-absent-signal.ja.md`) — that is technical-writer's responsibility, sequenced after implementation, with heading-tree parity owned by Roadmap #06.
- Changing ADR-012's Decision or its rejected Counter-proposal — #13 addresses ADR-012's recorded-but-unmitigated Negative, it does not dispute ADR-012's Decision.
- Translating any new scaffold to CI providers other than GitHub Actions.

## References

- ADR-012 (Code Reviewer as Dispatcher) — its Negative section records the unmitigated "no CI check on the existence of the target agents" and "delegation rows go stale silently" costs that #13 addresses; its Counter-proposal (Alternative B) is the deliberately-rejected vendor-locally option #13 must not revisit
- ADR-014 (Roadmap index as single entry point) — §(d) MECE table names #04/#05/#09/#10/#11 (amended for #12 via ADR-019) but does not pre-reserve a slot for #13; the architect weighs this when applying the discriminator
- ADR-018 (bilingual parity detector) — its Alternative-B discriminator (NEW detector + NEW MECE boundary + NEW keying ⇒ new ADR; consequence-clarification/extension ⇒ amendment) is the verbatim instrument the architect applies in R-01
- ADR-019 (CI coverage gate) — most recent consumed ADR number; ADR-020 is the next unused number if the architect's decision warrants a new ADR
- `.claude/agents/code-reviewer.md` lines 66–87 (three-case delegation rule) and lines 84–87 (no-introspection posture) — the per-review runtime signal #13's standing signal complements without restating
- `README.md` `## Prerequisites` lines 11–24 — the existing static prose statement of the degraded posture, not surfaced at any agent/CI checkpoint
- `specs/12-coverage-ci-gate.md` — structural sibling; its R-01 establishes the ADR-018 Alternative-B discriminator instruction and the "not a pre-reserved §(d) slot" observation this Spec mirrors
- `specs/11-verification-domain-opt-in-guidance.md` — structural sibling; its R-01 and `ref-allow` note precedent this Spec follows
- Roadmap row: #13
