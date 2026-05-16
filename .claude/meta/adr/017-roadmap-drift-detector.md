# ADR-017: Roadmap drift-detection CI — bidirectional-link contract, status-glyph well-formedness, MECE-bounded against #04

## Status

Accepted — 2026-05-16

## Context

The Roadmap (`.claude/CLAUDE.md`, ADR-014) is the single always-read
index mapping each milestone to its authoritative design source. ADR-014
makes the `adr:` ↔ `Roadmap row: #NN` link a **bidirectional**
contract: a row's `adr:` cell names an ADR, and that ADR's `## References`
back-links the row number. ADR-014 §Consequences → Negative names this
gap verbatim — "Index↔reality drift … There is no automated enforcement
in this ADR. Mitigation is *deferred* to a possible future … CI check"
— and `specs/05-roadmap-drift-detection-ci.md` is that deferred
mitigation. `specs/05-roadmap-drift-detection-ci.md` is the
authoritative scope; this ADR records the **structural** decisions the
Spec explicitly defers to `architect` (Spec Risk R-01, Key-interaction
4): the drift classes the detector keys on, the MECE scope boundary
against the #04 detector, and the exemption-keying rule that
distinguishes a legitimately back-link-less ADR from a genuinely drifted
one. The Spec names this decision ADR-017.

Three hard constraints bound the design and are non-negotiable:

1. **CI posture is inherited, not re-decided (Spec R-02).** ADR-015
   §Decision point 3 fixed the always-on posture for #05/#06 via the
   subject-matter-presence rule and stated they "inherit it rather than
   re-litigating it." This ADR records the posture as **inherited** and
   does **not** reopen it. Roadmap-consistency drift is a structural
   contract present in every fork from day one, so the
   subject-matter-presence rule places it always-on with no further
   reasoning required here.
2. **MECE against #04 (Spec R-03).** The #04 detector
   (`check-dangling-refs.sh`, ADR-015) owns reference *resolution*. This
   detector owns Roadmap *index consistency*. The partition must be
   drawn so a single defect maps to exactly one check and one owner —
   the same drift mode ADR-015's Check-4 boundary exists to prevent.
3. **ADR-014 index-only and reservation-rule consistency.** This
   detector must not duplicate the #04 reservation carve-out
   (`spec: specs/NN-slug.md` valid-by-design before the file exists),
   must not add anything to the Roadmap table, and must stay consistent
   with ADR-014's bidirectional-link contract rather than forcing
   ADR-014 to relax.

A fourth force is the **#04 dangling-reference detector itself**, now
active CI. This ADR file is in the #04 detector's Check-1 scope; its
forward references to the not-yet-written
`.claude/meta/scripts/check-roadmap-drift.sh` fall under Check 2, from
which ADR files are excluded by the #04 detector's own documented scope
decision (ADR files are historical records; their `.claude/`-rooted
paths are not Check-2-validated). This is treated as an explicit design
input, mirroring how ADR-015 and ADR-016 listed detector interactions.

The non-trivial decision is the **exemption keying** — the rule that
prevents the false-positive class "every ADR must have a Roadmap row."
It is reasoned through the same discipline ADR-015's carve-outs use:
key the exemption to a structural signal co-located with the reference,
never to a path allowlist.

## Decision

A Roadmap drift detector is a **single repo-local script at
`.claude/meta/scripts/check-roadmap-drift.sh`**, modeled structurally
on `.claude/meta/scripts/check-dangling-refs.sh` (#04), run **always-on**
by `.github/workflows/roadmap-drift-check.yml` on every push and pull
request to `main` with no per-fork configuration. The detector keys on
exactly three drift classes, is MECE-bounded against the #04 detector
by a *contract partition* (resolution vs. consistency), and exempts an
ADR from the bidirectional contract **iff it carries no `Roadmap row:`
line at all** — absence of the claim is not drift; only a present claim
that is inconsistent is drift.

### 1. Drift classes in scope (detector-keyable, exact)

The detector FAILs on, and only on, these three classes:

- **Forward direction of the bidirectional contract.** A Roadmap row
  whose `Design source` cell carries an `adr:` link to a file that
  **exists on disk** but whose `## References` section does **not**
  contain a `Roadmap row: #NN` entry matching that row's number.
- **Reverse direction of the bidirectional contract.** An ADR under
  `.claude/meta/adr/` whose `## References` section carries a
  `Roadmap row: #NN` line where Roadmap row `#NN`'s `Design source`
  cell does **not** list an `adr:` link to that ADR file.
- **Status-glyph well-formedness.** A Roadmap row whose Status cell
  contains any character other than the four ADR-014-sanctioned glyphs
  (`☐` todo / `◐` in-progress / `☑` done / `✗` dropped).

One narrow consistency case is **also** FAIL because no carve-out covers
it: a Roadmap `adr:` link pointing to a path that does **not** exist on
disk. Unlike `spec:` reserved links (valid-by-design absent, #04's
reservation carve-out), an `adr:` link is added by `architect` only at
the moment the ADR is written (ADR-014 write-ownership), so a
non-existent `adr:` target is never valid-by-design — it is always
drift. This overlaps the #04 detector by design (see Decision 2); the
overlap is a stronger signal, not a boundary violation, because the two
checks answer different questions about the same symptom.

**Excluded — the false-positive generator, bounded by an exact
exemption rule:** "every ADR must carry a Roadmap back-link" is **not**
checked. ADRs 001–013 predate Roadmap dogfooding; ADR-014 itself records
a design decision *for the Roadmap mechanism*, not for a discrete
milestone; future ADRs may legitimately record cross-cutting decisions
with no single milestone. The exemption is keyed to one structural
signal: **an ADR is exempt from the bidirectional contract iff its
`## References` section contains no `Roadmap row:` line at all.**
Absence of the claim is the valid-by-design state; the detector keys
*consistency when a claim is present*, never *universality of claims*.
This is the same narrowing discipline as ADR-015's reservation carve-out
("as wide as the documented valid-by-design set and no wider") and its
Reference-intent rule, applied to a new signal: presence-of-the-claim
rather than path-shape or file-absence.

### 2. MECE scope boundary against #04's `check-dangling-refs.sh`

The partition is drawn on **contract**, not file type (the #04↔Check-4
boundary used file-type/link-type; this boundary uses contract because
both checks scan the same files):

| Check | Owns the question | Verb |
|---|---|---|
| #04 `check-dangling-refs.sh` | Does the pointer **resolve** to a real file/ADR? | resolution |
| #05 `check-roadmap-drift.sh` | Does the **bidirectional index contract** hold (both directions) and is every Status glyph well-formed? | consistency |

A defect maps to exactly one owner by this rule: a *broken pointer* (the
target does not exist) is #04's; a *consistent-pointer-but-inconsistent-
contract* defect (both files exist, but the back-link is missing or the
glyph is unsanctioned) is #05's. The single deliberate overlap — a
Roadmap `adr:` link whose target file is absent — is owned **primarily
by #04 for resolution**; #05 *also* FAILs it because an absent `adr:`
target is by definition a broken bidirectional contract (the back-link
cannot exist if the file does not). This is the same "overlap is a
stronger signal" reasoning the Spec's R-03 mitigation states, and it
does not violate MECE-by-contract: the two failures answer two distinct
questions ("does it resolve?" vs. "is the contract satisfied?") about
one symptom, with two distinct conceptual owners, exactly as ADR-015's
Check-4 boundary permits a link to be *conceptually* one check's while
being physically adjacent to another's surface. The boundary is a
structural choice, not an implementation detail — the same standard
ADR-015 §Decision point 1 applied to the Check-4 partition.

This boundary **must be restated in both scripts' header comments**
(downstream task) so the partition is discoverable from either side —
the identical discipline ADR-015 required for the Check-4 boundary
(`check-skill-invariants.sh` carries the reciprocal one-line note).

### 3. CI posture — inherited from ADR-015, explicitly not re-litigated

The detector is always-on, modeled on
`.github/workflows/dangling-ref-check.yml` (#04), with no per-fork
configuration variable or config file. This posture is **inherited**
from ADR-015's subject-matter-presence rule (§Decision point 3, which
names #05 explicitly), **not a new decision in this ADR**. Roadmap
index consistency is a structural contract present in every fork that
keeps the Roadmap — it falls in the always-on (`skill-invariants`)
category, not the default-off (`workaround-check`) category. No new
posture reasoning is performed here; re-opening it is out of scope by
ADR-015's own "inherit rather than re-litigate" instruction.

### 4. Parsing-strategy constraint (structural requirement, not the bash)

The Spec's R-01 hands `architect` the constraint, not the
implementation. Two structural requirements are fixed; the exact
awk/sed/grep form is `implementer`'s (the Neutral-section discipline
ADR-015/016 used):

- **Multi-line `Design source` cell.** Roadmap rows join multiple
  design-source links with `<br>` inside a single Markdown table cell
  (rows #03/#04 carry `spec: …<br>adr: …`). The parser **must** treat
  the `Design source` cell as a `<br>`-joined unit and extract *every*
  `adr:` link in it, not only the first or last line. A line-greedy
  single-match parser that stops at the first `adr:` token would
  mis-key a future row carrying two ADRs (ADR-014 permits 1:N) and is
  forbidden.
- **Exemption keyed to absence-of-claim, never a path allowlist.** The
  pre-Roadmap / Roadmap-mechanism exemption (Decision 1) **must** be
  derived from the structural signal "this ADR's `## References` has no
  `Roadmap row:` line," computed per-ADR at scan time. Enumerating
  exempt ADR filenames in the script is **forbidden** — it is the
  ad-hoc-allowlist anti-pattern ADR-015's amendment explicitly rejected
  (fails open silently as ADRs are added; per-ADR maintenance cost). The
  exemption is a property of the artifact, read from the artifact.

This ADR records the decision and the agent-contract / downstream
implications. It does **not** itself write the script, the workflow, or
the tests, and does **not** modify any agent prompt — implementation is
deferred to `implementer` and listed under Consequences → Neutral for
traceability, exactly as ADR-014, ADR-015, and ADR-016 do.

## Consequences

### Positive

- The ADR-014 bidirectional-link contract is verified in **both
  directions** on every push/PR with zero opt-in: a row that names an
  ADR which does not back-link it, and an ADR that back-links a row
  which does not list it, are both caught before any agent follows the
  one-sided reference. The Spec's headline gap closes.
- Status-glyph well-formedness is enforced, closing ADR-014's
  acknowledged "a fork that hand-edits the table can diverge silently;
  nothing validates the format" negative consequence for the glyph
  column specifically.
- The MECE-by-contract boundary makes ownership unambiguous: a broken
  pointer is #04's, a satisfied-pointer-but-broken-contract defect is
  #05's, and the single deliberate overlap is a stronger signal, not a
  two-owner ambiguity — the same property ADR-015's Check-4 boundary
  delivers.
- The exemption is a **pattern-keyed structural rule** (absence of the
  back-link claim), not a maintained allowlist, so it does not fail
  open as ADRs are added and carries no per-ADR maintenance cost — the
  same property ADR-015's amendment chose over an enumerated allowlist.
- Infrastructure leverage is realized: #04 built the reusable detector
  shape; #05 mirrors it with no new pattern, exactly as ADR-015
  §Decision point 3 anticipated ("one pattern, three milestones").
- The posture is inherited from an already-decided, auditable rule, so
  the template gains no new ad-hoc posture concept — consistent with
  ADR-015 and ADR-016, which also apply the subject-matter-presence
  rule rather than re-deriving a posture.

### Negative

- **Deliberate #04 overlap on the absent-`adr:`-target case.** One
  symptom (a Roadmap `adr:` link to a missing file) produces two CI
  failures from two checks. This is accepted as a stronger signal (Spec
  R-03), but a maintainer must understand the contract partition to see
  *why* two checks fire for one symptom. Mitigation: the boundary is
  documented in both script headers (downstream task) so it is
  discoverable from either side.
- **Couples the detector to ADR-014's table format and back-link
  string.** The parser depends on the `<br>`-joined `Design source`
  cell shape and the literal `Roadmap row: #NN` back-link token. If
  ADR-014's table format or the back-link convention changes, the
  parser must change with it, and nothing cross-checks the two
  automatically. This is the same acceptable coupling ADR-015's
  reservation carve-out took on (keyed to ADR-014's `specs/NN-slug.md`
  shape) and ADR-016's path key took on (keyed to the row number) —
  recorded as a known maintenance edge, narrowed to the smallest
  surface (the Roadmap table and the back-link line only).
- **A fourth principled carve-out joins the detector family's
  conceptual load.** The template now carries: #04's reservation
  carve-out, #04's Reference-intent (opt-in config WARN) rule, the
  Class-A placeholder skip, and now #05's absence-of-claim exemption. A
  maintainer must hold four exemption concepts across two detectors.
  Each is one falsifiable sentence, pattern-keyed, and header-documented
  (downstream task), so the surface is discoverable, but the load grew
  by one rule. Mitigation: the exemption is stated here as one sentence
  so #06 (if it ever needs an analogous rule) inherits the *discipline*
  (key to a co-located structural signal, never an allowlist) rather
  than re-deriving it.
- **Always-on means a false positive blocks CI for the whole repo.**
  Inherited from ADR-015's posture and its accepted mitigation: the
  line-level `<!-- ref-allow: -->` escape hatch (reused by this
  detector unmodified, Spec acceptance criterion) absorbs forward
  references per-line; scope is path-restricted to the Roadmap and ADR
  trees. The cost asymmetry is the same one ADR-015 accepted — a missed
  drift misleads every agent that reads the Roadmap every session; a
  false positive costs one suppression comment.

### Neutral

- This is a **CI-layer addition** in the ADR-015 mold: no agent is
  added or removed; the Spec states no agent prompt change is required
  by this milestone. Agent count unchanged.
- The Roadmap row #05 `Design source` cell gains an `adr:` link to this
  ADR (performed by this change per ADR-014 write-ownership: `architect`
  adds the `adr:` link, `<br>`-joined after the existing reserved
  `spec:` link, exactly as rows #03/#04 show). No other row is touched;
  no Roadmap format change.
- The exact awk/sed/grep parsing form, the `<br>`-split mechanics, the
  zero-padding/`#NN` normalization, and the header-comment wording are
  `implementer` details; this ADR fixes the *categorization, keying, and
  boundary constraints*, not the bash — the same Neutral-section
  discipline ADR-015 and ADR-016 used.
- Downstream `implementer` tasks (recorded for traceability, **not
  performed by this ADR** — implementation is a future session):
  - `.claude/meta/scripts/check-roadmap-drift.sh` — author following
    the `check-dangling-refs.sh` structure (`set -euo pipefail`,
    `git rev-parse` root resolution, `pass`/`warn`/`fail_check`
    helpers, `fail=0` accumulator, `exit "$fail"`, the line-level
    `<!-- ref-allow: -->` escape hatch reused unmodified); include a
    prominent header block documenting (a) the three drift classes,
    (b) the absence-of-claim exemption keyed to "no `Roadmap row:`
    line," (c) the MECE-by-contract boundary against
    `check-dangling-refs.sh`, with a one-line pointer to this ADR.
  - `.github/workflows/roadmap-drift-check.yml` — author following the
    `dangling-ref-check.yml` structure: always-on,
    `on: push/pull_request` to `main` path-scoped to `.claude/CLAUDE.md`,
    `.claude/meta/adr/`, and the script and workflow themselves; single
    `check` job running `bash .claude/meta/scripts/check-roadmap-drift.sh`;
    `permissions: contents: read`; `timeout-minutes: 5`; job name
    `roadmap-drift-check`.
  - `.claude/meta/scripts/check-dangling-refs.sh` — add a one-line
    header comment naming the reciprocal boundary ("Roadmap
    bidirectional-link and status-glyph consistency is owned by
    check-roadmap-drift.sh per ADR-017") so the partition is
    discoverable from the #04 side too — the identical discipline
    ADR-015 required for the Check-4 reciprocal note.
  - The test suite — author following the
    `test-check-dangling-refs.sh` structure: fixtures proving each of
    the three drift classes FAILs, the absence-of-claim exemption does
    **not** FAIL, a `<br>`-joined two-`adr:` cell is fully parsed, an
    unsanctioned glyph FAILs with the row number, and the template's
    own artifacts pass (the Spec's "template is its own baseline"
    criterion).
  - The Japanese counterpart of this ADR
    (`017-roadmap-drift-detector.ja.md`) is owned by
    `technical-writer`, not this task.
- No agent prompt change is introduced or implied. The Spec's
  Key-interaction 5 states the detector is a CI layer only.

## Alternatives considered

| Alternative | Pros | Cons | Why not chosen |
|---|---|---|---|
| **A: Extend `check-dangling-refs.sh` (#04) to also check Roadmap bidirectional consistency and status glyphs — one script, one workflow** | One script, one workflow, one owner; no new boundary to document; the absent-`adr:`-target overlap disappears (one check, one failure); reuses #04's argument-parsing and escape-hatch code directly | Conflates two *different contracts* on the same files: reference *resolution* (does the pointer resolve) vs. index *consistency* (does the bidirectional contract hold). A resolution defect and a consistency defect would be reported by the same job with the same name, muddying which contract failed — the exact drift mode ADR-015's Check-4 boundary exists to prevent, here on the same artifacts; grows a single script past a cohesive size as #06 (parity) would also be folded in by the same logic | Rejected on the same MECE / locality-of-behavior grounds ADR-015 rejected its Alternative C (fold the new detector into `check-skill-invariants.sh`). The Spec scopes #05 as a *distinct* detector; two cohesive checks with a documented contract partition beat one overloaded script. The serious counter (see Counter-proposal); its pros are real but assume one contract where there are two |
| **B: Fold this into an ADR-014 or ADR-015 amendment (no new ADR number)** | Consistent with the ECC "consequence-clarifications fold into amendments" precedent; the posture half *is* an inherited consequence of ADR-015; fewer ADR numbers | The posture half is inherited, but #05 also introduces a **new detector**, a **new MECE contract boundary against a sibling check**, and a **new exemption-keying rule** (absence-of-claim) — exactly the "new structural decision" half of the ECC precedent ("new ADR numbers are reserved for new structural decisions"). ADR-015 itself classified the directly analogous case (new detector + new boundary + inheritable rule) as warranting a new ADR, not an ADR-014 amendment. Burying a new detector's scope-boundary inside another ADR's amendment trail hides a structural decision | Rejected: the ECC precedent's two halves point opposite ways and the structural half dominates. The posture is correctly handled by *inheriting* (referencing ADR-015) — not by amending it. A new detector with a new boundary and a new keying rule is the precedent's "new structural decision," parallel to ADR-015's own self-classification |
| **C: Status-glyph check only; defer the bidirectional-link check to a later milestone** | Smallest script; the glyph check is trivially mechanical and false-positive-free | Leaves the headline ADR-014 gap (the bidirectional `adr:`↔back-link drift the Spec exists to close, and which ADR-014 §Consequences explicitly defers to this milestone) unaddressed; the index can still silently desync, defeating the Spec's primary goal | Rejected: the glyph check is the *minor* class; the bidirectional contract is the milestone's reason to exist (Spec Goals 1–2, ADR-014 §Consequences → Negative). Shipping only the easy half would close the milestone while leaving its purpose unmet |
| **D: New ADR-017 — distinct detector, three drift classes, MECE-by-contract boundary against #04, absence-of-claim exemption, posture inherited from ADR-015 (chosen)** | Closes the bidirectional gap in both directions plus glyph well-formedness; MECE-by-contract boundary keeps ownership unambiguous; exemption is pattern-keyed not allowlisted; posture inherited from an already-decided rule (no re-litigation); reuses #04's shape (one pattern, three milestones) | Deliberate #04 overlap on the absent-`adr:`-target case (accepted as a stronger signal); couples the parser to ADR-014's table/back-link format; a fourth carve-out joins the detector family's conceptual load | Chosen: the only option that closes the full Spec scope, draws a defensible MECE boundary against the sibling detector, and keeps the exemption principled rather than allowlisted — while correctly inheriting (not re-deciding) the posture |

## Counter-proposal

The serious counter-position is **Alternative A — do not add a separate
detector; extend `check-dangling-refs.sh` (#04) to also check Roadmap
bidirectional consistency and status-glyph well-formedness, one script
and one workflow**. It is recorded here per the
ADR-012 / ADR-014 / ADR-015 / ADR-016 precedent of taking a rejected
alternative seriously rather than as a strawman. It is the direct
analogue of ADR-015's Alternative C (fold the new detector into the
existing one). The argument:

1. One script, one workflow, one owner is the simplest possible
   structure. The #04 detector already parses CLAUDE.md and ADR files,
   already has the `<!-- ref-allow: -->` escape hatch, and already
   resolves Roadmap `adr:`/`spec:` cells — adding "and also check the
   back-link is reciprocal" is a few more functions in code that
   already walks the same files.
2. The single deliberate overlap this ADR accepts (a Roadmap `adr:`
   link to a missing file FAILing both #04 and #05) **vanishes** under
   one script: one symptom, one failure, no "why did two checks fire?"
   confusion. Merging removes the only Negative this ADR has to
   actively defend.
3. The Spec's R-03 already concedes the overlap is "narrow" and
   "acceptable." If the overlap is acceptable, the simpler structure
   that eliminates it entirely is arguably better than the more complex
   one that documents it.

**Why the counter was not adopted:**

- The decisive issue is **two contracts, not two file sets**. ADR-015's
  Check-4 boundary partitioned by file-type/link-type because the
  contracts lived in different files. Here both checks scan the same
  files (CLAUDE.md, ADRs), so the partition must be by *contract*:
  reference *resolution* (does a pointer resolve) vs. index
  *consistency* (does the bidirectional contract hold, is every glyph
  sanctioned). Folding them makes a resolution failure and a
  consistency failure indistinguishable at the job level — the exact
  "which contract failed?" muddiness ADR-015 §Decision point 1 rejected
  for the Check-4 case, reproduced on the same artifacts. The contracts
  have different conceptual owners (the #04 detector owns "the pointer
  is real"; this detector owns "the index agrees with itself"); one job
  reporting both erases that ownership.
- The Spec scopes #05 as a **distinct detector** (Key-interaction 1–2:
  author `check-roadmap-drift.sh` and `roadmap-drift-check.yml`
  following — not extending — the #04 files) and its Non-goals
  explicitly say #04's prose-path / ADR-ref resolution is *not* this
  detector's scope. Merging would re-conflate exactly what the Spec
  separated.
- The overlap the counter eliminates is **deliberate and cheap**: a
  single absent-`adr:`-target symptom producing two failures is a
  stronger signal (Spec R-03), not a defect; its only cost is one
  documented sentence in two script headers. Eliminating a cheap,
  signal-positive overlap by paying the much larger cost of a
  two-contract overloaded script (which #06 would then also be folded
  into) is the wrong trade — the same locality-of-behavior value
  ADR-012 applied to the dispatcher and ADR-015 applied to its
  Alternative C.

**Trigger conditions for re-evaluating this counter-proposal:**

- The #04 and #05 detectors prove to share so much parsing code that
  the duplication cost (two parsers of the same Roadmap table) exceeds
  the contract-separation benefit — at which point a *shared parsing
  library* sourced by both scripts (not a merged script) would be the
  correct refactor, preserving the contract partition while removing
  the duplication.
- ADR-014's table format changes such that resolution and consistency
  can no longer be meaningfully separated on the Roadmap (e.g. the
  index collapses into a form where "resolves" and "is consistent" are
  the same predicate), removing the two-contract premise.
- #06 (bilingual parity) is designed and found to share the *same*
  contract as #05 (consistency of a bidirectional mapping) closely
  enough that one consistency detector with three sub-checks is more
  cohesive than three scripts — a deliberate re-evaluation point, not a
  default.

The counter-proposal stays in this ADR as the historical record of the
decision's most serious objection, per the
ADR-012 / ADR-014 / ADR-015 / ADR-016 convention.

## References

- ADR-014 (Roadmap Index as the Single Entry Point) — defines the
  bidirectional `adr:` ↔ `Roadmap row: #NN` contract this detector
  enforces and the four sanctioned status glyphs; §Consequences →
  Negative explicitly defers this CI mitigation to this milestone; the
  Spec reservation rule (and its 2026-05-16 amendment) is out of this
  detector's scope (it is the #04 detector's carve-out). This ADR
  follows ADR-014's "record the decision + downstream tasks, do not
  perform them" shape and its write-ownership model (`architect` adds
  the row's `adr:` link).
- ADR-015 (Dangling-Reference Detector) — §Decision point 3 fixes this
  milestone's always-on posture as **inherited, not re-litigated** (the
  subject-matter-presence rule names #05 explicitly); §Decision point 1
  and §Consequences establish the MECE-boundary discipline this ADR
  applies to the #04↔#05 partition (a single defect must map to one
  check and one owner); its reservation carve-out and Reference-intent
  rule are the narrowing-discipline precedent for this ADR's
  absence-of-claim exemption; ADR-015 is also the precedent for
  classifying "new detector + new boundary + inheritable rule" as a new
  ADR rather than an amendment.
- ADR-012 (Code Reviewer as Dispatcher) — precedent for recording a
  counter-proposal raised and rejected with real pros and explicit
  re-evaluation triggers; the locality-of-behavior / separation-of-
  concerns value applied here to reject the merged-detector counter.
- ADR-016 (Cross-session progress persistence) — the immediately prior
  ADR; the house style this ADR mirrors (Status / Context / Decision /
  Consequences[Positive/Negative/Neutral] / Alternatives considered /
  Counter-proposal / References) and the "record the decision +
  downstream tasks, do not perform them" discipline.
- `specs/05-roadmap-drift-detection-ci.md` — the authoritative scope of
  this milestone; this ADR records the structural *how/why* for the
  keying, boundary, and parsing constraints the Spec defers (R-01,
  R-03, Key-interaction 4); the Spec owns the *what*.
- `specs/04-dangling-reference-detector.md` /
  `.claude/meta/scripts/check-dangling-refs.sh` /
  `.github/workflows/dangling-ref-check.yml` — the structural sibling
  and the reusable detector/workflow/test shape this milestone mirrors;
  the MECE-by-contract boundary partner.
- Roadmap row: #05 (back-link to the milestone this ADR records a
  decision for).
- The Japanese counterpart
  (`017-roadmap-drift-detector.ja.md`) is owned by `technical-writer`,
  not part of this change.
