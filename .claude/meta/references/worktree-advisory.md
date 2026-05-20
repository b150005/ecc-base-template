# Worktree advisory protocol — reference

This document is the canonical reference for the worktree advisory
protocol summarized in `.claude/CLAUDE.md` § Worktree advisory
protocol. The design rationale lives in
`.claude/meta/adr/025-worktree-advisory-protocol.md`. Roadmap row #22.

The protocol governs three things:

1. The **suitability test** the orchestrator runs in Analyze to decide
   whether a multi-step task should use parallel worktrees.
2. The **advisory output** the orchestrator emits to the human before
   dispatching, so the human can redirect before any subagent fires.
3. The **per-worktree dispatch format** for multi-worktree mode,
   including the rule that one designated worktree exclusively owns
   shared mutable files.

The protocol is **advisory**, not enforced by CI. The orchestrator
implements it as a runtime obligation; deviations are visible in the
transcript and the human can intervene.

---

## 1. Suitability rubric (6 questions)

The orchestrator answers each question in the Analyze step:

| # | Question | Yes means | No means |
|---|----------|-----------|----------|
| 1 | **File-disjoint?** | Subtasks touch disjoint file sets (no common file) | At least one file is touched by ≥ 2 subtasks |
| 2 | **Roadmap-disjoint?** | Subtasks advance different Roadmap rows | Two subtasks share a Roadmap row (status-glyph contention) |
| 3 | **State-disjoint?** | No shared mutable state (CHANGELOG, lockfiles, generated artifacts, progress files) | Some shared state is mutated by multiple subtasks |
| 4 | **Mergeable?** | Outputs combine trivially (separate files / non-overlapping sections) | Outputs need integration work to combine |
| 5 | **Reversible?** | If one slice is rejected at review, the others remain useful | Rejecting any slice invalidates the others |
| 6 | **Net-faster?** | Parallelism wins wall-clock even after the human's serial review costs | Serial dispatch is faster end-to-end (typically true for ≤ 3 file-changes per slice) |

### Decision rule

- **Yes on all 6** → recommend `multi-worktree-N` (N = number of
  independent slices).
- **No on any of 1–3** → recommend `single-worktree` (forced — shared
  state would produce merge conflicts or data races).
- **No on any of 4–6** → recommend `single-worktree` (parallelism
  does not pay; sequential dispatch is faster or safer).

The rubric is biased toward `single-worktree`. Multi-worktree
parallelism is a sharp tool with significant coordination overhead;
the orchestrator only recommends it when the wins are unambiguous.

---

## 2. Advisory output

Before the implementation plan block, the orchestrator emits:

```
## Worktree Recommendation

Mode: [single-worktree | multi-worktree-N]
Reason: [≤ 2 sentences citing the failed rubric question if any,
         or naming why parallelism wins if multi-worktree]
If you prefer otherwise, say so before I dispatch.
```

### Examples

```
## Worktree Recommendation

Mode: single-worktree
Reason: Q3 fails — both subtasks update specs/22-progress.md
        (shared state).
If you prefer otherwise, say so before I dispatch.
```

```
## Worktree Recommendation

Mode: multi-worktree-3
Reason: Three independent agent files (architect.md /
        product-manager.md / orchestrator.md) need parallel
        Skill-invocation edits; outputs combine cleanly because each
        file is owned by exactly one slice.
If you prefer otherwise, say so before I dispatch.
```

The advisory always invites the human to override. The orchestrator
does not silently choose parallelism without surfacing the decision.

---

## 3. Per-worktree dispatch format (multi-worktree mode)

When the orchestrator recommends `multi-worktree-N`, it generates a
**shared header** plus N distinct **slice blocks**. The human pastes
the shared header into each worktree's first prompt, then the
matching slice block into the same worktree.

### Shared header

```
SHARED HEADER (paste into every worktree):

Feature: [name]
Roadmap row: #[NN]
Branch base: [SHA or branch-name]
No-write zones: .claude/CLAUDE.md, .claude/ROADMAP.md, CHANGELOG.md,
                specs/NN-progress.md, *.lock, *.lockb
                (these are owned by the Roadmap-owner worktree below)
Hand-off contract: each worktree opens a PR titled
                   "feature/[name]/[slice-id]"
```

### Per-worktree slice block

```
SLICE: worktree-A

Owned file subtree: [glob — e.g. .claude/agents/architect.md]
Success criterion: [one sentence — what "done" looks like]
Hand-off artifact: PR titled "feature/[name]/A"
```

```
SLICE: worktree-B

Owned file subtree: [glob — e.g. .claude/agents/product-manager.md]
Success criterion: [one sentence]
Hand-off artifact: PR titled "feature/[name]/B"
```

… and so on for each slice. The slice IDs (A / B / C / …) are
short, mnemonic-free letters; the human pastes the header + slice
into each worktree's prompt.

### Roadmap-owner worktree

When N worktrees are used, exactly one is designated the
**Roadmap-owner worktree** in the shared header. The Roadmap-owner
is the **only** worktree authorized to write to:

- `.claude/CLAUDE.md`
- `.claude/ROADMAP.md`
- `CHANGELOG.md`
- `specs/NN-progress.md`
- lockfiles (`package-lock.json`, `bun.lock`, `Cargo.lock`,
  `go.sum`, `Pipfile.lock`, etc.)

Non-owner worktrees produce slice outputs and surface "hand-off
requests" — e.g. "Roadmap row #NN should flip to ☑" — but never
write the shared files themselves. The Roadmap-owner reconciles
all hand-offs into single coherent updates to the shared files when
the slices merge.

This rule is the structural defense against the worktree-contention
failure mode the user identified: glyph flips and CHANGELOG edits
happening in parallel across worktrees would cause silent merge
conflicts or last-write-wins data loss.

---

## SAFE / UNSAFE write zones (full list)

### SAFE for any worktree to write

Each worktree gets its own copy of these via git; ordinary code-review
and merge handles divergence.

- Source code under the slice's assigned glob
- New files under `specs/NN-slug.md` if `NN` is the worktree's
  owned row (e.g. worktree-A owns row #22, may create
  `specs/22-slug.md`)
- New ADRs under `.claude/meta/adr/NNN-slug.md` with a globally
  unique number (orchestrator pre-allocates the numbers in the shared
  header to avoid collision)
- Tests under `tests/<slice>/` (per-slice test directories)
- Per-slice generated artifacts under explicitly-owned paths

### UNSAFE for non-owner worktrees

The Roadmap-owner worktree exclusively writes:

- `.claude/CLAUDE.md`
- `.claude/ROADMAP.md`
- `CHANGELOG.md`
- `specs/NN-progress.md` (ADR-016 progress files)
- Any file under `.github/workflows/` that another worktree's CI run
  depends on
- Lockfiles (above list)
- `README.md`, `README.ja.md`
- Files explicitly named in any out-of-band shared-state contract

---

## Interaction with existing protocols

**Orchestrator row-guard G1–G3 (Roadmap #08 / ADR-014 amendment).**
Worktree advisory fires **between** the row-guard and the dispatch
contract: G1–G3 → worktree advisory → dispatch contract per `Agent`
call. The row-guard determines *whether* dispatch can proceed; the
worktree advisory determines *how* (single vs. multi); the dispatch
contract determines *how each prompt is shaped*.

**Quality-gate loop re-entry (Roadmap #21 / ADR-014 amendment).** The
re-entry loop generally fails Q3 (the progress file is mutated by
the re-entered implementer and the existing reviewer) and Q5
(rejecting a fix-slice invalidates earlier work). The orchestrator
recommends `single-worktree` for quality-gate re-entry by default.

**Verification-layer parallel implementations
(`adversarial-implementer`, ADR-010).** This is a single-agent
worktree pattern: one Critic runs an alternate implementation in a
scratch worktree to produce a behavioural delta. The multi-worktree
advisory does **not** apply — there is no human-coordinated
parallelism to advise on. The dispatch contract still applies to the
Critic dispatch.

---

## First-week measurable signals

- `## Worktree Recommendation` block appears before **every**
  multi-step plan.
- The human accepts the orchestrator's default ≥ 80% of sessions
  (signal that the rubric matches user intuition).
- Zero merge conflicts on `.claude/CLAUDE.md`, `.claude/ROADMAP.md`,
  `CHANGELOG.md`, `specs/*-progress.md` across the week, even when
  multi-worktree was used.
- Roadmap-owner worktree is named explicitly in every
  `multi-worktree-N` recommendation.
