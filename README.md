# ECC Base Template

A framework-agnostic GitHub template that ships a 15-agent development team and an opt-in learning layer called **Developer Growth Mode**.

[日本語版 README はこちら](README.ja.md)

---

## What you get

- **15 AI agents** covering the full product lifecycle — orchestrator, product-manager, architect, implementer, test-runner, code-reviewer, security-reviewer, performance-engineer, devops-engineer, technical-writer, and more. Ecosystem-agnostic: the agents detect your language and framework at runtime.
- **Developer Growth Mode** (optional, default **off**) — when you turn it on, every agent appends two short trailer sections to its response explaining the decisions it made and updating a domain-organized knowledge base under `.claude/growth/notes/`. Over many sessions, the notebook becomes a personalized reference you built by shipping real features.
- **Quality invariants in CI** — `scripts/check-growth-invariants.sh` enforces the default-off guarantee so Growth Mode never leaks into production artifacts.

---

## Quick start

### 1. Create your repository

On GitHub, open [b150005/ecc-base-template](https://github.com/b150005/ecc-base-template) and click **Use this template**.

### 2. Clone and open

```sh
git clone https://github.com/<your-username>/<your-repo>.git
cd <your-repo>
```

Open the repository in Claude Code (`claude` in the repo root).

### 3. Customize `.claude/CLAUDE.md`

`.claude/CLAUDE.md` is the project instructions file the agents read on every session. Replace the `## About This Project` placeholder with your context. The rest (agent table, workflow, testing requirements, documentation convention) is designed to carry over as-is.

### 4. Start working

Give the orchestrator a real task. Specialists are invoked by the orchestrator or directly. Growth Mode stays off unless you opt in.

### 5. (Optional) Enable Growth Mode

```
/growth on [junior|mid|senior]       Enable at the chosen level
/growth off                          Disable
/growth status                       Show current state
/growth focus <domain>[,<domain>]    Narrow teaching effort to specific domains
/growth unfocus                      Clear focus
/growth level <junior|mid|senior>    Change level without toggling
/growth domain new <key>             Create a custom domain (confirmation required)
```

`/quiet` is a companion Skill that suppresses Growth trailers for a single agent response (notes are still updated).

**Full explanation** of levels, the notebook, philosophy, and a side-by-side example is in [docs/en/growth-mode-explained.md](docs/en/growth-mode-explained.md). **Authoritative design** is in [ADR-001](docs/en/adr/001-developer-growth-mode.md).

---

## The 15-agent team

All agents are ecosystem-agnostic. They detect the project's language and framework at runtime by reading `.claude/CLAUDE.md` and the project's manifest files (`package.json`, `pubspec.yaml`, `go.mod`, `Cargo.toml`, etc.). The orchestrator coordinates the team; the specialists are invoked by the orchestrator or directly by the developer.

| Agent | Phase | Role | Primary growth domains |
|-------|-------|------|----------------|
| **orchestrator** | All | Analyzes issues, plans work, delegates to specialists, coordinates the session | release-and-deployment |
| **product-manager** | Planning | PRD authoring, user stories, acceptance criteria, backlog prioritization | api-design |
| **market-analyst** | Planning | Market research, competitor analysis, user segment identification | market-reasoning |
| **monetization-strategist** | Planning | Business model design, pricing strategy, revenue analysis | business-modeling |
| **ui-ux-designer** | Design | UI/UX design, usability review, accessibility compliance | ui-ux-craft |
| **docs-researcher** | Research | API verification, framework behavior, version-specific changes against primary docs | ecosystem-fluency |
| **architect** | Design | System architecture, technology decisions, ADR creation | architecture, api-design, data-modeling |
| **implementer** | Build | Code implementation following architecture specs and TDD | ecosystem-fluency, error-handling, concurrency-and-async, implementation-patterns |
| **code-reviewer** | Quality | Code quality, maintainability, standards adherence | review-taste, testing-discipline, implementation-patterns, security-mindset |
| **test-runner** | Quality | Test execution, coverage reporting, TDD support | testing-discipline, performance-intuition |
| **linter** | Quality | Static analysis and code style enforcement | implementation-patterns |
| **security-reviewer** | Quality | Vulnerability detection, secret scanning, OWASP Top 10 | security-mindset |
| **performance-engineer** | Quality | Profiling, bottleneck identification, optimization | performance-intuition, concurrency-and-async |
| **devops-engineer** | Release | CI/CD, deployment strategy, release management | operational-awareness, release-and-deployment |
| **technical-writer** | Release | Documentation, changelog, bilingual docs maintenance | documentation-craft |

Each agent's domain ownership is declared in a `## Growth Domains` section at the top of its prompt body. See [ADR-002](docs/en/adr/002-growth-domains-location.md) for why the declaration lives in the body rather than in frontmatter. Secondary domains and the full taxonomy are in [docs/en/growth/domain-taxonomy.md](docs/en/growth/domain-taxonomy.md).

### Model tiers

Each agent declares its model in frontmatter. The template ships a mixed fleet — the right model for the job rather than a single floor — with the rule of thumb that agents whose output is consumed directly (authoritative prose, citations, translations) get Sonnet or Opus, while agents that wrap deterministic tools (linters, test runners) can safely use Haiku because the tool's own output is the ground truth.

**Opus 4.5** — deepest reasoning for decisions with the highest downstream cost:
architect, security-reviewer, performance-engineer, monetization-strategist

**Sonnet 4.6** — best all-around coding and writing, the default for authoritative output:
product-manager, market-analyst, ui-ux-designer, docs-researcher, implementer, code-reviewer, devops-engineer, technical-writer

**Haiku 4.5** — lightweight, for tool-wrapping agents with a deterministic downstream oracle:
linter, test-runner

**Inherit** — follows the orchestrating session's model:
orchestrator

---

## Project structure

```
.
├── .claude/
│   ├── CLAUDE.md                          # project instructions the agents read
│   ├── agents/                            # 15 agent definition files
│   ├── skills/
│   │   ├── growth/SKILL.md                # /growth toggle Skill
│   │   └── quiet/SKILL.md                 # /quiet trailer-suppression Skill
│   ├── growth/                            # Growth Mode runtime + shipped assets
│   │   ├── preamble.md                    # shipped — shared enrichment contract
│   │   ├── notes/                         # shipped — 19 seeded domain files (gitignored)
│   │   └── config.json                    # created on first /growth on (gitignored)
│   ├── settings.json
│   └── settings.local.json
├── .devcontainer/
│   └── devcontainer.json                  # commented template; customize per framework
├── .github/
│   ├── CODEOWNERS
│   ├── ISSUE_TEMPLATE/
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── dependabot.yml
│   └── workflows/                         # CI: lint/test/build + security scans
├── docs/
│   ├── en/                                # English source of truth
│   │   ├── adr/                           # architecture decisions
│   │   ├── prd/                           # product requirements
│   │   ├── growth/                        # growth domain taxonomy
│   │   ├── growth-mode-explained.md       # long-form Growth Mode explainer
│   │   └── (template-usage.md, etc.)
│   └── ja/                                # Japanese translations (link to English source)
├── scripts/
│   └── check-growth-invariants.sh         # CI check for default-off invariants
├── .env.example
├── .gitignore
├── .gitignore.example                     # shows the opt-in inversion for sharing notes
├── LICENSE
├── README.md                              # this file (English)
└── README.ja.md                           # Japanese translation
```

Note: `.claude/growth/preamble.md` and the 19 seeded notes under `.claude/growth/notes/` ship with the template. `config.json` alone is runtime-created on first `/growth on`. Both `config.json` and `notes/` are gitignored by default so personal state and private learning material do not leak into commits; see [growth-mode-explained.md](docs/en/growth-mode-explained.md#notes-are-private-by-default) for the opt-in path.

---

## Developing the template itself

Significant decisions are recorded as ADRs in `docs/en/adr/`. Current ADRs:

- [`000-template.md`](docs/en/adr/000-template.md) — ADR format template
- [`001-developer-growth-mode.md`](docs/en/adr/001-developer-growth-mode.md) — Growth Mode design decision
- [`002-growth-domains-location.md`](docs/en/adr/002-growth-domains-location.md) — why Growth Domains live in the prompt body

Product requirements are in [`docs/en/prd/`](docs/en/prd/). The PRD for Developer Growth Mode is the authoritative functional specification.

When working on the template itself, the same agent workflow applies: the orchestrator coordinates, the architect records decisions as ADRs, and the implementer works against the PRD's acceptance criteria.

---

## License

[MIT](LICENSE)
