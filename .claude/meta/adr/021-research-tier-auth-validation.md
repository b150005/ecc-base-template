# ADR-021: Research-tier auth→T1 validation — a new default-off detector validating auth-touching verification-review artifacts against the protocol.md T1 scope, contract co-located with the Tier table, new MECE partition not pre-reserved by ADR-014 §(d)

## Status

Proposed

<!-- Two-session split (the #03/ADR-016 · #05/ADR-017 · #06/ADR-018 · #12/ADR-019 · #13/ADR-020 precedent): this is the design-only record. The detector script, its forkable default-off workflow, the activation config, and the test suite are landed in a subsequent implementation session. Status moves Proposed → Accepted when that session ships the artifacts and the step-6 quality gate passes green — the #19/#20 transition precedent. -->

## Context

ADR-008 introduced the research verification layer with a **Generator-declared
Tier model**: `docs-researcher` declares T1/T2/T3 on every external-research
output; `research-critic` reviews; the orchestrator may escalate upward
(T3→T2, T2→T1) but never downward. ADR-008 §"Tier definitions" fixes the T1
scope as **"Breaking changes, authentication/authorization, security-sensitive
APIs, cryptographic primitives"**; `.claude/skills/verification-layer/research/protocol.md`
(Tier table, lines 49–53) carries the same line as
**"Breaking changes, auth, security-sensitive APIs, crypto primitives"**;
`.claude/verification.yml` (lines 34–38) sets `default_tier: T2` and a
comment block that also names "auth" in the T1 description.

ADR-008 §"Tier-confirmation guardrail" added a backstop: the orchestrator
applies a closed keyword allowlist (`auth`, `authn`, `authz`, `crypto`,
`breaking change`, `migration`, `CVE`, `security`, `permission`, `token`) and
confirms the declared Tier when the **research topic** contains any of them.
That guardrail is encoded as prose in `.claude/agents/orchestrator.md` — the
`**Tier-confirmation guardrail**:` block.

> **Line-range correction (factual, recorded for the implementer).** The Spec
> (`specs/14-research-tier-validation.md`) repeatedly cites this guardrail as
> "`orchestrator.md` lines 104–109". Independently re-verified in this design
> session with `grep -n` and `sed -n`: the string
> `**Tier-confirmation guardrail**:` **begins on line 103** ("never downward.
> **Tier-confirmation guardrail**: when the") and the block **ends on line
> 109** ("path (ADR-008 §Consequences)."). The Spec's "104–109" is off by one
> at the **start**. The implementer MUST use the **verified range lines
> 103–109**, or — more robustly, because line numbers are brittle — cite the
> guardrail **by content/anchor**: the `**Tier-confirmation guardrail**:`
> block under `.claude/agents/orchestrator.md` §"Research domain routing".
> This ADR does **not** propagate the Spec's "104–109"; every reference
> below uses the corrected range or the content anchor. The Spec's
> Non-goals/Out-of-scope lines that say "orchestrator.md lines 104–109"
> describe a *no-change* obligation on a block whose identity is
> unambiguous by its bold-string anchor; the off-by-one does not change
> the obligation, only the citation, and the corrected citation is
> recorded here so a future reader is not misled.

`specs/14-research-tier-validation.md` is the authoritative scope — AC-1
through AC-8, the Non-goals, R-01 through R-04, the seven Key interactions.
This ADR records the **structural** decisions the Spec explicitly defers to
`architect` (Spec Risk R-01 (a)–(d), Key-interaction 7): the validation
mechanism and its form, the exact artifact(s) and section(s) the auth→T1
contract lands in, the topic-description-omission coverage, the
new-ADR-vs-amendment decision via the ADR-018 Alternative-B discriminator,
the MECE boundary, and the R-04 staleness-sync handling. The Spec names this
decision ADR-021 and hands the discriminator to the architect verbatim; this
ADR closes it.

The gap #14 closes (Spec §Problem): the auth→T1 requirement exists today
**only** as (a) a *descriptive* Tier-table row in `protocol.md` (a "when to
use T1" description, not a checkable obligation) and (b) the orchestrator's
*runtime* keyword scan, which fires only when the orchestrator recognises an
auth keyword **in the topic description**. A Generator output whose topic
description says "login flow" or "session management" — auth content, no
"auth" keyword — declares T2, the orchestrator scan does not fire, and the
output silently reaches the Critic at T2. Neither `protocol.md` nor
`verification.yml` states the auth→T1 rule as a written contract independently
checkable against the artifact, separate from the orchestrator's runtime
judgement.

Six hard constraints bound the design and are non-negotiable (Spec
Non-goals, Out of scope, AC-3/AC-4/AC-5/AC-6/AC-8):

1. **`default_tier: T2` in `.claude/verification.yml` is unchanged
   (AC-3).** The default is correct for the non-auth majority; #14 narrows
   *when* T2 is safe, it does not change the default.
2. **The `protocol.md` Tier-table T1 scope line is unchanged (AC-4).** The
   line already names "auth"; #14 makes that scope a testable contract, it
   does not redefine T1. No new T1 categories (Spec R-03).
3. **The orchestrator Tier-confirmation guardrail prose is unchanged
   (AC-5).** It is a runtime backstop that *complements* #14's contract;
   neither replaces the other (AC-2).
4. **No scope bleed into the five existing detectors (AC-6).**
   `check-dangling-refs.sh`, `check-roadmap-drift.sh`,
   `check-skill-invariants.sh`, `check-bilingual-parity.sh`,
   `check-ecc-delegation-consistency.sh` and their test suites are **not**
   modified.
5. **No operator-environment introspection / external-source lookup
   (AC-8).** The contract is derivable entirely from in-repository
   artifacts; no live probe of external services.
6. **The mechanism does not require the orchestrator to be the sole
   enforcement point (Spec Goals).** A second, independently-checkable
   representation of the auth→T1 rule must exist.

A seventh force is the **ADR-018 Alternative-B discriminator itself**,
handed to the architect by Spec R-01 and Key-interaction 7 and applied
clause by clause in Decision 1 below — the same instrument ADR-019 §5 and
ADR-020 §1 applied for #12 and #13.

An eighth force is the **#04 dangling-reference detector**, now active CI.
This ADR file is in the #04 detector's Check-1 scope; its mentions of the
not-yet-written `.claude/meta/scripts/check-research-tier-auth.sh`,
`.github/workflows/research-tier-auth-check.yml`, and the activation config
fall under Check 2, from which ADR files are excluded by the #04 detector's
own documented scope decision (ADR files are historical records; their
`.claude/`-rooted forward paths are not Check-2-validated). The same
forward-reference lines in this ADR carry `<!-- ref-allow: -->` anchors for
the implementation-session window, the #19/#20 design-time precedent; they
are removed once the artifacts materialize (the #11 over-suppression
precedent — `technical-writer`'s call, not performed here).

## Decision

Resolve #14 as a **new ADR-021** (not an ADR-008 amendment, not an ADR-010
amendment) and ship, in a subsequent implementation session, a **new
default-off detector script plus a forkable default-off workflow** that
validates **verification-review artifacts** for auth-touching content
declared at T2/T3, with the auth→T1 written contract **co-located in
`protocol.md` immediately under the Tier table** (a new prose subsection
that *references the existing T1 scope line, never reproduces it*), **zero
operator-environment introspection**, and the template **green-by-construction**.
Concretely:

### 1. New-ADR-vs-amendment — the ADR-018 Alternative-B discriminator, applied clause by clause

The Spec's R-01 (c) hands `architect` the explicit choice "a new ADR-021 or
an amendment to an existing ADR (ADR-008, ADR-010, or another)" and
instructs the architect to apply ADR-018's Alternative-B discriminator
verbatim: *does #14 introduce a **NEW contract boundary** + **NEW
keying/mechanism** + **NEW structural artifact** none of the existing
detectors own (⇒ new ADR), or is it a **consequence-clarification /
extension** of ADR-008's already-stated-but-unformalized T1-for-auth scope
line (⇒ ADR-008 amendment)?* Applied honestly, clause by clause:

- **NEW contract boundary? Yes — a partition ADR-014 §(d) does not
  pre-reserve.** #14 owns the question *"Is a research-verification output
  whose content concerns auth/authn/authz/crypto/security-sensitive APIs
  classified at T1, expressed as an independently-checkable written
  contract — independent of the orchestrator's runtime keyword scan?"*
  §3 below shows no existing owner holds it. ADR-014 §(d)'s MECE table
  names #04/#05/#07/#08 (and §(d)'s lineage extends to #09/#10/#11,
  amended for #12 via ADR-019 §5 and for #13 via ADR-020 §2); it does
  **not** pre-reserve a slot for #14. Spec Key-interaction 6 states this
  explicitly. This is the same not-pre-reserved-slot observation ADR-019
  §5 recorded for #12 and ADR-020 §1/§2 recorded for #13 — the decisive
  distinction from #07–#11, each of which *populated a slot ADR-014 §(d)
  had already reserved* and therefore correctly took an ADR-014 amendment
  consuming no new number.
- **NEW keying / mechanism? Yes.** The keying is *"auth-keyword presence
  in a verification-review artifact's content (not its topic line) versus
  the Tier declared on that same artifact."* This is none of: ADR-015's
  path-resolution keying, ADR-017's absence-of-claim keying, ADR-018's
  convention-presence keying, ADR-019's coverage-percentage keying,
  ADR-020's intra-prompt-table-consistency keying. The defining new
  mechanism is *content-keyed Tier auditing that deliberately scans the
  artifact body, exactly to catch the topic-description-omission the
  orchestrator's topic-line scan misses* (Spec Goals, Key-interaction 3,
  R-01 (b)).
- **NEW structural artifact? Yes.** A new `check-*.sh` family member
  (`check-research-tier-auth.sh`) <!-- ref-allow: forward-reference to the implementation-session detector script named by this design ADR; it does not yet exist by design (two-session split) --> + a new forkable
  workflow + a new activation config + a new `test-check-*.sh` suite,
  plus a new prose contract subsection in `protocol.md`. None of the five
  existing detectors owns any of these.

All three discriminator clauses are satisfied — triad **3/3**. The
structural half dominates exactly as it did for ADR-015 (self-classified),
ADR-017 (Alternative B), ADR-018 (Alternative B), ADR-019 §5, and ADR-020
§1. An **ADR-008 amendment is rejected**: ADR-008's Decision (the Tier
model, the Generator-declared scope, the guardrail) is *unchanged* by #14
(Spec Non-goals AC-3/AC-4/AC-5 fix this). #14 closes a gap ADR-008's
guardrail *named at the topic level but left structurally unenforced for
content-without-the-keyword* — that is the "new detector + new boundary +
inheritable-rule" shape ADR-017/ADR-018/ADR-019/ADR-020 each self-classified
as a new ADR, **not** a consequence-clarification of ADR-008's Decision.
An **ADR-010 amendment is rejected** for the same reason: ADR-010
generalized the layer's cross-domain structure and opt-in switches; #14
neither changes that structure nor adds a domain — it adds a content-keyed
validation partition above the existing research-domain machinery.

### 2. Validation mechanism and its form — a content-keyed detector + a co-located written contract

The Spec Key-interaction 7 lists five candidate forms (a–e). The chosen
design is a **combination of (c) + (d)**, deliberately *not* (a) or (b):

- **(c) — the written contract: a new prose subsection in
  `protocol.md`, immediately under the Tier table.** Titled (exact wording
  the implementer's) so it states, as a **mandatory rule** (not guidance,
  not best-practice): *a verification-review output whose content concerns
  any item in the Tier table's existing T1 scope line — auth, authn,
  authz, crypto, security-sensitive APIs — MUST be declared T1; T2/T3 is
  non-conformant for such content regardless of how the topic line is
  worded; this obligation is independently readable here without first
  consulting `orchestrator.md`.* The subsection **references the existing
  T1 scope line by pointer ("the Tier table's T1 scope line above"),
  never reproduces it** — the single source of truth for *what* T1 covers
  stays the Tier table (R-04 resolution, see Decision 5; the same
  "reference, do not re-declare" discipline ADR-019 §3 used for the 80%
  number). This addition is a **new subsection appended below the table**;
  it does **not** edit the Tier-table row text (AC-4 preserved — verified
  by the implementer with `git diff` on the table lines) and does **not**
  edit `verification.yml` (AC-3) or `orchestrator.md` (AC-5).
- **(d) — the detector: a new default-off `check-*.sh` script** that
  audits **verification-review artifacts** (the
  `.claude/templates/verification-review-template.md`-shaped outputs the
  research domain produces — the artifact carrying the Generator's
  declared Tier and the research content) for the failure mode: **content
  matching the auth-scope keyword set while the declared Tier is T2 or
  T3.** It scans the artifact *body*, not only a topic line — that is the
  precise mechanism that catches the orchestrator-scan-misses case
  (Key-interaction 3, R-01 (b)). On a match it FAILs with a
  human-readable message naming the artifact, the matched auth term, and
  the declared Tier vs the required T1.

Forms (a) and (b) are **explicitly not chosen** and the reason is
recorded: (a) "elevate the Tier-table line itself to a machine-readable
mandatory rule" would *edit the Tier table*, violating AC-4 (Spec
Non-goals: "Changing the Tier table definition … #14 makes that scope a
testable contract, it does not re-define what T1 means"). (b) "a new
agent-prompt constraint in `docs-researcher.md`" would put the rule back
inside an agent prompt — the very "only-as-prose, only-at-runtime,
single-enforcement-point" property #14 exists to break (Spec Goals: "does
not require the orchestrator to be the sole enforcement point"; the same
objection applies to relocating the single point from orchestrator to
docs-researcher). The written contract must be **independently checkable
and not an agent instruction** (AC-1, AC-2); the detector is what makes it
*checkable* and the `protocol.md` subsection is what makes it *readable
without `orchestrator.md`*.

### 3. MECE boundary — a new partition ADR-014 §(d) does not pre-reserve

#14/ADR-021 owns the question **"Is a research-verification output whose
content concerns the Tier table's existing T1 scope (auth/authn/authz/
crypto/security-sensitive APIs) declared at T1, expressed as an
independently-checkable written contract — independent of the
orchestrator's runtime topic-keyword scan?"** This is a **new partition**,
distinct from every existing owned question:

| Owner | Owns the question | Input scanned |
|---|---|---|
| #04 `check-dangling-refs.sh` (ADR-015) | Does a prose/path reference **resolve** to a real file/ADR? | repository Markdown artifacts |
| #05 `check-roadmap-drift.sh` (ADR-017) | Does the **bidirectional Roadmap-index contract** hold and is every Status glyph well-formed? | `.claude/CLAUDE.md` + ADRs |
| #06 `check-bilingual-parity.sh` (ADR-018) | Does the **EN↔JA pair agree** structurally (heading tree, full-width parens, presence)? | paired `.md`/`.ja.md` artifacts |
| #11 (verification-domain opt-in guidance, ADR-014 §(d)) | Under what project characteristics should a fork **enable** the implementation/design verification domain? | documentation/convention (no detector) |
| #12 `coverage-gate.yml` (ADR-019) | Does the project's **test coverage** meet the 80% minimum, enforced at CI time? | the derived repo's already-computed coverage percentage |
| #13 `check-ecc-delegation-consistency.sh` (ADR-020) | Is `code-reviewer.md`'s ECC delegation table internally consistent, and is the standing degraded-review posture discoverable? | `code-reviewer.md`'s delegation table — repository-internal only |
| **#14 `check-research-tier-auth.sh` (ADR-021)** | **Is an auth-touching research-verification output declared at T1, as an independently-checkable written contract?** | **verification-review artifacts' content vs their declared Tier — repository-internal only, no external probe** |

A defect maps to exactly one owner: a *broken pointer* is #04's; a
*Roadmap-index inconsistency* is #05's; a *structurally-divergent EN/JA
pair* is #06's; a *verification-domain enablement guidance question* is
#11's documentation concern; a *coverage below threshold* is #12's; a
*delegation-table internal inconsistency* is #13's; an
*auth-touching-content-declared-below-T1 mis-classification* is #14's and
**only** #14's. The boundary is clean: #14 never resolves arbitrary
pointers, never touches the Roadmap, never touches EN/JA parity, never
checks coverage, never validates the delegation table, and — critically —
**never probes the operator environment or any external source** (AC-8;
the same constructive-impossibility boundary ADR-020 §3 drew, applied here
to research-content auditing rather than ECC presence). Spec AC-7 fixes
this as the routing answer: an auth-Tier mis-classification concern routes
to #14 or a successor, never to #04/#05/#06/#12/#13.

### 4. No operator-environment introspection / no external lookup — the AC-8 constraint

The detector reads only repository artifacts (the verification-review
outputs and `protocol.md`'s Tier-table line for the keyword scope). It
never reads `~/.claude/`, never makes a network call, never probes an
external service. The auth-scope keyword set the detector matches is
**derived from the Tier table's existing T1 scope line in `protocol.md`**
(Decision 5), not hardcoded as an independent list — so the detector's
notion of "auth-touching" is exactly the repository's already-declared T1
scope, with no external authority. This is what makes AC-8 satisfied by
construction and keeps the template's own CI deterministic.

### 5. R-04 staleness-sync — single source of truth is the Tier table; the contract and detector both reference it

Spec R-04 (and Key-interaction 1) require that the written contract and
`protocol.md`'s T1 scope line cannot silently diverge — the same "rows go
stale silently" failure ADR-012's Negative named. Resolution, fixed here:

- **The `protocol.md` subsection (Decision 2c) lives in the same file as
  the Tier table** and references the T1 scope line by pointer ("the Tier
  table's T1 scope line above"), never reproducing the scope words. A
  future amendment to the T1 scope line (e.g. adding "OAuth flows")
  changes the single source; the subsection's pointer still resolves to
  the amended line with **zero second edit**. Co-location + reference (not
  reproduction) is the structural anti-drift guarantee — the same
  discipline ADR-019 §3 used to bind the 80% threshold to a single
  canonical line.
- **The detector (Decision 2d) derives its auth-scope keyword set by
  reading the Tier-table T1 scope line out of `protocol.md` at run time**,
  not from an independent literal embedded in the script. If the
  extraction cannot find the canonical T1 scope line (e.g. a fork
  restructured the Tier table), the detector **fails closed with an
  explicit message** ("canonical T1 scope line not found in
  `protocol.md` Tier table"), never silently passes — the same
  fail-closed direction ADR-019 §3 fixed for the missing-`## Testing
  Requirements` case, so a removed contract is loud, not invisible. This
  couples the extractor to the Tier-table line shape; the coupling is
  recorded under Consequences → Negative, narrowed to the single
  canonical line, exactly as ADR-015/ADR-017/ADR-018/ADR-019 each
  recorded their single narrowest-surface coupling.

The implementer **must** verify (a test fixture) that a future
`protocol.md` T1-scope amendment is automatically tracked by both the
contract pointer and the detector's runtime-derived keyword set with no
second edit — closing R-04 by construction.

### 6. How each acceptance criterion is satisfied

- **AC-1** (auth content ⇒ T1 stated as a mandatory rule, independently
  readable without `orchestrator.md`): the `protocol.md` subsection
  (Decision 2c), worded as a mandatory rule, co-located with the Tier
  table, readable standalone.
- **AC-2** (complementary, non-duplicative with the orchestrator
  guardrail): the subsection states explicitly that it is the *written,
  independently-checkable* representation and the orchestrator block
  (cited by content anchor / corrected lines 103–109) is the *runtime
  routing* check; the detector enforces the written rule even when the
  guardrail's topic scan misses (Decision 2d).
- **AC-3** (`default_tier: T2` unchanged): Decision 2 edits neither
  `verification.yml` nor the default; the implementer verifies with
  `git diff .claude/verification.yml` (empty).
- **AC-4** (Tier-table T1 scope line unchanged): Decision 2c **appends a
  subsection below** the table; the implementer verifies the table lines
  themselves are byte-unchanged with `git diff` scoped to the Tier-table
  lines.
- **AC-5** (orchestrator guardrail prose unchanged): Decision 2 edits no
  agent prompt; the implementer verifies `git diff .claude/agents/orchestrator.md`
  (empty). The line-range correction in §Context changes only this ADR's
  *citation*, never `orchestrator.md`.
- **AC-6** (five existing detectors + suites unmodified): Decision 2 adds
  a *new* script/workflow/suite; the implementer verifies `git diff` on
  the five `check-*.sh`, `check-ecc-delegation-consistency.sh`, and their
  `test-check-*.sh` is empty.
- **AC-7** (MECE boundary, distinct owned question): Decision 3's table
  and routing statement.
- **AC-8** (no operator-environment introspection / external lookup):
  Decision 4; the detector reads only in-repo artifacts.

### 7. Implementation-session contract (deferred — two-session split)

The implementation session will, per the Spec's acceptance criteria and
this ADR's Decision: author one new default-off detector script
`check-research-tier-auth.sh` <!-- ref-allow: forward-reference to the implementation-session detector script named by this design ADR; it does not yet exist by design (two-session split) --> following the `check-*.sh` family
skeleton (`set -euo pipefail`, `git rev-parse` root resolution,
`pass`/`warn`/`fail_check` helpers, `fail=0` accumulator, `exit "$fail"`,
the line-level `<!-- ref-allow: -->` escape hatch reused unmodified, a
prominent header documenting the auth→T1 contract, the
no-external-introspection constraint, the R-04 single-source binding, and
the seven-way MECE-by-contract boundary with a pointer to this ADR); one
forkable workflow `research-tier-auth-check.yml` <!-- ref-allow: forward-reference to the implementation-session workflow named by this design ADR; it does not yet exist by design (two-session split) --> following the
`ecc-delegation-consistency-check.yml` default-off single-switch precedent
(standalone, authored **alongside** — not as a modification of —
`ci-base.yml`; `ci-base.yml` byte-unchanged; `permissions: contents: read`
least-privilege; `timeout-minutes: 5`; no `${{ inputs.* }}` ever
interpolated into a `run:` block — all dynamic values via `env:`; a single
`enabled: true` switch in one in-repository activation config, no second
`if: false` guard, no second config key, no repository variable); one
activation config artifact carrying exactly one `enabled`-style boolean;
the new prose subsection appended under the `protocol.md` Tier table
(Decision 2c, 5); and a dedicated `test-check-research-tier-auth.sh`
<!-- ref-allow: forward-reference to the implementation-session test suite named by this design ADR; it does not yet exist by design (two-session split) --> suite (fixtures: auth content at T2 FAILs naming term+Tier; auth
content at T3 FAILs; auth content at T1 passes; non-auth content at T2
passes; the switch off makes the job inert / template
green-by-construction; a missing canonical T1 scope line in `protocol.md`
fails closed; a `protocol.md` T1-scope amendment is tracked with no second
edit, closing R-04; and `verification.yml`, `orchestrator.md`, the
`protocol.md` Tier-table lines, and the five existing detectors + suites
are byte-unchanged, AC-3/AC-4/AC-5/AC-6). It will introduce **zero**
changes to the five existing detector scripts or their suites. On
implementation completion the architect transitions this ADR
Proposed → Accepted and reconciles the now-false present-tense
"deferred / will" self-narrative to past-tense (the
ADR-019/ADR-020 two-session reconciliation precedent), leaving the
Alternatives/Counter-proposal design-time rationale unchanged as
historical record.

This ADR records the decision and the downstream implications. It does
**not** itself write the script, the workflow, the activation config, the
`protocol.md` subsection, or the tests, and does **not** modify any agent
prompt, the Spec, any template, any other ADR, the CHANGELOG, or any
CI/script file — implementation is deferred to a subsequent session and
listed under Consequences → Neutral for traceability, exactly as
ADR-014/ADR-015/ADR-016/ADR-017/ADR-018/ADR-019/ADR-020 do. This continues
the #03/ADR-016 · #05/ADR-017 · #06/ADR-018 · #12/ADR-019 · #13/ADR-020
two-session decision-then-implementation split precedent and is the
deliberate **opposite** of a single-session collapse.

## Consequences

### Positive

- The auth→T1 requirement becomes an **independently-checkable written
  contract** in `protocol.md` (readable without `orchestrator.md`) **and**
  a deterministic detector — closing the Spec's headline gap: a
  topic-description-omission ("login flow", "session management") that the
  orchestrator's topic-keyword scan misses is still caught, because the
  detector scans artifact *content*.
- **The orchestrator stops being the sole enforcement point.** A second,
  independently-checkable representation of the auth→T1 rule now exists
  (Spec Goals), complementary to (not duplicative of) the runtime guardrail
  (AC-2).
- **Single source of truth preserved (R-04 closed by construction).** Both
  the contract subsection and the detector reference / runtime-derive the
  Tier table's existing T1 scope line; a future scope amendment tracks with
  zero second edit — the ADR-019 §3 "reference, do not re-declare"
  discipline applied to the T1 scope.
- **`default_tier: T2`, the Tier table, and the orchestrator guardrail are
  byte-unchanged** (AC-3/AC-4/AC-5) — #14 adds a validation layer above the
  existing machinery, exactly as the Spec Goals require.
- **Template green-by-construction** with no special case: default-off
  (Decision 7) means the job does not run against the template at all, and
  the template's own verification-review artifacts (if any) are conformant
  by construction; AC-8 forbids any external probe so there is no
  inert-detection branch.
- **The MECE partition is clean and disjoint.** #14 scans a
  *content-versus-declared-Tier* relationship in verification-review
  artifacts — an input no other detector touches; the seven-way boundary
  (Decision 3) has no overlap zone to reason about.
- **Detector-family leverage extends with no new pattern.** #14 mirrors the
  `check-*.sh` + `test-check-*.sh` + default-off-workflow shape #04
  established and #05/#06/#13 mirrored — "one pattern, N milestones"
  (ADR-015 §Decision point 3) extends once more.

### Negative

- **A seventh detector joins the family's conceptual load.** A maintainer
  must hold one more partition. Mitigation: the partition (Decision 3) is
  drawn so each owner answers exactly one question; the exemption surface
  does **not** grow (the detector has no path allowlist — its scope is the
  verification-review artifact set, its keyword set is runtime-derived from
  the Tier table, not enumerated).
- **The detector validates content-keyword presence, not semantic intent.**
  A research output that concerns auth using only synonyms outside the Tier
  table's scope words could still slip past — the detector's recall is
  exactly the Tier table's declared scope, no wider (Spec R-03 forbids
  inventing new T1 categories; AC-8 forbids an external classifier). This
  is a deliberate, Spec-bounded limitation: the contract covers the T1
  scope *as it already exists*, applied as a mandatory rule, not a broader
  semantic auth-detector. The standing written contract (Decision 2c) is
  what carries the obligation for the human/agent reader beyond the
  detector's keyword recall.
- **The detector and contract couple to the Tier-table T1 scope-line
  shape.** Decision 5 reads that line at run time. If the Tier table is
  restructured, the extractor must change with it; nothing cross-checks the
  two automatically. Mitigation: the detector **fails closed loudly** if
  the canonical line is absent (Decision 5) — the same acceptable,
  narrowed, fail-closed coupling ADR-015/ADR-017/ADR-018/ADR-019 each
  accepted, keyed to the single narrowest surface (one canonical line).
- **Default-off means an unconfigured fork enforces nothing.** A derived
  repo that never flips the switch ships with the detector inert — the
  accepted `workaround-check.yml`/`coverage-gate.yml`/
  `ecc-delegation-consistency-check.yml` property. The cost asymmetry runs
  the intended direction: an un-opted-in fork is the maintainer's explicit
  choice; the written contract in `protocol.md` (always present) still
  states the rule for any reader even when the detector is off.
- **Two-session split adds one ADR number and one cross-session handoff.**
  Mitigation: the ADR-016/017/018/019/020 lifecycle precedent makes the
  handoff a known, low-risk pattern; the Status block and Decision 7 record
  the implementation-session contract unambiguously.

### Neutral

- This is a **CI-layer + documentation addition** in the
  ADR-015/ADR-017/ADR-018/ADR-019/ADR-020 mold: no agent is added or
  removed; no agent prompt is changed (Spec AC-5 / Key-interaction 3 — the
  orchestrator guardrail prose is explicitly untouched). Agent count
  unchanged.
- This is the **third** template milestone (after #12/ADR-019 and
  #13/ADR-020) whose ADR records a not-pre-reserved-by-ADR-014-§(d) MECE
  partition stated in the ADR itself rather than as an ADR-014 §(d)
  amendment; the pattern is now thrice-applied and stable.
- The Roadmap row #14 `Design source` cell gains an `adr:` link to this
  ADR (performed by this design session per ADR-014 write-ownership:
  `architect` adds the `adr:` link, `<br>`-joined after the existing
  reserved `spec:` link, exactly as rows #03/#04/#05/#06/#12/#13 show).
  The row Status glyph is `◐ in-progress` at design time — this is a
  two-session split; the glyph flips to `☑` at implementation completion
  when the step-6 quality gate passes (the `product-manager`'s flip, not
  the architect's). No other row is touched; no Roadmap format change; the
  change is index-only (a single cell edit).
- The exact subsection wording in `protocol.md`, the detector's
  artifact-discovery glob, the auth-scope keyword-extraction awk/grep form,
  the activation config filename and YAML key name, the workflow job name,
  and the path-scoping are `implementer` details; this ADR fixes the
  *new-ADR classification*, the *mechanism form* ((c)+(d), not (a)/(b)),
  the *contract placement* (co-located under the Tier table, reference not
  reproduce), the *posture* (default-off single-switch), the *MECE
  partition*, and the *R-04 single-source binding* — not the bash. The
  same Neutral-section "constraints not bash" discipline
  ADR-015/016/017/018/019/020 used.
- The Japanese counterpart of this ADR
  (`021-research-tier-auth-validation.ja.md`) is authored by `architect`
  **in this same session** (the new-ADR JA mirror is the architect's, not
  deferred to `technical-writer`), exactly as ADR-019 and ADR-020's JA
  siblings were produced with their EN originals; heading-tree parity
  (level + position) is required and verified this session.
- Downstream `implementer` tasks are recorded in Decision 7 for
  traceability; they are **performed in the subsequent implementation
  session**, the deliberate opposite of a same-session implementation.

## Alternatives considered

| Alternative | Pros | Cons | Why not chosen |
|-------------|------|------|----------------|
| **A: ADR-008 amendment, no new ADR-021** | Fewer ADR numbers; #14's subject is ADR-008's Tier model; consistent with the "consequence-clarifications fold into amendments" precedent | The discriminator triad is **3/3**: new contract boundary not pre-reserved by ADR-014 §(d), new content-keyed mechanism, new structural artifacts (detector + workflow + config + suite + `protocol.md` subsection). ADR-008's Decision (Tier model + guardrail) is **unchanged**; #14 closes a gap ADR-008 named at topic level but left structurally unenforced for content-without-the-keyword. ADR-015/017/018/019/020 each self-classified the identical shape (new detector + new boundary + inheritable rule) as a new ADR | Rejected: the structural half dominates exactly as for ADR-017/018/019/020. ADR-008's Decision is not changed; #14 is a new partition, not a clarification of an existing Decision |
| **B: ADR-010 amendment (verification-layer generalization)** | ADR-010 owns the cross-domain verification structure #14 sits within; an amendment keeps the verification-layer decisions in one lineage | #14 neither changes ADR-010's cross-domain structure nor adds/removes a domain nor changes an opt-in switch; it adds a content-keyed validation partition *above* the research-domain machinery. No ADR-010 Decision is clarified or extended | Rejected: same reason as A — there is no ADR-010 Decision whose consequence #14 clarifies; the discriminator triad is 3/3 ⇒ new ADR |
| **C: Form (a) — elevate the `protocol.md` Tier-table line itself to a machine-readable mandatory rule** | One artifact; the rule lives exactly where T1 is defined | **Edits the Tier-table line**, violating AC-4 / Spec Non-goal ("#14 makes that scope a testable contract, it does not re-define what T1 means"); risks redefining T1 scope (Spec R-02/R-03) | Rejected: AC-4 is a hard constraint. The chosen design *appends a subsection below* the table and *references* the unchanged line — the AC-4-preserving realization of the same intent |
| **D: Form (b) — a new agent-prompt constraint in `docs-researcher.md`** | Fires at the exact point the Generator declares a Tier; no new script | Puts the rule back **inside an agent prompt** — the "only-as-prose, single-enforcement-point" property #14 exists to break (Spec Goals: must not require a single enforcement agent; relocating the single point from orchestrator to docs-researcher does not satisfy "independently checkable"); not independently checkable at a deterministic checkpoint (AC-1/AC-2) | Rejected: the Spec's whole purpose is a *second, independently-checkable* representation, not a relocated agent instruction |
| **E: Documentation/convention statement only (no detector), like #11/ADR-014-amendment single-session collapse** | Smallest change; no new script/workflow; matches #11's prose-only collapse | Leaves the topic-description-omission failure mode **entirely uncaught** — a prose paragraph cannot detect an auth-content artifact declared at T2. #14 has a **concrete, detectable failure mode** (auth content + declared T2/T3), unlike #11 which had no detectable failure mode (adoption guidance) and *populated a pre-reserved §(d) slot*. #14 is **not** pre-reserved in §(d) (Spec Key-interaction 6) | Rejected: #11 was correctly prose-only because it had no detectable failure mode and filled a reserved slot; #14 has a detectable failure mode and no reserved slot — the ADR-020 §Counter-proposal reasoning applied identically |
| **F: New ADR-021 — new default-off content-keyed detector + co-located written contract in `protocol.md`, single-source-bound to the Tier-table T1 line, new MECE partition, two-session split (chosen)** | Closes the topic-omission gap with a deterministic content-keyed signal **and** an independently-readable written contract; `verification.yml`/Tier-table/orchestrator-guardrail byte-unchanged (AC-3/4/5); template green-by-construction (AC-8); R-04 closed by single-source reference; cleanest disjoint MECE partition; reuses the #04/#05/#06/#13 detector shape; discriminator triad 3/3 ⇒ correctly a new ADR | Adds a seventh detector to the conceptual load; content-keyword recall is exactly the Tier-table scope (deliberate, Spec-bounded); couples to the Tier-table line shape (narrowed, fails closed); two-session handoff | Chosen: the only option that closes the detection gap, draws a defensible disjoint MECE boundary, keeps the auth→T1 scope single-sourced, preserves all three no-change constraints, and correctly applies the ADR-018 Alternative-B discriminator the Spec handed the architect (R-01, Key-interaction 7) |

## Counter-proposal

The serious counter-position is **Alternative E — do not add a detector;
make #14 a documentation/convention statement only (a `protocol.md`
subsection alone, no script/workflow), mirroring #11's prose-only ADR-014
amendment and single-session collapse**. It is recorded here per the
ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 / ADR-019 /
ADR-020 precedent of taking a rejected alternative seriously rather than
as a strawman. The argument, taken at full strength:

1. **The Spec lists "a documentation/convention placement" as an explicit
   R-01 option**, analogous to #11's ADR-014:1800 documentation/convention
   classification (Spec Key-interaction 4 raises exactly this analogy). A
   `protocol.md` subsection that names the auth→T1 obligation, with no
   script, already satisfies AC-1 (independently readable), AC-2
   (complementary to the guardrail), and AC-3/AC-4/AC-5 (changes nothing
   else). It is the smallest change that closes the *written-contract*
   half of the gap — no seventh detector, no new workflow, no activation
   config, zero added detector-family conceptual load (ADR-018's Negative
   warned about exactly that load).
2. **The template's primary user is a learner.** A prose obligation in the
   Tier-table's own file ("auth content is T1, always, regardless of how
   the topic is worded") may teach the lesson more directly than a
   green/red detector exit code whose semantics a learner must first
   understand. #11 deliberately chose prose-only and single-session
   collapse for an analogous "make the rule discoverable" milestone, and
   that was the correct call there.
3. **Single-session collapse + ADR-014 amendment, no new ADR number, is
   the conservative default** the recent #07–#11 run established. New ADR
   numbers carry permanent conceptual weight; not minting one when a
   subsection suffices is the cautious choice.

**Why the counter was not adopted:**

- **The analogy to #11 breaks on the decisive point — detectable failure
  mode, the exact reasoning ADR-020 §Counter-proposal recorded.** #11 had
  **no detectable failure mode** ("under what characteristics should a
  fork enable a domain?" is a judgment a detector cannot make), so prose
  was the only coherent form **and** #11 *populated a slot ADR-014 §(d)
  had already reserved*. #14 has a **concrete, detectable failure mode**:
  a verification-review artifact whose content concerns auth while its
  declared Tier is T2/T3 — exactly the silent-mis-classification the Spec
  §Problem names. A prose subsection cannot catch that drift; only a
  static check can. And #14 is **not** pre-reserved in ADR-014 §(d) (Spec
  Key-interaction 6) — so even the amendment-vehicle half of the #11
  analogy fails. The discriminator triad is 3/3; the structural half
  dominates exactly as ADR-017/018/019/020 each recorded.
- **Prose-only restates a rule that already half-exists; it does not
  close the *detection* gap.** The Tier table *already* descriptively
  names "auth" in T1 scope; adding a subsection that says "and this is
  mandatory" improves *readability* (the contract half, AC-1) but a
  reader/agent still has no deterministic checkpoint that catches an
  artifact that declared T2 anyway. The Spec §Problem is explicit that
  the gap is precisely the *absence of an independently-checkable
  enforcement separate from orchestrator runtime judgement* — prose alone
  reproduces the "only-as-prose" state #14 exists to break. This is the
  same "a second prose statement does not close the detection gap"
  conclusion ADR-020 reached against its own Alternative C.
- **The counter's points 2 and 3 are real costs already accepted by the
  family.** A seventh detector's conceptual load and one more ADR number
  are the costs ADR-015/017/018/019/020 each accepted *every time the
  detector-family pattern was extended for a milestone with a detectable
  failure mode*. #14 is such a milestone; #11 was not. The
  discoverability/learner half the counter correctly values **is**
  honored — the chosen design *includes* the `protocol.md` subsection
  (Decision 2c); the counter is right that prose belongs in the solution,
  wrong that prose is the *whole* solution. This is the precise position
  ADR-020 §Counter-proposal took ("prose belongs in the solution; it is
  not the whole solution").
- **Single-session collapse is wrong on implementation weight.** The
  chosen design ships a new detector script, a forkable default-off
  workflow, an activation config, a new `test-check-*.sh` suite, **and** a
  `protocol.md` subsection — the #12/#13 heavy-implementation profile, not
  #11's prose-only profile. The two-session split (design ADR Proposed
  now; implementation + Accepted later) is the ADR-016/017/018/019/020
  lifecycle for exactly this weight, and is the deliberate opposite of the
  #11 collapse the counter proposes.

**Trigger conditions for re-evaluating this counter-proposal:**

- ADR-014's §(d) MECE table is restructured to **pre-reserve a
  research-Tier-validation slot**. At that point #14 would be *populating
  a pre-reserved slot*, and an ADR-014 amendment + single-session collapse
  — not a standalone ADR-021 — would become correct under the very
  discriminator this ADR applies (the exact ADR-019 §Counter-proposal
  re-evaluation trigger, applied here).
- The verification-review artifact format is removed or the research
  domain is retired entirely (e.g. the layer drops Generator-declared
  Tiers). The detector's subject matter then vanishes and the
  subject-matter-presence rule retires or reclassifies the detector — at
  which point this whole ADR is re-evaluated, not just the counter.
- `check-research-tier-auth.sh` <!-- ref-allow: forward-reference to the implementation-session detector script named by this design ADR; it does not yet exist by design (two-session split) --> and the existing
  `check-*.sh` detectors prove to share so much parsing code (Tier-table
  walking, fence tracking, escape-hatch handling) that a **shared parsing
  library** sourced by all of them — not a merged script — becomes the
  right refactor, preserving the seven-way contract partition while
  removing duplication (the same shared-library re-evaluation trigger
  ADR-017/ADR-018/ADR-019 recorded for the detector family).

The counter-proposal stays in this ADR as the historical record of the
decision's most serious objection, per the
ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 / ADR-019 /
ADR-020 convention. No alternative ADR file is created — the rejected
counter's correct state is non-existence; this ADR-021 file is its only
citable home.

## References

- ADR-008 (research verification layer) — establishes the Tier model, the
  Generator-declared scope, the T1-for-auth scope line ("auth,
  security-sensitive APIs, crypto primitives"), and the Tier-confirmation
  guardrail this milestone's written contract makes independently
  checkable; **not** the ADR this milestone amends (Decision 1 records why
  a new ADR, not an ADR-008 amendment, is correct — ADR-008's Decision is
  unchanged)
- ADR-010 (verification-layer generalization) — establishes the
  cross-domain structure and per-domain opt-in switches; cited in the Spec
  as a candidate amendment target and rejected (Alternative B): #14 changes
  no ADR-010 Decision
- ADR-014 (Roadmap index as single entry point) — its §(d) MECE
  boundary-statement table names #04/#05/#07/#08 (lineage extends to
  #09/#10/#11, amended for #12 via ADR-019 §5 and #13 via ADR-020 §2) and
  does **not** pre-reserve a slot for #14; that absence is the decisive
  distinction making #14 a new partition (new ADR) rather than the
  population of a pre-reserved slot (#11's amendment case); this ADR
  follows ADR-014's "record the decision + downstream tasks, do not
  perform them" shape and its write-ownership model (`architect` adds the
  row's `adr:` link)
- ADR-018 (bilingual parity detector) — its Alternatives table row B is
  the **verbatim Alternative-B discriminator** (NEW detector + NEW MECE
  boundary + NEW keying ⇒ new ADR; consequence-clarification/extension ⇒
  amendment) this ADR applies clause by clause in Decision 1; the house
  style (Status / Context / Decision[numbered] /
  Consequences[Positive/Negative/Neutral] / Alternatives /
  Counter-proposal[with trigger conditions] / References) this ADR mirrors
- ADR-019 (CI coverage gate) — the two-session-split +
  not-pre-reserved-by-ADR-014-§(d) + default-off-single-switch +
  reference-don't-redeclare-the-single-source precedent this ADR mirrors
  (Decision 2c/5 apply ADR-019 §3's "read the rule from the artifact"
  discipline to the T1 scope line); the new-ADR JA-mirror-in-same-session
  precedent
- ADR-020 (ECC-absent degraded-review signal) — the most recently
  consumed ADR number (021 is the next unused); the immediately-preceding
  two-session-split + new-default-off-detector +
  no-operator-environment-introspection + Counter-proposal-prose-is-not-
  the-whole-solution precedent this ADR mirrors clause for clause
- ADR-012 (Code Reviewer as Dispatcher) — precedent for recording a
  counter-proposal with real pros and explicit re-evaluation triggers; its
  Negative "rows go stale silently" is the R-04 staleness failure
  Decision 5 closes by single-source reference
- ADR-016 (Cross-session progress persistence) — the #03 precedent for
  the two-session decision-then-implementation split this ADR follows
- `specs/14-research-tier-validation.md` — the authoritative scope (AC-1
  through AC-8, R-01 through R-04, the seven Key interactions, the
  Non-goals); its R-01 hands this decision to the architect and names it
  ADR-021; this ADR records the structural *how/why* the Spec defers; the
  Spec owns the *what*
- `.claude/skills/verification-layer/research/protocol.md` — the Tier
  table (lines 49–53) whose T1 scope line is the single source of truth
  Decision 5 binds the contract and detector to; the file the new written
  subsection (Decision 2c) is appended to, below the table, without
  editing the table line (AC-4)
- `.claude/verification.yml` (lines 34–38) — the `default_tier: T2`
  declaration this milestone leaves byte-unchanged (AC-3)
- `.claude/agents/orchestrator.md` — the `**Tier-confirmation
  guardrail**:` block (verified **lines 103–109**, *not* the Spec's
  "104–109"; cite by content anchor for robustness) this milestone's
  written contract complements without replacing and leaves byte-unchanged
  (AC-5)
- `.claude/meta/scripts/check-ecc-delegation-consistency.sh` /
  `.github/workflows/ecc-delegation-consistency-check.yml` — the #13
  structural sibling: the `check-*.sh` + `test-check-*.sh` +
  default-off-single-switch forkable-workflow shape this milestone's
  downstream tasks mirror
- Roadmap row: #14
- The Japanese counterpart (`021-research-tier-auth-validation.ja.md`) is
  authored by `architect` in this same session (the new-ADR JA mirror is
  the architect's responsibility, not deferred to `technical-writer`),
  with required heading-tree parity (level + position)
