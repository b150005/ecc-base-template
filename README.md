# ECC Base Template

A framework-agnostic repository template that ships a 15-agent development team and an opt-in learning layer called Developer Growth Mode.

[日本語版 README はこちら](README.ja.md)

---

## Why this template exists

This template was built because I wanted it for my own projects. Starting a new repository and immediately having a full agent team — orchestrator, architect, implementer, test runner, code reviewer, and the rest — ready to work within a structured workflow was something I had to set up from scratch every time. The template captures that setup once. If it is useful to someone else, that is a natural consequence of publishing it, not a design goal.

The philosophy underneath is straightforward: agents do the work, and with Developer Growth Mode enabled, the developer grows toward expertise by shipping real features alongside them. The agents are not tutors, and this template is not a course. Growth happens as a side effect of doing real work with agents that explain their reasoning when asked to.

---

## Developer Growth Mode

Developer Growth Mode is the template's flagship feature. It is an opt-in annotation layer that sits on top of the 15-agent team. When it is off — which is the default — the agents produce exactly the same output they would without the feature present. Not approximately the same. Byte-identical in substantive content. When it is on, each agent that completes a task appends two trailer sections to its response, calibrated to a declared experience level.

The two sections are `## Growth: taught this session` and `## Growth: notebook diff`. The first captures what was taught in this response — the decision rationale, the trade-off, the alternative considered and why it was not chosen, and where in the project's own ADRs or canonical external documentation the reasoning is grounded. The second records the maintenance operation performed on the knowledge base: which domain file under `.claude/growth/notes/` was touched, which section within that file, and what kind of operation was applied — add, deepen, refine, correct, or new-domain. They cite, they do not lecture. Note depth follows the concept being explained, not an artificial budget. A junior-level explanation of a foundational pattern is several paragraphs because it needs to build scaffolding from first principles. A senior-level trade-off note may be a single paragraph because that is what the decision demands. There are no length caps — no token budgets, no note counts, no sentence limits. The artifact — the code, the architecture document, the test file, the security report — is always first. The Growth trailers always follow.

### What changes when Growth Mode is ON

When Growth Mode is active, each agent in the team reads `.claude/growth/config.json` before completing its response. If `enabled` is `true`, the agent appends the two trailer sections after its primary output. The generated artifact is not touched. No inline educational comments are added to production code. No files are written to `docs/` or anywhere outside `.claude/growth/`. The trailer sections appear in the chat response, and each agent also updates the corresponding domain file under `.claude/growth/notes/<domain>.md` using a non-destructive enrichment operation defined in `.claude/growth/preamble.md`. The knowledge base is not a chronological log; it is organized by domain, and each session enriches existing sections or opens new ones as understanding accumulates across real project decisions.

What changes in practice: the developer learns the name of the pattern being applied, the reason this project chose it over the common alternative, and the ADR or external reference that records that decision. Over many sessions this adds up to something more than isolated tips. It adds up to a mental model of how the project's decisions fit together.

### The three levels

**junior** — Full Growth Notes on every response where a reasonable alternative exists. The note names the pattern, explains why it was chosen over the obvious alternative, and tells the reader what to look for in related code. The note assumes the reader has not encountered this pattern before. Up to three notes per response.

**mid** — Growth Notes only on non-obvious decisions: framework-specific idioms, cross-cutting concerns, trade-offs that are not visible in the code itself. Notes are omitted on well-established conventions the segment is expected to know. Up to three notes.

**senior** — Trade-off notes only, and only when the agent made a non-default choice. The note names the default and explains why it was rejected. No explanatory prose. Often zero notes per response. The use case here is a quick second opinion or a note to hand to a colleague in a review.

The level is a filter over which observations qualify as notes at all — it is not a knob for verbosity. A `senior`-level response that involved no non-default choices emits zero notes. That is correct behavior.

### The notes directory

The notes directory at `.claude/growth/notes/` is a living reference organized by domain, not a chronological log. Agents enrich, deepen, and refine the same domain files over time as relevant decisions accumulate across sessions. A session does not append a dated entry; it opens the file for the relevant domain and either adds a new section, deepens an existing section, or refines an older entry as understanding matures.

The 19 canonical domain files are pre-seeded at feature install time. After many sessions on a real project, a subset of them will have grown substantially. A developer's directory might look like this:

```
.claude/growth/notes/
├── architecture.md             # layered architecture, event sourcing, ACL placement, ADR references
├── business-modeling.md        # pricing model trade-offs, unit economics, monetization patterns
├── persistence-strategy.md     # repository pattern, option vs null, ADR-007, query boundaries
├── error-handling.md           # Result<T,E>, railway-oriented programming, boundary contracts
├── security-mindset.md         # OWASP notes, auth patterns, input validation conventions
├── testing-discipline.md       # AAA pattern, fixture isolation, coverage targets, TDD cycle
└── performance-intuition.md    # profiling methodology, database query cost, caching trade-offs
```

Each file is organized by concept, not by session date. A note about the repository pattern that was introduced in session one and reinforced in session twelve lives in `persistence-strategy.md` in one coherent section — not scattered across two entries in a chronological log. When the architect makes a decision that refines the earlier understanding, the agent updates or deepens the entry rather than appending a separate paragraph below the original.

This is the key differentiator from every other tool that claims to explain AI decisions. An AI that explains each decision at the point of generation is useful. A set of files that capture the cumulative understanding derived from dozens of real decisions — organized by domain, refined over time, grounded in the project's own ADRs — is a personal textbook built by shipping real features.

### Notes are private by default

`.claude/growth/notes/` is gitignored by default, and so is `.claude/growth/config.json`. The reason is deliberate: notes contain the learner's mistakes, prior misunderstandings, and the revision history of their mental model. That is private learning material, not documentation intended for a team's shared repository. Teams who want a shared textbook — where accumulated domain knowledge is checked in and visible to all contributors — can opt in by inverting the gitignore pattern. A `.gitignore.example` file in the repository shows the exact pattern to add.

### Side-by-side example

The following example uses a small pagination utility. It is ecosystem-neutral TypeScript. The task is: implement a `paginate` function that takes a total item count, a page size, and a current page number, and returns metadata for the current page.

---

**Growth Mode OFF — implementer response:**

```typescript
export interface PageMeta {
  currentPage: number;
  pageSize: number;
  totalItems: number;
  totalPages: number;
  hasPrevious: boolean;
  hasNext: boolean;
}

export function paginate(
  totalItems: number,
  pageSize: number,
  currentPage: number
): PageMeta {
  if (pageSize <= 0) throw new RangeError("pageSize must be positive");
  if (currentPage < 1) throw new RangeError("currentPage must be >= 1");

  const totalPages = Math.ceil(totalItems / pageSize);
  const clampedPage = Math.min(currentPage, Math.max(totalPages, 1));

  return {
    currentPage: clampedPage,
    pageSize,
    totalItems,
    totalPages,
    hasPrevious: clampedPage > 1,
    hasNext: clampedPage < totalPages,
  };
}
```

The implementer delivers the function, the interface, and boundary-condition handling. That is the complete response.

---

**Growth Mode ON, level junior — implementer response:**

The same function is delivered first, byte-identical. After the code block:

```
## Growth: taught this session

- Value Object pattern: the `PageMeta` return type is a plain data object, not a class, because this
  function crosses a module boundary. Callers should be able to serialize, log, or destructure the
  result without depending on a class hierarchy. This is the Value Object pattern from Domain-Driven
  Design; Martin Fowler's *Patterns of Enterprise Application Architecture* has the canonical description.

- Clamp-over-throw trade-off: `currentPage` is clamped to `[1, totalPages]` rather than throwing
  on out-of-range input. Pagination callers frequently supply stale page numbers from user state
  (browser history, cached query params), so silent correction is safer at a UI boundary than an
  uncaught exception. If strict validation is preferred for a different call site, the project's
  boundary-contract convention will live in an ADR (ADR-005 is the placeholder slot).

- Empty-collection handling: `Math.ceil(totalItems / pageSize)` handles the zero-items case
  correctly (yields 0) without a special branch, which is why it is preferred over integer
  division plus a remainder check. The empty-collection case is covered explicitly in
  `paginate.test.ts`.

## Growth: notebook diff

- notes/architecture.md → add on `## Value Object`: introduced the Value Object section with
  a definition, when-to-use / when-not-to-use guidance, a pointer to `lib/pagination.ts` as
  the canonical in-project example, and a reference to Martin Fowler's catalog entry.
```

**What gets written to `.claude/growth/notes/architecture.md`:**

The agent appends or updates the Value Object entry:

```markdown
## Value Object

A Value Object is a data structure that is fully described by its fields and carries no
identity. It is immutable by convention and safe to serialize, compare by equality, and pass
across module boundaries without introducing a dependency on a class hierarchy.

**When to use it**: return types from pure-computation functions that cross module or
process boundaries (e.g., pagination metadata, search result summaries, validation reports).

**When not to use it**: when the structure has behavior that must be encapsulated, or when
identity tracking is required (prefer an Entity in those cases).

**In this project**: `PageMeta` in `lib/pagination.ts` is a canonical example. See also
the ADR convention at `docs/en/adr/` for when new Value Objects warrant a formal record.

**Reference**: Martin Fowler, *Patterns of Enterprise Application Architecture*, Value Object
pattern, https://martinfowler.com/eaaCatalog/valueObject.html
```

The entry did not exist before this session. On the next session where a Value Object appears, the agent deepens the entry if the new context adds something — for instance, if a later session introduces a more complex case involving nested Value Objects, that case is added as a subsection of the same entry, not filed under a new date heading.

---

## The 15-agent team

All agents are ecosystem-agnostic. They detect the project's language and framework at runtime by reading `.claude/CLAUDE.md` and the project's manifest files (`package.json`, `pubspec.yaml`, `go.mod`, `Cargo.toml`, etc.). The orchestrator coordinates the team; the specialists are invoked by the orchestrator or directly by the developer.

When Growth Mode is active, each agent contributes to the domain notes in `.claude/growth/notes/` according to the domains listed below. The full domain taxonomy is defined in [`docs/en/growth/domain-taxonomy.md`](docs/en/growth/domain-taxonomy.md).

Each agent's `Growth domains` column lists its primary contribution domains; secondary domains are defined in [ADR-001](docs/en/adr/001-developer-growth-mode.md) and the taxonomy.

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

The old README listed 14 agents. The current team has 15. `docs-researcher` was added to give the team a dedicated research specialist: an agent that verifies API behavior, framework changes, and migration paths against primary documentation before code is written, rather than relying on training data that may be stale.

> **Implementation note.** Each agent's domain ownership is declared in a `growth_domains:` key in its frontmatter and referenced in the agent prompt body. The official Claude Code sub-agent frontmatter schema is `name`, `description`, `tools`, `model`; `growth_domains:` is a template-local convention that works because the agent prompt reads its own file as text. If Anthropic closes the frontmatter schema strictly in the future, this key will be moved into the agent prompt body. The default-off invariant is unaffected either way — it is enforced by `scripts/check-growth-invariants.sh`, not by frontmatter behavior.

---

## Getting started

### 1. Create your repository from the template

On GitHub, navigate to [b150005/ecc-base-template](https://github.com/b150005/ecc-base-template) and click **Use this template**. Choose a repository name and visibility. The template creates a new repository with the full `.claude/` structure, documentation, CI/CD pipelines, and community health files already in place.

### 2. Clone and open the repository

```sh
git clone https://github.com/<your-username>/<your-repo>.git
cd <your-repo>
```

Open the repository in your editor or directly in Claude Code (`claude` in the repository root).

### 3. Customize CLAUDE.md

`.claude/CLAUDE.md` is the primary instruction file for the agent team. The template ships with a placeholder "About This Project" section. Replace it with your project's context: what the project is, the frameworks in use, any domain-specific conventions. The rest of the file — the agent table, the development workflow, the testing requirements, the documentation convention — is designed to carry over as-is or with minor additions.

The template does not yet have a framework-specific manifest file (`package.json`, `go.mod`, etc.). Agents detect the ecosystem at runtime; create the manifest for your chosen framework and the agents will adapt automatically.

### 4. The default experience

With Growth Mode off (the default), the agents produce output and nothing else. The orchestrator analyzes issues and delegates work. The architect designs solutions and records decisions as ADRs in `docs/en/adr/`. The implementer writes code following TDD. The quality agents — code-reviewer, test-runner, linter, security-reviewer, performance-engineer — validate the work. The technical-writer keeps documentation current.

The workflow is defined in `.claude/CLAUDE.md` under "Development Workflow." Agents follow it without additional instruction. You interact with the orchestrator for most tasks; you can also invoke any specialist directly.

### 5. Enabling Growth Mode

There are three surfaces involved. Each has a distinct job.

**The Skill** is the action surface. `/growth` is a Claude Code Skill (defined at `.claude/skills/growth/SKILL.md`) that changes the state immediately for the current session. The skill uses `disable-model-invocation: true`, which means only the user can toggle Growth Mode — the model cannot auto-invoke it. This is a design guarantee, not a soft convention.

```
/growth on [junior|mid|senior]       Enable at the given level (or the last stored level)
/growth off                          Disable; preserve level and focus for the next enable
/growth status                       Print current state and recent notebook-diff summaries
/growth focus <domain>[,<domain>]    Narrow agent teaching effort to specific domains
/growth unfocus                      Clear focus; treat all domains equally
/growth level <junior|mid|senior>    Change level without toggling enabled
/growth domain new <key>             Create a custom domain file (prompts for confirmation)
```

`/quiet` is a separate, companion Skill at `.claude/skills/quiet/SKILL.md`. It suppresses the `## Growth: taught this session` and `## Growth: notebook diff` trailer sections for the **immediately following** agent response only. Domain notes are still written; only the chat-visible trailer is hidden. State is not modified. The next user turn restores normal trailer behavior.

**The config file** is the state surface. `.claude/growth/config.json` persists the level and focus across sessions. It is created on first `/growth on` invocation and is not present in a freshly cloned repository. Its schema:

```json
{
  "enabled": true,
  "level": "junior",
  "focus_domains": [],
  "updatedAt": "2026-04-22T00:00:00Z"
}
```

- `enabled` — whether Growth Mode is on. A missing or unparseable config is treated as disabled.
- `level` — `"junior"`, `"mid"`, or `"senior"`. Preserved across `/growth off` so the next `/growth on` restores it.
- `focus_domains` — array of domain keys (e.g. `["architecture", "testing-discipline"]`). When non-empty, agents write full enrichment entries for teaching moments in these domains; teaching moments in other domains are written only when genuinely load-bearing. This is a soft priority signal, not a per-agent on/off switch — all 15 agents continue to participate.
- `updatedAt` — ISO 8601 timestamp written by the `/growth` Skill on every state change.

**The CLAUDE.md pointer** is the discovery surface. It is a short pointer section in `.claude/CLAUDE.md` telling you the feature exists, where its runtime files live, and how to activate it. You do not need to edit CLAUDE.md to use Growth Mode; the pointer is there so you do not have to remember the invocation.

### 6. Your first session with Growth Mode on

Enable it, then give the orchestrator a real task — not a tutorial exercise, but actual work for your project. A reasonable first task: implement a feature from your backlog, or ask the architect to design the data layer for your domain model.

The agents will complete the task. Each one that contributed will also emit a `## Growth: taught this session` section with observations on the decisions made, and a `## Growth: notebook diff` section recording which domain file under `.claude/growth/notes/` was touched and what kind of operation was applied. These sections appear after the artifact, not inside it.

After the session, look at `.claude/growth/notes/`. The domain files will have been created or updated. Read them. They are written in the language of your actual codebase decisions, not in the language of a generic tutorial.

---

## The philosophy behind Growth Mode

### Annotations are a separate layer, not a behavior change

Growth Notes never appear inside generated artifacts. They are not inline comments in production files, not added to test code, not embedded in documentation. They are a trailing section in the agent's chat response. The code the implementer writes when Growth Mode is on is the same code it writes when Growth Mode is off. This is not enforced by hashing agent output — LLM output is non-deterministic, and golden-file regression against it would flake. It is enforced by three deterministic CI checks in `scripts/check-growth-invariants.sh`: `disable-model-invocation: true` on the growth Skill, the guard branch in every growth-aware agent prompt, and the gitignore posture.

The reason for this strictness is that an annotation layer which bleeds into production artifacts is not an annotation layer — it is a code quality degradation. Comments added for pedagogical purposes accumulate technical debt. Growth Notes stay in the conversation.

### Notes are organized by domain, not by session

A chronological log records what happened. A domain-organized notes directory records what is known. Growth Mode does not maintain a chronological journal at all — the per-response "notebook diff" in the chat output is the session-level provenance record, and git history is the long-term audit trail. The notes directory is the structured knowledge layer. When an agent adds a note about the repository pattern in session three, and another agent references the repository pattern in session seventeen, the note in `persistence-strategy.md` is the canonical place where that knowledge lives — deepened by session seventeen, not duplicated alongside it.

This mirrors how expertise actually works. A developer who has worked on a codebase for two years does not remember every session. They have a mental model built from many encounters with the same patterns. The notes directory externalizes that model.

### Levels adjust depth, not whether knowledge is shared

The three levels do not represent "how much the developer is taught." They represent which decisions are worth noting. A junior developer benefits from notes on every pattern decision because most patterns are new. A senior developer is not served by notes on patterns they know; they are served by notes on the non-obvious choices — the cases where the agent picked an alternative worth examining.

An agent at `senior` level that produces zero Growth Notes has not failed. It has correctly determined that this particular response contained no decisions that warranted a note at that level. Zero notes is a valid and frequent outcome for senior sessions, and that is the point.

### All 15 agents participate

There is no subset of "learning agents." All 15 agents in the team contribute to the notes directory when Growth Mode is on, each in the domains relevant to their function. The security-reviewer contributes to `security-mindset.md`. The product-manager contributes to `api-design.md`. The devops-engineer contributes to `operational-awareness.md` and `release-and-deployment.md`. The ui-ux-designer contributes to `ui-ux-craft.md`. Restricting Growth Mode to a subset of agents would create blind spots: the developer would accumulate knowledge about implementation patterns but not about security trade-offs or infrastructure decisions, which is exactly the kind of incomplete picture that produces siloed thinking.

### `docs/en/` is the source of truth

Documentation is in `docs/en/` (English, source of truth) with Japanese translations in `docs/ja/`. Agents read from `docs/en/` only, to minimize context window usage. Japanese files include a header linking to their English source. This separation is a deliberate choice: maintaining two authoritative versions of the same document doubles the maintenance burden and guarantees eventual drift. One source of truth with one maintained translation is more reliable.

### Foundational context is preserved

Growth Notes are brief, but the domain notes files take the space they need. A notes entry that fully explains the repository pattern — when to use it, when not to, how it is applied in this specific project, the ADR that records the decision — is more useful than a compressed summary that omits the "when not to" section. Pruning for scan-ability is not done. The audience is a developer who intends to understand the codebase, not a visitor who wants a quick impression.

---

## Project structure

```
.
├── .claude/
│   ├── CLAUDE.md                          # agent instructions + single Growth Mode pointer
│   ├── agents/                            # 15 agent definition files
│   │   ├── orchestrator.md
│   │   ├── product-manager.md
│   │   ├── market-analyst.md
│   │   ├── monetization-strategist.md
│   │   ├── ui-ux-designer.md
│   │   ├── docs-researcher.md
│   │   ├── architect.md
│   │   ├── implementer.md
│   │   ├── code-reviewer.md
│   │   ├── test-runner.md
│   │   ├── linter.md
│   │   ├── security-reviewer.md
│   │   ├── performance-engineer.md
│   │   ├── devops-engineer.md
│   │   └── technical-writer.md
│   ├── skills/
│   │   ├── growth/
│   │   │   └── SKILL.md                   # /growth Claude Code Skill handler
│   │   └── quiet/
│   │       └── SKILL.md                   # /quiet per-invocation trailer suppression
│   ├── growth/                            # Growth Mode runtime + shipped assets
│   │   ├── preamble.md                    # shipped — shared enrichment contract for all agents
│   │   ├── notes/                         # shipped — 19 seeded domain files (gitignored by default)
│   │   │   ├── architecture.md
│   │   │   ├── api-design.md
│   │   │   ├── data-modeling.md
│   │   │   ├── persistence-strategy.md
│   │   │   ├── error-handling.md
│   │   │   ├── testing-discipline.md
│   │   │   ├── concurrency-and-async.md
│   │   │   ├── ecosystem-fluency.md
│   │   │   ├── dependency-management.md
│   │   │   ├── implementation-patterns.md
│   │   │   ├── review-taste.md
│   │   │   ├── security-mindset.md
│   │   │   ├── performance-intuition.md
│   │   │   ├── operational-awareness.md
│   │   │   ├── release-and-deployment.md
│   │   │   ├── market-reasoning.md
│   │   │   ├── business-modeling.md
│   │   │   ├── documentation-craft.md
│   │   │   └── ui-ux-craft.md
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
│   └── workflows/
│       ├── ci-base.yml                    # lint, test, build
│       └── security.yml                   # secret scanning, vulnerability checks
├── docs/
│   ├── en/                                # English source of truth
│   │   ├── adr/
│   │   │   ├── 000-template.md
│   │   │   └── 001-developer-growth-mode.md
│   │   ├── growth/
│   │   │   └── domain-taxonomy.md         # canonical list of 19 growth domains and their owners
│   │   ├── prd/
│   │   │   └── developer-growth-mode.md
│   │   ├── ci-cd-pipeline.md
│   │   ├── devcontainer.md
│   │   ├── ecc-overview.md
│   │   ├── github-features.md
│   │   ├── template-usage.md
│   │   └── tdd-workflow.md
│   └── ja/                                # Japanese translations (link to English source)
├── scripts/
│   └── check-growth-invariants.sh         # CI check: Skill flag, agent guard branches, gitignore
├── .env.example
├── .gitattributes
├── .gitignore
├── LICENSE
├── README.md                              # this file (English)
└── README.ja.md                           # Japanese translation
```

Note: the `.claude/growth/` directory ships with `preamble.md` (the enrichment contract) and `notes/` (the 19 pre-seeded domain files) already present in the template. Only `config.json` is created at runtime, on first `/growth on` invocation. Both `config.json` and `notes/` are gitignored by default so that personal state and private learning material do not leak into commits; see the "Notes are private by default" section for the opt-in path if your team wants to share notes.

---

## Developing the template itself

Significant decisions about the template are recorded as ADRs in `docs/en/adr/`. The current ADR list:

- `000-template.md` — ADR format template
- `001-developer-growth-mode.md` — the design decision for Growth Mode (context, decision, alternatives considered, consequences)

Product requirements are in `docs/en/prd/`. The PRD for Developer Growth Mode is the authoritative specification: acceptance criteria, functional requirements, non-functional requirements, and the default-off invariant.

When working on the template itself, the same agent workflow applies. The orchestrator can be asked to analyze a proposed change, the architect records the decision as an ADR, and the implementer works against the PRD's acceptance criteria.

---

## License

[MIT](LICENSE)
