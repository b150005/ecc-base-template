---
name: claude-md-authoring
description: >
  Provides reference material for writing, editing, and reviewing project context
  documents that Claude reads at session start: CLAUDE.md, README.md, and
  .claude/agents/*.md prompt files. Manages a checklist of invariant rules
  (verified against Anthropic official docs) and a runtime-verification protocol
  for volatile rules (numeric thresholds, UI shortcuts, version-specific
  features). Reference this Skill when creating or significantly modifying any
  of these context documents — routine small edits do not need it.

  Skill contents (Progressive Disclosure):
    SKILL.md       — overview, invariant checklist, override protocol, navigation
    invariants.md  — the four invariant rules in detail, with rationale
    docs-protocol.md — Context7 → URL fallback → llms.txt anchor procedure
    examples.md    — good / bad CLAUDE.md and agent.md structural examples

  This Skill is English-only by design, consistent with
  .claude/meta/references/upstream-workaround-tracking.md and
  .claude/meta/references/domain-taxonomy.md. The audience is engineers and
  agents who already read upstream English content directly.
disable-model-invocation: true
arguments: []
---

# CLAUDE.md Authoring

## Purpose

Keep project-context documents — `CLAUDE.md`, `README.md`, `.claude/agents/*.md` —
short, structured, and aligned with current Anthropic guidance. The goal is not
"shortest possible" but "as small as the content allows, with reference detail
deferred to subdirectory docs and Skills."

## When to invoke

- Creating a new `CLAUDE.md` from the template placeholder.
- Adding, removing, or restructuring top-level sections of an existing
  `CLAUDE.md`.
- Authoring or significantly editing an agent prompt file under
  `.claude/agents/`.
- Reviewing a PR that touches any of the above.

Do **not** invoke for:

- Fixing a typo in `CLAUDE.md`.
- Adding a single bullet to an existing list.
- Updating a file path or version number.

The 200-line guard for `CLAUDE.md` (verified) makes the cost of small
incremental edits much lower than the cost of large structural changes.
Pre-/post-checklists target the latter.

## Invariant Core

The four rules below are inlined here because they are structural — Anthropic
would have to overhaul Claude Code's memory model to invalidate them. They
**cannot be overridden** at the meta level: the section itself is part of the
template's contract. Individual rules can be overridden per project (see
"Override Protocol" below) but only with an explicit declaration.

For full rationale and original-source citations for each rule, see
[invariants.md](./invariants.md).

1. **Hierarchy exists** — global (`~/.claude/CLAUDE.md`), project
   (`./CLAUDE.md` or `./.claude/CLAUDE.md`), and subdirectory
   (`./<dir>/CLAUDE.md`) all load. Project takes precedence over global on
   conflict; subdirectory loads on demand when files in that directory are
   accessed.
2. **Root content survives compaction; subdirectory and path-scoped content
   do not.** Anything you put in subdirectory `CLAUDE.md` files is summarized
   away when the context is compacted, and only reloaded when a matching file
   is touched again. Root `CLAUDE.md` is reloaded whole. **Place
   permanent-need-to-know content at the root; place narrowly-scoped content
   in subdirectories.**
3. **Code is not prose.** Do not document anything that can be inferred by
   reading the source: imports, function signatures, file structure, naming
   conventions visible in the code. Document only what cannot be inferred:
   intent, constraints from outside the code (deadlines, regulatory),
   non-obvious workflows, dev-environment quirks.
4. **`@path/to/file` import syntax exists.** Both relative and absolute paths
   (including `~`) are supported. Imports are evaluated at session launch and
   the imported content is loaded into context — splitting a file via imports
   improves organization but **does not save context tokens**. Code-block
   `@path` references are not evaluated.

## Volatile rules (verify before authoring)

The following are not invariant — they are documented numbers, UI surfaces,
and version-specific features that Anthropic can change. Verify the current
value via the procedure in [docs-protocol.md](./docs-protocol.md) before
relying on them:

- The 200-line CLAUDE.md guard (current value verified for 2026-05). Treat as
  "around 200" if Docs are unreachable; never enforce it as a hard CI failure.
- The `@path` import recursion-depth limit (currently 5).
- The auto-memory `#` shortcut and the `/memory` command — UI surfaces evolve.
- The `disable-model-invocation: true` semantics for Skills (whether the
  description is also hidden — currently yes, "context cost to zero").

`docs-protocol.md` defines the Context7 → URL → `llms.txt` fallback chain.
If all three fail, fall back to the inlined Invariant Core only and tell the
user the volatile section was not verified. **Do not stop work** because Docs
are unreachable.

## Pre-writing checklist (for new or significantly restructured files)

Before opening the editor, confirm each item below. If any is unclear, stop
and discuss the structure first.

- [ ] **Audience identified.** CLAUDE.md serves Claude (and humans on the
  team); README.md serves humans first. They duplicate prose at your peril.
- [ ] **Top-level sections decided.** A typical `CLAUDE.md` has: About This
  Project, Architecture Principles, Agent Team, Document Templates,
  Development Workflow, Testing Requirements, Code Quality Standards,
  Extending This File. Sections that are placeholder-shaped today (one
  sentence, no details) belong in `README.md` or a subdirectory doc, not
  `CLAUDE.md`.
- [ ] **Subdirectory split considered.** If a section will exceed ~30 lines
  of detail, ask: does it apply to the whole repo, or only to one area? If
  the latter, put it in a `<dir>/CLAUDE.md` instead.
- [ ] **No code-derivable content planned.** Skim the bullet list. Anything
  visible by reading source (file paths, function names, framework name when
  it appears in `package.json`) is dead weight.
- [ ] **Volatile-rule values verified** if the doc cites any of them (e.g.
  the 200-line guard, the import depth). Use `docs-protocol.md`.
- [ ] **Bilingual policy decided.** The template's default is `<file>.md` +
  `<file>.ja.md` siblings (per ADR-005). Some references are intentionally
  English-only; if you are creating one, document the reason in the file's
  header.
- [ ] **Japanese typography uses half-width parens** (only when authoring
  a `.ja.md` file). Use ASCII `(` `)` instead of `（` `）` (U+FF08 /
  U+FF09). The rule applies to every `.ja.md` file in this repo and is
  enforced going forward; see `technical-writer` agent prompt for the
  rationale.
- [ ] **Agent `description` is trigger-shaped** (only when authoring or
  editing a file under `.claude/agents/`). Per Anthropic's sub-agents
  guidance, the `description` should answer *"when do I use this agent?"*
  with at least one concrete trigger phrase — typically beginning with
  "Use when …", "Use for …", or "Use immediately after …". Description
  text that lists capabilities without naming a trigger condition makes
  the orchestrator unable to delegate accurately. ADR-009 codifies this
  for the template; see `.claude/agents/orchestrator.md` for the
  reference shape.

## Post-writing review checklist

Run this after authoring, before commit.

- [ ] **`CLAUDE.md` is under 200 lines.** Verified Anthropic guidance: longer
  files reduce instruction adherence. If you are over, the first move is to
  split a section into a subdirectory `CLAUDE.md` or a Skill, not to compress
  the prose. ([invariants.md](./invariants.md) §3)
- [ ] **No template placeholders remain.** Search for `[YOUR PROJECT NAME]`,
  `[one-line description]`, `[language] / [framework]`, etc. Adopters who
  ship with these visible look unfinished.
- [ ] **`@path` imports point to existing files.** Relative paths from
  `CLAUDE.md`'s directory; absolute paths use `~` for home or `/abs/path`.
- [ ] **Bilingual sync, if applicable.** If `CLAUDE.md` was edited and a
  `CLAUDE.ja.md` exists, the Japanese version reflects the same structure
  (not necessarily a literal translation — see ADR-005 §Bilingual).
- [ ] **Japanese half-width-parens scan**, if a `.ja.md` was edited.
  Search the file for `（` and `）` (U+FF08 / U+FF09); replace with
  ASCII `(` and `)`. A one-liner that catches strays:
  `grep -n '[（）]' path/to/file.ja.md` should return nothing.
- [ ] **No code-derivable content snuck in.** Re-skim. If a bullet describes
  what the code does rather than why or what constraint shaped it, cut it.
- [ ] **Cross-references resolve.** All `[link](path.md)` and `ADR-NNN`
  references match real files.
- [ ] **Volatile-rule citations carry a verification date** if any are
  cited inline (e.g. "as of 2026-05, the limit is 200 lines").
- [ ] **Agent `description` trigger-test passes** (only for files under
  `.claude/agents/`). Read the `description` aloud as the answer to *"when
  should I invoke this agent?"* — if the answer is a list of capabilities
  rather than a triggering situation, rewrite it. See the pre-writing
  checklist item above for the rule and ADR-009 for the rationale.

## Override Protocol

Adopting projects can disable individual invariant rules when the rule does
not fit their context. Override is **per-rule**, declared explicitly, and
recorded in the project's own `CLAUDE.md`:

```markdown
## CLAUDE.md Authoring overrides

- Invariant 3 (code is not prose): partially overridden. We document
  function signatures of the public SDK in CLAUDE.md because our
  third-party integrators read it before reaching the source.
  Reason: <why>. Date: <YYYY-MM-DD>.
```

What you **cannot** override:

- The structure of the Invariant Core itself (you cannot redefine which
  rules are invariant — only opt out of one).
- The Pre/Post checklists (you can add items, not silently remove them).
- The English-only policy of this Skill's reference docs
  (`invariants.md`, `docs-protocol.md`, `examples.md`).

If you find yourself overriding three or more invariants, the Skill is not
a fit for your project. Delete the directory entirely; that is also a
supported state.

## Skill update cadence

This Skill's invariants were verified against Anthropic official docs on
**2026-05-06** via two independent paths (Context7 MCP and direct URL
fetch). Re-verification cadence:

- **Monthly**, by `.github/workflows/docs-freshness.yml` if the project
  enables it (default-off; configuration at `.github/docs-freshness.yml`).
- **Half-yearly**, manually by `docs-researcher` for the four invariants
  even if no diff was detected.

If a re-verification finds that an invariant has changed, the right
response is: (1) update `invariants.md`, (2) update this Skill's checklist
references, (3) record the change in the project CHANGELOG with a date.

## See also

- [invariants.md](./invariants.md) — full text and citations for the four
  invariant rules
- [docs-protocol.md](./docs-protocol.md) — runtime verification procedure
  for volatile rules
- [examples.md](./examples.md) — concrete good/bad excerpts
- [`.claude/meta/adr/007-claude-md-authoring-skill.md`](../../meta/adr/007-claude-md-authoring-skill.md)
  — design rationale (English)
- [`.claude/meta/adr/007-claude-md-authoring-skill.ja.md`](../../meta/adr/007-claude-md-authoring-skill.ja.md)
  — same, Japanese
