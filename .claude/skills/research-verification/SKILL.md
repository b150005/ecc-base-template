---
name: research-verification
description: >
  Adversarial review protocol for external research that informs decisions
  (architecture, library selection, API usage, version constraints). Generator
  (docs-researcher) does the initial research; Critic (research-critic) reviews
  it using a different tool family and a primary-source-only citation
  requirement. Bounded GAN-style iteration, Tier-declared scope, opt-out via
  config. Reference this Skill when an external-research result will be
  consumed by a downstream agent — not for casual lookups.

  Skill contents (Progressive Disclosure):
    SKILL.md         — protocol overview, Pre/Post checklist, navigation
    checklist.md     — Critic checklist (10 items) and primary-source allowlist
    failure-modes.md — five typical research-error patterns with mitigations

  This Skill is English-only by design, consistent with
  .claude/meta/references/upstream-workaround-tracking.md and the
  claude-md-authoring Skill (ADR-007).
disable-model-invocation: true
arguments: []
---

# Research Verification

## Purpose

Stop wrong external-research conclusions from reaching downstream agents.
Catch confirmation echo, secondary-source drift, and hallucinated APIs at the
research step rather than at build/test time.

## When to invoke

- Generator (`docs-researcher`) is about to return findings that an
  architect, implementer, security-reviewer, or any other agent will rely on
  for a decision (technology choice, API usage, version pin, breaking-change
  assessment).
- Reviewing an ADR draft whose rationale cites external sources.
- The orchestrator is routing a research output to multiple downstream
  agents and wants the result verified once.

Do **not** invoke for:

- Style or convention lookups where the answer does not change a design
  decision (T3 in the Tier table below — Generator self-check is enough).
- Re-reading the project's own code or commit history (that is not external
  research).
- Casual conversational lookups during pair-programming.

## Opt-out

`.claude/research-verification.yml` controls activation. If the file is
absent, defaults apply (`enabled: true`, `max_iterations: 2`,
`default_tier: T2`). When `enabled: false`, this Skill is inert — agents
proceed without verification and no error is raised. See
`.claude/research-verification.yml.example` for the template.

## Tier table

The Generator declares a Tier on every external-research output. The
orchestrator can escalate upward (T3 → T2, T2 → T1) but never downward.

| Tier | Scope | Mechanism |
|---|---|---|
| T1 | Breaking changes, auth, security-sensitive APIs, crypto primitives | Two-stage (independent re-research + primary-source check) + GAN up to 2 rounds |
| T2 | Public API arguments, return types, defaults, common library behaviour, version-specific feature availability | Two-stage; Critic runs once, no iteration unless CRITICAL/HIGH |
| T3 | Idiomatic style, common usage examples, widely-known patterns | Generator self-check against one primary source; no Critic |

If unsure between Tiers, choose the higher one.

## Protocol (T1 / T2)

```
[1] Generator (docs-researcher)
    - Freshness-safe query (existing protocol; see docs-researcher.md)
    - Produce draft using research-review-template.md
    - Declare Tier
    - Record tool log + citation list

[2] Two-stage review (parallel)
    [2a] Critic (research-critic)
         - Receive Generator's tool log + citations
         - Use a DIFFERENT tool family
         - Cite at least one primary source the Generator did not use
         - Apply checklist.md (10 items)
         - Output findings with severity (CRITICAL / HIGH / MEDIUM / LOW)
    [2b] Generator self-check (docs-researcher)
         - Re-run with version-pinned primary source
         - Confirm or revise each claim against that source

[3] Verdict
    - LOW only or no findings: PASS
    - MEDIUM/HIGH/CRITICAL present: REQUEST CHANGES → [4]

[4] GAN iteration (T1 only, T2 only if CRITICAL/HIGH remain)
    - Generator addresses findings, produces v2
    - Critic re-reviews
    - Up to max_iterations (default 2). After that, escalate.
    - For T2: if remaining findings are MEDIUM/LOW only, terminate
      (do not iterate). Iteration is reserved for CRITICAL/HIGH.

[5] Escalation (if iterations exhausted with findings remaining)
    - Orchestrator presents both positions to the user, OR
    - Mark the claim UNVERIFIED: and pass it to downstream agents
      with that label preserved.
```

T3 collapses to step [1] plus a single primary-source check inside the
Generator. Critic is not invoked.

## Severity classification (Critic findings)

| Severity | When to use |
|---|---|
| CRITICAL | Source 404 or fabricated; claim hallucinated; method/argument absent from primary source |
| HIGH | Version mismatch; unstated breaking change; claim contradicts primary source on a load-bearing detail |
| MEDIUM | Generator cited only secondary sources (must add primary); internal contradiction in Generator's citations |
| LOW | Citation date missing; wording ambiguous; non-blocking style notes |

Round terminates when remaining findings are LOW only, or
`max_iterations` is reached. Full rationale in ADR-008.

## Primary-source-only constraint (Critic)

The Critic's independent citation **must** be a primary source.

**Acceptable** (primary):

- Vendor official documentation site (`nextjs.org/docs`, `pub.dev`,
  `flutter.dev/docs`, `pkg.go.dev`, etc.)
- Vendor official GitHub repository: README, CHANGELOG, source code, type
  definitions, official examples
- Vendor official issue tracker (for known-bug confirmation)
- RFC, W3C, ECMA, or equivalent standards bodies
- MDN Web Docs (Web platform APIs only)
- Language-runtime official references (`docs.python.org`,
  `pkg.go.dev/std`, `doc.rust-lang.org/std`, etc.)

**Not acceptable** (secondary):

- Stack Overflow, Qiita, Zenn, dev.to, Medium, personal blogs
- AI summary sites, cached snippets, screenshots
- Tutorial repositories that are not the vendor's own
- Translations of primary sources (use the original)

Rationale: secondary sources lag primary sources, often by months. The
Critic's purpose is to catch that lag. Permitting secondary citations
defeats the mechanism. See [checklist.md](./checklist.md) for the full
allowlist and the rationale for each entry.

## Tool families (resonance prevention)

The Critic's hard rule "use a different tool family from the
Generator" requires an enumerated list of families. Two agents are
considered to have used the *same* family if their tool calls fall in
the same row below:

| Family | Examples |
|---|---|
| Curated MCP docs lookup | Context7 MCP, plugin context7 variants |
| Direct vendor docs | WebFetch / direct URL fetch on vendor docs site |
| GitHub access | `gh` CLI, GitHub MCP, raw `github.com/<vendor>/<repo>` URLs at a tag |
| Web search | Generic web search (last resort; not acceptable as Critic's *only* family) |
| Vendor-specific MCP | Firebase MCP, dart MCP, etc. — for that vendor only |

If the Generator used Context7 MCP, the Critic's independent citation
must come from a different row (typical choice: direct vendor docs or
GitHub at a tag). Two `WebFetch` calls against unrelated URLs do
**not** count as different families — the rule is family, not URL.

## Pre-research checklist (Generator)

Before opening Context7 / WebFetch / `gh search`:

- [ ] **Tier declared.** T1 / T2 / T3, decided by the impact of the
  answer on downstream work.
- [ ] **Question restated in primary-source language.** If the question
  uses framework jargon, translate it to the terms the official docs use
  (e.g. "Server Actions" not "server-side functions").
- [ ] **Version pinned.** State the version the answer must apply to. If
  unknown, the answer is at best provisional — surface this.
- [ ] **Primary source identified.** Where will the authoritative answer
  come from? If you cannot name a primary source for this question, the
  question is ill-posed; reframe it.

## Post-research review checklist (Critic)

See [checklist.md](./checklist.md) for the full 10-item version. The
core five:

- [ ] **Primary source cited?** At least one citation must be from the
  primary-source allowlist.
- [ ] **Version-pinned URL?** Tagged docs URL, commit SHA, or release
  page — not a moving "latest" pointer.
- [ ] **Generator's tool log inspected?** The Critic must use a
  different tool family than the Generator did.
- [ ] **Conditional claims flagged?** "Works only when X" claims need
  the X stated explicitly.
- [ ] **Retrieval date present?** Every citation carries a
  `(retrieved: YYYY-MM-DD)` annotation.

## Output format

Generator and Critic both write into `research-review-template.md`. See
[`.claude/templates/research-review-template.md`](../../templates/research-review-template.md)
for the full structure.

Minimum required fields:

```markdown
## Research Review: <topic>

### Generator
- Tier: T1 | T2 | T3
- Tools used: <list>
- Retrieved: YYYY-MM-DD

### Claims
| # | Claim | Source URL | Retrieved | Severity |

### Critic Findings
- <claim ref>: <severity> — <reason>
  - Critic primary source: <URL>
  - Tool family used: <different from Generator>

### Verdict
- Round: N/2
- [ ] PASS  / [ ] REQUEST CHANGES  / [ ] UNVERIFIED (escalated)
```

## Escalation contract

When `max_iterations` is reached and findings remain, the orchestrator
receives a structured report:

```markdown
## Escalation: research-verification

- Topic: <what was being researched>
- Final Tier: T1 | T2 | T3
- Iterations consumed: 2/2
- Generator final position: <one sentence>
- Critic final position: <one sentence>
- Disagreement: <where they differ, with both citations>
- Recommended action:
  - [ ] Ask user for tie-break
  - [ ] Mark claim UNVERIFIED: and proceed
  - [ ] Block downstream until resolved
```

The orchestrator picks one of the three actions and records it in the
session output.

## See also

- [checklist.md](./checklist.md) — Critic checklist (10 items) and
  primary-source allowlist
- [failure-modes.md](./failure-modes.md) — five typical research-error
  patterns
- [`.claude/agents/docs-researcher.md`](../../agents/docs-researcher.md)
  — Generator agent
- [`.claude/agents/research-critic.md`](../../agents/research-critic.md)
  — Critic agent
- [`.claude/templates/research-review-template.md`](../../templates/research-review-template.md)
  — output artifact format
- [`.claude/meta/adr/008-research-verification-layer.md`](../../meta/adr/008-research-verification-layer.md)
  — design rationale (English)
- [`.claude/meta/adr/008-research-verification-layer.ja.md`](../../meta/adr/008-research-verification-layer.ja.md)
  — same, Japanese
