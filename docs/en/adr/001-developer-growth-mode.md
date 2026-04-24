# ADR-001: Developer Growth Mode (Domain-Organized Living Notebook)

## Status

Proposed (stabilized). Supersedes earlier drafts of this ADR per owner decisions recorded 2026-04-22.

> **Partially superseded 2026-04-24 by [ADR-003](003-learning-mode-relocate-and-rename.md):** the directory layout (`.claude/growth/notes/` → `learn/knowledge/`), the feature name ("Growth Mode" → "Learning Mode"), the Skill command (`/growth` → `/learn`), and the terms "notes/notebook" → "knowledge" are revised in ADR-003. The architectural substance (levels, enrichment contract, trailers, default-off invariant) remains governed by this ADR.
>
> **Note on links below.** The Metadata section and body of this ADR intentionally preserve their v1.x path references (`docs/en/prd/developer-growth-mode.md`, `docs/en/growth/domain-taxonomy.md`, `docs/en/growth-mode-explained.md`, `scripts/check-growth-invariants.sh`, etc.) as a historical record. Those files were renamed in v2.0.0 per ADR-003; use the current paths in [ADR-003](003-learning-mode-relocate-and-rename.md) or [docs/en/index.md](../index.md) to navigate to the live equivalents.

## Metadata

- Date: 2026-04-22
- Revised: 2026-04-22 — toggle moved to a Skill, notes gitignored by default, taxonomy stabilized at 19 canonical domains (added `ui-ux-craft` so ui-ux-designer has a primary domain that matches its craft rather than being force-fit into `api-design`), length-budget language removed, every agent assigned at least one primary domain.
- Deciders: Agent Team, with owner decisions recorded in Context
- Related: [docs/en/prd/developer-growth-mode.md](../prd/developer-growth-mode.md), [docs/en/growth/domain-taxonomy.md](../growth/domain-taxonomy.md) (canonical taxonomy — authoritative for domain list and ownership matrix), [docs/en/adr/002-growth-domains-location.md](002-growth-domains-location.md) (refines the Growth Domains declaration location — body section, not frontmatter)
- Learner-facing explainer: [docs/en/growth-mode-explained.md](../growth-mode-explained.md) — long-form prose walkthrough of what learners see when Growth Mode is on
- Prior drafts of this ADR framed Growth Mode as (a) an annotation layer with length caps, (b) an append-only journal, and (c) a custom slash-command toggle. All three framings are superseded by the decisions below.

## Context

The template ships a 15-agent team that produces finished artifacts — PRDs, architecture, code, tests, reviews, deployment plans — without making the reasoning behind each artifact visible to the person reading them. A learner using the template to build a real project sees the output but not the thinking. Growth Mode exists to expose that thinking as an opt-in layer without degrading the default experience for users who want the agents to just produce output.

Three owner decisions landed on 2026-04-22 and reshape the architecture. They are quoted faithfully below and drive every section that follows.

### Decision 1 — All fifteen agents are growth-aware from release

Every agent in `.claude/agents/` ships with a growth contract and with at least one primary domain. There is no subset, no "deferred" list, and no agent has an empty Growth Domains list. The feature ships with all fifteen agents wired to the taxonomy, or it does not ship.

### Decision 2 — Depth over brevity; no length budget

Contributions are as systematic as the concept requires and as specific as the code in front of the agent. There are no length caps — no token budgets, no note counts, no sentence limits. The constraint is relevance: notes must be load-bearing for understanding. Length follows from the concept, not from a budget. Agents are still bound by quality rules (non-destructive edits, no softening severity), but not by length floors or ceilings.

### Decision 3 — Notes are a living, organized knowledge base

Each time an agent is invoked, it provides the knowledge needed for that session and records what it taught and what the learner was taught. Notes are not appended blindly at the end — they are systematically organized, fleshed out, and over many sessions become a reference organized by domain.

Impact: the single `journal.md` file is replaced with a directory of per-domain note files. A session does not append a new chronological entry; it opens the file for the relevant domain and either adds a new section, deepens an existing section, refines an older entry as understanding matures, or establishes a new domain if truly new territory. The end state after many sessions is a personalized textbook the learner built by shipping real features — navigable by domain, not by date.

### Decision 4 — Notes are gitignored by default; sharing is opt-in

`.claude/growth/notes/` and `.claude/growth/config.json` are both gitignored out of the box. A learner consciously opts in to share notes when they want a team-level textbook; individual growth is not broadcast by default. Rationale in the Decision section below.

### Decision 5 — The toggle is a Skill, not a custom Command

In current Claude Code, Skills and Commands have merged and Skills are canonical for new work. The `/growth` toggle ships as a Skill at `.claude/skills/growth/SKILL.md` with `disable-model-invocation: true` so the user — not the model — controls when Growth Mode turns on. Rationale in the Decision section below.

### Why these decisions reshape the architecture

Decision 3 is the structural one. A journal is write-once and chronological; a living notebook is read-modify-write and organized. Every agent invocation participates in a structured edit cycle against shared files rather than emitting a one-shot annotation. Decision 1 multiplies that cycle by fifteen agents, which means the edit protocol has to be robust enough that any agent can safely modify any domain file it owns without stepping on another agent's concurrent work in the same session. Decision 2 means each edit can be as thorough as the concept demands, so the agents' contributions are substantive paragraphs and worked examples rather than one-liners. Decision 4 makes the notebook private by default, which aligns with the owner's stated philosophy ("I am not optimizing for user acquisition; I built this for myself") and with the nature of the material — notes contain mistakes, prior understanding, and revision history, which is private learning material. Decision 5 makes the toggle a first-class user gesture rather than a model-invokable action, which is essential: Growth Mode changes agent behavior across every subsequent turn, and the learner must be the one who chooses that. Together, these decisions move Growth Mode from an annotation layer to a knowledge-engineering layer with a clear authorship boundary.

## Decision

Ship Developer Growth Mode as a default-off feature with five coordinated elements: a domain-organized notes directory, a canonical taxonomy of nineteen domains owned jointly by the fifteen agents, an enrichment protocol that every growth-aware agent follows for non-destructive edits, a toggle Skill that exposes the on/off switch and per-domain focus preferences under exclusive user control, and a gitignore posture that keeps the notebook private by default with opt-in sharing. The design preserves the default-off invariant — users who never run `/growth on` see no change in behavior, no extra files read, and no extra work performed.

### Notes structure: `.claude/growth/notes/`

The learner's knowledge base lives at `.claude/growth/notes/`, one markdown file per domain. A domain file is a structured reference document organized by sections, not by date. Sections are named for the concept they cover (e.g., `## Repository Pattern`, `## Read Models and Write Models`), not for the session that created them. A section grows in place over multiple sessions; it is never split chronologically.

Directory shape at feature install time:

```
.claude/growth/
├── config.json                 # state: enabled, level, focus_domains, updatedAt (gitignored)
├── preamble.md                 # the enrichment contract every growth-aware agent reads
└── notes/                      # gitignored directory; see .gitignore.example
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

Count note: this ADR ships the nineteen canonical domains defined in [the taxonomy document](../growth/domain-taxonomy.md). The learner may open additional custom domains at runtime via `/growth domain new <key>`; those land in the same directory and follow the same shape.

Each seed file contains a YAML front matter block (title, domain key, owning agents, last-updated timestamp) and one placeholder section so agents know the expected shape when they arrive.

#### Realistic tree after ten sessions on a Flutter project

The Flutter-specific entries appear inside the ecosystem-agnostic files rather than as separate files. New custom domains only appear when the learner asks for a topic that genuinely does not fit the seed taxonomy.

```
.claude/growth/notes/
├── architecture.md             # + Riverpod providers as DI seams, + clean architecture boundaries in Dart
├── api-design.md               # + Dio interceptors vs plain http, + freezed for DTOs
├── data-modeling.md            # + immutable value classes with freezed, + union types for state
├── persistence-strategy.md     # + Drift vs Isar trade-offs, + local-first sync conflicts
├── error-handling.md           # + Result types in Dart, + sealed classes for failure modeling
├── testing-discipline.md       # + widget tests vs integration tests, + pump/pumpAndSettle semantics
├── concurrency-and-async.md    # + Future vs Stream, + isolate communication model
├── ecosystem-fluency.md        # + null safety idioms, + build_runner conventions, + pub.dev workflow
├── dependency-management.md    # + pubspec version constraints, + workspace refs in a monorepo
├── implementation-patterns.md  # + early-return guards in build methods, + StateNotifier patterns
├── review-taste.md             # + rebuild-cost heuristics, + const constructor discipline
├── security-mindset.md         # + secure storage plugin trade-offs, + platform channel surface risks
├── performance-intuition.md    # + frame budget, + shader warm-up, + RepaintBoundary placement
├── operational-awareness.md    # + Firebase console signals, + crashlytics triage
├── release-and-deployment.md   # + flavors, + Fastlane lanes, + Play/App Store review heuristics
├── market-reasoning.md         # + mobile app-store discovery signals, + category positioning
├── business-modeling.md        # + subscription vs one-off IAP trade-offs, + platform fee math
├── documentation-craft.md      # + dartdoc conventions, + worked-example pattern for widget APIs
├── ui-ux-craft.md              # + Material 3 spacing scale, + Cupertino vs Material decision notes, + reduce-motion handling
└── state-management.md         # custom domain opened by the learner in session 4
```

#### Realistic tree after ten sessions on a Go backend project

```
.claude/growth/notes/
├── architecture.md             # + hexagonal ports and adapters in Go, + wire for DI
├── api-design.md               # + chi router vs net/http, + request validation layer
├── data-modeling.md            # + aggregate boundaries, + repository seam placement
├── persistence-strategy.md     # + sqlc vs gorm trade-offs, + indexing for common queries
├── error-handling.md           # + errors.Is/As, + sentinel errors vs wrapped errors
├── testing-discipline.md       # + table-driven tests, + subtests, + httptest patterns
├── concurrency-and-async.md    # + goroutine lifecycle, + errgroup, + channels as signals vs queues
├── ecosystem-fluency.md        # + interfaces accepted small, + return concrete types, + idiomatic error wrapping
├── dependency-management.md    # + go mod vendor, + replace directives during migration
├── implementation-patterns.md  # + functional options, + named return values, + early return over nesting
├── review-taste.md             # + error wrapping cadence, + context propagation
├── security-mindset.md         # + sql.NullString vs pointers, + context cancellation leaking secrets
├── performance-intuition.md    # + allocation profiling, + sync.Pool when justified
├── operational-awareness.md    # + structured logs with slog, + liveness vs readiness semantics
├── release-and-deployment.md   # + multi-stage Dockerfiles, + distroless base images, + graceful shutdown
├── market-reasoning.md         # + B2B backend buyer signals, + infra-vendor landscape notes
├── business-modeling.md        # + usage-based pricing math, + cost-to-serve vs contract value
├── documentation-craft.md      # + godoc examples as tests, + README-driven endpoint docs
├── ui-ux-craft.md              # placeholder — this Go backend has no user-facing UI, so the file stays near-empty
└── observability.md            # custom domain opened by the learner when tracing was introduced
```

The domain files are identical in name across ecosystems; the content inside each file is ecosystem-specific. This is the point — the learner carries a stable mental model across stacks, and the notebook teaches them how the same domain plays out in the language they happen to be in.

### Domain taxonomy

Eighteen canonical domains ship seeded. They are ecosystem-agnostic in name and specific in intent, so they apply equally to a Flutter app, a Go service, a Rails monolith, or a Python data pipeline.

| Domain key | What belongs here |
|------------|------------------|
| `architecture` | System structure, module boundaries, layering, seams for replacement, dependency inversion, aggregate design |
| `api-design` | Resource modeling, versioning, error envelopes, idempotency, pagination, contracts |
| `data-modeling` | Entity design, relationships, normalization trade-offs, temporal data, state machines, aggregate boundaries |
| `persistence-strategy` | Database technology choice, schema design, indexing, query patterns, transactions, consistency models |
| `error-handling` | Error propagation, boundary crossing, user-facing vs logged messages, retries, recovery strategies |
| `testing-discipline` | Test pyramid, fixture hygiene, AAA structure, mocking vs integration, coverage trade-offs, flake diagnosis |
| `concurrency-and-async` | Race conditions, back-pressure, cancellation, reentrancy, lifecycle of concurrent units |
| `ecosystem-fluency` | Language idioms, toolchain workflow, framework patterns, the non-obvious conventions of the stack. Distinct from `dependency-management`: this holds language and toolchain idioms; `dependency-management` holds package pinning, lockfile strategy, and supply-chain hygiene. |
| `dependency-management` | Package pinning, lockfiles, supply-chain hygiene, upgrade cadence, transitive risk |
| `implementation-patterns` | Code organization within modules, helper extraction, control flow, naming, refactoring heuristics, code smells |
| `review-taste` | What a senior notices on a diff that a junior misses; style and invariants; smell detection |
| `security-mindset` | Input validation at boundaries, secrets handling, authz design, threat modeling, OWASP-aligned heuristics |
| `performance-intuition` | Bottleneck prediction, profiling discipline, algorithmic vs systemic wins, caching trade-offs |
| `operational-awareness` | Runtime behavior, logging, metrics, health checks, graceful degradation, incident response |
| `release-and-deployment` | Build pipelines, deployment strategies, rollbacks, feature flags, environment parity |
| `market-reasoning` | Competitive landscape reading, user-segment modeling, demand signals, positioning trade-offs |
| `business-modeling` | Pricing architecture, unit economics, revenue recognition patterns, monetization trade-offs |
| `documentation-craft` | Reference vs tutorial vs explainer shape, worked-example discipline, audience modeling, changelog hygiene |

The learner may open custom domains at any time via `/growth domain new <key>`. Custom domains live under `.claude/growth/notes/<key>.md` with the same shape.

### The enrichment protocol

Every growth-aware agent, when it has a teaching moment, follows a five-step contract against the target domain file. The contract is defined once in `.claude/growth/preamble.md` and followed by all fifteen agents.

1. **Identify the target domain.** The agent maps the teaching moment to a domain key it owns (see the per-agent mapping below). If the teaching moment spans two domains, the agent picks the one where the concept is most foundational and cross-links from the other. If no existing domain fits and the concept is genuinely new territory, the agent proposes a new domain with a rationale; the learner confirms via `/growth domain new <key>` before the file is created. Agents never auto-create domain files without that confirmation.
2. **Read the current domain file.** The agent reads the existing file before deciding how to contribute. This is non-negotiable — a contribution that ignores what is already there fragments the knowledge base. Reading is how agents avoid duplicating a section or contradicting an earlier entry without marking the supersession.
3. **Decide the operation.** One of:
   - **Add** — create a new top-level section for a concept not yet present in this domain.
   - **Deepen** — append to an existing section with a new example, a caveat, an edge case, or a cross-reference.
   - **Refine** — tighten the phrasing of an existing entry or improve an example without changing the claim.
   - **Correct** — mark a previous entry superseded and write the corrected understanding below it. The superseded text is never deleted; it remains with a `> Superseded YYYY-MM-DD: <reason>` marker above it so the learner can see how their understanding evolved.
   - **New domain** — only after learner confirmation per step 1.
4. **Apply the change non-destructively.** The agent rewrites the file with its change integrated. Existing headings, examples, and code blocks outside the change surface are preserved byte-for-byte. No entry is ever removed — superseded entries stay visible with their marker. If the file has grown past the organization threshold (see Open Questions on splitting), the agent flags it for reorganization rather than reorganizing unilaterally.
5. **Report the diff.** The agent reports, at the end of its response, the domain key, the section heading touched, the operation name, and a one-sentence summary of what changed. This is the teaching-provenance record the learner uses to audit how their notebook is evolving.

The organizing principle is that files are organized by concept, never by date. A session does not get its own section; its contributions are folded into the concept sections that already exist, or open new concept sections. The audit trail of when a change happened lives in git history and in the per-response diff report — not in the file structure itself.

### Per-agent growth responsibility

Every agent declares one or more domains it owns. Ownership is not exclusive — multiple agents can write into the same domain — but each agent is expected to be the primary contributor to the domains listed as primary under its name. Ownership is encoded in each agent's YAML frontmatter as a `## Growth Domains` section, with primary domains listed first.

Every one of the fifteen agents has at least one primary domain. No agent ships with an empty Growth Domains list. The ownership matrix below is the authoritative mapping for this ADR and is reconciled against [the taxonomy document](../growth/domain-taxonomy.md) — if any row drifts from the taxonomy, the taxonomy is the source of truth.

| Agent | Primary domains | Secondary domains |
|-------|-----------------|-------------------|
| orchestrator | `release-and-deployment` (delegation as release-path discipline) | `architecture`, `api-design` |
| product-manager | `api-design` (product-requirements angle — how a requirement shapes a contract) | `architecture`, `data-modeling`, `review-taste`, `release-and-deployment`, `market-reasoning` |
| market-analyst | `market-reasoning` | `business-modeling` |
| monetization-strategist | `business-modeling` | — |
| ui-ux-designer | `ui-ux-craft` (visual hierarchy, typography, accessibility, interaction patterns) | `api-design`, `architecture`, `implementation-patterns`, `performance-intuition` |
| docs-researcher | `ecosystem-fluency` | `dependency-management` |
| architect | `architecture`, `api-design`, `data-modeling` | `persistence-strategy`, `error-handling`, `ecosystem-fluency`, `dependency-management`, `security-mindset` |
| implementer | `error-handling`, `concurrency-and-async`, `ecosystem-fluency`, `implementation-patterns` | `architecture`, `api-design`, `data-modeling`, `persistence-strategy`, `testing-discipline`, `review-taste`, `security-mindset`, `performance-intuition`, `operational-awareness` |
| code-reviewer | `testing-discipline`, `implementation-patterns`, `review-taste`, `security-mindset` | `architecture`, `api-design`, `data-modeling`, `persistence-strategy`, `error-handling`, `concurrency-and-async`, `ecosystem-fluency`, `performance-intuition` |
| test-runner | `testing-discipline`, `performance-intuition` | `error-handling`, `implementation-patterns`, `review-taste`, `security-mindset` |
| linter | `implementation-patterns` | `testing-discipline`, `ecosystem-fluency`, `review-taste`, `security-mindset` |
| security-reviewer | `security-mindset` | `architecture`, `api-design`, `persistence-strategy`, `error-handling`, `testing-discipline`, `dependency-management`, `implementation-patterns` |
| performance-engineer | `concurrency-and-async`, `performance-intuition` | `persistence-strategy`, `testing-discipline`, `implementation-patterns`, `review-taste`, `operational-awareness` |
| devops-engineer | `operational-awareness`, `release-and-deployment` | `persistence-strategy`, `dependency-management`, `security-mindset` |
| technical-writer | `documentation-craft` | — (plus a curator role for the notes directory — reorganization, splitting, section renames — see Implementation Notes) |

When two agents in the same workflow both have a teaching moment that maps to the same domain and section, the enrichment protocol is serialized: the first agent to run completes its read-modify-write cycle, then the second agent starts from the updated file. In practice this means the orchestrator (or the harness) sequences growth-writing agents rather than parallelizing them when they target the same domain. See the Consequences section for how this plays with parallel Task execution.

### Level semantics (junior / mid / senior)

Levels control the angle and density of foundational context — what the agent assumes the learner already knows — not the length of the contribution. The governing phrase is: as systematic as the concept requires; as specific as the code in front of you.

- **junior** — the agent explains from first principles. Introduces vocabulary before using it. Contrasts the chosen approach with the naive alternative a beginner would reach for. Worked examples are expanded; trade-offs are named explicitly; prerequisite concepts are either explained inline or cross-referenced to the domain file that covers them. A junior contribution tends to be a full section with multiple subsections because it is building foundational scaffolding.
- **mid** — the agent assumes first principles but explains the non-obvious. Focuses on the idiomatic: what experienced practitioners of this stack do that a competent engineer switching in from another stack would not guess. Trade-offs are named; alternatives are acknowledged without being exhaustively compared. Mid-level contributions skip the scaffolding but still explain the why.
- **senior** — the agent contributes only when the decision was non-default. The note names the default, names the choice, and explains why the choice was preferred in this context. Senior contributions capture the reasoning that would otherwise stay in the author's head. A senior may write zero contributions in a session where every decision followed the default.

Critically, all three levels write into the same domain files. The notebook does not fork by level. A junior contribution that introduces a concept and a later senior contribution that refines the trade-off framing for the same concept coexist in the same section, with the senior entry as a `Trade-off refinement` subsection underneath. Over time this produces sections that read like a layered textbook: foundations on top, idioms in the middle, trade-offs at the bottom.

Behavior detail: when the same concept is encountered again in a later session at a different level, the agent deepens the existing section rather than duplicating it. A senior-level session that encounters the repository pattern when a junior-level session already explained it contributes a trade-off subsection, not a new explanation of what a repository is.

### Toggle surface: a Skill, not a Command

The toggle ships as a Skill at `.claude/skills/growth/SKILL.md`. In current Claude Code, Skills and Commands have merged; Skills are canonical for new work. Three specific properties of a Skill matter here:

1. **`disable-model-invocation: true`.** Growth Mode can only be toggled by the user, never auto-invoked by the model. This is a first-class invariant of the design, not a stylistic choice. The model learning to turn on its own teaching behavior — deciding on the learner's behalf that "this session is a growth session" — would invert the authorship boundary that makes Growth Mode meaningful. The learner chooses to be taught; the model does not choose to teach.
2. **`arguments: [action, level]`.** The slash surface `/growth on junior` maps cleanly to `$action=on`, `$level=junior`. The argument shape is the same across every supported invocation, which keeps the handler body small and the discoverability clean.
3. **Supporting-files directory.** A Skill lives in its own directory. Today the directory holds only `SKILL.md`; tomorrow it can hold argument-parsing helpers, a status formatter, or a reorganization prompt for the technical-writer without polluting a single file. A custom command in `.claude/commands/growth.md` would be single-file by convention and could not grow this way without being restructured.

Forward-compatibility with current Claude Code direction is the fourth reason: Skills are where new capabilities are landing, and the growth feature should sit where the platform is headed.

| Surface | Role |
|---------|------|
| `/growth` Skill at `.claude/skills/growth/SKILL.md` | Single-gesture state change; handles every subcommand below |
| `.claude/growth/config.json` | Machine-readable state (`enabled`, `level`, `focus_domains`, `updatedAt`); gitignored |
| `CLAUDE.md` pointer line | Discovery; one line that names the feature and the Skill |

Supported invocations and their argument mappings:

| Invocation | `action` | `level` / extra | Effect |
|-----------|----------|-----------------|--------|
| `/growth on [level]` | `on` | optional `junior`\|`mid`\|`senior` | Enable at the given level; default to stored level or `junior` if none |
| `/growth off` | `off` | — | Disable; preserve `level` and `focus_domains` for the next enable |
| `/growth status` | `status` | — | Report current state, including per-domain focus and the last ten diff reports |
| `/growth focus <domain>[,<domain>]` | `focus` | domain list | Set `focus_domains`; agents prioritize teaching moments that map to these domains |
| `/growth focus clear` | `focus` | `clear` | Clear focus; agents treat all domains equally |
| `/growth domain new <key>` | `domain` | `new <key>` | Create a new custom domain file after learner confirmation |
| `/growth level <level>` | `level` | `junior`\|`mid`\|`senior` | Change level without toggling enabled state |

**On `/quiet`.** A separate concern has been raised for a `/quiet` toggle that suppresses the session-contract trailer (teaching-provenance plus notebook-diff) without disabling Growth Mode writes. Position: this is its own Skill at `.claude/skills/quiet/SKILL.md`, not a `/growth` subcommand. Reasoning: `/quiet` has a distinct authorship boundary from `/growth` — a learner might want silent background enrichment while reading the response for non-teaching content, which is orthogonal to whether Growth Mode is on. Keeping them separate lets `/quiet` also be useful outside Growth Mode (e.g., suppressing other trailers in the future) without becoming a grab-bag subcommand of `/growth`.

`config.json` schema:

```json
{
  "enabled": false,
  "level": "junior",
  "focus_domains": [],
  "updatedAt": "2026-04-22T00:00:00Z"
}
```

When `focus_domains` is non-empty, agents with a teaching moment outside those domains still contribute if the moment is genuinely load-bearing, but they prefer to defer a non-focus teaching moment rather than write a shallow entry. This lets the learner say "this month I am studying concurrency" and have the agents intensify teaching effort there without going silent on the rest.

### CLAUDE.md integration

`.claude/CLAUDE.md` gets a pointer block under a "Growth Mode" heading. The block names the notes directory so agents know where to read and write, names the config path so agents know where to check state, and names the `/growth` Skill so humans know how to toggle. The block is unconditional — it is always present in CLAUDE.md — but it is one short paragraph and does not add meaningful overhead for default-off sessions because agents that never enter Growth Mode read the block once and do nothing with it.

At session start, every growth-aware agent performs this sequence:

1. Read `.claude/growth/config.json`. If missing or `enabled: false`, skip all growth steps entirely.
2. Read `.claude/growth/preamble.md` for the enrichment protocol.
3. Identify which domain files are relevant to the current task by mapping the task to domain keys from the taxonomy.
4. Read those domain files so the agent knows what is already recorded and does not duplicate.
5. Proceed with the normal task. When a teaching moment arises, follow the enrichment protocol.

### Privacy posture: gitignored by default

Both `.claude/growth/notes/` and `.claude/growth/config.json` are gitignored out of the box. The template ships a `.gitignore.example` file that shows the exact lines and includes a commented-out inversion that teams can enable if they choose to share notes:

```gitignore
# .gitignore.example — growth-mode defaults
.claude/growth/notes/
.claude/growth/config.json

# Opt-in: un-ignore notes to share them as a team textbook.
# Uncomment the two lines below, then commit .claude/growth/notes/.
# !.claude/growth/notes/
# !.claude/growth/notes/*.md
```

**Rationale.** Notes contain the learner's mistakes, prior understanding, and revision history — preserved in place with supersession markers. That is private learning material. A learner opts in to share notes when they want a team-level textbook; individual growth is not broadcast by default. This aligns with the owner's stated philosophy ("I am not optimizing for user acquisition; I built this for myself") and with how the supersession-with-history design treats early material: every superseded explanation remains visible forever, and that material is exactly what most people prefer to keep off a public repository. Teams that want the notebook as a shared artifact can flip the inversion in one place; the commented example makes that path trivial without making it the default.

`config.json` is gitignored for a different reason: it holds per-individual preferences (level, focus domains) that should not be version-controlled even when a team chooses to commit notes.

### Session contract

At the end of every response, a growth-aware agent operating under Growth Mode ON emits two trailing sections: a teaching-provenance summary and a notebook-diff report. These are visible to the learner in the agent response itself; they are not written to a file.

```
## Growth: taught this session
- [concept-name]: [one-sentence summary at the declared level]
- [concept-name]: [one-sentence summary]

## Growth: notebook diff
- notes/<domain>.md → <operation> on `## <section-heading>`: <one-sentence change summary>
- notes/<domain>.md → <operation> on `## <section-heading>`: <one-sentence change summary>
```

This makes the notebook evolution legible in real time and lets the learner spot-check whether the agent's operation choice was correct (for example, was that really a `deepen` or should it have been `correct`). It is also the hook for future tooling — a learner can scan their chat history and replay the evolution of any domain file.

## Alternatives Considered

| Alternative | Why Not Chosen |
|-------------|----------------|
| Append-only journal (original design) | Rejected — fragments knowledge without organization; a chronological log of teaching moments cannot answer "what do I know about concurrency?" without a human re-reading and synthesizing. |
| Single monolithic `notes.md` | Rejected — unreadable at scale; a file that touches nineteen domains loses section integrity within weeks. |
| Chronological per-session notes | Rejected — defeats the organize-by-domain goal; the learner would end up with "what happened in session 17" rather than "what I know about testing discipline". |
| LLM-re-summarized notes per session | Tempting but rejected. Summarization by an LLM at the end of a session can feel efficient, but it lossily destroys earlier material every pass. A junior-level foundational explanation from session 2 is exactly the content a senior-level learner returning to review fundamentals wants to see untouched three months later. Summarization would also break supersession-with-history, because the summarizer has no way to know which prior text was superseded-with-rationale and which was the active correct version. The cost of destroyed context outweighs the benefit of shorter files. The alternative we adopt — deepen and supersede rather than rewrite — keeps all original material, which is the point. |
| Custom command at `.claude/commands/growth.md` | Rejected — in current Claude Code, Skills and Commands have merged and Skills are canonical for new work. A custom command has no equivalent of `disable-model-invocation`, which means the model could auto-invoke `/growth on` on the learner's behalf; that inverts the authorship boundary. A custom command is also single-file by convention, which foreclosure supporting files the Skill directory can hold later (status formatter, reorganization prompt, helpers). Skills win on invocation control, argument mapping, and forward-compatibility. |
| Notes committed to git by default | Rejected — notes contain mistakes, prior understanding, and supersession history; that is private learning material, not a team artifact. Commit-by-default would broadcast every learner's gaps into the repository history. Gitignore-by-default with opt-in sharing via the shipped `.gitignore.example` inversion gives teams the path when they want the shared-textbook outcome, without making it the coercive default. |

### Append-only journal (detail)

A single `journal.md` with dated entries is how most session-log features start. It is easy to implement — agents append, never read back. But a month into a project, a learner asking "what do I know about error handling?" has to grep their journal, manually piece together seventeen entries, and hope nothing contradicts anything. The journal captures teaching moments without organizing them, which is the opposite of what the owner's decision 3 demands.

### Single monolithic `notes.md` (detail)

One big file with heading conventions could in principle be organized by domain. In practice, nineteen domains in one file produces a document where reading any single domain means scrolling past eighteen others, and where agents trying to edit the architecture section must load the entire file into context to avoid breaking structure elsewhere. Splitting into per-domain files is the natural boundary.

### Chronological per-session notes (detail)

A variant of the journal where each session gets a file (`2026-04-22-session.md`) rather than an append. This makes individual sessions reviewable but still does not produce an organized-by-domain reference. The learner searching for "the repository pattern" must open every session file that might contain it.

### LLM-re-summarized notes per session (detail)

After each session, an agent reads the full domain file, rewrites it as a tighter version, and commits. Short. Organized. But the rewriter has to make choices about what to keep, and any rewrite loses the exact phrasing of earlier entries. Two specific harms: (1) a superseded entry that carries a `Superseded YYYY-MM-DD: <reason>` marker teaches the learner how their understanding evolved; a rewrite collapses that history. (2) A junior-scaffolding entry is exactly the material a returning learner wants to re-read to rebuild context; a summarizer trained to prefer concision will compress exactly that scaffolding. The owner's decision 2 ("depth of explanation is a feature, not a bug") rules this out.

## Consequences

### Positive

- **The notebook becomes a textbook the learner built.** After dozens of sessions, the learner has a personalized reference organized by domain — a genuine pedagogical artifact rather than a log. It is navigable by concept at any time.
- **Domain-keyed structure survives stack changes.** The same nineteen domain names apply to a Flutter project and a Go project. A learner who moves between stacks carries a stable mental scaffold, and the inside of each domain file teaches them how the domain plays out in the current ecosystem.
- **Supersession-with-history captures how understanding evolves.** A junior-level entry from month one and a senior-level refinement from month six coexist in the same section. The learner can see their own progress by reading downward.
- **Self-review at any time.** Before a review session, a learner can open `review-taste.md` and re-read what they have accumulated. Before a deploy, `release-and-deployment.md`. The notebook is a study tool as well as a session artifact.
- **Per-agent ownership is explicit.** The `## Growth Domains` section in each agent's prompt body makes it auditable which agent is supposed to contribute to which domain. Adding or removing an agent's growth responsibility is a one-line change. (The declaration location moved from frontmatter to prompt body in ADR-002 for schema compliance.)
- **Authorship boundary is enforceable at the platform layer.** `disable-model-invocation: true` on the growth Skill means no model turn can silently flip the learner into teaching mode. The invariant is enforced by Claude Code, not by prompt discipline.
- **Privacy-by-default lowers adoption friction.** Learners can run Growth Mode on a public repository without worrying that their notes ship with their code. Teams that want the team-textbook outcome flip one inversion in `.gitignore.example`.
- **Default-off invariant is preserved.** Users who never run `/growth on` see no notes, no reads, no writes, no changes to agent behavior.

### Negative / Trade-offs

- **Every growth-aware agent invocation is now I/O-heavy.** Each turn reads `config.json`, `preamble.md`, and one or more domain files before emitting its response. For a session that touches five agents and four domains, this is up to ten file reads and multiple writes per session. Acceptable for opt-in, unacceptable as default — which is why the default-off invariant matters more than ever.
- **Context cost when ON is higher than it would be under a length budget.** Contributions are as thorough as the concept requires. A single junior-level session introducing the repository pattern can produce a multi-paragraph section plus a worked example. This is intended; it is real context spend, and it is what the design is for.
- **The reorganization step is nontrivial and can go wrong.** An agent applying a `refine` operation might inadvertently alter a nearby section. The enrichment protocol requires byte-for-byte preservation outside the change surface; enforcing this is a discipline problem. Mitigation: the session contract's notebook-diff report makes unintended changes visible in the same response where they happened, and PR reviewers verify the property during any change that touches agent prompts or the preamble. Automated byte-level assertion against agent output is explicitly rejected — LLM non-determinism makes it unreliable.
- **Merge-conflict scenario within a session.** If two agents in the same session (e.g., architect and implementer running in sequence) both want to enrich `architecture.md → Dependency Inversion`, the second agent must read the file after the first agent's write. If the orchestrator runs them in parallel and both start from the pre-edit file, the second write overwrites the first. Mitigation: the orchestrator serializes growth-writing agents when they target the same domain; see Implementation Notes. If serialization fails and a conflict happens, the session contract's diff report will show the lost operation, and the learner can ask the agent to retry.
- **Non-destructive editing under pressure.** An agent asked to "fix" an outdated entry must `correct` (mark superseded, append corrected version), not delete. The preamble forbids rewriting explicitly, and PR review of preamble or agent-prompt changes verifies the property holds.

### Neutral / Follow-ups

- **Teams can opt in to notebook sharing.** A team that wants a shared textbook flips the inversion in `.gitignore.example` and commits `.claude/growth/notes/`. We do not design an explicit export feature; the gitignore path is the export path.
- **Over time, some domain files will grow large enough to warrant splitting.** See Open Questions.
- **Technical-writer is both a primary author and a curator.** Primary ownership of `documentation-craft` means technical-writer originates teaching content about documentation shape and discipline. The curator role (proposing splits, merges, section renames across any domain when a file drifts) remains as a secondary responsibility.
- **Japanese translations of notes are out of scope for this ADR.** The notes directory is English only at ship. Future decision on whether `docs/ja/growth/notes/` mirrors exist.

## Implementation Notes

Concrete checklist for the implementer agent. Assume existing `.claude/` layout and existing `docs/en/adr/` directory.

### Directory and seed files

Create `.claude/growth/` with:

```
.claude/growth/
├── config.json
├── preamble.md
└── notes/
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

Also ship `.gitignore.example` at the repo root with the growth-mode privacy block defined in the Decision section. The actual `.gitignore` includes those lines by default; `.gitignore.example` documents the opt-in inversion for teams that want to share.

Each seed file contains front matter and one placeholder section so agents have a clear empty shape:

```markdown
---
domain: testing-discipline
owners: [test-runner, implementer, code-reviewer]
updated: 2026-04-22
---

# Testing Discipline

This domain covers how tests are structured, when each test type earns its keep,
fixture hygiene, and how test failures are triaged. Agents contribute entries
as teaching moments arise during real sessions; the file grows section by section.

## Placeholder

This section is seeded empty. The first agent with a teaching moment in this
domain will replace this placeholder with a real section following the
enrichment protocol in `.claude/growth/preamble.md`.
```

### `.claude/growth/preamble.md`

The preamble is the single source of truth for the enrichment protocol. It:

- Defines the five-step contract (identify → read → decide → apply → report).
- Lists the five operations (add, deepen, refine, correct, new-domain) with an example of each.
- Defines the supersession marker format: `> Superseded YYYY-MM-DD: <reason>`.
- Defines the diff-report format that agents emit at end of response.
- Defines the level semantics (junior / mid / senior) as angle-and-density — no length budget.
- Names the canonical nineteen domains and describes what belongs in each.
- States the non-destructive editing rule and the no-auto-create rule for new domains.
- States the serialization rule for same-domain concurrent edits.

Every growth-aware agent reads this file on session start (when Growth Mode is ON). The agent prompts reference it by path; they do not inline its content.

### Per-agent Growth Domains declaration

Every file in `.claude/agents/` gets a `## Growth Domains` section at the top of its prompt body. All fifteen agents ship with at least one primary domain — there is no exempt list, and no agent has an empty Growth Domains list. The section lists primary and secondary domains on two labeled lines. Example for the architect:

```markdown
---
name: architect
description: ...
model: opus
---

# Architect Agent

## Growth Domains

- Primary: architecture, api-design, data-modeling
- Secondary: persistence-strategy, error-handling, ecosystem-fluency, dependency-management, security-mindset
```

> **Note.** ADR-002 (accepted 2026-04-23) moved this declaration from the `growth_domains:` frontmatter key to the `## Growth Domains` body section shown above. The substance is unchanged; only the location changed to stay within the officially documented Claude Code sub-agent frontmatter schema. See [docs/en/adr/002-growth-domains-location.md](002-growth-domains-location.md) for the rationale.

Each agent's prompt body gets a short conditional block that says, in substance: "If `.claude/growth/config.json` has `enabled: true`, read `.claude/growth/preamble.md` and the domain files listed in your Growth Domains section, then follow the enrichment protocol. At end of response, emit the teaching-provenance summary and the notebook-diff report." This is the only growth-specific content that lives in each agent prompt. The policy lives in `preamble.md`.

### Growth Skill at `.claude/skills/growth/SKILL.md`

Create `.claude/skills/growth/SKILL.md` with YAML frontmatter:

```yaml
---
name: growth
description: Toggle Developer Growth Mode and manage per-domain focus for the notebook at .claude/growth/notes/.
disable-model-invocation: true
arguments:
  - name: action
    description: on | off | status | focus | domain | level
  - name: level
    description: Optional level (junior|mid|senior) for `on`, or subargument for other actions.
---
```

**Why `disable-model-invocation: true` is non-negotiable.** Growth Mode changes every subsequent agent turn in the session. The learner must be the one who chooses to enter teaching mode; allowing the model to auto-invoke `/growth on` would invert the authorship boundary. Document this reasoning inside the Skill body so future maintainers do not "helpfully" remove the flag.

**Argument mapping for every invocation:**

- `/growth on` or `/growth on junior` → `$action=on`, `$level=junior` (or stored level, or default `junior`)
- `/growth off` → `$action=off`
- `/growth status` → `$action=status`
- `/growth focus concurrency-and-async,security-mindset` → `$action=focus`, `$level=<csv>` (second positional holds the domain list)
- `/growth focus clear` → `$action=focus`, `$level=clear`
- `/growth domain new <key>` → `$action=domain`, `$level=new <key>` (the Skill body parses the subargument; confirmation is required before creating the file)
- `/growth level mid` → `$action=level`, `$level=mid`

The Skill body parses `$action` and dispatches. State is written to `.claude/growth/config.json`. For `domain new`, the Skill prompts for explicit confirmation, creates the seeded file following the shape in `preamble.md`, and updates `config.json.focus_domains` only if the learner opts in.

### `/quiet` Skill (separate)

Ship `.claude/skills/quiet/SKILL.md` as its own Skill, not a subcommand of `/growth`. It suppresses the session-contract trailer (teaching-provenance and notebook-diff sections) without disabling Growth Mode writes. The authorship boundaries are distinct: `/growth` controls whether the notebook is maintained, `/quiet` controls whether the trailer is rendered. Keeping them separate lets `/quiet` also be useful outside Growth Mode without becoming a grab-bag of subcommands.

### CLAUDE.md pointer

Add a short block to `.claude/CLAUDE.md` under a new heading `## Developer Growth Mode`:

```markdown
## Developer Growth Mode

Growth Mode is a default-off learning layer. When enabled via the `/growth` Skill
(`/growth on [junior|mid|senior]`), every agent contributes to a domain-organized
notebook at `.claude/growth/notes/`. The notebook grows and is refined over many
sessions into a personalized reference the learner built by shipping real features.
Notes and `config.json` are gitignored by default; see `.gitignore.example` to opt
in to team sharing. The enrichment protocol every agent follows is defined in
`.claude/growth/preamble.md`. Run `/growth status` to see current state.
```

This is the only growth-mode content in CLAUDE.md. Agent prompt content does not live here.

### Orchestrator serialization rule

Add a rule to the orchestrator agent prompt: when Growth Mode is ON and two or more delegated agents have overlapping Growth Domains, run them sequentially rather than in parallel. When Growth Domains do not overlap, parallel execution is fine. This preserves the read-modify-write invariant for the notebook without giving up parallelism elsewhere.

### Enforcement: default-off invariant

The default-off invariant is the load-bearing claim of the entire feature. It is enforced by three deterministic preconditions, not by golden-file comparison of agent responses. LLM output is non-deterministic across runs, model versions, and prompt compaction events; a hash-based regression harness against agent responses degrades to flaky tests that get disabled, which is worse than no test at all.

The three preconditions that actually enforce the invariant:

1. **The `disable-model-invocation: true` flag on `.claude/skills/growth/SKILL.md`.** This is the wall — the model cannot flip Growth Mode on. Only the user can. Verified by a one-line grep in CI.
2. **The guard branch in every growth-aware agent prompt.** Every agent is instructed: at session start, read `.claude/growth/config.json`; if the file is absent or `enabled: false`, skip all growth steps. This is the floor — the behavior itself lives here. Verified by grep for the guard-branch marker string in every file under `.claude/agents/` that declares a `## Growth Domains` section.
3. **The gitignore posture.** `.claude/growth/notes/` and `.claude/growth/config.json` are ignored by the shipped `.gitignore`. Verified by grep.

CI runs a single shell script (`scripts/check-growth-invariants.sh`) that performs these three grep checks. All three are deterministic and model-version-agnostic. No LLM is in the loop.

### Design goals verified during PR review

Three properties of the system are design goals rather than automated tests. Attempting to test them against agent output would hit the same non-determinism problem. They are enforced by PR review when changes touch `.claude/growth/preamble.md` or agent prompts:

- **Non-destructive editing.** An agent applying a `deepen` operation must preserve the original section content byte-for-byte and append rather than interleave. An agent applying `refine` must keep the original visible as a superseded block. An agent applying `correct` must leave the superseded text below the `> Superseded YYYY-MM-DD: <reason>` marker.
- **Supersession history.** Across multiple `correct` operations on the same section, all prior versions stay in the file with markers; no version is silently dropped.
- **Domain boundary discipline.** An agent writes to its primary domain and cross-references secondary domains rather than duplicating content.

These properties are spelled out in `.claude/growth/preamble.md` and checked during review of any PR that changes agent prompts or the preamble.

### Gitignore posture check

A fourth check — also a grep, also in `scripts/check-growth-invariants.sh`. From a clean clone, assert the `.gitignore` contains entries ignoring `.claude/growth/notes/` and `.claude/growth/config.json`. Assert `.gitignore.example` contains the opt-in inversion comment block. This guards the privacy default against accidental regression during template edits.

## Open Questions

Positions below are tentative. Items settled by owner decision (gitignore posture, domain count, Skill vs Command, length budgets, all-agents-growth-aware) have been moved to the Decision section and removed from this list.

1. **At what size should a domain file be split?**
   Tentative position: split when the file exceeds ~1200 lines or ~8 top-level sections, whichever comes first. Splitting is triggered by the technical-writer agent in its curator role, not by content-contributing agents. The split creates a sibling file with a derivative key (e.g., `architecture.md` → `architecture-layering.md` plus `architecture-boundaries.md`) and leaves a pointer section in the original. Reasoning: a 1200-line file is still readable as a reference; past that, concept retrieval degrades. The threshold itself is the open question — it may move once we see real notebooks in the wild.

2. **How does the orchestrator serialize concurrent writes to the same domain file?**
   Tentative position: the orchestrator inspects the Growth Domains of every agent it plans to invoke for the current turn; if two or more have overlapping domains, it runs them sequentially, otherwise parallel execution is fine. The open part: what is the right contract when the harness itself parallelizes agents outside the orchestrator's control? Can the Skill framework expose a file-level lock, or do we rely entirely on sequencing at the orchestrator layer? This matters as soon as a non-orchestrator harness runs multiple growth-aware agents in parallel.

3. **How do we detect a teaching moment that spans multiple domains?**
   Tentative position: the agent writes to the primary domain and emits a cross-reference line in the secondary domain pointing to the primary entry. Cross-references use relative markdown links (`See [Dependency Inversion](./architecture.md#dependency-inversion)`). Not perfect, but the cheapest approach that keeps the notebook navigable. Open: whether cross-references should themselves be tracked as an operation in the diff report.

4. **What happens when the learner changes level mid-project?**
   Tentative position: new contributions follow the new level; existing entries are not rewritten. A learner moving from junior to mid does not want their foundational scaffolding rewritten — that material remains valuable as a re-read resource. New sessions at the higher level layer idiomatic and trade-off material on top.

5. **Should the technical-writer periodically review the notebook?**
   Tentative position: yes, on-demand via an explicit invocation (`/growth review` dispatched through the Skill), not automatically. Reasoning: automatic reorganization risks lossy edits; a learner-initiated review gives a clear audit trail.

## References

- PRD: [docs/en/prd/developer-growth-mode.md](../prd/developer-growth-mode.md) — product-level requirements, level semantics, acceptance criteria, and rollout plan for the same feature.
- Taxonomy: [docs/en/growth/domain-taxonomy.md](../growth/domain-taxonomy.md) — canonical 18-domain definitions, owner-specific boundaries between adjacent domains (notably `ecosystem-fluency` vs `dependency-management`, and `data-modeling` vs `persistence-strategy`), and the authoritative per-agent ownership matrix. This ADR's ownership table is reconciled against that document; if any row drifts, the taxonomy is the source of truth.
- ADR template: [docs/en/adr/000-template.md](./000-template.md) — this ADR extends the minimal template with Metadata, Alternatives Considered (table plus prose), Open Questions, and Implementation Notes sections.
- Claude Code Skills: https://docs.claude.com/en/docs/claude-code/skills — canonical reference for `disable-model-invocation`, `arguments`, and the supporting-files directory.
- Claude Code agent frontmatter: https://docs.claude.com/en/docs/claude-code/sub-agents — source for the Growth Domains section convention.
- Project CLAUDE.md: [.claude/CLAUDE.md](../../../.claude/CLAUDE.md) — lists the fifteen-agent team this feature extends.

Style note: structure goes Metadata, Context, Decision, Alternatives, Consequences, Implementation Notes, Open Questions, References. This is the shape used here going forward for decisions of comparable weight.
