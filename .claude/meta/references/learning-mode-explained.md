# Developer Learning Mode — Explainer

> **Audience.** Learners and team leads who want to understand how Learning Mode works before turning it on, or who already have it on and want to understand why a particular agent response emitted a particular trailer. This is the long-form companion to the short mention in [README.md](../../README.md).
>
> **Source of truth.** The authoritative design is [ADR-001](adr/001-developer-growth-mode.md) (partially superseded by [ADR-003](adr/003-learning-mode-relocate-and-rename.md)), the functional specification is the [PRD](prd/developer-learning-mode.md), and the domain list is the [domain taxonomy](learn/domain-taxonomy.md). This explainer paraphrases those documents for a learner audience; it does not add new policy.

---

> **v2.0.0/v2.1.0 migration note.** This feature was renamed from "Developer Growth Mode" to "Developer Learning Mode" and the knowledge directory was relocated in v2.0.0 (see [ADR-003](adr/003-learning-mode-relocate-and-rename.md)). If you enabled the feature in v1.x and accumulated content under `.claude/growth/notes/`, follow the migration guide at `.claude/meta/references/migration/v1-to-v2.md` to move your knowledge files to the new location at `.claude/learn/knowledge/`. v2.1.0 adds the coaching pillar — five active-coaching styles plus `default` — as an orthogonal second axis alongside the knowledge pillar. Existing v2.0.0 installs upgrade transparently: a config file with no `coach` key resolves to `coach.style = "default"` and behavior is byte-identical to v2.0.0.

---

## What Learning Mode is

Developer Learning Mode is the template's opt-in learning layer that sits on top of the 15-agent team. When it is off — which is the default — the agents produce exactly the same output they would without the feature present. Not approximately the same. Byte-identical in substantive content. When it is on, each agent that completes a task appends two trailer sections to its response, calibrated to a declared experience level.

The two sections are `## Learning: taught this session` and `## Learning: knowledge diff`. The first captures what was taught in this response — the decision rationale, the trade-off, the alternative considered and why it was not chosen, and where in the project's own ADRs or canonical external documentation the reasoning is grounded. The second records the maintenance operation performed on the knowledge base: which domain file under `.claude/learn/knowledge/` was touched, which section within that file, and what kind of operation was applied — add, deepen, refine, correct, or new-domain. They cite, they do not lecture.

Note depth follows the concept being explained, not an artificial budget. A junior-level explanation of a foundational pattern is several paragraphs because it needs to build scaffolding from first principles. A senior-level trade-off note may be a single paragraph because that is what the decision demands. There are no length caps — no token budgets, no note counts, no sentence limits. The artifact — the code, the architecture document, the test file, the security report — is always first. The Learning trailers always follow.

To see what a fully populated knowledge file looks like after many sessions on a real project, refer to the worked examples at `.claude/meta/references/examples/<domain>.md`. These are read-only references grounded in a shared fictional project (Meridian); agents never read or write to them. They exist so you can calibrate expectations before your own `.claude/learn/knowledge/` directory accumulates real content. See [ADR-003 §5](adr/003-learning-mode-relocate-and-rename.md) for the design rationale.

---

## What changes when Learning Mode is ON

When Learning Mode is active, each agent in the team reads `.claude/learn/config.json` before completing its response. If `enabled` is `true`, the agent appends the two trailer sections after its primary output. The generated artifact is not touched. No inline educational comments are added to production code. No files are written to `docs/` or anywhere outside `.claude/learn/knowledge/`. The trailer sections appear in the chat response, and each agent also updates the corresponding domain file under `.claude/learn/knowledge/<domain>.md` using a non-destructive enrichment operation defined in `.claude/skills/learn/preamble.md`. The knowledge base is not a chronological log; it is organized by domain, and each session enriches existing sections or opens new ones as understanding accumulates across real project decisions.

What changes in practice: the developer learns the name of the pattern being applied, the reason this project chose it over the common alternative, and the ADR or external reference that records that decision. Over many sessions this adds up to something more than isolated tips. It adds up to a mental model of how the project's decisions fit together.

---

## The three levels

**junior** — Full Learning Notes on every response where a reasonable alternative exists. The note names the pattern, explains why it was chosen over the obvious alternative, and tells the reader what to look for in related code. The note assumes the reader has not encountered this pattern before. Up to three notes per response.

**mid** — Learning Notes only on non-obvious decisions: framework-specific idioms, cross-cutting concerns, trade-offs that are not visible in the code itself. Notes are omitted on well-established conventions the segment is expected to know. Up to three notes.

**senior** — Trade-off notes only, and only when the agent made a non-default choice. The note names the default and explains why it was rejected. No explanatory prose. Often zero notes per response. The use case here is a quick second opinion or a note to hand to a colleague in a review.

The level is a filter over which observations qualify as notes at all — it is not a knob for verbosity. A `senior`-level response that involved no non-default choices emits zero notes. That is correct behavior.

---

## The knowledge directory

The knowledge directory at `.claude/learn/knowledge/` is a living reference organized by domain, not a chronological log. Agents enrich, deepen, and refine the same domain files over time as relevant decisions accumulate across sessions. A session does not append a dated entry; it opens the file for the relevant domain and either adds a new section, deepens an existing section, or refines an older entry as understanding matures.

No domain files are pre-seeded. `ls .claude/learn/knowledge/` returns nothing on a fresh clone. Files appear only when a real teaching moment earns them. After many sessions on a real project, a subset of the 19 canonical domains will have grown substantially. A developer's directory might look like this:

```
.claude/learn/knowledge/
├── architecture.md             # layered architecture, event sourcing, ACL placement, ADR references
├── business-modeling.md        # pricing model trade-offs, unit economics, monetization patterns
├── persistence-strategy.md     # repository pattern, option vs null, ADR-007, query boundaries
├── error-handling.md           # Result<T,E>, railway-oriented programming, boundary contracts
├── security-mindset.md         # OWASP notes, auth patterns, input validation conventions
├── testing-discipline.md       # AAA pattern, fixture isolation, coverage targets, TDD cycle
└── performance-intuition.md    # profiling methodology, database query cost, caching trade-offs
```

Each file is organized by concept, not by session date. A note about the repository pattern that was introduced in session one and reinforced in session twelve lives in `persistence-strategy.md` in one coherent section — not scattered across two entries in a chronological log. When the architect makes a decision that refines the earlier understanding, the agent updates or deepens the entry rather than appending a separate paragraph below the original.

This is the key differentiator from every other tool that claims to explain AI decisions. An AI that explains each decision at the point of generation is useful. A set of files that capture the cumulative understanding derived from dozens of real decisions — organized by domain, refined over time, grounded in the project's own ADRs — is a personal textbook built by shipping real features.

---

## Knowledge is organized by domain, not by session

A chronological log records what happened. A domain-organized knowledge directory records what is known. Learning Mode does not maintain a chronological journal at all — the per-response "knowledge diff" in the chat output is the session-level provenance record, and git history is the long-term audit trail. The knowledge directory is the structured knowledge layer. When an agent adds a note about the repository pattern in session three, and another agent references the repository pattern in session seventeen, the note in `persistence-strategy.md` is the canonical place where that knowledge lives — deepened by session seventeen, not duplicated alongside it.

This mirrors how expertise actually works. A developer who has worked on a codebase for two years does not remember every session. They have a mental model built from many encounters with the same patterns. The knowledge directory externalizes that model.

---

## Knowledge is private by default

`.claude/learn/knowledge/` is gitignored by default, and so is `.claude/learn/config.json`. The reason is deliberate: knowledge files contain the learner's mistakes, prior misunderstandings, and the revision history of their mental model. That is private learning material, not documentation intended for a team's shared repository. Teams who want a shared textbook — where accumulated domain knowledge is checked in and visible to all contributors — can opt in by inverting the gitignore pattern. A `.gitignore.example` file in the repository shows the exact pattern to add.

---

## The coaching pillar

### Two pillars, one feature

Learning Mode v2.0.0 shipped with one pillar: **knowledge accumulation**. Every time a teaching moment arises, the agent records it in a domain file under `.claude/learn/knowledge/`. The record is post-hoc — the agent finishes its work and then writes down what it taught. Your accumulated knowledge grows across sessions without changing how the agents work in the moment.

v2.1.0 adds a second pillar: **coaching**. Coaching is a different axis entirely. Where the knowledge pillar changes what gets recorded, the coaching pillar changes how the agent works during the session. The two pillars are orthogonal — you can have the knowledge pillar on with no coaching, coaching on with no knowledge accumulation, both on together, or neither. Mixing and matching is first-class behavior.

### The six coaching styles

The coaching pillar defines six mutually exclusive styles. Exactly one is active at any time. Switching takes effect on the next agent turn, with no session restart required.

| Style | One-line description | When to reach for it |
|---|---|---|
| `default` | Agent works normally. No withholding, no extra teaching. Equivalent to coach-off. | You do not need active coaching for this session. |
| `hints` | Agent names the next concrete step and the relevant pattern, then stops before writing the target function body. Emits a `## Coach: hint` block. May write scaffolding (imports, signatures, test stubs). | You want to write the load-bearing code yourself. |
| `socratic` | Agent replies to a how/why question with exactly one focused question that, if answered, picks the design. Does not write code in the same turn. Resumes normal behavior after you answer. | You want help choosing a design, not a finished design handed to you. |
| `pair` | Agent writes complete scaffolding with `// TODO(human): <one-line instruction>` markers at the decision points. Tests are written in full so you have a target to hit. Markers cap at roughly 30% of the changed lines. | You want structure but want to own the algorithm. |
| `review-only` | Agent refuses to write production code. Reads code, runs tests, and produces a structured review of code you submit. May write tests if explicitly asked. | You are driving; you want the agent as a reviewer, not an author. |
| `silent` | Agent works normally and suppresses every `## Learning:` and `## Coach:` trailing section for the lifetime of this style. The inverse of teaching-mode. | You are in flow and do not want pedagogy noise in the response. |

### Concrete example: `default` vs. `hints`

Task: "Add a login endpoint."

**`default` style (or no coaching):**

The implementer writes the complete login handler — route registration, credential validation, token generation, error responses, and tests. You receive a working endpoint and, if the knowledge pillar is on, a learning trailer explaining the pattern. Nothing is withheld.

**`hints` style:**

The implementer identifies the next concrete step — "validate credentials against the user store, returning a typed error for not-found vs. wrong-password" — names the relevant pattern ("boundary error taxonomy"), and writes the scaffolding:

```typescript
// auth/handler.ts
export async function loginHandler(req: LoginRequest): Promise<LoginResult> {
  // TODO(human): call userStore.verifyCredentials(req.email, req.password)
  // and translate UserStore errors into LoginError variants
}
```

```typescript
// auth/handler.test.ts
it('returns Unauthorized for wrong password', async () => {
  const result = await loginHandler({ email: 'a@b.com', password: 'wrong' });
  expect(result).toEqual({ ok: false, error: 'Unauthorized' });
});
```

Then a hint block:

```
## Coach: hint

**Next step**: Implement the credential-validation call and map store errors to login errors.
**Pattern**: Boundary error taxonomy — translate storage-layer errors to caller-facing error variants at the module boundary, so storage details do not leak into the API layer.
**Rationale**: Callers of loginHandler should not have to understand UserStore's internal error shapes; they get a stable contract.
```

The body of `loginHandler` is intentionally blank. You write it. The tests already define what you are aiming for.

### How to switch styles

Use the `/learn coach` subcommand group:

| Command | Effect |
|---|---|
| `/learn coach hints` | Switch to `hints` style for this session. |
| `/learn coach socratic` | Switch to `socratic` style. |
| `/learn coach pair` | Switch to `pair` style. |
| `/learn coach review-only` | Switch to `review-only` style. |
| `/learn coach silent` | Suppress all trailers without disabling knowledge writes. |
| `/learn coach off` | Return to `default` (equivalent to `/learn coach default`). |
| `/learn coach list` | List all discovered style files with one-line descriptions. |
| `/learn coach show hints` | Print the full behavior rule for a single style. |

Only you can change the style. The `disable-model-invocation: true` flag on the `/learn` Skill extends to every `coach` subcommand — agents cannot switch their own coaching style on your behalf.

### The `silent` style in detail

`silent` is not the same as `/quiet`. `/quiet` suppresses trailers for a single agent invocation, then the next invocation resumes normal behavior. `silent` is a persistent-until-changed style: it suppresses all `## Learning:` and `## Coach:` trailing sections for the lifetime of the style.

Crucially, `silent` does not stop the knowledge pillar from writing. If the knowledge pillar is on and a teaching moment arises, the agent still enriches `.claude/learn/knowledge/<domain>.md` — it just does not show the diff trailer in the chat. `/learn status` always reports the last knowledge diffs, so silent writes are never invisible if you go looking.

Use `silent` when you are deep in a flow state and the trailers are noise. Use `/quiet` for a one-off suppression when you just need the agent to be brief once.

### How coaching composes with knowledge

The two pillars are fully orthogonal:

| Knowledge pillar | Coaching pillar | Behavior |
|---|---|---|
| off | off (`default`) | Default state. Byte-identical to no Learning Mode at all. |
| on | off (`default`) | v2.0.0 behavior: post-hoc knowledge accumulation, no in-session coaching. |
| off | on (any style) | Active coaching during the session, no knowledge accumulation. |
| on | on (any style) | Both layers stack. Coaching shapes the work; knowledge records the teaching moments. |

One interaction worth noting: in `socratic` style, the agent's clarifying question can itself surface a load-bearing concept. If it does, and the knowledge pillar is on, the agent writes to `.claude/learn/knowledge/` in the same response where the question is asked.

Level (`junior`, `mid`, `senior`) and coach style are also independent. `level: junior` does not auto-couple to `hints` or any other style. Level controls the angle of explanation in knowledge trailers; coach style controls the shape of the agent's work. Set them independently to match what you actually need.

### Config settings

The `coach` subtree in `.claude/learn/config.json` carries three fields:

```json
{
  "coach": {
    "style": "default",
    "trailers": "auto",
    "scope": "session"
  }
}
```

- **`coach.style`** — the active style. A missing or unparseable value resolves to `"default"`.
- **`coach.trailers`** — `auto | always | never`. Under `auto`, `silent` style suppresses trailers; every other style emits them when the knowledge pillar is on. Set `never` to suppress trailers globally regardless of style.
- **`coach.scope`** — `session | persistent`. Under `session` (the default), the style resets to `"default"` at the start of each new session. Under `persistent`, your chosen style survives across sessions.

A v2.0.0 config with no `coach` key resolves to `coach.style = "default"`. Nothing changes for existing installs.

---

## Side-by-side example

The following example uses a small pagination utility. It is ecosystem-neutral TypeScript. The task is: implement a `paginate` function that takes a total item count, a page size, and a current page number, and returns metadata for the current page.

**Learning Mode OFF — implementer response:**

```typescript
export interface PageMeta {
  currentPage: number;
  pageSize: number;
  totalItems: number;
  totalPages: number;
  hasPrevious: boolean;
  hasNext: boolean;
}

export function paginate(
  totalItems: number,
  pageSize: number,
  currentPage: number
): PageMeta {
  if (pageSize <= 0) throw new RangeError("pageSize must be positive");
  if (currentPage < 1) throw new RangeError("currentPage must be >= 1");

  const totalPages = Math.ceil(totalItems / pageSize);
  const clampedPage = Math.min(currentPage, Math.max(totalPages, 1));

  return {
    currentPage: clampedPage,
    pageSize,
    totalItems,
    totalPages,
    hasPrevious: clampedPage > 1,
    hasNext: clampedPage < totalPages,
  };
}
```

The implementer delivers the function, the interface, and boundary-condition handling. That is the complete response.

**Learning Mode ON, level junior — implementer response:**

The same function is delivered first, byte-identical. After the code block:

```
## Learning: taught this session

- Value Object pattern: the `PageMeta` return type is a plain data object, not a class, because this
  function crosses a module boundary. Callers should be able to serialize, log, or destructure the
  result without depending on a class hierarchy. This is the Value Object pattern from Domain-Driven
  Design; Martin Fowler's *Patterns of Enterprise Application Architecture* has the canonical description.

- Clamp-over-throw trade-off: `currentPage` is clamped to `[1, totalPages]` rather than throwing
  on out-of-range input. Pagination callers frequently supply stale page numbers from user state
  (browser history, cached query params), so silent correction is safer at a UI boundary than an
  uncaught exception. If strict validation is preferred for a different call site, the project's
  boundary-contract convention will live in an ADR (ADR-005 is the placeholder slot).

- Empty-collection handling: `Math.ceil(totalItems / pageSize)` handles the zero-items case
  correctly (yields 0) without a special branch, which is why it is preferred over integer
  division plus a remainder check. The empty-collection case is covered explicitly in
  `paginate.test.ts`.

## Learning: knowledge diff

- knowledge/architecture.md → add on `## Value Object`: introduced the Value Object section with
  a definition, when-to-use / when-not-to-use guidance, a pointer to `lib/pagination.ts` as
  the canonical in-project example, and a reference to Martin Fowler's catalog entry.
```

**What gets written to `.claude/learn/knowledge/architecture.md`:**

The agent appends or updates the Value Object entry:

```markdown
## Value Object

A Value Object is a data structure that is fully described by its fields and carries no
identity. It is immutable by convention and safe to serialize, compare by equality, and pass
across module boundaries without introducing a dependency on a class hierarchy.

**When to use it**: return types from pure-computation functions that cross module or
process boundaries (e.g., pagination metadata, search result summaries, validation reports).

**When not to use it**: when the structure has behavior that must be encapsulated, or when
identity tracking is required (prefer an Entity in those cases).

**In this project**: `PageMeta` in `lib/pagination.ts` is a canonical example. See also
the ADR convention at `docs/en/adr/` for when new Value Objects warrant a formal record.

**Reference**: Martin Fowler, *Patterns of Enterprise Application Architecture*, Value Object
pattern, https://martinfowler.com/eaaCatalog/valueObject.html
```

The entry did not exist before this session. On the next session where a Value Object appears, the agent deepens the entry if the new context adds something — for instance, if a later session introduces a more complex case involving nested Value Objects, that case is added as a subsection of the same entry, not filed under a new date heading.

---

## Philosophy

### Annotations are a separate layer, not a behavior change

Learning Notes never appear inside generated artifacts. They are not inline comments in production files, not added to test code, not embedded in documentation. They are a trailing section in the agent's chat response. The code the implementer writes when Learning Mode is on is the same code it writes when Learning Mode is off. This is not enforced by hashing agent output — LLM output is non-deterministic, and golden-file regression against it would flake. It is enforced by three deterministic CI checks in `.claude/meta/scripts/check-learn-invariants.sh`: `disable-model-invocation: true` on the learn Skill, the guard branch in every learning-aware agent prompt, and the gitignore posture.

The reason for this strictness is that an annotation layer which bleeds into production artifacts is not an annotation layer — it is a code quality degradation. Comments added for pedagogical purposes accumulate technical debt. Learning Notes stay in the conversation.

### Knowledge is organized by domain, not by session

A chronological log records what happened. A domain-organized knowledge directory records what is known. Learning Mode does not maintain a chronological journal at all — the per-response "knowledge diff" in the chat output is the session-level provenance record, and git history is the long-term audit trail. The knowledge directory is the structured knowledge layer. When an agent adds a note about the repository pattern in session three, and another agent references the repository pattern in session seventeen, the note in `persistence-strategy.md` is the canonical place where that knowledge lives — deepened by session seventeen, not duplicated alongside it.

This mirrors how expertise actually works. A developer who has worked on a codebase for two years does not remember every session. They have a mental model built from many encounters with the same patterns. The knowledge directory externalizes that model.

### Levels adjust depth, not whether knowledge is shared

The three levels do not represent "how much the developer is taught." They represent which decisions are worth noting. A junior developer benefits from notes on every pattern decision because most patterns are new. A senior developer is not served by notes on patterns they know; they are served by notes on the non-obvious choices — the cases where the agent picked an alternative worth examining.

An agent at `senior` level that produces zero Learning Notes has not failed. It has correctly determined that this particular response contained no decisions that warranted a note at that level. Zero notes is a valid and frequent outcome for senior sessions, and that is the point.

### All 15 agents participate

There is no subset of "learning agents." All 15 agents in the team contribute to the knowledge directory when Learning Mode is on, each in the domains relevant to their function. The security-reviewer contributes to `security-mindset.md`. The product-manager contributes to `api-design.md`. The devops-engineer contributes to `operational-awareness.md` and `release-and-deployment.md`. The ui-ux-designer contributes to `ui-ux-craft.md`. Restricting Learning Mode to a subset of agents would create blind spots: the developer would accumulate knowledge about implementation patterns but not about security trade-offs or infrastructure decisions, which is exactly the kind of incomplete picture that produces siloed thinking.

### `docs/en/` is the source of truth

Documentation is in `docs/en/` (English, source of truth) with Japanese translations in `docs/ja/`. Agents read from `docs/en/` only, to minimize context window usage. Japanese files include a header linking to their English source. This separation is a deliberate choice: maintaining two authoritative versions of the same document doubles the maintenance burden and guarantees eventual drift. One source of truth with one maintained translation is more reliable.

### Foundational context is preserved

Learning Notes are brief, but the domain knowledge files take the space they need. A knowledge entry that fully explains the repository pattern — when to use it, when not to, how it is applied in this specific project, the ADR that records the decision — is more useful than a compressed summary that omits the "when not to" section. Pruning for scan-ability is not done. The audience is a developer who intends to understand the codebase, not a visitor who wants a quick impression.

---

## Where to go next

- [ADR-001](adr/001-developer-growth-mode.md) — the authoritative design decision for the knowledge pillar, including alternatives considered and consequences (partially superseded by ADR-003 for paths and terminology).
- [ADR-003](adr/003-learning-mode-relocate-and-rename.md) — the v2.0.0 decision that renamed the feature, relocated the directory, and replaced "notes/notebook" with "knowledge."
- [ADR-004](adr/004-coaching-pillar.md) — the v2.1.0 design decision for the coaching pillar: six styles (`default` plus five active modes), the hybrid Output Styles architecture, config schema, and composition rules.
- [PRD](prd/developer-learning-mode.md) — functional requirements, non-functional requirements, and acceptance criteria for both pillars.
- [Domain taxonomy](learn/domain-taxonomy.md) — authoritative list of the 19 canonical domains and their owners (knowledge pillar).
- `.claude/skills/learn/preamble.md` — the enrichment contract every learning-aware agent follows at runtime, including §§15–20 covering the coaching pillar.
- `.claude/skills/learn/coach-styles/<style>.md` — the style files that define the deterministic behavior rules for each coaching style.
- `.claude/meta/references/examples/<domain>.md` — read-only worked examples showing what populated knowledge files look like, grounded in the Meridian reference project (one file per canonical domain).
