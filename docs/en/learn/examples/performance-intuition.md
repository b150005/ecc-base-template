---
domain: performance-intuition
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: performance-engineer
contributing-agents: [performance-engineer]
---

> **Read-only reference.** This file is shipped with the ECC Base Template as a worked
> example to illustrate what a populated knowledge file looks like after many sessions on
> a real project. It is **not** your knowledge file. Your own knowledge file lives at
> `learn/knowledge/performance-intuition.md` and starts empty until agents enrich it
> during real work. Agents never read, cite, or write under `docs/en/learn/examples/` —
> this tree is for human readers only. See
> [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md) for the design rationale.

---

## How to Read This File

Level markers indicate the intended audience for each section:
- `[JUNIOR]` — first-principles explanation; assumes no prior exposure
- `[MID]` — non-obvious idiomatic application in this stack
- `[SENIOR]` — non-default trade-off evaluation; names what is given up

---

## Latency Budgets for `GET /v1/tasks`  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

A latency target — "p99 of `GET /v1/tasks` must stay under 200ms" — is not a single
number to chase at the database layer. It is a **budget** split across every step the
request passes through. Each step consumes a slice; the sum of the slices must fit
under the target with headroom for variance. If a slice grows, another must shrink, or
the target must move.

An explicit budget answers two questions a vague "make it faster" goal cannot: which
step is worth optimizing, and how much headroom remains before the next regression
breaches the target. An engineer who shaves 5ms off a query that already costs 8ms
has done less than an engineer who shaves 30ms off a JSON step nobody profiled.

### Idiomatic Variation  [MID]

Meridian's budget for `GET /v1/workspaces/{wid}/tasks?limit=20` (the highest-traffic
read endpoint) sums to 200ms at p99 and decomposes roughly as:

| Stage | Budget | Typical p99 |
|-------|--------|-------------|
| TLS + reverse proxy (ingress → pod) | 30ms | ~20ms |
| Auth middleware (JWT verify + workspace check via Redis `GET`) | 10ms | ~6ms |
| Routing + binding (Gin) | 2ms | <1ms |
| Query (replica, cursor pagination, 20 rows, indexed) | 50ms | ~30ms |
| Assignee batch fetch (one extra query, replaced N+1 in 2026-Q1) | 25ms | ~18ms |
| JSON marshal (20 tasks + pagination, `sync.Pool` buffer) | 15ms | ~10ms |
| Response write + middleware unwind + structured-log emit | 8ms | ~5ms |
| Slack: variance, GC pauses, scheduler jitter | 60ms | — |
| **Sum at p99** | **200ms** | **~90ms** |

The budget is not divided equally. The query stage gets the largest fixed slice
because the `tasks` table is large; marshaling gets a non-trivial slice because the
endpoint returns a list. The 60ms slack is intentional headroom — if every other slice
runs at its ceiling simultaneously, the request still meets the target. When slack
falls below 30ms, the team treats it as a leading indicator that the budget needs to
be revisited rather than waiting for a p99 alert.

### Trade-offs and Constraints  [SENIOR]

Setting the budget at 200ms (rather than the 100ms a public hyperscaler endpoint would
target) reflects Meridian's customer mix: B2B task lists are loaded when a user enters
a workspace, not in a tight loop. Sub-100ms perception gains are small relative to the
engineering cost. The team chose to spend that budget on richer responses (embedded
assignee summaries, recent-activity counts) rather than chasing a tighter number.
Features that would push p99 above 200ms are rejected at design time; features that
fit ship without performance review beyond a load test.

The budget also implies what is **not** measured. Time the React client spends parsing
JSON or rendering the list is the frontend's budget, owned separately. The boundary is
the response write; a backend engineer who optimizes JSON shape to help the frontend is
reaching across a budget line and should coordinate first.

### Related Sections

- [See persistence-strategy → Indexing Strategy on the Tasks Table](./persistence-strategy.md#indexing-strategy-on-the-tasks-table)
  for the index that backs the 50ms query slice.
- [See operational-awareness → Three-Pillar Observability](./operational-awareness.md#three-pillar-observability-logs-metrics-and-traces)
  for the per-stage timing fields that make this budget verifiable at runtime.
- [See api-design → Cursor-Based Pagination on Task Lists](./api-design.md#cursor-based-pagination-on-task-lists)
  for the pagination pattern that keeps the query slice bounded as the table grows.

---

## N+1 on the Task List Assignee Lookup  [MID]

### First-Principles Explanation  [JUNIOR]

An **N+1 query** happens when a request issues one query to fetch N parent rows, then
N additional queries — one per parent — to fetch related rows. Total query count
grows linearly with result-set size; latency becomes dominated by per-query
round-trip cost rather than by the work each query performs.

The fix is almost always to **batch**: replace the N per-parent queries with a single
query that loads related rows for every parent at once, then reassemble the
parent-child relationship in application code. A single round trip is dramatically
cheaper than N round trips against the same database.

### Idiomatic Variation  [MID]

Meridian's `GET /v1/workspaces/{wid}/tasks?limit=20` returned each task with a
flattened `assignee` object (name, avatar, email). The first implementation looked
correct in isolation but issued one user query per task in a serial loop:

```go
// service/task.go — original (N+1)
for _, t := range tasks {
    if t.AssigneeID != nil {
        user, err := s.users.Get(ctx, *t.AssigneeID) // one round trip per task
        if err != nil { return nil, err }
        view.Assignee = &user
    }
    out = append(out, view)
}
```

A unit test against an in-memory mock ran in microseconds. A staging load test with a
200-row response (a workspace's full backlog, before pagination was tightened) showed
p99 at 1.4 seconds — the budget was 250ms at the time. The 1+200 pattern issued 201
serial round trips to the read replica at ~6ms cross-AZ each; nothing overlapped.

The fix replaced the per-task lookup with a single batch query executed after the
list query returns:

```go
// service/task.go — corrected (batched)
ids := uniqueAssigneeIDs(tasks)
users, err := s.users.GetMany(ctx, ids) // SELECT ... WHERE id = ANY($1)
if err != nil { return nil, err }
byID := indexByID(users)
for _, t := range tasks {
    view := TaskView{Task: t}
    if t.AssigneeID != nil {
        if u, ok := byID[*t.AssigneeID]; ok { view.Assignee = &u }
    }
    out = append(out, view)
}
```

Two queries regardless of result-set size. The batch query returns up to N distinct
users (often fewer — one assignee typically owns several tasks). p99 dropped to 95ms
after the change, with remaining latency dominated by the original list query.

### Trade-offs and Constraints  [SENIOR]

The batch fix loads every assignee row even when the calling code may filter them
later. For Meridian's workload, every returned task is rendered with its assignee, so
over-fetching is zero — but the pattern would not scale unchanged to an endpoint
returning 10 000 tasks. Rule: batch loads with bounded fan-in (page size 20–100) are
preferred to serial loops; unbounded fan-in must be paginated or chunked.

A second trade-off: two queries, not one. A SQL `JOIN` between `tasks` and `users`
would return everything in one round trip but duplicates each user row N times. At
Meridian's response sizes, the wasted bandwidth costs more than the second round trip
saves (2–3ms in p99 testing).

Detection: every new endpoint runs through a load test against a synthetic 50-row and
500-row workspace; CI extracts the per-request query count from the structured log
and fails the build above a hand-tuned threshold (`2 + ceil(rows/100)`). The
serial-loop bug above was caught in staging before it reached a paying tenant.

### Related Sections

- [See persistence-strategy → Postgres + Redis Split](./persistence-strategy.md#postgres--redis-split-what-lives-where)
  for the routing rule that sends this list query to the read replica.
- [See architecture → Repository Pattern](./architecture.md#repository-pattern)
  for the `GetMany` method addition that the fix required on the user repository.
- [See concurrency-and-async → Worker Pool for the Deadline-Reminder Job](./concurrency-and-async.md#worker-pool-for-the-deadline-reminder-job)
  for the rejected alternative (parallel goroutines for the per-task lookup), which fixes
  the latency at the cost of pool exhaustion under load.

---

## p50 vs p99: Per-Workspace Latency Histograms  [MID]

### First-Principles Explanation  [JUNIOR]

A single average latency number — "the API responds in 80ms on average" — hides the
distribution. A service whose median is 50ms but whose worst 1% take 4 seconds has
the same average as one whose median is 200ms and whose worst 1% take 250ms. The
first has happy median users and a very unhappy long tail; the second has uniformly
mediocre users. Averages cannot distinguish them.

**Percentiles** describe the distribution by position. p50 (the median) is the
latency that half of requests beat; p99 is the latency that 99% beat. Tracking p50,
p95, and p99 separately shows whether the slow requests are a noisy minority (p50
flat, p99 climbing) or a system-wide regression (all percentiles rising together).

### Idiomatic Variation  [MID]

Meridian instruments every HTTP request with a Prometheus histogram on
`http_request_duration_seconds`, labeled by route and status class. Default buckets
cover 5ms to 10s; the dashboard shows p50, p95, and p99 per route over a rolling
5-minute window.

The non-obvious instrumentation is a **per-workspace dimension** added in 2026-Q2
after a single 200-seat customer's `GET /v1/tasks` started timing out at 5–8 seconds
while the global dashboard showed a healthy 180ms p99. The workspace's traffic was a
small fraction of total volume; its tail did not move the global histogram. Adding a
`workspace_id`-bucketed histogram (off the default dashboard for cardinality reasons;
queryable on demand) showed the tenant's p99 at 6.2 seconds and attributed it to a
specific table-scan query their backlog size had begun to provoke.

```go
// observability/metrics.go — two histograms, same buckets, different label cost
var httpDuration = prometheus.NewHistogramVec(
    prometheus.HistogramOpts{Name: "http_request_duration_seconds", Buckets: prometheus.DefBuckets},
    []string{"route", "status_class"}, // ~80 series total
)
// Flag-gated; only enabled during incident response.
var httpDurationByWorkspace = prometheus.NewHistogramVec(
    prometheus.HistogramOpts{Name: "http_request_duration_by_workspace_seconds", Buckets: prometheus.DefBuckets},
    []string{"route", "workspace_id"}, // ~80 × workspace count
)
```

The per-workspace histogram is gated behind `obs.per_workspace_latency`, off by
default. Enabling during an incident gives an immediate per-tenant breakdown;
disabling after keeps cardinality manageable. Cardinality is paid only when needed.

### Trade-offs and Constraints  [SENIOR]

Percentile histograms carry per-bucket cost multiplied by every label combination.
`route × status_class` produces ~80 series; adding `workspace_id` to the same metric
would produce 80 × 1500 = 120 000 series, beyond the team's Prometheus capacity. The
flag-gated separate metric preserves percentile fidelity for tenant-attributed views
without forcing every series to carry the workspace label.

The accepted trade-off: the per-workspace metric is not always on, so the first 5–10
minutes of a tenant-specific incident lack historical data. A runbook step (enable
the flag, wait two minutes for buckets to fill) precedes the diagnostic query. The
always-on alternative is revisited annually.

A second constraint: Prometheus percentiles are bucket-bounded approximations,
accurate to within the bucket width (~10ms at this range for `DefBuckets`). For
200ms-budget decisions this is within tolerance; sub-millisecond targets would need
custom narrower buckets.

### Related Sections

- [See operational-awareness → Three-Pillar Observability](./operational-awareness.md#three-pillar-observability-logs-metrics-and-traces)
  for the structured-log fields that complement these metrics during incident response.
- [See architecture → Hexagonal Split](./architecture.md#hexagonal-split) for the
  middleware layer where the histogram observation is recorded.

---

## Allocation Discipline: `sync.Pool` for JSON Marshal Buffers  [SENIOR]

### First-Principles Explanation  [JUNIOR]

Go's garbage collector is concurrent but not free. Each allocation costs CPU at
allocation time and adds work to a future GC cycle. In a hot path (executed thousands
of times per second per pod), short-lived allocations accumulate into a steady tax on
tail latency — visible not as spikes but as a uniform offset.

`sync.Pool` is Go's standard mechanism for **reusing** short-lived objects across
requests. A worker takes an object from the pool, uses it, and returns it. The GC may
still reclaim pooled objects under memory pressure, but steady-state behavior is that
the same buffer is reused many times. The pattern fits objects that are large,
frequently allocated, and not shared across goroutine boundaries.

### Idiomatic Variation  [MID]

Meridian uses `sync.Pool` in exactly one place in the codebase: the JSON-marshaling
buffer for the `GET /v1/tasks` response writer. The endpoint serves the highest QPS in
the system; each response allocates a `bytes.Buffer` to assemble the JSON before
flushing to the response writer. Profiling showed those allocations at roughly 4% of
total CPU and a measurable contribution to GC pauses during peak traffic.

```go
// handler/encoding.go — single, well-reviewed pool location
var jsonBufferPool = sync.Pool{
    New: func() any { return bytes.NewBuffer(make([]byte, 0, 8*1024)) }, // pre-size for ~6KB typical
}

func writeJSONList(c *gin.Context, status int, payload any) {
    buf := jsonBufferPool.Get().(*bytes.Buffer)
    buf.Reset()
    defer jsonBufferPool.Put(buf)
    if err := json.NewEncoder(buf).Encode(payload); err != nil {
        c.AbortWithStatus(http.StatusInternalServerError)
        return
    }
    c.Data(status, "application/json", buf.Bytes())
}
```

After the change, the marshaling step's contribution to GC dropped to ~0.6%, and p99
for the endpoint improved by ~7ms — significant against the 15ms marshal slice in the
budget. The pre-sized 8KB backing array fits the 99th-percentile response without
re-growing.

### Trade-offs and Constraints  [SENIOR]

`sync.Pool` is intentionally **not used** in any other endpoint despite similar
allocation shapes elsewhere. The reasons are all thresholds:

1. **Cold paths do not benefit.** An endpoint serving 5 RPS does not allocate enough
   to register in profiling. Rule: if pprof's allocation profile does not show the
   site in the top 50, pooling is premature.
2. **Pool-reuse bugs are subtle.** A pooled value reused without a clean reset leaks
   data across requests — a security finding, not a performance regression. Limiting
   `sync.Pool` to one well-reviewed location keeps the audit surface small.
3. **The endpoint must be confirmed hot.** The team adopted `sync.Pool` here only
   after a four-week observation window confirmed this handler was the top GC
   contributor. Pre-emptive pooling on endpoints that **might** be hot was rejected.

The trade-off accepted: one unusual pattern in the encoding layer that new engineers
must understand. The encoding helper is the only consumer; engineers who do not touch
`encoding.go` never encounter it.

### Related Sections

- [See concurrency-and-async → Goroutine Ownership and the Supervised Reconciler](./concurrency-and-async.md#goroutine-ownership-and-the-supervised-reconciler)
  for the per-request goroutine model that makes `sync.Pool` safe in this layer (no
  buffer crosses request boundaries).
- [See operational-awareness → Three-Pillar Observability](./operational-awareness.md#three-pillar-observability-logs-metrics-and-traces)
  for the GC-pause histogram exposed alongside the latency metric, which signaled when
  this optimization began paying off.

---

## Cache Hit Rate on the Workspace Metadata Lookup  [MID]

### First-Principles Explanation  [JUNIOR]

A **cache** holds a copy of expensive-to-compute data so repeat requests return it
without redoing the work. The headline metric is **hit rate** — the fraction of
requests served from cache. Hit rate is bounded by two forces: the working set's
distribution (if every request asks a different question, no cache helps) and the
invalidation policy (refusing to evict serves stale data; evicting aggressively
lowers hit rate). Neither is solvable by adding more cache capacity.

### Idiomatic Variation  [MID]

Meridian caches **workspace metadata** (name, plan tier, member count, feature flags)
in Redis with a 5-minute TTL. The data is read on nearly every request — auth
middleware needs the plan tier — and changes rarely. After three months in production,
the steady-state hit rate is **89%**, not the 99% the team initially expected. The
gap is informative.

The 11% miss rate decomposes:
- **TTL expiry (~7%).** Every 5 minutes, every cached entry expires and re-warms.
- **Cold pod startup (~2%).** New pods from K8s autoscaling start with empty local
  routing; misses concentrate in the first 60 seconds of new pod life.
- **Long-tail workspaces (~2%).** Workspaces with one request per hour never hit a
  warm cache — the TTL has always expired between visits.

The team did not increase TTL to 1 hour to chase a higher number. The 5-minute window
matches the longest delay an admin will tolerate when changing a feature flag;
extending TTL would shift the cost from "extra Postgres read" to "users report stale
flag for an hour" — a worse trade.

```go
// repository/workspace.go — read-through cache, best-effort writes
func (r *postgresWorkspaceRepository) GetMetadata(ctx context.Context, id uuid.UUID) (domain.WorkspaceMetadata, error) {
    cacheKey := "ws:meta:" + id.String()
    if cached, err := r.redis.Get(ctx, cacheKey).Bytes(); err == nil {
        var meta domain.WorkspaceMetadata
        if err := json.Unmarshal(cached, &meta); err == nil {
            return meta, nil
        }
        // Decode failure on cached bytes is logged and treated as a miss.
    }
    meta, err := r.loadMetadataFromDB(ctx, id)
    if err != nil { return domain.WorkspaceMetadata{}, err }
    if encoded, err := json.Marshal(meta); err == nil {
        _ = r.redis.Set(ctx, cacheKey, encoded, 5*time.Minute).Err() // best-effort
    }
    return meta, nil
}
```

Targeted invalidation on writes (`DEL ws:meta:{id}` after any metadata update) reduces
the staleness window for known mutations to one cache miss but does nothing for the
TTL-driven majority. Most misses are simply the cache doing its job at the size it was
configured for.

### Trade-offs and Constraints  [SENIOR]

The team **does not cache** several read paths that look like good candidates:

- **Task list responses.** The key would have to encode workspace_id, cursor, filters,
  and per-user permission scope. Personalized responses produce a sparse key space —
  most slots would be hit at most once before expiring. The list query is fast enough
  against the indexed table that the caching cost exceeds the benefit.
- **Individual task fetches.** Tasks change often during a sprint; invalidation on
  every write would dominate the savings on reads. Hit rate would be high but overall
  load would not decrease.

The criterion before adding a cache: reads must be at least 10× more frequent than
writes, the response must not be personalized in a way that explodes the key space,
and the staleness window must be acceptable to the product owner. Workspace metadata
satisfies all three; task content satisfies none.

A second non-default choice: the cache is **read-through**, not write-through. On a
write, the application invalidates (`DEL`) the key rather than writing the new value
into Redis. Write-through introduces a new failure mode (Postgres succeeds, Redis
fails — what now?). Read-through with invalidation accepts one slow read after each
write rather than answering that question. The benefit: no two-store consistency
reasoning in the write path.

### Related Sections

- [See persistence-strategy → Postgres + Redis Split](./persistence-strategy.md#postgres--redis-split-what-lives-where)
  for the rule governing which state may live in Redis at all.
- [See operational-awareness → Three-Pillar Observability](./operational-awareness.md#three-pillar-observability-logs-metrics-and-traces)
  for the cache hit/miss counter exposed alongside the metadata read latency.

---

## Prior Understanding: Optimize SQL by Intuition  [MID]

### Prior Understanding (revised 2025-11-12)

The original guidance for SQL performance work was:

> "If the query feels slow, rewrite it. Common rewrites: change `IN (...)` to
> `EXISTS`, add an index on the WHERE column, replace OR clauses with a UNION."

This was revised because intuition-driven rewrites repeatedly produced regressions.
A 2025-11 incident: an engineer replaced an `IN` subquery with `EXISTS` per the rule
above. The planner had been using a hash semi-join on the original; the rewrite
forced a nested-loop join because the selectivity estimate changed. p99 regressed
from 70ms to 1.1 seconds. The fix was to revert.

**Corrected understanding:**

The rule is now **always EXPLAIN before changing the query, and always EXPLAIN ANALYZE
on production-shaped data after**. The planner's chosen execution path is the answer;
intuition about which SQL form is faster is not. Specifically:

1. **Capture the current plan** with `EXPLAIN (ANALYZE, BUFFERS)` against a snapshot
   that mirrors production row counts and statistics. A 1000-row local database does
   not predict plans against a 50-million-row table.
2. **Identify the cost driver.** A node with high `actual time` or high `loops` is
   the optimization target. A low-cost node high in the plan tree is not.
3. **Make one change** to query or schema, then re-EXPLAIN. Multiple simultaneous
   changes hide which one helped.
4. **Re-measure on production-shaped data** before merging.

The original rewrites are sometimes correct but they are tactics, not rules. The
planner decides the execution path; the engineer's job is to give it enough
information to choose well, then verify with EXPLAIN.

### Related Sections

- [See persistence-strategy → Indexing Strategy on the Tasks Table](./persistence-strategy.md#indexing-strategy-on-the-tasks-table)
  for the EXPLAIN-driven process used to decide which indexes ship.
- [See review-taste → The 2000-Line Refactoring PR](./review-taste.md#the-2000-line-refactoring-pr)
  for the code-reviewer rule that requires EXPLAIN output in the PR description for any
  query change on the `tasks` or `task_assignments` tables.

---

## Coach Illustration (default vs. hints)

> **Illustrative only.** A worked example of how the two coaching styles differ. Not
> part of the live agent contract. Actual behavior is governed by the style files at
> `.claude/skills/learn/coach-styles/`.

**Scenario:** A learner reports that `GET /v1/workspaces/{wid}/tasks` is showing p99
latency at 850ms in staging — well above Meridian's 200ms budget — and asks the agent
to investigate and fix the regression.

**`default` style** — The agent walks through the budget decomposition, requests the
slow-query log and `pgxpool` stats, identifies a newly reintroduced N+1 in the
assignee lookup, implements the batch fix (one `GetMany` call), updates the load-test
query-count threshold, and runs the test to confirm the regression is gone. It
appends `## Learning:` trailers explaining the latency budget framework, N+1
detection, and the batch-fix pattern.

**`hints` style** — The agent identifies the budget slice that grew (assignee lookup),
names the pattern (N+1 query), and writes a service-method scaffold with a comment
marking where the batched lookup belongs. It then emits:

```
## Coach: hint
Step: Replace the per-task assignee lookup in TaskService.ListWithAssignees with a
single batched query.
Pattern: N+1 query → batch SELECT (collect distinct IDs, one query, index by ID).
Rationale: With limit=20, the current code issues 21 serial round trips; cross-AZ
round trips dominate latency. SELECT ... WHERE id = ANY($1) replaces 20 trips with
one. EXPLAIN the batch query against production-shaped data before merging.
```

`<!-- coach:hints stop -->`

The learner writes the `GetMany` call, the deduplication helper, and the index-by-ID
loop. On the next turn, the agent responds to follow-up questions (assignees deleted
between the list query and the batch fetch, for example) without rewriting the
scaffold.
