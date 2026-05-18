# ADR-020: ECC-absent degraded-review signal — a new default-off detector validating `code-reviewer.md`'s ECC delegation-table internal consistency, no operator-environment introspection, new MECE partition not pre-reserved by ADR-014 §(d)

## Status

Proposed — 2026-05-18

## Context

ADR-012 made `.claude/agents/code-reviewer.md` a meta-reviewer that
delegates language-specific depth to ECC's `*-reviewer` agents via a
nine-row `manifest → ECC reviewer` delegation table. ADR-012's Negative
section explicitly recorded two costs it left **unmitigated**: (1)
"Forks that never install ECC permanently operate at reduced review
quality" and (2) "The contract with ECC reviewers is **unversioned**.
If ECC renames `typescript-reviewer` or substantially changes its
prompt contract, the dispatcher's delegation rows go stale silently.
**There is no CI check on the existence of the target agents**."

Today the only ECC-absent / degraded-review signals are the per-review
verdict-line note inside `code-reviewer.md` (the three-case delegation
rule, lines 66–87, which fires only when a review actually runs) and
one static prose paragraph in `README.md` `## Prerequisites` (read by
humans browsing the README, not surfaced at any agent or CI checkpoint).
The *standing* degraded-review posture and the *internal consistency*
of the delegation table are not observable at any deterministic,
non-review-time checkpoint.

`specs/13-ecc-absent-signal.md` is the authoritative scope — its eight
acceptance criteria, three risks, and Non-goals. This ADR records the
**structural** decisions the Spec explicitly defers to `architect`
(Spec Risk R-01 (a)–(d), Key-interaction 6): the signal mechanism, its
placement, the no-operator-environment-introspection contract, the
template-CI-green-for-expected-absence contract, the MECE boundary, and
the new-ADR-vs-ADR-012-amendment decision. The Spec names this decision
ADR-020 and hands the ADR-018 Alternative-B discriminator to the
architect verbatim; this ADR closes it.

This milestone is **not** a sixth member of an undifferentiated detector
pile. #04 (`check-dangling-refs.sh`, ADR-015) owns cross-reference
*resolution*. #05 (`check-roadmap-drift.sh`, ADR-017) owns Roadmap
*index consistency*. #06 (`check-bilingual-parity.sh`, ADR-018) owns
EN↔JA structural parity. #12 (`coverage-gate.yml`, ADR-019) owns the
*coverage-threshold* question. None of them owns the question "is
`code-reviewer.md`'s ECC delegation table internally consistent, and is
the standing degraded-review posture discoverable without first running
a review?" ADR-014 §(d)'s MECE table names #04/#05/#09/#10/#11 (amended
for #12 via ADR-019's reasoning) and does **not** pre-reserve a slot
for #13 — the same substantive distinction ADR-019 §5 drew for #12.

This is a **two-session split** (the ADR-016/017/018/019 lifecycle
precedent for heavy-implementation milestones): this session ships the
design (ADR-020 Proposed, Spec Approved) as a `docs(adr-020):` commit;
the implementation (the detector script, its workflow, and its test
suite) is deferred to a subsequent session as a `feat(roadmap):`
commit. Implementation has not been performed; the Status is Proposed.
The contrasting precedent is #11 (ADR-014 amendment, prose-only,
single-session collapse); #13's structural weight matches #12, not #11.

## Decision

Resolve #13 as a **new ADR-020** (not an ADR-012 amendment) and ship,
in the implementation session, a **new default-off detector script plus
a forkable workflow** that validates `code-reviewer.md`'s ECC
delegation-table internal consistency, with **zero operator-environment
introspection** and a **standing posture statement co-located with the
artifact the relevant checkpoint already consults**. Concretely:

### 1. New-ADR-vs-ADR-012-amendment — the ADR-018 Alternative-B discriminator, applied clause by clause

The Spec's R-01 (b) hands `architect` the explicit choice "a new
ADR-020 or an ADR-012 amendment" and instructs the architect to apply
ADR-018's Alternative-B discriminator verbatim: *does #13 introduce a
NEW detector + a NEW MECE contract boundary + a NEW keying/mechanism
(⇒ new ADR), or is it a consequence-clarification / extension of an
existing ADR's already-sanctioned Decision (⇒ amendment)?* Applied
honestly, clause by clause:

- **New detector? Yes.** The highest-value realization of #13 is a new
  static-analysis script plus a forkable workflow that checks the
  delegation table's internal consistency at a deterministic
  non-review-time checkpoint. ADR-017 and ADR-018 each self-classified
  as new-ADR-worthy *because* each introduced a new script + new
  workflow (`check-roadmap-drift.sh` / `check-bilingual-parity.sh`);
  ADR-019 did the same for `coverage-gate.yml`. #13 introduces one new
  script and one new workflow. The structural half that dominated for
  ADR-017/ADR-018/ADR-019 is present here.
- **New MECE contract boundary? Yes — a new partition ADR-014 §(d)
  does not pre-reserve.** #13 owns the question "is `code-reviewer.md`'s
  ECC delegation table internally consistent, and is the standing
  degraded-review posture discoverable?" — a question §2 below shows no
  existing owner holds. ADR-014 §(d)'s table names #04/#05/#09/#10/#11
  (amended for #12); it does not pre-reserve #13. This is the same
  not-pre-reserved-slot observation ADR-019 §5 recorded for #12, and it
  is a substantive distinction, not a formality: a new partition is the
  ADR-017/ADR-018/ADR-019 trigger.
- **New keying / mechanism? Yes.** The keying is "cross-reference
  consistency *within an agent prompt* — the delegation-table rows'
  ECC-agent names against `code-reviewer.md`'s own dispatcher contract
  — verified without reading anything outside the repository." This is
  none of: ADR-015's path-resolution keying, ADR-017's
  absence-of-claim keying, ADR-018's convention-presence keying,
  ADR-019's coverage-percentage keying. The no-operator-environment-
  introspection constraint (Spec AC-5; `code-reviewer.md` lines 84–87
  forbid the unreliable runtime introspection the naive reading would
  require) is the defining new mechanism: #13 checks *internal
  consistency and standing posture*, never *live ECC presence*.

All three clauses are satisfied. The structural half dominates exactly
as it did for ADR-017/ADR-018/ADR-019. An ADR-012 amendment is
**rejected**: ADR-012's Decision (dispatcher refactor + three-case
rule) is *unchanged* by #13 (Spec Non-goals fix this). #13 closes a
cost ADR-012 *recorded but deliberately left unmitigated* — that is
the ADR-017/ADR-018 "new detector + new boundary + inheritable rule"
shape, which both self-classified as a new ADR rather than an
amendment, not a consequence-clarification of an existing Decision.

### 2. MECE boundary — a new partition ADR-014 §(d) does not pre-reserve

#13/ADR-020 owns the question **"Is `code-reviewer.md`'s ECC
delegation table internally consistent, and is the standing
degraded-review posture discoverable without first running a review?"**
This is a **new partition**, distinct from every existing owned
question:

| Owner | Owns the question | Input scanned |
|---|---|---|
| #04 `check-dangling-refs.sh` (ADR-015) | Does a prose/path reference **resolve** to a real file/ADR? | repository Markdown artifacts |
| #05 `check-roadmap-drift.sh` (ADR-017) | Does the **bidirectional Roadmap-index contract** hold and is every Status glyph well-formed? | `.claude/CLAUDE.md` + ADRs |
| #06 `check-bilingual-parity.sh` (ADR-018) | Does the **EN↔JA pair agree** structurally (heading tree, full-width parens, presence)? | paired `.md`/`.ja.md` artifacts |
| #11 (verification-domain opt-in guidance, ADR-014 §(d)) | Under what project characteristics should a fork **enable** the implementation/design verification domain? | documentation/convention (no detector) |
| #12 `coverage-gate.yml` (ADR-019) | Does the project's **test coverage** meet the 80% minimum, enforced at CI time? | the derived repo's already-computed coverage percentage |
| **#13 `<the #13 detector>` (ADR-020)** | **Is `code-reviewer.md`'s ECC delegation table internally consistent, and is the standing degraded-review posture discoverable?** | **`code-reviewer.md`'s delegation table — repository-internal only, no operator-environment probe** |

A defect maps to exactly one owner: a *broken pointer* is #04's; a
*Roadmap-index inconsistency* is #05's; a *structurally-divergent
EN/JA pair* is #06's; a *verification-domain enablement guidance
question* is #11's documentation concern; a *coverage below threshold
at CI time* is #12's; a *delegation-table internal inconsistency or an
undiscoverable degraded-review posture* is #13's and **only** #13's.
The boundary is clean: #13 never scans for coverage, never resolves
arbitrary pointers (it validates one specific table's internal
consistency), never touches EN/JA parity, and — critically — never
probes the operator environment for ECC presence (that is impossible
from a repository/CI by construction and is the boundary against the
per-review runtime signal `code-reviewer.md` lines 66–87 already owns).

### 3. No operator-environment introspection — the defining constraint

The signal validates *internal consistency* and states *standing
posture*. It must never attempt to detect whether ECC is installed in
the operator's `~/.claude/` — that detection is impossible reliably
from a repository and from CI by construction, and `code-reviewer.md`
lines 84–87 explicitly forbid the unreliable runtime introspection it
would require ("The agent does not introspect the filesystem … Pick
case 3 by default when in doubt"). The detector reads only repository
artifacts (primarily `code-reviewer.md`). This is what makes the
template's own CI stay green for the expected, normal ECC-absent
in-repository condition (Spec AC-3): the detector is not asking "is ECC
here?" (always "no" in-repo), it is asking "is the delegation table
self-consistent?" (a question with a stable, repository-local answer).

### 4. Template-CI-green for the expected ECC-absent case

Because §3 makes the detector a repository-internal consistency check,
it passes on the template's own `main` with no special-casing: the
delegation table is consistent in the template, so the detector is
green; ECC's in-repo absence is irrelevant to what the detector
measures. This is the #12/ADR-019 precedent (a gate that does not
fail the template's own CI for the expected condition) applied to a
consistency detector rather than a coverage gate.

### 5. Standing-posture placement — co-located, no new always-read file

The standing degraded-review posture statement is co-located with the
artifact the relevant checkpoint already consults (the detector's own
output and/or `code-reviewer.md` / `README.md` `## Prerequisites`,
exact wording an implementation detail), so a fork maintainer or agent
encounters it without a new always-read file or a third lookup beyond
what that checkpoint already mandates (Spec AC-7). It complements — it
does not restate — the per-review three-case rule (Spec AC-2,
Key-interaction 1).

### 6. Implementation-session contract (deferred)

The implementation session must, per the Spec's acceptance criteria
and this ADR's Decision: author one new default-off detector script
(the `check-*.sh` family shape #04 established, #05/#06 mirrored) plus
one forkable workflow; add a dedicated test suite mirroring the
`test-check-*.sh` precedent (making the separated-run suite count five);
introduce **zero** changes to the four existing detector scripts or
their test suites (Spec Non-goals); leave `code-reviewer.md`'s
three-case rule and "pick case 3 by default" posture byte-unchanged
(Spec AC-6); and keep the detector's mechanism free of any read outside
the repository (Spec AC-5, §3 above). On implementation completion the
architect transitions this ADR Proposed → Accepted and reconciles any
now-false present-tense "not yet implemented" self-narrative to
past-tense (the ADR-017/ADR-019 two-session reconciliation precedent),
leaving the Alternatives/Counter-proposal design-time rationale
unchanged as historical record.

## Consequences

### Positive

- ADR-012's recorded-but-unmitigated "no CI check on the existence of
  the target agents" / "delegation rows go stale silently" cost is
  closed by a deterministic, non-review-time signal — the precise gap
  ADR-012's Negative named and left open.
- The degraded-review posture becomes discoverable at the checkpoint
  where it is actionable (adoption / CI), not only buried in a
  post-review verdict line or a README paragraph no agent reads.
- The detector family's "one pattern, N milestones" leverage (ADR-015
  §Decision point 3, completed through #06, reused by #12) extends once
  more with no new pattern: #13 mirrors the `check-*.sh` +
  `test-check-*.sh` shape.
- The MECE partition stays clean and unambiguous: a future milestone
  author routing scope has a sixth, sharply-bounded owner to map
  against.

### Negative

- A sixth detector joins the family's conceptual load. Mitigation: the
  partition (§2) is drawn so each owner answers exactly one question;
  the exemption surface does not grow (the detector has no allowlist —
  it checks one table's internal consistency).
- The detector validates *internal consistency*, not *real ECC
  presence*. A fork that has a perfectly consistent delegation table
  but no ECC installed still gets a green detector — the standing
  posture statement (§5), not the detector's exit code, is what tells
  that fork it is degraded. This is a deliberate boundary (§3): live
  presence is undetectable by construction; conflating the two would
  reproduce the unreliable introspection `code-reviewer.md` forbids.
- Two-session split adds one ADR number and one cross-session handoff.
  Mitigation: the ADR-016/017/018/019 lifecycle precedent makes the
  handoff a known, low-risk pattern; the Status block and §6 record
  the contract for the implementation session unambiguously.

### Neutral

- `code-reviewer.md`'s three-case rule and ADR-012's Decision are
  untouched; capability is added beside them, nothing is reorganized.
- This is the second template milestone (after #12/ADR-019) whose ADR
  records a not-pre-reserved-by-ADR-014-§(d) MECE partition; the
  pattern of stating the partition in the ADR itself (rather than
  amending ADR-014 §(d)) is now twice-applied and stable.
- Implementation is deferred; no script, workflow, or test suite exists
  yet. The Status is Proposed and will move to Accepted in the
  implementation session.

## Alternatives considered

| Alternative | Pros | Cons | Why not chosen |
|-------------|------|------|----------------|
| **A: ADR-012 amendment, no new ADR-020** | Fewer ADR numbers; #13 is downstream of ADR-012's dispatcher decision; consistent with the "consequence-clarifications fold into amendments" precedent | #13 introduces a new detector, a new MECE partition ADR-014 §(d) does not pre-reserve, and a new keying (intra-prompt consistency, no operator introspection) — the "new structural decision" half of the ECC precedent. ADR-017/ADR-018/ADR-019 all self-classified the directly analogous case (new detector + new boundary + inheritable rule) as a new ADR | Rejected: the structural half dominates exactly as for ADR-017/ADR-018/ADR-019. ADR-012's Decision is unchanged; #13 closes a recorded-but-unmitigated Negative, which is the new-detector shape, not a Decision clarification |
| **B: Detect real ECC presence (probe `~/.claude/` or the agent registry at CI time)** | Would directly answer "is this fork degraded right now?" | Impossible reliably from a repository / CI by construction (ECC is user-level, outside the repo; CI has no operator `~/.claude/`); reproduces the unreliable runtime introspection `code-reviewer.md` lines 84–87 explicitly forbid; would make the template's own CI perpetually "fail" for the normal expected condition | Rejected: the Spec's R-03 and AC-5 forbid operator-environment introspection precisely because it is unreliable and unbounded. The defensible signal is intra-repository consistency + standing posture, not a live presence probe |
| **C: Documentation/convention statement only (no detector), like #11/ADR-014-amendment** | Smallest change; no new script/workflow; matches #11's prose-only collapse | Leaves the "delegation rows go stale silently" failure mode entirely uncaught — a prose paragraph cannot detect a drifted table row. ADR-012 already has a prose statement (README `## Prerequisites`); adding another prose statement does not close the *detection* gap ADR-012's Negative named | Rejected: #11 was correctly prose-only because it had no detectable failure mode (it was adoption guidance). #13 has a concrete detectable failure mode (a drifted delegation-table row); the prose-only option does not close the gap the milestone exists to close |
| **D: New ADR-020 — new default-off detector validating delegation-table internal consistency, no operator-environment introspection, standing posture co-located, new MECE partition stated in this ADR, two-session split (chosen)** | Closes the recorded ADR-012 gap with a deterministic non-review-time signal; keying is intra-prompt-consistency not a live probe (the only constructively-possible defensible mechanism); reuses the #04/#05/#06/#12 detector shape; MECE partition unambiguous; CI stays green for the expected in-repo absence; three-case rule untouched | Adds a sixth detector to the conceptual load; validates consistency not live presence (a deliberate, constructively-necessary boundary); two-session split adds a cross-session handoff | Chosen: the only option that closes the detection gap ADR-012's Negative named, draws a defensible MECE boundary, keys on a constructively-possible mechanism (intra-repository consistency, not an impossible live probe), and correctly classifies via the ADR-018 Alternative-B discriminator as a new ADR like ADR-017/ADR-018/ADR-019 |

## Counter-proposal

The serious counter-position is **Alternative C — do not add a detector;
make #13 a documentation/convention statement only, mirroring #11's
prose-only ADR-014 amendment**. It is recorded here per the
ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 / ADR-019
precedent of taking a rejected alternative seriously rather than as a
strawman. The argument:

1. #13's own Spec lists "a documentation/convention statement" as an
   explicit option in R-01. ADR-012 already states the degraded posture
   in `README.md` `## Prerequisites`; the cheapest reading of #13 is
   "make that statement more discoverable" — pure prose, no new script,
   no new workflow, no sixth detector to maintain. This is exactly the
   shape #11 took (ADR-014 amendment, no new ADR number), and #11 was
   the correct call for adoption guidance.
2. The detector-family conceptual load is real. ADR-018's own Negative
   warned "a maintainer must hold N exemption concepts across the
   detectors." A sixth detector adds to that load. A prose statement
   adds zero detectors.
3. The template's primary user is a learner. A prose statement that
   says "your review is degraded without ECC; here is why and what to
   do" may teach the lesson more directly than a green/red detector
   exit code whose semantics ("internal consistency, not live
   presence") a learner must first understand.

This counter-proposal is **not adopted** because the analogy to #11
breaks on one decisive point: #11 had **no detectable failure mode** —
"under what characteristics should a fork enable a domain?" is a
judgment a detector cannot make, so prose was the only coherent form.
#13 has a **concrete, detectable failure mode**: a delegation-table row
whose ECC-agent name has drifted out of consistency with
`code-reviewer.md`'s own contract — exactly the "rows go stale
silently" failure ADR-012's Negative named. A prose paragraph cannot
catch a drifted row; only a static check can. ADR-012 *already* has the
prose statement (README `## Prerequisites`); adding a second prose
statement does not close the *detection* gap — it restates the
already-stated. The counter-proposal's points 2 and 3 are real costs,
but they are the costs ADR-015/ADR-017/ADR-018/ADR-019 already accepted
each time the detector-family pattern was extended for a milestone with
a detectable failure mode; #13 is such a milestone and #11 was not. The
posture half of #13 (discoverability) *is* handled by a co-located
statement (§5) — the counter-proposal is right that prose belongs in
the solution; it is wrong that prose is the *whole* solution.

## References

- ADR-012 (Code Reviewer as Dispatcher) — its Negative section records
  the unmitigated "no CI check on the existence of the target agents"
  and "delegation rows go stale silently" costs this ADR closes; its
  Counter-proposal (Alternative B, vendor reviewers locally) is the
  deliberately-rejected option #13 does not revisit. ADR-012's Decision
  is unchanged by #13
- ADR-014 (Roadmap index as single entry point) — §(d)'s MECE table
  names #04/#05/#09/#10/#11 (amended for #12 via ADR-019) and does not
  pre-reserve a slot for #13; this ADR states the new partition itself,
  the twice-applied #12/ADR-019 precedent
- ADR-015 (dangling-reference detector) — the `check-*.sh` +
  `test-check-*.sh` detector-family shape #13 reuses; precedent for
  classifying "new detector + new boundary + inheritable rule" as a new
  ADR
- ADR-017 (Roadmap drift detector) — self-classified as new-ADR-worthy
  on the new-detector + new-boundary discriminator #13 applies
- ADR-018 (bilingual parity detector) — its Alternative-B discriminator
  (NEW detector + NEW MECE boundary + NEW keying ⇒ new ADR;
  consequence-clarification/extension ⇒ amendment) is the verbatim
  instrument this ADR applies clause by clause in §1
- ADR-019 (CI coverage gate) — the immediately-preceding two-session
  split + not-pre-reserved-by-ADR-014-§(d) precedent this ADR mirrors;
  most recent consumed ADR number before ADR-020
- `specs/13-ecc-absent-signal.md` — the authoritative scope (eight
  acceptance criteria, three risks, Non-goals); its R-01 hands this
  decision to the architect and names it ADR-020
- `.claude/agents/code-reviewer.md` lines 66–87 (three-case delegation
  rule) and lines 84–87 (no-introspection posture) — the per-review
  runtime signal #13's standing signal complements without restating;
  the artifact the #13 detector validates for internal consistency
- `README.md` `## Prerequisites` — the existing static prose statement
  of the degraded posture, not surfaced at any agent/CI checkpoint
- Roadmap row: #13
