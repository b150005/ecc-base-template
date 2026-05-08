# ecc-base-template

A framework-agnostic GitHub template that ships a 18-agent development team
and an opt-in learning layer for high-quality, high-precision collaboration
with Claude Code.

[日本語版 README はこちら](README.ja.md)

---

## What you get

- **18 specialized agents** covering the full product lifecycle — orchestrator,
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

**What you'll see by default** (per ADR-009):

- **Plan Mode is on by default.** Claude proposes a plan and waits for your
  approval before any write or shell side effect. Toggle for the current
  session with Shift+Tab, or override per developer in
  `.claude/settings.local.json`.
- **Optional learning-aware output style.** Run `/output-style ecc-learn`
  once to switch on the bundled style — Claude inserts `TODO(human)`
  markers so you write small fragments yourself, and adds short `Insight:`
  notes that explain *why* a non-obvious choice was made.

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

## The 18-agent team

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
| **docs-researcher** | Research | API verification, framework behavior, version-specific changes against primary docs (verification-layer / research Generator) |
| **research-critic** | Research | Adversarial review of external-research outputs against primary sources, with primary-source-only citation (verification-layer / research Critic) |
| **adversarial-implementer** | Build | Parallel-implementation Critic for behavioural-delta verification (verification-layer / implementation Critic, default-off) |
| **architecture-critic** | Design | Counter-proposal Critic that takes rejected ADR alternatives seriously (verification-layer / design Critic, default-off) |
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
│   ├── agents/                ← 18 agent definition files
│   ├── skills/                ← /learn, /quiet, claude-md-authoring, verification-layer
│   ├── output-styles/         ← bundled `ecc-learn` output style (opt-in)
│   ├── hooks/                 ← UserPromptSubmit hook for coaching auto-context
│   ├── templates/             ← copy-and-fill ADR/spec templates
│   ├── meta/                  ← template-internal ADRs, references, init script
│   ├── settings.json          ← Plan Mode default + hook registration
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

### CLAUDE.md authoring Skill

The template ships a `claude-md-authoring` Skill that helps you keep
`CLAUDE.md`, `README.md`, and `.claude/agents/*.md` short and
structurally aligned with current Anthropic guidance.

- `.claude/skills/claude-md-authoring/SKILL.md` — entry point with
  Pre/Post checklists and the Override Protocol
- `.claude/skills/claude-md-authoring/invariants.md` — four invariant
  rules (verified against `code.claude.com/docs/en/{memory,best-practices,skills}`)
- `.claude/skills/claude-md-authoring/docs-protocol.md` — runtime
  verification chain (Context7 → URL → `llms.txt`)
- `.claude/skills/claude-md-authoring/examples.md` — concrete
  good/bad excerpts
- `.claude/meta/adr/007-claude-md-authoring-skill.md` — design rationale

The Skill is **manual-invoke only** (`disable-model-invocation: true`),
so it costs zero context unless you trigger it explicitly. Invoke it
when creating or significantly restructuring a context document; skip
it for routine small edits. CI verifies the Skill's structural
invariants (`.github/workflows/skill-invariants.yml`). An optional
monthly Anthropic-docs freshness diff is also shipped, default-off
(`.github/workflows/docs-freshness.yml`).

### Verification layer (adversarial review across three domains)

The template ships a `verification-layer` Skill that pairs every
artifact-producing agent with a Critic that uses a different tool
family and may cite only primary sources. Three independent domains:

- **`research`** (default-on; ADR-008). `docs-researcher` (Generator)
  declares a Tier on every external-research output; `research-critic`
  (Critic) reviews T1 and T2 outputs and must cite at least one
  **primary source** the Generator did not. Secondary sources (blogs,
  Q&A sites, AI summaries, translations of primary sources) are
  explicitly disallowed as the Critic's independent citation. Up to
  2 GAN rounds; T3 collapses to Generator self-check.
- **`implementation`** (default-off; ADR-010). `implementer`
  (Generator) writes the code; `adversarial-implementer` (Critic)
  re-implements the same acceptance criteria with a deliberately
  different approach, runs the test suite against both, and reports
  the behavioural delta. Constrained by a four-level ranking, a
  user-library precedence rule (an explicit pin disables levels 3-4),
  and an environment-safety contract (no system tooling installation,
  no Docker pulls, no manifest edits).
- **`design`** (default-off; ADR-010). `architect` (Generator) writes
  an ADR draft; `architecture-critic` (Critic) appends one concrete
  counter-proposal that takes a rejected alternative seriously — same
  Context, same constraints, different decision, full Consequences,
  citations from a different evidence base than the original ADR.

A cross-cutting **citation-discipline** CI check (default-on) scans
ADRs, PRDs, and Learning Mode knowledge entries for blocked
secondary-source links. The same allowlist powers the Critic.

Files:

- `.claude/skills/verification-layer/SKILL.md` — overview, shared
  invariants (Generator/Critic, primary-source-only, severity, tool
  families)
- `.claude/skills/verification-layer/research/{protocol,checklist,failure-modes}.md`
- `.claude/skills/verification-layer/implementation/{protocol,checklist,failure-modes}.md`
- `.claude/skills/verification-layer/design/{protocol,checklist,failure-modes}.md`
- `.claude/agents/{research-critic,adversarial-implementer,architecture-critic}.md`
- `.claude/templates/verification-review-template.md` — shared
  output format with per-domain sections
- `.claude/verification.yml.example` — opt-in config (per domain)
- `.claude/meta/adr/008-research-verification-layer.md` — research-
  domain rationale
- `.claude/meta/adr/010-verification-layer-generalization.md` —
  cross-domain generalization rationale

To opt in for `implementation` and `design`, copy
`.claude/verification.yml.example` to `.claude/verification.yml` and
set the relevant `enabled: true`. The `research` domain is on
when the file is present; with no file, all three domains are inert
and the citation-discipline CI is the only active piece (default-on
because the cost is essentially zero per CI run).

### Tracking upstream issues (default-off)

When a defect is caused by a third-party library or framework rather than
your own code, the template provides a lifecycle for it: triage, record,
track, and remove the workaround once the upstream patch lands.

- `.claude/templates/workaround-template.md` — copy to
  `workarounds/NNN-*.md` (the default `registry_dir`; or
  `docs/workarounds/NNN-*.md` if you keep a `docs/` tree) per workaround
- `.github/workflows/workaround-check.yml` — CI scaffold (config-gated;
  no `if: false` to remove)
- `.github/workaround-tracker.yml` — opt-in configuration
- `.claude/meta/adr/006-upstream-workaround-tracking.md` — full design
- `.claude/meta/references/upstream-workaround-tracking.md` — usage details

The 3-step "ours vs. upstream" triage protocol is run by **orchestrator**
+ **docs-researcher**; **implementer** places a
`WORKAROUND-UPSTREAM(<owner>/<repo>#<issue>, fixed=>=<version>)` marker
in source. The CI scaffold compares markers against the registry and
posts comments on Dependabot PRs that bump tracked packages.

**Opt-in is a single switch**: set `enabled: true` in
`.github/workaround-tracker.yml`. There is no second toggle to remove
from the workflow file — every job reads the config and short-circuits
when disabled. Projects with zero workarounds get zero CI noise.

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
