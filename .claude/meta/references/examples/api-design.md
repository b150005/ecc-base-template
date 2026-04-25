---
domain: api-design
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: architect
contributing-agents: [architect, code-reviewer]
---

> **Read-only reference.** This file is shipped with the ECC Base Template as a worked
> example to illustrate what a populated knowledge file looks like after many sessions on
> a real project. It is **not** your knowledge file. Your own knowledge file lives at
> `.claude/learn/knowledge/api-design.md` and starts empty until agents enrich it during real
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

## Resource Hierarchy: Tasks and Assignments  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

A REST API models the domain as **resources** — things that can be created, read,
updated, and deleted. Resources are organized into a URL hierarchy that reflects their
relationships. The central design question is how deep to nest that hierarchy.

Deep nesting (`/workspaces/{wid}/projects/{pid}/tasks/{tid}/assignments/{aid}`) makes
each resource's context explicit in the URL. The caller always knows which workspace and
project a task belongs to. But deep nesting creates long URLs, makes routes hard to
remember, and forces callers to reconstruct the full path whenever they navigate between
resources. If a task is moved between projects, its URL changes, breaking any client that
cached the old URL.

Shallow nesting limits relationships to one level: a task belongs to a workspace, but
the workspace ID is passed as a query parameter or encoded in the task ID, not as a URL
segment.

### Idiomatic Variation  [MID]

Meridian keeps nesting to one level for collection resources and zero levels for
individual resources:

```
GET    /v1/workspaces/{workspace_id}/tasks        # list tasks in workspace
POST   /v1/workspaces/{workspace_id}/tasks        # create task in workspace
GET    /v1/tasks/{task_id}                        # get specific task (no workspace in path)
PATCH  /v1/tasks/{task_id}                        # update task
DELETE /v1/tasks/{task_id}                        # delete task

POST   /v1/tasks/{task_id}/assignments            # assign task to user
DELETE /v1/tasks/{task_id}/assignments/{user_id}  # remove assignment
GET    /v1/tasks/{task_id}/assignments            # list assignees
```

Assignments are a sub-resource of tasks because an assignment has no independent
existence — it cannot be retrieved, updated, or deleted without knowing which task it
belongs to. The task context is always meaningful. By contrast, `/v1/tasks/{task_id}`
does not include `/workspaces/{workspace_id}` in the path because the caller already
knows the task ID and the task carries its workspace context in the response body.

### Trade-offs and Constraints  [SENIOR]

The shallow hierarchy means that `GET /v1/tasks/{task_id}` requires the backend to
authorize the caller against the task's workspace without seeing the workspace ID in the
URL. The handler must look up the task, find its workspace, and then check whether the
caller is a member of that workspace. This is one extra query compared to a deep-nested
design where the workspace ID is in the URL and can be checked before touching the task
table.

Meridian accepted this cost because the client-side benefit — stable resource URLs that
survive task moves between projects — outweighed the server-side cost of one extra
authorization query per task fetch. Task moves are a core Meridian feature (differentiator
from competitors); stable URLs mean Slack-shared task links do not break after a move.

### Example (Meridian)

The Gin router registration for the task resource:

```go
// router/router.go
func RegisterRoutes(r *gin.Engine, h *handlers.Handlers, auth middleware.AuthMiddleware) {
    v1 := r.Group("/v1")
    v1.Use(auth.RequireWorkspaceMember())

    workspaces := v1.Group("/workspaces/:workspace_id")
    workspaces.GET("/tasks", h.Task.ListTasks)
    workspaces.POST("/tasks", h.Task.CreateTask)

    tasks := v1.Group("/tasks")
    tasks.GET("/:task_id", h.Task.GetTask)
    tasks.PATCH("/:task_id", h.Task.UpdateTask)
    tasks.DELETE("/:task_id", h.Task.DeleteTask)
    tasks.POST("/:task_id/assignments", h.Task.AssignTask)
    tasks.DELETE("/:task_id/assignments/:user_id", h.Task.RemoveAssignment)
}
```

### Related Sections

- [See architecture → Hexagonal Split](./architecture.md#hexagonal-split) for
  how the handler layer interacts with this resource model.
- [See api-design → Error Envelope: RFC 9457](#error-envelope-rfc-9457) for how errors
  are returned from every endpoint in this hierarchy.

### Coach Illustration (default vs. hints)

> **Illustrative only.** Not part of the live agent contract. Governed by
> `.claude/skills/learn/coach-styles/`.

**Scenario:** A learner is designing the API for bulk task archival and asks whether to
use `POST /v1/tasks/bulk-archive` or `POST /v1/workspaces/{wid}/tasks/bulk-archive`.

**`default` style** — The agent recommends `POST /v1/tasks/bulk-archive` with the task
IDs in the request body, explains why the workspace-level path adds no authorization
benefit (the service checks each task's workspace anyway), and shows the request/response
shape. `## Learning:` trailers explain shallow nesting.

**`hints` style** — The agent notes which HTTP method and path pattern fits, names the
"shallow nesting" principle, and emits a hint naming the trade-off. The learner designs
the request body shape themselves.

---

## Idempotency Key Handling  [MID]

### First-Principles Explanation  [JUNIOR]

Network calls can fail in ambiguous ways. A POST request that creates a resource may fail
after the server processed the request but before the response reached the client. The
client does not know whether the resource was created. Retrying the POST may create a
duplicate. This is the "at-least-once delivery" problem.

**Idempotency keys** solve it. The client generates a unique key for each logical
operation and sends it in a request header. The server records the key when it first
processes the request and stores the result. If the same key arrives again, the server
returns the stored result instead of processing the request again. The operation is
idempotent: sending it twice has the same effect as sending it once.

### Idiomatic Variation  [MID]

Meridian uses idempotency keys for the Slack webhook ingest endpoint — the endpoint that
receives task-event callbacks from Slack's API when a Meridian bot command is invoked.
Slack's webhook delivery guarantee is at-least-once; the same event can arrive multiple
times. The `Idempotency-Key` header carries Slack's own event ID:

```go
// handler/webhook.go
func (h *WebhookHandler) IngestSlackEvent(c *gin.Context) {
    key := c.GetHeader("Idempotency-Key")
    if key == "" {
        c.JSON(http.StatusBadRequest, errorResponse(errors.New("missing Idempotency-Key")))
        return
    }

    seen, err := h.svc.CheckAndRecordIdempotencyKey(c.Request.Context(), key, 24*time.Hour)
    if err != nil {
        h.writeError(c, err)
        return
    }
    if seen {
        c.JSON(http.StatusOK, gin.H{"status": "already_processed"})
        return
    }

    var event slackEvent
    if err := c.ShouldBindJSON(&event); err != nil {
        c.JSON(http.StatusBadRequest, errorResponse(err))
        return
    }

    if err := h.svc.ProcessSlackEvent(c.Request.Context(), event); err != nil {
        h.writeError(c, err)
        return
    }
    c.JSON(http.StatusOK, gin.H{"status": "processed"})
}
```

The idempotency store is Redis with a 24-hour TTL. The key is checked and recorded
before processing, not after, so a failed processing attempt does not mark the key as
seen — the client can retry and the request will be processed again.

### Trade-offs and Constraints  [SENIOR]

Storing idempotency keys before processing means a failed operation is retryable, but
it also means the key is held in Redis for 24 hours even for requests that eventually
fail permanently. In Meridian's traffic volume, this is not a concern. For a higher-traffic
system, a shorter TTL or a more selective key storage strategy would be warranted.

The 24-hour TTL was chosen to match Slack's maximum event delivery retry window. Events
older than 24 hours are guaranteed by Slack to not be retried, so any key older than 24
hours can be safely expired without risk of duplicate processing.

### Example (Meridian)

The Redis key format is `idempotency:slack:{event_id}`. A separate Redis key namespace
(`idempotency:api:{client_key}`) is used for client-supplied idempotency keys on
Meridian's own write endpoints, but those endpoints are not exposed publicly and the
pattern is not yet documented in the OpenAPI spec.

### Related Sections

- [See error-handling → Idempotent Retry on the Slack Webhook](./error-handling.md#idempotent-retry-on-the-slack-webhook)
  for how the error-handling layer interacts with idempotency key checking.
- [See testing-discipline → Contract Testing the Slack Integration](./testing-discipline.md#contract-testing-the-slack-integration)
  for how this endpoint's idempotency behavior is tested.

---

## Cursor-Based Pagination on Task Lists  [MID]

### First-Principles Explanation  [JUNIOR]

Pagination limits how many results an API returns per request. The two common strategies
are **offset pagination** and **cursor pagination**.

Offset pagination: the client sends `page=2&limit=20`, the server runs
`SELECT ... LIMIT 20 OFFSET 20`. Simple to implement and understand. The client can jump
to any page by number.

Cursor pagination: the server returns a `nextCursor` token with each response. The client
sends `cursor=<token>&limit=20` on the next request. The server decodes the cursor to
find where the previous page ended and continues from there.

### Idiomatic Variation  [MID]

Meridian uses cursor pagination for task list endpoints. The cursor encodes the
`(created_at, id)` tuple of the last item on the previous page, base64-encoded:

```json
// GET /v1/workspaces/{workspace_id}/tasks?limit=20
{
  "tasks": [...],
  "pagination": {
    "nextCursor": "eyJjcmVhdGVkX2F0IjoiMjAyNi0wNC0yMlQxMDowMDowMFoiLCJpZCI6InV1aWQifQ==",
    "hasMore": true
  }
}
```

```go
// The SQL query for cursor-based continuation
func (r *TaskRepository) List(ctx context.Context, params ListParams) ([]domain.Task, error) {
    q := `SELECT * FROM tasks WHERE workspace_id = $1`
    args := []interface{}{params.WorkspaceID}

    if params.Cursor != nil {
        q += ` AND (created_at, id) < ($2, $3)`
        args = append(args, params.Cursor.CreatedAt, params.Cursor.ID)
    }
    q += ` ORDER BY created_at DESC, id DESC LIMIT $` + strconv.Itoa(len(args)+1)
    args = append(args, params.Limit+1) // fetch one extra to detect hasMore
    // ...
}
```

Fetching `limit + 1` rows and checking if the count exceeds `limit` is the standard
technique for determining `hasMore` without a separate `COUNT(*)` query.

### Trade-offs and Constraints  [SENIOR]

Cursor pagination cannot jump to an arbitrary page. A client building a "go to page 5"
feature cannot do so with cursors — it must walk through pages 1 through 4 sequentially.
For Meridian's task board (which scrolls continuously, never jumps to a page number),
this is not a limitation. If a reporting feature ever needs "skip to row 100," offset
pagination would be required for that endpoint specifically.

Offset pagination degrades when the dataset is large and mutates frequently. If tasks are
created or deleted between page fetches, offset pagination produces skipped or duplicated
results. Cursor pagination avoids this: the `(created_at, id)` tuple anchors the position
to a specific row, so insertions and deletions on other parts of the list do not affect
the current position.

The choice was made in favor of cursors specifically because Meridian's task list is
expected to receive high-frequency writes (tasks being created and updated during active
sprints) and users scroll continuously rather than jump between pages.

### Example (Meridian)

See the SQL snippet in the Idiomatic Variation section. The `(created_at, id)` composite
index on the `tasks` table is required for this query to be efficient — see
[persistence-strategy → Indexing Strategy on the Tasks Table](./persistence-strategy.md#indexing-strategy-on-the-tasks-table)
for the index definition.

### Related Sections

- [See persistence-strategy → Indexing Strategy on the Tasks Table](./persistence-strategy.md#indexing-strategy-on-the-tasks-table)
  for the composite index that makes cursor pagination efficient.
- [See implementation-patterns → Early Returns and Guard Clauses](./implementation-patterns.md#early-returns-and-guard-clauses)
  for the pagination utility that wraps this query pattern.

---

## Error Envelope: RFC 9457  [MID]

### First-Principles Explanation  [JUNIOR]

When an API call fails, the response must communicate two things: what went wrong (for
the client to display to the user or to retry intelligently) and enough context for the
server-side developer to diagnose the problem from logs alone. A bare HTTP status code
is not enough. `400 Bad Request` says the client made an error; it does not say which
field was invalid or why.

Every project that builds an HTTP API eventually needs an error response format. The
choice is: invent one or adopt a standard. Inventing a custom format means every client
library must be taught the custom format. Adopting a standard means client libraries that
already speak the standard work out of the box.

### Idiomatic Variation  [MID]

Meridian uses RFC 9457 (Problem Details for HTTP APIs) as its error envelope format. The
response body for any error is:

```json
{
  "type": "https://api.meridian.app/errors/validation-error",
  "title": "Validation Error",
  "status": 400,
  "detail": "The 'title' field is required and must be between 1 and 255 characters.",
  "instance": "/v1/tasks",
  "extensions": {
    "fields": ["title"]
  }
}
```

The `type` field is a URI that uniquely identifies the error class. Meridian's error
types are documented at `https://api.meridian.app/errors/` (an internal docs page, not a
live URL in the response). The `instance` field identifies the request that caused the
error — useful when correlating a client-visible error with a server-side log entry.

The `extensions` field carries domain-specific context not covered by the RFC. For
validation errors, it carries the list of invalid field names so the client can highlight
the right form fields without parsing the `detail` string.

### Trade-offs and Constraints  [SENIOR]

RFC 9457 is a standard, but it is not universally supported by HTTP client libraries.
Meridian's React frontend uses TanStack Query, which surfaces the raw error body; the
frontend must parse the `type` field to decide which error UI to show. This is not
significantly more work than parsing a custom format, but it does mean the frontend
team needed to build an error parsing layer.

The RFC-vs-custom decision was made for long-term maintainability: if Meridian ever ships
a public API or SDK, RFC 9457 is the format client SDK developers expect. A custom format
would require documenting the custom spec in addition to the REST resource semantics.

### Example (Meridian)

The Go middleware that translates domain errors to RFC 9457 responses:

```go
// handler/errors.go
func (h *baseHandler) writeError(c *gin.Context, err error) {
    var domainErr *domain.Error
    if errors.As(err, &domainErr) {
        c.JSON(domainErr.HTTPStatus(), gin.H{
            "type":     "https://api.meridian.app/errors/" + domainErr.Type(),
            "title":    domainErr.Title(),
            "status":   domainErr.HTTPStatus(),
            "detail":   domainErr.Detail(),
            "instance": c.Request.URL.Path,
        })
        return
    }
    // Unknown error: log and return 500
    log.Error("unhandled error", "err", err, "path", c.Request.URL.Path)
    c.JSON(http.StatusInternalServerError, gin.H{
        "type":   "https://api.meridian.app/errors/internal-error",
        "title":  "Internal Server Error",
        "status": 500,
        "detail": "An unexpected error occurred. Please try again or contact support.",
    })
}
```

### Related Sections

- [See error-handling → Domain Error Type Hierarchy](./error-handling.md#domain-error-type-hierarchy)
  for the `domain.Error` type that feeds this translation.

---

## Corrected: HTTP Status for Not Found  [JUNIOR]

> Superseded 2025-11-03: The original API design used `200 OK` with an empty body for
> missing resources. This was incorrect behavior; `404 Not Found` is the correct status
> for a resource that does not exist.

> Original implementation (incorrect):
> ```go
> task, err := repo.Get(ctx, id)
> if err == sql.ErrNoRows {
>     c.JSON(http.StatusOK, nil) // incorrect: 200 with null body
>     return
> }
> ```

**Corrected understanding:**

A resource that does not exist should return `404 Not Found`, not `200 OK`. The original
behavior was introduced in Meridian's first sprint when the frontend team was not yet
parsing status codes and checked for a null response body instead. When the frontend was
refactored to use TanStack Query's error handling (which treats non-2xx responses as
errors), the `200` behavior broke the error display. The correction was made in the same
PR as the TanStack Query refactor.

The corrected implementation:

```go
task, err := repo.Get(ctx, id)
if errors.Is(err, domain.ErrNotFound) {
    h.writeError(c, domain.NewNotFoundError("task", id))
    return
}
```

The principle: HTTP status codes are a contract. `200` means the request succeeded and
the response body contains the requested resource. `404` means the resource does not
exist. Returning `200` with a null body conflates "success" with "not found" and prevents
clients from using standard HTTP error-handling patterns.

### Related Sections

- [See error-handling → Domain Error Type Hierarchy](./error-handling.md#domain-error-type-hierarchy)
  for the `domain.ErrNotFound` type used in the corrected implementation.
