# ADR-014: Roadmap Index as the Single Entry Point for Design Artifacts

## Status

Accepted — 2026-05-15

## Context

This template's design knowledge is produced in three artifact types,
each owned by a different step of the Development Workflow:

- **CLAUDE.md** — the always-read project context every agent loads on
  every step.
- **Specs** — produced by `product-manager` (workflow step 2); the
  acceptance criteria a Spec carries are the authoritative *scope* of a
  milestone. `implementer` is hardcoded to read the Spec before writing
  code; `test-runner` derives its pass/fail target from the same
  acceptance criteria.
- **ADRs** — produced by `architect` (workflow step 4) only when a
  *structural* decision occurs; `architect` is hardcoded to read prior
  ADRs for consistency before proposing a new one.

These three artifact types are correctly separated by role, but there
is **no defined entry point** that maps a milestone to its authoritative
document(s). Humans and agents both re-discover "which document is
authoritative for this milestone" on every step. Symptoms:

1. The orchestrator has no per-milestone index to consult during the
   Analyze step, so it re-scans the repo (or guesses) to find the right
   Spec/ADR for the work in front of it.
2. `architect` may fork a new ADR for a milestone that already has one,
   because nothing points from the milestone to its existing `adr:`
   link before a new ADR is created.
3. `implementer` resolves "the Spec" by searching the repository rather
   than following a stable pointer, which is fragile as the Spec count
   grows.
4. There is no single place a learner (the template's primary user) can
   look to answer "what has been built, what is in progress, and where
   is the design for each?"

The template's CLAUDE.md currently has no per-milestone index. CLAUDE.md
is the only file every agent (orchestrator / architect / implementer) is
hardcoded to read on every step, which makes it the only place an index
can live without re-introducing a "remember to read the index"
instruction problem.

This decision was debated directly with the user. The collapse-to-one-
document-type counter-proposal (Alternative A below) was raised and
rejected during that dialogue; it is recorded here for the same reason
ADR-012 records its internal counter-proposal — so the rejected option
stays auditable.

## Decision

Add a `## Roadmap` section to `.claude/CLAUDE.md`, placed immediately
**before** the `## Development Workflow` section. The section is a
**table** (not a bullet list) with the columns:

`# | Milestone | Status | Design source`

Rules governing the table:

- **One row per milestone.** The row number is stable and never reused,
  following the same convention as ADR numbers. A milestone that is
  split becomes a new row plus a note on the old row; numbers are not
  recycled or re-numbered.
- **`Design source` names the document type explicitly** using
  `spec: <path>` and/or `adr: <path>` so a reader never has to infer
  which artifact a link points to.
- **Milestone ↔ Spec is 1:1 and mandatory.** Every milestone row has
  exactly one `spec:` link. This preserves the `implementer` /
  `test-runner` contract: the Spec's acceptance criteria remain the
  authoritative scope.
- **Milestone → ADR is 0:1 or 1:N and optional.** A row carries `adr:`
  links only when one or more structural decisions occurred for that
  milestone. The ADR's `## References` back-links the row number.
- **Status reflects implementation, not design.** Allowed values:
  `☐` todo / `◐` in-progress / `☑` done / `✗` dropped. Dropped rows
  remain in the table — history is not rewritten.
- **The table is an index only.** Acceptance criteria and rationale are
  never duplicated into it; the linked Spec/ADR remains the source of
  truth for content.

Ownership of index updates is assigned to the artifact producer so the
index and the artifact move together:

- `product-manager` adds/updates the Roadmap row (number, one-line
  milestone, `spec:` link) at the moment it generates a Spec.
- `architect` adds the `adr:` link to the existing row at the moment it
  generates an ADR, and checks the row for an existing `adr:` link
  before forking a new ADR.
- `orchestrator` only reads the Roadmap (it does not write rows).

This ADR records the design decision and the agent-contract changes it
implies. It does **not** itself modify CLAUDE.md, the agent prompts, or
the templates — those are downstream implementation tasks owned by
`implementer`, listed under Consequences for traceability.

## Consequences

### Positive

- A single, always-read entry point answers "which document is
  authoritative for this milestone?" in one lookup. The orchestrator's
  Analyze step becomes a table read instead of a repo scan.
- The `architect` ADR-fork problem is structurally addressed: the row
  is checked for an existing `adr:` link before a new ADR is created,
  steering toward amend/supersede rather than fork.
- `implementer` resolves the Spec via a stable pointer instead of
  searching the repository — robust as Spec count grows.
- MECE is preserved by **role separation** (Spec = *what to build* /
  ADR = *why this structure*), not by collapsing document types.
  Redundancy is suppressed by the "ADR only when a structural decision
  occurred" rule, so most milestones stay Spec-only.
- The template's primary user (a learner) gets a one-screen view of
  what was built, what is in progress, and where each design lives —
  with implementation status tracked separately from design.
- No new always-read file is introduced. The index lives where every
  agent already reads, so no agent gains a "remember to read the index"
  instruction.

### Negative

- **Index↔reality drift.** A Spec or ADR can be created without the
  Roadmap row being updated, leaving the index stale. There is no
  automated enforcement in this ADR. Mitigation is *deferred* to a
  possible future default-off CI check shaped like
  `.github/workflows/workaround-check.yml`; it is explicitly **not**
  part of this ADR. Until then, ownership-by-artifact-producer is the
  only guard, and it depends on agent prompt compliance.
- **No versioned contract on the table format.** The column shape and
  status glyphs are documented in CLAUDE.md and a template fragment,
  but a fork that hand-edits the table can diverge silently; nothing
  validates the format.
- Three agent prompts (`orchestrator`, `architect`, `implementer`) and
  `product-manager` gain a new step each. This is one more concept the
  agent team and human readers must hold — the index discipline only
  works if every producer honors its write-ownership.

### Neutral

- This is an **agent-prompt-plus-CLAUDE.md** change, following the
  precedent set by ADR-012 (which rationalized behavior by changing a
  single agent prompt without adding agents). No agent is added or
  removed; agent count is unchanged.
- Row number exhaustion / re-numbering pressure is handled by the same
  convention as ADR numbers: never reuse a number; a split is a new row
  plus a note on the old one. No special tooling is required.
- Roadmap table bloat at 100+ milestones is tolerated by the format:
  split into `### Phase N` sub-tables under the `## Roadmap` heading.
  The column contract is unchanged by the split.
- The downstream implementation tasks owned by `implementer` (recorded
  here for traceability, not performed by this ADR):
  - `.claude/CLAUDE.md` — add the `## Roadmap` section immediately
    before `## Development Workflow`, and add one line to
    `## Extending This File`: "Fill the Roadmap as you plan
    milestones."
  - `orchestrator.md` Analyze step — "Read `## Roadmap` in CLAUDE.md
    first; locate the target milestone row, open only its linked design
    source."
  - `architect.md` Design Mode "Analyze Context" — "Check the Roadmap
    row for an existing `adr:` link before creating a new ADR —
    amend/supersede rather than fork."
  - `implementer.md` "Read the Spec" step — "Resolve the Spec via the
    Roadmap row; do not search the repo for it."
  - `product-manager.md` Spec-generation step — "Add/update the Roadmap
    row in CLAUDE.md (number, one-line, `spec:` link)."
  - New `.claude/templates/roadmap-section.md` — paste-in skeleton
    fragment for CLAUDE.md.
  - `.claude/templates/spec-template.md` `## References` — add a
    "Roadmap row: #NN" example (and `.ja.md`).
  - `.claude/templates/adr-template.md` `## References` — add a
    "Roadmap row: #NN" back-link example (and `.ja.md`).
  - The Japanese counterpart of this ADR
    (`014-roadmap-index-single-entry-point.ja.md`) is owned by
    `technical-writer`, not this task.

## Alternatives considered

| Alternative | Pros | Cons | Why not chosen |
|---|---|---|---|
| **A: Collapse to one document type (ADR-only or Spec-only) and index that** | Only one artifact type to index; trivially MECE; no `spec:`/`adr:` disambiguation needed | `implementer` is hardcoded to read Spec acceptance criteria as authoritative scope and `architect` is hardcoded to read prior ADRs for consistency — collapsing to one document type breaks two agents' reference contracts; ADRs and Specs answer different questions (*why this structure* vs *what to build*) and merging them either bloats one type or loses the other's role | Raised and rejected during the user dialogue. MECE is preserved by *role separation*, not by having only one document type; the contract-breakage cost exceeds the benefit of one fewer type. Recorded here as the serious counter-proposal that was not adopted |
| **B: A separate `ROADMAP.md` at repo root as the index** | Keeps CLAUDE.md shorter; a conventional, discoverable filename for humans | No agent is hardcoded to read `ROADMAP.md`; making it authoritative requires adding a "first, read ROADMAP.md" instruction to every agent — re-introducing exactly the "remember to read the index" problem this ADR exists to remove | The single-entry-point property only holds if the index lives in the one file every agent already reads on every step |
| **C: Status quo — no index; agents re-discover the authoritative document per step** | Zero work; no new convention | The orchestrator re-scans/guesses every step; `architect` forks duplicate ADRs; `implementer` searches for the Spec; learners have no milestone overview — the concrete symptoms in Context | The cost is paid on every workflow step, indefinitely; the whole point of an always-read context file is to remove exactly this rediscovery |
| **D: `## Roadmap` table inside CLAUDE.md, index-only, role-separated Spec/ADR links (chosen)** | Single always-read entry point; preserves the `implementer`/`test-runner`/`architect` reference contracts; index-only so no content duplication; implementation status tracked separately from design; tolerates scale via `### Phase N` split | Index↔reality drift with no automated enforcement in this ADR; format contract unversioned; four agent prompts gain a step | Chosen: lowest-cost option that removes the rediscovery cost without breaking any existing agent reference contract |

## References

- ADR-007 (CLAUDE.md Authoring Skill) — the Roadmap section is a
  structural change to CLAUDE.md and must be authored under the
  `claude-md-authoring` Skill's Pre/Post checklist and invariant rules.
- ADR-012 (Code Reviewer as Dispatcher) — precedent for an
  agent-prompt-plus-CLAUDE.md change that rationalizes behavior without
  changing agent count, and precedent for recording a counter-proposal
  that was raised and rejected during review.
- `.claude/agents/orchestrator.md` — Analyze step gains a
  "read the Roadmap row first" instruction (downstream task).
- `.claude/agents/architect.md` — "Analyze Context" gains a
  "check the Roadmap row for an existing `adr:` link before forking"
  instruction (downstream task).
- `.claude/agents/implementer.md` — "Read the Spec" step gains a
  "resolve the Spec via the Roadmap row" instruction (downstream task).
- `.claude/agents/product-manager.md` — Spec-generation step gains a
  "add/update the Roadmap row" instruction; `product-manager` owns row
  creation, `architect` owns the `adr:` link, `orchestrator` only reads
  (downstream task).
- `.claude/templates/spec-template.md` and
  `.claude/templates/adr-template.md` — `## References` gains a
  "Roadmap row: #NN" example/back-link (downstream task).
- `.github/workflows/workaround-check.yml` — the shape the deferred,
  out-of-scope drift-check CI would follow if added later.
- Roadmap row: #21 (this ADR's 2026-05-20 amendment records the
  quality-gate loop re-entry rule and row-anchor invariant decided
  by that milestone; see §Amendment — 2026-05-20 (quality-gate loop
  re-entry anchored to Roadmap row) below)

## Amendment — 2026-05-16 (Spec reservation rule)

While dogfooding this ADR to populate the template's own `## Roadmap`
section with 21 audit-driven milestones, `product-manager` hit a real
tension between two of the original Decision's rules: "Milestone ↔ Spec
is 1:1 and mandatory" requires every row to carry a `spec:` link, but
authoring 21 full Spec files upfront — for milestones not yet picked up
— is wasteful and front-loads scope decisions that should be made when
the milestone is actually worked. This amendment ratifies the operating
interpretation that resolved the tension; it is now live in CLAUDE.md's
Roadmap section.

**The reservation rule.** Every Roadmap row carries a `spec:` link at
row-creation time, using the deterministic path `specs/NN-slug.md`
where `NN` is the stable row number. The Spec **file** is authored by
`product-manager` only when the milestone is picked up (status moves to
`◐ in-progress`). The reserved link is present and stable from the
moment the row exists; the file materializes on disk later.

**Why this does not violate the original Decision.** The Decision's
1:1-mandatory rule constrains the **link**, not the **file**:
"Every milestone row has exactly one `spec:` link." That property is
established at row-creation and never changes — the mapping is a
property of the index, which is exactly what an index-only table is
for. ADR-014 requires the link to be *present and stable*, not the
target to *exist on disk*, and the deterministic `specs/NN-slug.md`
path keyed to the immutable row number guarantees stability with no
ambiguity about what the link will resolve to. The
`implementer`/`test-runner` reference contract is honored because that
contract only fires when `implementer` is invoked for a milestone, and
by this ADR's own write-ownership model `product-manager` authors the
Spec at the `◐ in-progress` transition — which is, by construction,
before any code is written for that milestone. There is no window in
which `implementer` resolves the pointer and finds nothing: a row that
has reached the implementation step has, by the ownership rule, already
had its Spec authored. The reservation rule therefore tightens *when*
the file is written without weakening *that* the 1:1 mapping holds or
*that* the Spec precedes the code.

**Honestly-acknowledged strain.** `product-manager` flagged that rows
#16–#21 are S-effort prose edits (status discrepancies, CHANGELOG
back-fill, allowlist expiry) where a full Spec feels disproportionate
to the work. The reservation rule does not eliminate this — those rows
still owe a Spec file when picked up. The accepted mitigation is to
keep those Specs to roughly half a page: enough to carry acceptance
criteria for the `test-runner` contract, no ceremony beyond that. This
is a deliberate, eyes-open trade: the 1:1 contract is preserved
uniformly rather than carved out for "small" milestones (a carve-out
would reintroduce exactly the "is there a Spec for this?" rediscovery
ADR-014 exists to remove), and the proportionality cost is paid as
brevity in the Spec rather than as an exception in the index.

The original Status line (`Accepted — 2026-05-15`) is unchanged; this
amendment appends an operating interpretation and does not reopen the
Decision. The Japanese counterpart
(`014-roadmap-index-single-entry-point.ja.md`) must receive the
equivalent amendment; that is a `technical-writer` task, not part of
this change.

## Amendment — 2026-05-16 (CLAUDE.md line-budget vs. the Roadmap)

Populating the 21-row Roadmap pushed `.claude/CLAUDE.md` to 220 lines.
The `claude-md-authoring` Skill's post-writing checklist reads
"CLAUDE.md is under 200 lines," and the ~25 lines of Roadmap (header +
table + rules) are the direct cause. ADR-014's Decision already
anticipated table bloat at 100+ milestones (the `### Phase N` split),
but that mechanism does not help at 21 rows, and — more fundamentally —
splitting the Roadmap *anywhere* is structurally unavailable, not just
unhelpful. This amendment records the resolution; it does **not**
itself edit CLAUDE.md (that is a downstream `implementer` task, listed
below for traceability).

**Why the usual escape is closed for the Roadmap specifically.** The
Skill's own remediation for an over-length CLAUDE.md is "split a
section into a subdirectory `CLAUDE.md` or a Skill, not to compress the
prose." That remediation assumes the section is *relocatable*.
Invariant 2 (`.claude/skills/claude-md-authoring/invariants.md` §2:
"Root content survives compaction; subdirectory and path-scoped content
do not") makes the Roadmap the documented case where that assumption
fails: the Roadmap is ADR-014's single always-read entry point and is
only an entry point if it survives compaction. A subdirectory
`CLAUDE.md` or a Skill is loaded on demand and summarized away on
compaction — relocating the Roadmap there destroys the exact property
that justifies it. Invariant 4 closes the remaining door: `@path`
imports "improve organisation but do NOT save context tokens." For the
Roadmap *only*, the budget cannot be reclaimed by relocation.

**The "around 200" rule's actual enforcement status.** It is a
**volatile rule, not an invariant**, and the Skill states verbatim:
"Treat as 'around 200' if Docs are unreachable; **never enforce it as
a hard CI failure**" (SKILL.md §"Volatile rules"). The post-writing
"under 200 lines" line is a checklist prompt, not a gate. A permanent
overage is therefore *permitted by the Skill itself*; the only open
question is whether the overage is *minimal*.

**Decision: hybrid (reclaim the recoverable slack, then sanction the
irreducible residual).** Spending the full ~20-line overage on a
sanctioned exception when roughly half is cheaply recoverable without
touching any compaction-durable content is not minimal. Therefore:

1. **Compress the Roadmap row descriptions.** The table is index-only
   (the linked Spec is the source of truth), so row text does not need
   to be self-explanatory prose; it needs to be a stable, scannable
   handle. Tighten each milestone one-liner to a short noun phrase,
   moving the parenthetical justifications ("incl. …", "note: …",
   "A-08/C-06") out of the table — they are Spec/ADR content, not
   index content, and keeping them in the row violates the Decision's
   "index only — never duplicate rationale" rule anyway. Target: the
   25-line Roadmap block down to ~18–19 lines while keeping all 21
   rows.
2. **One targeted trim elsewhere.** The `## Plan-First &
   Learning-Aware Defaults` section's third paragraph (the
   `coaching-context.sh` hook mechanics) is operational detail that is
   *not* Invariant-2-locked — it is fully reconstructable from
   `.claude/meta/adr/004-coaching-pillar.md` and the hook file itself,
   and qualifies as code-derivable under Invariant 3. Move that
   paragraph's mechanics to the Learning Mode meta references and leave
   a one-line pointer. Recovers ~6 lines of genuinely relocatable
   content (it is loaded on demand precisely when Learning Mode is
   active, so compaction durability is not required for it).
3. **Sanction the irreducible residual inline.** After (1) and (2),
   whatever overage remains is attributable to the Roadmap's
   irreducible core, which Invariant 2 forbids relocating. Add a short
   sanctioned-exception note to CLAUDE.md's `## CLAUDE.md authoring
   guidance` section recording that the line guidance yields to the
   Roadmap by design. Exact wording handed to `implementer` below.

This stays within house style: it is a clarification of a *consequence*
of ADR-014's existing Decision (the Roadmap lives in root CLAUDE.md and
must survive compaction — already decided), plus downstream editing
instructions. It is **not** a new structural decision and therefore
**does not warrant its own ADR**. ECC precedent (ADR-008, ADR-010 fold
consequence-clarifications into amendments; new ADR numbers are
reserved for new structural decisions) places this as an ADR-014
amendment, not ADR-015. No ADR-015 was created.

**Sanctioned-exception wording for `implementer` to add to CLAUDE.md's
`## CLAUDE.md authoring guidance` section** (append as a final
paragraph; do not modify the existing paragraph):

> **Sanctioned line-budget exception (per ADR-014 amendment
> 2026-05-16).** The `## Roadmap` section is exempt from the
> ~200-line CLAUDE.md guidance. The Roadmap is the single always-read
> entry point for design artifacts and must survive compaction
> (Invariant 2), so it cannot be relocated to a subdirectory
> `CLAUDE.md` or a Skill without defeating its purpose. The "around
> 200" rule is a volatile guideline, never a hard CI failure; it
> yields to the Roadmap by design. Reclaim budget by compressing
> Roadmap row text (index-only) and trimming non-compaction-durable
> sections elsewhere — not by moving the Roadmap.

**Downstream `implementer` tasks (recorded for traceability, not
performed by this ADR):**

- `.claude/CLAUDE.md` — compress the 21 Roadmap row descriptions to
  short noun phrases; move parenthetical justifications out of the
  table (they are Spec/ADR content per the Decision's "index only"
  rule).
- `.claude/CLAUDE.md` — relocate the `coaching-context.sh` hook
  mechanics paragraph from `## Plan-First & Learning-Aware Defaults`
  to the Learning Mode meta references; leave a one-line pointer.
- `.claude/CLAUDE.md` — append the sanctioned-exception paragraph
  above to `## CLAUDE.md authoring guidance`.
- The Japanese counterpart of CLAUDE.md (if present) and of this ADR
  receive the equivalent edits — a `technical-writer` task, not part
  of this change.

The original Status line (`Accepted — 2026-05-15`) is unchanged.

## Amendment — 2026-05-17 (status-transition ownership matrix)

This amendment closes the gap this ADR's own §Consequences → Negative
flagged verbatim: "a formal status-transition state machine is not part
of this ADR. Until then, ownership-by-artifact-producer is the [interim]
only guard." `specs/07-roadmap-status-transitions.md` (Roadmap row #07)
is the authoritative scope; it defers the structural *how* to
`architect` (its Risk R-01 (a)–(d)). This amendment records that
decision. It is a **consequence-clarification of ADR-014's existing
Decision**, not a new structural decision: the §Decision already
assigns glyph ownership in interim form ("ownership-by-artifact-producer")
and this ADR pre-declared the formalization as its own deferred
follow-up. No new detector, boundary, keying, or mechanism is
introduced. Per the ECC precedent this ADR's two 2026-05-16 amendments
and ADR-018's 2026-05-17 amendment apply ("consequence-clarifications
fold into amendments; new ADR numbers are reserved for new structural
decisions" — ADR-015 §Context, ADR-017/ADR-018 Alternative B), this is
an ADR-014 amendment, **not ADR-019**. No ADR-019 is created; Roadmap <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal; it is intentionally never created (see Counter-proposal below) -->
row #07 stays `spec:`-only (Milestone → ADR is 0:1; an amendment to the
Roadmap-mechanism ADR is not #07's *own* ADR — ADR-014 has no milestone
row of its own, so adding an `adr:` link from row #07 to ADR-014 would
assert a milestone→ADR mapping that does not exist).

**Why this is not a state machine.** The Spec's Non-goals forbid
"designing a general workflow-state-machine engine." This amendment
assigns an *owner and a workflow-step trigger* to each of the four
glyph transitions ADR-014's §Decision already sanctioned (`☐`/`◐`/`☑`/
`✗`). It adds no new glyph, no new transition, and no new workflow
step. It codifies the interim practice exercised verbatim by
milestones #03, #05, and #06 (and by #07's own pickup this session) —
a documentation/ownership formalization, retroactively consistent with
every historical flip, not a behavior change.

### The status-transition ownership matrix

Exactly one owning role per transition, tied to a named
`## Development Workflow` step or gate:

| Transition | Owning role | Trigger / gate condition | ADR-014 / ADR-016 consistency |
|---|---|---|---|
| `☐ todo → ◐ in-progress` | `product-manager` | Atomic with authoring the Spec file `specs/NN-slug.md` at milestone pickup (Workflow step 2). The glyph must not remain `☐` once the Spec is on disk and work has begun. | Aligns with ADR-014's existing write-ownership (`product-manager` owns the row + `spec:` link) and the Spec reservation rule (file authored at the `◐` transition). |
| `◐ in-progress → ☑ done` | `product-manager` | After the Workflow step 6 quality gate passes for the milestone (code-reviewer, linter, security-reviewer, performance-engineer all pass) and steps 7–9 (docs, release, commit) are complete. `product-manager` — the row's existing write-owner under ADR-014 — performs the flip; no other role may. | The same role that owns the row under ADR-014 owns the close-out flip. The flip-owner also deletes `specs/NN-progress.md` in the same change (ADR-016 §4 retirement), so the ADR-016 deletion trigger and the #07 flip owner are one role — no ownership gap. |
| `◐ in-progress → ✗ dropped` | `product-manager`, on an `orchestrator`-confirmed drop decision | When the orchestrator (Workflow step 1 Analyze authority) determines the milestone is obsolete/infeasible, `product-manager` (the row write-owner) flips the glyph; the row stays in the table (history not rewritten). | Drop authority is split deliberately: `orchestrator` *decides* (it owns Analyze and is the only always-reading role), `product-manager` *writes* (ADR-014 reserves all row writes to `product-manager`/`architect`; `orchestrator` never writes rows). Same flip-owner deletes `specs/NN-progress.md` per ADR-016 §4. |
| `☑ done → ✗ dropped` (revert) | `product-manager`, on an `orchestrator`-confirmed reversal decision | When a shipped milestone is later found infeasible/reverted, same split as `◐→✗`: `orchestrator` decides, `product-manager` writes. The row stays; ADR-014's "dropped rows stay / history is not rewritten" governs. | Identical authority split to `◐→✗`. No `specs/NN-progress.md` exists at `☑` (ADR-016 §4 deleted it at `◐→☑`), so no progress-file action. |

**Resolving the "quality-gate close-out actor" ambiguity (Spec R-01
(b)).** The interim practice phrased the `◐→☑` owner as a
"quality-gate close-out actor," which the Spec flags as an
unresolved name. This amendment resolves it to a **named role:
`product-manager`**, not a compound responsibility. Rationale: ADR-014's
write-ownership model already reserves *every* Roadmap row write to
`product-manager` (row + `spec:`) or `architect` (`adr:`), with
`orchestrator` read-only. The Status glyph is a row cell; a glyph flip
is a row write. Assigning `◐→☑` to anyone other than the two
sanctioned row-writers would contradict ADR-014's existing Decision.
Between the two, `architect` writes only the `adr:` link; the row's
lifecycle owner is `product-manager`. Therefore `product-manager` owns
`◐→☑`, gated on the step-6 quality gate having passed (the gate is the
*condition*; the *owner* is the row-writer). This keeps the glyph
dimension consistent with — never contradictory to — ADR-014's
link/row write-ownership, satisfying the Spec's compatibility
acceptance criterion.

**Composability with ADR-016 (Spec R-01, ADR-016 §4).** ADR-016
defines `specs/NN-progress.md` deletion as triggered by "the `◐→☑` or
`◐→✗` flip" and assigns the deletion to "the agent that flips the
Roadmap glyph." This amendment names that agent (`product-manager` for
both `◐→☑` and `◐→✗`), making the two rules composable with no gap:
the role this amendment authorizes to flip is, by construction, the
role ADR-016 §4 already binds the progress-file deletion to. ADR-016's
downstream task list still names `implementer` as a possible deleter;
that is reconciled by reading ADR-016 §4's controlling phrase ("the
agent that flips the Roadmap glyph") as authoritative — whichever role
this amendment assigns the flip to is the one ADR-016 binds the
deletion to. Since this amendment assigns all `◐→{☑,✗}` flips to
`product-manager`, `product-manager` owns the paired deletion.

### Documentation placement (Spec R-01 (b))

The formalized matrix lives in the **CLAUDE.md `## Roadmap` Rules
block** as one added bullet, **not** in the Development Workflow
section and **not** duplicated into agent prompts. Rationale:

- The Rules block is **index-adjacent and compaction-durable**: it sits
  directly under the Roadmap table every agent reads on every step
  (Invariant 2), so `product-manager` encounters the glyph-ownership
  rule at exactly the step it authors a Spec or closes a gate, with
  **zero additional file reads** — the Spec's R-01 (b) acceptance
  criterion.
- It is the **tightest placement** respecting the CLAUDE.md
  line-budget guidance: the Rules block is *inside* the Roadmap
  section, which is already the sanctioned line-budget exception (this
  ADR's 2026-05-16 line-budget amendment). One added bullet to an
  already-exempt section costs no budget elsewhere; adding prose to
  `## Development Workflow` would bloat a non-exempt section.
- It is **index-consistent**: glyph ownership is a property of the
  Roadmap mechanism (who may write the Status cell), which is exactly
  what the Rules block governs (it already states the `Status =` glyph
  set and the row/link write-ownership). The transition matrix is the
  natural completion of the existing "Write-ownership:" bullet, not a
  new concept in a new place.

The exact one-bullet wording is handed to `implementer` below; the
MECE boundary against milestone #05's glyph *well-formedness* check
(ADR-017: #05 validates the glyph *value* is one of four sanctioned
characters; #07 governs *who* may change it and *when* — distinct,
non-overlapping, no CI automates #07) is stated in the Spec's R-03 and
restated in the bullet so a future milestone author does not route a
character check to #07 or an ownership question to #05.

### Spec R-01 (c)(d) judgements recorded for the implementer

- **(c) Amendment vs new ADR:** ADR-014 amendment (decided above). No
  ADR-019. Row #07 Design-source cell is unchanged (`spec:`-only). <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
- **(d) claude-md-authoring Skill necessity:** the deferred CLAUDE.md
  edit is **one bullet appended to the existing `## Roadmap` Rules
  list** — a "routine small edit (… single bullet …)" by the explicit
  carve-out in CLAUDE.md's `## CLAUDE.md authoring guidance` section
  ("Routine small edits (typo, single bullet, version bump) do not
  need the Skill"). It is **not** "significant restructuring" (no
  section added/moved/split, no heading change, no invariant touched).
  **Judgement: the claude-md-authoring Skill is NOT required** for the
  #07 implementation edit. (If the implementer instead chooses to add
  a sub-heading or a table, that *would* cross into restructuring and
  the Skill would then apply — but the design here is deliberately a
  single bullet precisely to stay under the routine-edit carve-out.)
- **(d) Agent-prompt impact:** **no agent prompt requires editing.**
  The matrix assigns transitions to roles whose Roadmap-write
  contracts ADR-014 *already* established (`product-manager` owns row
  writes; `orchestrator` reads/decides-at-Analyze; `architect` owns
  `adr:` only). `product-manager` already owns row+`spec:` writes at
  Spec authoring (ADR-014) — the `☐→◐` and `◐→{☑,✗}` flips are the
  glyph facet of that same already-owned row write, made explicit in
  the Rules block rather than in the prompt. `orchestrator`'s
  drop-*decision* authority is its existing Analyze-step role (ADR-014:
  "orchestrator only reads"; deciding a drop is an Analyze output, not
  a row write). ADR-016 already added the `product-manager`/
  `implementer` progress-file-deletion prompt lines; this amendment
  only *names which role's flip* triggers them, which the Rules-block
  bullet conveys without a prompt edit. Recording the rule in the
  always-read Rules block (not in prompts) is the deliberate
  minimal-surface choice, consistent with ADR-017/ADR-018 keeping their
  changes out of agent prompts.

### Downstream `implementer` tasks (recorded for traceability, not performed by this amendment — implementation is a future session, per the #03/ADR-016 · #05/ADR-017 · #06/ADR-018 two-session decision-then-implementation split)

- `.claude/CLAUDE.md` `## Roadmap` **Rules** block — append one bullet
  after the existing "Write-ownership:" bullet, of the form: *"Status
  glyph transitions: `product-manager` flips `☐→◐` atomically with
  authoring the Spec at pickup, and `◐→☑` after the step-6 quality
  gate passes (deleting `specs/NN-progress.md` in the same change per
  ADR-016); drops (`◐→✗`, `☑→✗`) are decided by `orchestrator` at
  Analyze and written by `product-manager`, row retained (history not
  rewritten). #05 checks glyph *value* well-formedness; #07 governs
  *who* flips and *when* — no CI enforces #07."* Single bullet, no
  sub-heading, no table — stays within the routine-edit carve-out (no
  claude-md-authoring Skill invocation required).
- **No agent-prompt edits** (judgement above). The implementer must
  *not* add glyph-ownership prose to `product-manager.md`,
  `orchestrator.md`, `architect.md`, or `implementer.md`; the Rules
  block is the single source.
- **No CI workflow** (Spec Non-goals; #07 is a process/documentation
  assignment, not an automated check — distinct from #05's glyph
  *value* check per ADR-017 and the Spec's R-03 MECE boundary).
- The Japanese counterpart of this ADR
  (`014-roadmap-index-single-entry-point.ja.md`) must receive the
  mirrored amendment, and the Japanese counterpart of CLAUDE.md (if
  present) the mirrored Rules-block bullet — a `technical-writer`
  task, **not** part of this change. **This amendment creates a
  transient EN/JA heading mismatch on ADR-014 until `technical-writer`
  mirrors it; the #06 bilingual-parity detector
  (`check-bilingual-parity.sh`) will FAIL on ADR-014 until the mirror
  lands. This is the expected, queued `technical-writer` task — not a
  reason to omit this EN amendment.**

### Counter-proposal

The serious counter-position is **new ADR-019 — formalize the <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
status-transition matrix as a standalone ADR rather than an ADR-014
amendment**. It is recorded here per the
ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 convention of
taking a rejected alternative seriously rather than as a strawman. The
argument:

1. The Spec hands `architect` an explicit (c) choice ("ADR-014
   amendment or a new ADR-019") and structurally parallel sibling <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
   milestones #05 and #06 both resolved their deferred-structural-
   question Specs with *new* ADRs (017, 018), not amendments. Symmetry
   of process argues #07 → ADR-019. <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
2. A named ownership matrix that four agent roles must honor is a
   first-class, citable contract; burying it as the third amendment in
   a long ADR-014 trail makes it less discoverable than a dedicated
   ADR-019 a reader can cite as "the status-transition ADR." <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
3. ADR-019 would carry its own Roadmap back-link (`Roadmap row: #07`) <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
   and the row would gain an `adr:` link — the same bidirectional
   contract #05/#06 exercise — giving #07 the same artifact shape as
   its siblings.

**Why the counter was not adopted:**

- ADR-017 and ADR-018 self-classified as new-ADR-worthy on a specific,
  stated discriminator: each introduced a **new detector + a new MECE
  contract boundary + a new exemption-keying rule** (ADR-017
  Alternative B; ADR-018 Alternative B). #07 introduces **none** of
  those — no detector, no boundary, no keying, no mechanism, no new
  glyph, no new workflow step. It assigns owners to transitions
  ADR-014's §Decision *already sanctioned* and whose formalization
  ADR-014 *itself pre-declared as its own deferred follow-up*
  ("not part of this ADR … until then"). The sibling-symmetry argument
  inverts on inspection: applying #05/#06's own stated discriminator to
  #07 yields "amendment," because the structural half that dominated
  for #05/#06 is absent for #07. This is the exact reasoning ADR-014's
  2026-05-16 line-budget amendment used to refuse its own ADR-015
  ("a clarification of a consequence of ADR-014's existing Decision …
  not a new structural decision") and ADR-018's 2026-05-17 amendment
  used to refine an already-decided ownership rule without a new
  number.
- Discoverability is *better*, not worse, as an ADR-014 amendment:
  glyph ownership is a property of the Roadmap mechanism ADR-014 owns;
  the canonical place a reader looks for "who may change a Roadmap
  cell" is the ADR that defined the Roadmap and already assigns
  row/link write-ownership. A separate ADR-019 would *fragment* the <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
  Roadmap-ownership contract across two ADRs — the orchestrator/
  architect would have to read ADR-014 *and* ADR-019 to know the full <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
  write-ownership picture, reintroducing exactly the "which document is
  authoritative" rediscovery ADR-014 exists to remove.
- The bidirectional-back-link argument is moot: ADR-014 has no
  milestone row of its own, so an amendment to it correctly carries
  *no* `Roadmap row:` line and triggers no #05 drift contract. Forcing
  a new ADR-019 purely to create a back-link manufactures the <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
  bidirectional artifact rather than reflecting a genuine
  structural decision.

**Trigger conditions for re-evaluating this counter-proposal:**

- A future milestone genuinely introduces a *workflow-state-machine
  engine* (new transitions, new states, an automated enforcement
  detector for *who* flipped a glyph) — that would be a new structural
  decision (new mechanism + new boundary) and would warrant its own
  ADR, with this amendment's matrix as its inherited baseline.
- The status-transition rule is found to require divergent ownership
  per project type (e.g. forks that drop `product-manager`), such that
  a single matrix in ADR-014 can no longer express it — at which point
  a dedicated ADR with per-profile matrices may be warranted.

The counter-proposal stays in this amendment as the historical record
of the decision's most serious objection, per the
ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 convention.

The original Status line (`Accepted — 2026-05-15`) is unchanged; this
amendment appends an ownership formalization of an already-sanctioned
mechanism and does not reopen the Decision.

## Amendment — 2026-05-17 (orchestrator Analyze row-guard)

This amendment closes the gap this ADR's own §Consequences → Negative
flagged verbatim: "Index↔reality drift. A Spec or ADR can be created
without the Roadmap row being updated, leaving the index stale. There
is no automated enforcement in this ADR … Until then,
ownership-by-artifact-producer is the only guard, and it depends on
agent prompt compliance." `specs/08-orchestrator-row-guard.md` (Roadmap
row #08) is the authoritative scope; it defers the structural *how* to
`architect` (its Risk R-01 (a)–(d), R-02, R-03). This amendment records
that decision. It is a **consequence-clarification of ADR-014's
existing Decision**, not a new structural decision: the §Decision
already makes the orchestrator's Analyze step a Roadmap read
("The orchestrator's Analyze step becomes a table read instead of a
repo scan") and already assigns the orchestrator a read-only Roadmap
contract ("`orchestrator` only reads the Roadmap"). #08 strengthens
*what that read must verify before the orchestrator dispatches work*.
No new detector, CI workflow, contract boundary, keying rule, or
mechanism is introduced — the guard reuses ADR-014's existing
Analyze-step entry point and ADR-016's existing `specs/NN-progress.md`
contract unchanged.

### The (b) decision — ADR-014 amendment, not new ADR-019, by the ADR-018 Alternative-B discriminator <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal; it is intentionally never created (see Counter-proposal below) -->

The Spec's R-01 (b) hands `architect` the explicit choice "ADR-014
amendment or a new ADR-019" and instructs the architect to apply <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
ADR-018's Alternative-B discriminator verbatim: *does #08 introduce a
NEW detector + a NEW MECE contract boundary + a NEW keying/mechanism
(⇒ new ADR), or is it a consequence-clarification / extension of an
existing ADR's already-sanctioned Decision (⇒ amendment)?* Applied
honestly, clause by clause:

- **New detector? No.** The Spec's Non-goals and Out of scope
  *explicitly forbid* a CI workflow ("Adding a new CI workflow file.
  #08 is a runtime orchestrator behavior change, not a static analysis
  addition"; "Enforcing the guard mechanically in CI (a possible
  future milestone, not #08)"). ADR-017 and ADR-018 each
  self-classified as new-ADR-worthy *because* each introduced a new
  script + new workflow (`check-roadmap-drift.sh` /
  `check-bilingual-parity.sh`). #08 introduces **zero** scripts and
  **zero** workflows. The structural half that dominated for
  ADR-017/ADR-018 is absent here.
- **New MECE contract boundary? No new partition.** A boundary
  *statement* is required (Spec Goal 4, R-03), but it does **not** add
  a fourth detector to the #04/#05/#06 detector-family contract
  partition. It states that #08 sits *outside* that partition
  entirely: #04/#05 are commit-time static checks; #08 is a runtime
  orchestrator behavior. This is a scope-delineation of where
  ADR-014's Analyze-step obligation lives, not a new keying rule like
  ADR-017's absence-of-claim or ADR-018's convention-presence.
- **New keying / mechanism? No.** There is no exemption-keying rule,
  no allowlist-vs-pattern choice, no parsing strategy, no new file
  artifact. The three guard conditions are *consequences* of
  invariants ADR-014 (the entry-point invariant; orchestrator
  read-only) and ADR-016 (the `specs/NN-progress.md` write-ownership)
  already established.
- **Consequence-clarification of an existing Decision? Yes,
  decisively.** ADR-014 §Consequences → Negative names the exact gap
  verbatim (quoted above). The #08 guard is the orchestrator's runtime
  obligation to refuse dispatch when ADR-014's entry-point invariant
  is unmet. This is the identical structural shape as the 2026-05-17
  status-transition amendment (#07), which closed a different
  ADR-014 §Consequences → Negative gap by amendment, not by ADR-019. <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->

**The sibling-symmetry argument inverts on inspection** (the same trap
the #07 amendment identified): "#05/#06 → ADR-017/ADR-018; therefore
#08 → ADR-019 for symmetry; and ADR-016 is a separate ADR though it <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
composes with ADR-014" — but applying #05/#06's *own stated
discriminator* to #08 yields **amendment**, because all three
structural clauses are absent. ADR-016 is a separate ADR because it
introduced a *new mechanism* (a new file artifact with its own
write-ownership / lifecycle / deletion-trigger contract); #08
introduces no new artifact and no new mechanism — it constrains the
*use* of two existing ones. **Decision: ADR-014 amendment. No
ADR-019 is created.** Roadmap row #08 stays `spec:`-only (Milestone → <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
ADR is 0:1; an amendment to the Roadmap-mechanism ADR is not #08's
*own* ADR — ADR-014 has no milestone row of its own, so adding an
`adr:` link from row #08 to ADR-014 would assert a milestone→ADR
mapping that does not exist — identical reasoning to the #07
amendment).

### The Analyze pre-dispatch guard (three named conditions, three routing outcomes)

ADR-014's §Decision makes the Analyze step a Roadmap read. This
amendment names the discrete preconditions that read must satisfy
*before the orchestrator dispatches any sub-agent for milestone work*.
Each condition has exactly one routing outcome; none auto-mutates the
Roadmap (the orchestrator stays read-only per ADR-014 §Decision):

| # | Guard condition | Routing outcome when unmet |
|---|---|---|
| G1 | A Roadmap row exists for the incoming task. | Surface the missing row to the user and route to `product-manager` to create the row (and author the Spec at pickup per the #07 `☐→◐` transition); the orchestrator does **not** dispatch any sub-agent and does **not** insert a row itself (ADR-014: orchestrator never writes rows). Re-run Analyze on the newly created row. |
| G2 | The row's `spec:` file exists on disk **whenever the next action would dispatch to `implementer` or `test-runner`** (R-02 resolution below). | Route to `product-manager` to author the Spec before that dispatch. A reserved-but-absent `spec:` on a `☐` row whose next action is *product planning or architecture* is the ADR-014 reservation rule's valid intermediate state and does **not** trip the guard. A `◐` row whose `spec:` is absent is an incomplete pickup: route to `product-manager` to author the missing Spec before any implementation dispatch. |
| G3 | For a `◐ in-progress` row, `specs/NN-progress.md` is present. | If absent, **state explicitly that no progress record exists** and fall back to re-deriving state from `git log`; do not assume any workflow step silently. This formalizes — as a named, visible guard condition rather than embedded prose — the fallback orchestrator.md Workflow step 1 already carries. The orchestrator remains read-only on the progress file (ADR-016 write-ownership unchanged). |

When G1–G3 are all satisfied the orchestrator proceeds to Assess
Feasibility (Workflow step 2) and the existing dispatch flow unchanged
— the guard adds a pre-dispatch gate, it does not alter any satisfied
path.

**(R-02) ☐-row dispatch-granularity sub-decision — resolved to the
simpler heuristic.** The Spec's R-02 hands the architect a choice: make
G2 introspect the intended downstream agent ("about to dispatch to
`implementer`/`test-runner`"), or collapse to the simpler heuristic
"if the row is `☐` and the Spec is absent, route to `product-manager`
first, regardless of intended downstream agent." **Decision: adopt the
simpler heuristic.** Rationale: (1) it is *safe* — `product-manager`
authoring the Spec and flipping `☐→◐` (the #07 transition) is exactly
what a `☐` row owes at pickup anyway, so routing there first never
produces a wrong outcome; (2) it removes downstream-agent introspection
from guard-evaluation time, keeping the guard a flat precondition check
(KISS) rather than a branch on a not-yet-decided dispatch target; (3)
it cannot under-fire — the failure mode the guard exists to prevent
("`implementer` dispatched without a Spec on disk") is structurally
impossible once any `☐`+absent-Spec row routes to `product-manager`
before *any* dispatch. The G2 row above is therefore read as: *a `☐`
row with an absent `spec:` file routes to `product-manager` first; a
`◐` row with an absent `spec:` file is an incomplete pickup and also
routes to `product-manager`; a `☐` row whose Spec already exists on
disk proceeds normally.* No downstream-agent test is evaluated at the
guard. (The Spec's parenthetical "a `☐` row whose next action is
product planning or architecture does not trigger this guard" is
preserved in effect: routing such a row to `product-manager` *is* its
next action — the heuristic and the Spec's carve-out converge, they do
not conflict.)

### (a) Documentation placement — orchestrator.md Workflow step 1, as a named guard, zero extra file reads

The guard conditions live in **`.claude/agents/orchestrator.md`
Workflow step 1 (Analyze)** as a named, discrete pre-dispatch check —
**not** in a CLAUDE.md Roadmap Rules bullet, **not** in a new CI
script, **not** duplicated across agent prompts. Rationale, against the
Spec's R-01 (a) "zero additional file reads at the Analyze step"
criterion:

- **The orchestrator already reads orchestrator.md to execute the
  Analyze step.** Workflow step 1 is *where* the orchestrator reads the
  Roadmap row and (for `◐` rows) the progress file. Naming the guard
  inside that exact step means the orchestrator encounters G1–G3 at the
  precise moment it performs the read, with **zero additional file
  reads** — the R-01 (a) criterion is met by construction. A CLAUDE.md
  Rules bullet would also be zero-extra-read (CLAUDE.md is always
  read), but the guard is *orchestrator runtime behavior*, not a
  Roadmap-mechanism property; the Rules block governs *who may write a
  Roadmap cell* (the #07 home), whereas #08 governs *what the
  orchestrator must verify before it dispatches*. Placement follows the
  contract owner: glyph-ownership → Rules block (#07); Analyze-dispatch
  precondition → the Analyze step (#08).
- **It is the tightest placement respecting the CLAUDE.md line-budget
  guidance.** orchestrator.md is not line-budget-constrained; CLAUDE.md
  is (this ADR's 2026-05-16 line-budget amendment). Putting #08 in
  orchestrator.md spends zero CLAUDE.md budget. This deliberately
  *differs* from #07's placement decision: #07 was a single Rules-block
  bullet about Roadmap-cell write-ownership (index-mechanism, Rules
  block by nature); #08 is a multi-condition runtime guard about
  orchestrator dispatch behavior (agent-behavior, agent-prompt by
  nature). Different contracts, different correct homes — not an
  inconsistency.
- **It is index-consistent and single-source.** The guard is the
  natural completion of Workflow step 1's existing progress-file
  fallback prose (G3 *is* that prose, promoted to a named condition).
  G1/G2 extend the same step's existing "locate the target milestone
  row and open only its linked design source" sentence with the
  precondition that the row and (for implementation dispatch) the Spec
  must actually exist. One source, in the step that already owns the
  behavior.

### (c) orchestrator.md edit scope + claude-md-authoring Skill judgement

- **orchestrator.md requires direct editing — the Analyze step
  (Workflow step 1) only.** No other section of orchestrator.md
  changes; no other agent prompt changes (`product-manager.md`,
  `architect.md`, `implementer.md`, `test-runner.md` are untouched —
  the guard *routes to* `product-manager`, but `product-manager`'s
  existing ADR-014 row+Spec write-ownership and the #07 `☐→◐` trigger
  already cover what it must do on receipt; no new prompt line is owed
  there).
- **claude-md-authoring Skill: NOT required for the orchestrator.md
  edit.** The Skill's scope (per CLAUDE.md `## CLAUDE.md authoring
  guidance` and ADR-007) is "creating or significantly restructuring"
  `CLAUDE.md` / `README.md` / `.claude/agents/*.md`. orchestrator.md is
  a `.claude/agents/*.md` file, so it is *in the file scope*, but the
  #08 edit is **not significant restructuring**: it extends one
  existing Workflow step's existing prose with a named guard
  (no new top-level section, no heading-tree change, no invariant
  touched, no role added). It is closer to the "routine small edit"
  carve-out than to "significant restructuring." **Judgement: the
  claude-md-authoring Skill is NOT required for the #08 implementation
  edit.** (If the implementer instead chooses to add a new `##`-level
  section to orchestrator.md or restructure the Workflow list, that
  *would* cross into restructuring and the Skill would then apply — the
  design here is deliberately an in-step named-guard extension to stay
  under the routine-edit threshold. Note also: ADR-014's existing
  References already say "`.claude/agents/orchestrator.md` — Analyze
  step gains a 'read the Roadmap row first' instruction (downstream
  task)" — the #08 guard is the same Analyze-step contract being
  tightened, in the same step, by the same downstream-task discipline.)
- **No CLAUDE.md edit.** Unlike #07 (a Roadmap Rules-block bullet),
  #08 adds nothing to CLAUDE.md. The guard is agent-behavior, not a
  Roadmap-mechanism rule. CLAUDE.md's existing Development Workflow and
  the `specs/NN-progress.md` paragraph already point at orchestrator.md
  Workflow step 1 as the Analyze authority; no CLAUDE.md change is
  owed.

### (d) MECE boundary statement against #04 / #05 / #07 (R-03)

The boundary is drawn on **trigger point + contract**, restated here
so a future milestone author cannot mis-route a runtime concern to a
static detector or vice versa:

| Milestone | Owns the question | Trigger point |
|---|---|---|
| #04 `check-dangling-refs.sh` | Does a path/reference in document prose **resolve** to a real file/ADR? | commit time (CI) |
| #05 `check-roadmap-drift.sh` | Does the **bidirectional Roadmap-index contract** hold and is every Status glyph **well-formed**? | commit time (CI) |
| #07 (ADR-014 2026-05-17 matrix) | **Who** may flip a Status glyph and **when**? | process/documentation (no CI) |
| #08 (this amendment) | Are the orchestrator's **Analyze preconditions met before it dispatches** (row exists; Spec on disk for an implementation dispatch; `◐` progress file present-or-explicitly-absent)? | **runtime** (orchestrator behavior, no CI) |

A defect maps to exactly one owner: a *broken prose path* is #04's
(commit-time resolution); a *consistent-pointer-but-inconsistent-
Roadmap-contract or malformed glyph* is #05's (commit-time
consistency); a *who/when may a glyph change* question is #07's
(process ownership); a *the orchestrator is about to dispatch against a
missing row / reserved-but-absent Spec / unstated missing progress
file* is #08's (runtime precondition). **(R-03 adjacency, explicit):**
#05's Non-goals already exclude checking whether a reserved `spec:`
link resolves to a file on disk — ADR-017 §1 keys "consistency when a
claim is present, never universality," and a reserved `spec:` for a
`☐` row is valid-by-design absent. That same reserved-but-absent
`spec:` *becomes* a defect **only at runtime, only when the
orchestrator is about to dispatch implementation** — which is #08's
contract, not #05's. #05 asks "is the Roadmap structurally valid?" at
commit time; #08 asks "are the Analyze preconditions met?" at runtime.
The reservation-rule carve-out is the seam: #05 deliberately does not
look, #08 deliberately does — at a different trigger point, for a
different contract. No two-owner ambiguity exists.

### Composability with ADR-016 and #07 (no ownership gap)

- **ADR-016 (`specs/NN-progress.md`).** G3 formalizes the orchestrator's
  named behavior when a `◐` row's progress file is absent. ADR-016
  §write-ownership reserves create/update/delete to
  `product-manager`/`implementer`; the orchestrator only reads. G3's
  "state explicitly and fall back to `git log`" is read-only and
  consistent with ADR-016 unchanged — it adds no write, only a named
  visible diagnostic where prose previously implied one.
- **#07 (status-transition matrix).** When G1/G2 route to
  `product-manager` to create a row or author a Spec, that authoring
  action *is* the #07 `☐→◐` transition `product-manager` already owns.
  #08 supplies the orchestrator-side precondition that *triggers* the
  pickup; #07 owns the pickup ownership itself. The two are composable
  with no gap: #08 says "the orchestrator must not dispatch
  implementation until a Spec is on disk"; #07 says
  "`product-manager` flips `☐→◐` atomically with authoring that Spec."
  Same boundary, two complementary sides.

### Downstream implementer tasks (recorded for traceability, not performed by this amendment — implementation is a future session, per the #03/ADR-016 · #05/ADR-017 · #06/ADR-018 · #07/ADR-014-amendment two-session decision-then-implementation split)

- `.claude/agents/orchestrator.md` **Workflow step 1 (Analyze)** —
  extend the existing step prose with a named pre-dispatch guard
  carrying the three conditions G1–G3 and their routing outcomes
  exactly as tabulated above, using the **simpler R-02 heuristic** (a
  `☐` or `◐` row with an absent `spec:` file routes to
  `product-manager` first; no downstream-agent introspection at the
  guard). G3 must be phrased as a *named, visible* condition, absorbing
  and replacing the current informal "If that file is absent, state
  explicitly that no progress record exists and fall back to
  re-deriving state from `git log`" sentence (do not duplicate it —
  promote it into the named guard). Keep it an **in-step extension**:
  no new `##`-level section, no Workflow-list restructuring — stay
  under the routine-edit threshold so the claude-md-authoring Skill is
  not triggered (judgement (c) above).
- **No other agent-prompt edits.** The implementer must **not** add
  guard prose to `product-manager.md`, `architect.md`,
  `implementer.md`, or `test-runner.md`; orchestrator.md Workflow step
  1 is the single source. `product-manager`'s receipt behavior is
  already covered by its ADR-014 row+Spec write-ownership and the #07
  `☐→◐` trigger.
- **No CLAUDE.md edit** (judgement (c)): #08 is agent-behavior, not a
  Roadmap-mechanism rule; CLAUDE.md's Development Workflow and
  `specs/NN-progress.md` paragraph already point at orchestrator.md
  Workflow step 1.
- **No CI workflow and no script** (Spec Non-goals / Out of scope:
  "#08 is a runtime orchestrator behavior change, not a static analysis
  addition"; mechanical CI enforcement is an explicitly-deferred
  possible future milestone, not #08 — distinct from #04/#05's
  commit-time checks per the (d) MECE table).
- **No Roadmap row change.** Row #08's `Design source` cell stays
  `spec:`-only — this is an ADR-014 amendment, ADR-014 has no milestone
  row of its own, so no `adr:` link is added to row #08 (Milestone →
  ADR is 0:1; identical to the #07 amendment's row-#07 reasoning).
- The Japanese counterpart of this ADR
  (`014-roadmap-index-single-entry-point.ja.md`) must receive the
  mirrored amendment — a `technical-writer` task, **not** part of this
  change. **This amendment creates a transient EN/JA heading mismatch
  on ADR-014 (EN gains one `##`-level heading plus its `###`
  sub-headings; JA is at 18 headings, in parity before this change)
  until `technical-writer` mirrors it; the #06 bilingual-parity
  detector (`check-bilingual-parity.sh`, when shipped) will FAIL on
  ADR-014 until the mirror lands. This is the expected, queued
  `technical-writer` task — not a reason to omit this EN amendment**,
  exactly as the 2026-05-17 status-transition amendment did.

### Counter-proposal

The serious counter-position is **new ADR-019 — formalize the <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
Analyze pre-dispatch guard as a standalone ADR rather than an ADR-014
amendment**. It is recorded here per the
ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 convention of
taking a rejected alternative seriously rather than as a strawman. The
argument:

1. The Spec hands `architect` an explicit (c) choice ("ADR-014
   amendment or a new ADR-019") and structurally parallel sibling <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
   milestones #05 and #06 both resolved their deferred-structural-
   question Specs with *new* ADRs (017, 018). Symmetry of process
   argues #08 → ADR-019. <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
2. A named pre-dispatch guard with three conditions and three routing
   outcomes that four agent roles (orchestrator, product-manager,
   implementer, template maintainer) must honor at runtime is a
   first-class, citable behavioral contract — arguably like ADR-016,
   which is a separate ADR even though it composes with ADR-014.
   Burying it as the fourth amendment in a long ADR-014 trail makes it
   less discoverable than a dedicated ADR-019 a reader can cite as <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
   "the Analyze-guard ADR."
3. ADR-019 would carry its own Roadmap back-link (`Roadmap row: #08`) <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
   and the row would gain an `adr:` link — the same bidirectional
   contract #05/#06 exercise — giving #08 the same artifact shape as
   its siblings.

**Why the counter was not adopted:**

- ADR-017 and ADR-018 self-classified as new-ADR-worthy on a specific,
  stated discriminator: each introduced a **new detector + a new MECE
  contract boundary + a new exemption-keying rule** (ADR-017
  Alternative B; ADR-018 Alternative B). #08 introduces **none** of
  those — the Spec's Non-goals and Out of scope *explicitly forbid* a
  new CI workflow or script ("#08 is a runtime orchestrator behavior
  change, not a static analysis addition"); the MECE statement is a
  scope-delineation placing #08 *outside* the detector-family
  partition, not a fourth partition within it; and there is no
  exemption keying, no new file artifact, no new mechanism. It
  strengthens what the orchestrator's Analyze read (ADR-014 §Decision)
  must verify before dispatch — closing the *exact* gap ADR-014
  §Consequences → Negative pre-flagged. The sibling-symmetry argument
  inverts on inspection: applying #05/#06's own stated discriminator to
  #08 yields "amendment," because the structural half that dominated
  for #05/#06 is absent for #08. This is the identical reasoning
  ADR-014's 2026-05-16 line-budget amendment used to refuse its own
  ADR-015, ADR-018's 2026-05-17 amendment used to refine an
  already-decided rule without a new number, and the 2026-05-17
  status-transition (#07) amendment used to refuse ADR-019. <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
- The ADR-016 analogy fails on inspection. ADR-016 is a separate ADR
  because it introduced a **new mechanism** — a new file artifact
  (`specs/NN-progress.md`) with its own write-ownership, lifecycle, and
  deletion-trigger contract. #08 introduces **no new artifact and no
  new mechanism**; it constrains the *use* of two artifacts ADR-014
  (the Roadmap row) and ADR-016 (the progress file) already define. A
  guard over existing mechanisms is a consequence-clarification of
  those mechanisms' owning Decisions, not a new mechanism.
- Discoverability is *better*, not worse, as an ADR-014 amendment: the
  canonical place a reader looks for "what must the orchestrator verify
  about the Roadmap before it dispatches" is the ADR that defined the
  Roadmap, made the Analyze step a Roadmap read, and already assigns
  the orchestrator its read-only Roadmap contract. A separate ADR-019 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
  would *fragment* the Analyze-step contract across two ADRs — the
  orchestrator would have to read ADR-014 *and* ADR-019 to know its <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
  full Analyze obligation, reintroducing exactly the "which document is
  authoritative" rediscovery ADR-014 exists to remove.
- The bidirectional-back-link argument is moot: ADR-014 has no
  milestone row of its own, so an amendment to it correctly carries
  *no* `Roadmap row:` line and triggers no #05 drift contract. Forcing
  a new ADR-019 purely to manufacture a back-link creates the <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
  bidirectional artifact rather than reflecting a genuine structural
  decision — identical to the #07 amendment's resolution of the same
  objection.

**Trigger conditions for re-evaluating this counter-proposal:**

- A future milestone genuinely adds a *mechanical CI enforcement* of
  the guard (a new detector that statically verifies the orchestrator
  honored G1–G3, or that a dispatched milestone had a Spec on disk) —
  that would be a new detector + new boundary + new keying, the
  ADR-017/ADR-018 discriminator's structural half, and would warrant
  its own ADR with this amendment's guard as its inherited baseline.
  The Spec explicitly flags this as "a possible future milestone, not
  #08."
- The guard is found to require divergent behavior per project type
  (e.g. forks that drop `product-manager` need a different routing
  target), such that a single guard in ADR-014 can no longer express
  it — at which point a dedicated ADR with per-profile guard variants
  may be warranted.
- A new always-read runtime contract for a *different* agent (not the
  orchestrator's Analyze step) is added that composes with but is not a
  consequence of ADR-014's Decision — a genuinely new mechanism like
  ADR-016, which would warrant its own ADR.

The counter-proposal stays in this amendment as the historical record
of the decision's most serious objection, per the
ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 convention.

## Amendment — 2026-05-17 (spec filename convention)

This amendment makes normative the filename convention this ADR's
2026-05-16 **Spec reservation rule** amendment already *uses* but never
*states as a named rule*. That amendment fixed the reserved-link path
as the deterministic form `specs/NN-slug.md` ("using the deterministic
path `specs/NN-slug.md` where `NN` is the stable row number"); all
eight Spec files authored to date (`specs/01-*.md` … `specs/08-*.md`)
already conform. `specs/09-spec-filename-convention.md` (Roadmap row
#09) is the authoritative scope; it states *what* the convention must
cover (canonical form, two-digit-minimum zero-padding, the 100+
extension rule, the `specs/NN-slug.ja.md` sibling, the
`specs/NN-progress.md` exclusion) and defers the structural *how* to
`architect` (its Risk R-01 (a)–(d), R-02, R-03). This amendment records
that decision. It is a **consequence-clarification of ADR-014's
existing Decision** — specifically of the already-accepted 2026-05-16
Spec-reservation amendment, whose reserved path *is* `specs/NN-slug.md`
— not a new structural decision. No new detector, CI workflow, contract
boundary, keying rule, or mechanism is introduced: the convention names
the filename component of a path scheme ADR-014 already mandates, and
the `specs/NN-progress.md` carve-out is a restatement of ADR-016's
existing lifecycle, not a new rule.

### The (b) decision — ADR-014 amendment, not new ADR-019, by the ADR-018 Alternative-B discriminator <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal; it is intentionally never created (see Counter-proposal below) -->

The Spec's R-01 (b) hands `architect` the explicit choice "ADR-014
amendment or a new ADR-019" and instructs the architect to apply <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
ADR-018's Alternative-B discriminator verbatim: *does #09 introduce a
NEW detector + a NEW MECE contract boundary + a NEW keying/mechanism
(⇒ new ADR), or is it a consequence-clarification / extension of an
existing ADR's already-sanctioned Decision (⇒ amendment)?* Applied
honestly, clause by clause:

- **New detector? No.** The Spec's Non-goals and Out of scope
  *explicitly forbid* a CI filename-format detector ("Adding a new CI
  detector that mechanically checks filename conformance. … #09 is a
  documentation/convention-statement milestone; CI enforcement is an
  optional consequence, not a deliverable of this milestone";
  "Adding a CI filename-format check — a structural decision deferred
  to the architect"). ADR-017 and ADR-018 each self-classified as
  new-ADR-worthy *because* each introduced a new script + new workflow
  (`check-roadmap-drift.sh` / `check-bilingual-parity.sh`). #09
  introduces **zero** scripts and **zero** workflows. The structural
  half that dominated for ADR-017/ADR-018 is absent here — identical to
  the #07 amendment (no detector) and the #08 amendment (Non-goals
  forbid a CI workflow).
- **New MECE contract boundary? No new partition.** A boundary
  *statement* is required (Spec Goal 5, Acceptance criterion, R-02),
  but it does **not** add a fourth detector to the #04/#05/#06
  detector-family contract partition. It states that #09 sits *outside*
  that partition entirely: #09 is a documentation/convention statement
  about the *filename of the reserved `spec:` path* ADR-014's
  reservation rule already produces, and against the *adjacent
  directory milestone #10*. This is a scope-delineation of where an
  ADR-014 reservation-rule consequence lives, not a new keying rule
  like ADR-017's absence-of-claim or ADR-018's convention-presence.
- **New keying / mechanism? No.** There is no exemption-keying rule, no
  allowlist-vs-pattern choice, no parsing strategy, no new file
  artifact. `specs/NN-slug.md` is *already* the deterministic path the
  2026-05-16 Spec-reservation amendment mandates for every reserved
  `spec:` link; #09 names that already-used form normative for the
  files too. The `specs/NN-progress.md` exclusion is a *consequence* of
  ADR-016's already-established progress-file lifecycle
  (created at session boundary, deleted at `◐→☑`/`◐→✗`), not a new
  mechanism this amendment introduces.
- **Consequence-clarification of an existing Decision? Yes,
  decisively.** ADR-014's 2026-05-16 Spec-reservation amendment already
  uses `specs/NN-slug.md` verbatim as the reserved-path scheme keyed to
  the immutable row number. The #09 convention is the statement, as a
  named normative rule, of the filename component of that
  already-sanctioned path. This is the identical structural shape as
  the 2026-05-17 status-transition amendment (#07), which formalized an
  interim practice ADR-014 §Consequences → Negative pre-flagged, and
  the 2026-05-17 Analyze row-guard amendment (#08), which strengthened
  what ADR-014's Analyze read must verify — both resolved by ADR-014
  amendment, not by ADR-019. <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->

**The sibling-symmetry argument inverts on inspection** (the same trap
the #07 and #08 amendments identified): "#05/#06 → ADR-017/ADR-018;
therefore #09 → ADR-019 for symmetry" — but applying #05/#06's *own <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
stated discriminator* to #09 yields **amendment**, because all three
structural clauses (new detector, new partition, new keying/mechanism)
are absent. ADR-016 is a separate ADR because it introduced a *new
mechanism* (a new file artifact with its own write-ownership /
lifecycle / deletion-trigger contract); #09 introduces no new artifact
and no new mechanism — it names the filename form of an artifact
(`specs/NN-slug.md`) ADR-014's own reservation amendment already
defines, and explicitly *excludes* `specs/NN-progress.md` by deferring
entirely to ADR-016's mechanism. **Decision: ADR-014 amendment. No
ADR-019 is created.** Roadmap row #09 stays `spec:`-only (Milestone → <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
ADR is 0:1; an amendment to the Roadmap-mechanism ADR is not #09's
*own* ADR — ADR-014 has no milestone row of its own, so adding an
`adr:` link from row #09 to ADR-014 would assert a milestone→ADR
mapping that does not exist — identical reasoning to the #07 and #08
amendments).

### The normative filename convention

The convention names the filename component of the `specs/NN-slug.md`
path the 2026-05-16 Spec-reservation amendment already mandates. It
adds no new path scheme; it states the existing one as a named rule:

| Rule | Statement | Source it clarifies |
|---|---|---|
| Canonical Spec filename | A Spec file is `specs/NN-slug.md`, where `NN` is the Roadmap row number zero-padded to a **minimum of two digits** and `slug` is the kebab-case slug **already fixed in the row's reserved `spec:` path** (so there is no authoring-time ambiguity — `product-manager` copies the slug from the Roadmap row, it does not re-derive it). | ADR-014 2026-05-16 Spec-reservation amendment (the reserved path *is* this form). |
| 100+ extension | The two-digit minimum pads single-digit rows only (`1→01`); rows already multi-digit are written without extra padding (`100`, `101`, …). Stable with the row-number convention (numbers never reused/renumbered). | ADR-014 §Decision "row number is stable and never reused." |
| JA sibling filename | The Japanese sibling is `specs/NN-slug.ja.md` — same `NN`, same `slug`, `.ja` inserted before `.md`. Its heading-tree parity with the EN primary is **owned by #06 / ADR-018**; this convention states only the *filename form* of the sibling, it does not redefine or extend the parity check. | ADR-018 (parity check owns content parity; this convention owns the sibling's name). |
| `specs/NN-progress.md` exclusion | `specs/NN-progress.md` shares the `specs/` directory and the `NN` prefix but is **not** a Spec file and is **excluded** from the `NN-slug.md` requirement. `progress` is a reserved suffix under ADR-016's lifecycle (created at the session/compaction boundary while `◐`, deleted at the `◐→☑`/`◐→✗` flip); its naming and lifecycle are governed entirely by ADR-016, never by this convention. | ADR-016 §write-ownership / §retirement (the carve-out is a restatement of ADR-016, not a new rule). |

The convention is **retroactively consistent with every existing Spec
file** (`specs/01-*.md` … `specs/08-*.md` all conform), confirming this
is a convention-*statement* amendment, not a bulk-rename — exactly the
"retroactively consistent with every historical [artifact], not a
behavior change" property the #07 amendment established for the
status-transition matrix.

### (a) Documentation placement — the CLAUDE.md `## Roadmap` Rules block, one added bullet, zero extra file reads

The convention lives in the **CLAUDE.md `## Roadmap` Rules block** as
one added bullet — **not** in the spec-template's `## How to use this
template` block, **not** in a new CI script, **not** duplicated into
agent prompts. Rationale, against the Spec's R-01 (a) "encountered at
the Spec-authoring step without an additional file read" criterion:

- **`product-manager` already reads the CLAUDE.md `## Roadmap` section
  to author a Spec.** The 2026-05-16 Spec-reservation amendment lives
  in that exact Rules block, and `product-manager`'s ADR-014
  write-ownership (create/update the row + reserved `spec:` link) is
  already exercised there. The filename convention is the named
  completion of the *same* reservation rule — `product-manager` reads
  the reserved `specs/NN-slug.md` path from the row it owns and authors
  the file at that path. Stating the convention one bullet below the
  reservation rule means `product-manager` encounters it at the precise
  moment it authors the Spec, with **zero additional file reads** — the
  R-01 (a) criterion is met by construction. The spec-template's
  `## How to use this template` block is read *only if the author opens
  the template*, which is one extra file read and is not guaranteed
  (the convention must hold even when an experienced agent skips the
  template) — so the template is the wrong single source.
- **This deliberately mirrors #07's placement, not #08's, because the
  contract is index-mechanism, not agent-runtime-behavior.** #07 (a
  Roadmap-cell write-ownership rule) went in the Rules block; #08 (an
  orchestrator runtime dispatch precondition) went in orchestrator.md
  Workflow step 1. #09 is a property of the Roadmap mechanism itself
  (what the reserved `spec:` path's filename *is*), exactly the
  contract class the Rules block governs — it already states the
  reservation rule, the row/link write-ownership, the glyph set, and
  the #07 transition matrix. The filename convention is the natural
  completion of the existing "Spec reservation rule" / "`spec:` paths
  are reserved at row-creation" bullet, not a new concept in a new
  place. Placement follows the contract owner, exactly as the #08
  amendment reasoned ("glyph-ownership → Rules block (#07);
  Analyze-dispatch precondition → the Analyze step (#08)").
- **It respects the CLAUDE.md line-budget guidance by living in the
  one already-exempt section.** The `## Roadmap` section is the
  sanctioned line-budget exception (this ADR's 2026-05-16 line-budget
  amendment, restated in CLAUDE.md's `## CLAUDE.md authoring
  guidance`). One added bullet to an already-exempt section costs no
  budget elsewhere — identical to the #07 amendment's placement
  rationale. Adding prose to a non-exempt section (e.g. a new
  `## Spec filename convention` heading) would bloat the budget and
  cross into restructuring (judgement (c) below).

The exact one-bullet wording is handed to `implementer` below; the
MECE boundary (next section) is restated *in that bullet* so a future
milestone author does not route a directory question to #09 or a
filename question to #10.

### (c) Edit scope + claude-md-authoring Skill judgement

- **CLAUDE.md requires editing — the `## Roadmap` Rules block only.**
  One bullet appended after the existing reservation-rule guidance. No
  other CLAUDE.md section changes.
- **`product-manager.md` does NOT require editing.** The convention
  names the filename of the reserved `spec:` path `product-manager`
  already owns under ADR-014 (row + `spec:` link write-ownership) and
  already authors at the #07 `☐→◐` pickup transition. Authoring the
  file *at the reserved path* is the existing write-ownership; the
  convention makes the *form* of that path explicit in the Rules block
  `product-manager` already reads, not a new prompt obligation. This is
  the identical reasoning the #07 amendment used to conclude "no agent
  prompt requires editing" (the matrix made an already-owned row write
  explicit in the Rules block, not in the prompt) and the #08
  amendment used for `product-manager.md` ("`product-manager`'s receipt
  behavior is already covered by its ADR-014 row+Spec write-ownership
  and the #07 `☐→◐` trigger").
- **The spec-template does NOT require editing.** The template's
  `## References` already carries a `Roadmap row: #NN` back-link
  example (ADR-014's original downstream task). The filename is a
  property of *where the file is created*, governed by the Roadmap
  reservation rule the Rules-block bullet states; the template's
  *content* is unaffected. Adding a filename note to the template would
  create a second source for the same rule (a Rules-block bullet *and*
  a template line), reintroducing exactly the "which document is
  authoritative" rediscovery ADR-014 exists to remove. Single source:
  the Rules block.
- **claude-md-authoring Skill: NOT required for the #09 CLAUDE.md
  edit.** The deferred CLAUDE.md edit is **one bullet appended to the
  existing `## Roadmap` Rules list** — a "routine small edit (…
  single bullet …)" by the explicit carve-out in CLAUDE.md's
  `## CLAUDE.md authoring guidance` section ("Routine small edits
  (typo, single bullet, version bump) do not need the Skill"). It is
  **not** "significant restructuring" (no section added/moved/split, no
  heading change, no invariant touched). **Judgement: the
  claude-md-authoring Skill is NOT required for the #09 implementation
  edit** — the identical judgement and the identical reasoning the #07
  amendment recorded for its single-bullet Rules-block edit. (If the
  implementer instead chooses to add a `##`-level "Spec filename
  convention" section or a table to CLAUDE.md, that *would* cross into
  restructuring and the Skill would then apply — the design here is
  deliberately a single bullet precisely to stay under the routine-edit
  carve-out, exactly as #07 was.)

### (d) MECE boundary statement against #04 / #05 / #10 / ADR-014-reservation-rule / ADR-016-progress-files (R-02)

The boundary is drawn on **what each owns**, restated here and in the
implementer's bullet so a future milestone author cannot mis-route a
filename concern to a directory pin, a path-resolution detector, or a
progress-file lifecycle:

| Owner | Owns the question | Trigger point |
|---|---|---|
| #04 `check-dangling-refs.sh` | Does a path/reference in document prose **resolve** to a real file/ADR? | commit time (CI) |
| #05 `check-roadmap-drift.sh` | Does the **bidirectional Roadmap-index contract** hold and is every Status glyph **well-formed**? | commit time (CI) |
| #10 (Spec/ADR directory pin) | **Which directory** do Spec/ADR files live in (`specs/`, `.claude/meta/adr/`)? | documentation/convention (no CI in #10's own scope) |
| #09 (this amendment) | **What is the filename form** of a Spec file inside `specs/` (`NN-slug.md`, two-digit-min, JA sibling form)? | documentation/convention (no CI; CI is an explicitly-deferred optional consequence, not #09) |
| ADR-014 reservation rule | *That* every row carries a reserved `spec:` link at row-creation, keyed to the immutable row number. | row-creation (process) |
| ADR-016 progress files | The `specs/NN-progress.md` *lifecycle* (create at boundary, delete at flip). `progress` is its reserved suffix; **excluded** from #09's `NN-slug.md` rule. | session/compaction boundary (process) |

A concern maps to exactly one owner: a *broken prose path* is #04's
(commit-time resolution); a *malformed glyph or broken bidirectional
ADR-link* is #05's (commit-time consistency); *which directory a Spec
lives in* is #10's; *what a Spec file is named inside that directory*
is #09's; *that a reserved link exists at all* is the ADR-014
reservation rule's; *how `specs/NN-progress.md` is born and retired* is
ADR-016's. The full canonical path `specs/NN-slug.md` is the
**composition** of #10's directory scope and #09's filename scope:
neither subsumes the other, and a future author uncertain about
directory reads #10 while one uncertain about filename reads #09. The
`specs/NN-progress.md` seam is explicit: it shares #09's directory and
`NN` prefix but its naming and lifecycle are ADR-016's entirely — #09
deliberately does not govern it, exactly as the #08 amendment's MECE
table drew the reserved-but-absent-`spec:` seam between #05 (does not
look) and #08 (does look, at a different trigger).

### Composability with ADR-014's reservation rule, ADR-016, and #06/ADR-018 (no gap)

- **ADR-014 2026-05-16 Spec-reservation amendment.** #09 names the
  filename component of the `specs/NN-slug.md` reserved path that
  amendment already mandates. The two are composable with no gap: the
  reservation amendment says *a reserved `spec:` link of form
  `specs/NN-slug.md` is present from row-creation*; #09 says *the file
  authored at pickup uses exactly that already-reserved name*. #09 adds
  no second path scheme; it states the existing one as normative.
- **ADR-016 (`specs/NN-progress.md`).** #09 excludes progress files by
  deferring entirely to ADR-016's lifecycle. ADR-016
  §write-ownership/§retirement remains the sole authority for
  `specs/NN-progress.md`; #09 adds no write, no lifecycle rule, only a
  named statement that `progress` is a reserved suffix outside the
  `NN-slug.md` requirement — read-only with respect to ADR-016, exactly
  as the #08 amendment's G3 was read-only with respect to ADR-016's
  write-ownership.
- **#06 / ADR-018 (bilingual parity).** #09 states the JA sibling's
  *filename form* (`specs/NN-slug.ja.md`); ADR-018 owns the JA file's
  *heading-tree/full-width-paren content parity*. Both must hold for a
  conformant bilingual Spec: #09 governs the sibling's name, #06
  governs its structure. No overlap — a naming defect is #09's, a
  heading-order defect is #06's.

### Downstream implementer tasks (recorded for traceability, not performed by this amendment — implementation is a future session, per the #03/ADR-016 · #05/ADR-017 · #06/ADR-018 · #07/ADR-014-amendment · #08/ADR-014-amendment two-session decision-then-implementation split)

- `.claude/CLAUDE.md` `## Roadmap` **Rules** block — append one bullet
  after the existing reservation-rule guidance (the "**Spec
  reservation rule:**" paragraph / the "`spec:` paths are reserved at
  row-creation" Rules bullet), of the form: *"Spec filename convention:
  a Spec file is `specs/NN-slug.md` where `NN` is the row number
  zero-padded to a two-digit minimum (`1→01`; rows ≥100 written without
  extra padding) and `slug` is the kebab-case slug already fixed in the
  row's reserved `spec:` path (copy it from the row, do not re-derive).
  The JA sibling is `specs/NN-slug.ja.md` (same `NN`/`slug`, `.ja`
  before `.md`); its heading-tree parity is owned by #06.
  `specs/NN-progress.md` is excluded — `progress` is ADR-016's reserved
  suffix, governed by ADR-016's lifecycle, not by this convention. #10
  pins the directory; #09 pins the filename — MECE."* Single bullet, no
  sub-heading, no table — stays within the routine-edit carve-out (no
  claude-md-authoring Skill invocation required; judgement (c) above).
- **No agent-prompt edits** (judgement (c) above). The implementer must
  **not** add filename-convention prose to `product-manager.md`,
  `orchestrator.md`, `architect.md`, or `implementer.md`; the Rules
  block is the single source. `product-manager`'s authoring-at-the-
  reserved-path behavior is already covered by its ADR-014 row+`spec:`
  write-ownership and the #07 `☐→◐` pickup trigger.
- **No spec-template edit** (judgement (c) above). The template's
  `## References` `Roadmap row: #NN` example is unaffected; the
  filename is a property of the reserved path the Rules-block bullet
  states, not of template content. Adding a template note would create
  a second source for the same rule.
- **No CI workflow and no script** (Spec Non-goals / Out of scope:
  "#09 is a documentation/convention-statement milestone; CI
  enforcement is an optional consequence, not a deliverable"; "Adding a
  CI filename-format check — a structural decision deferred to the
  architect"). A future mechanical filename-format check is a possible
  later milestone, **not** #09, and would be re-evaluated under the
  Counter-proposal trigger conditions below — distinct from #04/#05's
  commit-time checks per the (d) MECE table.
- **No renames.** All eight existing Spec files conform; #09 is a
  convention-statement, not a bulk-rename (Spec Non-goals).
- **No Roadmap row change.** Row #09's `Design source` cell stays
  `spec:`-only — this is an ADR-014 amendment, ADR-014 has no milestone
  row of its own, so no `adr:` link is added to row #09 (Milestone →
  ADR is 0:1; identical to the #07 and #08 amendments' row reasoning).
- The Japanese counterpart of this ADR
  (`014-roadmap-index-single-entry-point.ja.md`) must receive the
  mirrored amendment, and the Japanese counterpart of CLAUDE.md (if
  present) the mirrored Rules-block bullet — a `technical-writer`
  task, **not** part of this change. **This amendment creates a
  transient EN/JA heading mismatch on ADR-014 (EN gains one `##`-level
  heading plus its `###` sub-headings; JA was in heading parity before
  this change) until `technical-writer` mirrors it; the #06
  bilingual-parity detector (`check-bilingual-parity.sh`, now shipped)
  will FAIL on ADR-014 until the mirror lands. This is the expected,
  queued `technical-writer` task — not a reason to omit this EN
  amendment**, exactly as the 2026-05-17 status-transition (#07) and
  Analyze row-guard (#08) amendments did.

### Counter-proposal

The serious counter-position is **new ADR-019 — formalize the spec <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
filename convention as a standalone ADR rather than an ADR-014
amendment**. It is recorded here per the
ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 convention of
taking a rejected alternative seriously rather than as a strawman. The
argument:

1. The Spec hands `architect` an explicit (b) choice ("ADR-014
   amendment or a new ADR-019") and structurally parallel sibling <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
   milestones #05 and #06 both resolved their deferred-structural-
   question Specs with *new* ADRs (017, 018), not amendments. Symmetry
   of process argues #09 → ADR-019. <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
2. A named filename convention that every future milestone author and
   every fork must honor is a first-class, citable contract; burying it
   as the fifth amendment in a long ADR-014 trail makes it less
   discoverable than a dedicated ADR-019 a reader can cite as "the <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
   Spec-filename ADR." Milestone #10 (the adjacent directory pin) may
   itself become an ADR; symmetry between the filename rule and the
   directory rule argues both should be ADRs of the same shape.
3. ADR-019 would carry its own Roadmap back-link (`Roadmap row: #09`) <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
   and the row would gain an `adr:` link — the same bidirectional
   contract #05/#06 exercise — giving #09 the same artifact shape as
   its siblings.

**Why the counter was not adopted:**

- ADR-017 and ADR-018 self-classified as new-ADR-worthy on a specific,
  stated discriminator: each introduced a **new detector + a new MECE
  contract boundary + a new exemption-keying rule** (ADR-017
  Alternative B; ADR-018 Alternative B). #09 introduces **none** of
  those — the Spec's Non-goals and Out of scope *explicitly forbid* a
  new CI detector or script; the MECE statement is a scope-delineation
  placing #09 *outside* the detector-family partition and against the
  adjacent #10 directory pin, not a fourth partition within it; and
  there is no exemption keying, no allowlist-vs-pattern choice, no new
  file artifact, no new mechanism. #09 names the filename component of
  the `specs/NN-slug.md` reserved path ADR-014's *own* 2026-05-16
  Spec-reservation amendment already mandates. The sibling-symmetry
  argument inverts on inspection: applying #05/#06's own stated
  discriminator to #09 yields "amendment," because the structural half
  that dominated for #05/#06 is absent for #09. This is the identical
  reasoning ADR-014's 2026-05-16 line-budget amendment used to refuse
  its own ADR-015, ADR-018's 2026-05-17 amendment used to refine an
  already-decided rule without a new number, and the 2026-05-17
  status-transition (#07) and Analyze row-guard (#08) amendments used
  to refuse ADR-019. <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
- The ADR-016 analogy fails on inspection. ADR-016 is a separate ADR
  because it introduced a **new mechanism** — a new file artifact
  (`specs/NN-progress.md`) with its own write-ownership, lifecycle, and
  deletion-trigger contract. #09 introduces **no new artifact and no
  new mechanism**; it names the filename form of an artifact
  (`specs/NN-slug.md`) ADR-014's reservation amendment already defines,
  and *defers entirely to ADR-016* for the one adjacent artifact
  (`specs/NN-progress.md`) it explicitly excludes. A convention over an
  existing path scheme is a consequence-clarification of that scheme's
  owning Decision, not a new mechanism.
- Discoverability is *better*, not worse, as an ADR-014 amendment: the
  canonical place a reader looks for "what is the reserved `spec:`
  path's filename" is the ADR that defined the Roadmap, the
  reservation rule, and the `specs/NN-slug.md` path scheme itself. A
  separate ADR-019 would *fragment* the reservation-rule contract <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
  across two ADRs — a reader would have to read ADR-014 (the
  reservation rule) *and* ADR-019 (the filename form of the reserved <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
  path) to know the full path contract, reintroducing exactly the
  "which document is authoritative" rediscovery ADR-014 exists to
  remove. The #10 symmetry argument does not force ADR-019: whether <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
  #10's directory pin warrants its own ADR is #10's *own* discriminator
  application at its pickup, decided on #10's structural facts, not
  inherited from #09 — the two milestones are MECE precisely so each is
  classified on its own merits.
- The bidirectional-back-link argument is moot: ADR-014 has no
  milestone row of its own, so an amendment to it correctly carries
  *no* `Roadmap row:` line and triggers no #05 drift contract. Forcing
  a new ADR-019 purely to manufacture a back-link creates the <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
  bidirectional artifact rather than reflecting a genuine structural
  decision — identical to the #07 and #08 amendments' resolution of
  the same objection.

**Trigger conditions for re-evaluating this counter-proposal:**

- A future milestone genuinely adds a *mechanical CI enforcement* of
  the filename convention (a new detector that statically verifies
  every `specs/*.md` matches `NN-slug.md`, the JA sibling form, and the
  `progress` exclusion) — that would be a new detector + new boundary +
  new keying, the ADR-017/ADR-018 discriminator's structural half, and
  would warrant its own ADR with this amendment's convention as its
  inherited normative baseline. The Spec explicitly flags the CI check
  as "an optional consequence, not a deliverable of this milestone."
- The filename convention is found to require divergent forms per
  project type (e.g. forks that drop the bilingual `.ja.md` sibling, or
  adopt a different number-prefix width), such that a single convention
  in ADR-014 can no longer express it — at which point a dedicated ADR
  with per-profile filename rules may be warranted.
- The `specs/NN-slug.md` path scheme itself is restructured (e.g. the
  reservation rule is replaced, or `specs/` is renamed by #10 in a way
  that changes the filename grammar, not only the directory) — a
  genuine change to the underlying mechanism, which would reopen the
  owning Decision rather than extend it by amendment.

The counter-proposal stays in this amendment as the historical record
of the decision's most serious objection, per the
ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 convention.

The original Status line (`Accepted — 2026-05-15`) is unchanged; this
amendment appends a convention-statement of an already-sanctioned path
scheme and does not reopen the Decision.

The original Status line (`Accepted — 2026-05-15`) is unchanged; this
amendment appends a runtime-precondition clarification of an
already-sanctioned Analyze-step mechanism and does not reopen the
Decision.

## Amendment — 2026-05-17 (spec/adr directory pin)

This amendment makes normative the **directory** component of the
`specs/NN-slug.md` reserved-path scheme this ADR's 2026-05-16 **Spec
reservation rule** amendment already *uses* but never *states as a
named directory rule*, and pins the parallel `.claude/meta/adr/`
directory the ADR-authoring practice has used for every ADR to date.
`specs/10-spec-adr-directory-pinning.md` (Roadmap row #10) is the
authoritative scope; it states *what* the convention must cover
(canonical `specs/` directory for Specs, canonical `.claude/meta/adr/`
directory for ADRs, same-directory EN/JA sibling convention,
retroactive conformance) and defers the structural *how* to `architect`
(its Risk R-01 (a)–(d), R-02, R-03). This amendment records that
decision. It is a **consequence-clarification of ADR-014's existing
Decision** — specifically of the already-accepted 2026-05-16
Spec-reservation amendment, whose reserved path *is* `specs/NN-slug.md`
and whose `specs/` directory component #10 names normative — composed
with the #09 amendment, which pinned the filename component of the same
path. No new detector, CI workflow, contract boundary, keying rule, or
file artifact is introduced.

### The (b)/(c) decision — ADR-014 amendment, not new ADR-019, by the ADR-018 Alternative-B discriminator <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal; it is intentionally never created (see Counter-proposal below) -->

The Spec's R-01 (b)/(c) hands `architect` the explicit choice "ADR-014
amendment or a new ADR-019" and instructs the architect to apply <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
ADR-018's Alternative-B discriminator verbatim: *does #10 introduce a
NEW detector + a NEW MECE contract boundary + a NEW keying/mechanism
(⇒ new ADR), or is it a consequence-clarification / extension of an
existing ADR's already-sanctioned Decision (⇒ amendment)?* Applied
honestly, clause by clause:

- **New detector? No.** The Spec's Non-goals and Out of scope
  *explicitly forbid* a CI directory-conformance detector as a #10
  deliverable ("Adding a new CI directory-conformance check. Whether to
  add such a check is a structural decision deferred to the architect …
  #10 is a documentation/convention-statement milestone; CI enforcement
  is an optional consequence"; "Adding a CI directory-conformance
  check — a structural decision deferred to the architect"). Verified
  against the Spec text (Non-goals line 31, Out of scope line 110).
  ADR-017 and ADR-018 each self-classified as new-ADR-worthy *because*
  each introduced a new script + new workflow (`check-roadmap-drift.sh`
  / `check-bilingual-parity.sh`). #10 introduces **zero** scripts and
  **zero** workflows — identical to the #09 amendment (Non-goals forbid
  a CI filename detector), the #08 amendment (Non-goals forbid a CI
  workflow), and the #07 amendment (no detector). The structural half
  that dominated for ADR-017/ADR-018 is absent here.
- **New MECE contract partition? No new partition — a
  scope-delineation statement only.** A boundary *statement* is
  required (Spec Goal "Compose with #09", Acceptance criterion 8, R-01
  (d), R-02), but it does **not** add a fourth detector to the
  #04/#05/#06 detector-family contract partition. It states that #10
  sits *outside* that partition entirely: #10 is a
  documentation/convention statement about *which directory* the
  reserved `spec:` path's prefix denotes and where ADRs live, composed
  MECE with #09's filename scope and delineated against #04's
  path-resolution scope and #05's Roadmap-structural scope. This is a
  scope-delineation of where an ADR-014 reservation-rule consequence
  lives — the identical structural shape as the #09 amendment's "states
  #09 sits *outside* that partition entirely" clause — not a new keying
  rule like ADR-017's absence-of-claim or ADR-018's
  convention-presence.
- **New keying / mechanism / file artifact? No.** There is no
  exemption-keying rule, no allowlist-vs-pattern choice, no parsing
  strategy, no new file artifact, no new script. `specs/` is *already*
  the directory component of the deterministic `specs/NN-slug.md` path
  the 2026-05-16 Spec-reservation amendment mandates for every reserved
  `spec:` link; `.claude/meta/adr/` is *already* the directory every
  one of the 18 ADRs authored to date lives in (verified: ADR-001
  through ADR-018 plus `.ja.md` siblings all under
  `.claude/meta/adr/`). #10 names those already-used directories
  normative for the files; it adds no second directory scheme and no
  mechanism.
- **Consequence-clarification of an existing Decision? Yes,
  decisively — with one interaction the #09 amendment did not
  face, reasoned through explicitly below.** ADR-014's 2026-05-16
  Spec-reservation amendment already uses `specs/NN-slug.md` verbatim
  as the reserved-path scheme keyed to the immutable row number; the
  `specs/` directory is its prefix. The #10 convention is the
  statement, as a named normative rule, of the directory component of
  that already-sanctioned path, exactly as #09 stated its filename
  component. This is the identical structural shape as the #09
  amendment (filename component of the same reserved path), the #07
  amendment (formalized an interim practice ADR-014 pre-flagged), and
  the #08 amendment (strengthened what ADR-014's Analyze read must
  verify) — all resolved by ADR-014 amendment, not by ADR-019. <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->

**The one genuine difference from #09, and why it does not flip the
verdict.** #09's filename component touched no other CLAUDE.md section —
the `specs/NN-slug.md` filename had no competing prose anywhere. #10's
directory pin interacts with the CLAUDE.md `## Document Templates`
section, whose **current text explicitly disclaims imposing a layout**:
"You decide where to place the resulting documents … The template does
not impose a layout — only the templates," with an illustrative
`adr/en/` / `adr/ja/` split. Pinning `specs/` and `.claude/meta/adr/`
for *this repo* is therefore not merely silent alongside that prose; it
could be read as *changing* the `## Document Templates` stance. Both
readings were taken seriously:

- **Reading 1 (genuine structural change ⇒ ADR-019):** the <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
  `## Document Templates` "you decide" guidance is a deliberate,
  fork-facing design decision (forks choose their own layout). Pinning
  directories *reverses* it for this repo; reversing a stated design
  stance is a new structural decision, the ADR-017/ADR-018 structural
  half, warranting a standalone ADR-019. <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
- **Reading 2 (consequence-clarification ⇒ ADR-014 amendment, chosen):**
  the `## Document Templates` "you decide" guidance and #10's pin are
  **not in contradiction once correctly scoped** — they govern two
  different audiences. `## Document Templates` speaks to the *fork*
  ("the template does not impose a layout"); #10's pin speaks to *this
  repo's dogfooding posture*. The `specs/` directory is **already
  mandated for this repo** by ADR-014's own 2026-05-16 reservation
  amendment (every Roadmap row's reserved `spec:` link is
  `specs/NN-slug.md` — the directory is not a free choice here, it is
  ADR-014-determined). #10 does not *introduce* a directory constraint
  that `## Document Templates` lifts; it *names, as a convention, the
  directory ADR-014's reservation rule already fixed for this repo* and
  adds the parallel ADR-directory statement, while explicitly preserving
  `## Document Templates`'s fork-facing freedom by scoping the
  `adr/en/` / `adr/ja/` example to forks. Framed correctly, the
  `## Document Templates` prose is not *reversed* — it is *partitioned*
  by audience (fork = free; this repo = ADR-014-pinned), and #10 states
  the this-repo half that ADR-014's reservation rule already
  determined. That is a consequence-clarification of the reservation
  rule, identical in kind to #09.

**Verdict: Reading 2. ADR-014 amendment. No ADR-019 is created.** The <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
decisive fact is that the `specs/` directory is **not a free choice for
this repo in the first place** — ADR-014's 2026-05-16 reservation
amendment already nailed every reserved `spec:` link to
`specs/NN-slug.md`. #10 cannot be "reversing the `## Document
Templates` free-placement stance for Specs" because that stance was
*never operative for this repo's Specs* — it was already overridden, in
this repo, by ADR-014 itself. #10 names that ADR-014-determined
directory and adds the long-standing ADR-directory practice as its
parallel; the `## Document Templates` edit is a *scoping note* clarifying
the example is fork-facing, not a reversal of a stance that applied to
this repo. A scope-clarifying edit to existing prose, naming a
directory an existing ADR Decision already fixed, is a
consequence-clarification, exactly as the #09 amendment's clause-by-
clause application concluded for the filename component. The
sibling-symmetry trap ("#05/#06 → ADR-017/ADR-018, therefore #10 →
ADR-019") inverts identically to #09: applying #05/#06's *own stated <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
discriminator* yields **amendment**, because all three structural
clauses (new detector, new partition, new keying/mechanism) are absent.
Roadmap row #10 stays `spec:`-only (Milestone → ADR is 0:1; ADR-014 has
no milestone row of its own, so adding an `adr:` link from row #10 to
ADR-014 would assert a milestone→ADR mapping that does not exist —
identical reasoning to the #07, #08, and #09 amendments).

### The normative directory convention

The convention names the directory component of the `specs/NN-slug.md`
path the 2026-05-16 Spec-reservation amendment already mandates, plus
the ADR directory the ADR-authoring practice has always used. It adds
no new path scheme; it states the existing ones as named rules:

| Rule | Statement | Source it clarifies |
|---|---|---|
| Canonical Spec directory | Spec files live in `specs/` at the repository root. This is the directory component of the `specs/NN-slug.md` reserved path every Roadmap row already carries; `product-manager` authors the file at the directory already fixed in the row's reserved `spec:` link (copy the path from the row, do not choose a directory). | ADR-014 2026-05-16 Spec-reservation amendment (the reserved path's prefix *is* `specs/`). |
| Canonical ADR directory | ADR files live in `.claude/meta/adr/` at the repository root, with a three-digit zero-padded numeric prefix (`NNN-slug.md`). Every ADR authored to date (ADR-001 … ADR-018, plus `.ja.md` siblings) conforms; `architect` authors new ADRs there. | The ADR-authoring practice (retroactively consistent with all 18 existing ADRs); #10 names the de-facto directory normative. The three-digit-prefix *filename* form is the ADR-authoring practice, **not** #10's scope (Spec Non-goal). |
| Same-directory EN/JA siblings | The EN Spec and its JA sibling coexist in the **same** `specs/` directory as `specs/NN-slug.md` and `specs/NN-slug.ja.md`; the directory is **not** split by language (no `specs/en/` or `specs/ja/`). The `adr/en/` / `adr/ja/` split in `## Document Templates` is illustrative **for forks**, not this repo's convention. Heading-tree parity of the pair is owned by #06 / ADR-018; this convention states only the *co-location*, it does not redefine or extend the parity check. <!-- ref-allow: specs/en/ and specs/ja/ are non-existing illustrative paths documenting what this convention does NOT use; their non-existence is the point --> | ADR-018 (parity check owns content parity; this convention owns the same-directory placement its per-file-pair keying — ADR-018 2026-05-17 amendment — presupposes). |
| `## Document Templates` audience scope | The `## Document Templates` "you decide where to place … the template does not impose a layout" guidance is **fork-facing**: it tells a fork it may choose its own layout. It is **not** in tension with this repo's pin, because this repo's `specs/` directory is already ADR-014-determined (the reservation rule), not a free choice. The `adr/en/`/`adr/ja/` example is explicitly scoped to forks. | ADR-014 2026-05-16 Spec-reservation amendment (the reason this repo's Spec directory is not free) + Spec R-03. |

The convention is **retroactively consistent with every existing Spec
and ADR file** (`specs/01-*.md` … `specs/10-*.md` plus `.ja.md`
siblings all under `specs/`; ADR-001 … ADR-018 plus `.ja.md` siblings
all under `.claude/meta/adr/`), confirming this is a
convention-*statement* amendment, not a bulk-move — exactly the
"retroactively consistent with every historical artifact, not a
behavior change" property the #07 and #09 amendments established.

### (a) Documentation placement — the CLAUDE.md `## Document Templates` section, scoped, plus a one-line MECE pointer in the `## Roadmap` Rules block

#10 differs from #09 in *audience*: #09 concerned only Spec authoring
(`product-manager`, who already reads the `## Roadmap` Rules block, so
one Rules bullet sufficed). #10 concerns **both** Spec authoring
(`product-manager`) **and** ADR authoring (`architect`). The placement
decision must put each directory convention where its author already
reads, with **zero additional file reads**, and must avoid creating a
second authoritative source for the same rule (the "which document is
authoritative" rediscovery ADR-014 exists to remove). The decision,
against the Spec's R-01 (a) "encountered at the authoring step without
an additional file read" criterion:

- **Primary single source: the CLAUDE.md `## Document Templates`
  section, edited to be audience-scoped.** This is the natural single
  source because `## Document Templates` is *already the section about
  where documents are placed* — it already names the ADR and Spec
  templates and already discusses placement ("you decide where to
  place"). Both `product-manager` (Spec) and `architect` (ADR)
  resolve their template from this section as part of authoring;
  ADR-014's original downstream tasks already route `architect` to the
  adr-template and `product-manager` to the spec-template referenced
  *here*. Stating both pinned directories in the section that already
  governs placement means each author encounters its directory
  convention at the authoring step with **zero additional file reads** —
  the R-01 (a) criterion is met by construction, for *both* audiences,
  from *one* source. Putting the directory rule anywhere else (a new
  `## Spec/ADR directory convention` heading, or only the Rules block)
  would either bloat the budget with a new section or split the rule
  across two places (Rules block governs Spec authoring;
  `## Document Templates` governs template/placement) — reintroducing
  the two-source rediscovery.
- **Why not the `## Roadmap` Rules block as the primary (the #09
  choice)?** #09's Rules-block placement was correct *because the
  filename is a property of the reserved `spec:` path the Rules block
  already states* — `product-manager` reads that block to author a
  Spec, and the filename is the completion of the reservation-rule
  bullet already there. But the Rules block is **not** read by
  `architect` to author an ADR (ADR authoring is the #04 Architecture
  workflow step, not a Roadmap-row write — `architect`'s Roadmap
  interaction is the *`adr:` link add*, governed by ADR-014
  write-ownership, not directory choice). Making the Rules block the
  ADR-directory source would force `architect` to read a section it
  does not otherwise read at ADR-authoring time — an extra file/section
  read, failing R-01 (a) for the ADR audience. The `## Document
  Templates` section is the one location *both* authors already
  traverse, so it is the correct single source; this is the placement-
  follows-the-contract-owner reasoning the #08 and #09 amendments used,
  applied to a *two-audience* contract.
- **Secondary, non-authoritative cross-reference: one line in the
  `## Roadmap` Rules block.** The Rules block already carries the #09
  filename bullet ("#10 pins the directory; #09 pins the filename —
  MECE"). To keep the existing #09 bullet's forward reference honest
  (it already names #10), the #09 bullet is extended by **one short
  clause** pointing to `## Document Templates` as the directory source —
  *not* restating the directory rule (that would be the second source).
  This is a pointer, not a duplicate: it tells a Rules-block reader
  "the directory convention is in `## Document Templates`," preserving
  the single-source property while keeping the MECE statement
  discoverable from the Roadmap side, exactly as the #09 amendment
  restated its MECE boundary "in that bullet."
- **It respects the CLAUDE.md line-budget guidance.** `## Document
  Templates` is **not** the sanctioned-exception `## Roadmap` section,
  so the edit must be minimal. The decision is a *scoping rewrite of
  the existing placement paragraph* (no net new section, roughly
  net-neutral line count — the existing four-line "you decide" paragraph
  is rewritten to state the fork/this-repo partition and the two pinned
  directories in comparable length) plus a one-clause extension of the
  already-present #09 Rules bullet. No new `##` heading; the budget is
  not materially moved (judgement (c) below addresses the Skill
  implication of editing existing prose).

### (c) Edit scope + claude-md-authoring Skill judgement

- **CLAUDE.md requires editing — two locations, both minimal.** (1) The
  `## Document Templates` section's placement paragraph is **rewritten
  in place** to: state `specs/` as the canonical Spec directory and
  `.claude/meta/adr/` as the canonical ADR directory *for this repo's
  dogfooding posture*; scope the existing "you decide where to place …
  the template does not impose a layout" guidance and the `adr/en/` /
  `adr/ja/` example explicitly to *forks*; state the same-directory
  EN/JA sibling convention for this repo. (2) The existing #09 Rules
  bullet in `## Roadmap` gains **one clause** pointing to
  `## Document Templates` as the directory source (no directory rule
  restated). No other CLAUDE.md section changes.
- **`architect.md` does NOT require editing.** `architect` already
  resolves the adr-template from `## Document Templates` (ADR-014's
  original downstream task routes `architect` there) and the #04
  Architecture workflow step. The convention names the directory of the
  template `architect` already opens from the section it already reads;
  it is not a new prompt obligation. This is the identical reasoning
  the #09 amendment used for `product-manager.md` ("the convention
  names the … path `product-manager` already owns … not a new prompt
  obligation") and the #07/#08 amendments used to conclude "no agent
  prompt requires editing."
- **`product-manager.md` does NOT require editing.** `product-manager`
  already authors the Spec at the reserved `specs/NN-slug.md` path
  (ADR-014 reservation rule + #09 filename amendment + #07 `☐→◐`
  trigger). The directory is the prefix of that already-reserved path;
  stating it normative in `## Document Templates` and pointing to it
  from the Rules block `product-manager` already reads adds no prompt
  obligation — identical to the #09 conclusion for the same agent.
- **The spec/adr templates do NOT require editing.** The directory is a
  property of *where the file is created* (the reserved `spec:` path's
  prefix for Specs; the ADR-authoring practice for ADRs), governed by
  `## Document Templates` and the reservation rule. The templates'
  *content* (their `## References` `Roadmap row: #NN` back-link) is
  unaffected. Adding a directory note to a template would create a
  second source for the same rule — the exact "which document is
  authoritative" rediscovery ADR-014 exists to remove, and the
  identical reasoning the #09 amendment used to refuse a spec-template
  edit. Single source: `## Document Templates`, with the Rules-block
  pointer.
- **claude-md-authoring Skill: REQUIRED for the #10 CLAUDE.md edit —
  this is the genuine divergence from #09's judgement (c).** #09's
  deferred edit was *one bullet appended* to an existing list — squarely
  the "Routine small edits (… single bullet …)" carve-out, so the Skill
  was *not* required. #10's deferred edit **rewrites existing prose in
  the `## Document Templates` section** — it changes the *meaning* of a
  standing placement statement (from unqualified "you decide" to an
  audience-partitioned "forks decide; this repo is pinned"). Rewriting
  the semantics of an existing section's prose is **not** a "typo,
  single bullet, version bump" routine edit; it is the
  "significant restructuring" class CLAUDE.md's `## CLAUDE.md authoring
  guidance` and ADR-007 route through the Skill's Pre/Post checklist
  and invariant rules (the `## Document Templates` rewrite must be
  checked against the four invariants — particularly that the section
  stays compaction-durable and that no invariant about template
  layout-neutrality is silently violated). **Judgement: the
  claude-md-authoring Skill IS required for the #10 `## Document
  Templates` rewrite.** The one-clause extension of the existing #09
  Rules bullet, taken alone, is a routine single-line edit; but because
  the same implementation change also rewrites `## Document Templates`
  prose, the Skill governs the change as a whole. This is the
  deliberate inverse of the #09 amendment's (c): #09 was *designed* as a
  single bullet precisely to stay under the carve-out; #10's
  `## Document Templates` interaction *cannot* be reduced to a single
  bullet without leaving the standing "you decide" prose un-scoped (the
  exact R-03 tension the Spec forbids resolving silently), so the Skill
  applies.

### (d) MECE boundary statement — #10 (directory) vs #09 (filename) vs #04 vs #05 vs #11 vs `## Document Templates` free-placement vs ADR-014 reservation rule (R-01 (d), R-02)

The boundary is drawn on **what each owns**, restated here and in the
Rules-block pointer so a future milestone author cannot mis-route a
directory concern to a filename pin, a path-resolution detector, a
Roadmap-structural detector, a verification-domain guidance milestone,
the fork-facing placement guidance, or the reservation rule:

| Owner | Owns the question | Trigger point |
|---|---|---|
| #04 `check-dangling-refs.sh` | Does a path/reference in document prose **resolve** to a real file/ADR? | commit time (CI) |
| #05 `check-roadmap-drift.sh` | Does the **bidirectional Roadmap-index contract** hold and is every Status glyph **well-formed**? | commit time (CI) |
| #09 (spec filename amendment) | **What is the filename form** of a Spec file (`NN-slug.md`, two-digit-min, `.ja.md` sibling form, `progress` exclusion)? | documentation/convention (no CI; explicitly deferred optional consequence) |
| #10 (this amendment) | **Which directory** do Spec and ADR files live in for *this repo* (`specs/`, `.claude/meta/adr/`), and that EN/JA siblings are co-located? | documentation/convention (no CI in #10's own scope) |
| #11 (verification-domain opt-in guidance) | Opt-in **trigger guidance** for implementation/design verification domains. | documentation/convention (reserved-but-absent Roadmap row) <!-- ref-allow: #11 is a reserved-but-absent Roadmap row per the ADR-014 reservation rule; the MECE boundary must name it before its Spec is authored at pickup --> |
| `## Document Templates` free-placement guidance | That a **fork** may choose its own document layout (the template imposes none). | documentation (fork-facing; orthogonal audience to #10's this-repo pin) |
| ADR-014 reservation rule | *That* every row carries a reserved `spec:` link `specs/NN-slug.md` at row-creation, keyed to the immutable row number. | row-creation (process) |

A concern maps to exactly one owner: a *broken prose path* is #04's
(commit-time resolution); a *malformed glyph or broken bidirectional
ADR-link* is #05's (commit-time consistency); *what a Spec file is
named* is #09's; *which directory a Spec or ADR lives in for this repo*
is #10's; *verification-domain opt-in trigger guidance* is #11's; *that
a fork may pick its own layout* is the `## Document Templates`
fork-facing guidance's; *that a reserved `spec:` link exists at all* is
the ADR-014 reservation rule's. The full canonical Spec path
`specs/NN-slug.md` is the **composition** of #10's directory scope and
#09's filename scope: neither subsumes the other; a future author
uncertain about directory reads #10 (now stated in `## Document
Templates`), one uncertain about filename reads #09 (the `## Roadmap`
Rules bullet). The `## Document Templates` seam is explicit and is the
sharpest seam in this table: #10 and the fork-facing guidance are **not
in conflict** because they address **different audiences** — the
guidance tells a *fork* it is free; #10 states *this repo's* pinned
directories, which ADR-014's reservation rule already determined for
Specs regardless. They are MECE by audience, not by contradiction; the
`## Document Templates` rewrite makes that audience partition explicit
in the prose so it cannot be read as a contradiction, exactly as R-03
requires.

### Composability with ADR-014's reservation rule, #09, and #06/ADR-018 (no gap)

- **ADR-014 2026-05-16 Spec-reservation amendment.** #10 names the
  directory component (`specs/`) of the `specs/NN-slug.md` reserved
  path that amendment already mandates; #09 named its filename
  component. The three compose with no gap: the reservation amendment
  says *a reserved `spec:` link of form `specs/NN-slug.md` is present
  from row-creation*; #10 says *the directory prefix is `specs/`,
  pinned for this repo*; #09 says *the file authored at pickup uses the
  `NN-slug.md` name*. No second path scheme is introduced.
- **#09 (spec filename amendment).** #10 and #09 are MECE by
  construction (directory vs filename) and their CLAUDE.md homes are
  deliberately different and non-duplicating: #09 lives in the
  `## Roadmap` Rules bullet (its audience, `product-manager`, reads it
  there); #10's authoritative statement lives in `## Document
  Templates` (its two audiences, `product-manager` and `architect`,
  both traverse it at authoring). The Rules bullet's one-clause pointer
  links the two without restating either rule — single source per rule,
  cross-referenced, not duplicated.
- **#06 / ADR-018 (bilingual parity).** #10 states the EN/JA siblings'
  *co-location* in the same `specs/` directory; ADR-018's 2026-05-17
  per-file-pair amendment *presupposes* exactly that co-location (it
  derives `<stem>.md` from a `<stem>.ja.md` in the **same** directory —
  split language directories would break its keying). #10 confirms the
  same-directory convention ADR-018's keying already depends on; ADR-018
  owns the heading-tree/full-width-paren *content* parity of the pair.
  No overlap — a misplaced-directory defect is #10's convention, a
  heading-order defect is #06's check. #10 introduces no parity rule
  and does not touch `check-bilingual-parity.sh`.

### Downstream implementer tasks (recorded for traceability, not performed by this amendment — implementation is a future session, per the #03/ADR-016 · #05/ADR-017 · #06/ADR-018 · #07/ADR-014-amendment · #08/ADR-014-amendment · #09/ADR-014-amendment two-session decision-then-implementation split)

- `.claude/CLAUDE.md` `## Document Templates` section — **rewrite the
  existing placement paragraph in place** (the "You decide where to
  place the resulting documents … The template does not impose a
  layout — only the templates." paragraph) so it: (1) states `specs/`
  is the canonical Spec directory and `.claude/meta/adr/` the canonical
  ADR directory **for this repository's dogfooding posture**; (2)
  scopes the existing "you decide where to place" guidance and the
  `adr/en/` / `adr/ja/` example **explicitly to forks** ("a derived
  project may choose its own layout; the template imposes none — this
  repository pins `specs/` and `.claude/meta/adr/` as its own
  convention"); (3) states the EN/JA sibling co-location for this repo
  (`specs/NN-slug.md` + `specs/NN-slug.ja.md` in the **same** `specs/`
  directory, not `specs/en/` / `specs/ja/`), noting heading-tree parity
  is owned by #06. Keep it roughly net-neutral in line count (rewrite,
  not append). **This edit is governed by the claude-md-authoring
  Skill** (judgement (c) above — it rewrites the semantics of existing
  prose; run the Skill's Pre/Post checklist and verify the four
  invariants, particularly compaction-durability of `## Document
  Templates` and that no template-layout-neutrality invariant is
  silently violated by the audience-scoping).
- `.claude/CLAUDE.md` `## Roadmap` **Rules** block — extend the
  **existing** #09 filename bullet (the one ending "#10 pins the
  directory; #09 pins the filename — MECE.") with **one short clause**
  pointing to `## Document Templates` as the authoritative directory
  source — e.g. append: "see `## Document Templates` for the pinned
  `specs/` and `.claude/meta/adr/` directories." Do **not** restate the
  directory rule in the Rules block (that would create the forbidden
  second source); the clause is a pointer only. This one-clause
  extension, taken alone, is a routine single-line edit, but it ships
  in the same change as the `## Document Templates` rewrite, which the
  Skill governs.
- **No agent-prompt edits** (judgement (c) above). The implementer must
  **not** add directory-convention prose to `product-manager.md`,
  `architect.md`, `orchestrator.md`, or `implementer.md`;
  `## Document Templates` is the single source. `product-manager`'s
  authoring-at-the-reserved-path behavior is already covered by its
  ADR-014 row+`spec:` write-ownership, the #09 filename amendment, and
  the #07 `☐→◐` pickup trigger; `architect`'s ADR-authoring already
  resolves the adr-template from `## Document Templates`.
- **No spec/adr-template edits** (judgement (c) above). The templates'
  `## References` `Roadmap row: #NN` example is unaffected; the
  directory is a property of the reserved path / ADR-authoring practice
  the `## Document Templates` section states, not of template content.
  Adding a template note would create a second source for the same
  rule.
- **No CI workflow and no script** (Spec Non-goals / Out of scope:
  "#10 is a documentation/convention-statement milestone; CI
  enforcement is an optional consequence"; "Adding a CI
  directory-conformance check — a structural decision deferred to the
  architect"). A future mechanical directory-conformance check is a
  possible later milestone, **not** #10, re-evaluated under the
  Counter-proposal trigger conditions below — distinct from #04/#05's
  commit-time checks per the (d) MECE table.
- **No moves or renames.** Every existing Spec file
  (`specs/01-*.md` … `specs/10-*.md` plus `.ja.md` siblings) and every
  existing ADR file (`.claude/meta/adr/001-*.md` …
  `.claude/meta/adr/018-*.md` plus `.ja.md` siblings) already lives in
  the pinned directory; #10 is a convention-statement, not a bulk-move
  (Spec Non-goals).
- **No Roadmap row change.** Row #10's `Design source` cell stays
  `spec:`-only — this is an ADR-014 amendment, ADR-014 has no milestone
  row of its own, so no `adr:` link is added to row #10 (Milestone →
  ADR is 0:1; identical to the #07, #08, and #09 amendments' row
  reasoning). `product-manager` flips the row glyph `◐→☑` after the
  step-6 quality gate per the #07 transition matrix; `architect` adds
  no `adr:` link here.
- The Japanese counterpart of this ADR
  (`014-roadmap-index-single-entry-point.ja.md`) must receive the
  mirrored amendment, and the Japanese counterpart of CLAUDE.md (if
  present) the mirrored `## Document Templates` rewrite and Rules-block
  pointer-clause — a `technical-writer` task, **not** part of this
  change. **This amendment creates a transient EN/JA heading mismatch
  on ADR-014 (EN gains one `##`-level heading plus its `###`
  sub-headings; JA was in heading parity before this change) until
  `technical-writer` mirrors it; the #06 bilingual-parity detector
  (`check-bilingual-parity.sh`, shipped) will FAIL on the ADR-014
  EN/JA pair until the mirror lands. This is the expected, queued
  `technical-writer` task — not a reason to omit this EN amendment**,
  exactly as the 2026-05-17 status-transition (#07), Analyze row-guard
  (#08), and spec-filename (#09) amendments did.

### Counter-proposal

The serious counter-position is **new ADR-019 — formalize the spec/adr <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
directory pin as a standalone ADR rather than an ADR-014 amendment,
because #10 *changes the `## Document Templates` stance* rather than
merely clarifying a consequence of the reservation rule**. It is
recorded here per the
ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 convention of
taking a rejected alternative seriously rather than as a strawman. The
argument:

1. The Spec hands `architect` an explicit (b)/(c) choice ("ADR-014
   amendment or a new ADR-019") and structurally parallel sibling <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
   milestones #05 and #06 both resolved their deferred-structural-
   question Specs with *new* ADRs (017, 018). Symmetry of process
   argues #10 → ADR-019. <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
2. **#10's strongest claim to ADR-019 that #09 did not have:** #10's <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
   pin **edits the semantics of an existing CLAUDE.md section**
   (`## Document Templates`), turning an unqualified "the template does
   not impose a layout" into an audience-partitioned rule. #09 only
   *appended* a bullet; #10 *rewrites a standing design statement*.
   Changing the meaning of an existing, deliberate design stance is
   the ADR-017/ADR-018 "new structural decision" half, not a
   consequence-clarification — and it is precisely the kind of change
   that warrants a first-class, citable ADR a reviewer can point to as
   "the directory-pin ADR," rather than the sixth amendment buried in a
   long ADR-014 trail.
3. ADR-019 would carry its own Roadmap back-link (`Roadmap row: #10`) <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
   and row #10 would gain an `adr:` link — the same bidirectional
   contract #05/#06 exercise — giving #10 the same artifact shape as
   its siblings, and matching #10's directory rule with a dedicated ADR
   the way #10 is the directory complement of #09's filename rule.

**Why the counter was not adopted:**

- The argument 2 premise — "#10 *changes* the `## Document Templates`
  stance" — is false on inspection, and this is the decisive point.
  The `## Document Templates` "you decide where to place" guidance
  **was never operative for this repo's Spec files**: ADR-014's own
  2026-05-16 Spec-reservation amendment already nailed every reserved
  `spec:` link to `specs/NN-slug.md`, fixing the `specs/` directory for
  this repo *before #10 exists*. #10 does not reverse a stance that
  applied to this repo's Specs — that stance was already overridden, in
  this repo, by ADR-014 itself. The `## Document Templates` rewrite is
  a **scoping clarification** (the guidance is fork-facing; this repo
  is ADR-014-pinned) that makes an *already-true* audience partition
  explicit in the prose. Naming a directory an existing ADR Decision
  already fixed, and scoping standing prose to the audience it always
  implicitly addressed, is a consequence-clarification — the identical
  structural shape as #09's filename-component clarification of the
  same reserved path, and as the #07/#08 amendments' formalization of
  ADR-014-pre-flagged practice.
- ADR-017 and ADR-018 self-classified as new-ADR-worthy on a specific,
  stated discriminator: each introduced a **new detector + a new MECE
  contract boundary + a new exemption-keying rule**. #10 introduces
  **none** — the Spec's Non-goals and Out of scope *explicitly forbid*
  a new CI detector or script; the MECE statement is a
  scope-delineation placing #10 *outside* the detector-family partition
  and against #09/#04/#05/#11, not a fourth partition within it; and
  there is no exemption keying, no allowlist-vs-pattern choice, no new
  file artifact, no new mechanism. The sibling-symmetry argument
  inverts on inspection exactly as it did for #07, #08, and #09:
  applying #05/#06's own stated discriminator to #10 yields
  "amendment," because the structural half that dominated for #05/#06
  is absent for #10.
- Discoverability is *better*, not worse, as an ADR-014 amendment: the
  canonical place a reader looks for "what directory is the reserved
  `spec:` path's prefix" is the ADR that defined the Roadmap, the
  reservation rule, and the `specs/NN-slug.md` path scheme itself — the
  same ADR #09's filename clarification lives in. A separate ADR-019 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
  would *fragment* the reserved-path contract across three ADRs (ADR-014
  reservation rule + ADR-019 directory + the #09 amendment filename), <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
  reintroducing exactly the "which document is authoritative"
  rediscovery ADR-014 exists to remove. Keeping the directory
  clarification beside the filename clarification and the reservation
  rule, all in ADR-014, is the single-source discipline ADR-014
  embodies.
- The bidirectional-back-link argument is moot: ADR-014 has no
  milestone row of its own, so an amendment to it correctly carries
  *no* `Roadmap row:` line and triggers no #05 drift contract. Forcing
  a new ADR-019 purely to manufacture a back-link creates the <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
  bidirectional artifact rather than reflecting a genuine structural
  decision — identical to the #07, #08, and #09 amendments' resolution
  of the same objection.
- The claude-md-authoring Skill requirement (judgement (c)) is **not**
  evidence of a structural decision warranting a new ADR. The Skill
  governs *how the CLAUDE.md prose edit is performed* (Pre/Post
  checklist, invariant verification); it does not reclassify *whether
  the decision is structural*. ADR-007 routes any significant CLAUDE.md
  prose change through the Skill regardless of whether the underlying
  decision is a new ADR or an amendment — the Skill requirement and the
  ADR-vs-amendment classification are orthogonal axes. A
  consequence-clarification whose implementation happens to rewrite
  prose still needs the Skill for the *edit* and is still an amendment
  for the *decision*.

**Trigger conditions for re-evaluating this counter-proposal:**

- A future milestone genuinely adds a *mechanical CI enforcement* of
  the directory convention (a new detector that statically verifies
  every Spec is under `specs/` and every ADR under `.claude/meta/adr/`,
  with same-directory EN/JA siblings) — that would be a new detector +
  new boundary + new keying, the ADR-017/ADR-018 discriminator's
  structural half, warranting its own ADR with this amendment's
  convention as its inherited normative baseline. The Spec explicitly
  flags the CI check as "an optional consequence, not a deliverable of
  this milestone."
- This repo's `specs/` or `.claude/meta/adr/` directory is itself
  restructured (e.g. the reservation rule is replaced, or `specs/` is
  renamed, or ADRs move out of `.claude/meta/`) — a genuine change to
  the underlying path mechanism, which would reopen the owning Decision
  rather than extend it by amendment.
- The `## Document Templates` fork-facing guidance is found to require
  *divergent directory rules per fork profile* such that a single
  audience-scoped statement in CLAUDE.md plus an ADR-014 amendment can
  no longer express it — at which point a dedicated ADR with
  per-profile directory rules may be warranted.
- The directory convention is found to genuinely *contradict* (not
  merely coexist by audience with) the `## Document Templates`
  free-placement guidance — e.g. if a future decision makes the
  template *itself* (not just this repo) impose `specs/`, removing the
  fork's freedom — which would be a real reversal of a design stance,
  not a scoping clarification, and would warrant its own ADR.

The counter-proposal stays in this amendment as the historical record
of the decision's most serious objection, per the
ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 convention.

The original Status line (`Accepted — 2026-05-15`) is unchanged; this
amendment appends a directory convention-statement of an
already-sanctioned path scheme (the `specs/` prefix of the reservation
rule's reserved path, plus the de-facto ADR directory) and does not
reopen the Decision.

## Amendment — 2026-05-17 (verification-domain opt-in trigger guidance)

This amendment records the structural decision deferred to `architect`
by `specs/11-verification-domain-opt-in-guidance.md` Risk R-01: *where*
the fork-facing project-adoption trigger guidance for the default-off
`implementation` and `design` verification-layer domains lands, and
*whether* that placement warrants a new ADR-019 or is a <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
consequence-clarification handled by amendment. `specs/11-…` (Roadmap
row #11) is the authoritative scope; it states *what* the guidance must
cover (≥3 concrete project-characteristic triggers per domain,
explicitly distinct from the per-change runtime triggers in the
`protocol.md` files, no CI enforcement, no change to `.claude/verification.yml`
active defaults) and its eight acceptance criteria; it defers the
structural *how* (placement file/section, ADR strategy, split-vs-single)
to `architect` (R-01 (a)–(d)). This amendment records that decision. It
is a **consequence-clarification of ADR-014's already-sanctioned MECE
partition** — specifically of the 2026-05-17 spec/adr-directory-pin
amendment's §(d) MECE boundary table, **which already names #11's
boundary and classifies it "documentation/convention" before #11's Spec
existed**. It is *not* a clarification of ADR-010's Decision: ADR-010's
default-off posture is preserved verbatim and unchanged (Spec lines 22,
28, 76, 117; AC-5 line 60). No new detector, CI workflow, contract
boundary, keying rule, MECE partition, or file artifact is introduced.

### The (b)/(c) decision — ADR-014 amendment, not new ADR-019, by the ADR-018 Alternative-B discriminator <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal; it is intentionally never created (see Counter-proposal below) -->

The Spec's R-01 (b) hands `architect` the explicit choice "new ADR-019 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
or an ADR-010 amendment (applying the ADR-018 Alternative-B
discriminator)." Applied honestly, clause by clause, with file:line <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
evidence — and the host candidate corrected from the Spec's tentative
"ADR-010" to **ADR-014**, for the reason given in the final clause:

- **New detector? No.** The Spec's Non-goals line 26 ("Adding a CI
  detector or check that enforces or audits which domains a fork has
  enabled. A new detector would create a new MECE partition violating
  ADR-014:1800's 'documentation/convention' classification for #11.
  This is out of scope and must not be proposed as a consequence of
  this milestone") and Out of scope line 113 ("Adding a CI detector,
  audit check, or linting rule that inspects a fork's verification
  domain configuration") *explicitly forbid* a detector as a #11
  deliverable. ADR-015 and ADR-017 each self-classified as
  new-ADR-worthy *because* each introduced a new script + new workflow
  (`check-dangling-refs.sh` / `check-roadmap-drift.sh`); ADR-018 the
  same (`check-bilingual-parity.sh`). #11 introduces **zero** scripts
  and **zero** workflows — identical to the #07 (no detector), #08
  (Non-goals forbid a CI workflow), #09 (Non-goals forbid a CI filename
  detector), and #10 (Non-goals forbid a CI directory detector)
  amendments. The structural half that dominated for
  ADR-015/ADR-017/ADR-018 is absent here. #11 is pure prose guidance.
- **New MECE partition / boundary? No — the boundary already exists and
  already names #11.** The decisive check: ADR-014's 2026-05-17
  spec/adr-directory-pin amendment §(d) MECE table at this file's
  line 1800 *already* contains the row `| #11 (verification-domain
  opt-in guidance) | Opt-in trigger guidance for implementation/design
  verification domains. | documentation/convention (reserved-but-absent
  Roadmap row) |`, and line 1808 *already* states "*verification-domain
  opt-in trigger guidance* is #11's" as a distinct owner inside the
  existing documentation/convention partition. #11 adds **no row and no
  partition** — it *fills in* a boundary slot ADR-014 reserved for it
  before its Spec was authored, exactly as the (d) table's own
  `ref-allow` comment anticipated ("#11 is a reserved-but-absent
  Roadmap row … the MECE boundary must name it before its Spec is
  authored at pickup"). This is the inverse of ADR-015's
  absence-of-claim keying and ADR-018's convention-presence keying:
  there is no new keying because there is no new partition — only the
  population of a pre-declared, pre-classified slot.
- **New keying / mechanism / file artifact? No.** There is no
  exemption-keying rule, no allowlist-vs-pattern choice, no parsing
  strategy, no new file, no new script, no agent-prompt change. The
  deliverable is documentation prose appended to two existing files
  (see Downstream implementer tasks). Spec Key-interaction 6 (line 80)
  scopes the architect's decision to placement only; line 26 forbids
  any mechanism.
- **Reopen ADR-010's Decision? No — it explains the posture, it does
  not change it.** Spec line 22 ("Leave `.claude/verification.yml`
  active defaults unchanged … Default-off is ADR-010's accepted
  posture; the guidance explains the posture, it does not change it"),
  line 28, line 76 ("ADR-010 … #11 does not change that posture. It
  adds the documentation that makes the opt-in decision informed
  without modifying ADR-010's Decision or Consequences"), line 117
  ("Changing ADR-010's Decision or Consequences … the default-off
  posture is correct"), and AC-5 (line 60: `.claude/verification.yml`
  `implementation.enabled`/`design.enabled` remain `false` after #11
  ships) make this unambiguous. #11 is downstream documentation *of* an
  unchanged ADR-010 Decision, not a modification *of* it.
- **Consequence-clarification of an existing Decision? Yes — and the
  correct host is ADR-014, not ADR-010.** The Spec's R-01 tentatively
  names "an ADR-010 amendment" as the amendment candidate. Applying the
  discriminator rigorously corrects this: ADR-010's Decision is
  *untouched* (clause above), so #11 cannot be a consequence-clarification
  *of ADR-010's Decision* — there is no ADR-010 consequence being
  clarified; the posture is merely *cited*. What #11 *is* a
  consequence-clarification of is **ADR-014's MECE partition**: the
  §(d) boundary table already classified #11 "documentation/convention"
  and reserved it a slot, and #11 is structurally identical to
  #07/#08/#09/#10 — all documentation/convention milestones whose
  structural decision was recorded as an ADR-014 amendment because each
  only *filled in or clarified a consequence of* a boundary ADR-014
  already owned, never reopening a Decision. Hosting #11 in ADR-014
  keeps the §(d) MECE table and its owning ADR co-located (the table
  that names #11 and the amendment that populates #11's slot live in
  the same file); hosting it in ADR-010 would split the MECE
  bookkeeping across two ADRs for no benefit and would falsely imply an
  ADR-010 Decision consequence is being clarified when none is. ADR-014
  is the correct host on the same locality-of-bookkeeping grounds
  ADR-018 used to keep its three-way contract partition in one ADR.

**Conclusion.** Triad **not** met (no new detector, no new MECE
partition, no new keying); ADR-010's Decision **not** reopened. #11 is a
consequence-clarification that *populates a slot ADR-014's own §(d) MECE
table pre-reserved for it*. Recorded as an **ADR-014 amendment**, not a
new ADR-019, and not an ADR-010 amendment — the same call ADR-018's <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
Alternative B reasoned through and the #07/#08/#09/#10 amendments
applied.

### The placement decision (R-01 (a), (c))

**Single location: a new `## Project adoption triggers` section in
`.claude/skills/verification-layer/SKILL.md`, immediately after the
existing `## Configuration` section and before `## When to invoke`.**
Not split; not in `verification.yml.example`; not in the `protocol.md`
files. Rationale, against the three candidates the Spec surfaced
(Key-interaction 2, 3, 6):

- **Why SKILL.md, not `verification.yml.example`.** AC-6 (Spec line 62)
  requires a fork maintainer to encounter the guidance "without reading
  a file that is not already part of the adoption step." The adoption
  step is CLAUDE.md `## Development Workflow` step 3, which already
  routes the maintainer to *the verification-layer Skill*
  (`.claude/skills/verification-layer/SKILL.md`) and to
  `.claude/verification.yml` — **not** to `verification.yml.example`.
  `verification.yml.example` is, by its own line 2–8 header,
  "DOCUMENTATION REFERENCE ONLY … never read by the verification
  layer"; it is a *field reference*, not an adoption-step file. Placing
  decision guidance only there would require the maintainer to discover
  a non-adoption-step file (AC-6 fail) and would also tend to drift
  from the active `.claude/verification.yml` (two annotated copies). The
  active `.claude/verification.yml` is constraint-locked by AC-5 and the
  task ("Do NOT touch `.claude/verification.yml`"), so the guidance
  cannot live in the active config either. SKILL.md is the one file the
  adoption step already mandates that is *also* writable here.
- **Why a new section adjacent to `## Configuration`, not folded into
  it.** SKILL.md `## Configuration` (lines 126–146) answers "what does
  each knob default to and why is the default asymmetric." #11 answers
  the *adjacent but distinct* question "for what kind of project is
  paying the doubled cost worth flipping the knob." Placing
  `## Project adoption triggers` *between* `## Configuration` (the knob)
  and `## When to invoke` (the per-change runtime trigger) puts the
  three questions in their natural reading order — *what is the
  default → should my project change it → once changed, when does the
  Critic fire* — so the maintainer reads adoption guidance at exactly
  the point of the config decision, with zero extra file lookups
  (AC-6 satisfied by adjacency, not by a cross-reference).
- **Why not the `protocol.md` files.** `implementation/protocol.md` and
  `design/protocol.md` `## When to invoke` answer the *per-change*
  question ("for this specific change, does the Critic spawn?") after a
  project has already opted in. AC-3/AC-4 (Spec lines 56, 58) require
  the project-adoption guidance to be *unambiguously distinct* from and
  *non-duplicating* of those sections. Co-locating #11's guidance in
  the same files as the per-change triggers is the exact R-02 scope-creep
  risk; keeping it in SKILL.md (one level up, where the domain navigator
  and shared invariants live) structurally separates the two questions
  by file, not just by wording. The new section directs the reader
  *onward* to the `protocol.md` `## When to invoke` sections for the
  subsequent per-change question (Spec Key-interaction 1) without
  restating their content.

This placement is **self-contained in one location** (R-01 (c): not
split). The only cross-references it adds are *outbound pointers* ("for
the per-change trigger once enabled, see
`implementation/protocol.md` / `design/protocol.md` `## When to
invoke`"), satisfying Spec Key-interaction 1 without duplication
(AC-4).

### Downstream implementer tasks (performed in this same session — for #11 the two-session decision-then-implementation split used by #03/ADR-016 · #05/ADR-017 · #06/ADR-018 · #07/ADR-014-amendment · #08/ADR-014-amendment · #09/ADR-014-amendment · #10/ADR-014-amendment was deliberately collapsed: #11's implementation is a single prose-only SKILL.md section, fully enumerated below and verifiable against the Spec's eight ACs, requiring no separate review cycle; the task list is retained verbatim for traceability and as the precedent shape for milestones whose implementation *is* deferred)

The implementer step (Spec step 5) is mechanical and verifiable
against the Spec's eight ACs:

- `.claude/skills/verification-layer/SKILL.md` — **add one new
  `## Project adoption triggers` section, positioned immediately after
  the existing `## Configuration` section (ends line 146) and
  immediately before `## When to invoke` (line 148).** The section must
  contain, as prose (no detector/CI/enforcement language anywhere in
  it — AC-7, AC-8):
  1. A one-sentence framing distinguishing the *project-adoption*
     question ("should this project enable the domain at all?") from
     the *per-change* question owned by the `protocol.md` `## When to
     invoke` sections ("for this change, does the Critic spawn?") —
     satisfies AC-3.
  2. An `### implementation` subsection naming **at least three**
     concrete project-characteristic triggers for `implementation.enabled:
     true` (Spec AC-1 / Goal line 18 examples to draw from, not copy
     verbatim: non-trivial custom algorithms; small team with limited
     reviewer diversity; partial test-oracle ownership by the
     Generator). Framed as "signals that increase the value of opting
     in," additive not gating (Spec R-03 mitigation, line 108) — none
     of them a per-change "do I spawn now?" trigger (AC-1).
  3. A `### design` subsection naming **at least three** concrete
     project-characteristic triggers for `design.enabled: true` (Spec
     AC-2 / Goal line 19 examples: high ADR cadence; long architectural
     reversibility horizon; downstream consumers in multiple
     independent teams). Same additive framing; none a per-change
     trigger (AC-2). The two trigger sets must be visibly distinct and
     not conflated (Spec User-story row 2).
  4. A closing one-line *outbound pointer*: once a domain is enabled,
     the per-change runtime trigger lives in that domain's
     `protocol.md` `## When to invoke` — **link, do not restate**
     (satisfies AC-4 / Spec Key-interaction 1; restating would fail
     AC-4).
  5. No reference to `.claude/verification.yml` active values changing;
     the section is documentation only (consistent with AC-5, which a
     reviewer verifies against the untouched active config).
- **No `.claude/verification.yml` edit** (task constraint; Spec AC-5,
  Out of scope line 112). The active config's `implementation.enabled:
  false` / `design.enabled: false` stay verbatim.
- **No `.claude/verification.yml.example` edit.** Placement is
  single-location in SKILL.md (placement decision above); editing the
  example file too would create the split R-01 (c) rejects and a
  second annotated copy that drifts. (If a future maintainer wants a
  one-line "see SKILL.md `## Project adoption triggers`" pointer in the
  example's `implementation:`/`design:` comment blocks, that is an
  optional, separate, non-#11 nicety — explicitly **not** an #11
  deliverable, to keep the placement single-source.)
- **No `protocol.md` edits.** The per-change `## When to invoke` and
  `## Configuration` blocks in `implementation/protocol.md` and
  `design/protocol.md` are correct and out of scope (Spec Non-goals
  line 30, Out of scope line 115). #11 points *to* them; it does not
  modify them.
- **No CI workflow and no script** (Spec Non-goals line 26, Out of
  scope line 113). #11 is documentation/convention; a configuration-audit
  detector is explicitly forbidden as an #11 consequence and is not a
  deferred-optional either (unlike #09/#10, the Spec forbids it
  outright, not "deferred").
- **No agent-prompt edits.** No `product-manager.md`, `architect.md`,
  `orchestrator.md`, `implementer.md`, or Critic-agent prose changes.
  SKILL.md is the single source; the orchestrator/product-manager read
  it as policy context (Spec Target-users row 3 / User-story row 4) via
  the existing `## Development Workflow` step 3 route, which already
  names the verification-layer Skill.
- **No Roadmap row change.** Row #11's `Design source` cell stays
  `spec:`-only — this is an ADR-014 amendment, ADR-014 has no milestone
  row of its own, so no `adr:` link is added to row #11 (Milestone →
  ADR is 0:1; identical to the #07, #08, #09, and #10 amendments' row
  reasoning). `product-manager` flips the row glyph `◐→☑` after the
  step-6 quality gate per the #07 transition matrix; `architect` adds
  no `adr:` link here. (Per ADR-014 write-ownership the `architect`
  *would* add an `adr:` link only if a *new* ADR were authored; an
  amendment to ADR-014, which owns no row, adds none — the #07–#10
  precedent.)
- The Japanese counterpart of this ADR
  (`014-roadmap-index-single-entry-point.ja.md`) receives the mirrored
  amendment **in this same session** (architect-owned ADR JA-sibling
  parity for an ADR this task edits; see the report). The Japanese
  counterpart of CLAUDE.md (if present) and the JA Spec sibling
  (`specs/11-…ja.md`) remain `technical-writer` tasks, **not** part of
  this change. Because the EN↔JA mirror lands in the same session, the
  #06 bilingual-parity detector (`check-bilingual-parity.sh`) sees a
  matched heading tree on the ADR-014 pair at commit time — no
  transient FAIL is introduced by this amendment (distinct from the
  #07–#10 amendments, which deferred the JA mirror to `technical-writer`
  and accepted a transient FAIL; the task constraint here requires
  same-session ADR JA parity).

### MECE / no-detector / no-new-partition statement (Spec R-01 (d), AC-7, AC-8)

This placement introduces **no new CI detector** and **no new MECE
partition inconsistent with this file's §(d) table at line 1800**. #11
*populates* the `documentation/convention` slot the §(d) table already
reserved and classified for it (line 1800 row; line 1808 owner
sentence) before #11's Spec existed; it adds no row to that table, no
fourth detector to the #04/#05/#06 detector-family contract partition,
and no new keying. The boundary among #11 (verification-domain
project-adoption guidance, SKILL.md prose), the per-change runtime
triggers (`implementation/protocol.md` / `design/protocol.md`
`## When to invoke`), #04 (`check-dangling-refs.sh` path resolution),
and #05 (`check-roadmap-drift.sh` Roadmap-structural consistency)
remains unambiguous to a future milestone author: a *project-level
"should I enable this domain?"* question is #11's SKILL.md section; a
*per-change "does the Critic spawn now?"* question is the protocol
files'; a *broken prose path* is #04's; a *Roadmap-index/glyph defect*
is #05's. No two-owner ambiguity is created.

### Counter-proposal

The serious counter-position is **author a new ADR-019 rather than <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
amend ADR-014** — recorded here per the
ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 convention of
taking the rejected alternative seriously, not as a strawman. The
argument: #11 is the first verification-layer *adoption-guidance*
milestone; it introduces a reader-facing decision-framework concept
("project-characteristic triggers" as distinct from per-change
triggers) that did not previously exist in the Skill; a dedicated
ADR-019 would give that concept a single citable home and a clean <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
Counter-proposal slot of its own, rather than nesting it as the seventh
amendment in an already-long ADR-014.

**Why the counter was not adopted:**

- The decisive issue is the **ADR-018 triad is not met**. ADR-015,
  ADR-017, and ADR-018 each self-classified as new-ADR-worthy *because*
  each shipped a new detector + new MECE boundary + new keying. #11
  ships **none** of the three (clauses above, with Spec line
  evidence): the Spec *forbids* a detector (line 26, 113), adds *no*
  partition (the §(d) table already names #11), and introduces *no*
  keying (prose only). The ECC precedent's own concrete signal is
  absent; a new ADR would contradict the discriminator the Spec's R-01
  instructs the architect to apply.
- A "first adoption-guidance milestone" novelty argument proves too
  much: by it, #07 (first status-ownership), #08 (first Analyze
  row-guard), #09 (first filename pin), and #10 (first directory pin)
  would each also have warranted a new ADR. All four were ADR-014
  amendments precisely because novelty-of-topic is not the
  discriminator — *new structural mechanism* is, and all four (like
  #11) clarified a consequence of a boundary ADR-014 already owned.
  Consistency with the immediately-preceding four sibling decisions
  outweighs the citable-home convenience.
- The "single citable home" benefit is delivered without a new ADR:
  this amendment *is* the citable home, co-located with the §(d) MECE
  table that names #11 — keeping the table and the decision that
  populates its slot in one file is *better* bookkeeping than splitting
  them, the same locality argument ADR-018 used for its three-way
  contract partition.

**Trigger conditions for re-evaluating this counter-proposal (i.e.
when ADR-019 would become warranted):** <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->

- A future milestone adds a **CI detector** that audits or enforces
  which verification domains a fork has enabled (the precise thing
  #11's Spec forbids) — that detector + its MECE boundary + its keying
  would meet the triad and warrant its own ADR (not an ADR-014
  amendment, and not retroactively reclassifying #11).
- The project-adoption guidance is found to require a **new structural
  convention** beyond prose — e.g. a machine-readable
  capability-to-domain mapping the agents parse at Analyze time —
  introducing a mechanism and a keying rule the triad would then
  satisfy.
- The §(d) MECE table is restructured such that #11's
  `documentation/convention` slot no longer exists or is redrawn,
  removing the pre-reserved boundary this amendment populates — at
  which point #11's home would be reconsidered with the partition.

The counter-proposal stays in this amendment as the historical record
of the decision's most serious objection, per the
ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 convention.

The original Status line (`Accepted — 2026-05-15`) is unchanged; this
amendment records a placement decision that populates a slot ADR-014's
own §(d) MECE table pre-reserved for #11 and does not reopen the
Decision (nor ADR-010's, which it leaves verbatim).

## Amendment — 2026-05-20 (quality-gate loop re-entry anchored to Roadmap row)

This amendment closes the failure-path converse of the
`◐ in-progress → ☑ done` row of the 2026-05-17 status-transition
ownership matrix above. That matrix sanctioned the **success path**
(`◐→☑` after the step-6 quality gate **passes**, owned by
`product-manager`). It did **not** state what happens during the gate
when one or more quality-gate agents return CRITICAL or HIGH findings —
the fix-and-re-review loop that, in practice, every prior milestone has
exercised but no formalized rule named. `specs/21-quality-gate-row-anchor.md`
(Roadmap row #21) is the authoritative scope; it defers the structural
*how* to `architect` (its Risk R-01 (a)–(d)). This amendment records
that decision. It is a **consequence-clarification of the 2026-05-17
status-transition matrix**, not a new structural decision: the matrix's
`◐→☑` row already states the gate-pass trigger; #21 names what holds
while the gate has *not yet* passed. No new detector, boundary, keying,
or mechanism is introduced. Per the ECC precedent this ADR's
2026-05-16, 2026-05-17 (×5), 2026-05-20 (ADR-006), and 2026-05-20
(ADR-011) amendments apply ("consequence-clarifications fold into
amendments; new ADR numbers are reserved for new structural decisions" —
ADR-015 §Context, ADR-017/ADR-018 Alternative B), this is an ADR-014
amendment, **not ADR-023**. No ADR-023 is created; Roadmap row #21 <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal; it is intentionally never created (see Counter-proposal below) -->
gains an `adr:` link to ADR-014 with the `(amended 2026-05-20)`
annotation, mirroring the row #19/#20 amendment-citation shape, while
ADR-014 has no milestone row of its own and so carries no
`Roadmap row:` line for #21 — the row-back-link contract is one-way
(row → amendment), consistent with the #07/#08/#09/#10/#11 amendment
precedents that left their corresponding Roadmap rows `spec:`-only.

(#21's row receives an `adr:` link in this amendment because Spec AC-9
explicitly requires the `adr:` link to resolve to the ADR if any new ADR
was issued — and an amendment with an explicit Roadmap row attribution
is the substantive equivalent of a row-bound ADR for citation purposes.
The #07/#08/#09/#10/#11 rows did not receive `adr:` links because their
Specs did not state that acceptance criterion; #21's Spec does. The
contract surface — "the row points to the source of structural
resolution" — is honored equivalently in both shapes.)

### Triad classification — 0/3, amendment-not-new-ADR

The Spec hands `architect` the ADR-018 Alternative-B triad
discriminator (new contract boundary + new keying/mechanism + new
structural artifact ⇒ new ADR; consequence-clarification inside an
existing contract ⇒ amendment). Applied clause by clause to #21:

- **New contract boundary? No.** The 2026-05-17 #07 status-transition
  amendment above (lines 415–425) already established the
  `◐→☑` trigger condition verbatim: "After the Workflow step 6 quality
  gate passes for the milestone … `product-manager` … performs the
  flip; no other role may." #21's row-anchor invariant (Spec AC-2) is
  the **logical converse** of that already-stated success condition:
  while the gate has not yet passed (one or more CRITICAL/HIGH findings
  open), no row transition occurs. This is consequence-clarification of
  an already-stated trigger, not a new contract boundary. The re-entry
  routing (Spec AC-1: `orchestrator` routes the fix back to
  `implementer`) maps to roles whose Workflow contracts ADR-014 already
  establishes — `orchestrator` is the Analyze/routing authority (#08
  amendment lines 716–760), `implementer` owns step-5 implementation
  including fixes within the same milestone's Spec (no role change).
  No new role, no new ownership concept, no new contract surface.
- **New keying / mechanism? No.** The mechanism by which the loop is
  governed is the **same Status glyph cell** the #07 amendment already
  owns; the same `## Roadmap` Rules block already documents who may
  write it and when. The Spec explicitly forbids "Adding a new CI
  detector for quality-gate loop compliance" (Non-goal) and "Designing
  a general workflow-state-machine engine" (Non-goal). Spec R-01 (d)
  defers the CI detector necessity to `architect`; this amendment's
  judgement is **no detector** (see §(d) below). No new YAML key, no
  new regex, no new file format, no new short-circuit, no new
  detector. The existing `check-roadmap-drift.sh` (#05) glyph-value
  well-formedness check remains the sole automated touch on the Status
  cell — the MECE boundary against #05 (already stated by the #07
  bullet in the Rules block: "no CI enforces #07") extends unchanged
  to #21.
- **New structural artifact? No.** No new file, no new directory, no
  new CI workflow, no new agent role, no new Skill, no new template,
  no new workflow step (Spec Non-goal: "The quality-gate loop is
  already implicit in step 6; #21 names the ownership and anchor
  invariant within that step, not a new step number"). The placement
  target is the same `## Roadmap` Rules block in CLAUDE.md the #07
  amendment populated; the artifact is one added Rules-block bullet,
  not a new section, table, or sub-heading. Spec AC-7 requires the
  seven canonical detectors all green; AC-8 requires the eight
  canonical test suites all passing — explicit Spec affirmation that
  no new detector/test joins the canonical set.

Triad total: **0/3**. Per ADR-018 Alternative-B (and the
ADR-022 §1 / ADR-006 amendment 2026-05-20 / ADR-011 amendment
2026-05-20 applications of the same discriminator), 0–2/3 routes to an
**amendment of the existing ADR**, not a new ADR. ADR-022's
"new-ADR-vs-amendment" reasoning explicitly states that the triad
fires 3/3 to warrant a new ADR; #21's 0/3 is the strongest amendment
case in the family (stronger than #19's 1/3 and #20's 1/3 because #21
introduces literally no new contract direction, only the converse
statement of one already inside this very ADR). A new ADR-023 was <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal, intentionally never created -->
considered (Spec AC-6 names it as one branch of the OR) and rejected: <!-- ref-allow: counterfactual reference; ADR-023 deliberately not issued per triad 0/3 outcome | expires: 2026-07-20 -->
folding the resolution into ADR-014 itself keeps the four-row
Status-Transition Matrix and its converse-statement (the row-anchor
invariant) co-located at a single source of truth, matches the
#07/#08/#09/#10/#11 amendment shape exactly, and avoids fragmenting the
Roadmap-mechanism contract across two ADRs — the same reasoning the
#07 amendment counter-proposal lines 599–607 used to reject a separate
ADR-019 for the success-direction matrix. <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal for the #07 success-direction matrix; intentionally never created -->

### The row-anchor invariant and re-entry routing rule

Exactly two complementary statements, both consequences of the
2026-05-17 status-transition matrix's `◐→☑` row:

**Row-anchor invariant (Spec AC-2 / AC-3).** A Roadmap row at
`◐ in-progress` remains at `◐ in-progress` for the full duration of
the quality-gate loop; no actor flips it to `☑`, `✗`, or `☐` while one
or more CRITICAL or HIGH findings from any step-6 quality-gate agent
(`code-reviewer`, `linter`, `security-reviewer`, `performance-engineer`)
are open. The `◐→☑` transition fires **once and only when** every
quality-gate agent has passed for that milestone — the exit condition,
not a mid-loop action. The `◐→✗` transition fires only on an
`orchestrator`-confirmed drop decision (matrix row 3 unchanged).

**Re-entry routing (Spec AC-1).** When any quality-gate agent returns
one or more CRITICAL or HIGH findings, the **orchestrator** is the
named routing owner: it routes the fix task back to `implementer` and
initiates re-review. No other agent self-assigns the fix unilaterally;
no quality-gate agent loops back to itself without orchestrator
routing. `implementer` owns the fix action against the same Spec, and
the same quality-gate agents re-review when `implementer` reports the
fix complete. The cycle continues until all CRITICAL/HIGH findings are
resolved (gate passes ⇒ row eligible for `◐→☑` per matrix row 2) or
the milestone is dropped (`◐→✗` per matrix row 3).

**Resolving the unnamed "loop owner" ambiguity (Spec R-01 (a)).** The
interim practice left the routing owner implicit. This amendment
resolves it to a **named role: `orchestrator`**, the routing authority
ADR-014's #08 amendment already established for Analyze-step pre-
dispatch (G1–G3 guard). The MECE boundary against #08 is precise: #08
governs the **pre-dispatch** preconditions for **initial dispatch**
(does the row exist? Spec on disk? progress file surfaced?); #21
governs the **post-dispatch re-routing** that fires when a
quality-gate agent has already reviewed an implementation and returned
findings. Same routing role, two non-overlapping trigger points, no
ownership gap. (See §(d) below for the explicit boundary statement.)

**Composability with ADR-016 (Spec AC-4).** ADR-016's
`specs/NN-progress.md` mechanism is triggered by a session or
compaction boundary while `◐ in-progress`, not by a quality-gate loop
round. A loop that completes within a single session creates no
progress file (no boundary crossed); a loop mid-flight when a session
ends invokes both mechanisms (the loop continues across the boundary;
the progress file captures the mid-loop state for the resuming
agent — Spec R-02 names the natural extension of the
`progress-template.md` `## Notes` field to record loop state, which is
an implementer detail at step 5, not an ADR-layer mechanism). The two
mechanisms operate on different triggers and are non-overlapping.

**Composability with the 2026-05-17 #07 matrix.** #21's row-anchor
invariant is the converse of matrix row 2's success-trigger condition:
together they form a complete MECE picture of the `◐→☑` boundary.
Matrix row 2 says **when** `◐→☑` is authorized (gate passes); #21
says **when** it is prohibited (gate has not yet passed). No overlap,
no gap. Matrix rows 3–4 (`◐→✗` / `☑→✗`) are unaffected; #21's invariant
applies only to the `◐→☑` direction during an open loop.

### Documentation placement (Spec R-01 (a))

The formalized re-entry rule and row-anchor invariant live in the
**CLAUDE.md `## Roadmap` Rules block** as one added bullet, **not** in
the Development Workflow section and **not** duplicated into agent
prompts. Rationale (the same three-step argument the #07/#09 amendments
applied, now extended to #21):

- The Rules block is **index-adjacent and compaction-durable**: it
  sits directly under the Roadmap table every agent reads on every
  step (Invariant 2), so `orchestrator` and `implementer` encounter
  the re-entry rule and row-anchor invariant at exactly the step they
  would route a fix or perform a flip, with **zero additional file
  reads** — the Spec's R-01 (a) acceptance criterion ("documented so
  an agent executing step 6 encounters them without additional file
  reads").
- It is the **tightest placement** respecting the CLAUDE.md
  line-budget guidance: the Rules block is *inside* the Roadmap
  section, which is already the sanctioned line-budget exception (this
  ADR's 2026-05-16 line-budget amendment). One added bullet to an
  already-exempt section costs no budget elsewhere; adding prose to
  `## Development Workflow` step 6 would bloat a non-exempt section
  and would also fragment the matrix from its converse (one in the
  Rules block, one in the Workflow prose) — the exact rediscovery
  problem this ADR was created to remove.
- It is **matrix-adjacent**: the row-anchor invariant is the converse
  of the existing #07 bullet's `◐→☑` clause. Placing the converse one
  bullet below the success-direction bullet keeps the two facets of
  the same matrix row co-located, satisfying the "one source of
  truth for who may flip a Roadmap cell" property #07's amendment
  established.

Placing the rule in `orchestrator.md` Workflow step prose was
considered (Spec R-01 (c) alternative); rejected because (i) the rule
constrains four roles (`orchestrator` routes, `implementer` fixes,
quality-gate agents re-review, `product-manager` does *not* flip
prematurely) — placing it in one role's prompt would require either
duplicating it across four prompts (drift surface) or leaving three of
the four roles to discover the rule by reading another role's prompt
(violates the always-readable invariant); (ii) it would not be
compaction-durable in the same way the Rules block is (Invariant 2),
forcing re-reads each session; (iii) it would invert the discipline
the #07/#08/#09/#10/#11 amendments established for the same family of
Roadmap-mechanism rules — every prior amendment placed its rule in the
Rules block, never in an agent prompt.

The exact one-bullet wording is handed to `implementer` below; the
MECE boundary against #08 G1–G3 (Spec AC-5) and the MECE boundary
against ADR-016 (Spec AC-4) are restated in the bullet so a future
milestone author does not route a re-entry question to #08 or a
progress-file question to #21.

### Spec R-01 (b)(c)(d) judgements recorded for the implementer

- **(b) Amendment vs new ADR:** ADR-014 amendment (triad 0/3, decided
  above). No ADR-023. Row #21 Design-source cell gains an `adr:` link <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal, intentionally never created -->
  in the #19/#20 amendment-citation shape:
  `<br>adr: \`.claude/meta/adr/014-roadmap-index-single-entry-point.md\` (amended 2026-05-20)`.
  This satisfies Spec AC-6 branch (b) ("an existing ADR receives an
  amendment explicitly addressing those questions") and AC-9 ("if a
  new ADR was issued, the `adr:` link resolves to … `023-*.md`") — the
  `adr:` link resolves to the ADR carrying the structural resolution
  (here, the amended ADR-014), which is the substantive contract AC-9
  encodes.
- **(c) Agent-prompt impact:** **no agent prompt requires editing.**
  The re-entry rule assigns routing to a role whose routing contract
  ADR-014's #08 amendment already established (`orchestrator` owns
  Analyze-step routing). `implementer` already owns Workflow step 5
  implementation, which includes fixes within the same milestone's
  Spec — no role change. The four quality-gate agents already own
  step-6 review (`.claude/CLAUDE.md` §Development Workflow step 6,
  unchanged); the re-review action is the same action they perform on
  initial dispatch, just on a re-routed input. `product-manager`
  already owns row writes per ADR-014 §Decision and the #07 matrix;
  the row-anchor invariant constrains *when* (not *how* or *who*) for
  a write `product-manager` is already the sole owner of. Recording
  the rule in the always-read Rules block (not in prompts) is the
  deliberate minimal-surface choice, consistent with the
  #07/#08/#09/#10/#11 amendments keeping their changes out of agent
  prompts.
- **(d) CI detector necessity:** **no detector is warranted.** Three
  reasons:
  1. **Detection requires audit-log infrastructure that does not
     exist.** A "row flipped to `☑` while CRITICAL/HIGH findings open"
     incident is only detectable if the CI can read the quality-gate
     agents' historical findings against the commit that flipped the
     glyph. The template has no such audit log; sub-agent findings are
     ephemeral session artifacts, not committed. Building that
     infrastructure is far beyond #21's scope (Spec Non-goal:
     "Adding a new CI detector for quality-gate loop compliance …
     requires audit-log infrastructure that does not exist and is not
     in scope").
  2. **#05 already owns glyph-value well-formedness (the orthogonal
     check axis).** `check-roadmap-drift.sh` validates that every
     Status cell holds one of the four sanctioned glyphs (☐ / ◐ / ☑ /
     ✗). That is the static check the Roadmap mechanism can perform.
     #21's process rule (who flipped when, in what gate state) is
     dynamic and lies outside the static-artifact contract #05 owns.
     The #07 amendment's Rules-block bullet already states this MECE
     boundary verbatim ("#05 checks glyph *value* well-formedness;
     #07 governs *who* flips and *when* — no CI enforces #07"); #21's
     bullet inherits the same boundary, restated for symmetry.
  3. **A process detector is not the discipline of the detector
     family.** The existing seven detectors (#04 dangling-refs, #05
     drift, #06 bilingual-parity, ADR-022 ref-allow-expiry, #14
     research-tier-auth, ECC-delegation-consistency, skill-invariants)
     all enforce **static-artifact contracts** (a file exists / a
     pointer resolves / a heading sequence matches / a glyph is one of
     four characters). Adding a detector that audits dynamic process
     compliance (who flipped a row during which sub-agent review
     round) would introduce a new detector category and break the
     family's locality-of-behavior discipline. Spec AC-7 explicitly
     bounds the canonical set at seven; adding an eighth detector for
     a process rule would expand a contract Spec AC-7 closes.

  The judgement is symmetric with the #07 amendment's no-detector
  judgement (lines 543–545: "No CI workflow (Spec Non-goals; #07 is a
  process/documentation assignment, not an automated check)") and is
  the strongest such case in the family (no automated enforcement is
  even theoretically achievable without audit-log infrastructure).

- **(d) claude-md-authoring Skill necessity:** the deferred CLAUDE.md
  edit is **one bullet appended to the existing `## Roadmap` Rules
  list** — a "routine small edit (… single bullet …)" by the explicit
  carve-out in CLAUDE.md's `## CLAUDE.md authoring guidance` section
  ("Routine small edits (typo, single bullet, version bump) do not
  need the Skill"). It is **not** "significant restructuring" (no
  section added/moved/split, no heading change, no invariant touched).
  **Judgement: the claude-md-authoring Skill is NOT required** for
  the #21 implementation edit. (If the implementer instead chooses to
  add a sub-heading or a table, that *would* cross into restructuring
  and the Skill would then apply — but the design here is
  deliberately a single bullet precisely to stay under the
  routine-edit carve-out, mirroring the #07/#09 amendments.)

### MECE boundary statement against #07 / #08 / #04 / #05 / ADR-016 (Spec R-03, AC-4, AC-5)

The re-entry rule fits the existing partition without re-drawing any
boundary:

| Owner | Question | Trigger point |
|---|---|---|
| #07 (above amendment) | Who flips a Roadmap Status glyph, and when does each transition fire? | The transition event itself (success path: gate passes; drop path: orchestrator-confirmed drop) |
| #21 (this amendment) | What holds **between** dispatch and the `◐→☑` flip when one or more quality-gate agents return findings? | After step-6 review returns CRITICAL/HIGH findings, before all gate agents pass |
| #08 (above amendment) | What preconditions must hold for any sub-agent to be dispatched in the first place? | Orchestrator's Analyze step, pre-dispatch |
| #04 `check-dangling-refs.sh` | Does every cross-reference pointer resolve? | Static-artifact scan, always-on CI |
| #05 `check-roadmap-drift.sh` | Is each Status cell a sanctioned glyph value, and is the bidirectional Roadmap-index contract intact? | Static-artifact scan, always-on CI |
| ADR-016 `specs/NN-progress.md` | What in-flight state crosses a session or compaction boundary? | Session/compaction boundary while `◐` |

A defect maps to exactly one owner: a missing routing decision after
findings ⇒ #21; a glyph-character mismatch ⇒ #05; a broken
pointer ⇒ #04; a pre-dispatch precondition failure ⇒ #08; the
ownership-and-timing of a flip itself ⇒ #07; cross-session state
carry ⇒ ADR-016. The Spec's AC-5 (boundary against #08) and AC-4
(boundary against ADR-016) are honored: #08's trigger point is
pre-dispatch (G1–G3 fire **before** any sub-agent receives a task);
#21's trigger point is post-review (a sub-agent has **already**
returned findings). The same `orchestrator` role owns both routing
decisions, but the trigger points are non-overlapping in time and in
input.

### Composability with #13 (ECC-absent degraded-review signal — Spec Key Interaction 4)

#13 emits a degraded-review warning when the matching ECC
`<lang>-reviewer` Skill is absent in a fork — the language-depth
coverage is reduced but the review still proceeds. #21's re-entry rule
governs **routing** of findings, not their **production**. When #13
fires, the `code-reviewer` still owns the meta-review role and still
returns findings (some CRITICAL/HIGH, some downgraded due to the
absent Skill); when those findings arrive, #21's re-entry routing
applies unchanged — the orchestrator routes the fix back to
`implementer` regardless of whether the findings came from a full or
degraded review. The two milestones are **non-interfering**: #13 does
not alter the re-entry routing or the row-anchor invariant; #21 does
not alter the degraded-review signal. The Spec Key Interaction 4
statement holds verbatim.

### Downstream `implementer` tasks (performed in this same session — for #21 the two-session decision-then-implementation split used by #03/ADR-016 · #05/ADR-017 · #06/ADR-018 · #07/ADR-014-amendment · #08/ADR-014-amendment · #09/ADR-014-amendment · #10/ADR-014-amendment was deliberately collapsed; the rationale matches #11's collapse: #21's implementation is a single prose-only Rules-block bullet edit, fully enumerated below and verifiable against Spec AC-1 / AC-2 / AC-3 / AC-4 / AC-5 in one pass, requiring no separate review cycle; the task list is retained verbatim for traceability and as the precedent shape for milestones whose implementation *is* deferred)

- `.claude/CLAUDE.md` `## Roadmap` **Rules** block — append one bullet
  after the existing #07 status-glyph-transitions bullet, of the form:
  *"Quality-gate loop re-entry (#21): while a row is `◐ in-progress`
  and one or more CRITICAL/HIGH findings from any step-6 quality-gate
  agent (code-reviewer, linter, security-reviewer,
  performance-engineer) remain open, `orchestrator` routes the fix
  task back to `implementer` and the row stays `◐` for the full loop
  duration. The `◐→☑` flip per #07 fires only after every quality-gate
  agent passes for that milestone — the loop's exit condition, not a
  mid-loop action. ADR-016 progress files apply only when the loop
  crosses a session or compaction boundary; an in-session loop creates
  no progress file. #08 G1–G3 govern initial dispatch (pre-dispatch);
  #21 governs re-entry after a quality-gate agent has returned
  findings (post-review) — non-overlapping triggers, same `orchestrator`
  router. No CI enforces #21 (process rule; #05 owns glyph-value
  well-formedness, the orthogonal check axis)."* Single bullet, no
  sub-heading, no table — stays within the routine-edit carve-out (no
  claude-md-authoring Skill invocation required), exactly the #07
  amendment shape.
- `.claude/CLAUDE.md` `## Roadmap` table row #21 — flip the
  Design-source cell from `spec:`-only to:
  `spec: \`specs/21-quality-gate-row-anchor.md\`<br>adr: \`.claude/meta/adr/014-roadmap-index-single-entry-point.md\` (amended 2026-05-20)`.
  This is the `architect` write per ADR-014's existing write-ownership
  rule ("architect adds the `adr:` link"); performed by **this
  amendment in the same change**, mirroring rows #19/#20's pattern of
  pointing to an amended ADR rather than a new ADR. The row's Status
  glyph was flipped `☐→◐` by `product-manager` at Spec authoring (the
  atomic action mandated by the #07 amendment); this amendment adds
  only the `adr:` link cell to the same row without touching the
  glyph. `product-manager` performs the `◐→☑` flip at step 6
  close-out per the #07 amendment, after the step-6 quality gate
  passes and steps 7–9 complete.
- **No agent-prompt edits** (judgement above). The implementer must
  *not* add re-entry-routing prose to `orchestrator.md`,
  `implementer.md`, `code-reviewer.md`, `product-manager.md`, or any
  other agent file; the Rules block is the single source.
- **No CI workflow, no new detector, no new test suite** (judgement
  above; Spec Non-goals and AC-7/AC-8). The existing seven detectors
  and eight test suites continue to pass unchanged.
- **No `progress-template.md` edit in this amendment.** Spec R-02
  identifies a natural extension of the template's `## Notes` field to
  record loop state when a quality-gate loop crosses a session
  boundary; that is an `implementer`-step-5 detail when authoring a
  progress file in that exact scenario, not a template change this
  amendment performs. The current template already permits free-form
  notes; encoding loop state as a `## Notes` entry uses the existing
  surface unchanged.
- The Japanese counterpart of this ADR
  (`014-roadmap-index-single-entry-point.ja.md`) must receive the
  mirrored amendment, and the Japanese counterpart of CLAUDE.md (if
  present) the mirrored Rules-block bullet — a `technical-writer`
  task, **not** part of this change. **This amendment creates a
  transient EN/JA heading mismatch on ADR-014 until `technical-writer`
  mirrors it; the #06 bilingual-parity detector
  (`check-bilingual-parity.sh`) will FAIL on ADR-014 until the mirror
  lands. This is the expected, queued `technical-writer` task — not a
  reason to omit this EN amendment.** (The same transient was accepted
  for the #07, #08, #09, #10, #11, #19, #20 amendments in turn.)
- `specs/21-quality-gate-row-anchor.ja.md` is authored by
  `technical-writer` at step 7 per Roadmap #06 heading-tree parity
  ownership; not part of this amendment.
- `CHANGELOG.md` entry under `## [Unreleased]` recording the
  quality-gate loop re-entry formalization is authored by
  `technical-writer` at step 7 (Spec AC-10); not part of this
  amendment.

### Counter-proposal

The serious counter-position is **new ADR-023 — formalize the <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal, intentionally never created -->
quality-gate loop re-entry rule as a standalone ADR rather than an
ADR-014 amendment**. It is recorded here per the
ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 convention of
taking a rejected alternative seriously rather than as a strawman. The
argument:

1. The Spec hands `architect` an explicit (b) choice ("a new ADR-023 <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal, intentionally never created -->
   exists … or an existing ADR receives an amendment") — Spec AC-6
   names ADR-023 as the first branch, suggesting parity with milestones <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal, intentionally never created -->
   #03 / #04 / #05 / #06 / #12 / #13 that received new ADRs.
2. A re-entry routing rule that constrains the orchestrator's failure-
   path routing is a first-class, citable contract; burying it as the
   seventh amendment in a long ADR-014 trail makes it less discoverable
   than a dedicated ADR-023 a reader can cite as "the quality-gate <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal, intentionally never created -->
   loop ADR."
3. The re-entry path interacts with multiple ADRs (ADR-016 via the
   progress-file boundary, the #07 matrix via the `◐→☑` converse, #08
   via the routing-trigger MECE boundary, #13 via the degraded-review
   compatibility). A standalone ADR could own the four-way boundary
   statement explicitly, rather than appending another section to a
   2400+-line ADR-014.

**Why the counter was not adopted:**

- ADR-017, ADR-018, ADR-019, ADR-020, ADR-021, and ADR-022 each
  self-classified as new-ADR-worthy on the ADR-018 Alternative-B
  triad with a 2/3 or 3/3 score. #21 scores **0/3** — the strongest
  amendment case in the family (no new contract boundary, no new
  keying/mechanism, no new structural artifact). The sibling-symmetry
  argument inverts on inspection: applying the same triad
  discriminator the #03/#04/#05/#06/#12/#13 ADRs used to themselves
  yields "amendment" for #21, because the structural half that
  dominated for them is wholly absent for #21 — the rule is the
  failure-path converse of a success-path trigger ADR-014 itself
  already states (in the very amendment this one extends). This is
  the exact reasoning the #07/#08/#09/#10/#11 amendments used to
  refuse separate ADR-019 numbers, and which the #19/#20 amendments
  re-applied at 1/3.
- Discoverability is *better*, not worse, as an ADR-014 amendment:
  the four-row Status-Transition Matrix and its converse-statement
  (the row-anchor invariant) belong in one file, not two. The
  canonical place a reader looks for "what governs a Roadmap row's
  Status during step 6" is the ADR that defined the Roadmap and
  already states the success-direction trigger; a separate ADR-023 <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal, intentionally never created -->
  would *fragment* the matrix across two ADRs — the orchestrator
  would have to read ADR-014 *and* ADR-023 to know the full <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal, intentionally never created -->
  `◐→☑` picture, reintroducing exactly the "which document is
  authoritative" rediscovery ADR-014 exists to remove.
- The bidirectional-back-link argument is satisfied without a new
  ADR: this amendment populates row #21's `adr:` link with the
  `(amended 2026-05-20)` annotation in the #19/#20 shape, giving the
  row the citation surface AC-9 requires. ADR-014 has no milestone
  row of its own, so the back-link is correctly one-directional
  (row → amendment), consistent with the #07/#08/#09/#10/#11
  precedents.
- The four-way boundary argument is *better*, not worse, as an
  ADR-014 amendment: #08 (the routing-trigger MECE boundary partner)
  is itself an ADR-014 amendment, and the #07 matrix (the
  success-direction partner) is itself an ADR-014 amendment. Stating
  the four-way boundary in ADR-014 keeps all four boundary partners
  in one file; in a separate ADR-023 the boundary would have to <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal, intentionally never created -->
  cross-cite three sections of ADR-014 by line range — the locality
  argument runs strictly toward the amendment.

**Trigger conditions for re-evaluating this counter-proposal (i.e.
when ADR-023 would become warranted):** <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal, intentionally never created -->

- A future milestone adds a **CI detector** that statically audits
  quality-gate loop compliance — for example, an audit-log mechanism
  that records each sub-agent's findings and the commits that
  followed, and a detector that flags a `◐→☑` flip whose commit
  predates an unresolved CRITICAL/HIGH finding. That detector + its
  MECE boundary against #05's glyph-value check + its keying rule
  would meet the triad and warrant its own ADR (with this amendment's
  process rule as its inherited baseline).
- The quality-gate loop is found to require a **new structural
  mechanism** beyond a process bullet — e.g. a machine-readable
  per-milestone gate-status manifest the orchestrator parses at
  re-entry, or a quality-gate state machine with named sub-states
  inside `◐`. Such a mechanism would introduce a new keying rule and
  a new artifact, satisfying the triad.
- The four-way boundary statement (#21 vs #07, #08, #04, #05,
  ADR-016, #13) is found to require divergent re-entry semantics per
  fork profile (e.g. forks that drop one or more quality-gate agents
  need a different routing rule) such that a single rule in ADR-014
  can no longer express it — at which point a dedicated ADR with
  per-profile routing matrices may be warranted.

The counter-proposal stays in this amendment as the historical record
of the decision's most serious objection, per the
ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 convention.

The original Status line (`Accepted — 2026-05-15`) is unchanged; this
amendment records the failure-path converse of an ownership rule the
2026-05-17 status-transition amendment above already sanctioned for
the success path, and does not reopen the Decision.

## Amendment — 2026-05-20 (Roadmap relocation to `.claude/ROADMAP.md`; line-budget exception withdrawn)

This amendment relocates the Roadmap **index** (the row table + Rules
block) from `.claude/CLAUDE.md` to a new dedicated file
`.claude/ROADMAP.md`, and withdraws the 2026-05-16 (CLAUDE.md
line-budget vs. the Roadmap) amendment that exempted the Roadmap
section from CLAUDE.md's ~200-line guideline.

The decision was reached by an Agent Team consultation (architect,
product-manager, orchestrator, technical-writer) on 2026-05-20 after
the user surfaced three concerns spanning template-fitness: (1)
subagent dispatch prompt bloat, (2) CLAUDE.md as a worktree write-
contention surface, and (3) template-internal artifacts leaking into
fork repositories. This amendment addresses concern (2); concerns
(1) and (3) are addressed in ADR-024 (Subagent dispatch contract)
and the deferred Phase B branch-separation work (Roadmap row #23)
respectively. The full Plan that orchestrated the change is at
`/Users/b150005/.claude/plans/roadmap-agent-team-explore-shimmering-nygaard.md`
(plan file, outside the repo); the per-row Spec for this amendment
is `specs/22-claude-md-invariant-refactor.md`.

### What relocates

- **Roadmap row table** (21 historical rows + 2 newly-added rows for
  #22 and #23) moves from CLAUDE.md `## Roadmap` to
  `.claude/ROADMAP.md` `## Index`.
- **Rules block** (the bulleted protocol rules — spec reservation,
  filename convention, status-glyph transitions, quality-gate
  re-entry, write-ownership, phase-split convention) moves to
  `.claude/ROADMAP.md` `## Rules`, co-located with the data it
  governs.
- **Spec reservation rule paragraph** moves into the new file's
  header narrative.

### What stays in CLAUDE.md

- `## Roadmap` heading with a short pointer paragraph naming
  `.claude/ROADMAP.md` as the canonical index location.
- A one-paragraph **Write-ownership summary** preserving the most
  load-bearing rule (who flips which glyph at what step) so that an
  agent reading only CLAUDE.md has the essential governance reminder
  without needing to open ROADMAP.md.

### The two new rows added in `.claude/ROADMAP.md`

- **#22 — CLAUDE.md invariant-only refactor + Roadmap relocation +
  subagent-dispatch/worktree-advisory protocols.** Status `☑ done`
  on this amendment landing. Design source includes this amendment,
  ADR-024, ADR-025, and `specs/22-claude-md-invariant-refactor.md`.
- **#23 — Template / fork structural separation (`main` payload-only
  + `develop` template-dev branch split).** Status `☐ todo`,
  deferred Phase B. Spec `specs/23-template-fork-branch-separation.md`
  reserved per ADR-014 reservation rule, not yet authored on disk.

### Why an amendment and not a new ADR

Triad classification (per ADR-018 Alternative-B discriminator):

- **New contract boundary? Partial — REFINEMENT of an existing
  boundary.** ADR-014's core decision is "the Roadmap is the single
  always-read entry point." This amendment refines *where* that
  entry point physically lives (CLAUDE.md → `.claude/ROADMAP.md`) and
  *how* it is accessed (orchestrator explicit Read at session start,
  rather than auto-load via Invariant 2). The "single always-read
  entry point" claim itself is preserved — just split across two
  files (CLAUDE.md pointer + ROADMAP.md content).
- **New keying / mechanism? Partial — REFINEMENT.** Orchestrator now
  reads two files at session start instead of one. No new YAML key,
  no new regex, no new file format, no new short-circuit.
- **New structural artifact? Yes — one new file (`.claude/ROADMAP.md`).**

Triad effective: **1.5/3**. The same discriminator threshold (3/3 →
new ADR) applies. ADR-019's amendment (CHANGELOG-ADR sync) and the
preceding 2026-05-17 ×5 amendments to this ADR all landed as
amendments at lower triad scores; this amendment continues that
pattern. The new files ADR-024 and ADR-025, by contrast, each score
3/3 and correctly are new ADRs.

The decision aligns with the ECC convention recorded in the prior
amendments above: "consequence-clarifications fold into amendments;
new ADR numbers are reserved for new structural decisions" — and
"where the Roadmap physically lives" is the clearest possible
consequence-clarification of ADR-014's "single always-read entry
point" decision.

### Withdrawal of the 2026-05-16 line-budget exception

The 2026-05-16 (CLAUDE.md line-budget vs. the Roadmap) amendment
above declared the `## Roadmap` section exempt from CLAUDE.md's
~200-line guideline because the table could not be relocated without
defeating its Invariant-2-protected always-loaded status. With the
relocation now landing, the exception's premise no longer holds: the
Roadmap content lives in a separate file, CLAUDE.md is free to fit
the ~200-line guideline again, and the exception paragraph is
removed from CLAUDE.md's `## CLAUDE.md authoring guidance` section.

The exception is **withdrawn**, not deprecated by supersession — the
2026-05-16 amendment's reasoning was correct at the time it was
made and would still be correct if the relocation had not happened.
The amendment remains in this ADR's history as the record of why
CLAUDE.md was permitted to exceed ~200 lines between 2026-05-16 and
2026-05-20.

### Trade-off: Invariant 2 protection

ADR-014's original decision relied on Invariant 2 (compaction
durability for `.claude/CLAUDE.md` root content; defined in
`.claude/skills/claude-md-authoring/invariants.md`). The Roadmap
table, by virtue of living inside CLAUDE.md, inherited Invariant 2
protection: it survived compaction without an explicit re-Read.

`.claude/ROADMAP.md` is NOT covered by Invariant 2 — it is a
regular markdown file, not a subdirectory `CLAUDE.md`, and it is
not auto-loaded by Anthropic's nested-CLAUDE-md mechanism. The
compensating mechanism is the explicit instruction in CLAUDE.md
that `orchestrator` reads `.claude/ROADMAP.md` at session start.
This is a behavioural compensation, not a structural guarantee:
if a session compacts and the orchestrator skips the Read, the
Roadmap state is lost from working memory.

The Agent Team weighed this trade-off explicitly:

- **What is lost.** Always-on Invariant-2 compaction durability for
  the Roadmap row data.
- **What is gained.** CLAUDE.md becomes write-quiet across
  worktrees (the user's stated primary concern). Roadmap mutations
  no longer collide with CLAUDE.md authoring work. Two distinct
  files = two distinct write surfaces.
- **Compensation.** Explicit orchestrator Read at session start,
  recorded in `.claude/agents/orchestrator.md` Analyze step.
- **Backstop.** If a session compacts and the read is dropped,
  ADR-016's `specs/NN-progress.md` (cross-session progress
  persistence) is the in-flight state backstop. For non-in-flight
  rows, the orchestrator re-reads ROADMAP.md on the next Analyze
  step before any new dispatch.

A note documenting this Invariant 2 trade-off is added to
`.claude/skills/claude-md-authoring/invariants.md`. The Invariant 2
*statement* is unchanged; what changes is which content is now
governed by it.

### Bilingual posture

`.claude/ROADMAP.md` is **English-only**. No `.claude/ROADMAP.ja.md`
sibling is shipped. This is explicit exemption from the Roadmap #06
EN ↔ JA heading-tree parity contract, justified by:

- The file is overwhelmingly a structured table of identifiers
  (row numbers, status glyphs, file paths) plus a bullet-list of
  rules. Almost no natural-language prose that would benefit from
  translation.
- Roadmap mutations are **frequent** (every status flip).
  Maintaining EN ↔ JA parity on every flip is high mechanical cost
  for low signal.
- The bilingual-parity detector (`.claude/meta/scripts/check-bilingual-parity.sh`)
  is keyed per-pair on `.ja.md` presence: a file with no `.ja.md`
  sibling is structurally out of scope. No allowlist entry is
  needed to exempt this file — the exemption is the absence of the
  sibling.

This is consistent with the existing EN-only specs (#01–#04) and
with `workarounds/` (which the bilingual-parity detector also
excludes per Spec Non-goals). The Roadmap #06 contract continues
to apply to every other paired artifact.

### Updates to CI check scripts

Three check scripts are updated to reflect the relocation:

- `.claude/meta/scripts/check-roadmap-drift.sh` — parse target
  changes from `.claude/CLAUDE.md` to `.claude/ROADMAP.md`; awk
  table-row detection is simplified (no longer needs section
  guard, since the entire file is the Roadmap).
- `.claude/meta/scripts/check-dangling-refs.sh` — Check 1 (ADR-NNN
  refs) and Check 2 (`.claude/-rooted` / `specs/` paths) both add
  `.claude/ROADMAP.md` to the scan set. The ADR-014 reservation
  carve-out (`is_reservation_link`) requires no change because it
  is keyed on the line containing `|` and `spec:`, which holds in
  ROADMAP.md table rows identically.
- `.claude/meta/scripts/check-bilingual-parity.sh` — no change
  needed. The per-pair keying automatically excludes
  `.claude/ROADMAP.md` because no `.claude/ROADMAP.ja.md` sibling
  exists.

The 2026-05-17 (orchestrator Analyze row-guard) amendment is
updated implicitly: G1 (row exists) now reads `.claude/ROADMAP.md`
instead of CLAUDE.md, but the guard's three-condition structure
and the orchestrator's read-only posture are unchanged.

### Triad-classification update for the 2026-05-16 line-budget exception

The withdrawn 2026-05-16 amendment scored as a procedural amendment
at the time it was made (no triad applied; ADR-018's discriminator
post-dates it). With the relocation now landing, the question
"would the line-budget exception have warranted a new ADR?" is
moot: the exception was always intended as a transitional rule,
and ECC's discriminator would have classified it at 0/3 (no new
boundary, no new mechanism, no new artifact).

The original Status line (`Accepted — 2026-05-15`) is unchanged.
This amendment is the second 2026-05-20 amendment to ADR-014 (the
first being the quality-gate loop re-entry amendment immediately
above). Both amendments are dated the same day because both
emerged from the same Agent Team consultation on 2026-05-20.
