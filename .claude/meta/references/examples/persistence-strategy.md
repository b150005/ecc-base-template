---
domain: persistence-strategy
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: architect
contributing-agents: [architect, implementer]
---

> **Read-only reference.** This file is shipped with the ECC Base Template as a worked
> example to illustrate what a populated knowledge file looks like after many sessions on
> a real project. It is **not** your knowledge file. Your own knowledge file lives at
> `.claude/learn/knowledge/persistence-strategy.md` and starts empty until agents enrich it during
> real work. Agents never read, cite, or write under `.claude/meta/references/examples/` — this
> tree is for human readers only. See
> [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md) for the design rationale.

---

## How to Read This File

Level markers indicate the intended audience for each section:
- `[JUNIOR]` — first-principles explanation; assumes no prior exposure
- `[MID]` — non-obvious idiomatic application in this stack
- `[SENIOR]` — non-default trade-off evaluation; names what is given up

---

## Postgres + Redis Split: What Lives Where  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

A backend service typically needs two qualitatively different storage capabilities.
**Durable, queryable, transactional** storage holds business records (tasks, users,
audit history) — a relational database is the canonical fit. **Fast, ephemeral** storage
holds state that is short-lived or read-heavy on every request (session tokens,
rate-limit counters, deduplication keys, hot-path caches). A relational database can
serve the second load, but doing so wastes the durability and query power that cost the
most. An in-memory key-value store handles single-key access orders of magnitude faster
and is willing to forget data on a planned schedule. The split matches each store to its
designed access pattern; the cost is operational (two monitoring surfaces, two failure
modes), the benefit is that each store does what it does well.

### Idiomatic Variation  [MID]

Meridian's rule: **PostgreSQL is the source of truth; Redis holds nothing that cannot be
reconstructed.** Any state in Redis must be derivable from Postgres data, recomputable
from request inputs, or expirable without business loss. A full Redis flush at 3 a.m.
must not corrupt any user-visible record.

| Concern | Store | Rationale |
|---------|-------|-----------|
| Tasks, workspaces, users, assignments, audit log | Postgres | Durable; relational; transactional |
| Idempotency keys (Slack webhook event IDs) | Redis (24h TTL) | Loss = at most one duplicate notification |
| Rate-limit counters (sliding window) | Redis (60s TTL) | Loss = a brief over-quota burst |
| JWT refresh denylist after logout | Redis (until JWT exp) | Loss = logged-out token works until natural expiry |
| Workspace metadata cache (read-through) | Redis (5min TTL) | Loss = one slow request re-warms the cache |

What does **not** live in Redis: billing state, task content, assignment records, audit
history. Anything whose loss would surprise a user or trigger a support ticket lives in
Postgres only.

### Trade-offs and Constraints  [SENIOR]

The cache layer admits **stale reads**: an admin who renames a workspace may briefly see
the old name on adjacent pages. Targeted invalidation (every write enqueues a Redis `DEL`
for the affected keys) reduces but does not eliminate this. The team accepts brief
staleness rather than chasing strict consistency through this path.

Two alternatives were rejected. No-cache pushed Postgres connection-pool pressure beyond
comfort during the 2026-Q1 rollout to a 200-seat customer. Write-through doubled write
latency and introduced a new failure mode (Postgres succeeds, Redis fails — what now?).
Read-through with targeted invalidation was the middle ground.

### Related Sections

- [See architecture → Hexagonal Split](./architecture.md#hexagonal-split) for how the
  repository layer encapsulates both Postgres and Redis access behind interfaces.
- [See error-handling → Idempotent Retry on the Slack Webhook](./error-handling.md#idempotent-retry-on-the-slack-webhook)
  for the Redis `SET NX` pattern that backs the idempotency layer.
- [See api-design → Idempotency Key Handling](./api-design.md#idempotency-key-handling)
  for the HTTP surface that consumes this split.

---

## Indexing Strategy on the Tasks Table  [MID]

### First-Principles Explanation  [JUNIOR]

A relational database can answer any query without an index by scanning every row;
the scan cost grows linearly with table size. An **index** is a separate B-tree that
locates matching rows in logarithmic time. The cost: every write must update every
index, and every index occupies disk and memory. An unused index is pure overhead.

### Idiomatic Variation  [MID]

The `tasks` table holds approximately 50 million rows across all customers. The indexes
Meridian maintains:

```sql
CREATE TABLE tasks (
    id            UUID PRIMARY KEY,
    workspace_id  UUID NOT NULL REFERENCES workspaces(id),
    title         TEXT NOT NULL,
    assignee_id   UUID REFERENCES users(id),
    status        TEXT NOT NULL,  -- 'active' | 'archived' | 'deleted'
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    archived_at   TIMESTAMPTZ,
    deleted_at    TIMESTAMPTZ
);

CREATE INDEX tasks_workspace_created_idx
    ON tasks (workspace_id, created_at DESC, id DESC)
    WHERE deleted_at IS NULL;

CREATE INDEX tasks_assignee_status_idx
    ON tasks (assignee_id, status)
    WHERE deleted_at IS NULL AND assignee_id IS NOT NULL;

CREATE INDEX tasks_workspace_status_idx
    ON tasks (workspace_id, status)
    WHERE deleted_at IS NULL;
```

Every index is **partial** with `WHERE deleted_at IS NULL`. Soft-deleted rows are
excluded from index storage entirely; the audit-export job that needs them scans the heap
directly. The composite `(workspace_id, created_at DESC, id DESC)` directly serves the
cursor pagination query in
[api-design → Cursor-Based Pagination on Task Lists](./api-design.md#cursor-based-pagination-on-task-lists);
column order matches the `WHERE` and `ORDER BY` exactly. The `assignee_id` index
excludes nulls because most tasks are unassigned at creation; partial-indexing shrinks
the index by roughly 40 percent.

### Trade-offs and Constraints  [SENIOR]

Indexes Meridian considered and **did not** create:

- **`title` full-text GIN index.** A 2025-Q4 product ask. Rejected because tasks is the
  highest-write table (a GIN index roughly triples write cost when `title` changes) and
  because full-text across 50M rows for one workspace's 10K tasks reads global postings
  before filtering. Search was routed to a separate Postgres-backed service that
  materializes per-workspace inverted indexes on a 5-minute lag. Trade-off accepted:
  titles edited in the last five minutes do not yet match.
- **`updated_at` index.** No hot-path query orders by `updated_at`. Adding the index
  would carry write cost for a query that does not exist.
- **Per-status indexes (`tasks_active_idx`, `tasks_archived_idx`).** The composite
  `(workspace_id, status)` covers status filtering and is more selective. Single-column
  status indexes were rejected as redundant.

The rule: an index ships only when EXPLAIN ANALYZE on production-shaped data shows it is
required to keep p95 query latency under 50ms at the 99th-percentile workspace size.

### Example (Meridian)

The cursor-pagination query plan against `tasks_workspace_created_idx` consumes the
composite end-to-end (the `WHERE` uses the leading `workspace_id`; the row tuple uses
`(created_at, id)`); execution stays around 2ms. Replacing the composite with two
single-column indexes regresses to ~80ms on the same data.

### Related Sections

- [See api-design → Cursor-Based Pagination on Task Lists](./api-design.md#cursor-based-pagination-on-task-lists)
  for the query pattern that drives the composite index design.
- [See error-handling → Boundary Translation: Postgres to Domain Errors](./error-handling.md#boundary-translation-postgres-to-domain-errors)
  for the `23505` unique-violation translation that the unique index on
  `(workspace_id, external_slug)` (not shown above) produces.

---

## Transaction Boundaries Live in Services, Not Repositories  [MID]

### First-Principles Explanation  [JUNIOR]

A database **transaction** groups multiple writes so they either all commit or all roll
back — the mechanism by which relational databases preserve invariants across rows that
conceptually belong together (a task and its assignment, an archive and its audit entry).
The design question for layered services is **where the transaction boundary lives**. If
the repository opens its own transaction per method, multi-step operations across two
repositories cannot share one. If the service opens the transaction and passes a handle
into the repository, the repository becomes coupled to transaction lifecycle.

### Idiomatic Variation  [MID]

Meridian places transaction boundaries in the **service** layer. Repository methods
accept an interface that satisfies both pooled connections and active transactions, so
the same method works inside or outside a transaction:

```go
// repository/task.go — accepts the dbtx interface, not a concrete pool
type dbtx interface {
    QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
    Exec(ctx context.Context, sql string, args ...any) (pgconn.CommandTag, error)
}

func (r *postgresTaskRepository) ArchiveWithTx(ctx context.Context, tx dbtx, id uuid.UUID) error {
    _, err := tx.Exec(ctx, `UPDATE tasks SET archived_at = now(), status = 'archived' WHERE id = $1`, id)
    return translatePostgresError(err)
}

// service/task.go
func (s *TaskService) ArchiveWithAuditEntry(ctx context.Context, taskID, callerID uuid.UUID) error {
    tx, err := s.pool.BeginTx(ctx, pgx.TxOptions{IsoLevel: pgx.ReadCommitted})
    if err != nil {
        return err
    }
    defer tx.Rollback(ctx) // no-op if Commit succeeded
    if err := s.tasks.ArchiveWithTx(ctx, tx, taskID); err != nil {
        return err
    }
    if err := s.audit.RecordWithTx(ctx, tx, callerID, "task.archive", taskID); err != nil {
        return err
    }
    return tx.Commit(ctx)
}
```

For single-statement operations the service calls the non-transactional repository
method, which uses the pool directly. The repository exposes both shapes (`Archive` and
`ArchiveWithTx`); the duplication keeps callers explicit about transaction scope.

### Trade-offs and Constraints  [SENIOR]

Service-owned transactions force the service layer to understand database semantics
(isolation levels, deadlock retry, read-vs-write transactions) that the repository would
otherwise hide. The team accepted this because the alternative — repository-owned
transactions — meant any cross-aggregate write either had to live inside a single
repository (violating one-aggregate-per-repository) or had to be split into separate
transactions with manual compensation on partial failure (violating atomicity).

The forcing case: archiving a task and writing the audit-log entry must succeed or fail
together. If the archive commits and the audit entry fails, Meridian has a compliance
gap. Service-owned transactions make this atomic; repository-owned ones cannot. The rule:
if an operation writes to two or more tables in different aggregates, the service opens
the transaction. Single-table writes use the non-transactional method.

### Related Sections

- [See architecture → Repository Pattern](./architecture.md#repository-pattern) for the
  layer split this transaction policy operates within.
- [See error-handling → Boundary Translation: Postgres to Domain Errors](./error-handling.md#boundary-translation-postgres-to-domain-errors)
  for the SQLSTATE translation that runs inside `ArchiveWithTx` before the service
  decides whether to commit.

---

## Connection Pooling with pgxpool  [MID]

### First-Principles Explanation  [JUNIOR]

Opening a TCP connection to PostgreSQL and authenticating costs roughly 30–50ms. A
service that opened a fresh connection per request would spend most of its time on
connection setup. A **connection pool** keeps a small set of open connections; each
request borrows one and returns it. The two important sizing parameters are the
**maximum number of connections** and the **idle timeout**. The maximum must respect
Postgres's own `max_connections` divided by the application replica count — if ten pods
each hold 50 connections, a 200-connection Postgres rejects the eleventh pod's first
query.

### Idiomatic Variation  [MID]

Meridian uses `pgxpool` from `jackc/pgx/v5`:

```go
func NewPool(ctx context.Context, dsn string) (*pgxpool.Pool, error) {
    cfg, err := pgxpool.ParseConfig(dsn)
    if err != nil {
        return nil, err
    }
    cfg.MaxConns = 25
    cfg.MinConns = 5
    cfg.MaxConnLifetime = 30 * time.Minute
    cfg.MaxConnIdleTime = 5 * time.Minute
    cfg.HealthCheckPeriod = 1 * time.Minute
    return pgxpool.NewWithConfig(ctx, cfg)
}
```

`MaxConns = 25` is paired with the production K8s `Deployment` running 6 replicas:
6 × 25 = 150 connections, comfortably under the managed Postgres `max_connections = 200`.
The 50-connection headroom is reserved for the migration job, the analytics replica, and
`psql` debugging sessions. `MaxConnLifetime = 30 minutes` causes connections to be closed
and reopened periodically so that planned failovers (which reroute DNS) propagate without
an application restart. `HealthCheckPeriod = 1 minute` runs a background `SELECT 1` on
idle connections so a network partition is detected quickly rather than at the next
request.

### Trade-offs and Constraints  [SENIOR]

`MaxConns = 25` is deliberate. Postgres performance does not scale with connection count
past the number of physical CPU cores; more connections cause lock contention and
context-switching overhead inside Postgres itself. The Meridian primary runs on 8 vCPU;
load testing identified 16–32 concurrent active queries as the sweet spot. With 6
replicas at 25 connections each, peak concurrent queries stay near that band.

The cost of a tighter pool is that spikes manifest as "wait for connection" latency at
the application layer rather than Postgres-side lock contention. Meridian instruments
`pgxpool.Stat().AcquireDuration` and alerts when p95 acquire exceeds 100ms — the signal
that the pool is undersized or that queries are starving it. Both are remediable;
Postgres internal lock contention is much harder to diagnose at runtime. The K8s replica
count and pool size are coupled; the deployment manifest carries a comment pointing at
this file as the reason the value is what it is.

### Prior Understanding (revised 2025-09-14)

The original implementation (Meridian's first six months in production) used Go's
standard `database/sql` package with the `lib/pq` driver and `db.SetMaxOpenConns(50)`.
This worked at low traffic but produced an incident in 2025-09 where a Postgres failover
caused every pod to hold stale connections for several minutes; the `database/sql` pool
did not detect the dead peer until the next query attempted to use it, and `lib/pq`'s
connection-health behavior did not match the team's mental model.

Revised because: switching to `jackc/pgx/v5` with `pgxpool` provided explicit
`HealthCheckPeriod`, `MaxConnLifetime`, and per-acquire context cancellation. The
`database/sql` abstraction was insufficient for bounded failover recovery. The migration
also unlocked binary-protocol parameter encoding, which removed a category of subtle
type-conversion bugs at the `time.Time` ↔ `TIMESTAMPTZ` boundary.

### Related Sections

- [See error-handling → Domain Error Type Hierarchy](./error-handling.md#domain-error-type-hierarchy)
  for how a pool-acquire timeout (a wrapped `context deadline exceeded`) is translated by
  the handler layer into a 503 Service Unavailable.

---

## Online Migrations on the 50M-Row Tasks Table  [SENIOR]

### First-Principles Explanation  [JUNIOR]

Schema changes are issued as DDL. Some DDL statements acquire an exclusive lock on the
target table for the operation's duration; while held, no other query can read or write
the table. On a small table this is invisible. On a 50-million-row table, an exclusive
lock held for a sequential scan is an outage. **Online migration** patterns split one
apparently-atomic operation into a sequence of smaller operations, each holding locks
only briefly, with the database in a valid intermediate state between steps. Postgres
provides specific keywords (`CONCURRENTLY`, `NOT VALID`, `VALIDATE CONSTRAINT`) that opt
into online behavior at the cost of some constraint-checking guarantees during the
intermediate window.

### Idiomatic Variation  [MID]

Meridian's policy for the `tasks` table:

1. **Nullable column, no default** — one statement, safe at any time.
2. **Column with a default** — in Postgres 11+, no heap rewrite; also one-statement-safe.
3. **Index** — always `CREATE INDEX CONCURRENTLY`, never plain `CREATE INDEX`.
4. **NOT NULL constraint** — the two-step `NOT VALID` pattern (below).
5. **Dropping a column** — two-deploy sequence. Deploy one stops writing the column;
   deploy two issues `ALTER TABLE ... DROP COLUMN` (fast — the column is marked dropped
   in the catalog; the heap is reclaimed lazily).

Adding a `priority SMALLINT NOT NULL` column on a 50M-row table:

```sql
-- Migration 0042 (deploy N): add nullable column.
ALTER TABLE tasks ADD COLUMN priority SMALLINT;
-- Deploy N starts writing priority for new tasks; backfill job populates
-- historical rows in batches of 5000 until none remain.

-- Migration 0043 (deploy N+1, post-backfill): enforce NOT NULL.
ALTER TABLE tasks ADD CONSTRAINT tasks_priority_not_null
    CHECK (priority IS NOT NULL) NOT VALID;
ALTER TABLE tasks VALIDATE CONSTRAINT tasks_priority_not_null;
```

`NOT VALID` adds the constraint without a table scan; `VALIDATE CONSTRAINT` subsequently
scans without blocking concurrent writes.

### Trade-offs and Constraints  [SENIOR]

The two-deploy column-drop is operationally expensive — it imposes a window (often days)
during which the column exists but is unused. The alternative (drop in the same deploy
that stops writing it) risks a rollback scenario where the redeployed code expects the
column the migration has already removed. Two deploys with a deliberate gap make rollback
safe in either direction.

`CREATE INDEX CONCURRENTLY` cannot run inside a transaction block, so the migration tool
(`golang-migrate`) is configured with a per-migration `no-transaction` hint for these.
The cost is a partial-failure mode: a failed concurrent build leaves an `INVALID` index
that must be dropped before retrying. The alternative (a blocking `CREATE INDEX`) is a
multi-minute outage on the tasks table.

The team rejects ORM auto-migration tooling entirely. Every schema change is a
hand-written migration file with explicit `NOT VALID`, `CONCURRENTLY`, and batch-size
choices made by a human who understands the table's size and write rate. Schema work is
slower per change; migrations have not caused a production incident since the policy was
adopted.

### Related Sections

- [See architecture → Repository Pattern](./architecture.md#repository-pattern) for the
  layer that absorbs schema changes — a column addition typically requires a repository
  update but no service or handler changes.

---

## Corrected: All Reads Routed to the Primary  [MID]

> Superseded 2025-12-08: The original read-routing policy sent every read query to the
> Postgres primary, ignoring the read replica entirely. This was incorrect because it
> wasted half the available read capacity and pushed primary CPU above safe headroom
> during the 2025-12 customer onboarding spike, even though the read replica was idle.

> Original policy (incorrect):
> ```go
> // Single pool, primary-only
> pool, _ := pgxpool.New(ctx, primaryDSN)
> // Every repository read used `pool` directly.
> ```

**Corrected understanding:**

Read replicas serve read-only queries from a streaming-replicated copy of the primary.
The replica lags the primary by milliseconds under normal load and by seconds under
sustained write pressure. Routing reads to the replica frees primary CPU for writes and
for reads that cannot tolerate lag. The corrected policy is **per-endpoint replica
routing**, not blanket replica use:

| Read pattern | Route to | Reason |
|--------------|----------|--------|
| Listing tasks (`GET /v1/workspaces/{wid}/tasks`) | Replica | Tolerates sub-second lag |
| Reading audit history | Replica | Read-only, never affects write paths |
| Reading a task immediately after writing it (same request) | Primary | "Read your writes" must hold |
| Reading inside a transaction | Primary | Replica cannot serve a primary-side tx |
| Authorization checks before a write | Primary | Stale replica data could permit a write the user no longer has rights to |

The implementation uses two `pgxpool.Pool` instances wired into the repository, which
exposes **two read methods**: `Get` (replica, tolerates lag) and `GetFresh` (primary,
fresh):

```go
type postgresTaskRepository struct {
    primary *pgxpool.Pool
    replica *pgxpool.Pool
}

func (r *postgresTaskRepository) List(ctx context.Context, p ListParams) ([]domain.Task, error) {
    return r.queryList(ctx, r.replica, p)
}

func (r *postgresTaskRepository) GetFresh(ctx context.Context, id uuid.UUID) (domain.Task, error) {
    return r.queryGet(ctx, r.primary, id)
}
```

The service chooses the method based on whether the read is read-modify-write,
read-after-write within a request, or a standalone display read.

After the correction, primary CPU dropped from 78% sustained to 41% at the same traffic
level; the replica moved from idle to 35%. The cost is a category of bug to watch for:
any service that reads via `Get` (replica) and then writes based on what it read must be
reviewed for read-after-write coherence — staleness can cause the write to be based on an
out-of-date snapshot. Meridian's code-reviewer flags `replica.Query` followed by a write
to the same row as a HIGH finding.

### Related Sections

- [See architecture → Repository Pattern](./architecture.md#repository-pattern) for the
  repository interface that now exposes both lag-tolerant and fresh-read methods.
- [See api-design → Cursor-Based Pagination on Task Lists](./api-design.md#cursor-based-pagination-on-task-lists)
  for the list-endpoint pattern that benefits from replica routing.

---

## Coach Illustration (default vs. hints)

> **Illustrative only.** A worked example of how the two coaching styles differ. Not
> part of the live agent contract. Actual behavior is governed by the style files at
> `.claude/skills/learn/coach-styles/`.

**Scenario:** A learner asks the agent to add a `due_date` column to the `tasks` table
with a NOT NULL constraint, including the migration and repository update.

**`default` style** — The agent produces the complete two-step migration (nullable add,
backfill plan, `NOT VALID` + `VALIDATE CONSTRAINT`), updates the repository `INSERT`/
`UPDATE` statements, updates the domain type, and writes the unit test. It appends
`## Learning:` trailers explaining the `NOT VALID` pattern and the two-deploy sequence.

**`hints` style** — The agent writes only the first migration (the nullable add), the
domain type stub, and a test stub with a TODO for the NOT NULL case. It then emits:

```
## Coach: hint
Step: Write migration 0043 to enforce NOT NULL on `tasks.due_date` after backfill.
Pattern: NOT VALID + VALIDATE CONSTRAINT (online NOT NULL on a 50M-row table).
Rationale: A direct ALTER TABLE ... SET NOT NULL acquires an exclusive lock for the
duration of a sequential scan — minutes-long write outage. NOT VALID adds the
constraint without a scan; VALIDATE CONSTRAINT scans without blocking writes.
```

`<!-- coach:hints stop -->`

The learner writes the second migration. On the next turn, the agent responds to
follow-up questions without re-writing the scaffold.
