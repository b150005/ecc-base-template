# ecc-base-template

A framework-agnostic GitHub template that ships a 15-agent development team
and an opt-in learning layer for high-quality, high-precision collaboration
with Claude Code.

[日本語版 README はこちら](README.ja.md)

---

## What you get

- **15 specialized agents** covering the full product lifecycle — orchestrator,
  product-manager, architect, implementer, test-runner, code-reviewer,
  security-reviewer, performance-engineer, devops-engineer, technical-writer,
  and more. All ecosystem-agnostic: the agents detect your language and
  framework at runtime.
- **Clean root directory.** After forking you own the repo root — the template
  does not reserve `docs/`, `scripts/`, `learn/`, or any ADR/spec numbers.
- **Document templates** for ADRs and product specs at `.claude/templates/`,
  with English-first `*.md` and Japanese `*.ja.md` counterparts. Copy them
  wherever your project wants its decision records to live.
- **Developer Learning Mode** (default **off**) — an opt-in enrichment layer
  that turns everyday coding sessions into a personalized, domain-organized
  knowledge base. Includes a coaching pillar with five named deterministic
  styles (`hints`, `socratic`, `pair`, `review-only`, `silent`) plus
  `default` (no coaching modification).

---

## Quick start

### 1. Create your repository

On GitHub, open [b150005/ecc-base-template](https://github.com/b150005/ecc-base-template)
and click **Use this template**.

### 2. Clone and open

```sh
git clone https://github.com/<your-username>/<your-repo>.git
cd <your-repo>
```

### 3. Run the initializer

```sh
.claude/meta/scripts/init.sh
```

This will prompt you for a project name, one-line description, and tech stack,
then replace the `## About This Project` placeholder in `.claude/CLAUDE.md`
and copy `.env.example` to `.env`. Re-running is safe.

Non-interactive form:

```sh
.claude/meta/scripts/init.sh \
  --project-name "TaskFlow" \
  --description "Team task management API" \
  --stack "Go / Gin / PostgreSQL"
```

### 4. Start working

Open the repo in Claude Code (`claude` in the repo root) and give the
orchestrator a real task. Try something concrete, for example:

> Design and implement a REST endpoint `POST /tasks` that validates input,
> persists to PostgreSQL, and returns the created resource. Use TDD.

The orchestrator delegates to product-manager for acceptance criteria,
architect for the module boundaries, implementer for code, and the quality
agents for review — you steer the hand-offs.

### 5. (Optional) Enable Developer Learning Mode

```
/learn on [junior|mid|senior]     Enable at the chosen level
/learn off                        Disable
/learn status                     Show current state
/learn focus <domain>[,<domain>]  Narrow teaching effort
/learn coach <style>              Set coaching style (hints|socratic|pair|review-only|silent|default)
/learn coach list                 List available styles
```

`/quiet` is a companion Skill that suppresses the Learning trailer (the
appended summary at the end of an agent response) for a single turn.
Knowledge-base writes under `.claude/learn/knowledge/` continue normally.

Full Learning Mode explainer lives in
[.claude/meta/references/learning-mode-explained.md](.claude/meta/references/learning-mode-explained.md).
If you do not plan to use Learning Mode, delete `.claude/meta/` and
`.github/workflows/learn-invariants.yml` after step 3 — the machinery is
opt-in and adopters are free to drop it entirely.

---

## The 15-agent team

All agents are ecosystem-agnostic. They detect the project's language and
framework at runtime by reading `.claude/CLAUDE.md` and your project's manifest
files (`package.json`, `pubspec.yaml`, `go.mod`, `Cargo.toml`, etc.). The
orchestrator coordinates the team; specialists are invoked by the orchestrator
or directly.

| Agent | Phase | Role |
|-------|-------|------|
| **orchestrator** | All | Analyzes issues, plans work, delegates to specialists, coordinates the session |
| **product-manager** | Planning | Spec authoring, user stories, acceptance criteria, backlog prioritization |
| **market-analyst** | Planning | Market research, competitor analysis, user segment identification |
| **monetization-strategist** | Planning | Business model design, pricing strategy, revenue analysis |
| **ui-ux-designer** | Design | UI/UX design, usability review, accessibility compliance |
| **docs-researcher** | Research | API verification, framework behavior, version-specific changes against primary docs |
| **architect** | Design | System architecture, technology decisions, ADR creation |
| **implementer** | Build | Code implementation following architecture specs and TDD |
| **code-reviewer** | Quality | Code quality, maintainability, standards adherence |
| **test-runner** | Quality | Test execution, coverage reporting, TDD support |
| **linter** | Quality | Static analysis and code style enforcement |
| **security-reviewer** | Quality | Vulnerability detection, secret scanning, OWASP Top 10 |
| **performance-engineer** | Quality | Profiling, bottleneck identification, optimization |
| **devops-engineer** | Release | CI/CD, deployment strategy, release management |
| **technical-writer** | Release | Documentation, changelog, bilingual docs maintenance |

### Model tiers

Each agent declares its model in frontmatter using a Claude Code alias
(`opus` / `sonnet` / `haiku` / `inherit`), which resolves to the latest version
in that family. The template ships a mixed fleet — the right model for the job
rather than a single floor. Current assignment: **Opus** for deep-reasoning
decisions (architect, security-reviewer, performance-engineer,
monetization-strategist), **Sonnet** for authoritative output (most of the
team), **Haiku** for tool-wrapping agents with deterministic oracles (linter,
test-runner), and **inherit** for the orchestrator.

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
├── .env.example               ← template for environment variables
├── .env                       ← created by the initializer; never committed
├── .gitignore
├── .gitignore.example
├── .gitattributes
├── .claude/                   ← Claude Code machinery
│   ├── CLAUDE.md              ← project instructions (edit the About section first)
│   ├── agents/                ← 15 agent definition files
│   ├── skills/                ← /learn and /quiet skills
│   ├── templates/             ← copy-and-fill ADR/spec templates
│   ├── meta/                  ← template-internal ADRs, references, init script
│   ├── settings.json
│   └── settings.local.json    ← gitignored, user-specific
├── .devcontainer/             ← VS Code Dev Containers scaffold
└── .github/                   ← CI, dependabot, issue/PR templates
```

You own every visible root file. The template does not reserve `docs/`,
`src/`, `scripts/`, or any other top-level directory name.

### Placing your own ADRs and specs

Copy `.claude/templates/adr-template.md` to wherever you want your ADRs to
live. Common choices:

- `adr/001-use-postgresql.md` at the repo root
- `adr/en/001-use-postgresql.md` + `adr/ja/001-use-postgresql.md` for bilingual projects
- `docs/adr/001-use-postgresql.md` if you already have a `docs/` tree

The same applies to `spec-template.md`. There is no forced location.

---

## Maintaining the template itself

If you are working on **ecc-base-template** (this repository, not a fork),
template-internal documentation lives under `.claude/meta/`:

- `.claude/meta/adr/` — architecture decisions for the template itself
- `.claude/meta/prd/` — product requirements for template features
- `.claude/meta/references/` — long-form explainers and worked examples
- `.claude/meta/scripts/` — the initializer and invariant checker
- `.claude/meta/CHANGELOG.md` — template's own release history
- `.claude/meta/CHANGELOG.legacy.md` — full history through v2.2.0 (pre-v3 restructure)

CI enforces Learning Mode invariants via
`.claude/meta/scripts/check-learn-invariants.sh`, wired up through
`.github/workflows/learn-invariants.yml`.

---

## License

[MIT](LICENSE)
