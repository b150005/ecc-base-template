# Cross-Session Milestone Progress Persistence

## Status

Approved

**Owner:** product-manager / architect
**Target release:** template v3.7.0

## Problem

The Roadmap table in `CLAUDE.md` tracks implementation state with four glyphs
(☐ / ◐ / ☑ / ✗). When a milestone is marked `◐ in-progress`, the Roadmap row
records that the work has started — nothing more. It does not record which
workflow steps are complete, which Spec or ADR exists, what the next concrete
action is, or why work stopped.

A milestone of non-trivial length — picking up a ◐ milestone after a session or
compaction boundary — requires the resuming operator or agent to re-derive all
of this by re-reading git log, scanning the `specs/` directory, and re-tracing
the Development Workflow. On a long milestone (e.g., nine workflow steps, multiple
agents, a compaction boundary mid-session), that re-derivation costs meaningful
context budget and introduces re-derivation error risk: the wrong workflow step is
assumed to be next, or a completed action is repeated.

The existing `save-session` / `resume-session` commands (stored globally in
the user-home ECC session store, outside the repository tree) address general
work-session continuity but are project-agnostic and user-scoped. They are not
per-milestone and do not survive a compaction event during the same session —
their durability is the user-home global store (not the repository). A compacted
session that resumes within the same repository has no way to access the previous
session's user-home session file without an explicit `/resume-session` invocation
by the operator.

There is no durable, per-milestone mechanism inside the repository that answers
the question: "This milestone is ◐; what is its current in-flight state?"

## Goals

- Provide a durable, per-milestone record that captures in-flight state for any
  `◐ in-progress` milestone, so the next session or agent can answer: "which
  workflow step is current, what has been completed, and what is the next concrete
  action" — without re-reading the entire git log or re-scanning the spec tree.
- The record must survive compaction (Invariant 2 constraint — see Risks).
- The mechanism must not put progress state into the Roadmap table (ADR-014
  invariant: the Roadmap is index-only — ☐/◐/☑/✗ only).
- The mechanism must not require mandatory ceremony when a milestone ships in a
  single session (zero-ceremony-when-not-needed posture).
- The mechanism must be consistent with or extend the existing `save-session` /
  `resume-session` model rather than introducing a parallel convention.

## Non-goals

- A full task-tracking system, kanban board, or milestone management UI.
- Duplicating Roadmap status (☐/◐/☑/✗) — the Roadmap row remains the single
  implementation-state record; the progress record supplements it.
- Cross-repository state (the persistence mechanism is per-repo, not global).
- Automatic compaction triggering — compaction is a harness concern, not a
  template concern.
- Recording progress for milestones that complete in a single uninterrupted
  session (the mechanism is opt-in or zero-friction-to-skip when not needed).
- Retroactively populating progress records for already-completed milestones
  (☑ rows); this milestone targets active ◐ rows only.
- Defining the storage format, file location, or schema — those are architect
  decisions (ADR-016, deferred). <!-- ref-allow: ADR-016 is the deferred architecture decision for this milestone, to be authored when implementation begins -->

## Target users

| Persona | Description | Primary Need |
|---------|-------------|--------------|
| Template adopter (returning operator) | Developer who paused a multi-step milestone and is starting a new session | Resume the milestone at the correct workflow step without re-deriving state from git |
| Agent (orchestrator) | The orchestrator agent opening a ◐ milestone for the Analyze step | Locate the next concrete action without scanning git log or running file discovery |
| Agent (implementer/architect) | Any agent mid-milestone that crosses a compaction boundary | Continue from the known state without losing progress made before compaction |

## User stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| Returning operator | Open a new session for a ◐ milestone and immediately know the current workflow step and next action | I do not spend context re-deriving what was done in previous sessions |
| Orchestrator agent | Read a structured, per-milestone progress record at the start of the Analyze step | I follow the correct Development Workflow step without re-reading the full git log |
| Any agent crossing a compaction boundary | Write a minimal progress update before the boundary | The resuming agent or next session starts from the last known state, not from scratch |
| Template maintainer | Ship a mechanism that adds zero ceremony for single-session milestones | Adopters are not burdened with a mandatory ritual when it is not needed |

### US-001: Resumable in-flight milestone

- **As a** returning operator (or orchestrator agent)
- **I want to** recover the in-flight state of any ◐ milestone at the start of a new session
- **So that** work resumes at the correct workflow step with zero re-derivation from git

**Acceptance criteria:**

- Given a milestone is `◐ in-progress` and has persisted progress, when a new session starts, then the operator can identify (a) which Development Workflow step is current, (b) which artifacts (Spec, ADR) already exist on disk, and (c) the next concrete action — without running `git log` or searching the file tree.
- Given persisted progress exists for a milestone, when the progress is read, then it references the Roadmap row number so the reader can immediately cross-reference the Roadmap table.
- Given the progress record is read in a new session, when the milestone's Spec has already been authored (file exists on disk), then the progress record confirms that fact explicitly (the reader does not need to `ls specs/` to verify).

**Priority:** Must-have

### US-002: Compaction-durable persistence

- **As an** agent crossing a compaction boundary mid-milestone
- **I want to** write a progress snapshot that survives context compaction
- **So that** the resuming context (or next session) does not start from a blank slate

**Acceptance criteria:**

- Given a progress snapshot is written during a session, when context compaction occurs, then the snapshot is readable by the next resuming context without any operator action.
- Given the persistence storage location is a file tracked by git (or a committed/gitignored file within the repository), when compaction occurs, then the file is not discarded (satisfies Invariant 2: root content survives compaction; progress files in the repo survive because compaction only affects Claude's context, not the file system).
- Given a milestone is `◐` but has no persisted progress record, when a session starts, then the system indicates clearly that no progress record exists (the operator knows to re-derive from git rather than expecting one).

**Priority:** Must-have

### US-003: Zero ceremony for single-session milestones

- **As a** template maintainer
- **I want** the persistence mechanism to impose no mandatory ritual when a milestone ships in one session
- **So that** adopters are not burdened with progress-tracking ceremony for simple milestones

**Acceptance criteria:**

- Given a milestone is completed in a single uninterrupted session (status moves from ☐ to ☑ without a session boundary), when the milestone is done, then no progress record is required and no CI check fails for the absence of one.
- Given a milestone transitions from `◐ in-progress` to `☑ done`, when the transition occurs, then any existing progress record for that milestone can be archived or deleted without affecting the Roadmap or any other artifact.

**Priority:** Must-have

### US-004: Relation to existing save-session / resume-session

- **As an** operator
- **I want** the milestone progress mechanism to complement (not replace) the global `/save-session` command
- **So that** I have one mental model for session continuity rather than two parallel conventions

**Acceptance criteria:**

- Given both a global session file (in the user-home ECC session store, outside the repository) and a per-milestone progress record exist, when a new session starts, then the operator can use either independently; the two mechanisms are composable and do not conflict.
- Given the milestone progress mechanism is designed, when the architect authors ADR-016, then the design document references the existing `save-session` / `resume-session` convention and explicitly states whether the milestone record extends, wraps, or runs alongside it. <!-- ref-allow: ADR-016 is the deferred architecture decision for this milestone, to be authored when implementation begins -->

**Priority:** Should-have

## Key interactions

1. `orchestrator` reads the per-milestone progress record (if it exists) immediately after reading the Roadmap row during the Analyze step — before dispatching any sub-agent. If no record exists and the milestone is `◐`, the orchestrator falls back to git-log re-derivation.
2. `product-manager` or `implementer` writes an initial progress record when a milestone transitions to `◐ in-progress` — or at any compaction boundary during work on the milestone.
3. `implementer` updates the progress record at each completed Development Workflow step (plan, TDD, code-review, etc.).
4. When a milestone transitions to `☑ done`, the progress record is retired (archived or deleted) — it is no longer authoritative and should not mislead future readers.
5. The existing `/save-session` command continues to be used at the user's discretion for general session continuity; the milestone progress record is narrower in scope and lives within the repository.

## Metrics

| Metric | Current | Target | How to measure |
|--------|---------|--------|----------------|
| Time to re-orient on a ◐ milestone after a session break | Unmeasured; estimated 5-15 min of re-derivation for a 9-step milestone | Re-orientation reads the progress record in < 60 seconds | Developer report; observable in session transcript |
| Context tokens spent on re-derivation per resumed ◐ milestone | Unmeasured | Near-zero (record is a direct read, not a git-log scan) | Approximate from session logs |

## Risks and open questions

### Risk R-01: Invariant 2 — compaction durability constraint

**Description.** Invariant 2 (`.claude/skills/claude-md-authoring/invariants.md §2`) states:
"Root content survives compaction; subdirectory and path-scoped content do not."
Progress records stored inside the repository on the file system are not affected
by compaction (compaction only discards Claude's in-context working memory, not
files on disk). However, a progress record stored only in Claude's context (as an
in-memory artifact or as a subdirectory `CLAUDE.md` entry that compaction summarizes
away) would be lost.

**Constraint handed to architect.** The storage design for ADR-016 must satisfy: <!-- ref-allow: ADR-016 is the deferred architecture decision for this milestone, to be authored when implementation begins -->
the progress record is written to a file on disk (not kept in context only), and
the file is accessible to the resuming context without requiring a file-system
search (i.e., the path is deterministic and discoverable without scanning).
Whether the file is committed to git, gitignored-but-stable, or co-located with
the Spec is an architect decision — but the durability constraint is: on-disk and
deterministic-path.

### Risk R-02: ADR-014 index-only constraint

**Description.** ADR-014's Decision rule states: "The table is an index only.
Acceptance criteria and rationale are never duplicated into it." The ☐/◐/☑/✗
glyph is the only implementation state the Roadmap carries. Any per-milestone
progress detail (workflow step, completed actions, next step) must live outside
the Roadmap table. This Spec deliberately does not prescribe a location — that
is the architect's decision — but it must not be the Roadmap row itself, a
Roadmap column, or any addition to the Roadmap table format.

### Risk R-03: Record drift and staleness

**Description.** A progress record written at step 3 of 9 and then not updated
before compaction is stale but less stale than zero information. A record that
is never updated after the milestone completes (☑) misleads future operators.

**Mitigation constraint.** The architect design must address: how a stale record
is recognized (e.g., a `last_updated` timestamp or a "current step" field that
can be compared against the Roadmap status), and what happens to the record when
the milestone is marked ☑.

### Risk R-04: Ceremony cost for low-complexity milestones

**Description.** Several Roadmap rows (#16–#21) are S-effort prose edits. A
mandatory progress record for every ◐ milestone imposes ceremony that is
disproportionate to the work.

**Open question for architect.** Should the progress record be: (a) always
created when a milestone moves to ◐, (b) created only when a session boundary
occurs during a ◐ milestone, or (c) triggered explicitly by the operator via a
command (like `/save-session`)? The product-level preference is (b) — created
on need, not on status transition — but the architect may find (a) simpler to
implement and enforce. This is an explicit product-level open question deferred
to ADR-016. <!-- ref-allow: ADR-016 is the deferred architecture decision for this milestone, to be authored when implementation begins -->

### Risk R-05: Two conventions, one mental model

**Description.** The global `save-session` / `resume-session` commands already
exist and are familiar to operators. A new per-milestone mechanism risks
confusion ("should I use `/save-session` or the milestone progress record?").

**Constraint.** The architect design must address the composability question:
the two mechanisms must have clearly non-overlapping scopes and the milestone
progress record must not require the operator to abandon or replace the global
session command. This Spec's US-004 acceptance criteria formalize this
requirement.

## Out of scope

- Designing the progress record format, schema, or file location (ADR-016). <!-- ref-allow: ADR-016 is the deferred architecture decision for this milestone, to be authored when implementation begins -->
- Any CI check that validates progress record presence or freshness.
- Cross-repository or cross-project state.
- Automatic compaction detection or triggering.
- A UI or dashboard for milestone progress.
- Progress records for completed (☑) or dropped (✗) milestones.
- Retroactive population of records for past milestones.

## References

- ADR-014 (Roadmap index as single entry point) — the index-only constraint that
  prohibits progress detail in the Roadmap table; the ☐/◐/☑/✗ status model
- `.claude/skills/claude-md-authoring/invariants.md §2` — Invariant 2 (root
  content survives compaction; subdirectory and path-scoped content do not) —
  the compaction-durability constraint that governs where the progress record
  can live
- `/save-session` ECC command (user-home skill, outside the repository) — the
  existing global session-save mechanism; #03 must complement, not replace, this
  convention
- `/resume-session` ECC command (user-home skill, outside the repository) — the
  corresponding global session-resume command; the milestone progress record is
  narrower in scope (per-milestone, repo-local) and composable with this global
  command
- `.claude/CLAUDE.md §## Development Workflow` — the nine-step workflow whose
  step-completion state this milestone exists to persist
- ADR-016 — the forthcoming architect decision for storage design (to be authored <!-- ref-allow: ADR-016 is the deferred architecture decision for this milestone, to be authored when implementation begins -->
  when this milestone moves to implementation)
- Roadmap row: #03
