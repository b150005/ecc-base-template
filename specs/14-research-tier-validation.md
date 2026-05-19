# Research-tier Validation for auth→T2 Mis-classifications

## Status

Approved

**Owner:** product-manager / implementer
**Target release:** template v3.15.0

## Context note: verification-layer applicability for this milestone

This milestone is an **internal-structure milestone** (template meta-infrastructure, no external API or library research required to build it). The verification-layer research domain therefore does **not** apply to building #14 — there are no external facts from third-party sources to verify: no library selection, no API usage, no version pin, no breaking-change assessment. This is identical to the N/A posture stated for #11, #12, and #13.

#14's **subject matter**, however, *is* the research-domain Tier model (T1/T2/T3) and the `default_tier: T2` configuration in `.claude/verification.yml`. The Spec necessarily references that model as subject content. Referencing the Tier model as subject content is not the same as invoking the verification layer for the research needed to build this milestone. These two readings are MECE and must not be conflated.

## Problem

The research-domain Tier table (`.claude/skills/verification-layer/research/protocol.md`) defines **T1** as the mandatory Tier for "breaking changes, auth, security-sensitive APIs, crypto primitives." The research-domain configuration (`.claude/verification.yml`) sets `default_tier: T2` — a weaker enforcement level where the Critic runs once with no further iteration unless CRITICAL or HIGH findings remain.

The Tier is **Generator-declared per output**: the `docs-researcher` agent declares the Tier on each research result before the Critic reviews it. The orchestrator may escalate upward (T3→T2, T2→T1) but never downward.

The failure mode: when `docs-researcher` researches an auth-related external fact (authentication library behaviour, authn/authz API shape, token-handling default, session-management flag) but does not explicitly declare T1 for that output, the fact silently falls to `default_tier: T2`. The orchestrator's "Tier-confirmation guardrail" (`orchestrator.md` lines 104–109) provides a prose backstop: it lists `auth`, `authn`, `authz`, `crypto`, `breaking change`, `migration`, `CVE`, `security`, `permission`, `token` as keywords that trigger Tier confirmation before the declared Tier is accepted. That guardrail fires at routing time and depends on the orchestrator recognising those keywords in the research topic.

The gap: the guardrail is a prose instruction to the orchestrator. It is not validated, testable at CI time, or surfaced as a written contract that can be audited against the Tier table. A Generator output whose topic description omits the auth keyword — but whose content concerns authentication logic — can still reach T2 review without the orchestrator guardrail firing. Neither `protocol.md` nor `verification.yml` states the auth→T1 requirement in a form that is independently checkable as a written contract separate from the orchestrator's runtime judgement.

Milestone #14 closes this gap by establishing a **validation mechanism** — the form of which is deferred to the architect — so that the auth-touches-T1 requirement is expressed as a testable, discoverable contract and not only as an orchestrator prose instruction.

## Goals

- State the auth→T1 requirement as an independently-verifiable, written contract: the scope of T1 in `protocol.md` (breaking changes, auth, security-sensitive APIs, crypto) is not only a Tier-table description but a validation-triggering rule.
- Ensure a Generator output whose declared Tier is T2 or T3 but whose content concerns auth/authn/authz/crypto/security-sensitive topics is detectable as a potential mis-classification before it reaches the Critic at T2 — closing the gap that the orchestrator guardrail alone leaves open for topic-description omissions.
- Ensure the mechanism (whatever form the architect selects) does not require the orchestrator to be the sole enforcement point; a second, independently-checkable representation of the auth→T1 rule must exist.
- Establish a MECE boundary between #14's owned question ("Is a research output with auth-touching content correctly classified at T1, as a validatable contract?") and the five existing detectors, none of which owns a research-Tier classification check.
- Leave `default_tier: T2`, the Tier table structure, and the orchestrator guardrail prose **unchanged**. #14 adds a validation layer above the existing machinery; it does not alter the Tier table, the default, or the orchestrator's runtime logic.

## Non-goals

- Changing `default_tier: T2` in `.claude/verification.yml` — the default is correct for the non-auth, non-security majority of research outputs; #14 narrows *when* T2 is safe to use by adding a validation constraint, it does not change the default.
- Changing the Tier table definition in `research/protocol.md` — the T1 scope already names "auth"; #14 makes that scope a testable contract, it does not re-define what T1 means.
- Changing the orchestrator Tier-confirmation guardrail prose (`orchestrator.md` lines 104–109) — that guardrail is a runtime backstop that complements the validation mechanism #14 introduces; neither replaces the other.
- Checking path resolution, ADR textual references, or `.claude/`-rooted path mentions — that is milestone #04 (`check-dangling-refs.sh`, ADR-015).
- Checking the Roadmap bidirectional-link contract or status-glyph well-formedness — that is milestone #05 (`check-roadmap-drift.sh`, ADR-017).
- Checking EN/JA heading-tree parity — that is milestone #06 (`check-bilingual-parity.sh`, ADR-018).
- Enforcing a test-coverage threshold — that is milestone #12 (`coverage-gate.yml`, ADR-019).
- Detecting ECC-absent degraded-review posture or delegation-table consistency — that is milestone #13 (`check-ecc-delegation-consistency.sh`, ADR-020).
- Changing or extending the five existing detector scripts (`check-dangling-refs.sh`, `check-roadmap-drift.sh`, `check-skill-invariants.sh`, `check-bilingual-parity.sh`, `check-ecc-delegation-consistency.sh`) or their test suites. #14 introduces no changes to those artifacts.
- Handling research topics that are unambiguously non-auth (pure style lookups, T3 convention questions). The validation mechanism applies to the auth→T1 boundary; T3 for idiomatic style is out of scope.
- Specifying the exact form of the validation mechanism (a new agent-prompt constraint, a new detector, an extension of an existing artifact, a protocol amendment, or a combination) or whether it warrants a new ADR-021 or an amendment. That is the architect's structural decision (see Risk R-01).
- Applying the verification-layer research domain to *building* this milestone. As stated in the Context note above, #14 is an internal-structure milestone with no external research required.
- Authoring the JA sibling (`specs/14-research-tier-validation.ja.md`) — that is technical-writer's responsibility, sequenced after implementation, with heading-tree parity owned by Roadmap #06.

## Target users

| Persona | Description | Primary Need |
|---------|-------------|--------------|
| docs-researcher (agent) | Declares a Tier on every research output before the Critic reviews | A written, discoverable constraint that reminds it the auth→T1 rule is not advisory but mandatory — and that T2 is not safe for auth-touching outputs regardless of the topic description's wording |
| orchestrator (agent) | Routes research output to the Critic at the declared Tier, applying the Tier-confirmation guardrail | A second, independently-checkable representation of the auth→T1 rule — so that even if the guardrail's keyword scan misses an auth-adjacent output, the contract is auditable |
| Fork maintainer (human) | Adopts the template's verification layer for a project that uses auth libraries or handles tokens | Confidence that the T1 requirement for auth-touching research is expressed as a testable written contract, not only a prose note they must read and remember |
| Template maintainer (this repo) | Edits `protocol.md`, `verification.yml`, or agent prompts in the research domain | An auditable statement of the auth→T1 constraint so that a future edit cannot silently remove the rule without an explicit, visible change |

## User stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| docs-researcher | Encounter the auth→T1 rule as a mandatory written constraint at the point I declare a Tier | I cannot accidentally declare T2 for an auth-touching output without that classification being checkable against the written rule |
| orchestrator | Find the auth→T1 validation rule in a form I can apply independent of my keyword-scanning guardrail | A topic description that omits the "auth" keyword does not silently bypass the T1 requirement for content that concerns authentication |
| Fork maintainer | See the auth→T1 requirement stated as a testable contract in the verification-layer artifacts | I can audit at adoption time whether the contract is intact, without reading orchestrator prose to discover whether auth outputs get T1 treatment |
| Template maintainer | Have an auditable written constraint that the auth→T1 boundary is mandatory | A future edit to `protocol.md` or `verification.yml` that weakens the auth→T1 rule is an explicit, visible change, not a silent omission |

## Acceptance criteria

- **AC-1.** Given the artifact(s) #14 places its validation contract in (the exact artifact(s) and section(s) are determined by the architect), when a `docs-researcher` output concerns auth, authn, authz, crypto, security-sensitive API usage, or token handling, then the contract states unambiguously that the required Tier is T1 — this requirement is expressed as a mandatory rule, not as guidance or a best-practice suggestion, and is independently readable without first consulting `orchestrator.md`.

- **AC-2.** Given the validation contract established by #14, when a reviewer compares it to the orchestrator's Tier-confirmation guardrail (`orchestrator.md` lines 104–109), then it is unambiguous that the two are complementary and non-duplicative: the orchestrator guardrail is the *runtime routing* check (fires when the orchestrator sees certain keywords in the topic description), and #14's contract is the *written, independently-checkable* statement of the same rule — such that failure of the guardrail's keyword scan (topic description omits "auth") does not leave the contract unenforceable as a written obligation.

- **AC-3.** Given the validation contract established by #14, when a reviewer examines it for changes to `default_tier: T2` in `.claude/verification.yml`, then the value is unchanged — confirming #14 narrows *when* T2 applies (not for auth-touching outputs) without altering the default for the non-auth majority.

- **AC-4.** Given the validation contract established by #14, when a reviewer examines it for changes to the Tier table definition in `research/protocol.md` (the T1 scope line: "Breaking changes, auth, security-sensitive APIs, crypto primitives"), then the Tier table is unchanged — confirming #14 makes the existing T1 scope a testable contract, not a redefinition of scope.

- **AC-5.** Given the validation contract established by #14, when a reviewer examines it for changes to the orchestrator's Tier-confirmation guardrail prose (`orchestrator.md` lines 104–109), then that prose is unchanged — confirming #14 added a complementary written contract and did not alter the orchestrator's runtime logic.

- **AC-6.** Given the five existing detector scripts (`check-dangling-refs.sh`, `check-roadmap-drift.sh`, `check-skill-invariants.sh`, `check-bilingual-parity.sh`, `check-ecc-delegation-consistency.sh`) and their test suites, when milestone #14 ships, then none of those files has been modified — confirming #14 introduces no scope bleed into the existing detector layer.

- **AC-7.** Given a future milestone author evaluating where to route an auth-Tier concern, when they read the MECE boundary established by #14, then the owned question is unambiguous: "Is a research output with auth-touching content validated as T1, expressible as an independently-checkable written contract?" This question is distinct from #04's (path resolution), #05's (Roadmap structural), #06's (EN/JA parity), #12's (coverage threshold), and #13's (ECC-absent review posture). No existing detector or contract owns the auth→T1 mis-classification question; an auth-Tier concern must route to #14 or a successor milestone.

- **AC-8.** Given the validation contract established by #14, when examined for operator-environment filesystem introspection or external-source lookups, then it performs none — confirming the contract is derivable entirely from artifacts inside the repository (the Tier table in `protocol.md`, the `default_tier` in `verification.yml`, the auth-keyword list in `orchestrator.md`) without any live probe of external services.

## Key interactions

1. **Interaction with `research/protocol.md` Tier table.** The Tier table already names "auth" in T1's scope: "Breaking changes, auth, security-sensitive APIs, crypto primitives." The table is a description of when to use T1; it does not currently function as a validatable contract. #14's validation mechanism makes the auth→T1 requirement checkable against a second representation — without changing the table. The architect's placement decision (R-01) determines whether the second representation is a new constraint in the Generator's pre-research checklist, an amendment to the Tier table itself, a new machine-readable rule, or another form.

2. **Interaction with `.claude/verification.yml` `default_tier: T2`.** The default is correct for the non-auth majority and must remain T2. #14's mechanism defines the exception — auth-touching outputs cannot silently fall to T2 — as a written constraint independent of the Generator's topic-description wording. AC-3 is specifically verifiable for the no-change-to-default requirement.

3. **Interaction with `orchestrator.md` Tier-confirmation guardrail (lines 104–109).** The guardrail fires at routing time when the orchestrator recognises the keywords `auth`, `authn`, `authz`, `crypto`, `breaking change`, `migration`, `CVE`, `security`, `permission`, `token` in the research topic. The failure case: a research output whose topic description uses "login flow" or "session management" without those keywords. #14's second representation must remain enforceable even when the guardrail's scan fails. The two are complementary; neither replaces the other (AC-2).

4. **Interaction with the five existing detectors (#04/#05/#06/#12/#13).** If the architect's chosen mechanism is a new detector, it joins the `check-*.sh` family that #04 established and #05/#06/#13 mirrored. Whether that is the right shape — or whether a documentation/convention placement (analogous to #11's ADR-014:1800 "documentation/convention" classification) is more appropriate — is the architect's structural decision. #14's Non-goals fix that #14 does not modify the five existing detectors or their suites regardless of mechanism.

5. **Interaction with ADR-020 (#13 — ECC-absent signal).** ADR-020 is the most recently consumed ADR number. If the architect's structural decision for #14 warrants a new ADR, ADR-021 is the next unused number. Whether a new ADR-021 is warranted or an amendment suffices is the architect's decision, applying the ADR-018 Alternative-B discriminator (see Risk R-01).

6. **Interaction with ADR-014 §(d) MECE table.** ADR-014's §(d) MECE table names #04, #05, #09, #10, #11 (amended for #12 via ADR-019's reasoning, and for #13 via ADR-020). It does not pre-reserve a slot for #14. #14 therefore does not occupy a pre-reserved documentation/convention slot — a substantive distinction the architect must weigh when applying the ADR-018 Alternative-B discriminator. This mirrors the observation made by `specs/12-coverage-ci-gate.md` R-01 for #12 and `specs/13-ecc-absent-signal.md` R-01 for #13.

7. **Structural HOW deferred to architect.** Whether #14 ships as (a) an amendment to `research/protocol.md` that elevates the T1 scope line to a mandatory pre-classification rule with a machine-readable marker, (b) a new agent-prompt constraint in `docs-researcher.md` that fires before a Tier declaration is accepted, (c) a new standalone contract document or SKILL.md section that names the auth→T1 requirement as an independently-checkable obligation, (d) a detector-style script that audits research outputs in the session or in CI for T2/T3 declarations on auth-keyword-matching topics, or (e) some combination — all deferred to the architect's forthcoming decision. The architect applies the ADR-018 Alternative-B discriminator verbatim. ADR-021 is the next unused number (ADRs 016–020 are consumed). The architect decides; this Spec does not.

## Metrics

- **Leading:** After #14 ships, the auth→T1 requirement is expressed as a written, independently-checkable contract in at least one artifact other than `orchestrator.md` — verifiable by reading the artifact the architect places it in.
- **Leading:** Zero modifications to the five existing detector scripts or their test suites (AC-6), verifiable via `git diff` against those artifacts.
- **Leading:** `default_tier: T2` in `.claude/verification.yml` is unchanged after the milestone ships (AC-3), verifiable by reading the file.
- **Lagging:** Reduction in auth-touching research outputs that silently reach the Critic at T2 across derived repositories, observable through audit of Generator Tier declarations over time once the contract is in place.

## Risks and open questions

### Risk R-01: Structural decision deferred to architect — validation mechanism, placement, ADR strategy

**Description.** This Spec states *what* the validation contract must achieve (auth-touching outputs cannot silently settle at T2; the rule is independently checkable; default_tier, Tier table, and orchestrator guardrail are unchanged; no scope bleed into existing detectors; no external introspection) and the acceptance criteria for a conformant mechanism (AC-1 through AC-8). It explicitly defers the structural *how*: whether the mechanism is a protocol amendment, an agent-prompt constraint, a documentation/convention placement, a new detector, or a combination; the exact artifact(s) and section(s) where the contract lands; and whether the resolution warrants a new ADR-021 or an amendment to an existing ADR (ADR-008, ADR-010, or another).

**ADR-018 Alternative-B discriminator, handed to architect explicitly.** The architect must apply this discriminator: does #14 introduce a NEW contract boundary, NEW keying/mechanism, and NEW structural artifact none of the existing detectors own (⇒ new ADR-021), or is it a consequence-clarification / extension of ADR-008's already-stated-but-unformalized T1-for-auth rule (⇒ ADR-008 amendment)? ADR-020 is the latest consumed number; ADR-021 is the next unused number. This mirrors the explicit hand-off in `specs/12-coverage-ci-gate.md` R-01 and `specs/13-ecc-absent-signal.md` R-01.

**Mitigation constraint handed to architect.** The architect's forthcoming decision must specify: (a) the exact artifact(s) and section(s) where the auth→T1 validation contract lands, such that it is independently readable without consulting `orchestrator.md`; (b) how the contract covers topic-description-omission failures (auth content without the "auth" keyword in the topic) that the orchestrator guardrail scan can miss; (c) whether the resolution is a new ADR-021 or an amendment to an existing ADR (the Alternative-B discriminator, with the clause-by-clause reasoning recorded); (d) the explicit statement of where #14 sits in the MECE boundary against #04/#05/#06/#12/#13 and the per-domain Tier machinery, and whether it adds a new contract partition. Until that decision exists, the gap identified in this Spec (auth→T1 rule expressed only as orchestrator prose; topic-description omissions can silently route to T2) remains the operating state.

**Note:** The `<!-- ref-allow: -->` suppressions that were on lines referencing the forthcoming architect decision (ADR-021) and the JA sibling (`specs/14-research-tier-validation.ja.md`) lived only in this Spec file at authoring time, following the precedent set by `specs/13-ecc-absent-signal.md`, `specs/12-coverage-ci-gate.md`, and `specs/11-verification-domain-opt-in-guidance.md`. They do NOT appear in `.claude/CLAUDE.md`. Those suppressions were removed once ADR-021 and the JA sibling were realized (the #11/#12/#13 over-suppression removal precedent).

### Risk R-02: Scope creep toward changing the Tier table or the default_tier

**Description.** A future author or reviewer may conflate "add a validation contract" with "redefine T1's scope" or "raise default_tier to T1 for all research." The former is broader than #14; the latter eliminates the T2 tier's utility for the non-auth majority.

**Mitigation.** AC-3 and AC-4 are specifically verifiable for the no-change-to-default and no-change-to-Tier-table requirements. The Non-goals codify both. If a future author proposes redefining T1 scope or changing `default_tier`, the correct response is to route that as a new milestone or a deliberate amendment to ADR-008, not to fold it into #14.

### Risk R-03: Scope creep toward handling all security-topic mis-classifications

**Description.** The Tier table's T1 scope names "auth, security-sensitive APIs, crypto primitives" — not only "auth." The mechanism #14 specifies for auth also applies in principle to crypto and security-sensitive APIs. Broadening to all T1-scoped topics is a larger surface.

**Mitigation.** The auth→T2 mis-classification is the named, specific failure mode from the orchestrator Analyze scope sketch. The architect's implementation may naturally cover the full T1 scope (auth + crypto + security-sensitive APIs) if the chosen mechanism operates on the full T1 scope line rather than on "auth" alone — and that is acceptable. What is NOT acceptable is extending the scope to topics outside T1's already-defined scope (e.g., inventing new T1 categories). The Non-goals and AC-1 bound this: the contract covers the T1 scope as it already exists in `protocol.md`, applied as a mandatory rule. No new T1 categories may be introduced by #14.

### Risk R-04: Validation contract becomes stale if protocol.md is later amended

**Description.** If the Tier table's T1 scope line in `protocol.md` is later amended (e.g., to add "OAuth flows" explicitly), and the validation contract in a separate artifact is not updated, the two representations diverge. This is the same "rows go stale silently" failure ADR-012 named for the `code-reviewer` delegation table.

**Mitigation.** The architect's structural decision (R-01) must specify how the validation contract and `protocol.md` stay in sync. One approach: the contract references `protocol.md`'s T1 scope line directly rather than reproducing it, so the single source of truth for scope is still the Tier table. Another: both live in the same artifact. The implementer must verify that a future `protocol.md` T1-scope amendment would require updating the contract too, not allow silent divergence.

## Out of scope

- Changing `default_tier: T2` in `.claude/verification.yml`.
- Changing the Tier table definition in `research/protocol.md`.
- Changing the orchestrator Tier-confirmation guardrail prose (`orchestrator.md` lines 104–109).
- Modifying the five existing detector scripts (`check-dangling-refs.sh`, `check-roadmap-drift.sh`, `check-skill-invariants.sh`, `check-bilingual-parity.sh`, `check-ecc-delegation-consistency.sh`) or their test suites.
- Handling research topics that are unambiguously non-auth (T3 style lookups, T2 non-security-adjacent API questions).
- Authoring the JA sibling (`specs/14-research-tier-validation.ja.md`) — that is technical-writer's responsibility, sequenced after implementation, with heading-tree parity owned by Roadmap #06.
- Translating any new scaffold to CI providers other than GitHub Actions, if the architect selects a CI mechanism.
- Authoring ADR-021 — that is the architect's responsibility if the structural decision warrants a new ADR.

## References

- ADR-008 (research verification layer) — establishes the Tier table and the T1-for-auth scope that #14's validation contract makes testable; the existing T1 scope line ("auth, security-sensitive APIs, crypto primitives") is the primary source of the auth→T1 rule
- ADR-010 (verification-layer generalization) — establishes the cross-domain structure and opt-in switches; the `research` domain's `default_tier: T2` is set in `.claude/verification.yml` per ADR-008's intent, now constrained by #14's auth→T1 obligation
- ADR-018 (bilingual parity detector) — the source of the Alternative-B discriminator the architect must apply when deciding whether #14 warrants ADR-021 or an amendment; the most recently consumed ADR number before ADR-019/020 is 018 (confirming 021 is the next unused number after the 019/020 sequence)
- ADR-020 (ECC-absent degraded-review signal) — the most recently consumed ADR number; ADR-021 is the next unused number if the architect's decision warrants a new ADR
- `.claude/skills/verification-layer/research/protocol.md` — Tier table (lines 49–53), whose T1 scope "auth, security-sensitive APIs, crypto primitives" is the contract #14 makes independently verifiable; the `default_tier: T2` configuration whose auth-exception #14 codifies
- `.claude/verification.yml` lines 34–38 — `default_tier: T2` declaration and its T1/T2/T3 comment block (T1 names "auth" explicitly); the gap #14 closes is that this comment block is not a testable contract
- `.claude/agents/orchestrator.md` lines 104–109 — Tier-confirmation guardrail that lists auth/authn/authz/crypto/breaking change/migration/CVE/security/permission/token as escalation keywords; the runtime backstop that #14's written contract complements without replacing
- `specs/12-coverage-ci-gate.md` — structural sibling; its R-01 establishes the ADR-018 Alternative-B discriminator instruction and the "not a pre-reserved §(d) slot" observation this Spec mirrors
- `specs/13-ecc-absent-signal.md` — structural sibling; its R-01, ref-allow note precedent, and MECE boundary pattern this Spec follows; the most recent precedent in the same milestone family
- `specs/11-verification-domain-opt-in-guidance.md` — verification-layer sibling; establishes the N/A posture for internal-structure milestones in the Context note of this Spec
- Roadmap row: #14
