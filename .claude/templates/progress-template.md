# Milestone Progress Record Template

## How to use this template

1. This file records the **in-flight state of one `◐ in-progress`
   Roadmap milestone** so a resuming session or agent recovers it with
   one deterministic read. It is created/updated **only when a session
   or compaction boundary occurs while the milestone is `◐`** — never
   on the `☐ → ◐` transition, never by an operator command. A milestone
   that ships `☐ → ☑` in one uninterrupted session never creates one
   (zero ceremony when not needed). See
   `.claude/meta/adr/016-cross-session-progress-persistence.md` for the
   full rationale.
2. Copy this file to `specs/NN-progress.md`, where `NN` is the **stable,
   never-reused Roadmap row number** of the milestone (the same key
   ADR-014's reservation rule uses for `specs/NN-slug.md`). Milestone
   #03's record is `specs/03-progress.md`. The path is a pure function
   of the row number, so a resumer reads the Roadmap row, then opens
   `specs/NN-progress.md` directly — no `ls`, no `git log`, no scan.
3. Fill the YAML front-matter and the three body sections. **Use the
   front-matter block exactly as shown below — start the file with
   `---` on its own line, paste the keys, end with `---` on its own
   line. Do not wrap it in a code fence.** The example below is shown
   inside a code fence only for display; your actual file must contain
   the bare YAML.
4. Delete this "How to use this template" block before committing the
   real `specs/NN-progress.md`.
5. The record is **git-tracked**, not gitignored — the per-milestone
   state is project knowledge shareable across operators of the same
   fork, and recoverable via git history if deleted prematurely.
6. When the milestone transitions `◐ → ☑` (or `◐ → ✗`), the agent that
   flips the Roadmap glyph **deletes `specs/NN-progress.md` in the same
   change** that records completion. A `☑`/`✗` row with a surviving
   progress record is detectably stale (the glyph-mirror backstop).

This record is **English-only** by convention (same audience as the
upstream-workaround registry — engineers and agents resuming in-flight
work; no translation drift on fast-moving transient state).

Composes with — does not replace — the global `/save-session` ↔
`/resume-session` commands (user-home `~/.claude/session-data/`,
project-agnostic, per-session). Scope partition: `/save-session`
answers "what was I doing in this session"; this record answers "what
is the in-flight state of milestone #NN". Either is usable independently.

---

### Front-matter (paste literally as the start of your file)

```yaml
---
roadmap_row: 3                       # integer; the stable Roadmap row number
milestone: "Cross-session milestone progress persistence"   # the row's one-liner
status_glyph: "◐"                    # MUST mirror the Roadmap glyph; a mismatch ⇒ this record is stale
workflow_step: 4                     # integer 1–9 per ## Development Workflow; the current step
last_updated: 2026-05-16             # YYYY-MM-DD; date this record was last written
head_sha: 6caa258                    # git HEAD short SHA at write time (staleness pin)
spec_exists: true                    # true once specs/NN-slug.md exists on disk (US-001 (c))
adr_links: [".claude/meta/adr/016-cross-session-progress-persistence.md"]   # [] if no ADR
---
```

Field notes:

- `workflow_step` is the integer of the `## Development Workflow` step
  (1 Issue Analysis, 2 Product Planning, 3 Research & Reuse,
  4 Architecture, 5 Implementation, 6 Quality Gate, 7 Documentation,
  8 Release, 9 Commit). A resumer maps directly onto the known
  nine-step pipeline without re-tracing it.
- `status_glyph` MUST equal the Roadmap row's glyph. The Roadmap glyph
  is authoritative (ADR-014); this record never overrides it. If they
  disagree, the record is stale by definition.
- `head_sha` is the staleness pin. A resumer compares it to current
  `HEAD`: equal ⇒ maximally fresh; diverged ⇒ read this record as a
  *floor* on progress and reconcile the bounded delta with
  `git log <head_sha>..HEAD` — not a full-history re-derivation.
- `last_updated` is a coarse human-facing recency signal, secondary to
  the SHA pin.
- There is intentionally **no `started` field** — the `◐` glyph and the
  Roadmap already carry "work has begun"; duplicating it here would be
  index content, which this record is not.

## Done

The completed `## Development Workflow` steps, one bullet each, naming
the artifact produced. Keep it scannable — this is a handle, not prose.

- Step 2 (Product Planning) — `specs/NN-slug.md` authored
- Step 4 (Architecture) — ADR-0NN written and Accepted

## Next concrete action

The single next action a resumer takes. One sentence. Not a plan — the
*next* step only (the pipeline carries the rest).

[e.g. "Step 5: implement the detector per ADR-0NN Decision, TDD."]

## Notes / why work stopped

Free text. Why the boundary was hit, anything a resumer needs that the
Done/Next sections do not carry.

[e.g. "Compaction boundary at step 4; ADR Accepted, implementation deferred."]
