# Roadmap Section Template

## How to use this template

1. Paste the section below the `---` separator into your `.claude/CLAUDE.md`, immediately before `## Development Workflow`.
2. Replace the two placeholder rows with your first real milestones as you begin planning.
3. Delete this "How to use this template" block before committing.
4. Row numbers are stable and never reused — start at `01` and increment. A split milestone becomes a new row plus a note on the old one.

Japanese version: [`roadmap-section.ja.md`](./roadmap-section.ja.md) (maintained by `technical-writer`, per ADR-005).

---

## Roadmap

Single entry point mapping each milestone to its authoritative design source. Each row is one milestone; the linked Spec/ADR is the source of truth for content — this table is an index only, never duplicating acceptance criteria or rationale. See `.claude/meta/adr/014-roadmap-index-single-entry-point.md` for the rationale.

| # | Milestone | Status | Design source |
|---|-----------|--------|---------------|
| 01 | [replace with one-line milestone description] | ☐ todo | spec: `specs/01-example.md` |
| 02 | [replace with one-line milestone description] | ☑ done | spec: `specs/02-example.md` + adr: `adr/002-example.md` |

> **These rows are placeholders.** Replace them with real milestones as you plan. Row numbers are stable and never reused.

**Rules:**
- One row per milestone; row number stable, never reused (follows ADR-number convention). A split = new row + note on old row.
- `Design source` names the type explicitly: `spec:` and/or `adr:` links.
- Milestone ↔ Spec is 1:1 mandatory; Milestone → ADR is 0:1 or 1:N (only when a structural decision occurred; the ADR's `## References` back-links the row number).
- Status = implementation state: ☐ todo / ◐ in-progress / ☑ done / ✗ dropped. Dropped rows stay (history not rewritten).
- Index only — never duplicate acceptance criteria or rationale; the linked Spec/ADR is the source of truth.
- Write-ownership: `product-manager` creates/updates the row + `spec:` link; `architect` adds the `adr:` link; `orchestrator` only reads.
- At 100+ milestones, split into `### Phase N` sub-tables under `## Roadmap`.
