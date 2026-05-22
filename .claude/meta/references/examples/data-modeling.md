---
domain: data-modeling
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: architect
contributing-agents: [architect]
---

> **Read-only reference.** This file is shipped with the ECC Base Template as a worked
> example to illustrate what a populated knowledge file looks like after many sessions on
> a real project. It is **not** your knowledge file. Your own knowledge file lives at
> `.claude/learn/knowledge/data-modeling.md` and starts empty until agents enrich it during real
> work. Agents never read, cite, or write under `.claude/meta/references/examples/` — this tree
> is for human readers only. See [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md)
> for the design rationale.

---

## How to Read This File

Level markers indicate the intended audience for each section:
- `[JUNIOR]` — first-principles explanation; assumes no prior exposure
- `[MID]` — non-obvious idiomatic application in this stack
- `[SENIOR]` — non-default trade-off evaluation; names what is given up

---

## Tasks, Assignments, and Workspaces: The Core Aggregate  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

A **data model** is the set of entities a system stores, their attributes, and their
relationships. Two questions dominate every decision: what counts as a single entity,
and which relationships warrant their own table versus being embedded.

In domain-driven design vocabulary, an **aggregate** is a cluster of entities loaded,
modified, and persisted as a unit, with a single root that controls access to the
others. The aggregate boundary is the consistency boundary: a transaction either
modifies the whole aggregate consistently, or none of it.

Meridian's central aggregate is the **Task**. A task belongs to one workspace and has
zero or more assignees, comments, attachments, and a deadline. The boundary question is
which of those embed in the task row, which become separate tables linked by FK, and
which become entirely separate aggregates.

### Idiomatic Variation  [MID]

Meridian's core schema uses three aggregate roots — `workspaces`, `users`, and
`tasks` — with a join table for the many-to-many between users and tasks:

```sql
-- workspaces, users, workspace_members elided for brevity:
--   workspaces(id, name, plan_tier, created_at, deleted_at)
--   users(id, email UNIQUE, display_name, created_at, deleted_at)
--   workspace_members(workspace_id FK→workspaces ON DELETE CASCADE,
--                     user_id FK→users ON DELETE CASCADE, role, joined_at)

CREATE TABLE tasks (
    id              UUID        PRIMARY KEY,
    workspace_id    UUID        NOT NULL REFERENCES workspaces(id) ON DELETE RESTRICT,
    title           TEXT        NOT NULL,
    description     TEXT        NOT NULL DEFAULT '',
    status          TEXT        NOT NULL CHECK (status IN ('todo','in_progress','done','archived')),
    deadline_at     TIMESTAMPTZ NULL,
    deadline_tz     TEXT        NULL,
    assignee_count  INTEGER     NOT NULL DEFAULT 0,
    created_by      UUID        NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at      TIMESTAMPTZ NULL
);

CREATE TABLE task_assignments (
    task_id     UUID        NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    assigned_by UUID        NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    PRIMARY KEY (task_id, user_id)
);
```

The on-delete behavior is intentionally non-uniform. `workspace_members` cascades
because a deleted workspace has no meaningful members. `tasks.workspace_id` restricts
because a workspace cannot be deleted while it still owns tasks. `task_assignments`
cascades on `task_id` (an assignment without a task is meaningless) but restricts on
`user_id` (losing assignment history when a user is removed would corrupt audit trails).

### Trade-offs and Constraints  [SENIOR]

Treating `task_assignments` as a join table inside the task aggregate — rather than as
its own root — means loading a task with its assignees is a single repository call. The
boundary is correct because an assignment has no independent lifecycle: it cannot exist
before its task, be queried without it, or transfer between tasks. Treating assignments
as a separate aggregate would force callers to coordinate two aggregates per operation
with no consistency benefit.

The cost is that high-volume assignment activity (sprint planning re-assigns hundreds
of tasks) writes to the same aggregate as the task body, raising lock contention on the
`tasks` row. At ~50 customers and peak ~200 concurrent writes per workspace this is not
a bottleneck. If it becomes one, the response is to split assignments into their own
aggregate and accept eventual consistency between "task says N assignees" and
"assignment table has N rows" — the cost the current boundary buys back.

The Go domain types map one-to-one onto these tables, with the exception of
`tasks.assignee_count` — see [Denormalized Counters](#denormalized-counters-tasksassignee_count)
below for why that column exists despite being derivable from `task_assignments`.

### Related Sections

- [See architecture → Repository Pattern](./architecture.md#repository-pattern) for how
  the `TaskRepository` interface owns both `tasks` and `task_assignments` as a single
  aggregate.
- [See persistence-strategy → Indexing Strategy on the Tasks Table](./persistence-strategy.md#indexing-strategy-on-the-tasks-table)
  for the indexes that support the cursor pagination on this schema.

### Coach Illustration (default vs. hints)

> **Illustrative only.** Not part of the live agent contract. Governed by
> `.claude/skills/learn/coach-styles/`.

**Scenario:** A learner asks the agent to add a "task tag" feature where users can attach
short string labels to tasks for filtering.

**`default` style** — The agent produces the migration adding a `task_tags` join table
(`task_id`, `tag_name`, `created_at`), the domain type, repository methods (`AddTag`,
`RemoveTag`, `ListTagsForTask`), and the `(workspace_id, tag_name)` index. `## Learning:`
trailers explain why tags live in a join table rather than a PostgreSQL `text[]` column
on `tasks` (array queryability degrades as the filter set grows; a join table indexes
cleanly).

**`hints` style** — The agent emits the migration scaffold (column names and types
only) and empty repository method signatures, then a `## Coach: hint` block naming the
pattern (junction table for many-to-many) and the trade-off (queryability versus row
count). The learner fills in the constraints and repository bodies.

---

## ULID Identifiers Over Auto-Increment Integers  [MID]

### First-Principles Explanation  [JUNIOR]

A **primary key** uniquely identifies each row. Three families dominate: auto-incrementing
integers (`SERIAL`, `BIGSERIAL`), random UUIDs (v4), and time-ordered identifiers
(UUID v7, ULID, KSUID). Each makes a different trade-off:

- **Auto-increment integers** are compact and creation-ordered. The cost is central
  sequence allocation — every insert coordinates with the database, which becomes a
  latency floor in multi-region or sharded deployments. They also leak volume:
  a competitor counting `task_id` values in URLs can estimate total task count.
- **Random UUIDs (v4)** need no coordination but are unordered. Inserting them into a
  B-tree fragments the index because each insert lands at a random position. Both
  write throughput and range-scan cache efficiency degrade.
- **Time-ordered identifiers** solve both problems: 128 bits of identifier space
  (no coordination) with high-order bits derived from the timestamp (inserts append).
  ULIDs encode 48 ms-bits plus 80 random bits as a 26-character base32 string; UUID v7
  encodes 48 ms-bits plus 74 random bits in standard UUID format.

### Idiomatic Variation  [MID]

Meridian uses ULIDs stored as PostgreSQL `UUID` columns. The 128-bit ULID is bit-compatible
with the UUID storage format, so the database sees `UUID` and the application sees a
ULID-shaped string when serialized to clients:

```go
// domain/id.go
type TaskID uuid.UUID

func NewTaskID() TaskID {
    return TaskID(ulid.Make().UUID())  // ULID bits stored in UUID column
}

func (id TaskID) String() string {
    return ulid.ULID(id).String()       // 26-char base32 in API responses
}
```

The schema (see core aggregate above) uses `UUID PRIMARY KEY` everywhere; nothing in
the DDL hints at ULID. The choice is a runtime convention enforced in the domain
package's ID constructors and serializers. API responses present the ULID form
(`01HQXR4Z8K3M2N1P6V7W8Y9X0A`) — shorter, case-insensitive, no `0`/`O` ambiguity —
while internal logs and `psql` use the hyphenated UUID form by default.

### Trade-offs and Constraints  [SENIOR]

The ULID-in-UUID-column approach gives up two things compared to native UUID v7. First,
the encoding split (bits in DB, base32 in API) means every serializer converts between
formats, and operators cross-referencing logs against database state must learn which
form each surface uses. Second, `oklog/ulid` is a third-party dependency; UUID v7 (now
standardized in RFC 9562) offers the same time-ordering with first-party tooling.

Meridian chose ULID over UUID v7 in 2025 when v7 was still draft and library support
was inconsistent. The decision is documented in ADR-007: Identifier Format. If a
green-field schema were started today and v7 support were verified across the Go,
TypeScript, and Postgres tooling, v7 would be the default. Migrating the existing
schema is bounded (storage format is identical) but unmotivated.

### Related Sections

- [See persistence-strategy → Indexing Strategy on the Tasks Table](./persistence-strategy.md#indexing-strategy-on-the-tasks-table)
  for why time-ordered IDs reduce B-tree fragmentation on the `tasks` primary key index.
- [See api-design → Resource Hierarchy](./api-design.md#resource-hierarchy-tasks-and-assignments)
  for how task IDs appear in URLs in their ULID form.

---

## Soft Deletes with `deleted_at` Versus Hard Deletes  [MID]

### First-Principles Explanation  [JUNIOR]

A **soft delete** marks a row as deleted by setting a column (typically `deleted_at`)
without removing it. A **hard delete** removes the row entirely. The trade-off is
auditability versus storage cost and query simplicity. Soft deletes preserve history
(an accidentally-deleted task can be restored, an audit six months later can see what
existed) at the cost of storage and the complexity of filtering `WHERE deleted_at IS NULL`
on every read. Hard deletes release storage immediately but destroy history.

A common middle ground: soft-delete user-facing entities (tasks, comments) where
restoration and audit have value; hard-delete auxiliary entities (rate-limit counters,
idempotency keys, expired sessions) where history has no value and storage should be
reclaimed promptly.

### Idiomatic Variation  [MID]

Meridian soft-deletes `tasks`, `users`, `workspaces`, and `comments`. It hard-deletes
`task_assignments`, `idempotency_keys`, and `sessions`. The policy is enforced by
convention in the repository layer:

```go
// repository/task.go — soft delete sets deleted_at and writes an audit row in one tx
func (r *postgresTaskRepository) Delete(ctx context.Context, id, actorID uuid.UUID) error {
    return r.withTx(ctx, func(tx *sql.Tx) error {
        if _, err := tx.ExecContext(ctx, `
            UPDATE tasks SET deleted_at = now(), updated_at = now()
            WHERE id = $1 AND deleted_at IS NULL
        `, id); err != nil {
            return err
        }
        _, err := tx.ExecContext(ctx, `
            INSERT INTO audit_log (entity_type, entity_id, action, actor_id, occurred_at)
            VALUES ('task', $1, 'delete', $2, now())
        `, id, actorID)
        return err
    })
}
```

Every read query in the repository layer carries `WHERE deleted_at IS NULL` (see the
`Get` example in [architecture → Repository Pattern](./architecture.md#repository-pattern)).

The append-only `audit_log` table is the durable record of state transitions. A
soft-deleted `tasks` row plus an `audit_log` entry gives both the "what existed and was
removed" view and the "who did what when" view.

For GDPR Right-to-Erasure requests, the `users` row is hard-deleted and audit entries
referencing it are anonymized to a tombstone user ID — the policy distinguishes
"deleted by user action" (soft) from "deleted by erasure request" (hard plus
anonymization).

### Trade-offs and Constraints  [SENIOR]

The biggest cost of `WHERE deleted_at IS NULL` filters is forgetting one. A one-off
report query that omits the filter silently includes deleted rows; the numbers diverge
from what the application shows. Meridian mitigates this by exposing only filter-applying
repository methods (no raw SQL from service code) and by reviewing every new repository
query for the clause. Partial indexes on `WHERE deleted_at IS NULL` keep common-case
queries fast without indexing deleted rows.

Row-level security in Postgres could enforce the filter at the database, but Meridian
has not adopted RLS: it shifts access control from the application into the database,
complicates connection pooling, and makes test fixtures harder to construct. The
convention-plus-review approach holds at this scale.

### Related Sections

- [See error-handling → Domain Error Type Hierarchy](./error-handling.md#domain-error-type-hierarchy)
  for how `domain.ErrNotFound` is returned when a soft-deleted row is requested.
- [See security-mindset → Multi-Tenant Isolation](./security-mindset.md#multi-tenant-isolation-workspace_id-on-every-query)
  for the hard-delete-plus-anonymize policy that overrides the soft-delete default.

---

## Denormalized Counters: `tasks.assignee_count`  [SENIOR]

### Idiomatic Variation  [MID]

The `tasks` table carries an `assignee_count` integer column even though the count is
exactly derivable from `SELECT COUNT(*) FROM task_assignments WHERE task_id = $1`. This
is intentional denormalization. Two reasons drove it:

First, the task list view — the most-loaded screen in the product — displays the
assignee count badge for every task in the visible window (~50 tasks). Without the
cached count, the list becomes a JOIN with `GROUP BY` aggregation, or a per-task count
query (the N+1 antipattern). With the cached count, the list reads one row per task.

Second, the count is updated synchronously inside the same transaction as the
assignment insert or delete. The count cannot drift unless application code bypasses
the repository, because every write goes through `AddAssignee` or `RemoveAssignee`:

```sql
-- inside one transaction, after INSERT INTO task_assignments(...)
UPDATE tasks
SET assignee_count = (SELECT COUNT(*) FROM task_assignments WHERE task_id = $1),
    updated_at = now()
WHERE id = $1;
```

The subquery reads the freshly-inserted assignment row inside the same transaction, so
the cached count is always correct at commit time.

### Trade-offs and Constraints  [SENIOR]

Denormalization is a debt paid every write. Each `AddAssignee` or `RemoveAssignee`
becomes a two-statement transaction with a row-level lock on the parent task, so
concurrent assignments to the same task serialize. At Meridian's scale this is
acceptable because the same task is rarely assigned by two users in the same
millisecond; when it does happen, the second writer waits a few milliseconds.

The alternative of computing the count in the read query was rejected because the
read-to-write ratio for tasks is roughly 200:1 — optimizing the rare write path at the
cost of the common read path is the wrong direction. Asynchronous background computation
was also rejected because it opens a window where "the badge says 3 but I only see
2 names." Synchronous denormalization keeps the count honest at the cost of one extra
UPDATE per write.

The decision must be revisited if a feature ships that bulk-assigns hundreds of tasks
in a loop (a sprint-import feature). Criterion: sustained write volume on
`task_assignments` exceeds 50 inserts/sec on a single workspace; either batching the
count update or moving to derived-on-read becomes justified at that point.

### Related Sections

- [See performance-intuition → N+1 on the Task List Assignee Lookup](./performance-intuition.md#n1-on-the-task-list-assignee-lookup)
  for why the alternative read-time aggregation was rejected.
- [See persistence-strategy → Transaction Boundaries Live in Services, Not Repositories](./persistence-strategy.md#transaction-boundaries-live-in-services-not-repositories)
  for how `withTx` wraps the two statements above.

---

## Temporal Modeling: Deadlines, Time Zones, and Recurrence  [MID]

### First-Principles Explanation  [JUNIOR]

Time data has three independent dimensions schemas must keep distinct: the **instant**
(a point on the universal timeline), the **wall-clock time** (the hour and minute on a
particular calendar), and the **time zone** (the rule mapping between them). A schema
storing only one of the three loses information unrecoverable from the others.

"Friday at 5pm in São Paulo" is wall-clock plus zone. Converting it to a UTC instant at
entry time discards the zone, so if Brazil shifts daylight-saving rules between now and
Friday (it has done so), the stored instant is no longer "Friday at 5pm in São Paulo."
Storing only wall-clock plus zone forces every "what's overdue?" query to convert per row.

### Idiomatic Variation  [MID]

Meridian's `tasks.deadline_at` column is `TIMESTAMPTZ` (an instant), and the companion
`tasks.deadline_tz` column is the IANA time zone name (`America/Sao_Paulo`). Both are
written together; neither is derivable from the other:

```sql
deadline_at  TIMESTAMPTZ NULL,
deadline_tz  TEXT        NULL,
CHECK ((deadline_at IS NULL) = (deadline_tz IS NULL))
```

The CHECK constraint enforces pairing: either both are set or neither is. The instant
drives overdue-check queries (`WHERE deadline_at < now()`); the zone drives UI display
and notification timing ("deadline tomorrow" reminders fire at 9am local, not 9am UTC).
Calendar integrations export both fields so external calendars render the deadline in
the user's preferred zone, which may differ from the deadline's authored zone.

Recurring deadlines live in a separate `recurrence_patterns` table storing RFC 5545
RRULE strings; a background job materializes the next concrete instance when the
previous one completes, avoiding the N-instance problem of storing every future
occurrence at authoring time.

### Trade-offs and Constraints  [SENIOR]

Storing instant and zone separately means the application must keep them paired in
every domain type, API response, and form. The CHECK constraint catches schema
violations at write time, but the application-layer contract is implicit.

The alternative — storing only `TIMESTAMPTZ` and inferring zone from the authoring
user's profile — was rejected because the authoring user's zone is not the deadline's
intended zone. A user in Tokyo creating "5pm Friday for the São Paulo team" needs São
Paulo's zone. A profile-zone fallback would silently produce wrong reminder times. The
cost of explicit pairing falls on engineering; profile fallback would fall on the user.

### Related Sections

- [See ecosystem-fluency → Go Stdlib vs. Third-Party: The Meridian Policy](./ecosystem-fluency.md#go-stdlib-vs-third-party-the-meridian-policy)
  for the `time.Time` and IANA zone APIs the repository uses to convert between instant
  and wall-clock representations.

---

## Schema Evolution: Non-Nullable Columns on a Large Table  [SENIOR]

### Idiomatic Variation  [MID]

Adding a non-nullable column with a default to a 50-million-row table on a live
PostgreSQL deployment without downtime requires care. Postgres 11+ stores constant
defaults as metadata and avoids the rewrite, but a function default (such as
`gen_random_uuid()`) still triggers a full table rewrite that locks the table for the
duration.

Meridian's `tasks` table reached ~50 million rows in late 2025. The migration that added
`tasks.assignee_count` was structured as four steps to avoid downtime:

```sql
-- Migration step 1 (deployed first): add column as NULL with no default
ALTER TABLE tasks ADD COLUMN assignee_count INTEGER NULL;

-- Application step 2 (next deploy): writers populate column on every UPDATE; old rows NULL

-- Migration step 3 (background job): backfill in batches of 10,000
UPDATE tasks SET assignee_count = (SELECT COUNT(*) FROM task_assignments WHERE task_id = tasks.id)
WHERE id IN (SELECT id FROM tasks WHERE assignee_count IS NULL ORDER BY id LIMIT 10000);

-- Migration step 4 (after backfill complete): tighten the constraint
ALTER TABLE tasks ALTER COLUMN assignee_count SET DEFAULT 0;
ALTER TABLE tasks ALTER COLUMN assignee_count SET NOT NULL;
```

The four steps decouple schema change from data backfill from constraint tightening.
Each step is independently safe and reversible. The application is correct throughout.

### Trade-offs and Constraints  [SENIOR]

Four steps over four deploys means a feature needing the new column is not shippable
until the fourth deploy lands — roughly two weeks of calendar time, dominated by deploy
windows and backfill duration rather than engineering time. The alternative of a
maintenance window with the migration in one step was rejected because Meridian's SLA
promises 99.9% monthly uptime (~43 minutes of allowable downtime per month); an
hour-long window would consume the entire monthly budget.

The cost of the staged approach is per-migration complexity: four PRs, four deploys, a
backfill job to monitor, and a window during which the application must tolerate NULL
for some rows. Migrations routine on small tables become multi-week projects on large
ones. Subsequent migrations on `tasks` follow this pattern by default, codified in
`docs/en/runbooks/large-table-migration.md`. Column drops follow the inverse pattern:
stop reading, stop writing, drop — readers and writers must be off the column before
the DROP commits.

### Related Sections

- [See release-and-deployment → Database Migrations as a Deploy Gate](./release-and-deployment.md#database-migrations-as-a-deploy-gate)
  for the deploy-staging conventions that the four-step migration relies on.
- [See operational-awareness → Three-Pillar Observability](./operational-awareness.md#three-pillar-observability-logs-metrics-and-traces)
  for how the step-3 backfill is observed and resumed if interrupted.

---

## Prior Understanding: Auto-Increment Primary Keys  [MID]

> Superseded 2025-09-12: The original schema used `BIGSERIAL` primary keys on every
> table. This was incorrect for Meridian's roadmap because a multi-region deployment
> (planned for late 2025) cannot share a central sequence without coordination latency,
> and IDs in URLs leaked task volume to anyone who could enumerate them.

> Original schema (incorrect for the target deployment model):
> ```sql
> CREATE TABLE tasks (id BIGSERIAL PRIMARY KEY, workspace_id BIGINT NOT NULL, ...);
> -- API response: { "id": 8472, "title": "...", ... }   // ID is enumerable
> ```

**Corrected understanding:**

Meridian migrated from `BIGSERIAL` to `UUID` populated with ULID values in September
2025, before the multi-region rollout. The migration was staged: a new `uuid_id` column
populated with `ulid.Make()` for new and existing rows, foreign keys duplicated, and
after a multi-week verification the integer columns dropped and the UUID columns
renamed to `id`.

Three problems with the original `BIGSERIAL` design forced the change:

1. **Multi-region writes.** A central PostgreSQL sequence is single-region by
   definition. Per-region strides work but introduce an operational hazard: a
   misconfigured region whose stride overlaps another's silently breaks foreign-key
   invariants. UUID-shaped IDs avoid the question.
2. **Information leakage.** A task ID of `8472` in a URL tells any holder that Meridian
   has handled at most 8,472 tasks; competitors enumerate IDs to estimate vendor scale.
   ULIDs leak creation time but not aggregate volume.
3. **Hot-spotting on inserts.** A monotonically-increasing primary key concentrates
   write load on the right edge of the B-tree. Time-ordered ULIDs preserve write
   locality while spreading load across leaf pages.

The migration cost about three engineer-weeks. The forcing function was the multi-region
roadmap; absent it, the team would have lived with `BIGSERIAL` and accepted the
leakage. The pattern: a schema decision that looks fine in single-region becomes wrong
when the roadmap adds a constraint that did not exist when the schema was first
designed. Schema choices age against the roadmap, not against the present.

### Related Sections

- [See data-modeling → ULID Identifiers](#ulid-identifiers-over-auto-increment-integers)
  for the current ID strategy that replaced BIGSERIAL.
- [See architecture → Hexagonal Split](./architecture.md#hexagonal-split)
  for the deployment-model constraints that drove the migration.
