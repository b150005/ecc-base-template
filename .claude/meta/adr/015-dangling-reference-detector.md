# ADR-015: Dangling-Reference Detector — always-on, subject-matter-keyed CI posture

## Status

Accepted — 2026-05-16

## Context

The template ships design artifacts — `CLAUDE.md`, ADRs, Specs, and
agent files — that cross-reference each other densely. ADRs cite
sibling ADRs by number ("see ADR-007", "per ADR-012"); `CLAUDE.md`
names script paths and Skill directories by path; Specs carry `spec:`
and `adr:` links back-referencing Roadmap rows; agent files reference
ADR numbers and paths inline. None of these references are verified.
A rename, move, deletion, or a transposed digit silently produces a
dangling reference that misleads the next agent to read the document —
the orchestrator resolves design artifacts through `CLAUDE.md`,
`implementer` resolves the Spec through the Roadmap row, and
`architect` reads prior ADRs for consistency before creating a new
one. Every one of these resolution paths consumes context budget
chasing a pointer that may not resolve.

The existing `check-skill-invariants.sh` Check 4 validates relative-
path links **inside `SKILL.md` files only**. It does not validate
`ADR-NNN` textual references in any file, nor `.claude/`-rooted path
mentions in `CLAUDE.md`, ADRs, or Specs. This is the gap milestone #04
closes. Spec `specs/04-dangling-reference-detector.md` is the
authoritative scope; this ADR records the **structural** decisions the
Spec leaves to `architect`: the always-on-vs-default-off CI posture,
the scope boundary against `check-skill-invariants.sh`, the
ADR-014-reservation-rule carve-out as a hard constraint on the
detector, and the detector-pattern reuse by milestones #05 and #06.

The non-trivial decision is the **CI posture**. The template has two
established CI conventions, and they disagree on the surface:

- `skill-invariants.yml` (ADR-007) — **always-on**, path-scoped,
  runs on every push/PR that touches the relevant paths, no
  configuration step.
- `workaround-check.yml` (ADR-006) — **default-off, single-switch**,
  every job reads `.github/workaround-tracker.yml` and short-circuits
  until `enabled: true`.

A reviewer can reasonably ask: every config-driven CI in this template
is default-off (ADR-006 even states default-off as a convention and
rejected a default-on alternative for "ergonomics and convention").
Why is this detector different? That counter-position is taken
seriously in Alternatives below and in the "Counter-proposal" section,
following the ADR-012 / ADR-014 precedent of recording a rejected
option auditably with real pros and a concrete reason it was not
chosen.

This is a **new structural decision** — a new CI mechanism, its
posture, its scope boundary against an existing check, and a posture
rule that #05/#06 inherit — so per the ECC precedent stated in ADR-014
("new ADR numbers are reserved for new structural decisions;
consequence-clarifications fold into amendments") it warrants a new
ADR (015), not an ADR-014 amendment.

## Decision

The dangling-reference detector is **always-on**, modeled on
`skill-invariants.yml`, not default-off like `workaround-check.yml`. It
runs on every push and pull request to `main` (path-scoped to the
scanned document trees and the script/workflow themselves) with no
per-fork configuration variable or config file.

The posture is decided by a single explicit rule, stated here so #05
and #06 inherit it rather than re-litigating it:

> **Subject-matter-presence rule.** A template CI check is **always-on**
> when its subject matter is a structural contract present in *every*
> fork from day one; it is **default-off / single-switch** when its
> subject matter is *absent or irrelevant* in a fresh fork until the
> adopter opts into the feature that creates it.

Applying the rule: `workaround-check` and `docs-freshness` are
default-off because their subject matter — an upstream-workaround
registry, drift against Anthropic's docs — does not exist or is
irrelevant in a fresh fork until the adopter starts tracking
workarounds or wires the freshness job. `skill-invariants` is
always-on because its subject matter — Skill structural contracts —
exists in every fork that keeps `.claude/skills/`. Dangling-reference
detection's subject matter — the template's own
`CLAUDE.md`/ADR/Spec/agent cross-references — is present in every fork
from day one (it is the template's own structural fabric), so it falls
in the `skill-invariants` category, not the `workaround-check`
category. The template is its own first customer and must pass this
check at ship time with no opt-in step.

Three further structural decisions:

1. **Scope boundary against `check-skill-invariants.sh` Check 4.** The
   new detector owns `CLAUDE.md`, `.claude/meta/adr/*`, `specs/*`, and
   `.claude/agents/*`. Check 4 keeps sole ownership of relative-path
   links **inside `SKILL.md` files**. The detector does not scan
   `SKILL.md` relative links, and Check 4 does not scan `ADR-NNN`
   textual references or `CLAUDE.md`/ADR/Spec path mentions. The two
   checks are MECE by file-type-and-link-type partition; a link is
   validated by exactly one of them, never both. This separation is a
   structural choice, not an implementation detail: a single link that
   two checks both fail produces two CI failures for one defect and
   two owners for one fix, which is the drift mode this boundary
   exists to prevent.

2. **ADR-014 reservation-rule carve-out is a hard constraint on the
   detector.** ADR-014's Spec reservation rule (and its 2026-05-16
   amendment) makes a Roadmap `spec: specs/NN-slug.md` link
   valid-by-design even when the file does not yet exist on disk — the
   link is a property of the index, the file materializes when the
   milestone is picked up. The detector **must not** fail such a link.
   This does not weaken the detector: the carve-out is keyed to the
   exact deterministic pattern (the `specs/` prefix, two-digit `NN`,
   hyphen, slug, `.md` suffix) **and applied only to references found
   in the Roadmap `Design source` column** — not to all `specs/`
   mentions anywhere. A genuinely dangling Spec path written in prose,
   or a non-reservation-shaped `specs/` reference, is still caught. The
   carve-out narrows exactly to the set ADR-014 declares
   valid-by-design and no wider, so it removes false positives without
   opening a hole.

3. **#04 establishes the detector pattern #05 and #06 reuse.** Closing
   #04 first is the highest-leverage ordering (the Spec's framing)
   precisely because it builds the reusable shape — `set -euo
   pipefail` script under `.claude/meta/scripts/`, path-scoped
   always-on workflow under `.github/workflows/`, `pass`/`warn`/
   `fail_check` accumulator, line-level `<!-- ref-allow: -->` escape
   hatch — that #05 (Roadmap drift CI) and #06 (bilingual parity CI)
   reuse or mirror. Treating #05/#06 as default-off would contradict
   the subject-matter-presence rule (Roadmap drift and EN/JA parity
   are also always-present structural contracts), so the rule fixes
   their posture too.

This ADR records the decision and the agent-contract / downstream
implications. It does **not** itself write the script or the workflow;
those are downstream `implementer` tasks, listed under Consequences →
Neutral for traceability (the same convention ADR-014 follows).

## Consequences

### Positive

- The template's own structural fabric is verified on every push/PR
  with zero opt-in. The template ships green by construction; an
  adopter who forks inherits a known-sound cross-reference baseline
  without a configuration step.
- A principled, written posture rule (subject-matter-presence)
  replaces an ad-hoc "is this one default-off like the others?"
  judgement. #05 and #06 inherit a decided posture instead of
  re-arguing it; the rule is auditable and falsifiable.
- The scope boundary against Check 4 makes ownership unambiguous:
  every cross-reference is validated by exactly one check, so a single
  defect never produces two failures or two owners.
- The reservation-rule carve-out keeps ADR-014's valid-by-design
  reserved links green while still catching genuinely dangling Spec
  paths — the detector and ADR-014 stay mutually consistent rather
  than the detector forcing ADR-014 to relax.
- Infrastructure leverage: #04 builds the reusable detector shape #05
  and #06 mirror, which is why the gap analysis ranked it highest-
  leverage. One pattern, three milestones.

### Negative

- Always-on means a false positive blocks CI for the whole repo, not
  just an opted-in subset. Mitigation: the line-level
  `<!-- ref-allow: -->` escape hatch absorbs forward-looking
  references per-line without disabling the check; scope is restricted
  to known document trees, not all files. The asymmetry is deliberate
  — a missed dangling reference costs every agent that reads the
  document every session; a false positive costs one suppression
  comment.
- The detector and `check-skill-invariants.sh` now share a conceptual
  domain (cross-reference integrity) split across two scripts and two
  workflows. A future maintainer must know the file-type/link-type
  partition to know which check owns a given link. The boundary is
  documented here and must be restated in both scripts' header
  comments (downstream task) so the split is discoverable from either
  side.
- The carve-out couples the detector to ADR-014's deterministic
  `specs/NN-slug.md` path shape. If ADR-014's reservation path pattern
  ever changes, the carve-out regex must change with it, and nothing
  cross-checks the two automatically. This coupling is recorded as a
  known maintenance edge keyed to the Roadmap `Design source` column
  only (the narrowest possible surface).
- The posture rule is a new concept the agent team and human readers
  must hold. It is one sentence, but it is load-bearing for #05/#06
  and any future template CI; misapplying it (e.g. shipping a
  subject-matter-present check as default-off) silently weakens the
  template.

### Neutral

- No new agent; no agent removed. This is a CI-layer addition plus a
  documented posture rule. The Spec states no agent prompt changes are
  required by this milestone — consistent with ADR-014's
  CLAUDE.md-plus-traceability shape.
- The escape-hatch syntax (`<!-- ref-allow: -->`) and the zero-padding
  normalization for ADR numbers (`ADR-7` ≡ `ADR-007`) are
  implementation details the Spec assigns to `implementer`; this ADR
  does not fix their exact form, only that the carve-out and the
  Check-4 boundary are honored by whatever form is chosen.
- Downstream `implementer` tasks (recorded for traceability, not
  performed by this ADR):
  - `.claude/meta/scripts/check-dangling-refs.sh` — author following
    the `check-skill-invariants.sh` structure (`set -euo pipefail`,
    `git rev-parse` root resolution, `pass`/`warn`/`fail_check`
    helpers, `fail=0` accumulator, `exit "$fail"`); include a
    prominent header block documenting (a) the ADR-014 reservation-
    rule carve-out keyed to the Roadmap `Design source` column, and
    (b) the Check-4 scope boundary, with a one-line pointer to this
    ADR.
  - `.github/workflows/dangling-ref-check.yml` — author following the
    `skill-invariants.yml` structure: always-on, `on: push/pull_request`
    to `main` path-scoped to the scanned trees plus the script and
    workflow themselves, single `check` job, `permissions: contents:
    read`, `timeout-minutes: 5`, job name `dangling-ref-check`.
  - `.claude/meta/scripts/check-skill-invariants.sh` — add a one-line
    header comment naming the boundary ("ADR/Spec/CLAUDE.md/agent
    cross-references are owned by check-dangling-refs.sh per ADR-015")
    so the partition is discoverable from the Check-4 side too.
  - The Japanese counterpart of this ADR
    (`015-dangling-reference-detector.ja.md`) is owned by
    `technical-writer`, not this task.

## Alternatives considered

| Alternative | Pros | Cons | Why not chosen |
|---|---|---|---|
| **A: Default-off / single-switch, mirroring `workaround-check.yml` (the established config-driven CI convention)** | Consistent with ADR-006's stated default-off convention; zero CI cost for forks until opted in; no false-positive blast radius until enabled | The subject matter (the template's own ADR/CLAUDE.md/Spec cross-references) exists in **every** fork from day one — there is no fork where the check is vacuously unhelpful, unlike the empty workaround registry; the template would not pass its own check at ship time without an opt-in step, contradicting "template is its own first customer"; default-off here teaches forks that structural-fabric integrity is optional | Raised as the serious counter-position (a reviewer's "why is this one different?"). Rejected on the subject-matter-presence rule: default-off is correct only when the subject matter is absent in a fresh fork (workarounds, docs-drift). Cross-references are always present, so this belongs in the `skill-invariants` always-on category. Recorded as the rejected option, not a strawman — its pros are real, but they assume an absent subject matter this check does not have |
| **B: Always-on but a single global config switch (`enabled` defaulting to true) so forks can disable it** | Forks that deliberately strip the design-artifact layer can turn it off; nominal flexibility | A truthy-by-default switch is a non-switch for the ship-time guarantee while adding a second-toggle drift mode (the exact fail-unsafe pattern ADR-006 rejected in its "two-toggle activation" alternative); a fork that deletes `.claude/` simply deletes the workflow too — the path-scoped trigger already makes it inert with no content to scan | Adds an unused control surface and a drift mode for a guarantee that needs none. Deleting the workflow is the existing, clean opt-out (same as `skill-invariants.yml`); a config flag is strictly worse |
| **C: Extend `check-skill-invariants.sh` to also cover ADR/CLAUDE.md/Spec/agent references (one script, one workflow)** | One script, one workflow, one owner; no new boundary to document | Conflates two contracts with different scopes (Skill structural invariants vs. cross-document reference integrity); a Skill-contract change and a dangling-ADR-ref are reported by the same job with the same name, muddying which contract failed; grows a single script past a cohesive size | Separation of concerns: the Spec explicitly scopes the new detector to *not* double-report Check 4's `SKILL.md` links. Two cohesive checks with a documented MECE boundary beat one overloaded script — the same locality-of-behavior value ADR-012 applied to the dispatcher |
| **D: Always-on, modeled on `skill-invariants.yml`, with the Check-4 boundary and the ADR-014 carve-out as hard constraints (chosen)** | Template passes its own check at ship time with zero opt-in; posture decided by an explicit, inheritable rule; MECE boundary with Check 4; carve-out keeps ADR-014 consistent; builds the reusable shape #05/#06 mirror | False positive blocks the whole repo (mitigated by the line-level escape hatch and document-tree scoping); couples the carve-out to ADR-014's deterministic path shape | Chosen: it is the only option under which the template is green-by-construction at ship time, and the subject-matter-presence rule makes the posture principled rather than ad hoc |

## Counter-proposal

The serious counter-position is **Alternative A — make this detector
default-off / single-switch like every other config-driven CI in the
template** (`workaround-check.yml`; `docs-freshness.yml`). It is
recorded here per the ADR-012 precedent of taking a rejected
alternative seriously rather than as a strawman. The argument:

1. ADR-006 establishes default-off as *the* template CI convention and
   explicitly rejected a default-on alternative "for ergonomics and
   convention." Consistency has value: a fork maintainer who has
   internalized "template CI is opt-in" is surprised by an always-on
   job.
2. Always-on means a false positive blocks CI for the entire repo, not
   an opted-in subset. A noisy detector on day one erodes trust in the
   whole CI surface.
3. A single switch is a known, well-understood control in this
   template; reusing it has zero conceptual cost.

**Why the counter was not adopted:**

- The convention ADR-006 established is not "all template CI is
  default-off." It is "CI whose *subject matter is absent in a fresh
  fork* is default-off." ADR-006's subject matter is an upstream-
  workaround registry that is empty in a fresh template; ADR-007's
  `docs-freshness` subject matter is drift against Anthropic docs,
  irrelevant until wired. `skill-invariants` — also ADR-007, same
  template — is **always-on** for exactly the opposite reason: its
  subject matter (Skill structural contracts) is present in every
  fork. The template therefore already has *both* postures, selected
  by subject-matter presence. Dangling cross-references are present in
  every fork from day one, placing this check unambiguously in the
  always-on category. The counter mistakes one instance of the rule
  (default-off) for the rule itself.
- The ship-time guarantee is load-bearing: a default-off check cannot
  make "the template passes its own cross-reference check at the
  moment #04 ships" true without an opt-in step, which defeats the
  point of the template being its own first customer.
- The false-positive blast radius is bounded by design — document-tree
  scoping plus a line-level `<!-- ref-allow: -->` escape hatch — and
  the cost asymmetry runs the other way: a missed dangling reference
  is paid by every agent that reads the document on every session; a
  false positive is paid once as a suppression comment.

**Trigger conditions for re-evaluating this counter-proposal:**

- The template's audience shifts toward forks that routinely strip the
  `.claude/` design-artifact layer, at which point the subject matter
  is no longer universally present and the rule itself would reclassify
  the check.
- The detector proves chronically noisy in derived repos despite the
  escape hatch and scoping (false-positive rate high enough that the
  cost asymmetry inverts in practice).
- ADR-014's reservation path pattern changes in a way that makes a
  narrow carve-out infeasible, forcing a coarser exemption that would
  materially weaken the always-on guarantee.

The counter-proposal stays in this ADR as the historical record of the
posture decision's most serious objection, per the ADR-012 / ADR-014
convention.

## Amendment — 2026-05-16: opt-in/default-off config is a WARN category, not a FAIL category

**Status of original decision:** unchanged (Accepted — 2026-05-16). This
amendment clarifies a consequence of the always-on posture; it does not
reverse it. Per the ADR-014 convention ("consequence-clarifications
fold into amendments; new ADR numbers are reserved for new structural
decisions"), this is an amendment, not a new ADR.

### Trigger

During #04 quality gate, the detector produced two false-positive
classes against the template's own artifacts, and the `implementer`
resolved them with scattered `<!-- ref-allow: -->` suppressions in
`CLAUDE.md` and `specs/04-dangling-reference-detector.md`. This
directly violated the Spec's Leading metric ("Zero `<!-- ref-allow: -->`
suppressions … at ship time"). The `architect` was asked for a
structural ruling before the quality gate proceeds.

- **Class A (documentation pattern tokens):** `specs/NN-slug.md`,
  `specs/NNN-slug.md`, `ADR-NNN` where the numeric slot is literal `N`
  characters. These are metasyntactic placeholders describing the
  template's own reservation-rule notation, categorically identical to
  the `*`/`?`/`<`/`>` glob/template tokens the detector already skips
  in `check_path_refs_in_file`. Class A is a **detector gap in
  placeholder recognition**, not a reference defect, and is resolved by
  extending the existing example/template-token skip — no ADR change
  needed for Class A; it is recorded here only for traceability.
- **Class B (opt-in / default-off, absent-by-default config):**
  references to `.claude/learn/config.json` (Learning Mode, default-off)
  and `.claude/compliance.yml` (compliance Skill, opt-in; only the
  `.example` ships). Both are verified absent on disk and *intentionally*
  absent — the prose on the referencing line itself documents the
  absence as a valid state. This is the structural decision this
  amendment records.

### Decision (additive)

A reference to an **intentionally-absent opt-in / default-off
adopter-created config file** is a structurally distinct category from
a stale / broken / typo'd reference, and the detector must **not FAIL**
on it. Stated as an extension of the subject-matter-presence rule:

> **Reference-intent rule.** The detector FAILs a reference whose author
> intent is *intended-present, actually-absent* (a rename, move,
> deletion, or typo — the failure mode this detector exists to catch).
> A reference whose intent is *intended-absent, actually-absent*, with
> the absence documented as a valid state co-located with the
> reference, is **not that failure mode**. The ADR-014 reservation
> carve-out is the authoring-time instance of intended-absent
> (a Spec file materializes when the milestone is picked up);
> opt-in/default-off config is the runtime-creation instance
> (an adopter creates it only if they enable the feature). Both are
> valid-by-design absences, not dangling references.

The detector treats an absent `.claude/`-rooted `.json`/`.yml`/`.yaml`
path as **WARN, not FAIL**, **only when the exemption is keyed to
structural context co-located with the reference** — exactly as the
reservation carve-out is keyed to the Roadmap `Design source` column
and not to all `specs/` mentions. The keying signal is: the
referencing line carries a fixed opt-in vocabulary token
(`absent`, `default-off`, `opt-in`) **or** a sibling `<path>.example`
exists on disk. An absent `.claude/` config path **without** a
co-located opt-in signal and **without** an `.example` sibling stays
**FAIL** — a bare typo'd config path has no "absent is fine" context
beside it and is still the *intended-present, actually-absent* failure
mode the detector must catch.

This narrowing is deliberate and mirrors the reservation carve-out's
narrowing precisely: the exemption is as wide as the documented
valid-by-design set and **no wider**. It does not "weaken the check for
all absent `.claude/*.json|yml`" — only for those carrying the
co-located absent-by-design signal.

### Why not the rejected Class-B options

- **Documented allowlist in the detector (rejected).** An enumeration
  of specific paths is the ad-hoc-judgement pattern the
  subject-matter-presence rule was written to replace. It fails open
  silently (a forgotten new opt-in file produces a false CI red that
  pressures developers back toward scattered suppressions — the exact
  Spec-metric violation this amendment closes) and adds per-feature
  maintenance. A principled pattern-keyed rule has neither cost.
- **Accept suppressions; amend the Spec metric (rejected).** Bakes
  permanent `ref-allow` noise into `CLAUDE.md` — the single always-read,
  compaction-durable artifact — to compensate for a detector that
  mis-categorizes. Weakening a correct success metric to fit an
  implementation shortcut is the wrong direction of fit. The Spec
  metric is correct as written; the detector was wrong.

### Consequences of this amendment

- **Positive.** Zero functional `ref-allow` suppressions in the
  template's own `CLAUDE.md` and Spec at ship time — the Spec's Leading
  metric is satisfied *verbatim*, no Spec amendment required. The
  config-vs-design-artifact distinction is encoded as a rule, not a
  maintained list. #05 and #06 inherit a third, principled reference
  category alongside the reservation carve-out.
- **Negative.** The detector now carries two principled carve-outs
  (reservation-rule; opt-in-config WARN) plus the placeholder-token
  skip. A future maintainer must hold three exemption concepts. Each is
  pattern-keyed and documented in the script header (downstream
  `implementer` task), so the surface is discoverable, but the
  conceptual load of the detector grew by one rule. Mitigation: the
  Reference-intent rule is one falsifiable sentence, stated here so
  #05/#06 inherit it rather than re-deriving it.
- **Neutral.** No new agent; no agent prompt change. The detector
  behavior changes (Class A: extend placeholder skip to literal-`N`
  numeric-slot tokens; Class B: WARN-not-FAIL for opt-in-signalled
  absent `.claude/` config) are downstream `implementer` tasks; this
  amendment fixes the *categorization and keying constraints*, not the
  exact bash form, consistent with the original ADR's Neutral section.
- **Roadmap.** Row #04 was prematurely flipped to `☑ done`; it must
  return to `◐ in-progress` until the quality gate passes against the
  corrected detector. Roadmap write-ownership is `product-manager`
  (status) per ADR-014; this amendment only records that the flip was
  premature.
- The Japanese counterpart
  (`015-dangling-reference-detector.ja.md`) must carry this amendment;
  that translation is a `technical-writer` task, not part of this
  amendment.

## References

- ADR-006 (Upstream workaround tracking) — the default-off /
  single-switch CI precedent; this ADR distinguishes its posture by
  the subject-matter-presence rule (workaround registry is absent in a
  fresh fork; cross-references are present in every fork).
- ADR-007 (CLAUDE.md Authoring Skill) — ships both `skill-invariants.yml`
  (always-on, structural-contract-protecting) and `docs-freshness.yml`
  (default-off); the always-on `skill-invariants` is the structural
  model this detector follows, and `check-skill-invariants.sh` Check 4
  is the existing check this detector is MECE-bounded against.
- ADR-014 (Roadmap Index as the Single Entry Point) — defines the Spec
  reservation rule and its 2026-05-16 amendment; the detector's
  reservation-rule carve-out is a hard constraint derived from it, and
  this ADR follows ADR-014's "record the decision + downstream tasks,
  do not perform them" shape and its rejected-alternative recording
  convention.
- ADR-012 (Code Reviewer as Dispatcher) — precedent for recording a
  counter-proposal that was raised and rejected, with real pros and
  explicit trigger conditions for re-evaluation; the
  separation-of-concerns / locality-of-behavior value applied to the
  Check-4 boundary.
- `specs/04-dangling-reference-detector.md` — the authoritative scope
  of this milestone; this ADR records the structural *how/why*, the
  Spec owns the *what*.
- `.github/workflows/skill-invariants.yml` /
  `.claude/meta/scripts/check-skill-invariants.sh` — the always-on,
  path-scoped structural model and the Check-4 boundary partner.
- `.github/workflows/workaround-check.yml` /
  `.github/workaround-tracker.yml` — the default-off single-switch
  shape this detector deliberately does *not* follow, for the reason
  stated in the subject-matter-presence rule.
- Roadmap row: #04 (back-link to the milestone this ADR records a
  decision for).
- The Japanese counterpart
  (`015-dangling-reference-detector.ja.md`) is owned by
  `technical-writer`, not part of this change.
