# Subagent dispatch contract — reference

This document is the canonical reference for the subagent dispatch
contract summarized in `.claude/CLAUDE.md` § Subagent dispatch
contract. The design rationale lives in
`.claude/meta/adr/024-subagent-dispatch-contract.md`. Roadmap row #22.

The contract has two layers:

1. A **structural prompt template** (5 slots) every parent→subagent
   dispatch must fit.
2. A **delegate-and-stop rule** that physically prevents the parent
   from re-absorbing the delegated task between the `Agent` dispatch
   and the subagent's return.

Both layers apply to every `Agent` call made by `orchestrator`, by
`main Claude` when it acts as the session driver, and by any other
agent that dispatches a subagent (e.g. verification-layer Generator
delegating to Critic, code-reviewer delegating to ecosystem reviewer).

---

## Layer 1 — the 5-slot prompt template

Every dispatch prompt fits this fixed structure:

```
ROLE:        [agent name + posture, 1 line]
CONTEXT:     [≤3 bullets — decision this informs, Roadmap row if any,
              constraints the parent already established]
TASK:        [imperative verb + object, 1 sentence]
CONSTRAINTS: [≤5 bullets — what to skip, scope boundary, stop
              condition, files the subagent should NOT touch]
OUTPUT:      [exact shape the parent will consume — format, length cap,
              what columns/sections the parent expects]
```

### Why structural (not word count)

A word-count cap is easy to game by compressing whitespace; the failure
mode that the user observed (parent self-execution) is caused by
**over-large CONTEXT slots**, not by total token count per se. The slot
boundaries force the parent to categorize every line before writing it,
which catches the "I'm just thinking out loud in the prompt" failure
mode at the moment it happens.

Soft advisory: if any single slot exceeds ~ 8 lines, the parent is
probably re-solving the task in the act of writing the prompt — re-read
the CONTEXT bullets and decide whether they should be deleted before
continuing.

### Information-density rules

**MUST be in the prompt** (otherwise the subagent fails or context-switches back):

- The decision the subagent's output will inform (in CONTEXT)
- The specific files / symbols / paths the subagent should examine
  first (in TASK or CONSTRAINTS)
- The output shape the parent will consume — including a max length —
  (in OUTPUT)
- The stop condition: when the subagent should return even if more
  research seems possible (in CONSTRAINTS)

**MAY be in the prompt:**

- One short code excerpt if it disambiguates the task
- A pointer to a Roadmap row, ADR, or Spec (link, not contents)
- Known prior findings if they materially constrain the subagent's
  search (e.g. "we already ruled out X")

**MUST NOT be in the prompt:**

- The parent's own analysis or conclusions — this is the absorption
  trap, the single highest-risk pattern
- Full file contents the subagent can read itself
- "Background" the subagent does not need to act on
- Confirmation prompts ("I think X, please confirm") — rewrite as open
  questions, because confirmation prompts strongly bias the subagent
  to agree

---

## Layer 2 — the delegate-and-stop rule

After writing an `Agent` dispatch (the tool call), the parent agent may
call **only** the following tools until the subagent returns:

- `Agent` (to dispatch additional independent subagents in parallel)
- `AskUserQuestion` (to ask the human a clarifying question)
- `ScheduleWakeup` (in dynamic-loop mode)

Forbidden between dispatch and return:

- `Read`, `Bash`, `Edit`, `Write`, `Grep`, `Glob`
- `WebFetch`, `WebSearch`
- `Skill` invocations
- Any MCP tool call

This is the **forcing function**. The user-observed failure mode —
parent agent absorbs the task and starts solving it itself instead of
waiting for the subagent — is physically blocked: there is no tool
call the parent can make that would advance the delegated work between
dispatch and return.

When the subagent returns, the parent is free to use any tool again.

### Why this rule over alternatives

The alternative considered was a self-audit prompt at the start of
every parent turn ("am I about to do work I should delegate?"). That
adds cognitive overhead to every turn for a problem that only happens
at dispatch time. Restricting the tool surface between dispatch and
return targets the failure window precisely without taxing the rest
of the turn.

---

## Pre-dispatch checklist

The parent agent mentally checks each item before writing the prompt:

1. Have I named the decision this informs?
2. Have I named the stop condition?
3. Am I asking the subagent to confirm what I already believe? (If
   yes, rewrite as an open query.)
4. Could I delete my CONTEXT bullets and still have the subagent
   succeed? (If yes, delete them.)

The checklist is the cheap version of the 5-slot template: if the
parent passes the checklist, the prompt almost always fits the
template naturally.

---

## Worked example: 614 → 174 words

### BEFORE (614 words, absorption-prone)

> Please use the Explore agent to look at our verification-layer skill.
> I've been thinking about this a lot and I believe the research domain
> protocol has a gap around tier-confirmation. Specifically, when
> docs-researcher declares T2 for an auth-related question, we have a
> guardrail in orchestrator.md that says "confirm before accepting."
> But I'm worried this isn't actually being followed because the
> guardrail is in the orchestrator file, not in the skill itself. I
> want you to read `.claude/skills/verification-layer/SKILL.md` and
> `.claude/skills/verification-layer/research/protocol.md` and
> `.claude/skills/verification-layer/research/checklist.md` and tell me
> whether the tier-confirmation logic lives in the skill or only in
> orchestrator.md. Also check if there's a CI check that enforces it.
> And while you're there, look at ADR-008 and ADR-021 to see what the
> original intent was. I'm thinking we might need to move the guardrail
> into the skill itself, but I want to verify the current state first.
> Please be thorough — read the entire skill, not just the protocol
> file, because there might be shared invariants I'm missing. Also, the
> checklist file is the authoritative allowlist of primary sources for
> the Critic, so confirm whether the tier-confirmation list ("auth",
> "authn", "authz", "crypto"...) appears there too. […continues for
> another 300 words of speculation about what the answer might be…]

The failure pattern: the parent has already analyzed the problem
("there's a gap"), already formed a hypothesis ("might need to move
the guardrail"), and is sketching the answer in the prompt itself.
The subagent's role collapses to "rubber-stamp the parent's
conclusion." The parent will read the subagent's response,
disagree with a detail, and end up doing the analysis itself.

### AFTER (174 words, contract-compliant)

```
ROLE:    docs-researcher (read-only verification scan)

CONTEXT:
- Decision: whether the tier-confirmation guardrail for auth-related
  research needs to move from orchestrator.md into the
  verification-layer Skill.
- Roadmap row #14 (auth→T2 mis-classification) is already done.

TASK:    Determine where the tier-confirmation logic currently lives
         (orchestrator.md, the Skill, both, neither) and whether any
         CI check enforces it.

CONSTRAINTS:
- Read only: `orchestrator.md`,
  `verification-layer/SKILL.md`, `research/protocol.md`,
  `research/checklist.md`, and grep for `tier-confirmation` across
  `.github/workflows/`.
- Do not propose the fix — just report current state.
- Stop after these 4 files + 1 grep.

OUTPUT:  4-row table: Location | Present? | Quote (≤ 1 line)
         | Authoritative?
         Plus 1 sentence on CI enforcement.
```

The AFTER prompt preserves every actionable element of the BEFORE. The
deleted 440 words were the parent solving the problem in the prompt
itself.

---

## First-week measurable signals

The contract is "working" when these are observable in transcripts:

- **Slot compliance ≥ 90%.** Every dispatch fits the 5-slot template;
  no slot exceeds ~8 lines.
- **Zero parent tool calls between Agent dispatch and Agent return**
  other than `Agent`, `AskUserQuestion`, `ScheduleWakeup`.
- **CONTEXT slot ≤ 3 bullets** in ≥ 90% of dispatches (the absorption
  guard).
- **No "please confirm" or "I think X" pattern** in dispatch prompts.

---

## Interaction with existing protocols

**Verification layer (ADR-008 / ADR-010).** Generator (e.g.
`docs-researcher`, `implementer`) and Critic (e.g. `research-critic`,
`adversarial-implementer`, `architecture-critic`) dispatches both
follow the 5-slot template. The Critic's "use a different tool
family" constraint (ADR-008) goes in CONSTRAINTS; the citation
allowlist reference goes in OUTPUT. No verification-layer rule changes
— this contract is additive on top of the existing dispatch logic.

**Orchestrator row-guard G1–G3 (Roadmap #08 / ADR-014 amendment).**
The row-guard fires before any dispatch decision. The dispatch
contract fires when the dispatch prompt is written. Ordering at
Analyze: G1–G3 → worktree advisory rubric → dispatch contract per
`Agent` call.

**Quality-gate loop re-entry (Roadmap #21 / ADR-014 amendment).** The
re-entry routes `implementer` again on CRITICAL/HIGH findings; the
re-entry prompt uses the 5-slot template just like the initial
dispatch.
