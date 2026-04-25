---
domain: architecture
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: architect
---

> **Read-only reference.** This file is shipped with the ECC Base Template as a worked
> example to illustrate what a populated knowledge file looks like after many sessions on
> a real project. It is **not** your knowledge file. Your own knowledge file lives at
> `.claude/learn/knowledge/architecture.md` and starts empty until agents enrich it during real
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

## Hexagonal Split  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

A layered architecture divides a system into horizontal tiers where each tier is allowed
to call only the tier below it. The goal is to isolate business logic from infrastructure
concerns so that the business logic can be tested without a running database, HTTP server,
or external API.

Hexagonal architecture (also called Ports and Adapters) makes the isolation explicit with
a vocabulary: the **domain** (pure business logic) sits at the center. **Ports** are
interfaces the domain defines to express what it needs — "a thing that can find a task by
ID," "a thing that can send a notification." **Adapters** are the concrete implementations
that connect those ports to real infrastructure — the PostgreSQL implementation of the
task-finder port, the Slack implementation of the notification port.

The consequence of this separation is that adapters are swappable. If the notification
system moves from Slack to email, only the notification adapter changes. The domain logic,
the service layer, and the handler layer are untouched.

### Idiomatic Variation  [MID]

Meridian does not implement a strict textbook hexagonal architecture. The team uses a
pragmatic three-layer split that captures the benefits without the ceremony:

```
cmd/
  server/
    main.go               # wiring: instantiate repos, services, handlers, run Gin

internal/
  handler/                # HTTP layer: decode request → call service → encode response
    task.go
    webhook.go

  service/                # Business logic: orchestrate domain rules, call repositories
    task.go
    notification.go

  repository/             # Persistence layer: SQL queries, Redis calls
    task.go
    idempotency.go

  domain/                 # Pure types and error definitions — no imports from other layers
    task.go
    errors.go
```

The dependency direction is strict: `handler` imports `service`, `service` imports
`repository` interfaces (defined in `domain`), concrete repository implementations
import `domain`. Nothing in `domain` imports any other internal package. This prevents
cycles and keeps the domain testable without infrastructure.

In Go, the repository interface is defined where the service uses it — in the `service`
package or `domain` package — not in the `repository` package. This is the "accept
interfaces" idiom: the caller defines what interface it needs.

### Trade-offs and Constraints  [SENIOR]

The three-layer structure works well for Meridian's current size (one backend service,
~15 domain entities). At higher complexity — many teams writing many features in the same
service — the `service` package becomes a coordination problem: multiple engineers modify
`task.go` and `notification.go` simultaneously, creating merge conflicts and implicit
coupling between unrelated features.

At that scale, splitting by domain aggregate into subdirectories (`service/task/`,
`service/notification/`) or into separate services becomes worthwhile. The decision to
stay in one service was made consciously at Meridian's current stage: the operational
complexity of multiple services (separate deployments, cross-service transactions,
distributed tracing) would cost more than the coordination problem it solves.

The criterion for revisiting this decision: if any single service package file exceeds
600 lines and contains logic for more than two domain aggregates, it signals that the
package boundary has dissolved and a split is overdue.

### Example (Meridian)

```go
// domain/task.go — pure types, no infrastructure imports
package domain

type Task struct {
    ID          uuid.UUID
    WorkspaceID uuid.UUID
    Title       string
    AssigneeID  *uuid.UUID
    Status      TaskStatus
    CreatedAt   time.Time
    ArchivedAt  *time.Time
}

// TaskRepository is the port — defined in domain, implemented in repository
type TaskRepository interface {
    Create(ctx context.Context, params CreateTaskParams) (Task, error)
    Get(ctx context.Context, id uuid.UUID) (Task, error)
    List(ctx context.Context, params ListParams) ([]Task, error)
    Archive(ctx context.Context, id uuid.UUID) (Task, error)
}
```

```go
// service/task.go — imports domain types and interfaces, not repository package
package service

type TaskService struct {
    tasks  domain.TaskRepository  // interface from domain package
    notify NotificationService    // interface from this package
}
```

The `TaskService` never imports `repository.TaskRepository` — the concrete type. It only
knows the interface. In tests, a mock that implements `domain.TaskRepository` is injected.

### Related Sections

- [See api-design → Resource Hierarchy](./api-design.md#resource-hierarchy-tasks-and-assignments)
  for how this layer structure maps to the HTTP routing design.
- [See error-handling → Domain Error Type Hierarchy](./error-handling.md#domain-error-type-hierarchy)
  for how errors propagate through these layers.

### Coach Illustration (default vs. hints)

> **Illustrative only.** Not part of the live agent contract. Governed by
> `.claude/skills/learn/coach-styles/`.

**Scenario:** A learner is adding a new "milestone" feature to Meridian and asks where to
put the milestone aggregation logic — in the handler, the service, or the repository.

**`default` style** — The agent explains the three-layer rule (business logic in service,
persistence in repository, translation in handler), writes the `MilestoneService` struct
and interface, places the aggregation logic in the service, and shows how the handler
calls it. `## Learning:` trailers explain the hexagonal split rationale.

**`hints` style** — The agent names the layer (service), names the pattern (thin handler
+ fat service), and emits a hint. The learner writes the `MilestoneService` body.

---

## Repository Pattern  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

The **repository pattern** is a way of organizing all database access behind a single
interface for each domain aggregate. The business logic (service layer) does not write
SQL queries. It calls methods on a repository: `tasks.Create(...)`, `tasks.Get(id)`,
`tasks.Archive(id)`. The repository translates those calls into SQL, deserializes the
results into domain types, and returns them to the service.

The benefit is isolation. The service is independent of the database: it does not know
whether the underlying store is PostgreSQL, a test double, or an in-memory map. When
testing the service, the test injects a mock repository. When testing the repository, the
test injects a real database. The two test layers are independent.

The cost is indirection: every database operation requires a method on the repository
interface. In a small project, this feels like ceremony. In a project where the same
table is accessed from ten different service methods, the repository is the only place
that knows how the table is structured — a change to the schema is a change to one file,
not ten scattered SQL strings.

### Idiomatic Variation  [MID]

Meridian implements one repository per database table group. The `TaskRepository`
interface owns the `tasks` table and the `task_assignments` table (since assignments
have no independent lifecycle). The `WorkspaceRepository` owns the `workspaces` and
`workspace_members` tables.

The interfaces are defined in `domain/`:

```go
// domain/repository.go
type TaskRepository interface {
    Create(ctx context.Context, params CreateTaskParams) (Task, error)
    Get(ctx context.Context, id uuid.UUID) (Task, error)
    List(ctx context.Context, params ListParams) ([]Task, Pagination, error)
    Update(ctx context.Context, id uuid.UUID, params UpdateTaskParams) (Task, error)
    Archive(ctx context.Context, id uuid.UUID) (Task, error)
    ListAssignees(ctx context.Context, taskID uuid.UUID) ([]User, error)
    AddAssignee(ctx context.Context, taskID, userID uuid.UUID) error
    RemoveAssignee(ctx context.Context, taskID, userID uuid.UUID) error
}
```

The concrete implementation in `repository/task.go` holds the `*sql.DB` and implements
every method with SQL. The interface carries no SQL — not even a comment about SQL.

### Trade-offs and Constraints  [SENIOR]

The repository interface grows as the service needs more access patterns. Over time, a
`TaskRepository` with 15 methods becomes a god-interface: every test that injects a mock
must implement all 15 methods, even if the test only exercises one. Meridian has not hit
this limit yet (the interface has 8 methods), but the response when it does will be to
split: a `TaskReadRepository` for read-only operations and a `TaskWriteRepository` for
writes, each with fewer methods. Tests for read-only service logic inject only the read
interface.

The other cost is that complex cross-table queries — aggregation across tasks,
assignments, and workspace members in a single SQL JOIN — do not fit cleanly into a
single repository's method. Meridian handles this with a dedicated `ReportRepository`
that holds the cross-table query methods. It is not tied to any single domain aggregate;
it is a query object for reporting purposes only.

### Example (Meridian)

See the interface definition above. The PostgreSQL implementation:

```go
// repository/task.go
type postgresTaskRepository struct {
    db *sql.DB
}

func (r *postgresTaskRepository) Get(ctx context.Context, id uuid.UUID) (domain.Task, error) {
    row := r.db.QueryRowContext(ctx, `
        SELECT id, workspace_id, title, assignee_id, status, created_at, archived_at
        FROM tasks
        WHERE id = $1 AND deleted_at IS NULL
    `, id)

    var t domain.Task
    err := row.Scan(&t.ID, &t.WorkspaceID, &t.Title, &t.AssigneeID,
                    &t.Status, &t.CreatedAt, &t.ArchivedAt)
    if errors.Is(err, sql.ErrNoRows) {
        return domain.Task{}, domain.ErrNotFound
    }
    return t, err
}
```

The Postgres-to-domain error translation (`sql.ErrNoRows` → `domain.ErrNotFound`) happens
inside the repository, not in the service. See
[error-handling → Boundary Translation](./error-handling.md#boundary-translation-postgres-to-domain-errors)
for the full translation pattern.

### Related Sections

- [See error-handling → Boundary Translation](./error-handling.md#boundary-translation-postgres-to-domain-errors)
  for how this repository translates database errors into domain errors.
- [See persistence-strategy → Transaction Boundaries Live in Services, Not Repositories](./persistence-strategy.md#transaction-boundaries-live-in-services-not-repositories)
  for the SQL conventions the repository implementation follows.

---

## Cross-Cutting Concern: Notifications  [MID]

### First-Principles Explanation  [JUNIOR]

Some behaviors in a system are not owned by a single domain aggregate but participate in
many operations. Sending a notification when a task is assigned, when a deadline is
missed, and when a task is archived — these are all notification behaviors triggered from
different parts of the system. This is a **cross-cutting concern**.

The naive implementation puts notification calls everywhere: in `task.go`'s Create method,
in `task.go`'s Archive method, in `deadline.go`'s expiry check. The problem is that
notification behavior is now scattered across the codebase. Changing how notifications
work (switching from Slack to email, adding rate limiting) requires finding and updating
every callsite.

### Idiomatic Variation  [MID]

Meridian isolates notifications in a `NotificationService` that is injected into any
service that needs it:

```go
// service/notification.go
type NotificationService interface {
    NotifyTaskAssigned(ctx context.Context, task domain.Task, assignee domain.User) error
    NotifyTaskArchived(ctx context.Context, task domain.Task) error
    NotifyDeadlineMissed(ctx context.Context, task domain.Task) error
}
```

The `TaskService` receives a `NotificationService` via constructor injection. When a task
is assigned, `TaskService.AssignTask` calls `notify.NotifyTaskAssigned` after the
repository write succeeds. The notification service handles Slack API calls, retries, and
idempotency key storage.

The notification service is not a "domain" concept — tasks do not know about notifications.
Notifications are an application-layer concern. Placing `NotificationService` in the
`service` package (not in `domain`) makes this explicit: it is a capability of the
application, not a rule of the business domain.

### Trade-offs and Constraints  [SENIOR]

Synchronous notification calls in the service layer mean a Slack API timeout or error
causes the task operation to fail or return slowly. Meridian accepts this at current
scale because task operations are not high-frequency and the Slack client has a 3-second
timeout with one retry. If task creation volume grows significantly or Slack reliability
degrades, the correct response is to make notification delivery asynchronous: write the
notification to a queue (a `notifications` table or a Redis list) and have a separate
worker deliver it. The interface does not need to change — only the implementation.

This is the deferred-async pattern: design the interface as if delivery is synchronous,
implement it synchronously while scale permits, and swap the implementation for an async
queue when the forcing function arrives (timeout budgets, throughput targets). The
interface is the same; the implementation detail changes.

### Example (Meridian)

```go
// service/task.go
func (s *TaskService) AssignTask(ctx context.Context, taskID, assigneeID uuid.UUID) error {
    task, err := s.tasks.Get(ctx, taskID)
    if err != nil {
        return err
    }
    if err := s.tasks.AddAssignee(ctx, taskID, assigneeID); err != nil {
        return err
    }
    assignee, err := s.users.Get(ctx, assigneeID)
    if err != nil {
        return err // notification failure does not undo the assignment
    }
    // Notification is best-effort; log but do not propagate the error
    if err := s.notify.NotifyTaskAssigned(ctx, task, assignee); err != nil {
        log.Warn("notification delivery failed", "task_id", taskID, "err", err)
    }
    return nil
}
```

The notification error is logged but not propagated. The assignment succeeded; the
notification is best-effort. This is a deliberate product decision: failing to notify
Slack should not fail the user's assignment action.

### Related Sections

- [See error-handling → Error Propagation and Recovery](./error-handling.md#idempotent-retry-on-the-slack-webhook)
  for how notification retries are managed.
- [See testing-discipline → Contract Testing the Slack Integration](./testing-discipline.md#contract-testing-the-slack-integration)
  for how this notification path is tested.

---

## Prior Understanding: Package Layout by Type  [MID]

### Prior Understanding (revised 2025-12-03)

The original package layout (in Meridian's initial commit) grouped files by artifact
type rather than by layer:

```
internal/
  models/       # all domain structs
  handlers/     # all HTTP handlers
  services/     # all service logic
  db/           # all database logic
```

This was revised because the "group by type" layout created invisible coupling:
`handlers/task.go` and `handlers/webhook.go` shared no code but lived next to each
other, while `handlers/task.go` and `services/task.go` were tightly coupled but lived
in different packages. Adding a new domain entity (milestones) required touching four
packages simultaneously — one file per package — even though the entire feature was
logically one unit.

**Corrected understanding:**

The current layout groups by layer (handler, service, repository, domain), not by
entity. This is standard for Go projects at Meridian's size: layers are the natural
compilation and import boundary, not entities. Entity-based grouping
(`internal/tasks/handler.go`, `internal/tasks/service.go`) is appropriate when each
entity's package needs to export types used by other entity packages, but that level of
boundary enforcement is premature for a project of this size and introduces circular
import risks.

The revised layout (shown in the Hexagonal Split section above) was adopted after the
first feature addition (Slack integration) revealed that the "group by type" layout
required coordinating changes across all four top-level packages for every feature.

### Related Sections

- [See architecture → Hexagonal Split](#hexagonal-split) for the current layer-based
  layout that replaced the type-based layout.
