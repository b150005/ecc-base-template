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
