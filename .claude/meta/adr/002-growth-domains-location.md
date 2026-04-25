# ADR-002: Move `growth_domains` out of sub-agent frontmatter

## Status

Accepted. 2026-04-23.

> **Partially superseded 2026-04-24 by [ADR-003](003-learning-mode-relocate-and-rename.md):** the `## Growth Domains` section marker in agent prompt bodies is renamed to `## Learning Domains` (and the feature is renamed from "Growth Mode" to "Learning Mode"). The architectural decision recorded here — prompt-body declaration, CI re-anchor, schema compliance — remains governed by this ADR.

## Metadata

- Date: 2026-04-23
- Deciders: Agent Team (architect lead; docs-researcher schema verification)
- Supersedes: `growth_domains:` frontmatter declaration pattern introduced by [ADR-001](001-developer-growth-mode.md)
- Related: [ADR-001](001-developer-growth-mode.md), [docs/en/growth/domain-taxonomy.md](../growth/domain-taxonomy.md), [scripts/check-growth-invariants.sh](../../../scripts/check-growth-invariants.sh)

## Context

ADR-001 established that each of the 15 sub-agents in `.claude/agents/*.md` declares its Growth Mode domain ownership via a custom frontmatter key:

```yaml
---
name: implementer
description: ...
model: sonnet
growth_domains:
  primary: [error-handling, concurrency-and-async, ecosystem-fluency, implementation-patterns]
  secondary: [architecture, api-design, data-modeling, ...]
---
```

During the v1.1.1 spec-alignment review, we verified the official Claude Code sub-agent frontmatter schema against `docs.claude.com` (via Context7 MCP). The documented schema is **closed** to `name`, `description`, `tools`, `model`. `growth_domains:` is not a schema-supported key.

The pattern currently works for one reason only: the LLM reads the entire agent file as text, including its own frontmatter, and the prompt body contains a natural-language guard that says "follow the 5-step enrichment contract for any teaching moment that falls within its declared `growth_domains` (primary and secondary, as listed in the frontmatter above)." The LLM treats the frontmatter block as readable context, not as structured data processed by the Claude Code runtime.

This creates two risks:

1. **Silent regression risk.** If Anthropic ever enforces the closed frontmatter schema — for instance, by stripping unknown keys before the prompt is assembled — the guard branch still executes but has no domain list to reference. The agent would still gate correctly on `config.json`, but its teaching contributions would degrade silently.
2. **Hard-failure risk.** A stricter enforcement mode could reject the file outright during agent loading, causing every growth-aware agent to fail to load. This would not be silent, but would break the template for every downstream fork on the Anthropic release that ships the enforcement.

The `scripts/check-growth-invariants.sh` guard-branch check currently greps for the literal string `growth_domains:` as the marker that identifies a growth-aware agent. It does not depend on frontmatter parsing; it depends on textual presence.

This ADR records the decision to remove the dependency on unofficial frontmatter semantics before either regression mode can hit a downstream fork.

## Decision

Move each agent's Growth Mode domain declaration from a frontmatter key into a dedicated `## Growth Domains` section at the top of the agent prompt body, immediately after the frontmatter.

Canonical shape:

```markdown
---
name: implementer
description: ...
model: sonnet
---

## Growth Domains

- Primary: error-handling, concurrency-and-async, ecosystem-fluency, implementation-patterns
- Secondary: architecture, api-design, data-modeling, persistence-strategy, testing-discipline, review-taste, security-mindset, performance-intuition, operational-awareness

# Implementer Agent
...
```

Every growth-aware agent receives exactly this shape. The two-tier `Primary` / `Secondary` split is preserved because the enrichment contract in `.claude/growth/preamble.md` treats primary domains as the agent's first-responsibility zone and secondary domains as cross-reference territory; collapsing to a flat list would lose that signal.

The `scripts/check-growth-invariants.sh` guard-branch anchor changes from grepping for `growth_domains:` to grepping for the literal line `## Growth Domains`. The default-off invariant is unaffected — it continues to depend on (a) `disable-model-invocation: true` on the Skill, (b) the guard-branch reference to `.claude/growth/config.json` in each agent prompt, and (c) gitignore posture. Only the marker string changes.

The `.claude/growth/preamble.md` language is updated to say "declared Growth Domains section" instead of "declared `growth_domains` frontmatter."

The v1.1.1 README disclosure paragraph about `growth_domains:` being a template-local frontmatter convention is updated to reflect the new location (or removed during the README restructure in issue #3).

## Alternatives Considered

| Alternative | Pros | Cons | Why Not Chosen |
|---|---|---|---|
| **A. Inline prompt-body section** (chosen) | Colocated with agent; zero extra I/O at session start; invariant script re-anchors trivially; schema-compliant | Domain list is not machine-auditable without a bespoke CI check | Chosen. Best resilience at equal runtime cost. |
| **B. Centralized manifest file** (`.claude/growth/agent-domains.yaml`) | Auditable single view; lintable against taxonomy at CI time; no frontmatter dependency | Every growth-aware agent must read the manifest at session start (adds I/O); creates a new drift failure mode (agent ↔ manifest); domain list is no longer colocated with the agent definition | The I/O cost multiplies by every growth-aware agent invocation. Not justified when the 15 agents already live in one directory that CI can scan. |
| **C. Status quo** (`growth_domains:` frontmatter + README caveat) | Zero migration cost; works today | Bets the feature on undocumented schema tolerance; silent regression is the most likely failure mode if Anthropic enforces the schema | Not chosen. Alt A is strictly better on resilience at equal cost. |

A comparison table scoring A/B/C on maintainability, LLM reading cost, invariant enforcement, single-source-of-truth, regression risk, and taxonomy-drift resistance was run during the decision. Alt A scored 28; B and C tied at 21.

## Consequences

### Positive

- **Schema compliance.** No reliance on undocumented frontmatter keys. If Anthropic closes the schema strictly, the template continues to work unchanged.
- **Zero added I/O.** The domain list is already in the agent's prompt body, which the LLM reads top-to-bottom on every invocation. No new file reads.
- **Simpler mental model.** A new contributor reading an agent file sees the domain declaration visibly in the prose, not hidden in YAML.
- **Invariant enforcement preserved.** The CI check continues to grep for a literal marker (`## Growth Domains` instead of `growth_domains:`). All three existing invariant checks stay intact.

### Negative

- **One-time migration cost.** All 15 agent files are edited in a single commit. The invariant script is updated in the same commit. There is no transition window where both markers are accepted; the switch is atomic.
- **No machine-readable structure.** The domain list is markdown, not YAML. A future CI check that validates every listed domain against `docs/en/growth/domain-taxonomy.md` would need a new regex or parser. This is deferred as a separate issue.

### Neutral

- **README disclosure paragraph.** The v1.1.1 disclosure paragraph explaining `growth_domains:` as a template-local frontmatter convention is updated during the migration. Under issue #3 (README restructure), it may be further reshaped or removed.
- **ADR-001 references.** Passages in ADR-001 that describe `growth_domains:` as a frontmatter key are updated to point to this ADR and the new location. The architectural substance of ADR-001 is unchanged.
- **Japanese translations.** `docs/ja/adr/002-growth-domains-location.md` is authored as a synced translation alongside the English source.

## Implementation Notes

### Migration scope (single commit)

1. All 15 files under `.claude/agents/*.md` lose their `growth_domains:` frontmatter key and gain a `## Growth Domains` section immediately after the frontmatter, containing two labeled bullet lines in the canonical shape.
2. `scripts/check-growth-invariants.sh` Check 2 re-anchors: the existing `grep -Eq '^growth_domains:'` becomes `grep -Eq '^## Growth Domains$'`. The guard-branch check (that every such agent references `.claude/growth/config.json`) is unchanged.
3. `.claude/growth/preamble.md` wording updates: references to "`growth_domains` frontmatter" become "Growth Domains section at the top of the agent prompt." No protocol semantics change.
4. Each agent's "Developer Growth Mode contract" section updates its cross-reference from "as listed in the frontmatter above" to "as listed in the Growth Domains section above."
5. `README.md` and `README.ja.md` disclosure paragraphs are updated to describe the new location (or removed if #3 restructures around them first).
6. `docs/ja/adr/002-growth-domains-location.md` is authored in the same commit.

### Curator flag

The `technical-writer.md` agent currently declares `curator: true` alongside its `growth_domains:` in frontmatter. This flag marks it as the agent responsible for cross-domain curation operations (e.g., consolidating duplicated notes, promoting stable sections to canonical domain anchors). The flag migrates to the same `## Growth Domains` section as a third labeled line:

```markdown
## Growth Domains

- Primary: documentation-craft
- Secondary: (none)
- Curator: true
```

Only agents that perform cross-domain curation carry the `Curator` line. The default is absence; presence means the agent may edit any domain file for curation purposes, not just its primary/secondary list. `.claude/growth/preamble.md` is updated to look for this line in the same section.

### Out of scope for ADR-002

- Adding a CI check that every listed domain exists in `docs/en/growth/domain-taxonomy.md`. Useful, but separable. Tracked as a v1.2.x follow-up.
- Structural changes to the taxonomy itself or to the primary/secondary semantics in `preamble.md`. Those remain governed by ADR-001.
- Any change to agent behavior at runtime. The migration is prose-only.
