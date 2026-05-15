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
