# Research Review: <topic>

> Output artifact for the research-verification protocol
> (`.claude/skills/research-verification/SKILL.md`). The Generator
> (`docs-researcher`) writes the top sections. The Critic
> (`research-critic`) appends to "Critic Findings" and "Verdict".

## Generator

- Agent: docs-researcher
- Tier: T1 | T2 | T3
- Tools used: <list, e.g., "Context7 MCP, gh search code">
- Retrieved: YYYY-MM-DD
- Question: <what was asked, in primary-source language>
- Version pin: <e.g., "Next.js 14.2.x", or "unpinned — answer is provisional">

## Claims

| # | Claim | Source URL | Retrieved | Severity (Critic) |
|---|-------|-----------|-----------|-------------------|
| 1 | <what the Generator concluded> | <URL with version tag> | YYYY-MM-DD | <filled by Critic> |
| 2 | ... | ... | ... | ... |

## Generator self-check

For T3, this is the only verification step. For T1/T2, this runs in
parallel with the Critic.

- [ ] Each claim cites at least one primary source.
- [ ] Each citation URL is version-tagged or commit-pinned.
- [ ] Each citation has a retrieval date.
- [ ] No conditional claims left implicit.

## Critic Findings

> Filled by `research-critic` for T1 and T2. Skipped for T3.

- **[Claim #N]**: <CRITICAL | HIGH | MEDIUM | LOW> — <one-line reason>
  - Primary source (Critic): <URL with version tag, from primary-source allowlist>
  - Tool family used: <different from Generator>
  - Retrieved: YYYY-MM-DD
  - Detail: <what the primary source says vs. the claim>

## Verdict

- Round: <N>/<max_iterations>
- [ ] PASS (no findings, or LOW only)
- [ ] REQUEST CHANGES (MEDIUM/HIGH/CRITICAL findings present; back to Generator)
- [ ] ESCALATE (round limit reached, findings remain; orchestrator decides)

## Escalation block (only when ESCALATE)

- Topic: <one line>
- Final Tier: T1 | T2 | T3
- Iterations consumed: <N>/<max_iterations>
- Generator final position: <one sentence>
- Critic final position: <one sentence>
- Disagreement: <where they differ, with both citations>
- Recommended action:
  - [ ] Ask user for tie-break
  - [ ] Mark claim UNVERIFIED: and proceed
  - [ ] Block downstream until resolved

## Audit trail

- Generator query log: <preserved verbatim — reused as Critic's input>
- Critic primary-source allowlist consulted: yes
- Same-tool-family check: <Generator tools> vs <Critic tools> → distinct
