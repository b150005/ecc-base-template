---
domain: concurrency-and-async
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: implementer
contributing-agents: [implementer]
---

> **Read-only reference.** This file is shipped with the ECC Base Template as a worked
> example to illustrate what a populated knowledge file looks like after many sessions on
> a real project. It is **not** your knowledge file. Your own knowledge file lives at
> `learn/knowledge/concurrency-and-async.md` and starts empty until agents enrich it during
> real work. Agents never read, cite, or write under `docs/en/learn/examples/` — this
> tree is for human readers only. See
> [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md) for the design rationale.

---

## How to Read This File

Level markers indicate the intended audience for each section:
- `[JUNIOR]` — first-principles explanation; assumes no prior exposure
- `[MID]` — non-obvious idiomatic application in this stack
- `[SENIOR]` — non-default trade-off evaluation; names what is given up

---

## Notification Fanout: Single Goroutine vs. Fan-Out Pattern  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

When a task changes in Meridian, three downstream systems must be notified: Slack,
email, and the in-app feed. The naive approach calls each sequentially — if each takes
100ms the total added latency is 300ms, charged to the user's task update. A **fan-out
pattern** dispatches all three concurrently so the slowest one, not the sum, determines
the overhead:

```
task changed ──┬── notify Slack  ─┐
               ├── notify email  ─┤── all three complete → return
               └── notify in-app ─┘
```

The cost is error semantics. Sequential calls surface a clear failure at the exact step
that failed. Concurrent fan-out delivers partial results — two channels may succeed while
one fails — and the caller must decide what that means.

### Idiomatic Variation  [MID]

Meridian uses `errgroup` from `golang.org/x/sync` to manage the fan-out:

```go
// service/notification.go
func (s *slackEmailInAppNotifier) NotifyTaskAssigned(
    ctx context.Context, task domain.Task, assignee domain.User,
) error {
    g, ctx := errgroup.WithContext(ctx)
    g.Go(func() error { return s.slack.SendTaskAssigned(ctx, task, assignee) })
    g.Go(func() error { return s.email.SendTaskAssigned(ctx, task, assignee) })
    g.Go(func() error { return s.inApp.RecordTaskAssigned(ctx, task, assignee) })
    return g.Wait()
}
```

`errgroup.WithContext` creates a derived context cancelled on the first error.
`g.Wait()` blocks until all goroutines exit — no goroutine outlives the function, which
eliminates the goroutine-leak risk of fire-and-forget fan-out.

The caller in `service/task.go` treats notification errors as non-fatal — a failed
notification does not fail the task assignment, it is logged and the operation returns
success. See [architecture → Cross-Cutting Concern: Notifications](./architecture.md#cross-cutting-concern-notifications)
for the product rationale.

### Trade-offs and Constraints  [SENIOR]

`errgroup` discards all but the first error. If Slack and email both fail, the caller
sees only the Slack error. For Meridian's best-effort notification semantics this is
acceptable; if the product required "retry only failed channels," the return type would
need to be a per-channel result slice, not a single `error`.

A second cost: all goroutines share the same context deadline. To prevent a slow Slack
call from cancelling the in-app write, Meridian gives each channel its own
`context.WithTimeout` inside its `g.Go` body, derived from the parent context. Ordering
is not preserved — dispatch order is determined by the scheduler. This is acceptable for
notifications but would not be acceptable for an ordered event log.

### Related Sections

- [See error-handling → Idempotent Retry on the Slack Webhook](./error-handling.md#idempotent-retry-on-the-slack-webhook)
  for deduplication when a retry follows a partial fanout.
- [See architecture → Cross-Cutting Concern: Notifications](./architecture.md#cross-cutting-concern-notifications)
  for the deferred-async upgrade path when fanout latency becomes a forcing function.

---

## Context Propagation: Request to Repository  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

Every HTTP request has a lifecycle. Work triggered by that request — database queries,
external API calls, spawned goroutines — should respect it. If the client disconnects,
the server should stop doing work on its behalf rather than hold resources until
completion.

`context.Context` is Go's cancellation carrier. Passing the request context through
every function call in the chain means that a Postgres query passed a cancelled context
aborts immediately, releasing its connection to the pool. The discipline is
**propagation**: the context created at the request boundary travels unchanged to every
downstream call unless a specific sub-timeout is warranted.

### Idiomatic Variation  [MID]

In Meridian's Gin stack the context originates at the handler and flows unmodified
through the service to the repository:

```go
// handler/task.go
ctx := c.Request.Context()
task, err := h.svc.UpdateTask(ctx, taskID, params)
```

```go
// service/task.go
func (s *TaskService) UpdateTask(ctx context.Context, ...) (domain.Task, error) {
    task, err := s.tasks.Update(ctx, id, params) // ctx → Postgres
    if err != nil { return domain.Task{}, err }
    s.notify.NotifyTaskUpdated(ctx, task)         // ctx → fanout goroutines
    return task, nil
}
```

```go
// repository/task.go
err := r.db.QueryRowContext(ctx, `UPDATE tasks SET ...`, ...).Scan(...)
```

If the client disconnects, the Postgres driver sees `ctx.Done()` closed and aborts the
in-flight query. The connection is returned to the pool without waiting for completion.

### Trade-offs and Constraints  [SENIOR]

Strict propagation bounds all downstream operations to the request timeout (30 seconds
in Meridian's Gin default). This is usually correct. The exception: work that must
outlive the request. Meridian's background reconciler uses `context.Background()`
explicitly — it runs for the process lifetime, not per-request.

The diagnostic rule: if a function creates `context.Background()` mid-request to escape
a cancellation, the work belongs in a background worker, not in the request path. That
judgment is the primary boundary between request-scoped and process-scoped goroutines.

Per-channel notification timeouts are a middle case — each `g.Go` body uses
`context.WithTimeout(ctx, 3*time.Second)` to cap a single channel without affecting the
others, while still being cancelled early if the parent request context is cancelled.

### Related Sections

- [See error-handling → Panic Usage Policy](./error-handling.md#panic-usage-policy)
  for the startup initialization that establishes the `context.Background()` the
  reconciler runs under for its process lifetime.

---

## Goroutine Ownership and the Supervised Reconciler  [MID]

### First-Principles Explanation  [JUNIOR]

A goroutine launched without an explicit join is "fire-and-forget." In production it
is a liability: panics are unrecoverable in the launching scope, leaks accumulate
per-request, and writes to a closed channel crash the process. The principle **"every
goroutine has an owner"** means that exactly one scope is responsible for waiting until
a goroutine exits and handling whatever it produces.

### Idiomatic Variation  [MID]

Meridian enforces this with a codebase convention: every `go func()` call must appear
inside `errgroup.Go` or adjacent to a `wg.Add(1)` call. The code-reviewer agent treats
an uncounted goroutine as a HIGH finding.

The background deadline reconciler is the sole permitted exception — it runs for the
process lifetime. Instead of being joined by a calling function, it is supervised by the
OS signal handler:

```go
// cmd/server/main.go
ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
defer stop()

go reconciler.Run(ctx) // ctx cancelled on SIGINT/SIGTERM

srv.ListenAndServe()   // blocks until shutdown
// after return: ctx is cancelled; reconciler drains and exits within grace period
```

The reconciler owns its context; the OS signal owns the context's cancellation. The
process exits only after `ListenAndServe` returns and the grace-period timeout elapses.

### Trade-offs and Constraints  [SENIOR]

The policy prevents goroutine leaks but pushes long-running work to startup registration.
Goroutines cannot be spawned ad-hoc inside a handler and left to run after the response
is sent. What is given up: the convenience of fire-and-forget for "best-effort" background
tasks. Meridian handles async logging by buffering in the logger implementation — the
handler writes to a buffer synchronously; a single registered background goroutine flushes
it. The handler never spawns the flusher; only `main.go` does.

---

## Worker Pool for the Deadline-Reminder Job  [MID]

### First-Principles Explanation  [JUNIOR]

Meridian's deadline-reminder job runs every five minutes, querying the ~50M-row tasks
table for records with deadlines in the next 24 hours. The result set may be tens of
thousands of tasks. Sending notifications sequentially would take minutes; spawning an
unbounded goroutine per task would saturate the Slack API rate limit and exhaust the
Postgres connection pool.

A **bounded worker pool** constrains parallelism to a fixed number of goroutines. When
all slots are occupied, the producer blocks — this is backpressure. The pool size is
tunable and bounded by external constraints (connection pool size, downstream API limits).

### Idiomatic Variation  [MID]

Meridian uses a buffered channel as a semaphore:

```go
// background/deadline_reconciler.go
const workerPoolSize = 20

func (r *DeadlineReconciler) runRound(ctx context.Context) {
    tasks, _ := r.repo.ListDueSoon(ctx, 24*time.Hour)

    sem := make(chan struct{}, workerPoolSize)
    var wg sync.WaitGroup

    for _, task := range tasks {
        select {
        case sem <- struct{}{}: // acquire; blocks when 20 workers are active
        case <-ctx.Done():
            break
        }
        wg.Add(1)
        go func(t domain.Task) {
            defer wg.Done()
            defer func() { <-sem }()           // release on exit
            notifyCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
            defer cancel()
            if err := r.notifier.NotifyDeadlineMissed(notifyCtx, t); err != nil {
                r.log.Warn("deadline notification failed", "task_id", t.ID, "err", err)
            }
        }(task)
    }
    wg.Wait() // join all before returning
}
```

The `select` with `ctx.Done()` ensures the enqueue loop exits immediately on shutdown.
`wg.Wait()` drains already-dispatched goroutines before `runRound` returns.

### Trade-offs and Constraints  [SENIOR]

Pool size 20 was calibrated against the Postgres connection pool cap (25 connections).
With 20 concurrent workers each potentially holding a connection, the pool retains small
headroom. Raising to 50 would exhaust connections under a full round, triggering retries
that lengthen total duration — the opposite of the goal.

What is given up: `errgroup` with a semaphore would collect errors into one return value,
but notification errors are non-fatal by policy — logging is the correct response, not
propagation. A channel-based work queue with dedicated receiver goroutines is clearer but
adds significant boilerplate. The semaphore pattern is idiomatic enough in Go that the
team accepted its terseness.

For graceful shutdown: `select <-ctx.Done()` exits the enqueue loop; `wg.Wait()` drains
dispatched workers; a `context.WithTimeout` in `main.go`'s shutdown sequence caps how
long the drain can take before the process is killed.

### Related Sections

- [See operational-awareness → Three-Pillar Observability](./operational-awareness.md#three-pillar-observability-logs-metrics-and-traces)
  for how per-task notification failures appear in structured logs without alert noise.

---

## Corrected: Global Goroutine Pool Shared Across All Notification Types  [MID]

> Superseded 2026-01-14: The original notification service used a single global bounded
> pool shared across all workload types and all tenants. Production metrics showed
> cross-tenant interference: a high-volume tenant's deadline-reminder round occupied all
> 50 slots and delayed time-sensitive task-assignment notifications for other tenants.
> The shared-pool design was incorrect for a multi-tenant system with mixed workload
> latency requirements.

> Original implementation (incorrect):
> ```go
> // service/notification.go — original
> var globalPool = make(chan struct{}, 50)
>
> func dispatchNotification(ctx context.Context, fn func()) {
>     globalPool <- struct{}{}
>     go func() { defer func() { <-globalPool }(); fn() }()
> }
> ```
> All notification types competed for the same 50 slots.

**Corrected understanding:**

The correction introduced **per-bounded-context pools** — a separate semaphore per
logical workload type, sized to its concurrency and latency requirements:

| Pool | Size | Rationale |
|------|------|-----------|
| Notification fanout | 3 | One slot per channel (Slack, email, in-app) |
| Deadline reconciler | 20 | High throughput per round; bounded by connection pool |
| Webhook ingest | 10 | Burst handling; capped below Slack API rate limit |

A deadline-reminder round that occupies all 20 reconciler slots has no effect on
real-time fanout, which has 3 independent slots. The cross-tenant interference
disappeared in the production latency metrics after this change.

The cost: each pool size is a tunable constant with its own rationale. Adding a new
workload type requires a deliberate sizing decision rather than inheriting a shared
default.

### Related Sections

- [See concurrency-and-async → Worker Pool for the Deadline-Reminder Job](#worker-pool-for-the-deadline-reminder-job)
  for the current reconciler pool implementation.

---

## Coach Illustration (default vs. hints)

> **Illustrative only.** The following is a worked example of how the two coaching styles
> differ for a task in this domain. It is not part of the live agent contract. Actual
> agent behavior is governed by the style files at
> `.claude/skills/learn/coach-styles/`.

**Scenario:** A learner asks the agent to implement notification fanout for Meridian's
task-assignment event, dispatching to Slack, email, and in-app concurrently.

**`default` style** — The agent produces the complete `NotifyTaskAssigned` implementation:
`errgroup.WithContext` fan-out, per-channel `context.WithTimeout` sub-contexts, the
error-log-not-propagate call site in `TaskService.AssignTask`, and a table-driven unit
test covering the partial-failure case. `## Learning:` trailers explain `errgroup`
ownership semantics and the best-effort error policy.

**`hints` style** — The agent writes the function signature and `g, ctx := errgroup.WithContext(ctx)`,
leaving the three `g.Go(...)` bodies empty. It emits:

```
## Coach: hint
Step: Add three g.Go blocks — one per channel (Slack, email, in-app).
Pattern: errgroup fan-out; all three run concurrently, g.Wait() joins them.
Rationale: errgroup.WithContext cancels sibling goroutines on first error and
guarantees no goroutine outlives the function, preventing leaks.
```

`<!-- coach:hints stop -->`

The learner fills in the `g.Go` bodies. On the next turn the agent reviews and adds
per-channel timeout sub-contexts if absent.
