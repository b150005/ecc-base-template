# ADR-009: Plan-First & Learning-Aware Defaults

## Status

Accepted — 2026-05-07

## Context

`ecc-base-template` is a GitHub template repository whose primary user is a
**learner** who forks it to build a derived project while practicing
high-quality collaboration with Claude Code. Earlier ADRs added structured
artifacts (16-agent team, ADR/spec templates, Learning Mode, research
verification) but did not change the **default execution posture** of a fresh
session. Three observable gaps:

1. **No structural pressure to plan before implementing.** Claude Code's
   official Plan Mode exists, but the template ships with the default
   permission mode (auto-accept allow-listed tools), so a learner has to
   remember to toggle it. Decisions still happen mid-implementation.
2. **The agent team is 16 entries deep, but `description` fields focus on
   *what an agent is* rather than *when to invoke it*.** The official
   sub-agents documentation states that `description` should make the trigger
   condition explicit so the orchestrator can route correctly.
3. **Coaching context attaches manually.** When Learning Mode is enabled,
   `coach.style` lives in `.claude/learn/config.json`, but it is loaded only
   at the agent's discretion. There is no structural guarantee that every
   user prompt is enriched with the current coaching context.

A research-critic verification pass (Tier S, primary sources only) on
`code.claude.com/docs` confirms the following four primitives exist and are
production-ready (verified 2026-05-07):

- `permissions.defaultMode: "plan"` in `settings.json` — boots the session in
  Plan Mode by default.
- Built-in Output Style **`Learning`** — appends `TODO(human)` markers so
  learners write small fragments themselves rather than read finished code.
- Custom output styles in `.claude/output-styles/*.md` with frontmatter
  (`name`, `description`, `keep-coding-instructions`, `force-for-plugin`).
- `UserPromptSubmit` Hook with `additionalContext` injection and
  `decision: "block"` — runs before Claude processes a prompt.

Two further primitives are confirmed and used opportunistically:
`SubagentStop` Hook (can block), and the `ultrathink` keyword inside Skill
content (forces Extended Thinking for one turn). One primitive was
**deliberately rejected** during review: the
`Agent(<agent_type>, …)` tools-frontmatter restriction. The Critic verified
it only takes effect when an agent runs as the main thread under
`claude --agent`; in regular sub-agent definitions under `.claude/agents/` it
is a no-op. We do not adopt it.

## Decision

Adopt a **plan-first, learning-aware default posture** for every session that
boots from this template. Concretely:

1. **Plan Mode by default.** Add `"permissions": { "defaultMode": "plan" }`
   to `.claude/settings.json` so a learner is asked to confirm a plan before
   any write or shell side effect. Learners can opt out per session via
   Shift+Tab or by editing local settings.

2. **Output Style guidance (opt-in, but discoverable).** Ship a custom
   output style at `.claude/output-styles/ecc-learn.md` (built on top of the
   built-in `Learning` style) and document the trade-off in CLAUDE.md and
   README. We do **not** force-enable it (a custom output style replaces
   coding-specific system prompts when `keep-coding-instructions: false`,
   which is too invasive to set globally), but we make selection a one-line
   step.

3. **Codify the agent `description` convention.** A pre-implementation
   audit of `.claude/agents/*.md` showed that all 16 agents already follow
   the *"Use when …"* form recommended by the official sub-agent docs.
   Rather than rewrite identical text, this ADR fixes the convention
   forward: it is added as a checked item to the `claude-md-authoring`
   Skill (ADR-007), so future agent edits and any new agent files are
   verified against the same trigger-phrase rule. No agent file content
   changes as part of this ADR.

4. **`UserPromptSubmit` Hook for coaching auto-context.** When Learning Mode
   is enabled (`learn/config.json: enabled: true`), a hook script reads
   `coach.style` and injects the matching coaching preamble into
   `additionalContext` on every user prompt. This removes the "did the agent
   actually load my coaching style?" failure mode. The hook script itself
   is conditional — it exits 0 with no output when Learning Mode is
   disabled or the style is `default`, so derived projects pay nothing
   for the registration when they do not opt in. The hook is registered
   without a `matcher` field because, per the official hooks reference,
   `UserPromptSubmit` does not support matchers (it fires on every
   prompt, no filtering). The script name is resolved through
   `$CLAUDE_PROJECT_DIR` to avoid CWD assumptions, and the script
   strictly validates the configured style name against an allow-list
   plus a realpath-containment check before reading any file, so a
   tampered `learn/config.json` cannot be used to leak unrelated `.md`
   files into the prompt.

The four sub-decisions ship together because they reinforce each other: Plan
Mode raises the cost of "implement first, think later"; the Learning output
style turns reading into doing; better `description` fields route the right
agent to the right step of the plan; and the coaching hook guarantees the
chosen style is always live.

## Consequences

### Positive

- Implementation is gated by an explicit plan acceptance step, not
  willpower. Quality of decisions rises across the board.
- The `Learning` output style turns "read finished code" into "write the
  next small piece," matching the template's stated learning purpose.
- Agent routing becomes more reliable for newcomers: the orchestrator can
  pick the right specialist from `description` alone.
- Coaching style is no longer "advisory documentation" — it is structurally
  attached to every prompt while Learning Mode is on.

### Negative

- Plan Mode adds a confirmation step to every session. Power users will
  feel friction for trivial edits. Mitigation: Shift+Tab disables it for
  the current session; `.claude/settings.local.json` can override per
  developer.
- The custom output style and Plan Mode default both raise the floor of
  "minimum interaction" required to do anything. For a learner this is
  the point; for an experienced user adopting this template for non-
  learning work, the README must make the opt-out path obvious.
- A new `UserPromptSubmit` hook adds a (cheap) shell invocation per
  prompt. Hook script must be conservative — bounded runtime, no network,
  fail-open on any error so a misbehaving hook never blocks the user.

### Neutral

- No 16-agent rewrite is needed (the audit above). The convention is
  fixed forward in `claude-md-authoring`, so the next agent file added
  or edited is verified mechanically.
- The new output style file is opt-in, so it does not affect derived
  projects that ignore it.

## Alternatives considered

| Alternative | Pros | Cons | Why not chosen |
|---|---|---|---|
| Force Plan Mode + Learning output style globally | Strongest learning pressure | Breaks non-learning forks; surprising for users who skipped README | Defaults should be the *suggested* posture, not mandatory |
| Document Plan Mode in README only, no settings change | Zero behavior change | Most users never read past Quick Start; the structural guarantee never lands | Documentation alone has been the historical failure mode |
| Use `Agent(<agent_type>)` frontmatter to lock orchestrator's spawn list | Looks like cleaner routing | Critic verified it is a no-op in sub-agent definitions (only affects `--agent` main thread) — false sense of security | Rejected on primary-source evidence |
| Embed coaching context in CLAUDE.md instead of a hook | No new file/script | CLAUDE.md applies to every prompt regardless of Learning Mode state, and grows with every coach style | Hook is the right scope: per-prompt, conditional, removable |

## References

- ADR-001 (Developer Growth/Learning Mode), ADR-004 (Coaching Pillar) —
  the layer this ADR makes structurally enforced.
- ADR-007 (claude-md-authoring Skill) — same philosophy of "verify against
  Anthropic's official docs before writing."
- ADR-008 (Research Verification Layer) — provided the verification protocol
  that validated the primitives this ADR relies on.
- Anthropic primary sources (verified 2026-05-07, Tier S):
  `code.claude.com/docs/en/settings`, `/hooks`, `/output-styles`,
  `/sub-agents`, `/skills`. Re-verified during code review:
  `permissions.defaultMode` accepts `"plan"`; `UserPromptSubmit` ignores
  `matcher`; hook commands resolve through `$CLAUDE_PROJECT_DIR` and are
  not specified to accept relative paths; output-style frontmatter
  defaults `keep-coding-instructions` to `false`.
