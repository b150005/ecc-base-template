---
domain: error-handling
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: implementer
contributing-agents: [implementer, code-reviewer]
---

> **Read-only reference.** This file is shipped with the ECC Base Template as a worked
> example to illustrate what a populated knowledge file looks like after many sessions on
> a real project. It is **not** your knowledge file. Your own knowledge file lives at
> `learn/knowledge/error-handling.md` and starts empty until agents enrich it during real
> work. Agents never read, cite, or write under `docs/en/learn/examples/` — this tree
> is for human readers only. See [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md)
> for the design rationale.

---

## How to Read This File

Level markers indicate the intended audience for each section:
- `[JUNIOR]` — first-principles explanation; assumes no prior exposure
- `[MID]` — non-obvious idiomatic application in this stack
- `[SENIOR]` — non-default trade-off evaluation; names what is given up

---

## Domain Error Type Hierarchy  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

An application encounters many kinds of errors: a user submits a form with an invalid
email address; a database query returns no rows; an external API times out; a code path
that should never be reached is reached. Each of these errors has a different cause, a
different audience (user vs. operator), and a different appropriate response (prompt the
user to fix their input; return 404; retry; page an engineer). Treating them all
identically — logging everything as a 500, or returning the raw error string to the user
— is a security and usability failure.

A **domain error type hierarchy** assigns every error to a category with named semantics.
The category determines:
1. What HTTP status code the API returns.
2. What message (if any) is shown to the user.
3. What context is written to the structured log.
4. Whether the operation should be retried automatically.

In Go, the idiomatic approach is to define error types that implement the `error` interface
and can be detected with `errors.As`. Unlike error codes (which are stringly-typed and
fragile), typed errors are checked by the compiler: if a handler references a type that
does not exist, the build fails.

### Idiomatic Variation  [MID]

Meridian defines three top-level error categories in `domain/errors.go`:

```go
// domain/errors.go

// NotFoundError is returned when a requested resource does not exist.
type NotFoundError struct {
    Resource string
    ID       string
}

func (e *NotFoundError) Error() string {
    return fmt.Sprintf("%s with id %s not found", e.Resource, e.ID)
}

func (e *NotFoundError) HTTPStatus() int { return http.StatusNotFound }
func (e *NotFoundError) Title() string   { return "Not Found" }
func (e *NotFoundError) Type() string    { return "not-found" }
func (e *NotFoundError) Detail() string  { return e.Error() }

// ValidationError is returned when input fails business-rule validation.
// (Distinct from binding errors, which are handler-layer concerns.)
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation error on field %s: %s", e.Field, e.Message)
}
func (e *ValidationError) HTTPStatus() int { return http.StatusUnprocessableEntity }
func (e *ValidationError) Title() string   { return "Validation Error" }
func (e *ValidationError) Type() string    { return "validation-error" }
func (e *ValidationError) Detail() string  { return e.Message }

// AuthorizationError is returned when the caller lacks permission.
type AuthorizationError struct {
    Action   string
    Resource string
}

func (e *AuthorizationError) Error() string {
    return fmt.Sprintf("not authorized to %s %s", e.Action, e.Resource)
}
func (e *AuthorizationError) HTTPStatus() int { return http.StatusForbidden }
func (e *AuthorizationError) Title() string   { return "Forbidden" }
func (e *AuthorizationError) Type() string    { return "authorization-error" }
func (e *AuthorizationError) Detail() string  {
    // Safe to surface: no internal details exposed
    return fmt.Sprintf("You are not authorized to %s this %s.", e.Action, e.Resource)
}
```

The `Error` interface for the handler translation layer:

```go
// domain/errors.go (continued)
type Error interface {
    error
    HTTPStatus() int
    Title() string
    Type() string
    Detail() string
}

// Sentinel for quick equality checks
var ErrNotFound = &NotFoundError{}
```

The handler's `writeError` calls `errors.As(err, &domainErr)` to check whether the error
is a `domain.Error`. If it is, it uses the error's own methods to construct the RFC 9457
response. If it is not (an unrecognized error from a library or an unexpected condition),
it returns a 500 and logs the full error with context.

### Trade-offs and Constraints  [SENIOR]

A typed error hierarchy requires discipline at every layer to propagate errors correctly.
When a repository method encounters a Postgres constraint violation, it must translate
that violation into a `ValidationError` or a `NotFoundError` before returning it — not
return the raw `pq.Error`. If a Postgres-specific error leaks past the repository
boundary, the handler must either recognize it (coupling the handler to the database
client library) or treat it as a 500 (silently swallowing the real error category).

The enforcement mechanism in Meridian is code review: any repository method that returns
an error must return a domain error type. The code-reviewer agent flags raw `pq.Error`
returns as CRITICAL findings. This is a cultural enforcement, not a compiler enforcement
— Go does not have checked exceptions. The alternative (a linter rule) was considered but
not implemented; the pattern is simple enough that manual review is sufficient at current
team size.

### Example (Meridian)

Usage in a service method:

```go
// service/task.go
func (s *TaskService) GetTask(ctx context.Context, id uuid.UUID, callerID uuid.UUID) (domain.Task, error) {
    task, err := s.tasks.Get(ctx, id)
    if err != nil {
        return domain.Task{}, err // NotFoundError from repository, propagated as-is
    }
    if task.WorkspaceID != s.getMemberWorkspace(callerID) {
        return domain.Task{}, &domain.AuthorizationError{Action: "read", Resource: "task"}
    }
    return task, nil
}
```

### Related Sections

- [See api-design → Error Envelope: RFC 9457](./api-design.md#error-envelope-rfc-9457)
  for how these domain errors are translated to HTTP responses.
- [See architecture → Hexagonal Split](./architecture.md#hexagonal-split) for the layer
  structure that determines where each error type is created vs. translated.

### Coach Illustration (default vs. hints)

> **Illustrative only.** Not part of the live agent contract. Governed by
> `.claude/skills/learn/coach-styles/`.

**Scenario:** A learner is adding a "duplicate task title" check to `TaskService.CreateTask`
and asks how to return an appropriate error.

**`default` style** — The agent adds the duplicate check, creates a `ConflictError` type
in `domain/errors.go`, returns it from the service, adds it to the `writeError`
translation table (HTTP 409), writes the test, and appends `## Learning:` trailers on
typed errors vs. error codes.

**`hints` style** — The agent names the type to define (`ConflictError` implementing
`domain.Error`), names the HTTP status (409 Conflict), and emits a hint about the
translation in `writeError`. The learner defines the type and wires the HTTP translation.

---

## Boundary Translation: Postgres to Domain Errors  [MID]

### First-Principles Explanation  [JUNIOR]

The persistence layer (repository) speaks Postgres. The service layer speaks domain types.
When a Postgres query fails, the repository receives a Postgres error — a `*pq.Error` with
a five-character SQLSTATE code and a Postgres-specific message. If the repository returns
that error as-is, the service must know about Postgres to interpret it. That coupling
defeats the purpose of the repository pattern: the service should be ignorant of the
underlying database.

**Boundary translation** means the repository intercepts every Postgres error, classifies
it, and returns the appropriate domain error type. The service receives only domain types
and can handle them without knowing what database engine is behind the repository.

### Idiomatic Variation  [MID]

Meridian's repository layer translates Postgres errors using a helper function:

```go
// repository/errors.go
import "github.com/lib/pq"

func translatePostgresError(err error) error {
    if err == nil {
        return nil
    }
    if errors.Is(err, sql.ErrNoRows) {
        return domain.ErrNotFound
    }
    var pgErr *pq.Error
    if errors.As(err, &pgErr) {
        switch pgErr.Code {
        case "23505": // unique_violation
            return &domain.ConflictError{
                Field:   pgErr.Constraint,
                Message: "a resource with this value already exists",
            }
        case "23503": // foreign_key_violation
            return &domain.ValidationError{
                Field:   pgErr.Constraint,
                Message: "the referenced resource does not exist",
            }
        case "23514": // check_violation
            return &domain.ValidationError{
                Field:   pgErr.Constraint,
                Message: "the value violates a database constraint",
            }
        }
    }
    return err // unknown error; propagate as-is for 500 treatment
}
```

Every repository method wraps its error return with `translatePostgresError(err)`.
The Postgres client library never appears outside the `repository` package.

### Trade-offs and Constraints  [SENIOR]

The translation table covers the most common SQLSTATE codes. When a new migration adds
a constraint that can be violated by business logic, the translation table must be
updated. If it is not updated, the constraint violation propagates as an unknown error
and the caller receives a 500 instead of a 409 or 422.

Meridian's process: when a migration adds a new constraint that is reachable by
application code (not just by direct DB writes), the PR must include a corresponding
update to `translatePostgresError`. This is documented in the contributing guide but is
not automatically enforced. The code-reviewer agent checks for new migrations that
introduce constraints and flags the absence of a translation update as HIGH.

### Example (Meridian)

```go
// repository/task.go
func (r *postgresTaskRepository) Create(ctx context.Context, params domain.CreateTaskParams) (domain.Task, error) {
    var t domain.Task
    err := r.db.QueryRowContext(ctx, `
        INSERT INTO tasks (workspace_id, title, assignee_id, status)
        VALUES ($1, $2, $3, 'active')
        RETURNING id, workspace_id, title, assignee_id, status, created_at
    `, params.WorkspaceID, params.Title, params.AssigneeID).
        Scan(&t.ID, &t.WorkspaceID, &t.Title, &t.AssigneeID, &t.Status, &t.CreatedAt)

    return t, translatePostgresError(err)
}
```

### Related Sections

- [See persistence-strategy → Indexing Strategy on the Tasks Table](./persistence-strategy.md#indexing-strategy-on-the-tasks-table)
  for the unique constraints that produce the `23505` code this translation handles.
- [See testing-discipline → The Meridian Test Pyramid](./testing-discipline.md#the-meridian-test-pyramid)
  for why this translation is tested at the integration level, not the unit level.

---

## Idempotent Retry on the Slack Webhook  [MID]

### First-Principles Explanation  [JUNIOR]

When an operation fails partway through, the caller may retry it. If the operation has
side effects (writing to a database, sending a message to Slack), retrying may produce
duplicate side effects. Idempotency prevents this: an operation is idempotent if running
it multiple times has the same effect as running it once.

For Meridian's Slack webhook endpoint, the challenge is that Slack's delivery guarantee is
at-least-once: the same event can arrive multiple times if Slack's delivery confirmation
times out. Meridian must process each logical event exactly once regardless of how many
HTTP requests carry it.

### Idiomatic Variation  [MID]

The idempotency mechanism uses Redis as a deduplication store. When the Slack event
arrives, the handler checks whether the event's ID has been seen before. If it has, the
handler returns 200 immediately without processing. If it has not, the handler records
the ID in Redis (with a 24-hour TTL), then processes the event.

```go
// service/idempotency.go
type IdempotencyService struct {
    redis *redis.Client
}

func (s *IdempotencyService) CheckAndRecord(ctx context.Context, key string, ttl time.Duration) (alreadySeen bool, err error) {
    // SET NX (only set if key does not exist) — atomic check-and-set
    set, err := s.redis.SetNX(ctx, "idempotency:"+key, "1", ttl).Result()
    if err != nil {
        return false, fmt.Errorf("idempotency check failed: %w", err)
    }
    // set=true means the key was just written (first time seen)
    // set=false means the key already existed (already processed)
    return !set, nil
}
```

The `SET NX` (set if not exists) Redis command is atomic. There is no window between
"check" and "set" where a concurrent request could slip through.

### Trade-offs and Constraints  [SENIOR]

The Redis `SET NX` approach records the key before processing completes. If processing
fails after the key is recorded (a Postgres write fails, a downstream service is
unavailable), the key is still in Redis and the event will not be retried on the next
Slack delivery. This is a "mark before process" semantics, which favors exactly-once
delivery over guaranteed delivery.

The alternative is "mark after process" semantics: record the key only after processing
succeeds. If processing fails, the key is not recorded and the next retry will process
the event again. This guarantees delivery but risks duplicate processing if the
"mark after" step itself fails (Postgres write succeeds, Redis write fails — event is
processed but not recorded, so the next Slack retry processes it again).

Meridian chose "mark before" because the notification events are idempotent at the
business level: notifying a Slack channel twice about the same task assignment is a
nuisance, not a data integrity issue. If the events were financial transactions, the
trade-off would be evaluated differently — "mark after" with a distributed transaction
or a two-phase commit would be warranted.

### Example (Meridian)

The full handler flow is shown in
[api-design → Idempotency Key Handling](./api-design.md#idempotency-key-handling). The
`CheckAndRecord` function above is the implementation backing that handler.

### Related Sections

- [See api-design → Idempotency Key Handling](./api-design.md#idempotency-key-handling)
  for the HTTP handler that calls this idempotency service.
- [See testing-discipline → Contract Testing the Slack Integration](./testing-discipline.md#contract-testing-the-slack-integration)
  for how the deduplication behavior is verified in tests.

---

## Panic Usage Policy  [SENIOR]

### First-Principles Explanation  [JUNIOR]

In Go, `panic` is a mechanism to halt the current goroutine immediately, unwind the
stack, and run any registered `defer` functions before the goroutine exits. It is the
Go equivalent of an unhandled exception in other languages. Unlike explicit error returns,
`panic` bypasses the normal error propagation chain.

Using `panic` for ordinary error conditions (database errors, validation failures, network
timeouts) is an anti-pattern. It makes error flow unpredictable, bypasses error logging,
and can crash the entire process if not recovered. Go's error-return convention exists
precisely to make error flow explicit and local.

### Idiomatic Variation  [MID]

Meridian uses `panic` only for **true invariant violations** — conditions that indicate
a programming error that cannot be recovered at runtime and should not be silently
swallowed:

1. **Initialization failures** — if a required dependency (database connection, Redis
   client, configuration value) cannot be set up at startup, the process panics.
   Starting without a database connection in a database-backed service is incoherent;
   the process should not attempt to serve requests.

2. **Impossible type assertions in internal code** — if code that is provably correct
   under the current type system requires a type assertion that the compiler cannot
   verify, and the assertion failing would indicate that a contract was violated
   elsewhere in the codebase. These assertions are guarded with a comment explaining
   why the assertion cannot fail in correct code.

All other errors use explicit `error` returns. The handler's `writeError` recovers from
panics via Gin's recovery middleware and returns a 500, but this recovery is a safety
net, not a design strategy.

### Trade-offs and Constraints  [SENIOR]

The "panic only for invariants" policy requires that every external dependency be
verified at initialization time, which increases startup complexity. Meridian's `main.go`
has an explicit startup sequence that checks each dependency and panics on failure with a
clear error message. The consequence is fast-fail: a misconfigured deployment panics on
boot rather than serving some requests normally and failing others opaquely at runtime.

The cost: if a dependency (Redis, for example) becomes unavailable after startup,
subsequent calls return errors rather than panicking. This is correct behavior — Redis
unavailability is a runtime condition, not a startup invariant. The distinction is:
"Redis is unreachable at boot" (invariant — the service should not start) vs. "Redis
returned a timeout on this request" (runtime error — the caller should receive an error
response).

### Example (Meridian)

```go
// cmd/server/main.go
func main() {
    db, err := sql.Open("postgres", os.Getenv("DATABASE_URL"))
    if err != nil {
        panic(fmt.Sprintf("failed to open database: %v", err))
    }
    if err := db.PingContext(context.Background()); err != nil {
        panic(fmt.Sprintf("database not reachable at startup: %v", err))
    }
    // ... continue wiring
}
```

The `panic` message includes the error and context so that the deployment logs show
exactly what was misconfigured. A panic at startup writes a stack trace that points
directly to `main.go`; it is easy to distinguish from a runtime panic in a goroutine.

### Related Sections

- [See architecture → Hexagonal Split](./architecture.md#hexagonal-split) for the
  initialization wiring that these startup panics guard.
- [See operational-awareness → Three-Pillar Observability](./operational-awareness.md#three-pillar-observability-logs-metrics-and-traces)
  for how startup panics appear in structured logs.

---

## Corrected: Wrap Everything as 500  [JUNIOR]

> Superseded 2025-10-18: The original error handling strategy returned HTTP 500 for all
> errors regardless of their type, including not-found conditions and validation failures.
> This was incorrect because it deprived clients of actionable status codes and caused
> legitimate "task not found" conditions to appear as server errors in monitoring dashboards.

> Original implementation (incorrect):
> ```go
> // handler/task.go — original
> func (h *TaskHandler) GetTask(c *gin.Context) {
>     task, err := h.svc.GetTask(c.Request.Context(), id, callerID)
>     if err != nil {
>         c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
>         return
>     }
>     c.JSON(http.StatusOK, task)
> }
> ```

**Corrected understanding:**

HTTP status codes are the API's primary error-classification signal. A client must be
able to distinguish "this task does not exist" (404, user error, the client should update
its local state) from "the server had an unexpected failure" (500, system error, the
client should retry or alert). Returning 500 for everything collapses this distinction.

The corrected approach — the typed domain error hierarchy with `writeError` translation —
ensures that every error class maps to a specific HTTP status and a specific user-visible
message. The monitoring dashboard now shows 404s as a distinct signal from 5xxes; a
spike in 404s may indicate a client-side bug or a deleted resource, while a spike in 5xxes
indicates a backend failure. Before the correction, both scenarios appeared identical.

The correction was made as part of the frontend team's adoption of TanStack Query, which
treats non-2xx responses as errors. The frontend was already handling 4xx and 5xx
differently in its UI — the backend simply was not providing the signals.

### Related Sections

- [See api-design → Corrected: HTTP Status for Not Found](./api-design.md#corrected-http-status-for-not-found)
  for the corresponding API-design correction that accompanied this change.
- [See error-handling → Domain Error Type Hierarchy](#domain-error-type-hierarchy) for
  the architecture that replaced the "wrap everything as 500" approach.
