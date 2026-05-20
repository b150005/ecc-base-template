# ADR-022: CI exemption allowlist expiry/review mechanism — extended ref-allow syntax with optional expires:YYYY-MM-DD clause, WARN-not-FAIL on expiry, permanent grandfather of no-expiry form, new structural partition in the 5-detector ref-allow family

## Status

Accepted — 2026-05-20

## Context

Five detector scripts in the template share a single exemption mechanism:
`check-bilingual-parity.sh` (ADR-018), `check-dangling-refs.sh` (ADR-015),
`check-ecc-delegation-consistency.sh` (ADR-020), `check-roadmap-drift.sh`
(ADR-017), and `check-research-tier-auth.sh` (ADR-021) each grep the
same `<!-- ref-allow: <reason> -->` HTML-comment marker to suppress a
finding that would otherwise be a false positive (a pre-reserved Spec
path, a planned artifact not yet on disk, a deliberate convention
divergence, etc.). The marker's syntax is **reason-only** and carries
**no expiry**: once a ref-allow lands, it stays in the repository until
a human notices and removes it.

This has produced two observed costs. First, ad-hoc adjudication: in
both Roadmap #16 (ADR-001 status resolution) and Roadmap #17
(CHANGELOG↔ADR-acceptance sync), individual ref-allow markers had to be
re-examined by hand once the underlying artifact came into existence,
because the marker itself carried no signal about *when* the suppression
should be re-validated. Second, no-expiry over-suppression: a ref-allow
placed pre-creation for a planned artifact remains in force after the
artifact exists, silently masking any subsequent inconsistency the
detector would otherwise catch. The detector family's "one pattern, N
milestones" leverage (ADR-015 §Decision point 3) makes both costs
uniform across all five detectors.

`specs/18-ci-exemption-allowlist-expiry.md` is the authoritative scope —
its thirteen acceptance criteria (AC-1 through AC-13), three risks, and
Non-goals. The Spec deliberately separates this work from four
adjacent exemption mechanisms: the skill-invariants grandfather clause,
ADR-017's absence-of-claim carve-out, ADR-014's Spec-reservation-rule
carve-out, and the workaround-tracker's `expires_on` field. Each of
those four is keyed to its own artifact and lives in its own domain;
this ADR addresses **only** the 5-detector ref-allow family.

This ADR records the structural decisions the Spec defers to
`architect`: the new syntax shape, the grandfather rule for the
existing form, the WARN-not-FAIL signal level on expiry, the
implementation-scope delegation to `implementer`, the review-cadence
ownership distribution, and the new-ADR-vs-ADR-015-amendment decision
itself. The triad discriminator (new contract boundary + new keying +
new structural artifact) fires 3/3 — see Decision §1 below.

## Decision

Introduce an **optional `expires: YYYY-MM-DD` clause** to the ref-allow
syntax used by all five detectors, keep the existing reason-only form
as a **permanent grandfather**, surface expiry events at **WARN
severity (never FAIL)**, and delegate the implementation-scope choice
(shared library vs. per-detector amendment) to `implementer`.
Concretely:

### 1. New-ADR-vs-ADR-015-amendment — the ADR-018 Alternative-B discriminator, applied clause by clause

The Spec hands `architect` the explicit choice "new ADR-022 or
ADR-015 amendment" and instructs the architect to apply ADR-018's
Alternative-B discriminator: *does #18 introduce a NEW contract
boundary + a NEW keying/mechanism + a NEW structural artifact (⇒ new
ADR), or is it a consequence-clarification / extension of an existing
ADR's already-sanctioned Decision (⇒ amendment)?* Applied honestly,
clause by clause:

- **New contract boundary? Yes.** ADR-015's Decision establishes the
  ref-allow marker for the dangling-refs detector and sanctions its
  reuse by sibling detectors as they were authored (ADR-017, ADR-018,
  ADR-020, ADR-021 each adopted the same syntax). ADR-015's contract
  is "ref-allow is a *static* suppression keyed to a reason string."
  This ADR introduces a *temporal* dimension absent from that
  contract: a suppression that carries a self-expiring lifecycle.
  ADR-015's amendment notes (path allowlist as anti-pattern; grace
  period for syntax changes) operate inside the static-suppression
  contract; an expiring suppression is not inside it. The boundary is
  new.
- **New keying / mechanism? Yes.** ADR-015 keys on `<reason>`;
  ADR-017 keys on absence-of-claim within a Roadmap row; ADR-018 keys
  on convention presence in EN/JA pairs; ADR-020 keys on intra-prompt
  consistency; ADR-021 keys on Tier-presence in research evidence
  trails. This ADR keys on **(reason, expiry-date) pair with the
  expiry-date optional and absent in the grandfather form** — a
  temporal/structural composite none of the five existing keyings
  carry. The workaround-tracker's `expires_on` field (ADR-006) is the
  closest precedent, but it is artifact-self-keyed (one workaround,
  one expiry), per-workaround YAML metadata, and lives outside the
  ref-allow family entirely; this ADR's keying is in-line HTML-comment
  syntax read by five greps. The mechanism shape differs even where
  the temporal idea is analogous.
- **New structural artifact? Yes.** This ADR introduces a new syntax
  partition inside the ref-allow family: two co-existing forms (the
  grandfather no-expiry form and the new optional-expires form) with a
  documented WARN-not-FAIL escalation contract on expiry. The
  partition is **MECE within the ref-allow family** — no marker is
  both forms simultaneously; every marker is unambiguously one or the
  other; the WARN behavior fires only for the new form past its date.
  This is a new structural addition, not a consequence-clarification
  of ADR-015's existing syntax.

All three clauses fire. The triad discriminator (3/3) matches
ADR-017/ADR-018/ADR-019/ADR-020/ADR-021 exactly: every prior milestone
that introduced a new structural shape on top of the detector family
classified itself as new-ADR-worthy via this same instrument. An
ADR-015 amendment is **rejected**: ADR-015's Decision (a single
detector + the ref-allow syntax as a reason-only marker) is *unchanged*
by this ADR — the grandfather rule guarantees byte-compatibility of
every existing marker. This ADR adds a new optional shape beside the
existing one; that is the ADR-017/ADR-020/ADR-021 "new boundary + new
keying + new artifact" shape, not a refinement of an existing Decision.

### 2. The extended syntax — explicit and minimal

The grandfather form (unchanged):

```
<!-- ref-allow: <reason> -->
```

The new optional-expires form:

```
<!-- ref-allow: <reason> | expires: YYYY-MM-DD -->
```

The pipe character `|` is the delimiter between the reason clause and
the expires clause. The date format is strict ISO 8601
`YYYY-MM-DD` (zero-padded month and day, no timezone — the comparison
is calendar-date against the CI run's `date +%F`, evaluated at UTC for
determinism). Whitespace around the pipe is tolerated. The reason
clause comes first; the expires clause comes second; no other clauses
are introduced by this ADR (Spec Non-goals fixes the surface). The
new form is **opt-in per marker**: a new ref-allow can be authored in
either form. The grandfather form is **never deprecated** — no
sunset date is set, no warning is emitted for the no-expiry form, and
no tooling will rewrite old markers (Spec AC-3, AC-7).

### 3. WARN-not-FAIL on expiry — the grace-period philosophy applied

When a detector encounters a ref-allow whose `expires:` date is in the
past (relative to the CI run's UTC calendar date), it emits a WARN-level
diagnostic naming the file, line, reason, and expiry date, and then
**proceeds as if the marker were still active** for the current run.
The marker's suppression is *not* withdrawn on expiry — the finding
that the marker covered does not suddenly become a CI failure. Only
the WARN signal is emitted, surfaced in the run log and (where
applicable) as a non-blocking annotation. This is the ADR-015 amendment
grace-period philosophy applied to the temporal axis: a derived
repository's pipeline does not break the moment an expiry crosses, and
the responsible maintainer receives a discoverable, non-disruptive
signal to revisit the marker.

This is deliberate. A FAIL-on-expiry semantic would (a) reproduce the
ad-hoc adjudication problem this ADR exists to fix — pipelines stuck
red until a human re-examines the marker by hand, the #16/#17 pattern —
and (b) propagate breakage to every fork the moment the template ships
an expiry-dated marker that crosses. WARN keeps the signal honest
(visible, attributable, dated) without converting time into a
deployment hazard.

### 4. Implementation scope — delegated to `implementer`

Whether the parsing logic lives in a shared shell library sourced by
all five detectors, or as a per-detector amendment to each script's
existing ref-allow parser, is **deferred to `implementer` at step 5**
(Spec AC-12). The architect-level choice here is the *contract* (the
syntax, the grandfather rule, the WARN-not-FAIL semantic, the date
comparison rule); the implementation shape is an engineering judgment
on cohesion vs. duplication that the implementer is best positioned to
make once the five scripts are open side-by-side. Both shapes satisfy
the Spec's acceptance criteria; the architect does not prejudge.

### 5. Review-cadence ownership — three-tier responsibility

Expiry dates need someone to look at them. The Spec's AC-10 distributes
ownership across three tiers:

- **Template maintainer (this repo)** owns the cadence for ref-allow
  markers authored *in the template itself*. The template's CHANGELOG
  and the periodic Roadmap audit are the natural review points; a WARN
  in `main`'s CI on an expired template marker is the trigger.
- **Fork maintainer** owns the cadence for ref-allow markers authored
  *in their fork*. A WARN in the fork's CI is the trigger; the fork
  decides whether to renew, remove, or escalate to remove the
  suppression entirely.
- **`technical-writer` (step 7 of the Development Workflow)** owns the
  cadence at the point where documentation is touched: when a Spec or
  ADR is updated, any ref-allow markers in or near the touched
  artifacts are inspected as part of the documentation pass. This
  catches the #16/#17 case structurally — the artifact that the
  ref-allow was *about* is being modified; the marker should be
  re-validated in the same change.

The three tiers are non-overlapping in *who triggers the review* but
overlapping in *which markers can be reviewed* — any tier may legitimately
re-examine any marker. This redundancy is intentional: a marker missed
at one tier is still likely to be caught at another.

### 6. Out-of-scope by design

Four adjacent exemption mechanisms are explicitly **not** addressed by
this ADR (Spec Non-goals): the skill-invariants grandfather clause
(`.claude/skills/claude-md-authoring/invariants.md`, keyed per
invariant), ADR-017's absence-of-claim carve-out (keyed per Roadmap
row), ADR-014's Spec-reservation-rule carve-out (keyed per Spec path
reservation), and the workaround-tracker's `expires_on` field
(`.github/workaround-tracker.yml`, keyed per workaround entry). Each
of those four lives in its own domain with its own keying; bringing
them under one mechanism would conflate boundaries the Spec deliberately
keeps MECE. A future ADR may unify them if a concrete need emerges;
this ADR does not pre-judge that.

## Consequences

### Positive

- The ad-hoc adjudication pattern observed in #16 and #17 is closed
  structurally: a ref-allow can carry its own re-validation date, the
  detector surfaces the date crossing as a WARN, and the responsibility
  for review is distributed across three named owners (§5).
- The grandfather rule guarantees zero breakage for every existing
  ref-allow in the repository and in every fork. No marker has to be
  rewritten; no detector script behavior changes for existing markers.
- The new syntax shape is opt-in per marker, so adoption is incremental
  — a maintainer can introduce expiry dates only where the lifecycle
  question is real, and leave perma-suppressions untouched.
- The WARN-not-FAIL signal level keeps the grace-period philosophy
  consistent across the family (ADR-015 amendment, ADR-018's
  full-width-paren WARN, ADR-021's research-tier WARN): time-crossing
  produces information, not pipeline breakage.
- The MECE boundary against the four adjacent exemption mechanisms
  (§6) is stated explicitly, so a future milestone author routing scope
  has a clean partition to map against.

### Negative

- A sixth distinct shape now lives in the detector family's
  conceptual surface (the five existing keyings plus the new
  reason-plus-expiry composite). Mitigation: the grandfather rule
  means the no-expiry form remains the default mental model for every
  marker that does not explicitly opt in; the new form is additive,
  not pervasive.
- The implementation-scope decision (shared library vs. per-detector
  amendment) is deferred to `implementer`, so this ADR cannot point at
  a single artifact and say "this is where the parser lives." The
  Spec's AC-12 hands this choice down explicitly, but the architectural
  question "is the family cohesive enough to justify a shared library?"
  remains open until the implementer answers it concretely.
- WARN signals accumulate in CI logs. Forks that adopt many
  expiry-dated markers will see more WARN noise; the burden of
  filtering shifts to the fork maintainer. Mitigation: the three-tier
  review cadence (§5) is the structural answer — WARN is meant to be
  read, not silenced.

### Neutral

- The existing ref-allow markers in the repository — the grep across
  `main` finds them in `specs/04-dangling-reference-detector.md`,
  `specs/11-verification-domain-opt-in-guidance.md`,
  `specs/17-changelog-adr-sync.md`, and within the detector test
  scripts as fixture examples — are unaffected. They stay in the
  grandfather form indefinitely.
- The workaround-tracker's `expires_on` field (ADR-006) and this ADR's
  `expires:` clause are *not* unified. They share a temporal idea but
  belong to different domains and use different surfaces (YAML config
  vs. in-line HTML comment). Spec Non-goals fixes the boundary.
- The MECE table in ADR-014 §(d) does not pre-reserve a slot for #18,
  matching the #12/ADR-019, #13/ADR-020, #14/ADR-021 precedent of
  stating the new partition in the ADR itself rather than amending
  ADR-014. The pattern is now four-times-applied and stable.

## Alternatives considered

| Alternative | Pros | Cons | Why not chosen |
|-------------|------|------|----------------|
| **A: Path allowlist in `.claude/exemptions.yml`** | Central, list-visible, one file to audit | ADR-015's own amendment explicitly classified the path-allowlist shape as an anti-pattern: it scatters the suppression away from the artifact it protects, breaks under file renames, and discourages the reviewer from reading the suppressed line in context | Rejected: directly contradicts ADR-015 amendment; the in-line marker is the deliberate ADR-015 contract |
| **B: FAIL on expiry (not WARN)** | Strict enforcement; no log filtering burden; expired markers cannot rot indefinitely | Reproduces the #16/#17 ad-hoc adjudication problem under time pressure; propagates breakage to every fork on the expiry date; contradicts the ADR-015 amendment / ADR-018 / ADR-021 grace-period philosophy applied across the family | Rejected: the family's signal-level convention is WARN for time/convention crossings; FAIL would diverge for no compensating benefit |
| **C: Destructively replace the existing syntax (require `expires:` on every ref-allow)** | One canonical form, no two-shape surface to maintain | Every existing ref-allow across the repository and every fork would have to be rewritten in one change; the grace-period philosophy fails immediately; ADR-015's contract is broken | Rejected: a grandfather-free shape is not viable; the grandfather rule is what makes this ADR safe to ship |
| **D: ADR-015 amendment, no new ADR-022** | One fewer ADR number; consistent with "consequence-clarifications fold into amendments" | The triad discriminator fires 3/3 (new boundary + new keying + new structural artifact); ADR-015's Decision is unchanged; this ADR closes a cost observed *after* ADR-015 shipped and not in its scope. Matches the ADR-017/ADR-018/ADR-019/ADR-020/ADR-021 self-classification on the same instrument | Rejected: structural half dominates exactly as for ADR-017/020/021; an amendment understates the new keying and new artifact |
| **E: Reuse the workaround-tracker's `expires_on` mechanism** | Existing precedent for "exemption that expires"; no new syntax | Different domain (per-workaround YAML, not in-line ref-allow); different keying (workaround-id vs. reason string); different surface (config file vs. HTML comment); conflating the two would dissolve the MECE boundary the Spec keeps deliberately | Rejected: Spec Non-goals fixes the separation; analogy is at the idea level only |
| **F: Extended syntax with optional `expires:` clause, grandfather no-expiry form, WARN-not-FAIL on expiry, implementation scope deferred to `implementer`, three-tier review cadence (chosen)** | Closes the #16/#17 ad-hoc adjudication pattern; preserves byte-compatibility of every existing marker via grandfather; opt-in adoption; grace-period philosophy preserved; MECE boundary against four adjacent mechanisms stated explicitly | Adds a sixth shape to the family's conceptual surface; implementation-scope decision deferred; WARN noise on adopting forks | Chosen: the only option that closes the observed cost, preserves the grace-period philosophy, leaves existing markers untouched, and correctly classifies via the ADR-018 Alternative-B discriminator as a new ADR like ADR-017/020/021 |

## References

- Roadmap row: #18
- `specs/18-ci-exemption-allowlist-expiry.md` — authoritative scope (AC-1 through AC-13, three risks, Non-goals)
- ADR-015 (`.claude/meta/adr/015-dangling-reference-detector.md`) — the ref-allow syntax's origin; its amendment classifies path-allowlist as an anti-pattern and establishes the grace-period philosophy this ADR inherits
- ADR-017 (`.claude/meta/adr/017-roadmap-drift-detector.md`) — absence-of-claim exemption precedent (out of scope per Spec Non-goals); a sibling detector reusing the ref-allow marker
- ADR-018 (`.claude/meta/adr/018-bilingual-parity-detector.md`) — the Alternative-B triad discriminator (new boundary + new keying + new structural artifact ⇒ new ADR; consequence-clarification/extension ⇒ amendment) applied verbatim in §1
- ADR-020 (`.claude/meta/adr/020-ecc-absent-signal.md`) — most recent application of the triad discriminator; precedent for stating a new MECE partition in the ADR itself
- ADR-021 (`.claude/meta/adr/021-research-tier-auth-validation.md`) — most recent consumed ADR number before ADR-022; a sibling detector reusing the ref-allow marker
- ADR-006 (`.claude/meta/adr/006-upstream-workaround-tracking.md`) — the `expires_on` field precedent (out of scope per Spec Non-goals); different domain, analogy at the idea level only
- The five detector scripts: `.claude/meta/scripts/check-bilingual-parity.sh`, `check-dangling-refs.sh`, `check-ecc-delegation-consistency.sh`, `check-roadmap-drift.sh`, `check-research-tier-auth.sh`
