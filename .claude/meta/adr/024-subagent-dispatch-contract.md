# ADR-024: Subagent Dispatch Contract — 5-slot Prompt Template + Delegate-and-Stop Rule

## Status

Accepted — 2026-05-20

## Context

The user observed across multiple sessions that the parent agent
(`orchestrator`, or `main Claude` acting as the session driver) often
**absorbs** a task that has just been delegated to a subagent — that is,
after writing a long, detailed prompt to a subagent like `Explore` or a
specialist agent, the parent then proceeds to read files, run commands,
and effectively solve the task itself instead of waiting for the
subagent's return. The result is duplicated work, polluted parent
context, and silent erosion of the agent-team division of labor that
ADR-014 (Roadmap), ADR-008/010 (verification layer), and ADR-012 (code
review dispatcher) all assume holds.

Two failure-driving patterns appear in transcripts:

1. **Over-large CONTEXT slots.** The parent packs the prompt with so
   much background — including its own preliminary analysis,
   speculative hypotheses, and "while you're there" extensions — that
   the act of writing the prompt becomes the act of solving the
   problem. The subagent's role collapses to rubber-stamping; the
   parent inevitably finds something the subagent missed and finishes
   the work itself.
2. **No physical guardrail between dispatch and return.** Once the
   `Agent` tool call is written, nothing prevents the parent from
   calling `Read`, `Bash`, `Edit`, `WebFetch`, or a Skill in the same
   turn or the next. The parent treats the subagent as "an extra pair
   of hands" rather than a delegation boundary, and races ahead.

No current ADR or Skill addresses dispatch prompt shape or the
parent's tool-call behavior between dispatch and return. The
verification layer (ADR-008/010) governs *which* Critic gets routed,
not *how* the dispatch prompt is written. The orchestrator row-guard
G1–G3 (Roadmap #08 amendment to ADR-014) governs whether dispatch
proceeds at all, not how it is shaped. The Roadmap protocol
(ADR-014) governs which agent owns which row-level write, not how
prompts get written.

### Forces in tension

- **Information density vs. absorption risk.** Subagents need enough
  context to act without round-trips, but more context invites the
  parent to over-think and over-write.
- **Discipline vs. enforceability.** A prompt-length cap is easy to
  state and impossible to enforce mechanically — the only enforcement
  surface is what the parent agent can and cannot do at runtime.
- **Generality vs. opt-in.** The rule must apply to every parent →
  subagent dispatch, including verification-layer Generator/Critic
  routing — but it must not be so intrusive that ad-hoc delegations
  become painful.

### Triad classification (per ADR-018 Alternative-B discriminator)

- **New contract boundary? YES.** Establishes a parent ↔ subagent
  contract that no existing ADR covers.
- **New keying / mechanism? YES.** The 5-slot prompt template and the
  delegate-and-stop tool restriction are both new mechanisms.
- **New structural artifact? YES.** A new reference document
  (`.claude/meta/references/dispatch-contract.md`) plus a new CLAUDE.md
  section that compaction-durably documents the rule.

Triad total: **3/3** → warrants a new ADR (not an amendment to an
existing one). This is the same discriminator ADR-022 used to justify
its own creation.

## Decision

Adopt a two-layer subagent dispatch contract that applies to every
`Agent` tool call made by any agent (orchestrator, main Claude, or any
specialist that dispatches a subagent).

### Layer 1 — 5-slot prompt template

Every dispatch prompt fits this fixed structure:

```
ROLE:        [agent name + posture, 1 line]
CONTEXT:     [≤3 bullets — decision this informs, Roadmap row if any,
              constraints the parent already established]
TASK:        [imperative verb + object, 1 sentence]
CONSTRAINTS: [≤5 bullets — what to skip, scope boundary, stop
              condition, files the subagent should NOT touch]
OUTPUT:      [exact shape parent will consume — format, length cap,
              expected sections]
```

The slot bounds (≤3 CONTEXT bullets, ≤5 CONSTRAINTS bullets) are the
absorption guards: they force the parent to categorize every line
before writing it. A word-count cap was considered and rejected — it
is easy to game by compressing whitespace and does not target the
absorption failure mode.

### Layer 2 — delegate-and-stop rule

After writing an `Agent` dispatch in a turn, the parent agent may
only call the following tools until the subagent returns:

- `Agent` (to dispatch additional independent subagents in parallel)
- `AskUserQuestion` (to ask the human a clarifying question)
- `ScheduleWakeup` (in dynamic-loop mode)

Forbidden between dispatch and return:

- `Read`, `Bash`, `Edit`, `Write`, `Grep`, `Glob`
- `WebFetch`, `WebSearch`
- `Skill` invocations
- Any MCP tool call

This is the **forcing function**. The absorption failure mode is
physically blocked: there is no tool call the parent can make that
would advance the delegated work between dispatch and return.

### Placement and inheritance

The contract is declared as `## Subagent dispatch contract` in
`.claude/CLAUDE.md` (compaction-durable per Invariant 2) and detailed
in `.claude/meta/references/dispatch-contract.md` (canonical reference
with worked examples). It applies to ALL parent → subagent dispatches,
including verification-layer Generator/Critic routing — no opt-out.

Forks inherit the contract via CLAUDE.md. Forks may amend the SAFE
tool list in Layer 2 (e.g. to permit a specific MCP tool they use for
out-of-band monitoring) but may not weaken the structural prompt
template; weakening Layer 1 defeats the absorption guard.

## Consequences

### Positive

- The user-observed absorption failure mode is physically blocked.
  Layer 2 leaves the parent no tool path that advances the delegated
  work between dispatch and return.
- The 5-slot template makes dispatch prompts skimmable in
  transcripts. A reviewer can spot a defective dispatch in seconds
  (over-large CONTEXT slot, missing OUTPUT shape, confirmation prompt
  pattern) instead of reading 600-word prose blocks.
- Parallel dispatch ergonomics improve: because Layer 2 permits
  additional `Agent` calls during the wait, the parent is incentivized
  to fan out multiple subagents in one message instead of serializing
  them.
- The rule applies uniformly to verification-layer Generator → Critic
  routing, eliminating the "this dispatch is different because it's a
  verification call" carve-out that would have invited absorption.

### Negative

- A genuinely-needed Read or Bash call between dispatch and return is
  blocked. Workaround: dispatch a second `Agent` with the read/bash
  task in parallel; this is usually cleaner anyway.
- Some prompts feel cramped under the slot bounds, especially when
  the parent has legitimate complex context to share. Mitigation: the
  reference doc shows a 614→174-word worked example demonstrating that
  the lost 440 words were typically the parent solving the problem in
  the prompt.
- The contract adds a sentence-shape obligation to every dispatch,
  raising the floor of dispatch effort. Mitigation: after a few
  dispatches the template becomes automatic; the floor lift is one-time.

### Neutral

- The verification-layer protocols (ADR-008/010) get a one-line note
  pointing at this ADR for the dispatch-shape rule; the verification
  protocols are otherwise unmodified.
- The orchestrator agent file (`.claude/agents/orchestrator.md`)
  receives an inline summary of both layers under its Dispatch
  subsection.
- The contract is not enforced by CI. Compliance is observable in
  transcripts (the user can grep for absorption patterns) but no
  static check exists. ADR-022's "machine-verifiable" criterion does
  not apply because the absorption failure mode is behavioural, not
  artifact-shaped.

### Risks

- **Forks weaken Layer 2 piecemeal.** A fork that needs an MCP tool
  for monitoring might add it to the SAFE list, then add another, and
  another, eventually re-opening the absorption hole. Mitigation: the
  reference doc explicitly states that weakening Layer 1 (the slot
  template) is forbidden but Layer 2 (the tool list) is fork-adjustable
  — drawing the boundary at the structural prompt rule, which is the
  primary absorption guard. Layer 2 is the secondary guard.
- **Parent re-absorbs across turns.** The forcing function only covers
  the dispatch turn; nothing prevents the parent from doing work in a
  later turn that the subagent already addressed. Mitigation: the
  pre-dispatch checklist's question 4 ("Could I delete my CONTEXT
  bullets and still have the subagent succeed?") is the cross-turn
  defense.

## Alternatives considered

| Alternative | Pros | Cons | Why not chosen |
|---|---|---|---|
| **A: 5-slot template + delegate-and-stop (selected)** | Two-layer defense (structural + behavioural); applies uniformly; reference doc carries the rationale; forks inherit cleanly | Adds dispatch-shape obligation; some legitimate Read between dispatch and return needs a workaround | Selected. The two layers cover the two failure-driving patterns the user observed |
| **B: Word-count cap on subagent prompts** | Easy to state | Easy to game by compressing whitespace; does not target absorption directly; produces false positives on legitimate-complex dispatches | Word counts do not measure the failure mode (over-large CONTEXT slot is the failure; total length is a noisy proxy) |
| **C: Self-audit prompt at start of every parent turn** | No tool restrictions; less intrusive between dispatch and return | Adds cognitive overhead to every turn for a problem that only happens at dispatch time; relies on the parent noticing the violation it just committed | Targets the wrong time window; the absorption pattern happens at dispatch, not at turn start |
| **D: Static CI lint of dispatch prompts in transcripts** | Mechanically enforceable | Requires transcript persistence and a CI surface for prompts; absorption is behavioural and won't always show up as a prompt defect; transcripts are not currently a CI artifact | Out of scope for current infrastructure; the reference doc's "first-week measurable signals" are the manual equivalent |
| **E: Skill rather than ADR + reference doc** | Skill body could include runtime examples | A Skill is opt-in via `.claude/skills/`; the dispatch contract needs to apply universally, not be selected per-task | The rule is invariant (not task-specific) — CLAUDE.md + reference doc is the correct placement |

## References

- `.claude/CLAUDE.md` § Subagent dispatch contract — the
  compaction-durable summary that survives session boundaries.
- `.claude/meta/references/dispatch-contract.md` — canonical reference
  with the 614→174-word worked example and the pre-dispatch checklist.
- `.claude/meta/adr/008-research-verification-layer.md` — the research
  domain Generator → Critic routing this contract now also shapes.
- `.claude/meta/adr/010-verification-layer-generalization.md` —
  generalization of (ADR-008) to implementation and design domains;
  same dispatch-shape rule now applies.
- `.claude/meta/adr/014-roadmap-index-single-entry-point.md` — the
  Roadmap entry point and its orchestrator row-guard G1–G3, which fire
  before this contract.
- `.claude/agents/orchestrator.md` — receives an inline summary of
  both layers under its Dispatch subsection.
- Roadmap row: #22
