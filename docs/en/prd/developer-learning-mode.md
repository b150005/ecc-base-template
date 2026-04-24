# Developer Learning Mode

> **Version history.** Originally specified for v1.1.0 as "Developer Growth Mode." Directory layout, feature name, and terminology revised in [ADR-003](../adr/003-learning-mode-relocate-and-rename.md) / v2.0.0 (2026-04-24). All paths, commands, and terminology below reflect the v2.0.0 state.

## Metadata

| Field | Value |
|-------|-------|
| Status | Accepted |
| Target release | v2.0.0 (breaking) |
| Owner | Agent Team |
| Created | 2026-04-22 |
| Last updated | 2026-04-24 |

---

## 1. Problem Statement

Developers using the ECC agent team receive finished artifacts — code, architecture documents, test suites, security reports — without any signal about why each decision was made, what the trade-offs were, or how the choice fits into the broader pattern landscape of the project. A developer who copies the implementer's output and ships it has accelerated delivery. They have not necessarily accelerated understanding.

This gap is not a function of the quality of the artifact. A well-written function returned by the implementer teaches nothing about the pattern it embodies, the boundary condition that shaped the error handling, or the ADR that records why this project made a non-obvious choice here rather than the idiomatic one. A developer who encounters the same pattern six months later in a different context must rediscover it — or look it up — because the reasoning was never exposed the first time.

Three observation categories capture most of the loss:

- **Pattern blindness.** A developer applies agent-generated patterns without internalizing the name, the alternatives, or the conditions under which the pattern stops being appropriate. They can reproduce but cannot reason from it.
- **Context blindness.** The agent made a choice that diverges from the default. The developer does not notice, because the output is correct and the review passes. The divergence is load-bearing: understanding it matters the next time a similar decision arises.
- **Knowledge fragmentation.** Teaching moments are scattered across sessions — a note here, an inline comment there — but never organized into a reference the developer can consult when a new task touches the same concept. Fragments do not accumulate into a mental model.

Developer Learning Mode addresses all three. It is an opt-in annotation layer that exposes reasoning alongside output, calibrated to the declared experience level, and accumulates that reasoning over time into an organized domain-keyed knowledge base the developer built by shipping real features. It does not alter the artifacts. It does not gate the work. It does not infer the developer's level or change it without explicit action.

The default experience — Learning Mode off — is unchanged for developers who do not want it.

---

## 2. Goals and Non-Goals

### Goals

The following goals are testable. Each states an observable condition and the measurement method.

1. **All-agent coverage.** When Learning Mode is active, all 15 agents in the team participate in knowledge enrichment according to their declared domain responsibilities. Measurable: inspect the `## Learning Domains` sections across all 15 agent files and confirm each agent's enrichment contract is exercised by a session that exercises that agent's primary task.

2. **Default-off invariant.** When Learning Mode is inactive (default), agent responses contain no learning-mode artifacts — no `## Learning:` sections, no `[Learning Note]` markers — and no file under `learn/knowledge/` is created or modified. This is a design claim about where the logic branches in agent prompts, not an output-equivalence claim (LLM outputs are non-deterministic across runs, model versions, and prompt compaction events; treating them as hashable against golden files is an antipattern). Verified: `scripts/check-learn-invariants.sh` asserts the three enforcement preconditions on every PR — `disable-model-invocation: true` on the learn Skill, the guard branch in every learning-aware agent prompt, and the gitignore posture.

3. **Knowledge base accumulates by domain.** After a session where an agent encounters at least one teaching moment, the relevant domain file under `learn/knowledge/` contains a new or deepened section. Observable: diff the knowledge directory before and after a session; at least one domain file shows a net content addition.

4. **Non-destructive editing.** An enrichment operation never silently removes content from a domain file that existed before the operation. This is a design goal spelled out in `learn/preamble.md` and enforced by PR review when changes touch the preamble or agent prompts — not by automated assertion against agent output.

5. **Severity preservation.** Code-reviewer findings are reported at their true severity regardless of Learning Mode level. A CRITICAL finding is labeled CRITICAL at `junior`, `mid`, and `senior` levels. This is a design requirement in agent prompts, verified by PR review when the code-reviewer prompt changes — not by fixture-based output matching.

6. **Skill toggles state correctly.** `/learn on junior`, `/learn off`, `/learn status`, `/learn focus <domain>`, and `/quiet` all produce the documented config change or suppression effect in the same session. Measurable: acceptance test per command form.

### Non-Goals

1. Learning Mode does not change, gate, delay, or alter the code or artifacts generated by any agent. It is an annotation and enrichment layer only.
2. Learning Mode does not infer or auto-escalate a developer's level based on behavior signals. The declared level is the level.
3. Learning Mode does not include any sharing or export feature for domain knowledge files in this release.
4. Learning Mode does not include progress scoring, completion markers, badges, streaks, or any gamification element.
5. Learning Mode does not auto-level-infer from session content, commit history, or any behavioral proxy.
6. Learning Mode does not merge or synchronize knowledge files across multiple developers. Domain files are personal learning artifacts.
7. Learning Mode does not translate domain knowledge files into Japanese or any other language in this release.
8. Learning Mode does not apply to orchestrator delegation logic — the orchestrator's learning responsibility is limited to declaring domain ownership in its prompt body and following the enrichment protocol when its own response contains a teaching moment.

---

## 3. User Segments and Jobs-to-Be-Done

These are the users this feature serves. The table is a description of the served population, not a growth target.

| Segment | Description | Job-to-be-done |
|---------|-------------|----------------|
| Career-switching developer | First professional engagement with a statically typed, compiled, or highly idiomatic language; has genuine competence in a prior domain. | When I accept agent-generated code, I want to understand the pattern it embodies so that I can replicate it intentionally in the next feature rather than copy-pasting it without being able to explain it. |
| Mid-level engineer on a new stack | Three to five years of experience; the stack or framework in this project is new to them. Knows the fundamentals of programming; does not yet know what "idiomatic" means for this ecosystem. | When an agent makes a choice that diverges from what I would have written, I want an explanation of the convention it is following so I can calibrate quickly without stopping work to research. |
| Senior engineer onboarding a teammate | Owns the codebase; is working alongside a less-experienced developer who is also using the agents. | When the agent makes a non-obvious architectural choice, I want a trade-off note I can reference in a review conversation so that the discussion starts from shared vocabulary rather than from first principles. |

These three segments define the population. The feature does not assume any particular team size, company stage, or tooling context beyond Claude Code and the ECC template structure.

---

## 4. Level Semantics

Learning Mode has three levels: `junior`, `mid`, and `senior`. Levels control the angle and density of foundational context — what the agent assumes the developer already knows, and which decisions are worth noting at all. Levels are not a verbosity knob. They do not set a token budget or a note count cap. Depth is a property of the concept; the level determines which concepts clear the threshold for a note.

All three levels write into the same domain files. The knowledge base does not fork by level. A junior-level foundational explanation from session one and a senior-level trade-off refinement from session twelve coexist in the same section, layered — foundations on top, idiomatic variation in the middle, trade-off reasoning at the bottom.

### junior

The agent explains from first principles. It introduces vocabulary before using it. It names the pattern and contrasts it with the naive alternative a developer would reach for without prior exposure. Worked examples are expanded. Prerequisite concepts are either explained inline or cross-referenced to the domain file that covers them. The agent does not assume the developer has encountered this concept in any context.

A typical junior-level contribution to a domain file is a full section with a first-principles explanation, an idiomatic variation block, and a trade-offs block. It may be several paragraphs. That length is intended — it is building foundational scaffolding.

### mid

The agent assumes first principles but explains the non-obvious. It focuses on what idiomatic practitioners of this stack do that a competent engineer switching in from a different stack would not guess. Trade-offs are named; alternatives are acknowledged without being exhaustively compared. The agent does not re-explain concepts the mid-level developer is expected to know; it focuses on the places where this stack or this project diverges from what general experience would predict.

A typical mid-level contribution is shorter than a junior contribution — one to three paragraphs — but it is not terse. It still explains the why.

### senior

The agent contributes only when a decision was non-default. The note names the default, names the actual choice, and states why the choice was preferred in this context. Seniors write trade-off notes: compact, specific to the decision, valuable precisely because they capture reasoning that would otherwise stay in the author's head. A senior-level session that involved no non-default choices contributes zero notes. That is correct behavior, not a failure.

### Level-by-level sample lines

Each sample is realistic agent output. The examples cover seven agents across the 19-domain taxonomy: architect, implementer, test-runner, code-reviewer, market-analyst, technical-writer, and devops-engineer.

---

#### Architect — architecture domain

**Junior:**
> The event-sourcing boundary here keeps the write model append-only and the read model eventually consistent. These are two separate models that share no data store — the canonical description is Martin Fowler's Event Sourcing pattern; in a real project, the ADR that records the aggregate's consistency requirements would live under `docs/en/adr/NNN-event-sourcing.md` (illustrative path; no such ADR ships with the base template). The key thing to understand is that "eventually consistent" is a deliberate trade-off: the read model may be slightly stale, but the write model never has to lock to serve a read.

**Mid:**
> The anti-corruption layer (ACL) is placed at the domain boundary rather than the adapter layer. The difference matters: an ACL at the adapter layer keeps the adapter clean but lets the external schema leak into domain objects via the calling convention. An ACL at the domain boundary prevents leakage entirely. This diverges from the project scaffold's default, which skipped the ACL; in a real project the external API ownership constraint that made schema isolation worth the extra mapping step would be recorded in the corresponding ADR.

**Senior:**
> ACL at domain boundary over adapter-layer translation. Cost: an extra mapping step on every inbound call. Benefit: external schema changes cannot reach domain objects without passing through the ACL. Default omits this when the external API is team-owned and stable. (In a real project, cite the ADR by number here.)

---

#### Implementer — error-handling domain

**Junior:**
> `Result<T, E>` is used here instead of throwing an exception. The reason is not syntactic preference — it is about who handles the error. When a function throws, the caller must know to catch it and must handle the error path in a way that is invisible at the call site. When a function returns `Result<T, E>`, the type system forces the caller to acknowledge that both outcomes are possible, and the error path is handled explicitly where the call is made. This is the railway-oriented programming pattern. For the project's error-boundary convention, see `docs/en/` and the error-handling knowledge file.

**Mid:**
> The repository method returns `Option<T>` rather than `T | null` per ADR-007. The distinction is that `Option<T>` forces callers to unwrap, making the absent-value case explicit in the type system and preventing null propagation across module boundaries. Older files in this codebase still use `null` returns; those are migration candidates. Be consistent within a module boundary — mixed null and Option in the same module is worse than either alone.

**Senior:**
> `Option<T>` over `T | null` per ADR-007. Older files not yet migrated. Mixed strategies within a module boundary introduce cognitive overhead; standardize when touching.

---

#### Test-runner — testing-discipline domain

**Junior:**
> The test is structured as Arrange / Act / Assert (AAA) with no logic in the Assert section — no conditionals, no loops, no method calls beyond the assertion itself. The reason this matters: when a test fails, you want the failure to point directly at the assertion line, not at a conditional inside the Assert block that chose which assertion to run. A clean AAA test is self-documenting about what it is proving. If you find yourself writing logic in the Assert section, that is a signal that the test is proving too many things or that the setup is incomplete.

**Mid:**
> The fixture is constructed inline rather than shared via `beforeEach`. Shared fixtures that accumulate state to satisfy multiple tests become a source of coupling: Test A changes the fixture requirements, Test B breaks silently. Each test should be independently reproducible — able to run in isolation with everything it needs declared locally. The verbosity cost of inline fixtures is real; the coupling cost of shared fixtures that grow is higher.

**Senior:**
> Inline fixture over `beforeEach`. Trade-off: verbosity for isolation. Justified here because these two tests have divergent setup requirements. A shared fixture that conditionally handles both cases is the worse outcome.

---

#### Code-reviewer — review-taste domain

**Junior:**
> The mutation on line 14 is flagged as CRITICAL. The consequence is not just about this function: when a function mutates its argument, the caller's reference changes state without the caller knowing it happened. In a synchronous single-threaded flow, this can be traced. Across async boundaries or when the object is shared across components, the mutation becomes invisible and hard to diagnose. The fix is to return a new copy. This is the immutability rule in `rules/common/coding-style.md`. Learning note: the rule exists because hidden state change is one of the most common sources of bugs in large codebases that are hard to reproduce.

**Mid:**
> The nested conditional on lines 22-31 exceeds the project's 4-level nesting limit. This is labeled HIGH rather than style because deep nesting degrades test coverage effectiveness: branches inside deeply nested conditionals are harder to reach independently. The preferred refactor is to extract the inner branch into a named predicate, which also makes the intent visible at the call site. Naming the predicate is not cosmetic — it documents the condition's business meaning.

**Senior:**
> Mutation on line 14, async context, CRITICAL. Return new copy per immutability rule. Nested conditional on 22-31, HIGH, extract named predicate. No other blocking issues.

---

#### Market-analyst — market-reasoning domain (new canonical domain)

**Junior:**
> The competitive positioning decision recorded here assumes that the target user's primary job-to-be-done is reducing time-to-output rather than deepening understanding. This assumption shapes which features are surfaced first in the PRD. It is worth naming explicitly because job-to-be-done framing (Clayton Christensen's framework) predicts that users will switch away from a product when a competitor better serves the same underlying job — not when a competitor has more features. Understanding the JTBD protects against building for the wrong outcome.

**Mid:**
> The market segment definition uses revealed-preference data (downloads, issues, public repos using the template) over stated-preference data (surveys). The distinction matters for competitor analysis: stated preferences over-index on "I want X" while revealed preferences show what users actually chose under constraint. For this analysis to remain valid, the data source is cited; any segment update should come from comparable revealed-preference signals rather than substituting survey data.

**Senior:**
> Segment boundary drawn at "teams using Claude Code for production projects" rather than broader "AI tool users." Narrower definition reduces TAM estimate but increases signal quality. Widening it would require a different acquisition model. Cited rationale: ADR equivalent in the product-planning docs. Update if the project's adoption evidence shifts.

---

#### Technical-writer — documentation-craft domain (new canonical domain)

**Junior:**
> The ADR format used here — Context, Decision, Alternatives Considered, Consequences — is not arbitrary. Each section has a specific job: Context prevents the reader from having to reconstruct the situation that existed when the decision was made; Decision states the choice without hedging; Alternatives Considered shows that the decision was not the only option and prevents re-litigation later; Consequences captures both the positive and negative effects so future maintainers can evaluate whether the trade-off still holds. Omitting any section degrades the ADR's long-term utility. The format is drawn from Michael Nygard's ADR practice, commonly adapted in open-source projects.

**Mid:**
> The documentation for this API is split between the reference section (what parameters, what responses) and the conceptual section (why the endpoint is shaped this way). This separation is intentional: reference docs answer "what do I call," conceptual docs answer "why does this exist." Merging them produces docs that are neither good reference nor good explanation. The split also future-proofs updates: a parameter name change only touches the reference section; a redesign that changes the endpoint's purpose only touches the conceptual section.

**Senior:**
> Bilingual docs maintained via the single-source-of-truth pattern: `docs/en/` is authoritative, `docs/ja/` links to it and carries translations. This avoids dual-authorship drift at the cost of one translation pass per change. Alternative was to maintain both in parallel (higher drift risk) or English-only (lower maintenance, reduced accessibility). The current model holds unless translation lag becomes a user complaint.

---

#### Devops-engineer — operational-awareness and release-and-deployment domains

**Junior:**
> The CI pipeline runs lint, test, and build as sequential gates, not parallel jobs, for this stage. The reason is that lint failure produces noise in test output — a lint-failing file may trigger false test failures because the parsing step fails. Running lint first means that if a test fails, you know it is not a lint artifact. The ordering is a debugging-time convenience. The cost is slightly slower CI for fully-passing PRs. Both choices are defensible; the project chose determinism-of-failure-signal over raw throughput.

**Mid:**
> The Docker image uses a distroless base rather than alpine. The trade-off: distroless has no shell, no package manager, and no debugging tools in the image — it reduces the attack surface and image size but complicates live debugging. For a production service that logs structured output to an aggregator, you do not need to shell into the container; the logs are the debugging surface. If your operational model requires `exec`-ing into containers, alpine (or a debug sidecar) is the appropriate choice. This project's choice is recorded and should be revisited if the ops model changes.

**Senior:**
> Graceful shutdown on SIGTERM via a 15-second drain window before SIGKILL. This window is set to twice the 95th-percentile request latency from the last load test. If the latency distribution changes, update the drain window. Not documented in the Dockerfile but encoded in the Kubernetes deployment manifest; both need to stay consistent.

---

## 5. Functional Requirements

### FR-001: Skill Definition

Learning Mode is toggled via a Claude Code Skill. The Skill file lives at:

```
.claude/skills/learn/SKILL.md
```

The Skill's YAML frontmatter must include:

```yaml
---
disable-model-invocation: true
arguments: [action, level]
---
```

`disable-model-invocation: true` ensures the Skill can only be triggered by a user action (`/learn ...`), never auto-invoked by the model itself.

The `arguments` field maps positional tokens so that `/learn on junior` resolves to `$action=on` and `$level=junior`.

The Skill body implements the command dispatch logic: it reads `learn/config.json`, applies the requested state change, and writes the updated config back. On first invocation when no config file exists, it creates the file.

The Skill is the only surface through which Learning Mode state changes. Agents read the config file; they do not write it directly (except for the knowledge enrichment step, which writes domain files, not config).

### FR-002: Skill Command Forms

The following invocation forms must be supported:

| Command | Effect |
|---------|--------|
| `/learn on` | Enable at the level stored in config; default to `junior` if no level is stored |
| `/learn on junior` | Enable at `junior` level; write `enabled: true`, `level: "junior"` to config |
| `/learn on mid` | Enable at `mid` level |
| `/learn on senior` | Enable at `senior` level |
| `/learn off` | Disable; set `enabled: false`; preserve `level` and `focus_domains` for the next enable |
| `/learn status` | Report current enabled state, level, focus_domains, and the last ten knowledge-diff report summaries; does not modify config |
| `/learn focus <domain>` | Set `focus_domains` to a single domain; agents prioritize teaching moments in this domain |
| `/learn focus <domain>,<domain>` | Set `focus_domains` to multiple comma-separated domains |
| `/learn focus clear` | Clear `focus_domains`; agents treat all domains equally |
| `/learn level junior\|mid\|senior` | Change level without toggling enabled state |
| `/learn domain new <key>` | Prompt the learner to confirm a new custom domain key; on confirmation, create the seeded domain file and update config |
| `/quiet` | One-shot suppression for the immediately following agent invocation; does not modify config |

Unknown subcommands return a short usage message. They do not halt the session.

### FR-003: Config Schema

Learning Mode state persists in `learn/config.json`. The schema:

```json
{
  "enabled": false,
  "level": "junior",
  "focus_domains": [],
  "updatedAt": "2026-04-22T00:00:00Z"
}
```

Field semantics:

- `enabled` — boolean; required. If absent or unparseable, treat as `false`.
- `level` — string, one of `"junior"`, `"mid"`, `"senior"`; required when `enabled` is `true`.
- `focus_domains` — array of domain key strings; may be empty. When non-empty, agents with a teaching moment outside the listed domains still contribute if the moment is genuinely load-bearing for understanding, but prefer to defer non-focus moments rather than write a shallow entry.
- `updatedAt` — ISO 8601 timestamp; set by the Skill on every write.

The file must be valid JSON. A parse error is treated as `enabled: false`. Unknown keys are preserved on write (forward compatibility).

The file is created on first `/learn on` invocation. It does not exist in the repository before first use.

### FR-004: State Persistence and Agent Read Path

Config is read at session start by every learning-aware agent. The read sequence:

1. Read `learn/config.json`. If absent or `enabled: false`, skip all learning steps entirely. No reads of preamble, no reads of domain files, no modifications of any file under `learn/knowledge/`.
2. If `enabled: true`, read `learn/preamble.md` for the enrichment protocol.
3. Identify which domain files are relevant to the current task by mapping the task to domain keys from the agent's declared Learning Domains section.
4. Read those domain files so the agent knows what is already recorded and does not duplicate.
5. Proceed with the primary task. When a teaching moment arises, follow the enrichment protocol.

This read path is executed independently by each agent. The orchestrator does not propagate a pre-parsed config; each agent is responsible for its own read.

### FR-005: Knowledge Directory Structure

The domain-organized knowledge base lives at `learn/knowledge/`. One file per domain. No files are pre-seeded; the directory is empty on a fresh clone and is gitignored by default. The 19 canonical domain files are created lazily by agents when their first teaching moment fires:

```
learn/knowledge/
├── architecture.md
├── api-design.md
├── data-modeling.md
├── persistence-strategy.md
├── error-handling.md
├── testing-discipline.md
├── concurrency-and-async.md
├── ecosystem-fluency.md
├── dependency-management.md
├── implementation-patterns.md
├── review-taste.md
├── security-mindset.md
├── performance-intuition.md
├── operational-awareness.md
├── release-and-deployment.md
├── market-reasoning.md
├── business-modeling.md
├── documentation-craft.md
└── ui-ux-craft.md
```

When a domain file is created for the first time, the agent uses the seed shape defined in `learn/preamble.md` §7. The seed shape:

```markdown
---
domain: testing-discipline
owners: [test-runner, code-reviewer, implementer]
updated: 2026-04-22
---

# Testing Discipline

This domain covers test strategy, structure, fixture hygiene, and the test pyramid.
Agents contribute entries as teaching moments arise during real sessions.
```

The first agent with a teaching moment writes its section directly after the seed front matter; there is no intermediate placeholder. Custom domains opened via `/learn domain new <key>` follow the same shape and live in the same directory. They are not in a subdirectory.

### FR-006: Per-Agent Domain Ownership

Every agent file in `.claude/agents/` carries a `## Learning Domains` section at the top of its prompt body. Every agent has at least one primary domain. There is no exempt list — all 15 agents participate in learning enrichment.

The 19-domain ownership map (aligned to the canonical taxonomy in `docs/en/learn/domain-taxonomy.md` and ADR-001):

| Agent | Primary domains | Secondary domains |
|-------|-----------------|-------------------|
| orchestrator | release-and-deployment | architecture (planning lens only — delegates concrete teaching moments to receiving specialist) |
| product-manager | api-design | documentation-craft, market-reasoning |
| market-analyst | market-reasoning | business-modeling |
| monetization-strategist | business-modeling | — |
| ui-ux-designer | ui-ux-craft | api-design, architecture, implementation-patterns, performance-intuition |
| docs-researcher | ecosystem-fluency | dependency-management, documentation-craft |
| architect | architecture, api-design, data-modeling | concurrency-and-async, persistence-strategy, security-mindset |
| implementer | ecosystem-fluency, error-handling, concurrency-and-async, implementation-patterns | data-modeling, persistence-strategy, testing-discipline, architecture, api-design, security-mindset, performance-intuition, operational-awareness |
| code-reviewer | review-taste, testing-discipline, implementation-patterns, security-mindset | architecture, api-design, data-modeling, persistence-strategy, error-handling, concurrency-and-async, ecosystem-fluency, performance-intuition |
| test-runner | testing-discipline, performance-intuition | error-handling, implementation-patterns, review-taste, security-mindset |
| linter | implementation-patterns | review-taste, ecosystem-fluency, testing-discipline, security-mindset |
| security-reviewer | security-mindset | architecture, api-design, persistence-strategy, error-handling, testing-discipline, concurrency-and-async, dependency-management, implementation-patterns |
| performance-engineer | performance-intuition, concurrency-and-async | data-modeling, persistence-strategy, testing-discipline, implementation-patterns, review-taste, operational-awareness |
| devops-engineer | operational-awareness, release-and-deployment | dependency-management, persistence-strategy, security-mindset |
| technical-writer | documentation-craft | — |

The Learning Domains section is a list of domain keys combining primary and secondary. Ownership does not restrict writing — multiple agents can write into the same domain — but it defines primary responsibility and the default expectation for which agent will produce the most thorough contributions to that domain.

### FR-007: Enrichment Operation Contract

The contract every learning-aware agent follows when a teaching moment arises. The canonical definition lives in `learn/preamble.md`. Every agent references that file by path; agents do not inline it.

Five-step contract:

1. **Identify the target domain.** Map the teaching moment to a domain key from the agent's Learning Domains section. If the moment spans two domains, choose the one where the concept is most foundational and add a cross-reference link in the secondary domain. If no existing domain fits, propose a new one and wait for learner confirmation via `/learn domain new <key>`; do not auto-create domain files.

2. **Read the current domain file.** The agent reads the existing file before deciding how to contribute. This is non-negotiable. A contribution made without reading the current file risks duplicating content, contradicting an earlier entry without marking the supersession, or fragmenting a concept that already has a home.

3. **Decide the operation.** One of:
   - **Add** — create a new top-level section for a concept not yet present.
   - **Deepen** — append to an existing section with a new example, caveat, edge case, or cross-reference. The existing content is unchanged.
   - **Refine** — tighten the phrasing or improve an example in an existing section without changing the underlying claim. The prior phrasing is preserved as a `Prior Understanding (revised YYYY-MM-DD)` block.
   - **Correct** — mark a prior entry superseded and write the corrected understanding below it. The superseded text is never deleted; it remains with a `> Superseded YYYY-MM-DD: <reason>` marker.
   - **New domain** — only after learner confirmation per step 1.

4. **Apply the change non-destructively.** Existing headings, examples, and code blocks outside the change surface are preserved byte-for-byte. No entry is ever removed. If the file has grown past the organization threshold (see Open Questions on splitting), the agent flags the threshold in the diff report rather than reorganizing unilaterally.

5. **Report the diff.** At the end of its response, the agent emits two trailing sections visible in the chat response (not written to any file):

```
## Learning: taught this session
- [concept-name]: [one-sentence summary at the declared level]

## Learning: knowledge diff
- knowledge/<domain>.md → <operation> on `## <section-heading>`: <one-sentence change summary>
```

These sections are the provenance record the developer uses to audit knowledge base evolution. They are also the signal that any manual spot-check of default-off behavior looks for — these headers must be absent when Learning Mode is off.

### FR-008: CLAUDE.md Pointer

`.claude/CLAUDE.md` must contain a `## Developer Learning Mode` section. The section is unconditional — present in CLAUDE.md regardless of whether Learning Mode is currently enabled. Its content:

```markdown
## Developer Learning Mode

Learning Mode is a default-off learning layer. When enabled via `/learn on [junior|mid|senior]`,
every agent contributes to a domain-organized knowledge base at `learn/knowledge/`. The
knowledge base grows and is refined over many sessions into a personalized reference built by
shipping real features. Configuration lives at `learn/config.json`; the enrichment
protocol every agent follows is defined in `learn/preamble.md`. Run `/learn status`
to see current state.
```

No agent prompt instructions for Learning Mode live in CLAUDE.md. No learning-mode content other than this block is in CLAUDE.md.

Agents discover the knowledge directory and config path from this block on session start. The block is short enough that it does not materially add to context overhead for default-off sessions.

### FR-009: Git Stance for Knowledge Files

`learn/knowledge/` is gitignored by default. The repository ships:

1. A `.gitignore` entry that excludes `learn/knowledge/` and `learn/config.json` from version control.
2. A `.gitignore.example` file (or a comment block in the existing `.gitignore`) that shows the exact lines to comment out or remove if the developer chooses to commit their knowledge files.

The rationale for gitignore-by-default: domain knowledge files contain the developer's mistakes, superseded understandings, and revision history. That is private learning data. A developer who wants to share their knowledge base — for example, as a team learning commitment or a public study journal — makes that choice explicitly by editing `.gitignore`. The repository does not make it for them.

The README documents both paths: default private, opt-in shared. The README does not editorialize about which path is better.

`config.json` is always gitignored. It contains personal level and focus preferences that are individual and should not be committed.

### FR-010: Per-Session One-Shot Suppression

`/quiet` suppresses learning annotations for the immediately following agent invocation. It does not modify `config.json`. After the suppressed call, the next invocation from any agent resumes normal learning behavior. The `/quiet` flag can be appended to any agent invocation form.

### FR-011: Focus Domain Preference

When `focus_domains` is non-empty in config, agents use it as a soft priority signal. An agent with a teaching moment in a focus domain writes a full enrichment entry. An agent with a teaching moment outside the focus domains evaluates whether the moment is genuinely load-bearing for understanding; if it is, it writes normally; if it is a secondary or marginal teaching moment, it defers rather than produce a shallow entry. This is a preference, not a hard filter — agents never suppress a genuinely important teaching moment because it falls outside the focus list.

---

## 6. Non-Functional Requirements

### NFR-001: Default-Off Invariant

When `learn/config.json` is absent, or when `enabled` is `false`, or when the file is unparseable, every agent's response must contain none of the following learning-mode artifacts:

- No `## Learning:` sections appear in agent responses.
- No `[Learning Note]` markers appear.
- No files under `learn/knowledge/` are created or modified.
- No reads of `learn/preamble.md` occur.

This is the load-bearing claim of the feature. It is enforced by three deterministic preconditions, not by output-equivalence assertion against agent responses (LLM outputs are non-deterministic; golden-file regression against them degrades to flaky tests):

1. `disable-model-invocation: true` on `.claude/skills/learn/SKILL.md`.
2. A guard branch in every learning-aware agent prompt that reads `config.json` and skips all learning steps when absent or disabled.
3. `learn/knowledge/` and `learn/config.json` are gitignored so that artifacts from accidental activation do not leak into commits.

All three are verified by `scripts/check-learn-invariants.sh` on every PR. The script uses grep-based static checks; no LLM is in the loop.

### NFR-002: No Gating UX

Learning annotations and knowledge enrichment must never block, delay, or precede the primary deliverable. The artifact — code, design document, review, security report — is always the first substantive content in any response. Learning sections always follow. The developer is not prompted to acknowledge, confirm, or respond to learning content before the next agent invocation. No pre-response quizzes or comprehension checks.

### NFR-003: Depth-Appropriate Explanation

There are no arbitrary caps on entry length, entry count, or token count for learning content. The governing principle is: as systematic and complete as the concept requires, as specific to the code in front of the agent as possible. An explanation that omits the "when not to use this" case to stay under a length cap is worse than a longer explanation that includes it.

What is not permitted is length without load: verbose recaps of the artifact content in prose, repetition of content already in the domain file, or explanatory filler that the developer would skip. Length is earned by substance.

### NFR-004: Severity Preservation

The code-reviewer's Learning Mode output must not soften, hedge, qualify, or dilute severity labels on findings. CRITICAL means CRITICAL at all three levels. A Learning Note that explains why a CRITICAL finding is CRITICAL is permitted and encouraged at `junior` level; that explanation does not change the severity label. The Learning section is additive to the finding, not a replacement or a softening gloss on it.

### NFR-005: Non-Destructive Editing Under Pressure

An agent that encounters an outdated or superseded entry must apply the `correct` operation — mark superseded, write corrected version below — rather than overwrite silently. An agent must never delete prior content from a domain file. An agent must never summarize or compress prior entries to reclaim space. Superseded entries accumulate with their markers. This is the design, not a constraint to optimize around.

### NFR-006: Human-Readable Markdown, Organized by Concept

Domain files are standard Markdown. No proprietary format. Organization is by concept (H2 section headings = concept names), never by date or session. A developer opening `testing-discipline.md` six months from now should encounter a coherent reference text organized by subject matter, not a chronological log.

### NFR-007: Serialization for Overlapping Domain Writes

When the orchestrator delegates to two or more agents in a single workflow, and both agents have Learning Domains that overlap, the orchestrator runs them sequentially rather than in parallel for the knowledge-writing phase. When Learning Domains do not overlap, parallel execution is permitted. This preserves the read-modify-write invariant for the knowledge base. The serialization rule is encoded in the orchestrator's agent prompt.

---

## 7. Knowledge Layer Specification

Learning Notes and domain file entries draw from three tiers of knowledge. Agents use the most specific applicable tier. Citations must be verifiable by the developer.

### Tier 1: External Canonical Documentation

Links to official documentation, language specifications, well-known named patterns (Martin Fowler's patterns catalog, Gang of Four, OWASP, RFC specifications, framework official docs). A contribution citing Tier 1 must include a URL or a named pattern that is verifiable by the developer. Tier 1 is preferred when the decision is a well-established convention that predates this codebase.

Freshness constraint: agents must not synthesize new canonical documentation from training data when a specific external URL is available. If the URL might be stale, the agent notes the retrieval date or flags it as a reference to verify. Stale or fabricated citations are worse than no citation.

### Tier 2: Project ADRs

Records in `docs/en/adr/`. A contribution citing Tier 2 must reference the ADR by number and short title (e.g., "ADR-007: use-option-over-null"). Agents must not generate a Tier 2 citation for an ADR that does not exist. If the decision has not been formally recorded, the agent may note that the reasoning is local convention and flag it as a candidate for an ADR.

### Tier 3: Prior Domain Knowledge

Entries already in `learn/knowledge/` from prior sessions. An agent may reference a prior domain knowledge entry when a concept was already introduced and the current session adds a nuance or a cross-reference. Tier 3 is the lowest authority; it is used to build on what exists rather than to establish new claims. Cross-references use relative Markdown links.

### What Must Not Be Generated

- A `docs/learn/` directory tree of any kind beyond the read-only examples at `docs/en/learn/examples/`.
- Generated wiki pages, learning modules, or curriculum files.
- Any file outside `learn/` produced by a learning operation (domain files are under `learn/knowledge/`; preamble and config are under `learn/`). The Skill itself remains in `.claude/skills/learn/`.
- Inline educational comments added to production code files solely for pedagogical purposes.
- Session-specific context in domain files ("we were debugging the cache miss when..."). Domain files contain extracted principles, not session logs.

---

## 8. Default-Off Invariant

### The Guarantee

When `learn/config.json` is absent, or when the file has `"enabled": false`, or when the file is not valid JSON, the agent response for any prompt contains none of the learning-mode artifacts defined in NFR-001: no `## Learning:` sections, no `[Learning Note]` markers, no writes to `learn/knowledge/`.

This is a claim about agent-prompt logic, not about byte-level output equivalence. LLM output is non-deterministic across runs, model versions, and prompt compaction events. Any attempt to hash agent responses against golden files will flake and be disabled. The design addresses this by placing the invariant's enforcement into deterministic, LLM-free checks rather than into output comparison.

### Enforcement

Three deterministic preconditions enforce the invariant. All three are checked by `scripts/check-learn-invariants.sh` on every PR.

1. **Skill flag check.** `.claude/skills/learn/SKILL.md` contains `disable-model-invocation: true`. This prevents the model from flipping `enabled: true` on the user's behalf. One line of grep.

2. **Agent guard-branch check.** Every file under `.claude/agents/` that declares a `## Learning Domains` section also contains the guard-branch text — reading `config.json`, skipping all learning steps when absent or disabled. One regex per agent file.

3. **Gitignore posture check.** `.gitignore` ignores `learn/knowledge/` and `learn/config.json`. `.gitignore.example` contains the opt-in inversion comment block. Two greps.

If any of the three fails, the CI job fails and the PR cannot merge.

### Design goals verified by PR review

Three additional properties are design goals rather than automated checks. Attempting to test them against agent output would hit the same non-determinism problem. They are enforced by reviewer inspection when a PR touches `learn/preamble.md` or agent prompts:

- **Non-destructive editing.** A `deepen` operation preserves the original section byte-for-byte and appends rather than interleaves. A `refine` operation keeps the original as a superseded block. A `correct` operation leaves the superseded text visible below the marker.
- **Supersession history.** Multiple `correct` operations on the same section accumulate with markers; no version is silently dropped.
- **Severity preservation.** A CRITICAL code-reviewer finding stays CRITICAL at every level.

These are spelled out in `learn/preamble.md` and in the code-reviewer agent prompt. Reviewers enforce them when a change touches those files.

---

## 9. Acceptance Criteria

All criteria must be satisfied for this feature to be considered shippable. The criteria are QA-runnable.

### Skill and Configuration

- [ ] `/learn on junior` creates `learn/config.json` with `enabled: true`, `level: "junior"`, `focus_domains: []`, and a valid `updatedAt` timestamp.
- [ ] `/learn off` sets `enabled: false` in config; subsequent agent responses in the same session contain no `## Learning:` sections.
- [ ] `/learn status` reports enabled state, level, focus_domains, and last-ten diff summaries without modifying any file.
- [ ] A missing or malformed `config.json` is treated as disabled; no error is surfaced to the developer; subsequent agent behavior is unchanged from no-learning-mode behavior.
- [ ] `/learn on` without a level argument uses the previously stored level; if no level is stored, defaults to `junior`.
- [ ] `/learn level senior` changes the level field in config without changing the `enabled` field.
- [ ] `/learn focus architecture,testing-discipline` sets `focus_domains: ["architecture", "testing-discipline"]` in config.
- [ ] `/learn focus clear` resets `focus_domains` to `[]`.
- [ ] `/learn domain new observability` prompts for confirmation, creates `learn/knowledge/observability.md` with seed content after confirmation.

### All-Agent Coverage

- [ ] Every agent file in `.claude/agents/` has a `## Learning Domains` section at the top of its prompt body.
- [ ] A session invoking the architect produces at least one domain file enrichment in `architecture.md` or `api-design.md` when a non-trivial design decision is involved.
- [ ] A session invoking the security-reviewer produces at least one enrichment in `security-mindset.md` when a security finding is present.
- [ ] A session invoking the devops-engineer produces at least one enrichment in `operational-awareness.md` or `release-and-deployment.md` when a deployment pattern is used.
- [ ] A session invoking the market-analyst at `junior` level produces an enrichment in `market-reasoning.md`.
- [ ] A session invoking the technical-writer produces an enrichment in `documentation-craft.md`.

### Enrichment Operations

- [ ] An `add` operation on a new concept creates a new H2 section; no existing section is touched.
- [ ] A `deepen` operation on an existing section appends content below the existing text; the existing text is byte-for-byte unchanged.
- [ ] A `correct` operation marks the prior entry with `> Superseded YYYY-MM-DD: <reason>` and appends the corrected version below it; the superseded text remains in the file.
- [ ] A `refine` operation produces a `Prior Understanding (revised YYYY-MM-DD)` block with the prior phrasing and the new phrasing in the active position.
- [ ] No enrichment operation deletes any content from a domain file.
- [ ] An agent proposes a new domain via the diff report; it does not auto-create a domain file without `/learn domain new <key>` confirmation.

### Knowledge Diff Report

- [ ] After any enrichment, the agent response ends with `## Learning: taught this session` and `## Learning: knowledge diff` sections.
- [ ] The diff report names the domain file, the operation, the section heading, and a one-sentence change summary.
- [ ] The diff report does not appear when Learning Mode is off.
- [ ] The diff report does not appear when `/quiet` was issued for that invocation.

### Levels

- [ ] A `junior`-level architect response on a non-trivial design task includes a full first-principles explanation of the pattern applied in the response's teaching sections.
- [ ] A `senior`-level implementer response on a task with no non-default choices contributes zero notes (both in the response and in the diff report).
- [ ] A `mid`-level code-reviewer response explains a non-obvious convention finding; a routine formatting finding has no learning content.
- [ ] Learning content adjusts angle and density across levels without changing the correctness or completeness of the primary artifact.

### Anti-Patterns

- [ ] No learning content contains affirmation language ("Great question", "Well done", "Excellent work").
- [ ] No learning content is phrased as a quiz or question directed at the developer.
- [ ] No learning content restates the artifact in prose without adding reasoning.
- [ ] A CRITICAL code-reviewer finding is labeled CRITICAL at all three levels; no learning section softens or qualifies the label.
- [ ] No learning-related knowledge file is created outside `learn/knowledge/`.
- [ ] No educational inline comment is added to a production code file.

### Per-Session Suppression

- [ ] `/quiet` suppresses the `## Learning:` sections and the knowledge diff for the immediately following invocation; the next invocation resumes normal behavior.
- [ ] `/quiet` does not modify `config.json`.

### Default-Off Enforcement

- [ ] `scripts/check-learn-invariants.sh` asserts `disable-model-invocation: true` in `.claude/skills/learn/SKILL.md`.
- [ ] `scripts/check-learn-invariants.sh` asserts every `.claude/agents/*.md` file that declares a `## Learning Domains` section also contains the guard-branch reference to `config.json`.
- [ ] `scripts/check-learn-invariants.sh` asserts `.gitignore` contains entries for `learn/knowledge/` and `learn/config.json`.
- [ ] The script runs in CI on every PR and fails the build if any check fails.

### Git and Privacy

- [ ] `.gitignore` includes entries that exclude `learn/knowledge/` and `learn/config.json`.
- [ ] The repository includes a `.gitignore.example` or comment block showing the lines to modify to opt in to committing knowledge files.
- [ ] The README documents the default-private and opt-in-shared paths without editorializing.

### CLAUDE.md

- [ ] `.claude/CLAUDE.md` contains a `## Developer Learning Mode` section.
- [ ] The section names `config.json`, `preamble.md`, and the `/learn` Skill.
- [ ] No agent prompt instructions for Learning Mode appear in CLAUDE.md.
- [ ] The section is the only learning-mode content in CLAUDE.md.

---

## 10. Success Metrics

These metrics are observable without instrumentation inside agent internals. Vanity metrics (session count, knowledge-impression count, `/learn on` invocation rate) are excluded.

| Metric | Measurement Method | Target |
|--------|--------------------|--------|
| Agent-output modify rate | Fraction of sessions where the developer edits agent-generated code within a few minutes of receipt (proxy: file diff on agent-touched files in rapid succession). A lower rate suggests less reflexive copy-paste. | 10% reduction at 60 days versus baseline for Learning Mode users. |
| Reasoned push-back rate | Count of session turns where the developer challenges an agent decision by name ("why repository pattern here?" not "I don't like this"). Higher rate indicates learning notes are prompting engagement with reasoning, not just output. | 15% increase in named-pattern push-backs at 30 days for Learning Mode users at `junior` or `mid` level. |
| Pattern-name active use | Count of sessions where the developer independently uses a pattern name introduced in the same session in a later prompt in that session. Indicates the names are being internalized. | At least 25% of `junior`-level sessions contain at least one pattern-name reuse by session end. |
| Recurrence rate | Fraction of code-reviewer findings that appear in the same file within 14 days. A lower rate for findings with associated learning content suggests the explanations are being acted on. | 20% reduction in recurrence at 60 days for CRITICAL and HIGH findings that had a learning note. |
| Knowledge file growth quality | Size and section-count trend per domain file across sessions. Growing section count with stable depth-per-section indicates the knowledge base is accumulating concepts rather than bloating. | Each active domain file shows at least one new top-level section per five sessions. |

---

## 11. Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| A learning note fabricates a citation — cites an ADR that does not exist or misquotes a named pattern. | Medium — model hallucination is a known risk for citation-heavy tasks. | High — a wrong citation is worse than no citation; it builds incorrect mental models. | The preamble explicitly forbids fabricated ADR citations. Agents must verify that an ADR file exists before citing it by number. For external sources, the agent cites by named pattern rather than URL when the URL is not directly accessible; the developer is expected to verify. Fabricated citations are treated as defects and block merge. |
| Non-destructive editing fails under pressure — an agent rewrites or compresses prior content to save space. | Medium — agents under cost pressure may optimize for brevity. | High — silent loss of prior understanding breaks the supersession-with-history model. | The preamble forbids rewrites of prior content. PR reviewers check the property whenever `learn/preamble.md` or agent prompts change. The `correct` operation is the only sanctioned mechanism for changing a prior entry; it always preserves the original. |
| Guard-branch marker in an agent prompt is removed or edited in a way that breaks the grep check. | Medium — refactoring of agent prompts is routine. | High — the default-off invariant would silently break. | `scripts/check-learn-invariants.sh` fails the PR. The script's grep pattern is simple and stable; if a legitimate refactor needs to change it, the script is updated in the same PR and the reviewer checks that the new pattern still matches all fifteen agents. |
| Two agents in the same workflow write to the same domain concurrently — the second write overwrites the first. | Medium — parallel agent execution is common in the orchestrator's delegation pattern. | Medium — lost enrichment is visible in the diff report but may not be caught until review. | The orchestrator serializes learning-writing agents when their Learning Domains overlap. The session contract's diff report makes lost operations visible in the same response. If serialization fails, the learner can ask the agent to retry the enrichment. |
| Domain files grow large enough that agents load too much context per session when Learning Mode is on. | Medium — a mature project with 50+ sessions will produce domain files of meaningful size. | Low-Medium — large domain files slow agent reads and increase context cost. The feature is opt-in, so this cost is known. | The technical-writer's `/learn review` command triggers a reorganization proposal when a file exceeds the split threshold (see Open Questions). Content-contributing agents flag the threshold in the diff report rather than splitting unilaterally. |

---

## 12. Open Questions

The following questions are not decided by this PRD. Each is a candidate for a follow-on ADR or a future iteration. Items marked `[PRD-scope]` affect functional or non-functional requirements in this document and would require PRD amendment if resolved. Items marked `[ADR-scope]` are architectural and should be resolved in a follow-on ADR.

1. **When should a domain file be split?** `[ADR-scope]` The ADR's tentative position is 1200 lines or 8 top-level sections, whichever comes first, triggered by the technical-writer on demand via `/learn review`. This PRD defers to that position but does not formalize the threshold as a requirement until the ADR resolves it.

2. **Should market-analyst and monetization-strategist write to `market-reasoning.md` and `business-modeling.md`?** `[CLOSED]` Resolved in favor of full participation. Both the taxonomy (ownership matrix, ✓ on their respective primary domains) and ADR-001 (Decision 1: all fifteen agents are learning-aware from release; per-agent table assigns market-analyst → `market-reasoning` primary and monetization-strategist → `business-modeling` primary) confirm these agents write to their matching domains. FR-006 reflects this. No further escalation needed.

3. **Should the knowledge directory be committed by default or gitignored by default?** `[CLOSED]` Resolved as gitignore-by-default. ADR-001 Decision 4 and ADR-003 both state this unambiguously. FR-009 of this PRD reflects the same stance. The `.gitignore.example` opt-in path is the mechanism for teams that want shared knowledge files. No further escalation needed.

4. **How does level change mid-project affect existing domain knowledge files?** `[ADR-scope]` Tentative position per ADR: new contributions follow the new level; existing entries are not rewritten. The foundational scaffolding from `junior` sessions remains and is layered by `senior` refinements. This PRD inherits that position.

5. **Interaction with parallel agent execution.** `[ADR-scope]` The serialization rule for overlapping Learning Domains is specified in NFR-007 of this PRD and in the ADR. Verification that the orchestrator correctly detects domain overlap before dispatch is an implementation concern; the mechanism for overlap detection is not yet specified.

6. **i18n of Learning Notes.** `[PRD-scope]` Knowledge files are English-only in this release. For teams whose primary working language is not English, this limits effectiveness. Machine translation is not addressed here; it is explicitly out of scope.

7. **Interaction with existing CI hooks.** `[ADR-scope]` The project's `PostToolUse` hooks run linting and type-checking after edits. Learning Mode writes to `learn/knowledge/` domain files. Those files are Markdown; the existing ESLint/TypeScript hooks do not run on Markdown. No conflict is anticipated, but it is not verified.

---

## 13. Out of Scope for This Release

The following items are explicitly deferred. They are named here to prevent scope creep during implementation.

- Any sharing or export feature for domain knowledge files (exporting to a gist, publishing to a team wiki, syncing across repositories).
- Multi-user knowledge file merging or collaboration on domain files.
- Progress scoring, learning completion markers, concept mastery indicators, or any form of gamification.
- Automatic level inference from session content, commit history, or behavioral signals of any kind.
- Translation or localization of Learning Notes or domain knowledge files.
- A structured curriculum, lesson plan, or sequenced concept progression across sessions.
- A UI viewer or summary command for domain knowledge files beyond `/learn status`.
- Retroactive annotation of prior session output.
- Integration with external LMS systems, team analytics dashboards, or reporting tools.
- Japanese translation of domain knowledge files (`docs/ja/learn/knowledge/` does not exist in this release).
- Suppression of learning annotations in CI environments (annotations only appear in interactive agent responses; this is assumed, not specified).
- A `/learn review` command for technical-writer-triggered reorganization (described in ADR open questions; not implemented in this release).

---

## 14. Rollout Plan

The owner's intent is a clean release, not adoption maximization. The plan below reflects that.

### Phase 1: Dark

Ship the feature with the default-off invariant verified by CI. Present in repositories derived from the template from the first clone: the `/learn` Skill at `.claude/skills/learn/SKILL.md`, the `/quiet` companion Skill at `.claude/skills/quiet/SKILL.md`, and the enrichment contract at `learn/preamble.md`. No domain files are pre-seeded; `learn/knowledge/` is empty and gitignored. CLAUDE.md contains the pointer block. `scripts/check-learn-invariants.sh` runs in CI and passes for all three checks (Skill flag, agent guard branches, gitignore posture).

Created at runtime on the learner's first `/learn on` invocation: `learn/config.json` only. Domain files under `learn/knowledge/<key>.md` are created lazily on first teaching moment per domain, or on explicit `/learn domain new <key>` confirmation for custom domains.

Both `learn/config.json` and `learn/knowledge/` are gitignored by default. The shipped `learn/preamble.md` is not hidden from the repository — it is part of the template — but any knowledge a learner accumulates stays local unless the learner inverts the gitignore entry.

The feature is available to any developer who runs the Skill. It is not mentioned in release notes beyond the ADR and PRD existing in the repository.

### Phase 2: Available

Release the v2.0.0 breaking version containing the feature. The changelog records the feature and the breaking change. The repository is the documentation. Developers who discover the Skill via CLAUDE.md or direct invocation can use it. No feature flag. No staged rollout by user segment. This is a template repository; every fork benefits immediately from the next version when they update their template reference.

The goals of Phase 2 are: confirm that no default-off regressions surface in real usage, and confirm that the enrichment protocol behaves as specified on real projects.

### Phase 3: Documented

After Phase 2 signal is clean — no default-off regressions, no open CRITICAL issues from the open-questions list, at least one real project using Learning Mode for several weeks — add a section to `docs/en/template-usage.md` describing the feature and its three levels. Add a corresponding Japanese translation in `docs/ja/`. Add a more prominent mention in README.md.

No changes to the feature itself are required for Phase 3. The announcement is documentation only.

Forks that were on v1.x and had enabled the feature should follow the migration guide at `docs/en/migration/v1-to-v2.md` to move their knowledge files from `.claude/growth/notes/` to `learn/knowledge/`.
