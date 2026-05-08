---
name: verification-layer
description: >
  Adversarial review protocol applied across three domains: external
  research that informs decisions (research domain — ADR-008), production
  implementations whose behaviour matters (implementation domain), and
  architecture decisions before they are accepted (design domain). Each
  domain pairs a Generator with a Critic that uses a different tool
  family and may cite only primary sources. Bounded GAN-style iteration,
  per-domain opt-in via .claude/verification.yml, and a shared severity
  vocabulary. Reference this Skill when an artifact in any of the three
  domains will be consumed by a downstream agent for a decision.

  Skill contents (Progressive Disclosure):
    SKILL.md                 — overview, shared invariants, domain navigator
    research/protocol.md     — research-domain protocol (Tier table, GAN)
    research/checklist.md    — Critic checklist (10 items) + allowlist
    research/failure-modes.md — five typical research-error patterns
    implementation/protocol.md — implementation-domain protocol
    implementation/checklist.md — Critic checklist for behavioural delta
    implementation/failure-modes.md — typical implementation-error patterns
    design/protocol.md         — design-domain protocol (counter-proposal)
    design/checklist.md        — Critic checklist for ADR review
    design/failure-modes.md    — typical design-error patterns

  This Skill is English-only by design, consistent with
  .claude/meta/references/upstream-workaround-tracking.md and the
  claude-md-authoring Skill (ADR-007).
disable-model-invocation: true
arguments: []
---

# Verification Layer

## Purpose

Stop wrong conclusions from reaching downstream agents. Three domains
cover the three artifact types most prone to silent error in this
template:

| Domain | Generator | Critic | What it catches |
|---|---|---|---|
| `research` | `docs-researcher` | `research-critic` | Confirmation echo, secondary-source drift, hallucinated APIs |
| `implementation` | `implementer` | `adversarial-implementer` | Subtly wrong choice that all reviewers see the same way |
| `design` | `architect` | `architecture-critic` | Rejected alternatives that were never seriously considered |

The three domains share a philosophy and differ only in the artifact
shape and the per-domain ranking of "what counts as a different
approach." This file fixes the shared invariants. The per-domain
files in `research/`, `implementation/`, and `design/` carry the rest.

## Shared invariants (apply to every domain)

These are non-negotiable. A domain that drops one of them is no longer
a verification-layer domain.

1. **Generator-vs-Critic separation.** The agent that produces the
   artifact does not also adjudicate it.

2. **Different tool family.** The Critic uses a tool family disjoint
   from the Generator's wherever feasible. The enumerated families
   are below.

3. **Primary-source-only citation.** The Critic may cite only primary
   sources for any external claim. Secondary sources (blogs, Q&A
   sites, AI summaries, translations of primary sources) are
   disqualifying. The shared allowlist lives in
   [research/checklist.md](./research/checklist.md) and is referenced
   by every domain.

4. **Severity vocabulary.** All domains use the same four-level
   severity table:

   | Severity | When to use |
   |---|---|
   | CRITICAL | Source 404 or fabricated; behaviour diverges; ADR contradicts a load-bearing prior decision |
   | HIGH | Version mismatch; behaviour diverges on a load-bearing path; ADR omits a constraint that materially changes the choice |
   | MEDIUM | Generator cited only secondary sources; Critic produced two implementations that agree but on different inputs; ADR's "Alternatives" entry is too thin to evaluate |
   | LOW | Citation date missing; minor style; non-blocking observation |

5. **Bounded iteration.** Each domain caps the Generator/Critic round
   trip (`max_iterations`, default 2). After the cap, escalate to the
   orchestrator with the structured report described in
   [research/protocol.md §Escalation contract](./research/protocol.md).

6. **Opt-in per domain.** Each domain has its own `enabled: true|false`
   switch in `.claude/verification.yml`. The default-off domains pay
   nothing for a derived project that does not enable them. The
   `research` domain is default-on **only** when the file
   `.claude/verification.yml` is present and `research.enabled` is
   true (matching ADR-008's intent); absent file = inert.

## Tool families (resonance prevention)

The "different tool family" rule below requires an enumerated list. Two
calls are considered to have used the *same* family if they fall in the
same row.

| Family | Examples |
|---|---|
| Curated MCP docs lookup | Context7 MCP, plugin context7 variants |
| Direct vendor docs | WebFetch / direct URL fetch on vendor docs site |
| GitHub access | `gh` CLI, GitHub MCP, raw `github.com/<vendor>/<repo>` URLs at a tag |
| Web search | Generic web search (last resort; not acceptable as Critic's *only* family) |
| Vendor-specific MCP | Firebase MCP, dart MCP, etc. — for that vendor only |
| Local execution | Run the project's own test suite, profiler, or static analyser |

For the `implementation` domain, "different tool family" extends
naturally: the Critic's implementation must exercise a different code
path or library than the Generator's, and any external citation must
still come from a different docs-lookup family.

For the `design` domain, the Critic must derive its counter-proposal
from a different evidence base than the Generator's ADR — different
benchmark source, different vendor docs version, or a different
constraint emphasis.

## Configuration

`.claude/verification.yml` controls activation. The defaults are
deliberately asymmetric:

| Knob | File absent | File present, key absent | File present, key explicit |
|---|---|---|---|
| `research.enabled` | inert (matches ADR-008) | `true` | as written |
| `implementation.enabled` | off | `false` | as written |
| `design.enabled` | off | `false` | as written |
| `citation_discipline.enabled` | **on** | `true` | as written |

Three of the four knobs default to "do nothing for a derived project
that has not opted in." Citation discipline is the exception — its
runtime cost is essentially zero per CI run and its failure mode
(silent secondary-source accumulation in load-bearing documents) is
severe, so it runs even without a config file. Derived projects can
disable it explicitly with a documented reason.

See [`.claude/verification.yml.example`](../../verification.yml.example)
for the full template with annotated knobs.

## When to invoke

Per domain. Each domain's `protocol.md` states its own triggers and
non-triggers. The shared rule:

> If the artifact you are about to ship will inform a decision a
> downstream agent or human reviewer takes — invoke. If the artifact
> is a casual lookup or an internal scratch step — do not.

Casual conversational use, style lookups (T3 in the research domain),
and re-reading the project's own commit history are out of scope.

## Cross-domain citation discipline

Knowledge entries written under `.claude/learn/knowledge/` (Developer
Learning Mode, opt-in) and ADR / spec files in this repo carry the
same primary-source-only citation rule. A CI check enforces it
mechanically: see
[research/checklist.md §Allowlist](./research/checklist.md). The CI
script and the Critic share the same allowlist file as the single
source of truth.

## Domain navigator

| Domain | Start here | Critic agent |
|---|---|---|
| `research` | [research/protocol.md](./research/protocol.md) | [`.claude/agents/research-critic.md`](../../agents/research-critic.md) |
| `implementation` | [implementation/protocol.md](./implementation/protocol.md) | [`.claude/agents/adversarial-implementer.md`](../../agents/adversarial-implementer.md) |
| `design` | [design/protocol.md](./design/protocol.md) | [`.claude/agents/architecture-critic.md`](../../agents/architecture-critic.md) |

## See also

- [`.claude/meta/adr/008-research-verification-layer.md`](../../meta/adr/008-research-verification-layer.md)
  — original research-domain rationale (English)
- [`.claude/meta/adr/010-verification-layer-generalization.md`](../../meta/adr/010-verification-layer-generalization.md)
  — generalization rationale, including the four-level ranking for
  the implementation domain and the counter-proposal contract for the
  design domain (English)
- Japanese ADR pairs at the same paths with `.ja.md` extension.
