# CLAUDE.md Authoring — Invariant Rules

> Loaded on demand from `SKILL.md`. English-only by design (see SKILL.md
> frontmatter).

The four rules below are inlined into the Skill because they are
**structural**: Anthropic would have to overhaul Claude Code's memory model
to invalidate them. Each rule cites the original source and gives the
verification date.

Last verified: **2026-05-06** (two independent paths: Context7 MCP +
direct URL fetch).

---

## Invariant 1 — Hierarchy exists

**Rule.** Three discoverable locations, each with a defined role:

| Location | Scope | Sharing |
|---|---|---|
| `~/.claude/CLAUDE.md` | Global (all projects) | Personal, not version-controlled |
| `./CLAUDE.md` or `./.claude/CLAUDE.md` | Project | Team-shared, checked in |
| `./<dir>/CLAUDE.md` | Subdirectory | Team-shared, loaded on demand |

`./CLAUDE.local.md` exists as a project-personal override; it should be
gitignored.

**Precedence** on conflict: project beats global. Managed/enterprise
settings (`/etc/claude-code/managed-settings.json`) override everything,
but that channel is for organisations, not file authors.

**Why this is invariant.** The hierarchy is the way Claude Code expresses
the difference between "rules that follow me everywhere" and "rules that
belong to this codebase." Removing it would require redesigning the
memory model. Anthropic has only added new locations (auto-memory, path
rules), never removed.

**Source.** `https://code.claude.com/docs/en/memory` —
"Choose where to put CLAUDE.md files."

---

## Invariant 2 — Root content survives compaction; subdirectory and path-scoped content do not

**Rule.** Project-root `CLAUDE.md` is reloaded whole when context is
compacted. Subdirectory `<dir>/CLAUDE.md` files and path-scoped rules
are summarized away during compaction and only reload when a matching
file is touched again.

**Practical consequence.** **Place permanent-need-to-know content at
the root; place narrowly-scoped content in subdirectories.** A "fact
that always matters" buried in `src/auth/CLAUDE.md` will be
intermittently invisible to Claude across long sessions.

**Why this is invariant.** This is the structural payoff of the
hierarchy. If subdirectory content survived compaction the same way as
root content, there would be no point in having a hierarchy at all —
every project's root `CLAUDE.md` would just import every subdirectory
file via `@path`.

**Source.** `https://code.claude.com/docs/en/context-window` —
compaction behaviour for path-scoped and subdirectory CLAUDE.md files.

---

## Invariant 3 — Code is not prose

**Rule.** Do not document anything Claude can infer by reading the source.
Document only what is **not in the code**:

- **Inferable (do not document)**: file structure, function signatures,
  imports, framework names visible in `package.json` / `pubspec.yaml` /
  `go.mod`, naming conventions visible in any 5 source files.
- **Not inferable (document)**: intent of a non-obvious workflow, the
  reason behind a design choice, deadlines and external constraints,
  dev-environment quirks ("requires Postgres ≥ 14 because of the
  `gen_random_uuid()` call"), repo-etiquette ("squash before merge,"
  "tags trigger release CI").

**Why this is invariant.** This is Anthropic's stated philosophy of what
`CLAUDE.md` is for: "persistent context [Claude] can't infer from code
alone." If you write things Claude can already see, you trade context
budget for nothing.

**Source.** `https://code.claude.com/docs/en/best-practices` —
"Write an effective CLAUDE.md."

---

## Invariant 4 — `@path/to/file` import syntax exists

**Rule.** A `CLAUDE.md` file may include `@path/to/file.md` references
(outside code blocks). Both relative and absolute paths are supported,
including `~` for home. Imported content is loaded into context **at
session launch**.

**Practical consequence.** Splitting one big `CLAUDE.md` into multiple
files via `@path` improves **organisation** but **does not save context
tokens** — every imported file is loaded the same way the original
content would have been. Token savings come from moving content to
Skills (loaded on demand) or to subdirectory `CLAUDE.md` files (loaded
on demand when the matching directory is touched).

**Why this is invariant.** The import syntax is part of how the memory
model is composed. The recursion-depth limit is volatile (currently 5,
verify before relying on it), but the existence of the syntax is not.

**Source.** `https://code.claude.com/docs/en/memory` —
"Import additional files."

---

## Re-verification protocol

When `docs-researcher` re-verifies these invariants (monthly or
half-yearly):

1. For each invariant, run the [docs-protocol.md](./docs-protocol.md)
   procedure and locate the corresponding section in current Anthropic
   Docs.
2. If the rule is **still present and unchanged**, update the
   "Last verified" date at the top of this file.
3. If the rule has **shifted** (e.g., a new precedence ordering was
   introduced), update the rule text, update SKILL.md's Invariant Core
   summary, and record the change in the project CHANGELOG.
4. If a rule has been **invalidated** (the structural property no
   longer holds), this is a Skill-breaking change: open an ADR
   amendment to ADR-007, downgrade the rule from "invariant" to
   "volatile" or remove it, and update the Skill's CHANGELOG entry to
   warn adopters.
