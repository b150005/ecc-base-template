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
