# CLAUDE.md Authoring — Examples

> Loaded on demand from `SKILL.md`. English-only by design.

Concrete excerpts that show how the invariants and checklists apply.
Each pair (Bad / Good) targets one rule; read the rule first in
[SKILL.md](./SKILL.md) or [invariants.md](./invariants.md).

---

## Example 1 — Invariant 3 (code is not prose)

### Bad

```markdown
## Architecture

We use Next.js 16 with the App Router. Pages live in `app/`. Each
route directory has a `page.tsx` and optional `layout.tsx`. We use
Server Components by default and add `"use client"` for interactive
ones. Database access goes through Drizzle ORM. Schemas are in
`db/schema.ts`. We use Tailwind for styles. Shared UI components are
in `components/ui/`.
```

Every fact above is recoverable by reading `package.json`,
`tsconfig.json`, and the directory listing. This block is dead
weight — it consumes ~150 tokens and tells Claude nothing it does
not already see.

### Good

```markdown
## Architecture (constraints, not facts)

- **Server Components by default.** A new route is a Server Component
  unless it needs DOM interactivity. Reach for `"use client"` only at
  the leaf level — wrapping a whole tree in a Client Component blows
  away SSR for everything inside it.
- **Schema is single-source.** Migrations are generated from
  `db/schema.ts`; never hand-edit migration SQL. If the migration is
  surprising, the schema is wrong.
- **No styling outside Tailwind.** No CSS Modules, no `styled-components`.
  This is enforced by ESLint, not just convention.
```

These are constraints and intent — not visible from a directory listing.

---

## Example 2 — Invariant 2 (root vs subdirectory)

### Bad — over-stuffed root `CLAUDE.md`

```markdown
# Project Context (root CLAUDE.md, 240 lines)

## Auth module

We use NextAuth with the Drizzle adapter. The session table lives in
`db/schema.ts`. Custom callbacks are in `lib/auth/callbacks.ts`. When
debugging session issues, set NEXTAUTH_DEBUG=1 ...

## Billing module

Stripe webhooks are handled in `app/api/webhooks/stripe/route.ts`.
The webhook signing secret is in 1Password vault "Stripe Live". Test
events use `stripe trigger` with the `--api-key` flag pointing at the
test key ...

## Email module

We use Resend. Templates are in `emails/` as React components. The
preview server runs on port 3001 ...
```

Each module's notes are scoped to that module. After the next
compaction, the auth-debug hint reloads only when an auth file is
touched — but here it sits in the root file, where it pays the full
context-token cost on every session, even when the work is in `email/`.

### Good — root summary + subdirectory detail

`CLAUDE.md` (root, ~80 lines):

```markdown
## Modules with their own context files

- `lib/auth/CLAUDE.md` — NextAuth session debugging, callback chain
- `app/api/webhooks/stripe/CLAUDE.md` — webhook secret rotation, test triggers
- `emails/CLAUDE.md` — Resend preview server, template invariants

The root file holds only repo-wide rules.
```

`lib/auth/CLAUDE.md` (loaded only when auth files are touched):

```markdown
- Set `NEXTAUTH_DEBUG=1` to see the full callback chain in stderr.
- Custom callbacks in `callbacks.ts` run **before** the default
  session-cookie write. Order matters.
- Session-table migrations are coupled to NextAuth releases — read
  the NextAuth changelog before bumping the package.
```

Now the auth detail is invisible until Claude actually opens an auth
file, and the root file stays well under the 200-line guard.

---

## Example 3 — Invariant 4 (`@path` does not save tokens)

### Bad — splitting "to save context"

`CLAUDE.md` (root):

```markdown
@architecture.md
@workflow.md
@testing.md
@deployment.md
```

This is the same content as one big file — every imported file is
loaded into context at session start. The split helps a human reader
navigate but **does not reduce token cost**. If the goal was to save
tokens, the author misunderstood imports.

### Good — split for organisation, not for tokens

```markdown
## Where things live

- Architecture overview is in this file.
- Detailed module-level notes are in `<module>/CLAUDE.md` files
  (loaded on demand when the module is touched).
- Long-form guides (deployment runbook, release process) live in
  `docs/` and are read by humans, not loaded into Claude context.
```

The split decision is now driven by **load behaviour** (on-demand
subdirectory loading), not by file count.

---

## Example 4 — Override Protocol declaration

### Bad — silent override

A project replaces Invariant 3 with "we DO document function
signatures" but does not record the change. Six months later, a new
contributor reads the Skill, runs the post-writing checklist, and
deletes the function-signature documentation as "code-derivable
content," breaking the integrator-facing reference.

### Good — explicit, dated override

In the project's own `CLAUDE.md`:

```markdown
## CLAUDE.md Authoring overrides

- **Invariant 3 (code is not prose) — partial override.** We
  intentionally document the public-SDK function signatures of
  `packages/sdk/` here because third-party integrators read this
  file before reaching the source. Other modules follow the
  default invariant.
  Reason: integrator onboarding feedback in 2026-Q1.
  Date: 2026-05-06.
```

A future reviewer sees the exception, sees the reason, and knows
exactly which files it covers.

---

## Example 5 — Pre-writing checklist applied

A user wants to add a "Performance budgets" section to a project's
root `CLAUDE.md`. Walk through the checklist:

| Item | Decision |
|---|---|
| Audience identified | Mixed — Claude needs the limits to follow them; humans need them on PRs. Both are served by the same content. **CLAUDE.md is correct.** |
| Top-level sections decided | "Performance budgets" sits naturally after "Code Quality Standards." |
| Subdirectory split considered | The budgets apply to the whole repo (LCP, INP, bundle size). They are not module-specific. **Root is correct.** |
| No code-derivable content planned | The numbers (e.g., LCP < 2.5s) are not in the code; they are constraints. **Pass.** |
| Volatile-rule values verified | Not citing any volatile rule. **N/A.** |
| Bilingual policy | Project is bilingual. Plan to update both `CLAUDE.md` and `CLAUDE.ja.md`. |

The section is appropriate for root `CLAUDE.md`, will not duplicate
code, and the bilingual sync is planned. Proceed.

---

## Example 6 — Post-writing review applied

After writing, the file has grown from 180 lines to 235. Run the
checklist:

| Item | Result |
|---|---|
| Under 200 lines | **Fail (235).** |
| No template placeholders | Pass. |
| `@path` imports valid | Pass. |
| Bilingual sync | Pass (both files updated). |
| No code-derivable content | One bullet describes that "we use Tailwind." Cut it. |
| Cross-references resolve | Pass. |
| Volatile citations dated | All volatile citations carry a verification date and source — e.g., `"... 200 lines (verified 2026-05-06, source: code.claude.com/docs/en/memory)"`. Pass. |

Two follow-ups:

1. Cut the Tailwind bullet (gains ~3 lines, brings the file to 232).
2. The 235-line breach is not solvable by trimming. Move the
   "Module-specific testing notes" subsection to the affected
   `<module>/CLAUDE.md` files. **This is the right move per
   Invariant 2** — those notes are scoped, so they belong in the
   subdirectory file and survive compaction only when relevant.

After both: file is 192 lines. Pass.
