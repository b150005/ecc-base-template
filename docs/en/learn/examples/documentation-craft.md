---
domain: documentation-craft
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: technical-writer
contributing-agents: [technical-writer]
---

> **Read-only reference.** This file is shipped with the ECC Base Template as a worked
> example to illustrate what a populated knowledge file looks like after many sessions on
> a real project. It is **not** your knowledge file. Your own knowledge file lives at
> `learn/knowledge/documentation-craft.md` and starts empty until agents enrich it during
> real work. Agents never read, cite, or write under `docs/en/learn/examples/` — this tree
> is for human readers only. See [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md)
> for the design rationale.

> This file's home in the knowledge pillar is `learn/knowledge/documentation-craft.md`.

---

## How to Read This File

Level markers indicate the intended audience for each section:
- `[JUNIOR]` — first-principles explanation; assumes no prior exposure
- `[MID]` — non-obvious idiomatic application in this stack
- `[SENIOR]` — non-default trade-off evaluation; names what is given up

---

## The Four Documentation Audiences  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

Documentation fails when it tries to serve everyone at once. A single document that aims
at new contributors, on-call operators, API consumers, and future maintainers ends up
serving none of them well: it is too slow for operators who need a decision in two minutes,
too shallow for maintainers who need to understand a constraint that will outlast its
author, and too detailed for contributors who need to start a local server.

The question documentation must answer before anything else is: who is reading this, and
what do they need to do next? The answer determines voice, depth, and structure.

**New contributors** need the fewest steps that actually work — not an architecture
overview. A contributor document that explains hexagonal architecture before explaining
how to run the tests has mistaken the audience.

**Operators on call** need to diagnose and mitigate a live incident with minimal
decisions. Runbooks serve this audience. They are built around observable symptoms, not
architecture. A runbook that opens with background theory has mistaken the audience.

**API consumers** need to know what a call accepts, what it returns, and what can go
wrong — with paste-and-modify examples. They do not need to know how the database stores
the data.

**Future maintainers** need to understand why a decision was made. Code expresses the
what. An Architecture Decision Record expresses the why, including the alternatives that
were rejected and the constraints that made them worse.

### Idiomatic Variation  [MID]

Meridian maps each audience to a specific document type and location:

| Audience | Document type | Location |
|----------|---------------|----------|
| New contributors | README + `docs/en/onboarding.md` | Repo root + `docs/en/` |
| Operators on call | Runbooks | `docs/en/runbooks/` |
| API consumers | OpenAPI spec + usage examples | `docs/en/api/` |
| Future maintainers | Architecture Decision Records | `docs/en/adr/` |

The README covers only what a visitor needs to know within the first five minutes: what
the project does, how to run it locally, and where deeper documentation lives. Everything
else lives in `docs/`. A README that also covers onboarding, API reference, and
architecture rationale grows to several thousand words, becomes stale faster than it is
updated, and serves none of the four audiences well.

### Trade-offs and Constraints  [SENIOR]

Separating documentation by audience means a single feature change may require updates
to four documents: the onboarding guide, the runbook, the API reference, and an ADR. The
cost is discipline — every PR that changes observable behavior carries a documentation
checklist. The benefit is that each document stays focused and readable.

The alternative — a single wiki — requires readers to scan and filter. Meridian ran a
wiki for the first three months. The signal that it was failing: on-call engineers
opening a runbook-style page and finding two paragraphs of background before the
mitigation steps.

### Related Sections

- [See documentation-craft → ADR Discipline](#adr-discipline-when-and-how-to-write-an-adr)
  for the format that governs future-maintainer documents.
- [See operational-awareness → Three-Pillar Observability](./operational-awareness.md#three-pillar-observability-logs-metrics-and-traces)
  for what operators expect the system to expose during an incident, and the runbook
  conventions that operator documents follow.

---

## ADR Discipline: When and How to Write an ADR  [MID]

### First-Principles Explanation  [JUNIOR]

An Architecture Decision Record captures one decision: what was decided, why, and what
alternatives were considered and rejected. The record is written once and never edited —
future decisions that revisit the same topic create a new ADR that supersedes the prior
one. This immutability is the point: the ADR is a historical artifact, not a living
document.

The most important part of an ADR is the alternatives table. A decision without its
rejected alternatives is half a record — it tells you what was chosen but not why the
other paths were worse. A maintainer who reads only the decision cannot tell whether it
was obvious or a close call with important constraints.

### Idiomatic Variation  [MID]

Meridian's ADR header block:

```markdown
# ADR-007: Cursor-Based Pagination for Task Lists

**Status:** Accepted
**Date:** 2026-01-14

## Context

Task list queries return results ordered by (created_at DESC, id DESC). Two pagination
strategies were evaluated: offset-based (LIMIT n OFFSET m) and cursor-based (encoding
the last row's (created_at, id) pair).

## Decision

Use cursor-based pagination for all task list endpoints.

## Alternatives Considered

| Alternative | Why rejected |
|-------------|--------------|
| Offset pagination | Produces skipped or duplicated results when tasks are inserted between page fetches, which occurs frequently during active sprints. |
| Keyset on id only | Breaks when two tasks share a created_at timestamp, which occurs during bulk imports. |

## Consequences

Clients cannot jump to an arbitrary page number. Continuous-scroll UIs (Meridian's
primary pattern) are unaffected. Reporting views requiring row skipping will need a
separate strategy if that feature is ever built.
```

ADRs live in `docs/en/adr/` numbered sequentially. Meridian writes them at decision
time — the draft lives in the PR that implements the decision. Reviewers approve the ADR
alongside the code.

### Trade-offs and Constraints  [SENIOR]

The threshold question: "Would a future contributor ask why this was done this way?" If
yes, write an ADR. Small implementation choices — loop structure, variable naming, which
assertion library to call — do not warrant ADRs. Significant behavioral choices —
pagination strategy, database selection, why an interface lives in `domain` rather than
in the implementing package — do.

The cost of a missing ADR materializes months later: a maintainer revisits the decision
without its context, explores an alternative that was already rejected, and either
implements a worse solution or spends time rediscovering the original reasoning. The cost
of an unnecessary ADR is a longer log that reviewers must skim. Between those costs,
Meridian prefers erring toward writing ADRs for decisions that felt like real choices.

### Example (Meridian)

ADR-007 (cursor-based pagination) was written alongside the PR that added the task list
endpoint. Without it, a future engineer adding a new list endpoint would likely default
to offset pagination and reintroduce the race condition on concurrent task creation.

### Related Sections

- [See api-design → Cursor-Based Pagination on Task Lists](./api-design.md#cursor-based-pagination-on-task-lists)
  for the implementation ADR-007 governs.
- [See review-taste → Abstraction With One Caller](./review-taste.md#abstraction-with-one-caller)
  for how reviewers identify decisions that cross the ADR-warranted threshold.

---

## Comment Policy in Code: Why, Not What  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

Code communicates what it does to any reader who can read the language. A comment that
restates the code in English adds no information and doubles the maintenance surface.
When the code changes, the comment must also change — or it silently becomes wrong. A
wrong comment is worse than no comment: it actively misleads.

Meridian's rule: **comments explain why, not what**. The code already says what. A
comment earns its place by explaining the reasoning invisible in the code: a constraint
from an external system, a performance consideration, a safety invariant that future
changes must not break.

The one exception: godoc comments on exported Go identifiers. A caller outside the
package may not read the body. For exported functions, the godoc comment is part of the
API contract — it explains what the function does and what errors it may return.

### Idiomatic Variation  [MID]

Meridian's Go code has three categories of acceptable comment:

**Godoc on exported identifiers** (what-comment, required):

```go
// CheckAndRecord checks whether the given idempotency key has been seen before.
// It records the key on first encounter with the given TTL.
// Returns (true, nil) if already present; (false, nil) on first record;
// (false, err) if the Redis operation failed.
func (s *IdempotencyService) CheckAndRecord(ctx context.Context, key string, ttl time.Duration) (bool, error) {
```

**Inline why-comment** explaining an externally constrained behavior:

```go
// Fetch limit+1 rows to determine hasMore without a separate COUNT query.
// COUNT(*) on large tables causes a sequential scan; the extra-row technique avoids it.
rows, err := r.db.QueryContext(ctx, q, args...)
```

**Safety invariant comment** warning future editors of a constraint that a single
function cannot enforce alone:

```go
// SET NX is atomic: no window between the existence check and the write.
// Do NOT replace this with GET followed by SET — that introduces a race condition.
set, err := s.redis.SetNX(ctx, "idempotency:"+key, "1", ttl).Result()
```

What Meridian does not permit: comments describing deleted code. If code is removed, it
is removed. The commit message is the record. A comment reading `// removed feature X —
no longer needed` becomes stale as soon as anyone reads it without the removal context.

### Trade-offs and Constraints  [SENIOR]

The "why not what" policy requires engineers to resist using comments as a crutch for
unclear code. The correct response to code that requires a "what" comment is to clarify
the code itself — a better name, a smaller function, a descriptive helper. The comment
should not substitute for clarity.

When a comment passes the why-test, it functions as a signal: comments are sparse enough
in Meridian's codebase that a developer learns to pay attention to them. A comment means
"this is not obvious and there is a reason." A codebase where every line has a comment
trains developers to skip them.

### Related Sections

- [See documentation-craft → The Four Documentation Audiences](#the-four-documentation-audiences)
  for why godoc comments serve the API consumer audience specifically.
- [See review-taste → The Severity Ladder](./review-taste.md#the-severity-ladder) for how code
  reviewers evaluate comment quality alongside coverage.

---

## Bilingual Documentation Maintenance  [MID]

### First-Principles Explanation  [JUNIOR]

When a project maintains documentation in two languages, one must be the source of truth.
Without that designation, both versions drift: each receives some updates and misses
others, and readers encounter outdated information without knowing it. The longer drift
continues uncorrected, the more expensive reconciliation becomes.

The source-of-truth convention answers one question: when the English version and the
Japanese version disagree, which is correct? If the answer is always English, then
English must be updated first and Japanese must follow. If the Japanese version is ever
more current, the convention has broken down.

This project and Meridian follow the same convention: English is the source of truth.
Every documentation change begins with the English file. The Japanese file is a
maintained translation, not an independently authored document.

### Idiomatic Variation  [MID]

Meridian's bilingual tree is parallel:

```
docs/
  en/
    onboarding.md       # source of truth
    runbooks/slack-webhook-latency.md
  ja/
    onboarding.md       # maintained translation
    runbooks/slack-webhook-latency.md
```

Every Japanese file begins with a header identifying the source:

```markdown
> このドキュメントは `docs/en/onboarding.md` の日本語訳です。英語版が原文（Source of Truth）です。
```

PR review enforces the pairing: any PR that modifies a file under `docs/en/` includes a
checklist item verifying that the corresponding file under `docs/ja/` was updated in the
same PR. If the Japanese update is absent, the reviewer requests it before approving.

### Trade-offs and Constraints  [SENIOR]

The pairing check prevents PR-level drift but cannot catch gaps introduced before the
policy existed. When Meridian introduced the bilingual policy at v0.3, several English
documents had been updated since their initial Japanese translations. Those gaps were
addressed in a dedicated cleanup PR.

The deeper trade-off: every documentation change now requires two files. For engineers
without Japanese proficiency, the Japanese update requires machine translation followed
by review, or a separate pass by a fluent team member. This adds friction to small
documentation changes. Meridian accepts this cost because the Japanese-language audience
is a significant fraction of the customer base and reducing documentation barriers is a
product priority.

### Example (Meridian): The v0.4 Drift Incident

A PR during the v0.4 release cycle updated `docs/en/onboarding.md` to reflect a new
required environment variable. The PR was merged without updating `docs/ja/onboarding.md`.
The pairing checklist existed in the PR template but had not yet been incorporated into
the regular review flow — reviewers were not yet in the habit of checking it.

The gap was caught two weeks later when a Japanese-language new contributor followed the
Japanese onboarding guide, encountered an error from the missing variable, and filed an
issue. The Japanese file was updated within 24 hours. The PR template was revised to
place the bilingual checklist above the "Tests pass" item, where it had previously been
buried below.

The incident established a team norm: the bilingual checklist is now the second item
reviewers verify after CI status, not the last.

### Related Sections

- [See documentation-craft → The Four Documentation Audiences](#the-four-documentation-audiences)
  for the audience model that drives the bilingual commitment.
- [See release-and-deployment → CI/CD Pipeline Shape](./release-and-deployment.md#ci-cd-pipeline-shape)
  for how release notes are also maintained bilingually.

---

## Prior Understanding: README as the Documentation System  [SENIOR]

### Prior Understanding (revised 2026-01-28)

Meridian's original approach (present from the initial commit in 2025-08) was a single
README at the repository root containing everything: project overview, local setup,
environment variable reference, architecture overview, API endpoint list, and a deployment
guide. The README reached approximately 1,800 words.

This was revised because:

1. **Different update frequencies broke the README.** Environment variables changed with
   every deployment update. The API endpoint list changed with every feature PR.
   Architecture changed rarely. Mixing these frequencies in one file meant the README was
   always partially stale, and readers could not tell which sections to trust.

2. **Navigation degraded.** A 1,800-word README has no meaningful structure. Both
   on-call engineers and new contributors scanned the entire document to find the section
   relevant to their task.

3. **The README accumulated content that did not belong there.** Once the pattern of "put
   it in the README" was established, every team member added a section. It accumulated a
   feature comparison table, a FAQ, a list of known issues, and a "Tips" section with
   three items from three engineers sharing no coherent theme.

**Corrected understanding:**

The README communicates five things to a repository visitor: what the project does, how
to run it in under ten minutes, where detailed documentation lives, how to contribute,
and what license applies. Everything else belongs in `docs/`. The boundary is enforced by
the PR template: any PR that adds more than 20 lines to the README triggers a flag asking
whether the content belongs in `docs/` instead.

The corrected structure produced a README of 94 lines. Displaced content moved to:

- Local setup details → `docs/en/onboarding.md`
- Environment variable reference → `docs/en/configuration.md`
- API endpoint list → `docs/en/api/` (OpenAPI specs)
- Deployment guide → `docs/en/runbooks/` and the devops-engineer's scope

The principle: README length is a proxy for documentation discipline. A long README
signals the project has not yet decided where documentation belongs and has defaulted
to the most visible surface.

### Related Sections

- [See documentation-craft → The Four Documentation Audiences](#the-four-documentation-audiences)
  for the audience model that determined where each displaced section landed.

---

## Coach Illustration (default vs. hints)

> **Illustrative only.** Not part of the live agent contract. Governed by
> `.claude/skills/learn/coach-styles/`.

**Scenario:** A learner has just merged a PR that adds a Redis keyspace monitoring
command to the Meridian backend. They ask the agent to document it.

**`default` style** — The agent identifies the relevant audiences (operators need the
command in a runbook; if the function is exported, API consumers need godoc). It
determines the command is internal operational tooling, produces an update to the
relevant runbook section under Triage, and adds a godoc comment to the exported function.
It checks whether the monitoring strategy warrants an ADR — it does not, because the
strategy follows an already-recorded pattern. It appends `## Learning:` trailers
explaining the audience-to-document mapping and the comment-policy distinction between
godoc (what) and inline why-comments.

**`hints` style** — The agent names the two relevant surfaces (runbook for operators,
godoc for the exported function), identifies the comment type (inline why-comment for the
keyspace naming convention), and emits:

```
## Coach: hint
Step: Add the monitoring command to docs/en/runbooks/redis-keyspace.md under Triage,
and a godoc comment to the exported function explaining what it returns.
Pattern: Audience-specific documentation — runbook for operators, godoc for API consumers.
Rationale: The command is operational; it belongs in the runbook where on-call engineers
will find it, not in the README or a general tutorial.
```

`<!-- coach:hints stop -->`
