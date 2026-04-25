# ADR-005: Template repository restructure — consumer layer vs template layer

## Status

Accepted — 2026-04-25

## Context

ecc-base-template is a GitHub template repository. Its value to users comes
from what they see when they fork it and open the new repo for the first time.
Through v2.2.0 the repository's top-level layout conflated two very different
kinds of content:

1. **Consumer layer** — things the adopting project owns and edits: `README`,
   `.env.example`, `.gitignore`, `LICENSE`, project-level agent definitions.
2. **Template layer** — things the template itself ships to make its machinery
   work: Learning Mode's `preamble.md`, the invariant-checking CI script,
   the template's own ADRs, its PRD, its migration guide, its worked example
   library, its explainer documents.

Both lived at the root, in `docs/`, `learn/`, `scripts/`, and `docs/en/adr/`.
The practical consequences for adopters were:

- `docs/en/adr/001..004` occupied the ADR number space. An adopter could not
  write `001-my-first-decision.md` without colliding with the template's
  history (or accepting a confusing "`005-...` is our first ADR" situation).
- `prd/` was an abbreviation that an adopter could not decode without reading
  the README — "decision-by-directory-name" was undermined by cryptic naming.
- `learn/preamble.md` and `scripts/check-learn-invariants.sh` forced two
  directory names adopters might legitimately want to claim for their own use
  (especially `scripts/`).
- `CHANGELOG.md` (21 KB) and the README's `v2.1.0 — Coaching Pillar:` banner
  made a freshly-forked repository look like a promo page for the template.
- The template's own `docs/en/learn/examples/` (≈19 worked-example files per
  language) sat next to whatever `docs/` the adopter wanted to author.

The goal of this ADR is to make the conflation structurally impossible going
forward, even at the cost of breaking every previously published path.

## Decision

Adopt a two-layer repository structure with an explicit rule: **the root
directory contains zero visible directories; every template-internal artifact
lives under `.claude/`.**

### Principles

1. **Consumer layer is minimal and obvious.** After `Use this template`, the
   adopter sees only `README.md`, `README.ja.md`, `CHANGELOG.md`, `LICENSE`,
   `.env.example`, `.gitignore`, `.gitignore.example`, `.gitattributes`, and
   three dot-directories: `.claude/`, `.github/`, `.devcontainer/`.
2. **Template layer is hidden in `.claude/`.** Learning Mode machinery,
   template-internal ADRs, the template's PRD, worked examples, migration
   guides, and the invariant-check script all move under `.claude/`.
   Adopters who never open `.claude/` never see them.
3. **Bilingual convention is `filename.md` + `filename.ja.md`.** The prior
   `docs/en/` + `docs/ja/` split made sense for a docs-heavy site but is
   unnecessary overhead for the template's internal references.
4. **Templates, not fixtures.** `adr-template.md` and `spec-template.md` live
   in `.claude/templates/` and are meant to be copied into whatever directory
   the adopter chooses (`adr/`, `docs/adr/`, `adr/en/`, etc.). The template
   does not claim an ADR directory.
5. **The Learning Mode runtime state relocates to `.claude/learn/`**, not the
   root `learn/`. This prevents collision with any adopter that wants to use
   `learn/` for product-side concepts (e.g. an education app).

### Mapping

| v2.x path | v3.0 path |
|---|---|
| `learn/preamble.md` | `.claude/skills/learn/preamble.md` |
| `learn/config.json` (runtime) | `.claude/learn/config.json` (runtime) |
| `learn/knowledge/` (runtime) | `.claude/learn/knowledge/` (runtime) |
| `scripts/check-learn-invariants.sh` | `.claude/meta/scripts/check-learn-invariants.sh` |
| `docs/en/adr/000-template.md` | `.claude/templates/adr-template.md` (+ `.ja.md`) |
| `docs/en/adr/001..004-*.md` | `.claude/meta/adr/*.md` (+ `.ja.md` siblings) |
| `docs/en/prd/developer-learning-mode.md` | `.claude/meta/prd/developer-learning-mode.md` (+ `.ja.md`) |
| `docs/en/learn/domain-taxonomy.md` | `.claude/meta/references/domain-taxonomy.md` |
| `docs/en/learn/examples/*.md` | `.claude/meta/references/examples/*.md` (+ `*.ja.md`) |
| `docs/en/migration/v1-to-v2.md` | `.claude/meta/references/migration/v1-to-v2.md` (+ `.ja.md`) |
| `docs/en/learning-mode-explained.md` | `.claude/meta/references/learning-mode-explained.md` (+ `.ja.md`) |
| `docs/en/{ci-cd-pipeline,devcontainer,ecc-overview,github-features,tdd-workflow,template-usage}.md` | `.claude/meta/references/<same>.md` (+ `.ja.md`) |
| `docs/en/index.md`, `docs/ja/index.md` | removed (v3 has no landing page) |
| `CHANGELOG.md` (template history through v2.2.0) | `.claude/meta/CHANGELOG.legacy.md` (retained for reference) |
| `CHANGELOG.md` (new) | starts from `## [Unreleased]` — intended as the adopter's changelog |

New artifacts:

- `.claude/meta/scripts/init.sh` — adopter's post-fork initializer.
- `.claude/meta/CHANGELOG.md` — the template's own ongoing changelog.
- `.claude/templates/spec-template.md` (+ `.ja.md`) — for product specs.

In-place edits across the codebase (not file moves but path-string updates):

- All 15 `.claude/agents/*.md` files: the trailing
  `## Developer Learning Mode contract` section now references
  `.claude/learn/config.json`, `.claude/skills/learn/preamble.md`, and
  `../meta/adr/00X-*.md` instead of `learn/config.json`,
  `learn/preamble.md`, and `../../docs/en/adr/00X-*.md`.
- `.claude/skills/learn/SKILL.md` and `.claude/skills/learn/preamble.md`:
  every internal path string updated to the v3 layout.
- `.github/workflows/learn-invariants.yml`: `paths:` triggers and the
  `run:` invocation point at `.claude/learn/**` and
  `.claude/meta/scripts/check-learn-invariants.sh`.
- `.claude/meta/scripts/check-learn-invariants.sh`: `repo_root` is now
  resolved via `git rev-parse --show-toplevel` (with a relative-path
  fallback) since the script moved three levels deep from the repo root.
- `.gitignore` and `.gitignore.example`: the Learning Mode entries point
  at `.claude/learn/knowledge/` and `.claude/learn/config.json`.

## Consequences

### Positive

- An adopter's first ADR is `001-*.md` in whichever directory they choose.
  There is no ADR-number collision and no directory they are forced to
  inherit.
- `docs/` is now an adopter-owned name. If the project wants MkDocs or Docusaurus
  at `docs/`, nothing in the template competes for that path.
- `scripts/` is similarly available to adopters.
- A freshly forked repository opens to a `README.md` that describes the
  template, not a `v2.1.0 Coaching Pillar` release banner.
- `.claude/meta/` becomes a clear contract: "everything here is the
  template's own business; delete it if you do not want to track template
  upstream changes."

### Negative

- Every external link into the v2.x paths breaks. The `CHANGELOG.legacy.md`
  preserves the history for archaeological use, but any PR or issue that
  referenced `docs/en/adr/001-developer-growth-mode.md` now points at a
  404-equivalent. The user explicitly accepted this cost — this ADR does not
  try to maintain backward compatibility.
- Adopters upgrading from v2.x must either merge the restructure manually
  (non-trivial) or re-template from v3 and migrate their project-specific
  content. There is no automated migration path because the template is not
  designed to be upgraded in place.
- Learning Mode's invariant checks are now in a directory that adopters
  might never visit. The CI workflow explicitly tells adopters that they
  should delete both `.github/workflows/learn-invariants.yml` and
  `.claude/meta/` if they do not plan to maintain Learning Mode.

### Neutral

- The all-under-`.claude/` convention means heavier `.claude/` growth over
  time. This is acceptable because `.claude/` is already the convention for
  Claude Code's own machinery; adding template-internal metadata there fits
  the existing mental model.
- The bilingual convention changes from `docs/en/` + `docs/ja/` to
  `*.md` + `*.ja.md` within a single directory. This matches the existing
  `README.md` / `README.ja.md` pattern and simplifies cross-linking.

## Alternatives considered

| Alternative | Why not chosen |
|---|---|
| Keep `docs/` at the root; prefix template ADRs with `template-` (e.g. `template-001-*.md`) | Does not free the ADR number space for adopters; leaves the template's explainers and examples competing with the adopter's `docs/` |
| Symlink `learn -> .claude/learn` at the root for backward compatibility | Preserves old paths but defeats the goal of a clean root; introduces symlink-related edge cases on Windows and in some CI runners |
| Move only `learn/` and `scripts/`; leave `docs/` alone | Half-measure. Leaves `docs/en/adr/` collision and `prd/` naming problem unresolved |
| Move to a fully flat root (no `docs/` visible, no `CHANGELOG.md`, only `README.md` + `LICENSE`) | Overkill. `CHANGELOG.md` at the root is a standard SemVer artifact adopters expect; hiding it confuses more than it helps |

## References

- [PRD: Developer Learning Mode](../prd/developer-learning-mode.md)
- [ADR-001: Developer Growth Mode](001-developer-growth-mode.md)
- [ADR-003: Learning Mode relocate and rename](003-learning-mode-relocate-and-rename.md)
- [ADR-004: Coaching pillar](004-coaching-pillar.md)
- User discussion recorded in the v3.0.0 planning session (2026-04-25):
  "ルート直下の可視ディレクトリは0にするのが望ましいです。"
