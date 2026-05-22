# Project Context

## About This Project

<!-- TODO(init): Replace this entire section before your first agent session.
     The agents read this block on every turn. Vague context = vague output.

     Minimum viable description (1–3 sentences):
       - What does this application do, and for whom?
       - What is the primary tech stack? (language, framework, database)
       - Any hard constraints? (mobile-first, offline-capable, GDPR, etc.)

     Example:
       TaskFlow is a team task management API built with Go + Gin and PostgreSQL.
       It is consumed by a React SPA and an iOS client.
       All data must remain within the EU (GDPR).
-->

[YOUR PROJECT NAME] — [one-line description].

**Stack:** [language] / [framework] / [database]
**Target users:** [who uses this]
**Key constraints:** [performance, compliance, platform, etc.]

## Architecture Principles

- Layered architecture with clear separation of concerns
- Repository pattern for data access abstraction
- Immutable data structures preferred; copy-on-write for state updates
- Dependency injection for testability

## Agent Team

This project uses an agent team for structured development. The **orchestrator** agent coordinates the following specialists:

| Agent | Role |
|-------|------|
| orchestrator | Analyzes issues, creates plans, delegates to specialists |
| product-manager | Product planning, PRD, user stories, acceptance criteria |
| market-analyst | Market research, competitor analysis |
| monetization-strategist | Business model, pricing, revenue strategy |
| ui-ux-designer | UI/UX design, accessibility, usability review |
| docs-researcher | Documentation research, API verification, freshness-safe search (verification-layer / research Generator) |
| research-critic | Adversarial review of external research with primary-source-only citation (verification-layer / research Critic) |
| adversarial-implementer | Parallel-implementation Critic for behavioural-delta verification (verification-layer / implementation Critic, default-off) |
| architecture-critic | Counter-proposal Critic that takes rejected ADR alternatives seriously (verification-layer / design Critic, default-off) |
| architect | System architecture, technology decisions |
| implementer | Code implementation following architecture and TDD |
| code-reviewer | Meta-reviewer: delegates language depth to ECC `*-reviewer`, owns template cross-cutting checks |
| test-runner | Test execution, coverage reporting |
| linter | Static analysis, code style enforcement |
| security-reviewer | Vulnerability detection, OWASP Top 10 |
| performance-engineer | Profiling, bottleneck identification, optimization |
| devops-engineer | CI/CD, deployment strategy, release management |
| technical-writer | Documentation, changelog, bilingual docs |

All agents detect the project ecosystem at runtime by reading this file and project manifest files (package.json, pubspec.yaml, go.mod, etc.).

## Document Templates

- ADR template: `.claude/templates/adr-template.md` (`.ja.md` for Japanese)
- Spec/PRD template: `.claude/templates/spec-template.md` (`.ja.md` for Japanese)

**Forks** decide their own layout: a single-language fork under any top-level
directory (e.g. `adr/001-foo.md`), a bilingual fork split by language (e.g.
`adr/en/001-foo.md`, `adr/ja/001-foo.md`), or a co-located pair under one
directory (e.g. `adr/001-foo.md` + `adr/001-foo.ja.md`). The template imposes
no layout on forks — only the templates themselves. A common pin worth
adopting: put Specs under `specs/` and ADRs under `adr/` at the repo
root, three-digit zero-padded prefix on each filename; `product-manager`
then authors a Spec at the row's reserved path and `architect` a new
ADR alongside.

## CLAUDE.md authoring guidance

When creating or significantly restructuring this file (or `README.md` or
`.claude/agents/*.md`), invoke the **claude-md-authoring** Skill at
`.claude/skills/claude-md-authoring/SKILL.md`. The Skill provides a
Pre/Post checklist, four invariant rules verified against Anthropic's
official docs, and a runtime protocol for volatile values. Routine
small edits (typo, single bullet, version bump) do not need the Skill.

## Developer Learning Mode

Default-off learning layer with two orthogonal pillars: the **knowledge pillar**
(agents contribute teaching moments to a domain-organized knowledge base) and the
**coaching pillar** (agents change how they work during implementation based on a
chosen coaching style). At session start, read `.claude/learn/config.json`; if
absent or `"enabled": false`, skip all learning behavior entirely. If
`"enabled": true`, read `.claude/skills/learn/preamble.md` for the enrichment
contract. Also read `coach.style` from `.claude/learn/config.json`; if non-`default`
and the style file exists at `.claude/skills/learn/coach-styles/<style>.md`, load
and apply the `behavior-rule` for this turn.

Toggled only via the `/learn` Skill. Use `/learn coach <style>` to set the coaching
style; `/learn coach list` to see available styles. The Skill at
`.claude/skills/learn/` carries the enrichment protocol and domain definitions.

## Plan-First & Learning-Aware Defaults

This template ships with `permissions.defaultMode: "plan"` in
`.claude/settings.json`. New sessions therefore boot in **Plan Mode**:
Claude proposes a plan and waits for explicit approval before any
write or shell side effect. Toggle off for the current session with
Shift+Tab, or override per developer in `.claude/settings.local.json`.

A learning-aware custom output style is shipped at
`.claude/output-styles/ecc-learn.md`. It builds on the built-in
`Learning` style — Claude inserts `TODO(human)` markers so you write
small fragments yourself — and adds short `Insight:` notes that explain
*why* a non-obvious choice was made. Selection is opt-in: choose it
once via `/output-style ecc-learn`.

The coaching hook is implemented in `.claude/hooks/coaching-context.sh`
(self-documenting inline docblock) and registered in
`.claude/settings.json` under `UserPromptSubmit`.

## Roadmap

When a fork keeps a Roadmap, it lives at `.claude/ROADMAP.md` — the
row-by-row state of each milestone, plus the protocol rules that govern
it. `orchestrator` reads that file at session start, **before** the
Analyze-step row-guard (G1–G3). If `.claude/ROADMAP.md` does not exist,
the row-guard is silently skipped — the template ships without one and
the file is genuinely optional.

**Write-ownership summary** (when the file exists): `product-manager`
creates rows and flips status glyphs (`☐→◐` at Spec authoring, `◐→☑`
after step-6 quality-gate pass); `architect` adds `adr:` links;
`orchestrator` is read-only.

## Subagent dispatch contract

All subagent dispatch (any `Agent` tool call from `orchestrator` or main Claude) follows a fixed 5-slot prompt template and a delegate-and-stop rule. Applies to ALL parent→subagent dispatches, including verification-layer Generator/Critic routing.

**5-slot prompt structure** (every dispatch prompt fits this shape):

- `ROLE:` — agent name + posture (1 line)
- `CONTEXT:` — ≤ 3 bullets — the decision this informs, Roadmap row if any
- `TASK:` — imperative verb + object (1 sentence)
- `CONSTRAINTS:` — ≤ 5 bullets — what to skip, scope boundary, stop condition
- `OUTPUT:` — exact shape the parent will consume — format + max length

**Delegate-and-stop rule.** After writing an `Agent` dispatch, the parent agent may only call `Agent`, `AskUserQuestion`, or `ScheduleWakeup` until the subagent returns. No `Read`, `Bash`, `Edit`, `WebFetch`, no Skill invocations. This is the forcing function that prevents the parent from re-absorbing the delegated task between dispatch and return.

## Worktree advisory protocol

Before dispatching any multi-step plan, `orchestrator` evaluates worktree-parallelism suitability and emits a `## Worktree Recommendation` block **ahead of** the implementation plan.

**6-question suitability rubric** (answered in Analyze):

1. **File-disjoint?** Subtasks touch disjoint file sets.
2. **Roadmap-disjoint?** Subtasks affect different Roadmap rows.
3. **State-disjoint?** Subtasks don't share mutable shared state.
4. **Mergeable?** Outputs are trivially mergeable (no integration work).
5. **Reversible?** Rejecting one slice leaves the others useful.
6. **Net-faster?** Parallelism wins wall-clock once review costs count.

Yes on all 6 → recommend multi-worktree. No on any of 1–3 → single-worktree (forced — shared-state risk). No on 4–6 → single-worktree (recommended — parallelism does not pay).

**Write-zone rule.** UNSAFE for any non-owner worktree: `.claude/CLAUDE.md`, `.claude/ROADMAP.md`, `CHANGELOG.md`, `specs/NN-progress.md`, lockfiles. In multi-worktree mode, `orchestrator` designates **one Roadmap-owner worktree** that exclusively handles those files; other worktrees produce hand-off artifacts only.

## Development Workflow

1. **Issue Analysis**: Feed issues to the orchestrator via GitHub MCP or copy-paste. For defect reports, the orchestrator runs the **ours vs. upstream triage** (3-step protocol via docs-researcher) before deciding the workflow path
2. **Product Planning**: The product-manager creates a spec, user stories, and acceptance criteria using `.claude/templates/spec-template.md`
3. **Research & Reuse**: Search GitHub, package registries, and docs before writing new code. When the result will inform a decision (architecture, library selection, API usage, version pin), invoke the **verification-layer** Skill — research domain (`.claude/skills/verification-layer/research/protocol.md`; shared invariants in `.claude/skills/verification-layer/SKILL.md`). The `docs-researcher` (Generator) declares a Tier and the `research-critic` (Critic) reviews using a different tool family with primary-source-only citation. Default config in `.claude/verification.yml`; opt out via `research.enabled: false`. The same Skill also covers the **implementation** and **design** domains (default-off; opt in per domain).
4. **Architecture**: The architect designs the solution; significant decisions are recorded as ADRs using `.claude/templates/adr-template.md`
5. **Implementation**: The implementer writes code following TDD (RED → GREEN → IMPROVE). When the implementation is a workaround for an upstream defect, the implementer also places a `WORKAROUND-UPSTREAM(<owner>/<repo>#<issue>, fixed=>=<version>)` marker at each workaround site, and optionally records it under `workarounds/` using `.claude/templates/workaround-template.md`
6. **Quality Gate**: The code-reviewer (delegates language depth to the matching ECC `<lang>-reviewer`, owns template cross-cutting checks), linter, security-reviewer, and performance-engineer validate the implementation
   - **6a. Compliance check (opt-in)**: When `.claude/compliance.yml` has `compliance.enabled: true` and a non-empty `target_jurisdictions`, the **compliance-checklist** Skill (`.claude/skills/compliance-checklist/SKILL.md`, default-off) is invoked by `product-manager` / `security-reviewer` / `technical-writer` for capabilities that may have legal exposure (chat, payments, PII collection, data egress). The Skill produces a checklist with primary-source citations and a mandatory disclaimer; it never marks items as "complied with" — only the human reviewer can
7. **Documentation**: The technical-writer updates docs and changelog. When a workaround is removed, the technical-writer maps `user_impact` to the appropriate CHANGELOG category (`internal` / `changed` / `fixed`)
8. **Release**: The devops-engineer manages deployment and release
9. **Commit**: Conventional commits format (feat, fix, refactor, docs, test, chore, perf, ci)

When an `◐ in-progress` milestone crosses a session or compaction boundary, its in-flight workflow state persists to `specs/NN-progress.md` (`NN` = the Roadmap row number) — created/updated by `product-manager`/`implementer` at the boundary, read by `orchestrator` at the Analyze step, deleted on the `◐ → ☑`/`✗` flip, and composable with (not a replacement for) `/save-session`.

### Upstream workaround lifecycle

When a defect is traced to an upstream library or framework, the
implementer places a `WORKAROUND-UPSTREAM(<owner>/<repo>#<issue>,
fixed=>=<version>)` marker at each workaround site and optionally
records it under `workarounds/` using
`.claude/templates/workaround-template.md`. Remove the marker and the
workaround once the upstream fix lands and the dependency is bumped
past `<version>`.

## Testing Requirements

- Minimum 80% test coverage
- Unit tests for individual functions
- Integration tests for API/database operations
- E2E tests for critical user flows

## Code Quality Standards

- Functions: < 50 lines
- Files: 200-400 lines typical, 800 max
- Validate all inputs at system boundaries
- Handle errors explicitly at every level
- Never hardcode secrets; use environment variables

## Extending This File

Derived projects should:

1. Replace the "About This Project" section with project-specific context.
   The fastest way is to run `.claude/init.sh` once after forking;
   it interactively replaces the placeholder. Manual editing is fine too.
2. Add framework-specific architecture details (e.g., state management, routing).
3. Add framework-specific testing tools (e.g., Jest, pytest, go test).
4. Add framework-specific code style rules (e.g., Biome, Ruff, gofmt).
5. Keep the universal sections (workflow, testing requirements, code quality).
6. Create `.claude/ROADMAP.md` if you want the Roadmap mechanism; let
   `product-manager` own row creation. Without it, the orchestrator skips
   the Roadmap row-guard entirely.
7. Add your own CI workflows under `.github/workflows/` — the template
   ships none.
8. If you do not plan to use Developer Learning Mode, delete
   `.claude/skills/learn/`, `.claude/hooks/coaching-context.sh`,
   `.claude/output-styles/ecc-learn.md`, and the
   `## Developer Learning Mode` section above.
