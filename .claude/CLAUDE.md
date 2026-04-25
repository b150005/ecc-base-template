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
| docs-researcher | Documentation research, API verification, freshness-safe search |
| architect | System architecture, technology decisions |
| implementer | Code implementation following architecture and TDD |
| code-reviewer | Code quality and standards review |
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

You decide where to place the resulting documents. Single-language projects can
write directly under a top-level directory of your choice (e.g. `adr/001-foo.md`);
bilingual projects can split by language (e.g. `adr/en/001-foo.md`,
`adr/ja/001-foo.md`). The template does not impose a layout — only the templates.

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
style; `/learn coach list` to see available styles. The complete design lives in
`.claude/meta/` (template-internal):

- `.claude/meta/adr/001-developer-growth-mode.md` — original Learning Mode design
- `.claude/meta/adr/003-learning-mode-relocate-and-rename.md` — Learning Mode rename and relocation
- `.claude/meta/adr/004-coaching-pillar.md` — coaching pillar design
- `.claude/meta/prd/developer-learning-mode.md` — full functional specification
- `.claude/meta/references/domain-taxonomy.md` — domain definitions

## Development Workflow

1. **Issue Analysis**: Feed issues to the orchestrator via GitHub MCP or copy-paste
2. **Product Planning**: The product-manager creates a spec, user stories, and acceptance criteria using `.claude/templates/spec-template.md`
3. **Research & Reuse**: Search GitHub, package registries, and docs before writing new code
4. **Architecture**: The architect designs the solution; significant decisions are recorded as ADRs using `.claude/templates/adr-template.md`
5. **Implementation**: The implementer writes code following TDD (RED → GREEN → IMPROVE)
6. **Quality Gate**: The code-reviewer, linter, security-reviewer, and performance-engineer validate the implementation
7. **Documentation**: The technical-writer updates docs and changelog
8. **Release**: The devops-engineer manages deployment and release
9. **Commit**: Conventional commits format (feat, fix, refactor, docs, test, chore, perf, ci)

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
   The fastest way is to run `.claude/meta/scripts/init.sh` once after forking;
   it interactively replaces the placeholder. Manual editing is fine too.
2. Add framework-specific architecture details (e.g., state management, routing).
3. Add framework-specific testing tools (e.g., Jest, pytest, go test).
4. Add framework-specific code style rules (e.g., Biome, Ruff, gofmt).
5. Keep the universal sections (workflow, testing requirements, code quality).
6. If you do not plan to use Developer Learning Mode, delete `.claude/meta/`,
   `.github/workflows/learn-invariants.yml`, and the
   `## Developer Learning Mode` section above.
