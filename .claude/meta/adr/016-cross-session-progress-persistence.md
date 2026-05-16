# ADR-016: Cross-session milestone progress persistence — repo-local, row-keyed, boundary-triggered

## Status

Accepted — 2026-05-16

## Context

The Roadmap (`.claude/CLAUDE.md`, ADR-014) records a milestone's
*implementation state* with one of four glyphs (☐ / ◐ / ☑ / ✗). A row
at `◐ in-progress` says only that work has started — not which of the
nine Development-Workflow steps is complete, which artifacts already
exist on disk, what the next concrete action is, or why work stopped.
A milestone of non-trivial length crossing a session or compaction
boundary forces the resuming operator or agent to re-derive all of
that from `git log`, a `specs/` scan, and a re-trace of the workflow —
context budget spent on rediscovery, with re-derivation error risk
(wrong "next step", repeated completed action). `specs/03-cross-session-progress-persistence.md`
is the authoritative scope; this ADR records the four **structural**
decisions the Spec explicitly defers to `architect`: storage location
and path convention, trigger model, staleness recognition, and
retirement on completion — plus the relationship to the existing
session machinery (Spec US-004).

Three hard constraints bound the design and are non-negotiable:

1. **ADR-014 index-only (Spec R-02).** Progress detail must not enter
   the Roadmap table, a Roadmap column, or any addition to the table
   format. The glyph stays the only implementation-state the Roadmap
   carries. The progress record lives *outside* the Roadmap.
2. **Invariant 2 compaction durability (Spec R-01).** A progress
   record kept only in Claude's context — or in a subdirectory
   `CLAUDE.md`, which compaction summarizes away
   (`.claude/skills/claude-md-authoring/invariants.md` §2) — is lost
   across a compaction boundary. A file *on disk* is unaffected by
   compaction (compaction discards Claude's working memory, not the
   file system). The record must be on disk **and** at a deterministic
   path discoverable without a file-system search.
3. **Composability with existing session machinery (Spec R-05 /
   US-004).** The global `/save-session` ↔ `/resume-session` commands
   already exist (user-home `~/.claude/session-data/`, project-agnostic,
   per-session). A new per-milestone mechanism must complement them, not
   introduce a competing parallel convention. A repo grep confirms
   there is **no in-repo `ECC:SUMMARY` block**: the only existing
   session-summary surface is the user-home one. The two scopes must be
   cleanly non-overlapping.

A fourth force is the **#04 dangling-reference detector**, now active
CI (`check-dangling-refs.sh`, ADR-015). It scans `CLAUDE.md`,
`.claude/meta/adr/*.md`, `specs/*.md`, and `.claude/agents/*.md`. Any
storage path this ADR introduces must either fall inside an
already-scoped tree consistently or not create new dangling-reference
false positives. This is treated as an explicit design input, not an
afterthought (mirroring how ADR-015 listed detector interactions).

The trigger-model decision is the non-trivial one and is reasoned
through ADR-015's **subject-matter-presence rule**: a mechanism is
always-on when its subject matter is present in every fork from day
one; it is need-triggered / opt-in when its subject matter is absent
or irrelevant until a specific situation arises. That rule, established
for CI posture, bears directly here and is applied in the Decision.

## Decision

A per-milestone in-progress record is a **single repo-local Markdown
file at the deterministic path `specs/NN-progress.md`**, where `NN` is
the stable, never-reused Roadmap row number (the same immutable key
ADR-014's reservation rule uses for `specs/NN-slug.md`). It is
**created/updated only when a session or compaction boundary occurs
while the milestone is `◐ in-progress`** (the Spec's product-preferred
option b), **not** on the ☐→◐ status transition and **not** by an
operator command. It is **deleted by the agent that flips the row to
☑ done**, in the same change that records completion. It **runs
alongside** `/save-session`, with a precisely drawn scope boundary.

### 1. Storage location and path convention

`specs/NN-progress.md`, `NN` = the two-digit Roadmap row number.
Concretely, milestone #03's record is `specs/03-progress.md`.

Why this satisfies every constraint:

- **On disk, compaction-durable (Invariant 2 / R-01).** A file in
  `specs/` is a file on the file system; compaction does not touch it.
  It is *not* a subdirectory `CLAUDE.md` (summarized away) and *not*
  context-only.
- **Deterministic, no file-system search (R-01).** The path is a pure
  function of the row number the reader already has from the Roadmap.
  A resumer reads the Roadmap row #03, then opens `specs/03-progress.md`
  — no `ls`, no `git log`, no scan. The key is the *stable row number*,
  which ADR-014 guarantees never changes or is reused.
- **Outside the Roadmap (ADR-014 / R-02).** Nothing is added to the
  table; the glyph remains the sole implementation-state token. The
  record is a sibling file, co-located with the milestone's Spec
  (`specs/NN-slug.md`) so the two milestone artifacts sit together.
- **Detector-consistent (the #04 interaction).** `specs/` is already a
  fully-scoped tree for the active detector. `specs/NN-progress.md`
  matches the same `specs/<NN>-<slug>.md` shape ADR-014's reservation
  carve-out and the Class-A placeholder skip already reason about; a
  real-digit `specs/03-progress.md` that **exists on disk** resolves
  normally and produces no dangling-reference finding. Because the
  record is created only at a boundary (Decision 2), it materializes on
  disk *before* anything references it, so there is no
  intended-present/actually-absent window. A downstream task (below)
  asks `implementer` to confirm detector compatibility with a real
  fixture, mirroring ADR-015's downstream-task discipline.

The record is **git-tracked**, not gitignored. Rationale: US-002's
durability requirement is satisfied by either, but a tracked file is
(a) shareable across operators of the same fork — the per-milestone
state is project knowledge, not one developer's scratchpad — and
(b) recoverable via git history if deleted prematurely. A
`.gitignore`d file would be invisible to a teammate resuming the same
`◐` milestone on a different machine, defeating the per-repo (not
per-developer) scope the Spec sets in its Non-goals.

**Schema (minimal, enforced by convention, not CI — the Spec's
out-of-scope list forbids a presence/freshness CI check):** YAML
front-matter then a short body.

```
---
roadmap_row: 3
milestone: "Cross-session milestone progress persistence"
status_glyph: "◐"            # MUST mirror the Roadmap glyph; mismatch ⇒ stale
workflow_step: 4             # 1–9 per ## Development Workflow; current step
last_updated: 2026-05-16     # YYYY-MM-DD, date the record was last written
head_sha: 7cee30f            # git HEAD short SHA at write time (staleness pin)
spec_exists: true            # mirrors specs/NN-slug.md presence (US-001 (c))
adr_links: [".claude/meta/adr/016-cross-session-progress-persistence.md"]
---

## Done
- Step 2 (Spec) — specs/03-...md authored
- Step 4 (Architecture) — ADR-016 written

## Next concrete action
[the single next action a resumer takes]

## Notes / why work stopped
[free text; e.g. "compaction boundary at step 4"]
```

`workflow_step` is the integer of the `## Development Workflow` step
(1 Issue Analysis … 9 Commit), so a resumer maps directly onto the
known nine-step pipeline without re-tracing it (US-001 (a)). The body
sections are deliberately the same shape as `/save-session`'s "What
WORKED / Next Step" so an operator carries one mental model (US-004 /
R-05). The exact field set is handed to `implementer`; this ADR fixes
the *required signals* (row key, glyph mirror, step, timestamp, SHA,
spec-exists), not the final bash/YAML form — the same Neutral-section
discipline ADR-015 used.

### 2. Trigger model — boundary-triggered (option b)

The record is written **only when a session or compaction boundary
occurs during a `◐` milestone**, not on the ☐→◐ transition (option a)
and not by an explicit operator command (option c).

This is the Spec's stated product preference, and the
subject-matter-presence rule (ADR-015) *confirms* rather than overrides
it. The subject matter of a progress record — "in-flight state that a
*future* context must recover" — is **absent until a boundary is about
to sever the current context from the next one**. A milestone that
ships in one uninterrupted session never has that subject matter: there
is no future context to hand off to, so option a (always-create-at-◐)
would manufacture a record whose subject matter does not yet exist,
imposing exactly the ceremony Spec R-04 / US-003 forbids for the
S-effort prose rows (#16–#21). Option c (operator command like
`/save-session`) under-triggers in the agent case: an agent crossing a
compaction boundary mid-step cannot rely on a human to have run a
command first (US-002's actor is "any agent crossing a compaction
boundary"). Boundary-triggered is the unique option whose firing
condition coincides with the moment the subject matter comes into
existence — the same logic by which ADR-015 placed always-on vs
default-off by *when the subject matter is present*.

**Write-ownership (agent-contract terms, modeled on ADR-014's
producer-owns-the-index model):**

- `product-manager` or `implementer` **creates** the record at the
  first session/compaction boundary encountered while the milestone is
  `◐` (Spec Key-interaction 2). Whichever agent holds the work when the
  boundary is hit owns the create.
- `implementer` **updates** it as workflow steps complete *when a
  boundary is anticipated* (Spec Key-interaction 3) — not after every
  step unconditionally (that would re-introduce per-step ceremony).
- `orchestrator` **reads** it at the start of the Analyze step,
  immediately after reading the Roadmap row, before dispatching any
  sub-agent; if the milestone is `◐` and no record exists, it falls
  back to git-log re-derivation and says so (Spec Key-interaction 1;
  US-002 AC-3 — absence must be explicit, never silently assumed).
  `orchestrator` never writes, exactly as it never writes Roadmap rows.

This keeps the producer/reader split identical in shape to ADR-014:
the agent doing the work owns the write; `orchestrator` only reads.

### 3. Staleness recognition

A resumer must distinguish a current record from a stale one without
trusting it blindly. Three concrete, cheap cross-checks, in order:

1. **Glyph mirror.** `status_glyph` in the record MUST equal the
   Roadmap row's glyph. If the Roadmap says ☑ or ✗ but the record says
   ◐ (or the record exists at all), the record is **stale by
   definition** — the milestone moved on without the record being
   retired. The Roadmap glyph is authoritative (ADR-014); the record
   never overrides it.
2. **`head_sha` pin.** The record records the `git HEAD` short SHA at
   write time. A resumer compares it to current `HEAD`: equal ⇒ no
   commits since the snapshot (maximally fresh); diverged ⇒ the record
   predates N commits and `Done`/`Next` may be behind — the resumer
   reads it as a *floor* on progress (work is *at least* this far),
   then reconciles the delta against `git log <head_sha>..HEAD`, which
   is bounded and cheap, not a full-history re-derivation.
3. **`last_updated` date.** A coarse human-facing recency signal;
   secondary to the SHA pin (a date cannot distinguish "no work" from
   "work, no record update" — the SHA can).

The contract a resumer applies: **the Roadmap glyph wins on
*implementation state*; the record is authoritative only on
*in-flight detail* (which step, what next) and only while its glyph
mirrors the Roadmap and its SHA is an ancestor of HEAD.** A stale
record is never worse than no record (US-002's framing: "less stale
than zero information") because the SHA pin makes the staleness
*measurable* rather than invisible.

### 4. Retirement on ◐ → ☑

When a milestone transitions `◐ in-progress` → `☑ done`, the agent
that flips the Roadmap glyph **deletes `specs/NN-progress.md` in the
same change** that records completion. Deletion, not archival:

- The record's entire purpose is to answer "this milestone is ◐; what
  is its in-flight state?" A ☑ milestone has no in-flight state; a
  retained record can only mislead a future reader (Spec R-03: "a
  record never updated after the milestone completes misleads future
  operators"). Deleting removes the misleading artifact entirely.
- This is **consistent with ADR-014's "dropped rows stay / history is
  not rewritten"** philosophy, correctly read: ADR-014 protects the
  *index* (the Roadmap row and its glyph history) from rewriting — the
  ☑/✗ row persists forever. The progress record is *not* index; it is
  transient working state explicitly outside the index (Decision 1).
  Deleting it does not rewrite any history — the completion is recorded
  by the Roadmap glyph and the milestone's Spec/ADR, all of which
  persist. Git history retains the deleted file if forensic recovery is
  ever needed, so nothing is truly lost.
- For ◐ → ✗ (dropped): same rule — delete on the glyph flip. A dropped
  milestone has no resumable in-flight state worth keeping; the ✗ row
  and any Spec/ADR carry the "why dropped" record per ADR-014.

Retirement is an **agent action bound to the glyph flip**, not a
separate CI job (the Spec's out-of-scope list forbids a CI check for
this) and not a manual operator chore that can be forgotten. Binding
deletion to the same change as the status flip makes "record retired"
and "row marked done" atomic from the reader's perspective: the glyph
mirror (Staleness check 1) is the backstop if the binding is ever
violated — a ☑ row with a surviving record is *detectably* stale.

### 5. Relationship to `/save-session` ↔ `/resume-session` and ECC:SUMMARY

The per-milestone record **runs alongside** the global session
commands; it neither extends nor wraps them. The boundary is drawn on
**scope**, not mechanism:

| Dimension | `/save-session` ↔ `/resume-session` | `specs/NN-progress.md` |
|---|---|---|
| Scope | One *work session* (anything the operator did) | One *milestone's* workflow state |
| Location | User-home `~/.claude/session-data/` (outside repo) | Repo-local `specs/` (in repo, git-tracked) |
| Granularity | Per session, project-agnostic | Per Roadmap row, project-specific |
| Lifetime | Operator-managed; survives in user-home | Tied to the ◐ window; deleted at ☑ |
| Compaction durability | Survives only via explicit `/resume-session` | Survives implicitly (on disk, deterministic path) |
| Trigger | Operator command | Session/compaction boundary during ◐ |

They are **composable and non-competing**: an operator may run
`/save-session` for broad cross-cutting session continuity *and* have
`specs/NN-progress.md` for the narrow "where is milestone #NN" question
— US-004's requirement that "the operator can use either
independently; the two mechanisms are composable and do not conflict."
The deliberate design choice is **non-overlap by scope**: the global
command answers "what was I doing in this session"; the milestone
record answers "what is the in-flight state of this specific
milestone." A resumer reads the Roadmap → the milestone record for
milestone-scoped state; `/resume-session` remains the operator's tool
for whole-session state. Neither is required to use the other.

On **ECC:SUMMARY**: a repo grep confirms no in-repo `ECC:SUMMARY` block
or convention exists in this template. There is therefore nothing to
extend or align with in-repo; the only existing session-summary surface
is the user-home `save-session` file format, which this ADR composes
with as above. The body-section shape of `specs/NN-progress.md` (Done /
Next concrete action / Notes) is *deliberately modeled on*
`save-session`'s section vocabulary so an operator who knows one reads
the other with zero new mental model — composition by familiar shape,
not by a new shared block format. Reuse-over-reinvention (Development
Workflow step 3) is honored: no parallel session convention is
invented; the new artifact is scoped to exactly the gap the existing
machinery does not cover (per-milestone, repo-local, compaction-durable
without an explicit resume command).

This ADR records the decision and the agent-contract / downstream
implications. It does **not** create any progress file, write any
script, or modify any agent prompt — implementation is deferred to a
future session and is listed under Consequences → Neutral for
traceability, exactly as ADR-014 and ADR-015 do.

## Consequences

### Positive

- A resuming operator or agent answers "which workflow step is
  current, what exists on disk, what is the next action" with **one
  deterministic file read** keyed to the Roadmap row number — no
  `git log`, no `specs/` scan, no workflow re-trace (US-001,
  Spec metric: re-orientation < 60s, near-zero re-derivation tokens).
- Compaction durability is structural, not procedural: the record is a
  file on disk at a path that is a pure function of the stable row
  number, so the resuming context recovers it with no operator action
  (US-002), unlike `/save-session` which needs an explicit
  `/resume-session`.
- Zero ceremony for single-session milestones (US-003): the
  boundary-trigger means a milestone that ships ☐→☑ in one session
  never creates a record, and no CI fails for its absence (the Spec
  forbids such a CI check). The S-effort prose rows (#16–#21) pay no
  progress-tracking tax.
- The ADR-014 index-only contract is untouched: the Roadmap glyph
  remains the sole implementation-state token; progress detail lives in
  a sibling file, not the table.
- Staleness is *measurable* (glyph mirror + `head_sha` pin), so a stale
  record degrades gracefully to "a floor on progress, reconcile the
  bounded delta" rather than misleading silently — the Spec's R-03
  mitigation requirement is met concretely.
- The trigger model is decided by the *same* subject-matter-presence
  rule ADR-015 established, so the template gains no new ad-hoc posture
  concept — the rule now governs both CI posture and progress-record
  triggering, auditable and consistent.
- Composes with existing session machinery by scope partition, so
  operators hold one mental model (US-004 / R-05); no parallel
  convention is invented (Development Workflow step 3 reuse principle).

### Negative

- **Update discipline depends on agent-prompt compliance.** Like
  ADR-014's index↔reality drift, nothing enforces that a boundary
  actually triggers a write (the Spec forbids a presence/freshness CI
  check). A boundary hit without a write leaves the next resumer with
  no record — degraded to the status-quo git-log re-derivation, which
  is the current baseline, not a regression, but the benefit is
  unrealized for that milestone. Mitigation is the explicit-absence
  fallback (orchestrator says "no record, re-deriving") and the SHA pin
  making any written record's staleness measurable.
- **Two session-continuity surfaces remain** (global `/save-session`,
  per-milestone record). The scope table makes the boundary explicit,
  but a maintainer must hold both concepts; the risk is an operator
  using `/save-session` and expecting milestone-step granularity it
  does not carry, or vice versa. Mitigated by the deliberately
  non-overlapping scopes and the shared body-section vocabulary.
- **Couples the record path to ADR-014's row-number key.** If ADR-014's
  row-numbering convention ever changed (it will not — "never reused"
  is itself an ADR-014 invariant), the `specs/NN-progress.md` key would
  change with it. This is the same acceptable coupling ADR-015's
  reservation carve-out already took on, keyed to the same immutable
  number.
- **Retirement-by-deletion loses the in-flight narrative at ☑.** A
  reader curious about *how* a completed milestone progressed cannot
  read the (deleted) record. Accepted deliberately: that narrative is
  not index content, the Spec scopes records to active ◐ rows only, git
  history retains the file for forensic recovery, and a retained record
  actively misleads (R-03) — the cost of keeping it exceeds the cost of
  losing the narrative.

### Neutral

- This is a **CLAUDE.md-plus-agent-prompt** change in the ADR-014 /
  ADR-015 mold: no agent is added or removed; existing agents
  (`product-manager`, `implementer`, `orchestrator`) gain one
  responsibility each. Agent count unchanged.
- The Roadmap row #03 `Design source` cell gains an `adr:` link to this
  ADR (performed by this change per ADR-014 write-ownership: `architect`
  adds the `adr:` link). No other row is touched; no Roadmap format
  change.
- Downstream `implementer` tasks (recorded for traceability, **not
  performed by this ADR** — implementation is a future session):
  - `.claude/templates/` — add a `progress-template.md` paste-in
    skeleton (YAML front-matter + Done / Next / Notes body) matching
    the schema in Decision 1; `.ja.md` counterpart is a
    `technical-writer` task, not this one.
  - `.claude/agents/product-manager.md` — add: "at the first
    session/compaction boundary while a milestone is `◐`, create
    `specs/NN-progress.md` from the template if absent."
  - `.claude/agents/implementer.md` — add: "when a boundary is
    anticipated mid-milestone, update `specs/NN-progress.md`
    (`workflow_step`, `head_sha`, `last_updated`, Done/Next); on the
    ◐→☑ (or ◐→✗) glyph flip, delete `specs/NN-progress.md` in the same
    change."
  - `.claude/agents/orchestrator.md` — Analyze step: "after reading the
    Roadmap row, if the milestone is `◐`, read `specs/NN-progress.md`;
    if absent, state explicitly that no record exists and re-derive
    from git. Never write the record."
  - `.claude/CLAUDE.md` `## Development Workflow` — one sentence noting
    that an `◐` milestone crossing a boundary persists in-flight state
    to `specs/NN-progress.md` (per ADR-016), composable with
    `/save-session`. Authored under the `claude-md-authoring` Skill
    (this is a structural CLAUDE.md change); the
    sanctioned-line-budget interaction is unaffected (one sentence,
    not the Roadmap).
  - `implementer` confirms detector compatibility: add a real
    `specs/NN-progress.md` fixture to the `test-check-dangling-refs.sh`
    suite proving an existing on-disk progress file produces no
    dangling-reference finding, and that a *referenced-but-absent*
    progress path is correctly handled (it should not occur given the
    boundary-trigger create-before-reference ordering, but the test
    pins the invariant). No detector code change is anticipated —
    `specs/` is already fully scoped and `specs/03-progress.md` is a
    real-digit path that resolves normally when present.
  - The Japanese counterpart of this ADR
    (`016-cross-session-progress-persistence.ja.md`) is owned by
    `technical-writer`, not this task.
- No CI check is introduced or implied. The Spec's out-of-scope list
  forbids a progress-presence or freshness CI check; this ADR honors
  that — staleness is handled by the in-record glyph mirror + SHA pin
  read at resume time, not by a workflow.

## Alternatives considered

| Alternative | Pros | Cons | Why not chosen |
|---|---|---|---|
| **A: Reuse `~/.claude/session-data/` only — no repo-local record** | Zero new artifact; the `save-session`/`resume-session` machinery already exists and operators know it; one mechanism, not two | User-home, not repo-tracked: invisible to a teammate resuming the same `◐` milestone on another machine (Spec scopes state per-repo, not per-developer); project-agnostic, so not keyed to a Roadmap row — a resumer cannot deterministically locate "the milestone-#03 state" without the operator having run `/save-session` and `/resume-session` with the right file; survives compaction only via an *explicit* `/resume-session`, failing US-002's "no operator action" requirement | Recorded as the serious counter-proposal (see Counter-proposal). Its pros are real (reuse, familiarity) but it cannot satisfy three Spec acceptance criteria: per-repo shareability, deterministic row-keyed location, and compaction durability with zero operator action. Not a strawman — it is the "do nothing new" option taken seriously and rejected on concrete AC failures |
| **B: Extend an in-repo ECC:SUMMARY block instead of a new per-milestone file** | One in-repo session-summary surface; no new file convention if such a block existed | A repo grep confirms **no in-repo `ECC:SUMMARY` block or convention exists** in this template — there is nothing to extend; inventing one would itself be a new convention (the very thing reuse-over-reinvention warns against), and a single shared block cannot be deterministically keyed to a specific Roadmap row without becoming a de-facto per-milestone record anyway | The premise is false on inspection (no such block exists), so "extend it" reduces to "invent a new shared block and multiplex milestones into it" — strictly worse than one file per stable row number for deterministic location and retirement |
| **C: Co-locate as a section appended to `specs/NN-slug.md` (the milestone's own Spec)** | One file per milestone already exists (the Spec); no new file; trivially co-located | Mutates the Spec — an `implementer`/`test-runner` contract artifact whose acceptance criteria are authoritative scope (ADR-014); interleaving mutable progress state into an immutable scope document is the exact "decisions vs status" conflation ADR-006 rejected for the ADR template; retirement-by-deletion would mean deleting a section of a contract file, risky and reviewer-hostile | Rejected for the same lifecycle-mismatch reason ADR-006 rejected a "Workaround section in the ADR template": scope/contract documents and mutable working-state have different lifecycles and must not share a file |
| **D: A dedicated `progress/NN.md` top-level directory** | Clean separation; one file per row; deterministic | Introduces a new top-level tree the #04 detector does not currently scope — either it produces no validation coverage for these files, or the detector must be widened (out of scope for #03, and a new tree to teach every reader); `specs/NN-progress.md` reuses the already-scoped `specs/` tree and sits beside the milestone's own Spec, giving co-location for free | Rejected on the detector-consistency constraint and reuse: a new tree is strictly more surface than reusing `specs/`, which is already scoped and is where the sibling Spec lives |
| **E: `specs/NN-progress.md`, repo-local, row-keyed, boundary-triggered, deleted at ☑ (chosen)** | On-disk + deterministic (Invariant 2 / R-01); outside the Roadmap (ADR-014 / R-02); zero ceremony for single-session milestones via the boundary trigger (R-04 / US-003); composes with `/save-session` by scope partition (R-05 / US-004); reuses the already-scoped `specs/` tree (no detector change); trigger decided by the inherited subject-matter-presence rule | Update discipline is prompt-compliance-dependent (no CI, by Spec mandate); two session-continuity surfaces coexist; path coupled to ADR-014's row-number key | Chosen: the only option satisfying all three hard constraints *and* all four deferred open questions with a single, deterministic, reuse-maximizing artifact, with the trigger model decided by an already-established rule rather than a new ad-hoc judgement |

## Counter-proposal

The serious counter-position is **Alternative A — add no repo-local
record; rely entirely on the existing `/save-session` ↔
`/resume-session` machinery**. It is recorded here per the
ADR-012 / ADR-014 / ADR-015 precedent of taking a rejected alternative
seriously rather than as a strawman. The argument:

1. The machinery already exists, is documented, and operators know it.
   Reuse-over-reinvention (Development Workflow step 3) explicitly
   prefers composing with a proven mechanism over a new one. Adding a
   second session-continuity artifact arguably violates the very
   principle this ADR cites in its favor.
2. The `save-session` file format already has "What WORKED / Next Step /
   Decisions Made" sections that cover most of what a progress record
   needs. A milestone-scoped variant could be a *convention on top of*
   the existing file, not a new file type.
3. Two mechanisms is the R-05 risk the Spec itself flags ("should I use
   `/save-session` or the milestone progress record?"). One mechanism
   eliminates that risk by construction.

**Why the counter was not adopted:**

- The decisive failure is **location determinism under the Spec's
  acceptance criteria**, not familiarity. US-001 requires a resumer to
  locate milestone-#NN state *without searching* — a pure function of
  the row number. `~/.claude/session-data/` files are dated and
  short-id'd, project-agnostic, and not keyed to any Roadmap row; there
  is no deterministic path from "row #03" to "the file holding #03's
  state." Reuse is only valuable if the reused mechanism *can* satisfy
  the requirement; this one structurally cannot provide a row-keyed
  deterministic address.
- **Compaction durability with zero operator action (US-002)** is
  unmet: a user-home session file is recovered only via an explicit
  `/resume-session`. The Spec's actor for US-002 is "any agent crossing
  a compaction boundary," which has no operator to invoke the command.
- **Per-repo shareability** (Spec Non-goals scope it per-repo, not
  per-developer / not cross-repo): a user-home file is the resuming
  *developer's*, not the *fork's*. A teammate picking up the same `◐`
  milestone on another machine cannot see it.
- Reuse is honored at the level it *can* be honored: the new artifact's
  body-section vocabulary deliberately mirrors `save-session`'s, and
  the two compose by a clean scope partition (Decision 5). The
  principle is satisfied by composition-by-shape, not by forcing a
  user-home, non-row-keyed mechanism to do a job its address space
  cannot express.

**Trigger conditions for re-evaluating this counter-proposal:**

- The session machinery gains a repo-local, row-addressable storage
  mode (e.g., a future `/save-session --milestone NN` writing into the
  repo at a deterministic path), at which point the new mechanism could
  be folded into it without losing determinism or shareability.
- The template's audience shifts to single-developer forks where
  per-repo shareability is moot, weakening one of the three rejection
  grounds (the other two — determinism, zero-action durability — would
  still stand).

The counter-proposal stays in this ADR as the historical record of the
decision's most serious objection, per the ADR-012 / ADR-014 / ADR-015
convention.

## References

- ADR-014 (Roadmap Index as the Single Entry Point) — the index-only
  constraint that keeps progress detail out of the Roadmap table, and
  the stable, never-reused row-number convention this ADR's
  `specs/NN-progress.md` path key reuses; this ADR follows ADR-014's
  "record the decision + downstream tasks, do not perform them" shape
  and its producer-owns-the-write ownership model.
- ADR-015 (Dangling-Reference Detector) — the active #04 detector whose
  `specs/` scope this storage path is consistent with, and the source
  of the **subject-matter-presence rule** this ADR applies to decide
  the boundary-trigger model; precedent for the Counter-proposal
  section and downstream-task discipline.
- ADR-006 (Upstream workaround tracking) — precedent for rejecting a
  shared-file design on lifecycle mismatch (mutable working-state must
  not share a file with an immutable contract/decision document),
  applied here to reject Alternative C.
- ADR-012 (Code Reviewer as Dispatcher) — precedent for recording a
  counter-proposal raised and rejected, with real pros and explicit
  re-evaluation triggers.
- `specs/03-cross-session-progress-persistence.md` — the authoritative
  scope of this milestone; this ADR records the structural *how/why*
  for the four open questions the Spec defers, the Spec owns the
  *what*.
- `.claude/skills/claude-md-authoring/invariants.md` §2 (Invariant 2) —
  the compaction-durability property: root content survives compaction,
  subdirectory/path-scoped content does not, and on-disk files are
  unaffected; the structural basis for the on-disk-deterministic-path
  storage decision. §3 (Invariant 3, code-derivable) and §4 (Invariant
  4, `@path` does not save tokens) bound where compaction-durable
  content may live.
- `/save-session` and `/resume-session` ECC commands (user-home skills,
  `~/.claude/session-data/`, outside the repository) — the existing
  global session-continuity machinery this ADR composes with by scope
  partition (Decision 5 / US-004); confirmed by repo grep to have no
  in-repo `ECC:SUMMARY` block counterpart, so there is no in-repo
  session-summary convention to extend.
- `.claude/CLAUDE.md` `## Development Workflow` — the nine-step pipeline
  whose step-completion state the `workflow_step` field records.
- Roadmap row: #03 (back-link to the milestone this ADR records a
  decision for).
- The Japanese counterpart
  (`016-cross-session-progress-persistence.ja.md`) is owned by
  `technical-writer`, not part of this change.
