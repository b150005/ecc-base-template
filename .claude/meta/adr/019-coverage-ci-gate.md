# ADR-019: CI coverage gate (80% hard check) — pre-computed-percentage input, default-off single-switch posture, single-source-of-truth threshold binding, new MECE partition not pre-reserved by ADR-014 §(d)

## Status

Accepted — 2026-05-18

## Context

The template's `.claude/CLAUDE.md` `## Testing Requirements` section
states "Minimum 80% test coverage" as a written rule. No CI job enforces
it. `.github/workflows/ci-base.yml` accepts a `test-command` input from
derived repositories and runs their tests, but imposes no threshold,
emits no coverage metric, and does not fail the build when coverage
falls below 80%. A derived repo can ship with 10% coverage and pass CI
today. `specs/12-coverage-ci-gate.md` is the authoritative scope — the
eight acceptance criteria, the four risks, and the Non-goals. This ADR
records the **structural** decisions the Spec explicitly defers to
`architect` (Spec Risk R-01 (a)–(e), R-02, R-03, R-04, Key-interaction
6): the CI structural form, the activation posture and its
single-point-of-control mechanism, the threshold single-source-of-truth
binding, the language-agnostic forkability input contract, and the
new-ADR-vs-amendment decision. The Spec names this decision ADR-019 and
hands the discriminator to the architect verbatim; this ADR closes it.

This milestone is **not** a fourth detector. #04
(`check-dangling-refs.sh`, ADR-015) owns cross-reference *resolution*.
#05 (`check-roadmap-drift.sh`, ADR-017) owns Roadmap *index
consistency*. #06 (`check-bilingual-parity.sh`, ADR-018) owns EN↔JA
*translation parity*. None of the three — nor #11's
documentation/convention guidance — owns a *coverage-threshold
enforcement at CI time* contract. #12 introduces that contract as a new
partition. The same reasoning ADR-017 §2 and ADR-018 §5 used to draw
MECE-by-contract boundaries among checks that scan overlapping files
applies here at the partition level: #12's check scans a *different
input entirely* (a derived repo's already-computed coverage percentage,
not the repository's Markdown artifacts), so the boundary is even
cleaner than the #04/#05/#06 three-way contract partition — there is no
shared artifact to disambiguate.

Five hard constraints bound the design and are non-negotiable:

1. **The template has no application code (Spec R-03, AC-5).** The
   template repository's only executable artifacts are the bash detector
   scripts and their test suites; there is no application coverage to
   measure. Any coverage gate authored here is a **forkable scaffold**,
   not a check run against the template's own bash — exactly the
   structural posture `ci-base.yml` (parameterized `workflow_call`) and
   `workaround-check.yml` (default-off single-switch scaffold) already
   occupy. The gate **must** be green-by-construction or correctly inert
   for the template itself, with no coverage exemption and no
   `ref-allow`-style suppression required to stay green.
2. **Single source of truth for the 80% number (Spec R-02, AC-2,
   AC-8).** The canonical declaration is `.claude/CLAUDE.md`
   `## Testing Requirements` ("Minimum 80% test coverage"). The scaffold
   **must not** introduce a second, competing numeric literal that can
   drift from the canonical declaration. A future change to the
   threshold must require editing exactly one location.
3. **Language-agnostic forkability (Spec R-04, AC-3).** Coverage output
   formats vary by language and toolchain (`coverage.py` XML, Go
   `coverprofile`, `lcov.info`, JaCoCo XML, `llvm-cov`, Swift JSON, …).
   The template **must not** parse N formats. The derived repo supplies
   its own already-computed coverage percentage, mirroring
   `ci-base.yml`'s `workflow_call` `test-command` input pattern.
4. **`ci-base.yml`'s `test-command` contract is unchanged (Spec
   Key-interaction 1).** The existing `test-command` input and its
   no-threshold behavior **must** remain identical for derived repos
   that have not opted into the coverage gate. The gate is additive, not
   a modification of the run-tests contract.
5. **No scope bleed into the existing detector layer (Spec AC-6,
   Key-interaction 5).** The four detector scripts
   (`check-dangling-refs.sh`, `check-roadmap-drift.sh`,
   `check-skill-invariants.sh`, `check-bilingual-parity.sh`) and their
   three test suites are **not** modified by this milestone.

A sixth force is the **ADR-018 Alternative-B discriminator itself**,
handed to the architect by Spec R-01 and Key-interaction 6. ADR-018's
Alternatives table row B classifies "fold into an existing ADR's
amendment" against "new ADR" by a three-part test: a milestone that
introduces a **new detector/CI hard-check + a new MECE contract
boundary + new structural keying** is the "new structural decision"
half of the ECC precedent and warrants a new ADR, exactly as ADR-015,
ADR-017, and ADR-018 each self-classified. This ADR records the
application of that discriminator (Decision 5) as the citable home for
the decision; the rejected counter's correct state is non-existence
(see Counter-proposal).

A seventh force is the **#04 dangling-reference detector itself**, now
active CI. This ADR file is in the #04 detector's Check-1 scope; its
mentions of the then-not-yet-written
`.github/workflows/coverage-gate.yml`
and a possible `.claude/meta/scripts/` coverage-threshold helper fall
under Check 2, from which ADR files are excluded by the #04 detector's
own documented scope decision (ADR files are historical records; their
`.claude/`-rooted paths are not Check-2-validated). This is treated as
an explicit design input, mirroring how ADR-015, ADR-016, ADR-017, and
ADR-018 listed detector interactions.

## Decision

The coverage gate is a **single standalone, forkable workflow at
`.github/workflows/coverage-gate.yml`**,
authored *alongside* — **not** as a modification of —
`.github/workflows/ci-base.yml`, run **default-off behind a single
switch** so the template's own CI is inert-green by default and a
derived repo opts in with exactly one change. It accepts the derived
repo's **already-computed coverage percentage** as a `workflow_call`
input (the template parses no coverage format), fails the build with a
non-zero exit and a human-readable message naming both the measured
coverage and the threshold when coverage is below the threshold, and
**references the 80% number from the single canonical source rather than
re-declaring it**. It introduces a **new MECE partition** —
coverage-threshold enforcement at CI time — that ADR-014's §(d) MECE
table (at approximately line 1800; it names #04/#05/#09/#10/#11, **not**
#12) does **not** pre-reserve, which is why this is a **new ADR-019**,
not an ADR-014 amendment and not an ADR-010 amendment.

This ADR was authored as a **design-only** record first. The actual
workflow file, the activation config artifact, the threshold-extraction
mechanism, the green-by-construction template guarantee, and the tests
were **landed in a subsequent implementation session** — the deliberate
two-session split that #03/ADR-016, #05/ADR-017, and #06/ADR-018 each
followed (decision-then-implementation), and the **opposite** of a
single-session collapse. The Status moved **Proposed → Accepted** when
that implementation session shipped the artifacts and the quality gate
passed green: the decision was recorded first, then verified by a
faithful implementation.

### 1. CI structural form — a standalone forkable workflow, not a `ci-base.yml` modification

The gate ships as its own file,
`.github/workflows/coverage-gate.yml`,
exposing a `workflow_call` interface, the same way
`roadmap-drift-check.yml` and `workaround-check.yml` ship as their own
files rather than as steps grafted into another workflow. It is **not**
an edit to `ci-base.yml`.

The reasoning is the locality-of-behavior / one-contract-one-owner
discipline ADR-017 §2 applied to the #04↔#05 boundary and ADR-018 §5
extended to three: `ci-base.yml` owns one contract — "run the derived
repo's `test-command`." A coverage gate owns a *different* contract —
"is the resulting coverage at or above the threshold?" Folding the
threshold check into `ci-base.yml` would put two contracts on one job
with one name, reproducing the exact "which contract failed?" muddiness
ADR-017 §2 rejected for the Check-4 case and ADR-018 §5 rejected for the
three-way detector partition. It would also force every derived repo
that uses `ci-base.yml` for its no-threshold test run to inherit a
threshold opinion it did not opt into, breaking hard constraint 4 (Spec
Key-interaction 1: the `test-command` behavior must remain unchanged for
non-opted-in repos). A standalone `workflow_call` file keeps the two
contracts in two files with two owners and leaves `ci-base.yml`
byte-unchanged.

A small threshold-extraction helper under `.claude/meta/scripts/` is
**permitted but not mandated** by this design — whether the 80%
single-source binding (Decision 3) is realized by an inline workflow
step or a tiny sourced helper is an `implementer` detail, recorded under
Consequences → Neutral, not fixed here. If a helper is authored its path
is `implementer`'s to choose under the existing
`.claude/meta/scripts/check-*.sh` naming family; this ADR fixes that the
template parses **no coverage report format** (Decision 4), not the bash.

### 2. Activation posture — default-off single-switch, the `workaround-check.yml` precedent

The Spec (R-01, Key-interaction 2/3, AC-4) names three candidate
postures and asks the architect to choose one and justify it against
the three precedents:

- **always-on** (ADR-015 subject-matter-presence rule, as
  `roadmap-drift-check.yml`),
- **default-off-single-switch** (`workaround-check.yml`: `enabled: true`
  in a tracker YAML),
- **repository-variable-gated** (CodeQL #02: `CODEQL_ENABLED=true`).

**Chosen: default-off single-switch**, the direct analog of
`workaround-check.yml`. The decisive discriminator is hard constraint 1
(Spec R-03/AC-5): the template repository has **no application code and
no coverage to measure**. The ADR-015 subject-matter-presence rule
places a check always-on **iff its subject matter is an
always-present structural contract in every fork** — Roadmap drift and
EN/JA parity qualify because the Roadmap and the bilingual artifacts
exist in the template itself. Application-code coverage is the opposite:
it is **absent** from the template by construction and present only once
a derived repo adds application code. Always-on therefore fails the
subject-matter-presence test for this milestone — the subject matter is
not present in the template — and would require the gate to detect "no
coverage artifacts" and exit zero, i.e. carry a template-specific
inert-path special case purely to stay green. Default-off removes the
need for that special case entirely: with the switch off, the job does
not run against the template at all, so AC-5 ("no new failing job …
must not require a coverage exemption or a `ref-allow`-style
suppression") is satisfied **by construction**, not by an inert-detection
branch.

Default-off-single-switch is preferred over repository-variable-gated
(CodeQL #02) on the single-point-of-control criterion (AC-4): a
repository variable lives in GitHub Settings UI, *off* the file tree,
invisible to a reviewer reading the repo and not diffable in a PR. The
`workaround-check.yml` precedent keeps the switch **in the repository,
in one file, one key** — diffable, reviewable, greppable — which is the
stronger realization of AC-4's "documented in exactly one place and
toggled by exactly one change." CodeQL #02's repository-variable posture
is correct for CodeQL because CodeQL is a GitHub-platform security
feature whose natural control plane is GitHub Settings; a coverage
threshold is a repository-policy decision whose natural home is the
repository.

**The single point of control** is exactly one key in one
in-repository activation config file (the `workaround-check.yml` /
`.github/workaround-tracker.yml` shape: a single `enabled: true`
boolean), read by the workflow at CI runtime. There is **no second
`if: false` guard in the workflow body, no second config key, no
repository variable** — one switch, one location, the AC-4 / ADR-002
single-switch discipline. The exact filename of the activation config
and the YAML key name are `implementer` details under Decision 1's
family conventions; this ADR fixes the *posture* (default-off) and the
*single-point-of-control invariant* (exactly one boolean, in-repository,
diffable), not the bash or the filename.

### 3. Single source of truth — the 80% number is referenced, never re-declared

The canonical declaration of the threshold is, and remains,
`.claude/CLAUDE.md` `## Testing Requirements` — the literal line
"Minimum 80% test coverage" (Spec R-02, AC-2, AC-8; hard constraint 2).
The scaffold **must not** hardcode a second `80` numeric literal that
can drift.

The structural requirement fixed here (the exact awk/grep is
`implementer`'s, the Neutral-section discipline ADR-015/016/017/018
used): the enforced threshold is **derived at CI runtime by reading the
canonical line out of `.claude/CLAUDE.md` `## Testing Requirements`**,
not written as an independent literal in the workflow or any config
file. Concretely, the workflow (or a tiny sourced helper, Decision 1)
extracts the integer from the `## Testing Requirements` "Minimum NN%
test coverage" line and compares the derived repo's supplied coverage
percentage against *that* extracted value. The activation config file
(Decision 2) carries the **on/off switch only** — it deliberately does
**not** carry the number, because a number in the config file would be
the exact second drifting declaration R-02 forbids. A future threshold
change (80 → 85) is then a one-line edit to `## Testing Requirements`
and nothing else; the CI enforcement tracks it automatically with zero
second edit. This is the same "key the rule to the artifact, read it
from the artifact" discipline ADR-017 §4 mandated for the
absence-of-claim exemption and ADR-018 §1 mandated for convention-presence
keying — applied here to the threshold value.

If the extraction cannot find the canonical line (e.g. a fork deleted
`## Testing Requirements`), the gate **fails closed with an explicit
message** ("canonical 80% declaration not found in
`.claude/CLAUDE.md` `## Testing Requirements`"), not silently passes —
the same fail-closed direction the detector family takes, so a removed
contract is loud, not invisible. (This couples the extractor to the
`## Testing Requirements` line shape; that coupling is recorded under
Consequences → Negative, narrowed to the single canonical line.)

### 4. Language-agnostic forkability — pre-computed percentage as a `workflow_call` input

The scaffold accepts the derived repo's **already-computed coverage
percentage** as a `workflow_call` input (Spec R-04, AC-3; hard
constraint 3), mirroring `ci-base.yml`'s `workflow_call` `test-command`
input pattern. The derived repo runs its own language-specific coverage
tool in its own job, computes a single project-level percentage by
whatever means is native to its toolchain (`coverage.py`, `go tool
cover`, `lcov`, JaCoCo, `llvm-cov`, …), and passes that **number** in.
The template-owned workflow parses **no coverage report format** — it
receives an integer/decimal percentage and a threshold (Decision 3) and
performs one numeric comparison.

The input contract fixed here (the exact input name/type is
`implementer`'s): one required `workflow_call` input carrying the
measured coverage percentage as a number, supplied by the caller; the
threshold is **not** a caller input (it comes from the canonical source,
Decision 3) so a caller cannot weaken the gate by passing a low
threshold. This keeps the template free of every coverage-format parser
(the forkability goal Spec R-04 protects) and keeps the threshold
authority on the template side (the single-source goal Spec R-02
protects) — the two constraints are satisfied by the same input-shape
decision: caller supplies the *measurement*, template owns the
*threshold*.

### 5. MECE boundary — a new partition ADR-014 §(d) does not pre-reserve

#12/ADR-019 owns the question **"Does the project's test coverage meet
the 80% minimum, enforced at CI time?"** This is a **new partition**,
distinct from every existing owned question:

| Owner | Owns the question | Input scanned |
|---|---|---|
| #04 `check-dangling-refs.sh` (ADR-015) | Does a prose/path reference **resolve** to a real file/ADR? | repository Markdown artifacts |
| #05 `check-roadmap-drift.sh` (ADR-017) | Does the **bidirectional Roadmap-index contract** hold and is every Status glyph well-formed? | `.claude/CLAUDE.md` + ADRs |
| #06 `check-bilingual-parity.sh` (ADR-018) | Does the **EN↔JA pair agree** structurally (heading tree, full-width parens, presence)? | paired `.md`/`.ja.md` artifacts |
| #11 (verification-domain opt-in guidance, ADR-014 §(d)) | Under what project characteristics should a fork **enable** the implementation/design verification domain? | documentation/convention (no detector) |
| **#12 `coverage-gate.yml` (ADR-019)** | **Does the project's test coverage meet the 80% minimum, enforced at CI time?** | **the derived repo's already-computed coverage percentage** |

A defect maps to exactly one owner: a *broken pointer* is #04's; a
*Roadmap-index inconsistency* is #05's; a *structurally-divergent EN/JA
pair* is #06's; a *verification-domain enablement guidance question* is
#11's documentation concern; a *coverage below threshold at CI time* is
#12's and **only** #12's. The boundary here is even cleaner than the
#04/#05/#06 three-way contract partition (ADR-018 §5): those three scan
overlapping Markdown artifacts and the partition had to be drawn on
*contract* to disambiguate; #12 scans a **wholly different input** (a
runtime-supplied coverage number, not any repository artifact), so there
is no shared surface to disambiguate at all — the partition is by
*input* **and** *contract*.

**Why this is a new ADR, not an ADR-014 amendment (the ADR-018
Alternative-B discriminator applied).** ADR-018's Alternatives table row
B test: a milestone introducing a **new CI hard-check + a new MECE
contract boundary + new structural keying** is the "new structural
decision" half of the ECC precedent and warrants a new ADR; only a
milestone that *populates a slot a prior ADR already reserved* folds
into that ADR's amendment trail. The discriminator triad for #12 is
**3/3**:

1. **New CI hard-check** — `coverage-gate.yml`;
   no existing workflow gates on a coverage threshold (`ci-base.yml`
   runs tests with **no** threshold; the four detectors check Markdown
   contracts, not coverage).
2. **New MECE contract boundary not pre-reserved** — ADR-014's §(d)
   MECE table (≈ line 1800) enumerates #04/#05/#09/#10/#11; it does
   **not** name #12. #12 occupies **no pre-reserved slot**. This is the
   decisive distinction from #11, which *populated a slot ADR-014 §(d)
   had already reserved* and therefore correctly took an ADR-014
   amendment, consuming **no** new ADR number. #12 has no such reserved
   slot, so it is structurally a new partition, not the population of an
   existing one.
3. **New structural keying** — the 80%-threshold value, its
   single-source-of-truth binding to `.claude/CLAUDE.md`
   `## Testing Requirements` (Decision 3), and the default-off
   single-switch activation-posture mechanism (Decision 2). None of
   these keying decisions exists in any prior ADR.

Triad 3/3 ⇒ **new ADR-019**, exactly the #04/#05/#06 precedent: each of
those introduced a new detector + a new boundary + new keying and each
received a *new* ADR (ADR-015 / ADR-017 / ADR-018), while #07–#11 — each
of which *populated a pre-reserved ADR-014 §(d) slot* — were ADR-014
*amendments* consuming no new number. 019 is the next unused number
(016/017/018 consumed). The structural half of the ECC precedent
dominates exactly as ADR-015 §self-classification, ADR-017 Alternative
B, and ADR-018 Alternative B each recorded.

This ADR records the decision and the agent-contract / downstream
implications. It did **not** itself write the workflow, the activation
config, the threshold-extraction mechanism, or the tests, and did
**not** modify any agent prompt, the Spec, any template, any other ADR,
the CHANGELOG, or any CI/script file — implementation was deferred to a
subsequent session and listed under Consequences → Neutral for
traceability, exactly as ADR-014, ADR-015, ADR-016, ADR-017, and
ADR-018 do. This continues the #03/ADR-016, #05/ADR-017, #06/ADR-018
two-session decision-then-implementation split precedent and was the
deliberate opposite of a single-session collapse.

## Consequences

### Positive

- The written "Minimum 80% test coverage" rule in `## Testing
  Requirements` becomes an **enforceable build-failing contract** for
  derived repos that opt in, not a suggestion — the Spec's headline gap
  closes.
- **The threshold has exactly one canonical home.** Decision 3 reads
  the number out of `.claude/CLAUDE.md` `## Testing Requirements` at CI
  runtime; the activation config carries the on/off switch only, never
  the number. A future threshold change is a one-line edit in one file
  with zero risk of CI/doc drift — the AC-2/AC-8/R-02 single-source
  guarantee, realized by the same "read the rule from the artifact"
  discipline ADR-017 §4 and ADR-018 §1 use.
- **The template is green-by-construction with no special case.**
  Default-off (Decision 2) means the job does not run against the
  template at all; AC-5 is satisfied structurally, with **no**
  inert-detection branch, **no** coverage exemption, and **no**
  `ref-allow`-style suppression — the cleanest possible satisfaction of
  Spec R-03/AC-5.
- **Language-agnostic by input shape.** The template parses no coverage
  format (Decision 4); a derived repo supplies a pre-computed
  percentage, mirroring `ci-base.yml`'s `test-command` input. Any
  language/toolchain wires in with zero template-owned logic change —
  the AC-3/R-04 forkability guarantee.
- **`ci-base.yml` is byte-unchanged.** The standalone-file decision
  (Decision 1) leaves the existing `test-command` contract identical for
  non-opted-in repos — hard constraint 4 / Spec Key-interaction 1
  satisfied by construction.
- **The MECE partition is the cleanest in the family.** #12 scans a
  wholly different input (a runtime number, not any repository
  artifact), so the boundary against #04/#05/#06/#11 is unambiguous by
  input *and* contract — no shared-surface disambiguation needed
  (Decision 5; Spec AC-6/AC-7).
- **Single-point-of-control is in-repository and diffable.** Choosing
  the `workaround-check.yml` switch shape over the CodeQL
  repository-variable shape keeps the activation control greppable,
  reviewable, and PR-diffable — the stronger realization of AC-4.

### Negative

- **The threshold extractor couples to the `## Testing Requirements`
  line shape.** Decision 3 reads "Minimum NN% test coverage" out of
  `.claude/CLAUDE.md`. If that section's wording changes, the extractor
  must change with it, and nothing cross-checks the two automatically.
  This is the same acceptable, narrowed coupling ADR-015 took on (keyed
  to `specs/NN-slug.md`), ADR-017 took on (keyed to the `<br>`-joined
  cell and `Roadmap row: #NN` token), and ADR-018 took on (keyed to the
  `.ja.md` suffix) — recorded as a known maintenance edge keyed to the
  single narrowest surface (one canonical line). Mitigation: the
  extractor fails **closed** with an explicit message if the line is
  absent (Decision 3), so the coupling breaks loudly, never silently.
- **Default-off means an unconfigured fork enforces nothing.** A
  derived repo that never flips the switch ships with the gate inert —
  the same accepted property `workaround-check.yml` carries. This is the
  deliberate cost of hard constraint 1 (the template cannot be
  always-on because it has no coverage subject matter); the mitigation
  is one documented activation step (the AC-4 single switch) and the
  cost asymmetry runs the intended direction: an un-opted-in fork is the
  fork maintainer's explicit choice, whereas an always-on gate would
  break the template's own CI on day one for zero benefit.
- **A new partition joins the conceptual map.** The template's CI
  surface now carries #04 (resolution), #05 (Roadmap-index
  consistency), #06 (translation parity), and #12 (coverage-threshold
  enforcement). A maintainer must hold one more boundary. Mitigation:
  #12's input is wholly disjoint from the other three (a runtime number
  vs. repository Markdown), so the partition is the *easiest* in the
  family to keep straight — there is no overlap zone to reason about,
  unlike the deliberate #04↔#05 absent-`adr:` overlap ADR-017 had to
  document.
- **Implementation was deferred across one session boundary.** Between
  this ADR's design commit and the implementation session that shipped
  `coverage-gate.yml` and the activation config, the "80% rule exists in
  writing, is not enforced by CI" state was the operating reality (Spec
  R-01 closing sentence). That was the accepted, deliberate cost of the
  two-session split, identical to the #03/ADR-016, #05/ADR-017,
  #06/ADR-018 precedent — design correctness was verified before
  implementation began, and the gap is now closed.

### Neutral

- This is a **CI-layer addition** in the ADR-015/ADR-017/ADR-018 mold:
  no agent is added or removed; the Spec (Key-interaction 5/6) states no
  agent prompt change is required. Agent count unchanged.
- The Roadmap row #12 `Design source` cell gained an `adr:` link to this
  ADR (performed by the design session per ADR-014 write-ownership:
  `architect` adds the `adr:` link, `<br>`-joined after the existing
  reserved `spec:` link, exactly as rows #03/#04/#05/#06 show). The row
  Status glyph was `◐ in-progress` at design time — this was a
  two-session split; the glyph flips to `☑` at implementation
  completion, when the quality gate passes. No other row is touched; no
  Roadmap format change; the change is index-only (a single cell edit).
- The exact `workflow_call` input name/type, the threshold-extraction
  awk/grep form, whether a sourced `.claude/meta/scripts/` helper is
  used or the logic is inline, the activation config filename and YAML
  key name, the job name, and the path-scoping are `implementer`
  details; this ADR fixes the *structural form* (standalone file), the
  *posture* (default-off single-switch), the *single-source binding*
  (read from `## Testing Requirements`, switch carries no number), the
  *input contract* (caller supplies measurement, template owns
  threshold), and the *MECE partition* — not the bash. The same
  Neutral-section discipline ADR-015/016/017/018 used.
- Downstream `implementer` tasks (recorded for traceability at design
  time; **performed in the subsequent implementation session** per the
  #03/ADR-016, #05/ADR-017, #06/ADR-018 two-session split precedent —
  the deliberate opposite of a same-session implementation):
  - `.github/workflows/coverage-gate.yml` —
    authored following the `workaround-check.yml` default-off structure
    and the `ci-base.yml` `workflow_call` input shape: a `workflow_call`
    workflow with one required input (the caller's already-computed
    coverage percentage, Decision 4), gated default-off behind one
    in-repository switch (Decision 2), deriving the threshold by reading
    `## Testing Requirements` from `.claude/CLAUDE.md` at runtime
    (Decision 3), failing with a non-zero exit and a message naming both
    the measured coverage and the threshold when below it (Spec AC-1),
    `permissions: contents: read`, `timeout-minutes: 5`, a
    deterministic job name signalling a coverage failure
    unambiguously (Spec AC-1, target-users orchestrator/test-runner).
  - The single in-repository activation config artifact carrying exactly
    one `enabled`-style boolean and **no threshold number** (Decision
    2/3), in the `workaround-check.yml` / `.github/workaround-tracker.yml`
    single-switch shape; filename/key `implementer`'s under the existing
    family conventions.
  - An optional tiny threshold-extraction helper under
    `.claude/meta/scripts/` *iff* the implementer judges an inline step
    insufficient (Decision 1) — its presence and path are
    `implementer`'s; this ADR neither mandates nor forbids it.
  - The test(s) — author following the `test-check-*.sh` convention:
    fixtures proving (a) coverage below threshold FAILs naming measured
    + threshold, (b) coverage at/above threshold passes, (c) the switch
    off makes the job inert (template green-by-construction, Spec AC-5),
    (d) a missing `## Testing Requirements` canonical line fails closed
    (Decision 3), (e) the threshold tracks a changed
    `## Testing Requirements` value with no second edit (Spec AC-2/AC-8),
    and (f) `ci-base.yml` and the four detector scripts + three test
    suites are byte-unchanged (Spec AC-6).
  - The Japanese counterpart of this ADR
    (`019-coverage-ci-gate.ja.md`) is authored by `architect` **in this
    same session** (the new-ADR JA mirror is the architect's, not
    deferred to `technical-writer`), exactly as ADR-017 and ADR-018's
    JA siblings were produced with their EN originals; heading-tree
    parity (level + position) is required and verified this session.
- No agent prompt change is introduced or implied. The Spec's
  Key-interaction 5/6 states the gate is a CI layer only.

## Alternatives considered

| Alternative | Pros | Cons | Why not chosen |
|---|---|---|---|
| **A: Extend `ci-base.yml` with a `coverage-threshold` input and a coverage step — one workflow, one owner** | One workflow, one file; `ci-base.yml` already runs the derived repo's tests so the coverage number is "right there"; no new workflow file to maintain; fewer moving parts | Conflates two **different contracts** on one job with one name: "run the tests" (the existing, opt-in-free `test-command` contract) vs. "is coverage at/above threshold?" — the exact "which contract failed?" muddiness ADR-017 §2 rejected for Check-4 and ADR-018 §5 rejected for the three-way detector partition; **breaks Spec Key-interaction 1 / hard constraint 4** by forcing every non-opted-in `ci-base.yml` caller to inherit a threshold opinion; makes default-off harder (the test run must stay always-on while only the threshold half is opt-in, i.e. an `if:` guard *inside* the shared job — the second-guard anti-pattern AC-4 forbids) | Rejected on the same MECE / locality-of-behavior grounds ADR-015 rejected its Alternative C, ADR-017 rejected its Alternative A, and ADR-018 rejected its Alternative A. The serious counter (see Counter-proposal); its pros are real but assume one contract where there are two, and it cannot satisfy Key-interaction 1 + AC-4 simultaneously |
| **B: Fold the coverage gate into an ADR-014 amendment / an ADR-010 amendment (no new ADR number)** | Fewer ADR numbers; consistent with the ECC "consequence-clarifications fold into amendments" precedent; #07–#11 were all ADR-014 amendments, so an amendment is the recent house pattern | The ADR-018 Alternative-B discriminator triad is **3/3**: new CI hard-check + new MECE boundary **not pre-reserved by ADR-014 §(d)** + new structural keying (the 80% value, its single-source binding, the activation posture). ADR-014 §(d)'s MECE table names #04/#05/#09/#10/#11 — **not** #12; #12 populates **no** pre-reserved slot, the decisive distinction from #11 (which *did* populate a reserved §(d) slot and thus correctly took an amendment). ADR-015/ADR-017/ADR-018 each self-classified the directly analogous case (new check + new boundary + new keying) as warranting a new ADR. Burying a new partition inside another ADR's amendment trail hides a structural decision | Rejected: the structural half of the ECC precedent dominates, exactly as it did for ADR-015/ADR-017/ADR-018. #11 took an amendment **because** it populated a pre-reserved §(d) slot; #12 has no such slot, so it is a new partition warranting ADR-019. This is the recorded application of the discriminator the Spec handed the architect (R-01, Key-interaction 6) |
| **C: Always-on posture (ADR-015 subject-matter-presence rule), with an inert-detection branch to keep the template green** | Symmetric with #05/#06 (the always-on detectors); a fork gets coverage enforcement with zero activation step; one fewer config artifact | Application coverage is **not** an always-present structural contract in the template (hard constraint 1 / Spec R-03) — the subject-matter-presence rule's own predicate ("the subject matter exists in every fork") **fails** for coverage, unlike Roadmap drift / EN-JA parity whose subject matter *is* in the template. Always-on would force a template-specific "no coverage artifacts → exit 0" inert branch purely to satisfy AC-5 — a special case default-off removes entirely; AC-5 explicitly disallows needing a suppression to stay green | Rejected: the subject-matter-presence rule itself classifies this milestone as **not** always-on (its subject matter is absent from the template by construction), the opposite of #05/#06. Default-off satisfies AC-5 structurally with no inert branch — strictly simpler and the posture the Spec's Key-interaction 2 names as the closest precedent |
| **D: Repository-variable-gated posture (CodeQL #02, `COVERAGE_GATE_ENABLED=true`)** | Exact precedent exists (#02); zero in-repo config file; activation is a GitHub Settings toggle | The switch lives in GitHub Settings UI, **off the file tree**: not greppable, not PR-diffable, invisible to a reviewer reading the repo — a weaker realization of AC-4's "documented in exactly one place, toggled by exactly one change." CodeQL's repo-variable posture fits CodeQL because it is a GitHub-platform security feature; a coverage threshold is a repository-policy decision whose natural control plane is the repository | Rejected in favor of the in-repository single switch (Alternative E / Decision 2): both are single-point-of-control, but the `workaround-check.yml` in-repo switch is diffable and reviewable, the stronger AC-4 realization. Recorded as a viable posture a fork may still prefer, but not the template default |
| **E: New ADR-019 — standalone forkable workflow, default-off single-switch, pre-computed-percentage input, threshold read from `## Testing Requirements`, new MECE partition not pre-reserved by ADR-014 §(d) (chosen)** | Closes the Spec gap; `ci-base.yml` byte-unchanged (Key-interaction 1); template green-by-construction with no special case (AC-5); language-agnostic by input shape (AC-3); single-source threshold with zero drift surface (AC-2/AC-8); in-repo diffable single switch (AC-4); cleanest MECE partition in the family (AC-6/AC-7); discriminator triad 3/3 ⇒ correctly a new ADR | Threshold extractor couples to the `## Testing Requirements` line shape (narrowed, fails closed); default-off means an unconfigured fork enforces nothing (deliberate, one documented switch); a new partition joins the conceptual map (but with zero overlap zone); implementation deferred to a later session (the accepted two-session-split cost) | Chosen: the only option that satisfies every Spec AC and hard constraint simultaneously, draws the cleanest MECE boundary, keeps the threshold single-sourced, and correctly applies the ADR-018 Alternative-B discriminator the Spec handed the architect |

## Counter-proposal

The serious counter-position is **fold the coverage gate into an
ADR-014 amendment and extend `ci-base.yml` instead of a new ADR-019 + a
new standalone workflow** (Alternatives B + A combined into the single
"smallest-footprint" position). It is recorded here per the
ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 precedent of
taking a rejected alternative seriously rather than as a strawman. It is
the direct analogue of ADR-017's Alternative A and ADR-018's Alternative
A (fold the new check into an existing one) crossed with ADR-017's
Alternative B (no new ADR number). The argument, taken at full strength:

1. **Fewer ADR numbers, the recent house pattern.** #07 through #11 were
   *all* ADR-014 amendments, consuming **zero** new ADR numbers. An
   amendment for #12 would continue that recent run and keep the ADR
   index compact. New ADR numbers carry permanent conceptual weight; not
   minting one is the conservative default.
2. **`ci-base.yml` already runs the tests.** The reusable workflow
   already accepts a `test-command` and runs the derived repo's suite.
   The coverage number is produced by that very run. Adding a
   `coverage-threshold` input and one comparison step to the workflow
   that already has the data is fewer moving parts than standing up a
   second workflow file with its own `workflow_call` interface,
   activation switch, and threshold-extraction logic — one workflow, one
   owner, one place to look.
3. **One workflow, one owner is the simplest structure.** The
   detector-family ADRs themselves repeatedly invoke
   locality-of-behavior; a single coverage-aware `ci-base.yml` keeps the
   "test and gate" story in one file rather than splitting a tightly
   related concern across two workflows a maintainer must mentally join.

**Why the counter was not adopted:**

- **The discriminator triad is 3/3 and the structural half dominates.**
  ADR-018's Alternative-B test classifies "new ADR vs. amendment" by
  whether the milestone introduces a new check + a new MECE boundary +
  new keying. #12 satisfies all three (Decision 5): a new CI hard-check
  (`coverage-gate.yml`;
  nothing gates on coverage today), a new MECE partition **that ADR-014
  §(d)'s table does not pre-reserve** (it names #04/#05/#09/#10/#11,
  not #12), and new structural keying (the 80% value + its single-source
  binding + the activation posture). ADR-015, ADR-017, and ADR-018 each
  self-classified the identical shape (new check + new boundary + new
  keying) as a new ADR, **not** an amendment. The amendment counter's
  premise — "this is a consequence-clarification of an existing ADR" —
  is false: there is no prior ADR whose consequence this clarifies.
- **#11 took an amendment for the opposite reason, not as a precedent
  for #12.** #07–#11 were amendments **because each populated a slot
  ADR-014 §(d) had already reserved** — they were the *population of an
  existing partition*, the textbook amendment case. #12 populates **no**
  pre-reserved §(d) slot (the table omits #12 by name); it *creates* a
  partition. Citing #07–#11's amendment run as a pattern for #12 inverts
  the actual rule: the rule keys on "pre-reserved slot?" not on "recent
  count of amendments." On the actual rule, #12 is a new ADR and #11 was
  an amendment for consistent, opposite reasons.
- **Extending `ci-base.yml` conflates two contracts and breaks
  Key-interaction 1.** `ci-base.yml` owns "run the derived repo's
  `test-command`" — a contract every caller already depends on with **no
  threshold**. Grafting a coverage gate onto it puts "did the tests
  run?" and "is coverage ≥ threshold?" on one job with one name (the
  exact muddiness ADR-017 §2 and ADR-018 §5 rejected) **and** forces
  every non-opted-in caller to inherit a threshold opinion, violating
  Spec Key-interaction 1 / hard constraint 4 ("the existing
  `test-command` behavior must remain unchanged for derived repos that
  have not opted in"). Default-off then requires an `if:` guard *inside*
  the shared job — the second-guard anti-pattern AC-4 explicitly
  forbids. The "fewer moving parts" pro is real but it is bought by
  breaking two binding Spec constraints; a standalone `workflow_call`
  file keeps two contracts in two owners and `ci-base.yml`
  byte-unchanged.
- **The simplicity the counter buys is illusory at the contract level.**
  "One workflow" is simpler only if the two contracts were one. They are
  not: "run tests" is unconditional and opt-in-free; "gate on coverage"
  is opt-in and threshold-bearing. Collapsing them is the same
  locality-of-behavior error ADR-012 applied to the dispatcher,
  ADR-015 to its Alternative C, ADR-017 to its Alternative A, and
  ADR-018 to its Alternative A — paying a larger correctness cost
  (broken Key-interaction 1, conflated job, forbidden second guard) to
  "simplify away" a separation that the Spec deliberately drew.

**Trigger conditions for re-evaluating this counter-proposal:**

- ADR-014's §(d) MECE table is restructured to **add a coverage
  enforcement slot** (i.e. ADR-014 pre-reserves the partition #12 now
  creates). At that point #12 *would* be populating a pre-reserved slot,
  and an ADR-014 amendment — not a standalone ADR-019 — would become the
  correct classification under the very discriminator this ADR applies.
- `coverage-gate.yml`
  and `ci-base.yml` prove at implementation time to share so much YAML
  (job scaffolding, checkout, the `workflow_call` plumbing) that a
  **shared composite action** sourced by both — not a merged workflow —
  becomes the right refactor; this preserves the two-contract partition
  while removing the duplication, the same "shared library, not merged
  script" re-evaluation trigger ADR-017 and ADR-018 recorded for the
  detector family.
- The "Minimum 80% test coverage" rule is **removed from
  `.claude/CLAUDE.md` `## Testing Requirements`** entirely (e.g. the
  template stops mandating a coverage floor). The enforced contract's
  subject matter then vanishes, and the subject-matter-presence rule
  itself would retire or reclassify the gate — at which point this whole
  ADR is re-evaluated, not just the counter.

The counter-proposal stays in this ADR as the historical record of the
decision's most serious objection, per the
ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 convention.
No alternative ADR file is created — the rejected counter's correct
state is non-existence; this ADR-019 file is its only citable home.

Note: at design time, `<!-- ref-allow: -->` suppressions were placed on
lines referencing the then-forthcoming implementation artifacts
(`coverage-gate.yml` and the planned `.claude/meta/scripts/` helper)
in this ADR file (`.claude/meta/adr/019-coverage-ci-gate.md`) and its
JA sibling, following the precedent set by `specs/12-coverage-ci-gate.md`,
`specs/11-verification-domain-opt-in-guidance.md`, and
`specs/05-roadmap-drift-detection-ci.md`. Those suppressions were
**removed** once the artifacts materialized (per the #11 LOW precedent
for over-suppression removal when the forward-ref resolves). They did
**not** appear in `.claude/CLAUDE.md`.

## References

- ADR-018 (Bilingual parity detector) — the **source of the
  Alternative-B discriminator** this ADR applies (its Alternatives table
  row B: "new detector + new MECE contract boundary + new structural
  keying" ⇒ new ADR); the immediately preceding ADR and the exact house
  style this ADR mirrors (Status / Context / Decision[numbered
  sub-decisions] / Consequences[Positive/Negative/Neutral] /
  Alternatives considered / Counter-proposal[with trigger conditions] /
  References); its §5 three-way MECE-by-contract partition is the
  boundary-reasoning precedent this ADR extends with a wholly-disjoint
  input.
- ADR-017 (Roadmap drift detector) — the closest detector-plus-CI
  precedent; its §2 MECE-by-contract boundary statement and its
  Counter-proposal "trigger conditions" structure are the direct models
  for this ADR's Decision 5 and Counter-proposal; its two-session
  decision-then-implementation split (design ADR first, implementation a
  separate session) is the precedent this ADR follows; its §4
  "constraints not bash" Neutral-section discipline and forbidden-second-
  declaration rule are inherited unchanged.
- ADR-015 (Dangling-Reference Detector) — establishes the
  subject-matter-presence posture rule this ADR applies to *reject*
  always-on for #12 (coverage subject matter is absent from the
  template, unlike Roadmap drift / EN-JA parity); the precedent for
  classifying "new check + new boundary + new keying" as a new ADR
  rather than an amendment; the reusable detector/workflow/test shape
  family this milestone's downstream tasks mirror.
- ADR-014 (Roadmap Index as the Single Entry Point) — its §(d) MECE
  table (≈ line 1800) names #04/#05/#09/#10/#11 but **not** #12; that
  absence is the decisive distinction making #12 a new partition (new
  ADR) rather than the population of a pre-reserved slot (#11's
  amendment case); this ADR follows ADR-014's "record the decision +
  downstream tasks, do not perform them" shape and its write-ownership
  model (`architect` adds the row's `adr:` link).
- ADR-010 (verification-layer generalization) — establishes the
  default-off posture for the `implementation`/`design` domains; cited
  in the Spec as an opt-in precedent the architect may draw on for the
  activation posture; **not** the ADR this milestone amends (Decision 5
  records why a new ADR, not an ADR-010 amendment, is correct).
- ADR-012 (Code Reviewer as Dispatcher) — precedent for recording a
  counter-proposal raised and rejected with real pros and explicit
  re-evaluation triggers; the locality-of-behavior / separation-of-
  concerns value applied here to reject the merged-workflow counter.
- ADR-016 (Cross-session progress persistence) — the #03 precedent for
  the two-session decision-then-implementation split this ADR follows
  (record the decision + downstream tasks; implementation deferred to a
  later session).
- `specs/12-coverage-ci-gate.md` — the authoritative scope of this
  milestone (the eight acceptance criteria, R-01 (a)–(e), R-02, R-03,
  R-04, the Non-goals); this ADR records the structural *how/why* for
  the CI form, posture, single-source binding, input contract, and
  new-ADR decision the Spec defers (R-01, Key-interaction 6); the Spec
  owns the *what*.
- `.claude/CLAUDE.md` `## Testing Requirements` — the canonical single
  source of truth for the 80% coverage rule this ADR's gate enforces;
  Decision 3 binds the implementation to read the threshold from this
  one location (Spec AC-2/AC-8/R-02).
- `.github/workflows/ci-base.yml` — the existing reusable workflow whose
  `test-command` contract this ADR leaves byte-unchanged (Decision 1 /
  Spec Key-interaction 1); its `workflow_call` input pattern is the
  forkability model for Decision 4 (Spec AC-3/R-04).
- `.github/workflows/workaround-check.yml` — the default-off-single-
  switch posture precedent this ADR's Decision 2 follows; the in-repo
  single-switch shape chosen over the CodeQL repository-variable shape.
- Roadmap row: #12
- The Japanese counterpart (`019-coverage-ci-gate.ja.md`) is authored by
  `architect` in this same session (the new-ADR JA mirror is the
  architect's responsibility, not deferred to `technical-writer`), with
  required heading-tree parity (level + position).
