# ADR-004: Learning Mode Coaching Pillar (Output Styles–Compatible Behavior Modes)

## Status

Accepted. 2026-04-25.

## Metadata

- Date: 2026-04-25
- Deciders: Agent Team (architect lead; implementer on enforcement surface; technical-writer on style-file register; ui-ux-designer on command-surface ergonomics)
- Related: [ADR-001](001-developer-growth-mode.md) (the knowledge pillar this ADR complements), [ADR-003](003-learning-mode-relocate-and-rename.md) §G "Coaching pillar" (explicitly deferred from v2.0.0 to v2.1.0 — this ADR delivers what ADR-003 deferred), [docs/en/prd/developer-learning-mode.md](../prd/developer-learning-mode.md)
- Target release: v2.1.0. The Meridian worked-examples deliverable also deferred from ADR-003 §5 ships separately in v2.2.0 (a later split of the original PR #2 scope, made for review-load reasons).

## Context

Learning Mode shipped in v2.0.0 with a single pillar: **knowledge accumulation**. Every agent, when a teaching moment arises, writes a durable entry into `learn/knowledge/<domain>.md`. The output is a domain-organized textbook that grows across sessions. This pillar is **post-hoc and passive** — the agent produces its normal artifact and then records what it taught. The learner reads the artifact as they always would and reads the knowledge diff afterward.

Two classes of learner need that is not covered:

1. **The learner who wants to write the load-bearing code themselves.** The knowledge pillar does not change what the agent produces — it only annotates the produced result. A learner asking "I want to implement the login endpoint myself; tell me the next step but not the code" has no lever. Today they rely on prose instructions to the agent and hope the next turn honors them; the honoring is per-turn and prone to drift.

2. **The learner who wants help with the shape of a decision rather than a finished answer.** A "should I cache this?" question returned as a finished caching implementation skips the decision. The knowledge pillar may write a trade-off note afterward, but the decision has already been made for the learner.

Both gaps call for **in-session behavior change** — the agent behaves differently during implementation, not only after. This is a different axis than knowledge accumulation: knowledge is what gets recorded; coaching is how the agent works.

Claude Code's **Output Styles** feature is the nearest platform primitive. Output Styles replace the system prompt's coding-style section with a different instruction set loaded from a Markdown file. They are well-suited to session-wide register changes — "run in learning-tutor mode for this session." But the Output Styles primitive has two properties that do not fit Learning Mode:

- Output Styles are **bound at session start** and replace coding instructions wholesale. Learning Mode needs coaching to layer on top of normal behavior and to be switchable mid-session without restart.
- Output Styles have no awareness of Learning Mode's default-off invariant, the knowledge pillar's state, or the authorship-boundary guarantee (`disable-model-invocation: true`). Adopting them directly would mean coaching escapes the invariants the rest of the feature enforces.

The coaching pillar adopts the Output Styles **file format** — portable, standards-aligned, reviewable by humans who already know the Claude Code ecosystem — while keeping state and dispatch inside Learning Mode's existing surface. This ADR records that architecture and its six coaching styles (the inert `default` plus five active styles).

## Decision

Ship the coaching pillar as an orthogonal axis to the knowledge pillar. Both pillars can be off, on independently, or on together. The coaching pillar introduces six styles (the inert `default` plus five active behavior modes) expressed in Output Styles–compatible Markdown files under `.claude/skills/learn/coach-styles/`, with the active style written to `learn/config.json` and enforced by the same agent guard branch that enforces the knowledge pillar.

### 1. Five coaching styles with deterministic behavior rules

| Style | Behavior rule | When to use |
|---|---|---|
| `default` | Agent works normally. No withholding, no extra teaching. Equivalent to coach-off. | Coach is not needed for this session. |
| `hints` | Agent identifies the next concrete step, names the relevant pattern or API, and stops before writing the body of the target function. Emits a `## Coach: hint` block with the step, the pattern name, and a one-line rationale. May write scaffolding (imports, signatures, test stubs). Never writes the target function body. | Learner wants to write the load-bearing code themselves. |
| `socratic` | Agent replies to a how or why request with exactly one focused question that, if answered, picks the design. Does not write code in the same turn as the question. Resumes normal behavior after the learner answers. | Design decisions where the learner has enough context to choose if prompted. |
| `pair` | Agent writes complete scaffolding with `// TODO(human): <one-line instruction>` markers at the load-bearing decision points. Markers are capped at roughly 30% of the changed lines so the scaffolding is genuinely a skeleton, not a stub. Tests are written in full so the learner has a target to hit. | Learner wants structure handed to them but to own the algorithm. |
| `review-only` | Agent refuses to write production code. Reads code, runs tests, and produces a structured review of code the learner submits or already has on disk. May write tests if explicitly asked. | Learner is driving; wants the agent as reviewer, not author. |
| `silent` | Agent works normally **and** suppresses every `## Learning:` and `## Coach:` trailing section for the lifetime of this style. The inverse of teaching-mode. | Learner is in flow and does not want pedagogy noise in the response. |

Styles are mutually exclusive — exactly one is active. Switching styles takes effect on the next agent turn.

### 2. Hybrid architecture (Output Styles file format + Learning Mode config state)

Style files are authored in Output Styles–compatible Markdown: YAML frontmatter plus body. The frontmatter carries `name`, `description`, and a Learning Mode extension field `behavior-rule:` that encodes the deterministic rule the agent enforces at turn time. The body is prose for humans reviewing the file.

```yaml
---
name: hints
description: Name the next step and the pattern; stop before the function body.
behavior-rule: >
  Identify the next concrete step toward the learner's goal. Name the relevant
  pattern or API. Write scaffolding (imports, signatures, test stubs) only.
  Do not write the body of the target function. Emit a `## Coach: hint` block
  with step, pattern, and one-line rationale.
stop-markers:
  - "<!-- coach:hints stop -->"
---
```

The source of truth for **which** style is active is `learn/config.json`, not a session-start binding. This lets `/learn coach <style>` switch mid-session without restart, lets the guard branch read a single JSON file to resolve all Learning Mode state, and keeps the `disable-model-invocation: true` authorship boundary intact.

Style files ship at `.claude/skills/learn/coach-styles/<style>.md`. The Skill body discovers available styles by listing this directory — new styles can be added by dropping a file in, with no code change.

### 3. Config schema extension

```json
{
  "enabled": true,
  "level": "junior",
  "focus_domains": [],
  "coach": {
    "style": "default",
    "trailers": "auto",
    "scope": "session"
  },
  "updatedAt": "2026-04-25T00:00:00Z"
}
```

- `coach.style` — one of `default | hints | socratic | pair | review-only | silent`. A missing or unparseable value resolves to `"default"`. A style name not matching any file in `coach-styles/` also resolves to `"default"` with a warning on next `/learn status`.
- `coach.trailers` — `auto | always | never`. Under `auto`, `silent` style suppresses trailers; every other style emits them when the knowledge pillar is on.
- `coach.scope` — `session | persistent`. Under `session`, the `coach` subtree resets on session end (the Skill writes `coach.style = "default"` on the first invocation of a new session if `scope = session`). Under `persistent`, the style survives across sessions.
- **Backwards compatibility:** a v2.0.0 config with no `coach` key resolves to `coach.style = "default"`. No behavior changes for existing installs. The default-off invariant is preserved.

### 4. Pillar composition rules

The two pillars are orthogonal:

- **Knowledge off, coach off** — default state. Byte-identical to no Learning Mode at all.
- **Knowledge on, coach off (= `default`)** — v2.0.0 behavior.
- **Knowledge off, coach on** — permitted. Learner gets active coaching without notebook overhead.
- **Knowledge on, coach on** — both layers stack.

Interaction rules:

- In `socratic`, the agent's clarifying question can itself be a teaching moment. If the question reveals a load-bearing concept, the agent writes to `learn/knowledge/` following the enrichment protocol in the same response where the question is asked.
- In `silent`, knowledge writes still happen when the knowledge pillar is on; only the chat-visible trailers are suppressed. `/learn status` always reports the last-N knowledge diffs so silent writes are not invisible.
- `level: junior` does not auto-couple to `hints` or any other coach style. The default coach is `"default"` at every level. Level controls the angle of explanation; coach controls the shape of the agent's work. The two axes do not constrain each other.

### 5. Skill command surface additions

The `/learn` Skill gains a `coach` subcommand group:

```
/learn coach <style>                      — set style (equivalent to /learn coach style <style>)
/learn coach off                          — equivalent to /learn coach default
/learn coach list                         — list discovered style files and their descriptions
/learn coach show <style>                 — print a single style's behavior rule
/learn coach scope <session|persistent>   — set persistence scope for the coach subtree
```

The `disable-model-invocation: true` flag on the Skill extends to every coach subcommand. No agent turn can switch, disable, or otherwise alter the coach style — only the learner can.

## Alternatives Considered

| Alternative | Pros | Cons | Why Not Chosen |
|---|---|---|---|
| **A. Direct Claude Code Output Styles adoption.** The learner invokes `/output-style learning-tutor` and Learning Mode reads the Output Styles API for its coach state. | Zero protocol invention; the platform already knows how to load style files; minimal surface we have to maintain. | Session-start-bound — switching styles mid-session requires a restart and loses context; Output Styles replace the coding-instruction section wholesale rather than layering on top; no awareness of Learning Mode invariants (`disable-model-invocation`, default-off guard, pillar composition); the learner has to understand two toggles (`/output-style` and `/learn`) to reason about a single feature. | Not chosen. The invariants we already enforce for the knowledge pillar would escape the feature boundary. |
| **B. Pure own implementation.** Custom file format, custom discovery path, no reference to Output Styles at all. | Full control; no dependency on a platform feature that might evolve; could be simpler in the short term. | More specification to maintain; style files would not be portable to other Output Styles consumers; forkers already familiar with Output Styles have to learn our bespoke variant; loses the ability to lift/port existing Output Styles files as starting points. | Not chosen. We would be reinventing a perfectly good file format for no gain. |
| **C. Hybrid — Output Styles file format, Learning Mode state and dispatch (chosen).** | Portable file format; discoverable by humans who already know Output Styles; state stays in `learn/config.json` so invariants hold; switchable mid-session; new styles are drop-in files with no code change. | One-time cost to document the `behavior-rule:` frontmatter extension and its semantics. | Chosen. Preserves every Learning Mode invariant while borrowing a proven file format. |

## Decision Drivers

In priority order:

1. **Default-off byte-identity.** A v2.1.0 install with no `coach` key in config must produce byte-identical output to v2.0.0. The coach branch guard mirrors the knowledge branch guard.
2. **Harness-vs-artifact boundary.** Style files live under `.claude/skills/learn/coach-styles/` because styles are platform-adjacent machinery. The learner's accumulated knowledge stays at `learn/knowledge/`. The boundary established in ADR-003 is honored.
3. **Deterministic enforcement.** Behavior rules are stated imperatively in the style file and checked at turn time. Stop markers (`<!-- coach:hints stop -->`) give the enforcer something grep-able to verify the style ran. No LLM-in-the-loop invariant checks.
4. **No model-initiated state change.** `disable-model-invocation: true` extends to every `coach` subcommand. The learner — not the model — chooses the style.
5. **Orthogonal composition with the knowledge pillar.** The coaching pillar does not change what the knowledge pillar writes. The knowledge pillar does not change which coach style is active. Each can be toggled without touching the other.
6. **Mid-session switchability.** The learner can flip between `hints` and `default` several times per session as the work shape changes. This is only possible because state lives in `config.json`, not in a session-start binding.

## Consequences

### Positive

- Learners who want active coaching get a deterministic set of behaviors to choose from, with file-backed rules that are reviewable and forkable.
- Style files are portable. A team that wants a custom coaching style drops a file into `coach-styles/` and references it by name — no code change, no Skill rewrite.
- The authorship boundary is unchanged. The model cannot promote a learner into pair-programming mode or demote them to review-only; only the learner can.
- The `silent` style gives learners an escape hatch from trailer noise without disabling the knowledge pillar. This preserves accumulation while quieting the chat response.
- The hybrid format means the template can, in a later release, register its styles with the platform's Output Styles registry if Claude Code grows an affordance for layered styles — the files are already in the right shape.

### Negative

- The preamble grows by approximately 50 lines (new §§15–20). This is a one-time cost; the new sections are self-contained.
- Per-style deterministic enforcement depends on model adherence to imperative rules. Stop markers and affordance stripping (e.g., the agent's write-tool privileges are withheld from turns executed under `review-only`) mitigate drift, but the coaching pillar is the first place where behavior correctness is partly a discipline problem rather than a grep-able invariant. PR review of style files is the compensating control.
- `silent` + knowledge on means knowledge files change without the chat showing a diff trailer. This could feel invisible to a learner who is not expecting writes. Mitigation: `/learn status` always reports the last-N knowledge diffs, and the trailer-suppression behavior is documented explicitly in the style's body.

### Neutral

- Existing v2.0.0 installs upgrade transparently. A config file with no `coach` key resolves to `coach.style = "default"` and nothing changes.
- Japanese translation of the style files is out of scope for this ADR. Style file bodies are English at ship; behavior rules apply regardless of learner language.
- The `/quiet` Skill (introduced in ADR-001 for one-shot trailer suppression) remains separate from `coach: silent`. `/quiet` is a single-turn suppression; `silent` is a persistent-until-changed style. Both exist because they serve different authorship boundaries.

## Implementation Notes

Grouped by phase. The implementer agent picks this up after ADR-004 lands.

### Phase 1: Config schema and guard

- Extend `learn/config.json` schema to accept the optional `coach` subtree. Write a migration step that adds `coach: { style: "default", trailers: "auto", scope: "session" }` to existing configs on first `/learn` invocation post-upgrade. Existing fields are preserved.
- Extend the guard branch in every learning-aware agent: after reading `learn/config.json`, if `coach.style` is a non-`default` value and the style file exists under `.claude/skills/learn/coach-styles/`, load the style file and apply the behavior rule for this turn. If `coach.style` is missing, invalid, or the file does not exist, fall back to `default`.

### Phase 2: Style files

- Create `.claude/skills/learn/coach-styles/` with one file per style: `default.md`, `hints.md`, `socratic.md`, `pair.md`, `review-only.md`, `silent.md`. Each file uses the frontmatter shape shown in Decision §2 and carries a prose body explaining the behavior for human reviewers.
- The specific content of each style file is the implementer's deliverable. This ADR specifies the shape and the behavior rules; it does not author the files.

### Phase 3: Preamble additions

Add §§15–20 to `learn/preamble.md`:

- **§15 Coaching Pillar Overview** — what it is, default-off invariant restated for coach, orthogonality with the knowledge pillar.
- **§16 Coach Style Resolution** — the read order `config.coach.style` → style file → built-in fallback to `default`.
- **§17 Per-Style Behavior Contracts** — the six deterministic rules from Decision §1 (`default` plus the five active styles), stated in the preamble's imperative voice.
- **§18 Coach × Knowledge Composition** — when a coach behavior (particularly `socratic`) produces a knowledge-eligible moment, and the `silent` rule for trailer suppression.
- **§19 Coach Trailer Format** — `## Coach: <style> output` heading format, and the suppression rule under `silent` and `coach.trailers: never`.
- **§20 Style File Format** — frontmatter schema (`name`, `description`, `behavior-rule`, `stop-markers`), the extension over Output Styles, and the rule that style files are loaded at guard time, not at session start.

### Phase 4: Skill body

- Extend `.claude/skills/learn/SKILL.md` with the `coach` subcommand group from Decision §5. Keep `disable-model-invocation: true` at the Skill level — it already applies to every subcommand.
- Add discovery logic: `/learn coach list` enumerates files under `coach-styles/` and reports `name` and `description` from each file's frontmatter.
- Extend `/learn status` output to report `coach.style`, `coach.trailers`, `coach.scope`, and — when `scope: session` — the session-start behavior.

### Phase 5: CI invariant check

- Extend `scripts/check-learn-invariants.sh` with two additional deterministic greps:
  1. The coach guard branch marker string must appear in every file under `.claude/agents/` that declares a `## Learning Domains` section.
  2. `.claude/skills/learn/coach-styles/` must contain at least the six canonical style files, each with a `behavior-rule:` frontmatter key.
- No LLM-in-the-loop checks are added. The existing three checks remain unchanged.

### Phase 6: Examples and JA mirrors

- Extend the Meridian worked examples (also shipping in PR #2 per ADR-003) with one short section per example showing how a `hints`-style turn would differ from a `default` turn for that domain. This is illustrative, not normative — the examples remain read-only references.
- Japanese mirror for ADR-004 at `docs/ja/adr/004-coaching-pillar.md`.
- Japanese translation of style file bodies is explicitly out of scope for this ADR and is tracked for a later release.

## Out of Scope

- **Specific style file content.** This ADR states the behavior rules; authoring the bodies of each `<style>.md` file is the implementer's task in PR #2.
- **Translation of style files to Japanese.** Behavior rules are language-agnostic; body prose is English at ship. A later release can translate bodies without changing this ADR.
- **New coach styles beyond the initial six.** Additional styles (e.g., `drill`, `refactor-coach`) are a post-v2.1.0 concern. The drop-in file format means they can be added without a new ADR unless they change the invariants stated here.
- **Integration with Claude Code's Output Styles registry.** If the platform grows layered-style support, a future ADR records the registration step. Until then, style files are loaded by Learning Mode's own guard, not by the platform.
- **Anything about the knowledge pillar's internal rules.** Those remain governed by ADR-001 and the v2.0.0 preamble. ADR-004 adds a second pillar; it does not modify the first.
