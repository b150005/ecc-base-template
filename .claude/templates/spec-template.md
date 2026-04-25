# Feature Spec Template

## How to use this template

1. Decide where your specs live. The template does not force a location — common choices:
   - Single-language project: `specs/task-management.md` at repo root
   - Bilingual project: `specs/en/task-management.md` and `specs/ja/task-management.md`
   - Under docs: `docs/specs/task-management.md`
2. Copy this file into that directory and rename it to `kebab-case-feature-name.md`.
3. Fill in the sections below. Delete the "How to use this template" block before committing.
4. Keep it short. A spec is a decision record, not a design document — aim for 1–3 pages for most features.

A Japanese version of this template is at `.claude/templates/spec-template.ja.md`.

---

# [Feature name]

## Status

[Draft | Approved | Shipping | Shipped | Deprecated]

**Owner:** [name or role]
**Target release:** [version or date, if known]

## Problem

What user-facing problem are we solving? Who has it? How often? What do they do today as a workaround? One short paragraph — do not jump to solutions.

## Goals

- Specific, testable outcomes this feature must achieve
- Prefer 3–5 goals; if the list grows past 7, split the feature

## Non-goals

- What this feature will deliberately not do, so reviewers do not argue about scope creep
- Named non-goals turn "we forgot" into "we chose not to"

## User stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| [persona] | [action] | [outcome] |

## Acceptance criteria

Concrete, testable conditions that must hold before this ships. Prefer Given / When / Then:

- **Given** [state] **when** [action] **then** [observable result]
- ...

## Key interactions

High-level description of the primary flows — not a full wireframe. Link to designs if they exist.

## Metrics

- **Leading:** what tells us this is working before we can measure the real outcome
- **Lagging:** the outcome we actually care about (retention, revenue, completion rate, etc.)

## Risks and open questions

- Known unknowns — what could invalidate this spec?
- Decisions we are deliberately deferring to implementation

## Out of scope

- Related things we explicitly are not tackling in this iteration

## References

- Links to user research, prior specs, related ADRs, competitive analysis
