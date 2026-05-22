# Implementation domain — protocol

> Loaded on demand from the verification-layer SKILL.md.
> Shared invariants live in `../SKILL.md`. This file states the
> implementation-domain specifics: the four-level ranking of
> "different approach", the environment-safety contract, the user-
> library precedence rule, and the output format.

This domain corresponds to ADR-010 §`implementation:`.

## When to invoke

- The Generator (`implementer`) has produced a code change that
  satisfies acceptance criteria, and the change carries non-trivial
  judgement: a custom algorithm, a non-obvious data structure, an
  unusual control flow, or a performance-sensitive choice.
- An existing implementation is being refactored and the new shape
  is materially different from the old one — a behavioural delta
  check is the cheapest way to confirm equivalence.

Do **not** invoke for:

- Mechanical refactors (renames, import re-orderings, formatting).
- One-line bug fixes whose correctness is obvious from the diff.
- Pure prototypes / spikes that will be thrown away.
- Code paths fully covered by deterministic property-based tests
  whose oracle the Generator did not also write.

## Configuration

`.claude/verification.yml` → `implementation:` section:

```yaml
implementation:
  enabled: false              # default-off
  max_iterations: 1           # the implementation domain rarely benefits
                              # from more than one round; the cost of
                              # reimplementing twice is high
```

When `enabled: false`, the Critic is never spawned. Derived projects
that do not opt in pay nothing.

## What the Critic does — and does not do

The Critic is **not** a diff reviewer (that is `code-reviewer`'s
job). The Critic re-implements the **same acceptance criteria** with
a different approach, runs the test suite against both
implementations, and reports the **behavioural delta**:

- Which test outputs differ?
- Which edge cases does each implementation handle?
- What performance profile does each show?

The output is a `verification-review.md` artifact. The PR author
decides what to do with the delta.

## Four-level ranking of "different approach"

The Critic must prefer the **lowest level** that yields a meaningful
behavioural delta. Climbing up the ranking is allowed only when the
lower levels would produce no difference worth reporting.

### Level 1 — different control flow or data structure (default)

Same language, same dependency set, different algorithm or shape.
Always allowed. Examples: recursive vs. iterative, hashmap vs.
sorted-array, eager vs. streaming.

### Level 2 — different idiom within the same library

Same API surface, alternative invocation pattern. Examples: pipeline
vs. chained calls; query builder vs. raw SQL within the same ORM.
Allowed.

### Level 3 — different library

Allowed only when **both** of the following hold:

1. The user has **not** pinned a specific library in the task, the
   spec, or an existing ADR.
2. The alternative library is already declared in the project's
   manifest (`package.json`, `pubspec.yaml`, `go.mod`, `Cargo.toml`,
   `pyproject.toml`, etc.) **or** is a standard-library equivalent
   (e.g. `net/http` instead of an HTTP client library).

If either condition fails, level 3 is off the table for this task.
The Critic operates at level 1 or 2 and **must say so explicitly**
in the review header — silence about why a higher level was not
used is treated as a process error.

### Level 4 — a library or runtime not currently in the project

**Disallowed** without explicit human approval. The Critic must
instead emit a **verification-blocked note** describing what
alternative it would have used and what would be needed (CLI tool,
Docker image, SDK, license commitment). The PR author can then:

1. Approve the addition (and re-run with `enabled: true`).
2. Accept the verification gap (and ship the original
   implementation).
3. Supply the environment manually and re-run.

The blocked-note format is:

```markdown
## Verification blocked (level 4)

- Reason: alternative library/runtime requires environment changes.
- Candidate alternative: <name>
- Why it would be a useful comparison: <one sentence>
- Required to enable: <list — CLI, Docker, SDK, license, etc.>
- Fallback used: level <1|2|3 — what was actually compared, if anything>
```

## User-library precedence (permanent)

When the user has explicitly named a library in the task, spec, or
an existing ADR — `"use Drizzle, not Prisma"`, `"keep using axios"`,
or an ADR that selected a stack — levels 3 and 4 are **permanently
off the table** for that task. The Critic operates at levels 1–2
and notes the constraint in the review header:

```markdown
> User pinned <library X>; alternatives 3-4 disabled for this task.
> Comparison performed at levels 1-2.
```

This is non-negotiable. A behaviour that ignores an explicit user
choice is a worse failure than no verification at all.

## Environment-safety contract

The Critic must **not**, as part of verification:

- Install system-level tooling (apt, brew, gem, pip system-wide).
- Pull Docker images or start containers.
- Fetch standalone binaries.
- Modify the project's dependency manifest.
- Make network calls outside of the project's already-allowed
  registries.

If a candidate alternative needs any of these, the Critic emits
the level-4 blocked-note instead. This keeps verification
reproducible on a learner's laptop without surprising side effects.

## Protocol

```
[1] Generator (implementer)
    - Produces diff that satisfies acceptance criteria.
    - Runs the test suite; records pass/fail and timing.
    - Optionally annotates which acceptance criteria each test maps to.

[2] Critic (adversarial-implementer)
    - Reads spec / acceptance criteria, NOT the Generator's diff.
      (Reading the diff first is forbidden — it primes the Critic
      toward the same shape. The Critic may consult the diff only
      after producing its own draft, to identify behavioural
      differences.)
    - Picks the lowest level (1-4) that yields a meaningful delta,
      respecting user-library precedence and environment safety.
    - Writes a parallel implementation in a scratch worktree or
      branch; does NOT modify the Generator's code path.
    - Runs the same test suite against the parallel implementation.
    - Diffs observable behaviour: test outputs, error paths,
      performance metrics if relevant.
    - Cites primary sources for any external behavioural claim
      (framework docs, RFC, language spec).

[3] Verdict
    - Implementations agree on all observable behaviour: PASS, with
      a one-line "agrees on all paths" note. (Silence is forbidden.)
    - Implementations differ: REQUEST CHANGES. The delta becomes a
      structured table; the PR author reviews and decides.

[4] No iteration by default.
    Implementation re-rounds rarely yield more signal than the first
    pair. If the delta surfaced a real divergence, the right next
    step is for the PR author to choose, not for the Generator to
    write a third implementation. max_iterations may be raised by
    config when the user wants the loop.
```

## Output format

Critic writes into
[`.claude/templates/verification-review-template.md`](../../../templates/verification-review-template.md).
The implementation domain uses these template fields:

- `Domain: implementation`
- `Level used: 1 | 2 | 3 | 4-blocked`
- `User-library constraint: <none | name>`
- `Behavioural delta table` (test name, Generator output, Critic
  output, severity)
- `Performance delta` (only if relevant)
- `Primary sources cited` (for external behavioural claims)

## See also

- [checklist.md](./checklist.md) — Critic checklist for behavioural
  delta and citation discipline
- [failure-modes.md](./failure-modes.md) — typical implementation-
  domain error patterns
- [`.claude/agents/adversarial-implementer.md`](../../../agents/adversarial-implementer.md)
  — Critic agent
