# ADR Template

## How to use this template

1. Decide where your ADRs live. The template does not force a location — common choices:
   - Single-language project: `adr/001-use-postgresql.md` at repo root
   - Bilingual project: `adr/en/001-use-postgresql.md` and `adr/ja/001-use-postgresql.md`
   - Under docs: `docs/adr/001-use-postgresql.md`
2. Copy this file into that directory and rename it to `NNN-kebab-case-title.md`.
3. Start numbering from `001`. The template does not reserve any numbers.
4. Fill in the sections below. Delete the "How to use this template" block before committing.
5. If a decision later becomes obsolete, mark the old ADR `Superseded by ADR-NNN` and write a new ADR — never rewrite history.

A Japanese version of this template is at `.claude/templates/adr-template.ja.md`.

---

# ADR-NNN: [Decision Title]

## Status

[Proposed | Accepted | Deprecated | Superseded by ADR-NNN]

## Context

What is the issue or question that motivates this decision? What forces are at play? State the concrete constraints (deadline, team skills, existing systems, regulatory requirements) that make this decision non-trivial.

## Decision

What is the decision? State it clearly, in one or two sentences, so a reader who only reads this section knows what was chosen.

## Consequences

### Positive

- What are the benefits of this decision?

### Negative

- What are the drawbacks or trade-offs? Which future options are now harder to reach?

### Neutral

- What else changes as a result of this decision? (Migration required, team ergonomics shift, documentation debt, etc.)

## Alternatives considered

| Alternative | Pros | Cons | Why not chosen |
|-------------|------|------|----------------|
| Alternative A | ... | ... | ... |
| Alternative B | ... | ... | ... |

## References

- Links to prior art, benchmarks, vendor docs, or related ADRs.
