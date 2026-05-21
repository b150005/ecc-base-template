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
| architect | System architecture, technology decisions |
| implementer | Code implementation following architecture and TDD |
| code-reviewer | Meta-reviewer: delegates language depth to ECC `*-reviewer` agents; owns project-wide cross-cutting checks |
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
no layout on forks — only the templates themselves.

## Plan-First Default

This template ships with `permissions.defaultMode: "plan"` in
`.claude/settings.json`. New sessions therefore boot in **Plan Mode**:
Claude proposes a plan and waits for explicit approval before any write
or shell side effect. Toggle off for the current session with Shift+Tab,
or override per developer in `.claude/settings.local.json`.

## Subagent dispatch contract

All subagent dispatch (any `Agent` tool call from `orchestrator` or main
Claude) follows a fixed 5-slot prompt template and a delegate-and-stop
rule. Applies to ALL parent→subagent dispatches.

**5-slot prompt structure** (every dispatch prompt fits this shape):

- `ROLE:` — agent name + posture (1 line)
- `CONTEXT:` — ≤ 3 bullets — the decision this informs
- `TASK:` — imperative verb + object (1 sentence)
- `CONSTRAINTS:` — ≤ 5 bullets — what to skip, scope boundary, stop condition
- `OUTPUT:` — exact shape the parent will consume — format + max length

**Delegate-and-stop rule.** After writing an `Agent` dispatch, the parent
agent may only call `Agent`, `AskUserQuestion`, or `ScheduleWakeup` until
the subagent returns. No `Read`, `Bash`, `Edit`, `WebFetch`, no Skill
invocations. This is the forcing function that prevents the parent from
re-absorbing the delegated task between dispatch and return.

## Worktree advisory protocol

Before dispatching any multi-step plan, `orchestrator` evaluates
worktree-parallelism suitability and emits a `## Worktree Recommendation`
block **ahead of** the implementation plan.

**5-question suitability rubric** (answered in Analyze):

1. **File-disjoint?** Subtasks touch disjoint file sets.
2. **State-disjoint?** Subtasks don't share mutable shared state.
3. **Mergeable?** Outputs are trivially mergeable (no integration work).
4. **Reversible?** Rejecting one slice leaves the others useful.
5. **Net-faster?** Parallelism wins wall-clock once review costs count.

Yes on all 5 → recommend multi-worktree. No on any of 1–2 → single-worktree
(forced — shared-state risk). No on 3–5 → single-worktree (recommended —
parallelism does not pay).

**Write-zone rule.** UNSAFE for any non-owner worktree: `.claude/CLAUDE.md`,
`CHANGELOG.md`, lockfiles. In multi-worktree mode, `orchestrator` designates
**one owner worktree** that exclusively handles those files; other worktrees
produce hand-off artifacts only.

## CLAUDE.md authoring guidance

When creating or significantly restructuring this file (or `README.md` or
`.claude/agents/*.md`), verify that anything stated as fact about Anthropic
tooling, model IDs, or API surfaces is checked against current official docs
at edit time — these values drift. Keep cross-cutting invariants (file
locations, agent names, workflow ordering) consistent with the rest of this
file. Routine small edits (typo, single bullet, version bump) do not need
this discipline.

## Development Workflow

1. **Issue Analysis**: Feed issues to the orchestrator via GitHub MCP or
   copy-paste.
2. **Product Planning**: The product-manager creates a spec, user stories,
   and acceptance criteria using `.claude/templates/spec-template.md`.
3. **Research & Reuse**: Search GitHub, package registries, and docs before
   writing new code. Prefer adopting or porting a proven approach over
   net-new code when it meets the requirement.
4. **Architecture**: The architect designs the solution; significant
   decisions are recorded as ADRs using `.claude/templates/adr-template.md`.
5. **Implementation**: The implementer writes code following TDD (RED →
   GREEN → IMPROVE).
6. **Quality Gate**: The code-reviewer (delegates language depth to the
   matching ECC `<lang>-reviewer` if available), linter, security-reviewer,
   and performance-engineer validate the implementation.
7. **Documentation**: The technical-writer updates docs and changelog.
8. **Release**: The devops-engineer manages deployment and release.
9. **Commit**: Conventional commits format (feat, fix, refactor, docs, test,
   chore, perf, ci).

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
   The fastest way is to run `.claude/init.sh` once after forking; it
   interactively replaces the placeholder. Manual editing is fine too.
2. Add framework-specific architecture details (e.g., state management, routing).
3. Add framework-specific testing tools (e.g., Jest, pytest, go test).
4. Add framework-specific code style rules (e.g., Biome, Ruff, gofmt).
5. Keep the universal sections (workflow, testing requirements, code quality).
6. Add your own CI workflows under `.github/workflows/` (this template ships
   the folder empty by design — fork CI is opt-in).
