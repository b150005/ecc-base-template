# ecc-base-template

A framework-agnostic GitHub template that ships a 14-agent development
team for high-quality, high-precision collaboration with Claude Code.

[日本語版 README はこちら](README.ja.md)

---

## Prerequisites

This template is designed for developers who already have **ECC
(Everything Claude Code)** installed at the user level (`~/.claude/`).
The agents in this template reference ECC-provided rules and Skills at
runtime — language-specific reviewers, framework patterns, and shared
verification workflows live in your ECC install, not in this repository.

The template still runs without ECC, but agent quality is degraded:
rule references resolve to nothing, Skill invocations are no-ops, and
the language-specific code review path (see
[`code-reviewer`](.claude/agents/code-reviewer.md)) falls back to a
generic review and says so in its verdict.

> **New to ECC?** Install it at the user level first, then return here
> to create your project repository from this template.

---

## What you get

- **14 specialized agents** covering the full product lifecycle —
  orchestrator, product-manager, architect, implementer, test-runner,
  code-reviewer, security-reviewer, performance-engineer, devops-engineer,
  technical-writer, and more. All ecosystem-agnostic: the agents detect
  your language and framework at runtime.
- **Plan-First default.** New sessions boot in Plan Mode (per
  `permissions.defaultMode: "plan"` in `.claude/settings.json`) — Claude
  proposes a plan and waits for explicit approval before writing or
  shelling out.
- **Clean root directory.** After forking you own the repo root — the
  template does not reserve `docs/`, `scripts/`, or any ADR/spec
  numbers.
- **Document templates** for ADRs and product specs at
  `.claude/templates/`, with English-first `*.md` and Japanese `*.ja.md`
  counterparts. Copy them wherever your project wants its decision
  records to live.
- **Empty CI scaffold** (`.github/workflows/.gitkeep`) so the folder is
  there waiting when you decide to add CI.

---

## Quick start

### 1. Create your repository

On GitHub, open
[b150005/ecc-base-template](https://github.com/b150005/ecc-base-template)
and click **Use this template**.

### 2. Clone and open

```sh
git clone https://github.com/<your-username>/<your-repo>.git
cd <your-repo>
```

### 3. Run the initializer

```sh
.claude/init.sh
```

This prompts you for a project name, one-line description, and tech
stack, then replaces the `## About This Project` placeholder in
`.claude/CLAUDE.md` and copies `.env.example` to `.env`. Re-running is
safe.

Non-interactive form:

```sh
.claude/init.sh \
  --project-name "TaskFlow" \
  --description "Team task management API" \
  --stack "Go / Gin / PostgreSQL"
```

### 4. Start working

Open the repo in Claude Code (`claude` in the repo root) and give the
orchestrator a real task. For example:

> Design and implement a REST endpoint `POST /tasks` that validates
> input, persists to PostgreSQL, and returns the created resource.
> Use TDD.

The orchestrator delegates to product-manager for acceptance criteria,
architect for the module boundaries, implementer for code, and the
quality agents for review — you steer the hand-offs.

---

## The 14-agent team

All agents are ecosystem-agnostic. They detect the project's language
and framework at runtime by reading `.claude/CLAUDE.md` and your
project's manifest files (`package.json`, `pubspec.yaml`, `go.mod`,
`Cargo.toml`, etc.). The orchestrator coordinates the team;
specialists are invoked by the orchestrator or directly.

| Agent | Phase | Role |
|-------|-------|------|
| **orchestrator** | All | Analyzes issues, plans work, delegates to specialists |
| **product-manager** | Planning | Spec authoring, user stories, acceptance criteria |
| **market-analyst** | Planning | Market research, competitor analysis |
| **monetization-strategist** | Planning | Business model, pricing, revenue analysis |
| **ui-ux-designer** | Design | UI/UX design, usability review, accessibility |
| **architect** | Design | System architecture, technology decisions, ADR creation |
| **implementer** | Build | Code implementation following architecture specs and TDD |
| **code-reviewer** | Quality | Code quality, maintainability, standards adherence |
| **test-runner** | Quality | Test execution, coverage reporting, TDD support |
| **linter** | Quality | Static analysis and code style enforcement |
| **security-reviewer** | Quality | Vulnerability detection, secret scanning, OWASP Top 10 |
| **performance-engineer** | Quality | Profiling, bottleneck identification, optimization |
| **devops-engineer** | Release | CI/CD, deployment strategy, release management |
| **technical-writer** | Release | Documentation, changelog, bilingual docs |

### Model tiers

Each agent declares its model in frontmatter using a Claude Code alias
(`opus` / `sonnet` / `haiku` / `inherit`), which resolves to the latest
version in that family. The template ships a mixed fleet — the right
model for the job rather than a single floor.

For the current version numbers, see the
[Anthropic model overview](https://docs.claude.com/en/docs/about-claude/models/overview).

---

## Project structure (after forking)

```
your-repo/
├── README.md                  ← your project's README (replace this one)
├── README.ja.md               ← optional bilingual README
├── CHANGELOG.md               ← starts at [Unreleased]; grows with your releases
├── LICENSE
├── .env.example
├── .gitignore
├── .gitattributes
├── .claude/
│   ├── CLAUDE.md              ← project instructions (edit the About section first)
│   ├── agents/                ← 14 agent definition files
│   ├── templates/             ← copy-and-fill ADR/spec templates
│   ├── init.sh                ← interactive initializer
│   └── settings.json          ← Claude Code settings (Plan Mode default)
└── .github/
    ├── workflows/.gitkeep     ← empty by design — add your CI here
    ├── CODEOWNERS
    ├── ISSUE_TEMPLATE/
    ├── PULL_REQUEST_TEMPLATE.md
    └── dependabot.yml
```

You own every visible root file. The template does not reserve
`docs/`, `src/`, `scripts/`, or any other top-level directory name.

### Placing your own ADRs and specs

Copy `.claude/templates/adr-template.md` to wherever you want your
ADRs to live. Common choices:

- `adr/001-use-postgresql.md` at the repo root
- `adr/en/001-use-postgresql.md` + `adr/ja/001-use-postgresql.md` for bilingual projects
- `docs/adr/001-use-postgresql.md` if you already have a `docs/` tree

The same applies to `spec-template.md`. There is no forced location.

### CI

`.github/workflows/` ships empty (just a `.gitkeep`). CI is a per-fork
choice — different projects want different CI scaffolding (lint, test,
coverage gates, security scanning, dependency-bump triage). Write
your own workflows when you are ready, sized to your stack.

---

## Contributing to the template

This section is for people working on **ecc-base-template itself**,
not for fork users. Open issues and PRs against the `main` branch.

---

## License

[MIT](LICENSE)
