# ADR-007: CLAUDE.md authoring Skill — hybrid invariants + runtime docs verification

## Status

Accepted — 2026-05-06

## Context

The template ships eight specialist agents that routinely create or modify
project-context documents — `CLAUDE.md`, `README.md`, and
`.claude/agents/*.md`. Anthropic's official guidance for these documents has
evolved across Claude Code releases, and adopters of ecc-base-template have
no built-in mechanism to keep their authoring aligned with current Anthropic
recommendations. Two failure modes follow:

1. **Bloat.** Without a checklist, agents accumulate prose about
   code-derivable facts (file paths, framework names) and miss the
   200-line guard. The result is a `CLAUDE.md` that consumes context
   tokens without informing Claude.
2. **Drift.** Anthropic's guidance changes — domain renames
   (`docs.anthropic.com` → `code.claude.com`), new frontmatter fields,
   adjusted thresholds. A static checklist baked into agent prompts
   silently goes stale.

Two naive designs fail:

- **All-inline Skill.** Maximum determinism, but freezes Anthropic
  guidance at the date the Skill was written. Within months the Skill
  contradicts current Docs and adopters cannot tell which to trust.
- **All-runtime fetch.** Always current, but every authoring session
  pays Context7 / WebFetch latency and tokens for the same facts.
  Worse, when Docs are unreachable (404, network failure, mirror
  drift) authoring stops.

The agent-team review established a hybrid: **inline the structurally
invariant rules; fetch the volatile values at runtime through a defined
protocol with graceful degradation.**

## Decision

Introduce a Skill at `.claude/skills/claude-md-authoring/` that splits
its content along the invariant / volatile axis and uses Progressive
Disclosure (per Anthropic's official skill-authoring pattern) to keep
the entry point small while making detailed reference available on
demand.

### Principles

1. **Structurally invariant rules are inlined.** Four rules are
   stable enough that Anthropic would have to redesign Claude Code's
   memory model to invalidate them: hierarchy existence, root-vs-subdir
   compaction survival, code-is-not-prose, and `@path` import syntax
   existence. These are the Skill's contract.
2. **Volatile values are deferred to a runtime protocol.** Numeric
   thresholds (200-line guard, recursion depth 5), UI surfaces (`#`
   shortcut, `/memory`), and version-specific frontmatter behaviour
   (`disable-model-invocation` semantics) are looked up via a defined
   Context7 → URL → `llms.txt` chain.
3. **Graceful degradation.** When all three runtime paths fail, the
   Skill does **not** fail. The agent continues with the inlined
   invariants only and tells the user the volatile section was not
   verified this session.
4. **Progressive Disclosure** (Anthropic-recommended pattern). The
   Skill directory is `SKILL.md` (entry point, ~200 lines) plus
   `invariants.md`, `docs-protocol.md`, and `examples.md` loaded on
   demand. Adopters reading the Skill never see all four files at
   once; agents load only what the current task requires.
5. **Manual invocation only.** Frontmatter declares
   `disable-model-invocation: true`. The Skill is reference material —
   not a behaviour the model should auto-trigger. This also reduces
   context cost to zero unless the Skill is explicitly invoked
   (verified Anthropic guidance — "context cost to zero for skills you
   only trigger yourself").
6. **Override Protocol.** Adopters can opt out of individual
   invariants in their own `CLAUDE.md`, but only with an explicit,
   dated declaration. The structure of the Invariant Core itself
   cannot be redefined by an adopter.
7. **English-only**, consistent with
   `.claude/meta/references/upstream-workaround-tracking.md` and
   `.claude/meta/references/domain-taxonomy.md`. The audience is
   engineers and agents that already read English upstream content
   directly.

### Invariant / volatile classification

The classification was derived from `docs-researcher`'s freshness
audit and verified twice (Context7 MCP and direct URL fetch) on
2026-05-06.

| Item | Class | Rationale |
|---|---|---|
| Hierarchy (global / project / subdir) | Invariant | Memory model would have to be redesigned to remove. Anthropic has only added new locations. |
| Root vs subdir compaction-survival difference | Invariant | The structural payoff of the hierarchy. Removing it eliminates the reason for the hierarchy. |
| Code-is-not-prose principle | Invariant | Anthropic's stated philosophy of what `CLAUDE.md` is for; not a numeric tweakable. |
| `@path` import syntax existence | Invariant | Removal is a breaking change for every existing CLAUDE.md in the world. |
| 200-line CLAUDE.md threshold | Volatile | Numeric, can shift with model and context-window improvements. |
| `@path` recursion depth (5) | Volatile | Numeric tunable. |
| `#` shortcut and `/memory` UI | Volatile | UI surfaces are the most likely to be redesigned. |
| `disable-model-invocation` exact effect | Volatile | Frontmatter semantics can extend; "context cost zero" was added in a recent release. |

### File budget (verified guidance)

`SKILL.md` is targeted at ~200 lines and capped at the Anthropic
recommended **500 lines** (verified 2026-05-06 against
`code.claude.com/docs/en/skills`). The 200-line CLAUDE.md guard does
**not** apply to Skill files — that is a CLAUDE.md-specific
recommendation, also verified against the same source. Detailed
reference belongs in the sibling `.md` files, which load only on
demand.

### Provided artifacts

| Path | Role |
|---|---|
| `.claude/skills/claude-md-authoring/SKILL.md` | Entry point, ~200 lines, Pre/Post checklists, Override Protocol, navigation |
| `.claude/skills/claude-md-authoring/invariants.md` | The four invariant rules with citations and re-verification protocol |
| `.claude/skills/claude-md-authoring/docs-protocol.md` | Context7 → URL → `llms.txt` runtime verification chain, with fallback semantics |
| `.claude/skills/claude-md-authoring/examples.md` | Bad/Good excerpts that show each invariant applied in practice |
| `.claude/meta/scripts/check-skill-invariants.sh` | CI script enforcing structural invariants on the Skill (line cap, frontmatter fields, cross-reference resolution) |
| `.github/workflows/skill-invariants.yml` | Default-on workflow running `check-skill-invariants.sh` on Skill changes |
| `.github/workflows/docs-freshness.yml` | Default-off, monthly workflow that diffs `code.claude.com/docs/llms.txt` against the previous run and posts a summary |
| `.github/docs-freshness.yml` | Configuration for the freshness workflow (`enabled: false` default) |

### Grandfathered Skills

The pre-existing `learn` Skill (ADR-001 / ADR-003 / ADR-004) predates
this contract and is currently 721 lines, above the 500-line cap.
Restructuring it into Progressive Disclosure form is not part of
ADR-007 — that would expand the scope of this decision into the
Learning Mode design. `check-skill-invariants.sh` exempts
`.claude/skills/learn/SKILL.md` via an explicit allowlist; new skills
are not exempt. If `learn` is restructured later, the allowlist entry
should be removed in the same change.

### Out of scope (deliberately)

- A second Skill for README-specific authoring (the same Skill covers
  `README.md` because the structural rules are the same).
- A linter that flags code-derivable content automatically. The
  invariant is judgement-based; CI cannot enforce it.
- Bidirectional sync with Anthropic's Docs (no API for that).
- Auto-updating Skill content from `llms.txt` diffs. Human review
  remains in the loop.

## Consequences

### Positive

- Adopters get a working CLAUDE.md authoring contract on day one,
  without needing to read Anthropic's docs first.
- The Skill stays useful as Anthropic's guidance evolves: invariants
  remain stable, volatile values are looked up on demand, and a
  defined recovery path (`llms.txt`) handles domain renames.
- Progressive Disclosure means the Skill never blows past the
  500-line cap. Detail lives in sibling files that load only when
  invoked.
- `disable-model-invocation: true` keeps the context cost at zero
  unless an agent explicitly invokes the Skill — adopters with no
  authoring activity in a session pay nothing.

### Negative

- An adopter who never reads the Skill is unaffected by it. The Skill
  is opt-in by design (manual invocation), so adopters who do not
  know to invoke it during authoring miss its checks. Mitigation:
  reference the Skill from the relevant agent definitions
  (`technical-writer`, `docs-researcher`, `architect`, `implementer`,
  `code-reviewer`, `devops-engineer`, `orchestrator`).
- The runtime-verification protocol depends on Context7 MCP being
  configured. Adopters without Context7 fall through to direct URL
  fetch, which is fine but slower.
- The Skill's verification dates require periodic refresh. Without
  the `docs-freshness.yml` workflow enabled, dates drift silently.

### Neutral

- The Skill is English-only. Adopters who want a Japanese authoring
  guide for their team should write one in their own docs; the
  Skill's English text is the reference document.
- The Skill does not replace `CLAUDE.md` itself. It is a meta-document
  about how to write `CLAUDE.md` — the project still needs its own
  `CLAUDE.md` filled with project-specific context.

## Alternatives considered

| Alternative | Pros | Cons | Why not chosen |
|---|---|---|---|
| All-inline Skill (no runtime fetch) | Maximum determinism; never fails | Freezes Anthropic guidance at write time; goes stale silently | Drift over Claude Code release cycles is the dominant failure mode |
| All-runtime fetch (no inline rules) | Always current | Authoring stops when Docs are unreachable; tokens spent re-fetching invariants every session | The four invariants are stable enough to inline; runtime cost on the stable parts is pure waste |
| Single-file SKILL.md (no Progressive Disclosure) | Simpler structure | Pushes total content over the 500-line cap; hurts indexability | Anthropic explicitly recommends Progressive Disclosure for skills with reference detail |
| Treat as ADR-006 special case (Anthropic-as-upstream) | Reuses existing workaround machinery | ADR-006 tracks semver-versioned dependencies; Anthropic Docs are not semver-versioned, and the marker/registry contract does not fit | Independent ADR keeps both contracts clean |
| 200-line cap on SKILL.md | Symmetry with CLAUDE.md | Anthropic recommends 500 for SKILL.md; a 200 cap would force unnatural compression and harm Skill quality | Verified Anthropic guidance: 200 is CLAUDE.md-specific, 500 is the SKILL.md recommendation |

## References

- ADR-005 — template-internal vs consumer-layer separation; this ADR
  follows the same partitioning principle.
- ADR-006 — upstream workaround tracking; this ADR is its sibling
  (Anthropic Docs as a different upstream-source category, but with
  no semver to track, requiring a different contract).
- `https://code.claude.com/docs/en/skills` — Skill structure, 500-line
  recommendation, Progressive Disclosure pattern. Verified 2026-05-06.
- `https://code.claude.com/docs/en/memory` — CLAUDE.md hierarchy,
  imports, 200-line recommendation. Verified 2026-05-06.
- `https://code.claude.com/docs/en/best-practices` — code-is-not-prose
  guidance. Verified 2026-05-06.
- `https://code.claude.com/docs/en/features-overview` — Skill load
  semantics ("full content when used"; `disable-model-invocation` →
  "context cost to zero"). Verified 2026-05-06.
- Council deliberation 2026-05-06 — architect, docs-researcher,
  technical-writer, devops-engineer, code-reviewer reviewed the
  initial proposal and surfaced the line-cap and trigger-design
  issues that shaped the final form. Findings are folded into
  §Decision and §Alternatives considered above.
