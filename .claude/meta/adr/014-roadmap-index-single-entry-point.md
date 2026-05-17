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

The original Status line (`Accepted — 2026-05-15`) is unchanged; this
amendment appends a runtime-precondition clarification of an
already-sanctioned Analyze-step mechanism and does not reopen the
Decision.
