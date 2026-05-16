# ADR-018: EN/JA bilingual parity detector — convention-presence in-scope keying, level+position heading normalization, three-way MECE-by-contract against #04 and #05

## Status

Accepted — 2026-05-16

## Context

The template ships bilingual paired artifacts — ADRs, Specs, agent
files, and templates exist in both English (`<name>.md`) and Japanese
(`<name>.ja.md`). Humans and agents depend on these pairs being
structurally consistent: an agent reading the canonical EN file must be
able to trust that the JA translation covers the same sections in the
same order, and a human reviewer must be able to verify parity without
manually diffing heading trees. No CI check enforces this today.
`specs/06-bilingual-parity-detector.md` is the authoritative scope —
the three parity dimensions (heading-tree, full-width-parentheses,
presence), the 11 acceptance criteria, and the Non-goals. This ADR
records the **structural** decisions the Spec explicitly defers to
`architect` (Spec Risk R-01, R-03, Key-interaction 5): the in-scope
tree set, the EN-only carve-out rule, the heading-normalization
strategy, and the parsing-approach constraint. The Spec names this
decision ADR-018 and hands the four constraints to the architect
verbatim; this ADR closes them.

This is the **third detector** in a family. #04
(`check-dangling-refs.sh`, ADR-015) owns cross-reference *resolution*.
#05 (`check-roadmap-drift.sh`, ADR-017) owns Roadmap *index
consistency*. #06 owns EN↔JA *translation parity*. The same files —
`CLAUDE.md`, ADRs, Specs — are scanned by more than one detector, so
the partition cannot be drawn on file type; it must be drawn on
*contract*, the same reasoning ADR-017 §2 used for the two-way
#04↔#05 partition, now extended to three.

Four hard constraints bound the design and are non-negotiable:

1. **CI posture is inherited, not re-decided (Spec R-02).** ADR-015
   §Decision point 3 fixed the always-on posture for #05/#06 via the
   subject-matter-presence rule and **names #06 explicitly**: "Treating
   #05/#06 as default-off would contradict the subject-matter-presence
   rule (Roadmap drift and EN/JA parity are also always-present
   structural contracts), so the rule fixes their posture too." This
   ADR records the posture as **inherited** and does **not** reopen it,
   exactly as ADR-017 §3 did not re-litigate the #05 posture. Bilingual
   parity is a structural contract present in every fork that keeps the
   bilingual artifacts, so the subject-matter-presence rule places it
   always-on with no further reasoning required here.
2. **Three-way MECE against #04 and #05 (Spec R-04).** A defect must
   map to exactly one of resolution / Roadmap-index-consistency /
   translation-parity, one check, and one owner — the same drift mode
   ADR-015 §Decision point 1 and ADR-017 §2 exist to prevent, now on a
   three-detector partition.
3. **Convention-presence keying, never a path allowlist.** The in-scope
   and carve-out rules must be keyed to a structural signal co-located
   with the artifact, never an enumerated allowlist. ADR-017 §4
   explicitly forbids the allowlist anti-pattern ("Enumerating exempt
   filenames in the script is forbidden — it is the
   ad-hoc-allowlist anti-pattern ADR-015's amendment explicitly
   rejected"); this ADR inherits that discipline unchanged.
4. **The boundary is already load-bearing before #06 ships.**
   `check-roadmap-drift.sh` (#05, just shipped this session) already
   excludes `.ja.md` from its reverse-direction scan, citing #06 as the
   contract owner. Its lines 349–357 state verbatim: a `.ja.md` "is a
   DERIVED artifact, not an independent claim-bearer, so it is excluded
   from the reverse-direction scan … EN/JA back-link parity is a
   distinct contract owned by milestone #06 (bilingual parity),
   explicitly a Spec Non-goal here." The three-way partition is in
   force before this detector exists; this ADR records it, it does not
   invent it.

A fifth force is the **#04 dangling-reference detector itself**, now
active CI. This ADR file is in the #04 detector's Check-1 scope; its
mentions of the not-yet-written
`.claude/meta/scripts/check-bilingual-parity.sh` fall under Check 2,
from which ADR files are excluded by the #04 detector's own documented
scope decision (ADR files are historical records; their `.claude/`-
rooted paths are not Check-2-validated). This is treated as an explicit
design input, mirroring how ADR-015, ADR-016, and ADR-017 listed
detector interactions.

## Decision

A bilingual-parity detector is a **single repo-local script at
`.claude/meta/scripts/check-bilingual-parity.sh`**, modeled structurally
on `.claude/meta/scripts/check-dangling-refs.sh` (#04) and
`.claude/meta/scripts/check-roadmap-drift.sh` (#05), run **always-on**
by `.github/workflows/bilingual-parity-check.yml` on every push and
pull request to `main` with no per-fork configuration. The detector
checks exactly the three Spec parity dimensions, scopes itself by the
*presence of the bilingual convention*, normalizes headings by
*level + position only*, and is MECE-bounded against the #04 and #05
detectors by a three-way *contract partition*.

### 1. In-scope tree set — keyed to the presence of the bilingual convention itself

A directory tree is **in-scope for bilingual-parity checking iff it
contains at least one `<name>.ja.md` file**. Parity is keyed to the
*presence of the bilingual convention*, not to an enumerated allowlist
of trees. This is the direct analog of ADR-017 §1's absence-of-claim
exemption applied to a new signal: ADR-017 keys *consistency when a
claim is present, never universality of claims*; this ADR keys *parity
where the bilingual convention is used, never universality of the
convention*. A tree that ships only `.md` files has never made the
bilingual claim and is not in scope — the same discipline as
ADR-015's reservation carve-out ("as wide as the documented
valid-by-design set and no wider") and ADR-017's presence-of-the-claim
keying, applied here to presence-of-a-`.ja.md`.

This rule **supersedes** the Spec's conservative interim default (all
of `.claude/meta/adr/`, `.claude/templates/`, `.claude/agents/`,
`specs/` in-scope; nothing carved out). The Spec explicitly labels that
default a stopgap "until ADR-018 exists"; this is ADR-018, and the
structural rule replaces the enumerated stopgap. Concretely, with
today's repository the convention-presence rule selects the same trees
the stopgap named — but it does so by *reading the artifact*, so a new
bilingual tree (e.g. a future `docs/`) is auto-included the moment its
first `.ja.md` lands, and a tree that drops its last `.ja.md` falls out
automatically, with zero script edit. An enumerated list would fail
open silently on the first (a new bilingual tree never gets checked
until someone remembers to add it) and fail closed noisily on the
second — the exact ad-hoc-allowlist failure mode ADR-017 §4 forbids.

The `workarounds/` registry tree is **out of scope by the Spec's own
Non-goals**, not by a script exception: registry entries are not
bilingual artifacts and carry no `.ja.md` convention, so the
convention-presence rule excludes them without a special case. This is
the rule subsuming a would-be exception, exactly the property
Decision 2 relies on.

### 2. EN-only carve-out — subsumed by Decision 1, no separate signal needed

The Spec asks for an EN-only carve-out rule (a `.md` that legitimately
has no `.ja.md` without being a presence-parity failure), the #06
analog of ADR-017 §1's absence-of-claim exemption. Reasoned through
explicitly: **Decision 1 subsumes it; no separate carve-out signal is
required.**

Two cases exhaust the space:

- **A `.md` in a tree with zero `.ja.md` files.** The tree is not
  in-scope (Decision 1). The detector never evaluates presence-parity
  for it, so its lone-EN status is not a failure — there is nothing to
  carve out, because the tree was never in scope. This is the
  load-bearing simplification: the carve-out is not a second rule, it
  is the *complement* of the in-scope rule.
- **A `.md` in an in-scope tree (the tree has ≥1 `.ja.md` elsewhere)
  with no `.ja.md` of its own.** This **is** a presence-parity failure
  and **must** FAIL (Spec acceptance criterion: "a `.md` file in an
  in-scope tree has no corresponding `.ja.md` counterpart … then it
  fails naming the unpaired `.md` file"). A tree that has adopted the
  bilingual convention is asserting every member is paired; a missing
  pair there is the exact drift this dimension exists to catch.

Therefore the only sanctioned EN-only state is "the whole tree is
EN-only" (Decision 1 excludes it), **not** "this one file is EN-only
inside an otherwise-bilingual tree" — that would be a path-keyed
per-file allowlist, precisely the anti-pattern ADR-017 §4 forbids.
There is no `<!-- en-only -->`-style per-file escape; the
`<!-- ref-allow: -->` line-level hatch (Decision 4) handles genuine
forward-reference edge cases without opening a per-file presence
exemption. This keeps the exemption surface at exactly one rule
(convention-presence), not two, holding the detector-family conceptual
load flat rather than growing it — directly addressing ADR-017's
recorded Negative that "a maintainer must hold N exemption concepts."

### 3. Heading-normalization strategy — compare by (level, position) only

Heading-tree parity compares the EN file's heading sequence against the
JA file's heading sequence by **(heading level, ordinal position)
only**. Heading **text is never compared** — JA heading text is a
translation and will never string-match EN by construction; comparing
text would make every correct translation a false positive. The Spec's
acceptance criteria are written in terms of count and positional order
precisely so that level+position is the satisfying comparison form.

Three structural requirements are fixed; the exact awk/grep form is
`implementer`'s (the Neutral-section discipline ADR-015/016/017 used):

- **Level + position, text ignored.** For each heading the detector
  extracts only its level (count of leading `#`, 1–4 per Spec) and its
  ordinal index in the document. EN heading *i* must have the same
  level as JA heading *i*; the two sequences must have equal length.
  A length mismatch FAILs with the count pair (EN vs JA); an
  equal-length level/position mismatch FAILs naming the first
  mismatched ordinal position. Heading text is read for the failure
  *message* (so the report is human-actionable) but never for the
  *comparison predicate*.
- **Numbered-prefix handling is a non-issue under level+position, and
  is explicitly NOT special-cased.** `## 1. Context` (EN) vs
  `## 1. コンテキスト` (JA) already matches: same level (`##`), same
  ordinal position. The shared digit prefix is irrelevant because text
  is never compared; the differing localized text is irrelevant for
  the same reason. No prefix-stripping normalization is introduced —
  it would be dead code under a text-blind comparison and is forbidden
  as speculative generality (Spec R-03 asked the architect to decide
  *whether* prefix handling is needed; the decision is **no, it is
  not**, because level+position makes it moot).
- **Fenced code blocks are skipped — inherited from #04/#05,
  unmodified.** A ` ``` `-or-`~~~`-delimited block whose content
  contains a `#`-prefixed line is **not** a heading and must not enter
  either sequence. The #04 and #05 detectors already implement
  single-pass fence tracking (`in_fence`/`fence_char` state, both
  ` ``` ` and `~~~`); this detector reuses the identical fence-skip
  discipline so a code sample containing `# foo` never produces a
  phantom heading parity failure. This is a structural requirement,
  not a new mechanism — it is the established #04/#05 fence behavior
  applied to heading extraction.

The full-width-parenthesis dimension (`（` U+FF08 / `）` U+FF09 anywhere
in a `.ja.md`, FAIL with file + line number) is a flat per-line scan of
in-scope `.ja.md` files; it carries no normalization decision and is
recorded here only for completeness — the Spec fully specifies it.

### 4. Parsing-approach constraint (structural requirement, not the bash)

Structural requirements only; the exact bash is `implementer`'s:

- **Single-pass scan with fence-skip.** Heading extraction for each
  file is a single pass that tracks fenced-code state (Decision 3,
  third bullet) — no second read, no fence-unaware grep that would
  mis-extract `#`-lines inside code blocks. This matches the #04/#05
  single-awk-pass structure.
- **`<!-- ref-allow: -->` escape hatch reused UNMODIFIED.** The
  line-level suppression comment from #04/#05 is reused verbatim —
  same token, same per-line semantics, no new escape syntax. A line
  carrying `<!-- ref-allow: -->` is skipped for validation in this
  detector exactly as in #04/#05 (Spec acceptance criterion). No
  `<!-- parity-allow: -->`-style detector-specific variant is
  introduced; one escape vocabulary across all three detectors keeps
  the conceptual load flat (the same reasoning as Decision 2).
- **Standard detector skeleton.** `set -euo pipefail`, repo-root
  resolution via `git rev-parse`, `pass`/`warn`/`fail_check` helpers,
  `fail=0` accumulator, `exit "$fail"` — the reusable shape ADR-015
  §Decision point 3 built and ADR-017 mirrored. No new pattern.

### 5. Three-way MECE scope boundary against #04 and #05

The partition is drawn on **contract**, not file type (all three
checks scan overlapping files — `CLAUDE.md`, ADRs, Specs — so the
ADR-017 §2 contract-partition reasoning extends from two contracts to
three):

| Check | Owns the question | Verb |
|---|---|---|
| #04 `check-dangling-refs.sh` | Does the pointer **resolve** to a real file/ADR? | resolution |
| #05 `check-roadmap-drift.sh` | Does the **bidirectional Roadmap-index contract** hold and is every Status glyph well-formed? | Roadmap-index consistency |
| #06 `check-bilingual-parity.sh` | Does the **EN↔JA pair agree** structurally (heading tree, full-width parens, presence)? | translation parity |

A defect maps to exactly one owner: a *broken pointer* (target absent)
is #04's; a *consistent-pointer-but-inconsistent-Roadmap-contract*
defect is #05's; a *structurally-divergent EN/JA pair* (heading-count
or order mismatch, a full-width paren in a `.ja.md`, or a missing
counterpart in an in-scope tree) is #06's. The Spec R-04 overlap zone —
a `.ja.md` containing a broken `ADR-NNN` reference in heading text — is
**#04's by resolution**; #06 does not validate reference resolution
inside JA files at all, so there is no two-owner ambiguity. The
existing concrete evidence the partition is real: `check-roadmap-drift.sh`
lines 349–357 already exclude `.ja.md` from its reverse-direction scan,
naming "milestone #06 (bilingual parity)" as the contract owner —
the three-way boundary is load-bearing before #06's script exists.

This boundary **must be restated in all three scripts' header comments**
(downstream task) so the three-way partition is discoverable from any
side — the identical reciprocal-note discipline ADR-015 required for
the Check-4 boundary and ADR-017 §2 required for the #04↔#05 boundary
(today `check-dangling-refs.sh` and `check-roadmap-drift.sh` already
carry the reciprocal #04↔#05 note; #06's arrival makes each note a
three-way statement).

This ADR records the decision and the agent-contract / downstream
implications. It does **not** itself write the script, the workflow, or
the tests, and does **not** modify any agent prompt — implementation is
deferred to `implementer` and listed under Consequences → Neutral for
traceability, exactly as ADR-014, ADR-015, ADR-016, and ADR-017 do.
This continues the #03/ADR-016 and #05/ADR-017 two-session
decision-then-implementation split precedent.

## Consequences

### Positive

- The three parity dimensions are verified on every push/PR with zero
  opt-in: an agent or reader can trust that any in-scope JA artifact
  covers the same structural sections, in the same order, as its EN
  canonical. The Spec's headline gap closes.
- **In-scope keying is a pattern-keyed structural rule** (presence of a
  `.ja.md` in the tree), not a maintained allowlist, so it neither
  fails open as new bilingual trees are added nor fails closed when a
  tree drops the convention — the same property ADR-015's amendment and
  ADR-017's absence-of-claim exemption chose over an enumerated list.
- **The EN-only carve-out costs zero new concepts.** It is the logical
  complement of the in-scope rule, not a second rule. The
  detector-family exemption load stays flat rather than growing — a
  direct, deliberate answer to ADR-017's recorded Negative that "a
  maintainer must hold N exemption concepts across the detectors."
- **Text-blind heading comparison eliminates the entire
  translated-text false-positive class** by construction: a correct
  translation can never fail heading parity because text is never the
  predicate. Numbered-prefix handling is proven moot, so no
  speculative normalization code is introduced.
- The three-way MECE-by-contract boundary makes ownership unambiguous
  across the whole detector family: resolution → #04, Roadmap-index
  consistency → #05, translation parity → #06. The ADR-017 §2
  two-contract reasoning extends cleanly to three with no new
  mechanism.
- Infrastructure leverage is fully realized: #04 built the reusable
  detector shape, #05 mirrored it, #06 mirrors it again with no new
  pattern — exactly the "one pattern, three milestones" ADR-015
  §Decision point 3 anticipated, now completed.
- The posture is inherited from an already-decided, auditable rule
  (ADR-015 names #06 explicitly), so the template gains no new ad-hoc
  posture concept — consistent with ADR-016 and ADR-017, which also
  inherit rather than re-derive.

### Negative

- **Convention-presence keying couples the detector to the `.ja.md`
  filename convention.** If the template ever changes its bilingual
  suffix (e.g. `.ja.md` → a locale directory layout), the in-scope rule
  must change with it, and nothing cross-checks the two automatically.
  This is the same acceptable, narrowed coupling ADR-015 took on
  (keyed to ADR-014's `specs/NN-slug.md` shape) and ADR-017 took on
  (keyed to the `<br>`-joined cell and `Roadmap row: #NN` token) —
  recorded as a known maintenance edge keyed to the single narrowest
  surface (the `.ja.md` suffix).
- **An in-scope tree with one legitimately-untranslatable EN-only file
  has no per-file exemption.** Decision 2 deliberately refuses a
  per-file carve-out (it would be the forbidden path allowlist). The
  only sanctioned remedies are: translate the file (the intended
  outcome — the tree asserted the bilingual claim), or, for a genuine
  transient, the line-level `<!-- ref-allow: -->` hatch. This is an
  accepted rigidity: the cost asymmetry (a silently un-paired artifact
  misleads every JA reader every session vs. one translation or one
  suppression comment) runs the same direction ADR-015 and ADR-017
  accepted for their always-on detectors.
- **A third detector joins the family's conceptual load.** The template
  now runs #04 (resolution), #05 (Roadmap-index consistency), #06
  (translation parity), each with a header-documented contract. A
  maintainer must hold a three-way partition. Mitigation: each
  detector's contract is one sentence, the partition is restated in
  all three script headers (downstream task), and #06 deliberately
  adds **zero** new exemption concepts (Decision 2 subsumes the
  carve-out; Decision 4 reuses the #04/#05 escape hatch unmodified) —
  so the partition grew by one *check* but the exemption surface did
  **not** grow, directly bounding the load ADR-017's Negative flagged.
- **Always-on means a false positive blocks CI for the whole repo.**
  Inherited from ADR-015's posture and its accepted mitigation: the
  line-level `<!-- ref-allow: -->` escape hatch (reused unmodified,
  Decision 4) absorbs forward references per-line; scope is
  path-restricted to in-scope bilingual trees plus the script and
  workflow. The cost asymmetry is the one ADR-015 accepted and
  ADR-017 re-accepted.

### Neutral

- This is a **CI-layer addition** in the ADR-015/ADR-017 mold: no agent
  is added or removed; the Spec (Key-interaction 6) states no agent
  prompt change is required by this milestone. Agent count unchanged.
- The Roadmap row #06 `Design source` cell gains an `adr:` link to this
  ADR (performed by this change per ADR-014 write-ownership:
  `architect` adds the `adr:` link, `<br>`-joined after the existing
  reserved `spec:` link, exactly as rows #03/#04/#05 show). No other
  row is touched; no Roadmap format change; the change is index-only
  and does not affect the CLAUDE.md line budget materially (a single
  cell edit).
- The exact awk/grep parsing form, the fence-state mechanics, the
  heading-extraction regex, the full-width-paren scan form, and the
  header-comment wording are `implementer` details; this ADR fixes the
  *in-scope keying, the carve-out subsumption, the normalization form,
  the parsing constraints, and the three-way boundary* — not the bash.
  The same Neutral-section discipline ADR-015/016/017 used.
- Downstream `implementer` tasks (recorded for traceability, **not
  performed by this ADR** — implementation is a future session, per
  the #03/ADR-016 and #05/ADR-017 split precedent):
  - `.claude/meta/scripts/check-bilingual-parity.sh` — author following
    the `check-dangling-refs.sh` / `check-roadmap-drift.sh` structure
    (`set -euo pipefail`, `git rev-parse` root resolution,
    `pass`/`warn`/`fail_check` helpers, `fail=0` accumulator,
    `exit "$fail"`, the line-level `<!-- ref-allow: -->` escape hatch
    reused unmodified, single-pass fence-skip). Implement the three
    checks in sequence: (1) presence-parity across convention-present
    trees (Decision 1; the EN-only carve-out is the rule's complement,
    Decision 2 — no separate signal), (2) heading-tree parity by
    (level, position) only with fenced-code skipped (Decision 3),
    (3) full-width-parenthesis scan of every in-scope `.ja.md`. Include
    a prominent header block documenting (a) the convention-presence
    in-scope rule, (b) the carve-out-is-the-complement reasoning,
    (c) the level+position normalization and why numbered prefixes are
    not special-cased, (d) the three-way MECE-by-contract boundary
    against `check-dangling-refs.sh` and `check-roadmap-drift.sh`, with
    a one-line pointer to this ADR.
  - `.github/workflows/bilingual-parity-check.yml` — author following
    the `dangling-ref-check.yml` / `roadmap-drift-check.yml` structure:
    always-on, `on: push/pull_request` to `main` path-scoped to the
    in-scope bilingual trees plus the script and workflow themselves;
    single `check` job running
    `bash .claude/meta/scripts/check-bilingual-parity.sh`;
    `permissions: contents: read`; `timeout-minutes: 5`; job name
    `bilingual-parity-check`.
  - `.claude/meta/scripts/check-dangling-refs.sh` **and**
    `.claude/meta/scripts/check-roadmap-drift.sh` — update each script's
    MECE-boundary header note from the current two-way (#04↔#05)
    statement to the three-way (#04 / #05 / #06) statement, so the
    full partition is discoverable from every side — the identical
    reciprocal-note discipline ADR-015 required for the Check-4
    boundary and ADR-017 §2 required for the #04↔#05 boundary. (The
    `.ja.md` reverse-scan exclusion in `check-roadmap-drift.sh` lines
    349–357 already names #06; the header note is the reciprocal of
    that already-shipped exclusion.)
  - The TDD suite — author following the
    `test-check-dangling-refs.sh` / `test-check-roadmap-drift.sh`
    convention: fixtures proving heading-count mismatch (EN fewer,
    EN more), positional heading mismatch (same count, different
    order), a full-width paren in a `.ja.md`, a missing JA counterpart
    in an in-scope tree, an orphaned `.ja.md`, a fenced `# foo` not
    counted as a heading, an EN-only tree (zero `.ja.md`) correctly
    *not* failing, and the template's own artifacts passing
    (the Spec's green-by-construction baseline criterion).
  - The Japanese counterpart of this ADR
    (`018-bilingual-parity-detector.ja.md`) is owned by
    `technical-writer`, **not** this task.
- No agent prompt change is introduced or implied. The Spec's
  Key-interaction 6 states the detector is a CI layer only.

## Alternatives considered

| Alternative | Pros | Cons | Why not chosen |
|---|---|---|---|
| **A: Fold bilingual parity into `check-roadmap-drift.sh` or `check-dangling-refs.sh` — one detector family, fewer scripts** | Scans overlapping files (`CLAUDE.md`, ADRs, Specs); #05 already touches `.ja.md` (it excludes them from reverse-scan); one script, one workflow, one owner; reuses the fence-skip and escape-hatch code directly | Conflates a **third distinct contract** (translation parity) with resolution (#04) and Roadmap-index consistency (#05). A parity failure and a resolution/consistency failure reported by one job with one name reproduces the exact "which contract failed?" muddiness ADR-015 §Decision point 1 rejected for Check-4 and ADR-017 §2 rejected for #04↔#05 — now on three contracts; grows a single script past a cohesive size | Rejected on the same MECE / locality-of-behavior grounds ADR-015 rejected its Alternative C and ADR-017 rejected its Alternative A. ADR-017's two-contract reasoning extends directly to three. The Spec scopes #06 as a *distinct* detector (Key-interaction 1–2: author — not extend — the script and workflow). The serious counter (see Counter-proposal); its pros are real but assume one or two contracts where there are three |
| **B: Fold this into an ADR-015 or ADR-017 amendment (no new ADR number)** | The posture half *is* an inherited consequence of ADR-015; fewer ADR numbers; consistent with the "consequence-clarifications fold into amendments" precedent | The posture is inherited, but #06 also introduces a **new detector**, a **new three-way MECE contract boundary**, and **new structural keying** (convention-presence in-scope; carve-out-as-complement; level+position normalization) — the "new structural decision" half of the ECC precedent. ADR-015 and ADR-017 both self-classified the directly analogous case (new detector + new boundary + inheritable rule) as warranting a new ADR | Rejected: the structural half dominates, exactly as it did for ADR-015 and ADR-017. The posture is correctly handled by *inheriting* (referencing ADR-015 §Decision point 3, which names #06), not by amending it |
| **C: Enumerate the in-scope trees as a fixed list in the script (the Spec's interim stopgap, frozen)** | Trivially simple; deterministic; matches the Spec's conservative default exactly | Fails open silently when a new bilingual tree is added (never checked until someone edits the script — the precise ad-hoc-allowlist failure ADR-017 §4 forbids); fails closed when a tree drops its last `.ja.md`; carries per-tree maintenance cost; is the anti-pattern ADR-015's amendment and ADR-017 §4 both explicitly rejected | Rejected: the Spec itself labels the enumerated list a stopgap "until ADR-018 exists." A pattern-keyed structural rule (Decision 1) has neither failure mode and is the discipline the whole detector family already follows |
| **D: New ADR-018 — distinct detector, convention-presence in-scope keying, carve-out subsumed by the in-scope rule, level+position heading normalization, three-way MECE-by-contract against #04/#05, posture inherited from ADR-015 (chosen)** | Closes all three Spec parity dimensions; in-scope rule is pattern-keyed not allowlisted; carve-out adds zero new concepts (it is the in-scope rule's complement); heading comparison is false-positive-free by construction; three-way boundary keeps ownership unambiguous; posture inherited (no re-litigation); reuses the #04/#05 shape | Couples the in-scope rule to the `.ja.md` suffix; no per-file EN-only exemption inside a bilingual tree (deliberate — a per-file allowlist is forbidden); a third detector joins the family's conceptual load (but the exemption surface does not grow) | Chosen: the only option that closes the full Spec scope, draws a defensible three-way MECE boundary, keeps keying principled rather than allowlisted, holds the exemption surface flat, and correctly inherits (not re-decides) the posture |

## Counter-proposal

The serious counter-position is **Alternative A — do not add a separate
detector; fold bilingual parity into `check-roadmap-drift.sh` (or
`check-dangling-refs.sh`): one detector family, fewer scripts**. It is
recorded here per the
ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 precedent of taking a
rejected alternative seriously rather than as a strawman. It is the
direct analogue of ADR-015's Alternative C and ADR-017's Alternative A
(fold the new detector into an existing one). The argument:

1. The candidate host already scans the overlapping files. #05 parses
   `CLAUDE.md` and every ADR; #04 parses those plus Specs and agent
   files. Both already implement single-pass fence tracking and the
   `<!-- ref-allow: -->` escape hatch. Adding "and also compare each
   EN/JA heading sequence" is a few more functions over files the host
   already walks.
2. #05 **already touches `.ja.md`** — it explicitly excludes them from
   its reverse-direction scan (lines 349–357). The detector that
   already has an opinion about `.ja.md` files is the natural place to
   add the rest of the `.ja.md` contract, rather than standing up a
   third script.
3. The Spec's R-04 already concedes the #04↔#06 overlap zone is
   "narrow" and "acceptable." If overlap is acceptable, the simpler
   structure that keeps everything in one or two scripts is arguably
   better than a third script with a third boundary to document.

**Why the counter was not adopted:**

- The decisive issue is **three contracts, not three file sets**.
  ADR-017 §2 already established that when checks scan the same files
  the partition must be drawn on *contract*, not file type, and
  partitioned #04 (resolution) ↔ #05 (Roadmap-index consistency) on
  exactly that basis. #06 adds EN↔JA *translation parity* — a third
  contract answering a third question ("does the pair agree
  structurally?") with a third conceptual owner. ADR-017's
  two-contract reasoning extends directly: folding makes a parity
  failure, a resolution failure, and a consistency failure
  indistinguishable at the job level — the exact "which contract
  failed?" muddiness ADR-015 §Decision point 1 rejected for Check-4
  and ADR-017 §2 rejected for #04↔#05, now reproduced across three
  contracts on the same artifacts.
- #05 touching `.ja.md` is **evidence the boundary is real, not an
  argument to merge**. `check-roadmap-drift.sh` excludes `.ja.md`
  *precisely because* EN/JA parity "is a distinct contract owned by
  milestone #06" (its own comment, lines 349–357). The host detector
  has already drawn the boundary against itself; honoring that boundary
  means a separate #06 detector, not folding #06 back into the script
  that explicitly disclaimed the contract.
- The Spec scopes #06 as a **distinct detector** (Key-interaction 1–2:
  author `check-bilingual-parity.sh` and `bilingual-parity-check.yml`
  *following* — not *extending* — the #04/#05 files) and its Non-goals
  explicitly assign cross-reference resolution in JA files to #04.
  Merging would re-conflate exactly what the Spec separated.
- The R-04 overlap the counter cites as cheap is genuinely cheap and
  signal-positive (a `.ja.md` with a broken `ADR-NNN` ref is #04's by
  resolution; #06 simply does not check JA reference resolution, so
  there is no two-owner ambiguity to eliminate). Paying the much larger
  cost of a three-contract overloaded script to "simplify away" a
  non-problem is the wrong trade — the same locality-of-behavior value
  ADR-012 applied to the dispatcher, ADR-015 to its Alternative C, and
  ADR-017 to its Alternative A.

**Trigger conditions for re-evaluating this counter-proposal:**

- The #04, #05, and #06 detectors prove to share so much parsing code
  (Roadmap-table walking, fence tracking, escape-hatch handling) that
  the duplication cost exceeds the contract-separation benefit — at
  which point a *shared parsing library* sourced by all three scripts
  (not a merged script) is the correct refactor, preserving the
  three-way contract partition while removing duplication. This is the
  same re-evaluation trigger ADR-017 recorded for #04↔#05, now
  three-way.
- The template abandons the `.ja.md` bilingual convention entirely
  (e.g. moves to single-source-with-generated-translation), removing
  the translation-parity contract's subject matter — at which point the
  subject-matter-presence rule itself reclassifies or retires the
  detector.
- The bilingual-parity contract is found to collapse into the
  Roadmap-index-consistency contract (e.g. parity becomes expressible
  purely as a Roadmap bidirectional property) such that one consistency
  detector with sub-checks is genuinely more cohesive than two — a
  deliberate re-evaluation point, not a default. (ADR-017's own
  Counter-proposal flagged exactly this #06 question as a re-evaluation
  trigger; this ADR resolves it: the contracts are distinct, so the
  scripts stay distinct.)

The counter-proposal stays in this ADR as the historical record of the
decision's most serious objection, per the
ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 convention.

## References

- ADR-015 (Dangling-Reference Detector) — §Decision point 3 fixes this
  milestone's always-on posture as **inherited, not re-litigated** and
  **names #06 explicitly** ("Roadmap drift and EN/JA parity are also
  always-present structural contracts, so the rule fixes their posture
  too"); §Decision point 1 and its amendment establish the
  pattern-keyed-not-allowlisted discipline this ADR's convention-presence
  keying applies; ADR-015 is also the precedent for classifying "new
  detector + new boundary + inheritable rule" as a new ADR rather than
  an amendment.
- ADR-017 (Roadmap drift-detection CI) — the immediately preceding ADR
  and the exact house style this ADR mirrors (Status / Context /
  Decision / Consequences[Positive/Negative/Neutral] / Alternatives
  considered / Counter-proposal / References); §2's MECE-by-contract
  partition is the two-contract precedent this ADR extends to three;
  §3's "posture inherited, explicitly not re-litigated" is the
  discipline copied here; §4's Neutral-section "constraints not bash"
  and forbidden-allowlist rules are inherited unchanged; ADR-017's
  Counter-proposal explicitly flagged the #06-folds-into-#05 question
  as a re-evaluation trigger, which this ADR resolves.
- ADR-016 (Cross-session progress persistence) — the #03 precedent for
  the two-session decision-then-implementation split this ADR follows
  (record the decision + downstream tasks; implementation deferred).
- ADR-012 (Code Reviewer as Dispatcher) — precedent for recording a
  counter-proposal raised and rejected with real pros and explicit
  re-evaluation triggers; the locality-of-behavior / separation-of-
  concerns value applied here to reject the merged-detector counter.
- ADR-014 (Roadmap Index as the Single Entry Point) — defines the
  Roadmap index this ADR's row #06 `adr:` link is added to; this ADR
  follows ADR-014's "record the decision + downstream tasks, do not
  perform them" shape and its write-ownership model (`architect` adds
  the row's `adr:` link).
- `specs/06-bilingual-parity-detector.md` — the authoritative scope of
  this milestone (the three parity dimensions, the 11 acceptance
  criteria, the Non-goals); this ADR records the structural *how/why*
  for the keying, carve-out, normalization, and parsing constraints the
  Spec defers (R-01, R-03, R-04, Key-interaction 5); the Spec owns the
  *what*.
- `specs/04-dangling-reference-detector.md` /
  `.claude/meta/scripts/check-dangling-refs.sh` /
  `.github/workflows/dangling-ref-check.yml` — the #04 structural
  sibling and one of the two reusable detector/workflow/test shapes
  this milestone mirrors; a three-way MECE-by-contract boundary partner.
- `specs/05-roadmap-drift-detection-ci.md` /
  `.claude/meta/scripts/check-roadmap-drift.sh` /
  `.github/workflows/roadmap-drift-check.yml` — the #05 structural
  sibling and the other reusable shape this milestone mirrors; its
  `.ja.md` reverse-scan exclusion (lines 349–357), citing #06 as the
  contract owner, is the concrete proof the three-way boundary is
  load-bearing before #06 ships; a three-way MECE-by-contract boundary
  partner.
- The Japanese counterpart
  (`018-bilingual-parity-detector.ja.md`) is owned by
  `technical-writer`, not part of this change.
- Roadmap row: #06
