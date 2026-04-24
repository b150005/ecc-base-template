# ECC Base Template

> **v2.1.0 — Coaching Pillar:** Developer Learning Mode gains a second pillar — five deterministic coaching styles (`hints`, `socratic`, `pair`, `review-only`, `silent`) that change how agents work during implementation. Toggle with `/learn coach <style>`. Default-off; no behavior change for existing installs. See [ADR-004](docs/en/adr/004-coaching-pillar.md).
>
> **v2.0.0 — Breaking Change:** Developer Growth Mode is renamed to **Developer Learning Mode** and the feature directory moves from `.claude/growth/` to `learn/`. If you have enabled this feature and committed knowledge files, follow the migration guide at [`docs/en/migration/v1-to-v2.md`](docs/en/migration/v1-to-v2.md) before upgrading.

A framework-agnostic GitHub template that ships a 15-agent development team and an opt-in learning layer called **Developer Learning Mode**.

[日本語版 README はこちら](README.ja.md)

---

## What you get

- **15 AI agents** covering the full product lifecycle — orchestrator, product-manager, architect, implementer, test-runner, code-reviewer, security-reviewer, performance-engineer, devops-engineer, technical-writer, and more. Ecosystem-agnostic: the agents detect your language and framework at runtime.
- **Developer Learning Mode** (optional, default **off**) — when you turn it on, every agent appends two short trailer sections to its response explaining the decisions it made and updating a domain-organized knowledge base under `learn/knowledge/`. Over many sessions, the knowledge base becomes a personalized reference you built by shipping real features.
- **Quality invariants in CI** — `scripts/check-learn-invariants.sh` enforces the default-off guarantee so Learning Mode never leaks into production artifacts.

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

Give the orchestrator a real task. Specialists are invoked by the orchestrator or directly. Learning Mode stays off unless you opt in.

### 5. (Optional) Enable Learning Mode

```
/learn on [junior|mid|senior]              Enable at the chosen level
/learn off                                 Disable
/learn status                              Show current state
/learn focus <domain>[,<domain>]           Narrow teaching effort to specific domains
/learn unfocus                             Clear focus
/learn level <junior|mid|senior>           Change level without toggling
/learn domain new <key>                    Create a custom domain (confirmation required)
/learn coach <style>                       Set coaching style (hints|socratic|pair|review-only|silent|default)
/learn coach off                           Reset coaching to default (no modifications)
/learn coach list                          List available coaching styles
/learn coach show <style>                  Show a style's behavior rule
/learn coach scope <session|persistent>    Set persistence scope for coach subtree
```

`/quiet` is a companion Skill that suppresses Learning Mode trailers for a single agent response (knowledge files are still updated).

**Coaching styles** change how agents work during implementation — `hints` names the next step without writing the function body, `socratic` returns a focused question instead of code, `pair` writes scaffolding with `TODO(human):` markers, `review-only` refuses to write production code, `silent` suppresses all trailer noise. All styles are default-off; selecting `default` or running `/learn coach off` restores normal behavior. See [ADR-004](docs/en/adr/004-coaching-pillar.md) for the design.

**Full explanation** of levels, the knowledge base, philosophy, and a side-by-side example is in [docs/en/learning-mode-explained.md](docs/en/learning-mode-explained.md). **Authoritative design** is in [ADR-001](docs/en/adr/001-developer-growth-mode.md). **Rename and relocation rationale** is in [ADR-003](docs/en/adr/003-learning-mode-relocate-and-rename.md). **Coaching pillar design** is in [ADR-004](docs/en/adr/004-coaching-pillar.md).

---

## The 15-agent team

All agents are ecosystem-agnostic. They detect the project's language and framework at runtime by reading `.claude/CLAUDE.md` and the project's manifest files (`package.json`, `pubspec.yaml`, `go.mod`, `Cargo.toml`, etc.). The orchestrator coordinates the team; the specialists are invoked by the orchestrator or directly by the developer.

| Agent | Phase | Role | Primary learning domains |
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

Each agent's domain ownership is declared in a `## Learning Domains` section at the top of its prompt body. See [ADR-002](docs/en/adr/002-growth-domains-location.md) for why the declaration lives in the body rather than in frontmatter. Secondary domains and the full taxonomy are in [docs/en/learn/domain-taxonomy.md](docs/en/learn/domain-taxonomy.md).

### Model tiers

Each agent declares its model in frontmatter using a Claude Code alias (`opus` / `sonnet` / `haiku` / `inherit`), which always resolves to the latest version in that family — so the assignment below does not drift when Anthropic releases a new version. For the current version numbers, see the [Anthropic model overview](https://docs.claude.com/en/docs/about-claude/models/overview).

The template ships a mixed fleet — the right model for the job rather than a single floor — with the rule of thumb that agents whose output is consumed directly (authoritative prose, citations, translations) get Sonnet or Opus, while agents that wrap deterministic tools (linters, test runners) can safely use Haiku because the tool's own output is the ground truth.

**Opus** — deepest reasoning for decisions with the highest downstream cost:
architect, security-reviewer, performance-engineer, monetization-strategist

**Sonnet** — best all-around coding and writing, the default for authoritative output:
product-manager, market-analyst, ui-ux-designer, docs-researcher, implementer, code-reviewer, devops-engineer, technical-writer

**Haiku** — lightweight, for tool-wrapping agents with a deterministic downstream oracle:
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
│   │   ├── learn/SKILL.md                 # /learn toggle Skill
│   │   └── quiet/SKILL.md                 # /quiet trailer-suppression Skill
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
│   │   ├── learn/                         # learning domain taxonomy and examples
│   │   ├── migration/                     # upgrade guides (e.g., v1-to-v2.md)
│   │   ├── learning-mode-explained.md     # long-form Learning Mode explainer
│   │   └── (template-usage.md, etc.)
│   └── ja/                                # Japanese translations (link to English source)
├── learn/
│   ├── preamble.md                        # shipped — shared enrichment contract
│   ├── config.json                        # created on first /learn on (gitignored)
│   └── knowledge/                         # lazy-materialized — created per domain on first teaching moment (gitignored)
├── scripts/
│   └── check-learn-invariants.sh          # CI check for default-off invariants
├── .env.example
├── .gitignore
├── .gitignore.example                     # shows the opt-in inversion for sharing knowledge files
├── LICENSE
├── README.md                              # this file (English)
└── README.ja.md                           # Japanese translation
```

Note: `learn/preamble.md` ships with the template. `learn/knowledge/` is lazy-materialized — no files exist on disk until a teaching moment earns content for a domain. `learn/config.json` is runtime-created on first `/learn on`. Both `config.json` and `learn/knowledge/` are gitignored by default so personal state and private learning material do not leak into commits; see [learning-mode-explained.md](docs/en/learning-mode-explained.md#knowledge-files-are-private-by-default) for the opt-in path.

---

## Developing the template itself

Significant decisions are recorded as ADRs in `docs/en/adr/`. Current ADRs:

- [`000-template.md`](docs/en/adr/000-template.md) — ADR format template
- [`001-developer-growth-mode.md`](docs/en/adr/001-developer-growth-mode.md) — Learning Mode design decision (originally named Growth Mode; superseded in part by ADR-003)
- [`002-growth-domains-location.md`](docs/en/adr/002-growth-domains-location.md) — why Learning Domains live in the prompt body
- [`003-learning-mode-relocate-and-rename.md`](docs/en/adr/003-learning-mode-relocate-and-rename.md) — rename to Learning Mode and relocation to `learn/`
- [`004-coaching-pillar.md`](docs/en/adr/004-coaching-pillar.md) — v2.1.0 coaching pillar: five deterministic coaching styles (Output Styles–compatible file format, Learning Mode state and dispatch)

Product requirements are in [`docs/en/prd/`](docs/en/prd/). The PRD for Developer Learning Mode is the authoritative functional specification.

When working on the template itself, the same agent workflow applies: the orchestrator coordinates, the architect records decisions as ADRs, and the implementer works against the PRD's acceptance criteria.

---

## License

[MIT](LICENSE)
