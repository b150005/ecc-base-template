# ADR-003: Rename Growth Mode to Learning Mode, relocate output, lazy-materialize

## Status

Accepted. 2026-04-24.

## Metadata

- Date: 2026-04-24
- Deciders: Agent Team (architect lead; technical-writer terminology selection; product-manager examples strategy; ui-ux-designer directory ergonomics)
- Supersedes: directory layout and pre-seeding decisions in [ADR-001](001-developer-growth-mode.md) §Directory and seed files; the term "notes" / "notebook" throughout ADR-001, [ADR-002](002-growth-domains-location.md), `.claude/growth/preamble.md`, and all agent prompts
- Related: [ADR-001](001-developer-growth-mode.md), [ADR-002](002-growth-domains-location.md), v2.0.0 breaking release

## Context

Developer Growth Mode shipped in v1.1.0 and stabilized through v1.2.1. Early-fork feedback and an Agent Team audit in April 2026 surfaced three defects that are not separable — each compounds the others:

1. **The term `notes` undersells the artifact.** The output is a domain-organized reference built up over many sessions — closer to a personal textbook than to a scratchpad. "Notes" connotes informal, temporary capture; it primes learners (and agents) to treat the files as low-stakes jottings rather than curated earned understanding.

2. **The directory lives inside `.claude/`, which is harness-config territory.** Every other resident of `.claude/` is instructions Claude Code reads — agents, skills, settings, config. The learner's accumulating knowledge base is a **project artifact**, not harness machinery. Burying it next to `preamble.md` and `config.json` conflates two very different categories of content and makes it hard to discover, share with teammates, or selectively gitignore.

3. **Pre-seeding 19 placeholder files lies about what the feature has learned.** A fresh clone carries 19 near-identical 23-line stubs. `ls .claude/growth/notes/` shows structure that does not yet exist in content. Git diffs on first enrichment mix "placeholder deleted" noise with "real content added" signal. The preamble's Step 2 already handles the "file does not exist" branch correctly, so the placeholders are load-bearing for nothing.

Separately, the feature's own umbrella name — **Growth Mode** — is abstract. It describes neither the knowledge-accumulation pillar (which is passive recording) nor the new coaching pillar being designed for v2.1.0 (which is active in-session behavior change). Both pillars are forms of **learning**, so renaming the umbrella unlocks a name that covers both.

This ADR records the decision to address all four concerns atomically as a v2.0.0 breaking release, accepting the migration cost now while the template is young and forks are few.

## Decision

### 1. Rename the feature

| Surface | v1.x | v2.0.0 |
|---|---|---|
| Feature name (long) | Developer Growth Mode | Developer Learning Mode |
| Feature name (short) | Growth Mode | Learning Mode |
| Skill command | `/growth` | `/learn` |
| Trailer label 1 | `## Growth: taught this session` | `## Learning: taught this session` |
| Trailer label 2 | `## Growth: notebook diff` | `## Learning: knowledge diff` |

The umbrella becomes **Learning Mode**. Both pillars — passive knowledge accumulation and (v2.1.0) active coaching — are forms of learning on both sides of the interaction: the agent teaches, the learner learns. The name is intentionally bidirectional and covers the whole feature scope.

### 2. Relocate the directory out of `.claude/`

The entire feature directory moves to the repository root.

| Surface | v1.x | v2.0.0 |
|---|---|---|
| Feature directory | `.claude/growth/` | `learn/` (top-level) |
| Config file | `.claude/growth/config.json` | `learn/config.json` |
| Preamble file | `.claude/growth/preamble.md` | `learn/preamble.md` |
| Knowledge output | `.claude/growth/notes/<domain>.md` | `learn/knowledge/<domain>.md` |
| Skill directory | `.claude/skills/growth/` | `.claude/skills/learn/` |
| Docs directory | `docs/en/growth/` | `docs/en/learn/` |
| Examples directory | (n/a) | `docs/en/learn/examples/<domain>.md` |

`.claude/` retains only harness config and Skills — the platform's own vocabulary. The learner-owned artifact lives at project root where every other project artifact lives. The Skill itself stays in `.claude/skills/learn/` because Skills are Claude Code platform residents, not project artifacts.

### 3. Replace the term

`notes` and `notebook` are replaced throughout with `knowledge`. The output directory is `learn/knowledge/`. Trailer sections say "knowledge diff." Agent prompts, preamble, ADRs, and docs all reflect the new term.

### 4. Lazy-materialize the knowledge directory

v1.x shipped 19 placeholder files at `.claude/growth/notes/*.md`. v2.0.0 ships **zero** files under `learn/knowledge/`. The directory itself is gitignored. The first teaching moment for a domain creates `learn/knowledge/<domain>.md` using the seed shape already defined in `learn/preamble.md` §7. This makes `ls learn/knowledge/` a truthful dashboard of activity — files only exist when content has been earned.

### 5. Ship worked examples as a separate, read-only reference

To give learners an immediate sense of what a populated knowledge file looks like, v2.0.0 ships 19 worked examples at `docs/en/learn/examples/<domain>.md` (and Japanese mirrors at `docs/ja/learn/examples/`). These are:

- **Read-only references.** Agents never read, cite, or write under `docs/en/learn/examples/`. The preamble's read/write surface explicitly excludes this tree (§8).
- **Grounded in a shared fictional project.** All 19 examples reference *Meridian*, a B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query frontend, Kubernetes + GitHub Actions deployment). Cross-domain references feel earned rather than invented.
- **Level-aware.** Each concept entry is marked `[JUNIOR]`, `[MID]`, or `[SENIOR]` to match the three-level reasoning ladder from ADR-001.
- **Clearly distinguished from live content.** Every example file opens with a banner stating it is a read-only reference and not a user-generated file.

The examples are coexistence-friendly with lazy-materialize: a fresh fork has an empty `learn/knowledge/` and 19 populated `docs/en/learn/examples/` files. Learners read the examples to understand the format, then grow their own knowledge base as teaching moments fire.

## Alternatives Considered

| Alternative | Pros | Cons | Why Not Chosen |
|---|---|---|---|
| **A. Full v2.0.0 as specified above** (chosen) | Fixes all four concerns atomically; harness/artifact boundary restored; fresh clones are honest; term matches artifact shape; umbrella name covers both pillars | Breaking change; one-time migration cost | Chosen. The defects are coupled and piecemeal fixing would force two breaking releases. |
| **B. Rename-only, keep layout** | Lowest migration cost; no path changes | Leaves the harness/artifact boundary violation and the placeholder noise intact; renames the problem without fixing it | Not chosen. Addresses one of four concerns. |
| **C. Single-file journal** (`learn/knowledge.md` with H2-per-domain) | One file is easier to skim end-to-end | Already rejected in ADR-001; concurrent-agent edits in the same session create merge risk; 19 H2 sections become unwieldy | Not chosen. ADR-001 already evaluated and rejected this shape. |
| **D. Lifecycle subdirs** (`learn/knowledge/active/`, `/archived/`, `/superseded/`) | Explicit lifecycle signaling | Premature structure; agents are not qualified to assess "stable" vs. "pending"; contradicts the "organized by concept, not by maturity" invariant in preamble §Voice and Longevity | Not chosen. Adds structure before the content justifies it. |
| **E. Keep in `.claude/` but rename** (`.claude/learn/knowledge/`) | Fixes the term without path churn | Fixes term only, not the harness/artifact boundary; forkers still confuse `.claude/` with project deliverables | Not chosen. Addresses two of four concerns. |

## Decision Drivers

The decision is explicitly optimizing for the following, in priority order:

1. **Preserve the default-off byte-identity invariant** (preamble §1). All changes must continue to guarantee byte-identical output when Learning Mode is disabled.
2. **Honor the harness-config vs. project-artifact boundary** of `.claude/`. Project artifacts belong at project root; harness config and Skills belong under `.claude/`.
3. **Match terminology to the artifact's actual shape.** A domain-organized, accumulating, cross-referenced reference is *knowledge*, not *notes*.
4. **Keep fresh-clone footprint honest** — no files exist on disk until their content has been earned.
5. **Preserve deterministic CI enforcement.** No LLM-in-the-loop invariant checks; everything stays grep-able.
6. **Minimize forker migration burden** — the template is young, most forks have not enabled the feature, and the migration cost hits a small population.

## Consequences

### Positive

- **Clean harness/artifact boundary.** `.claude/` regains its identity as Claude Code platform territory only. `learn/` is unambiguously a project artifact.
- **Honest fresh-clone state.** `ls learn/knowledge/` returns nothing until real content exists. Git diffs on first enrichment show only real content, no placeholder noise.
- **Better umbrella term.** "Learning Mode" covers both the existing knowledge-accumulation pillar and the v2.1.0 coaching pillar without stretching.
- **Aligned vocabulary.** "Knowledge" matches the artifact's long-term reference shape. The trailer label "knowledge diff" reads naturally.
- **Examples ship populated.** Forkers see a realistic picture of what their own `learn/knowledge/` will look like after 15-20 sessions, without polluting their live learner surface.

### Negative

- **Breaking change for existing forks.** Any fork that has enabled Growth Mode and accumulated content in `.claude/growth/notes/` must migrate paths. A prose migration guide at `docs/en/migration/v1-to-v2.md` covers the steps (`git mv`, search/replace). No migration script is shipped — the template has few forks and the operation is mechanical.
- **One-time large PR.** Every document in the repository that mentions Growth Mode is touched in a single v2.0.0 PR. Review burden is higher than a typical feature PR, offset by the fact that most edits are mechanical path/term substitutions.

### Neutral

- **ADR-001 body is not rewritten.** It carries a "Superseded in part by ADR-003" header note at top. The architectural substance (levels, enrichment contract, trailers) remains governed by ADR-001; only directory layout and terminology are superseded.
- **ADR-002 gets a terminology pass.** The `## Growth Domains` section marker in agent files is renamed to `## Learning Domains` to match the umbrella. ADR-002's substance (prompt-body declaration, CI re-anchor) is unchanged.
- **CI invariant script renames** to `scripts/check-learn-invariants.sh` and updates its grep targets (`.claude/growth/notes/` → `learn/knowledge/`, `## Growth Domains` → `## Learning Domains`). The three deterministic checks remain.

## Implementation Notes

### Migration scope (single PR)

This is PR #1 of the v2.0.0 release. The coaching pillar (Output Styles–compatible behavior modes) is a separate deliverable targeted for v2.1.0 (PR #2) and is not included in this ADR's implementation scope.

1. **ADR-003** (this file) and the Japanese translation at `docs/ja/adr/003-*.md`.
2. **Preamble relocation and rewrite.** `.claude/growth/preamble.md` → `learn/preamble.md`, with all path and terminology substitutions.
3. **All 15 agent files.** Each `## Growth Domains` becomes `## Learning Domains`. Each "Developer Growth Mode contract" section updates path references and wording.
4. **Skill relocation.** `.claude/skills/growth/SKILL.md` → `.claude/skills/learn/SKILL.md`. The `/growth` command becomes `/learn`. The Skill body is rewritten for the new paths and vocabulary.
5. **CI script.** `scripts/check-growth-invariants.sh` → `scripts/check-learn-invariants.sh`. Grep targets update; the three deterministic checks remain unchanged in principle.
6. **.gitignore / .gitignore.example.** Default ignores `learn/knowledge/`; opt-in inversion block points at `!learn/knowledge/`.
7. **Documentation.** `docs/en/growth-mode-explained.md` → `docs/en/learning-mode-explained.md`. `docs/en/growth/domain-taxonomy.md` → `docs/en/learn/domain-taxonomy.md`. PRD renamed. All Japanese mirrors updated in parallel.
8. **ADR-001 and ADR-002.** Both get supersession headers and terminology passes. Body rewrites are avoided to preserve historical record.
9. **README.md and README.ja.md.** Terminology and path pass; v2.0.0 breaking-change banner at top.
10. **CLAUDE.md.** Project template instruction block updates to reference Learning Mode and new paths.
11. **Filesystem migration.** Delete `.claude/growth/notes/` (all 19 placeholders). Create `learn/config.json` and `learn/preamble.md` from their old locations. Create `docs/en/learn/examples/` with 19 Meridian-grounded example files.
12. **CHANGELOG.md.** v2.0.0 entry with breaking-change banner and link to migration guide.
13. **Migration guide.** `docs/en/migration/v1-to-v2.md` (and `docs/ja/migration/v1-to-v2.md`) — prose-only, covers the `git mv` and search/replace steps for forks that have enabled the feature and committed knowledge.

### Worked examples deliverable

- 19 files at `docs/en/learn/examples/<domain>.md`, 350–500 lines each, 3–5 concept entries per file.
- Shared reference project: **Meridian** (B2B task-management SaaS, Go + Gin + PostgreSQL + Redis backend, React + TanStack Query frontend, Kubernetes + GitHub Actions).
- technical-writer authors the universal template and 5 reference examples (testing-discipline, api-design, architecture, error-handling, market-reasoning) as the quality bar.
- Per-domain owning agents author the remaining 14, citing the reference examples.
- technical-writer performs a final voice-consistency pass.
- Japanese mirrors at `docs/ja/learn/examples/` authored in the same PR.

### Out of scope for ADR-003

- **Coaching pillar.** Output Styles–compatible in-session behavior modes (`hints`, `socratic`, `pair`, `review-only`, `silent`) are deferred to ADR-004 and PR #2 (v2.1.0). The current decision leaves room for the `coach` subtree in `learn/config.json` to be added without a second breaking change.
- **Structural changes to the taxonomy or enrichment contract.** Those remain governed by ADR-001. ADR-003 moves and renames; it does not restructure the protocol itself.
- **Automated migration script.** The maintainer explicitly chose prose-only migration instructions over a shipped shell script. The template's fork population is small and the migration is mechanical.
