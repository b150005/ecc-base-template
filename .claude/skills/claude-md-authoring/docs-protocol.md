# CLAUDE.md Authoring — Docs Verification Protocol

> Loaded on demand from `SKILL.md`. English-only by design.

This document defines how an agent (typically `docs-researcher`)
verifies a **volatile rule** against current Anthropic documentation.
Use it when SKILL.md cites a number, UI surface, or version-specific
behaviour that you want to confirm before acting on it.

## Volatile rules covered

- The 200-line `CLAUDE.md` guard (numeric threshold).
- The `@path` import recursion-depth limit (currently 5).
- The `#` quick-add shortcut and the `/memory` command (UI surfaces).
- The exact effect of `disable-model-invocation: true` on Skills
  (currently: "context cost to zero" — description hidden until manual
  invoke).
- Any new field name or directive added to `SKILL.md` frontmatter.

## Step 0 — Decide whether you need this

If you are documenting an invariant from
[invariants.md](./invariants.md), you do **not** need this protocol —
those rules are already inlined and dated. Use the protocol only for
the volatile categories above.

## Step 1 — Context7 MCP (preferred)

Context7 mirrors `code.claude.com` docs and absorbs domain renames. It
is the lowest-cost first hop.

```text
1. Resolve the library:
   tool: mcp__context7__resolve-library-id
   args: { libraryName: "Claude Code", query: "<your question>" }
   expected: a libraryId such as `/websites/code_claude`
              (Benchmark Score around 83.85, "High" reputation)

2. Query the docs:
   tool: mcp__context7__query-docs
   args: { libraryId: "<from step 1>", query: "<your question>" }
   expected: a passage from code.claude.com with the volatile value
```

> **Note on tool names.** Some harnesses prefix MCP tool names with the
> plugin namespace, e.g. `mcp__plugin_ecc_context7__resolve-library-id`
> and `mcp__plugin_ecc_context7__query-docs`. Both naming patterns refer
> to the same Context7 server. Use whichever is exposed in your
> environment; the procedure is identical.

Cap usage at **3 total Context7 calls per question**. If the answer is
still unclear, fall through to Step 2.

## Step 2 — Direct URL fetch (fallback)

If Context7 is unavailable or the mirror is stale, fetch the canonical
URLs directly. Try in this order; stop at the first that satisfies the
question:

```text
https://code.claude.com/docs/en/memory
https://code.claude.com/docs/en/best-practices
https://code.claude.com/docs/en/skills
https://code.claude.com/docs/en/features-overview
```

The legacy domain `docs.anthropic.com/en/docs/claude-code/*` currently
301-redirects to `code.claude.com/docs/en/*`. Do not hardcode the
legacy URLs in any file — call only the new ones.

## Step 3 — `llms.txt` index (recovery)

If both Context7 and the URLs above fail (e.g., another domain rename
ships), use the documentation index as the recovery anchor:

```text
https://code.claude.com/docs/llms.txt
```

This file lists every Claude Code documentation page as direct `.md`
URLs. Find the new path for the topic you wanted, then retry Step 2
against the new URL. Update SKILL.md's URL list and open a project ADR
amendment if the change is structural.

## Step 4 — Fallback when all three fail

If Context7, the canonical URLs, and `llms.txt` are all unreachable in
a single session:

1. **Continue work** using only the inlined Invariant Core in
   `SKILL.md` and the contents of `invariants.md`.
2. **Tell the user** the volatile section was not verified this
   session, and that the inlined invariants are the only contract that
   was applied.
3. **Do not** stop or fail — the invariants are sufficient to author a
   correct-shape document; only the numeric thresholds are unverified.

## What to record

When a volatile value is cited inside `CLAUDE.md`, `README.md`, or a
project ADR after this protocol runs, include the verification date
inline:

```markdown
The recommended CLAUDE.md size limit is 200 lines (verified 2026-05-06,
source: code.claude.com/docs/en/memory).
```

Without a date, future readers cannot tell whether the citation is
current.

## Drift signals

The following signals usually mean a volatile value has changed and the
protocol should run before the next authoring session:

- A new `claude-code` minor or major release in the changelog (Claude
  Code releases sometimes adjust thresholds).
- A noticed change in Anthropic's published `llms.txt` / docs.
- A community report or upstream issue citing a different number than
  what `invariants.md` records.
