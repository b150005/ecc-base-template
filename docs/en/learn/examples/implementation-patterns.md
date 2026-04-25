---
domain: implementation-patterns
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: linter
contributing-agents: [linter, implementer, code-reviewer]
---

> **Read-only reference.** This file is shipped with the ECC Base Template as a worked
> example to illustrate what a populated knowledge file looks like after many sessions on
> a real project. It is **not** your knowledge file. Your own knowledge file lives at
> `learn/knowledge/implementation-patterns.md` and starts empty until agents enrich it during real
> work. Agents never read, cite, or write under `docs/en/learn/examples/` — this tree is for
> human readers only. See [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md)
> for the design rationale.

---

## How to Read This File

Each entry in a knowledge file covers one **concept** — a durable topic within the domain.
Entries are organized by concept, not by date or session. Every entry carries one or more
level markers:

| Marker | Audience | What it covers |
|--------|----------|----------------|
| `[JUNIOR]` | First encounter with this concept | First-principles explanation; vocabulary introduced before use; naive alternative named and contrasted |
| `[MID]` | Competent engineer new to this stack | Non-obvious idiomatic application; what practitioners do that a newcomer would not guess |
| `[SENIOR]` | Non-default trade-off evaluation | Why the project chose a non-default option; what was given up; when to revisit |

A single concept entry may carry multiple markers. `[JUNIOR]` and `[MID]` sections build
sequentially within one entry; `[SENIOR]` sections name the trade-off and name what is
given up. Entries with only `[SENIOR]` markers record decisions a junior developer can
skip until they encounter the forcing function.

**Prior Understanding and Corrected entries** show how understanding evolved over time.
These are the most valuable entries to read before starting your own knowledge file —
they demonstrate that the knowledge base is a living record, not a static snapshot.

---

## Early Returns and Guard Clauses  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

When a function encounters a condition that makes the rest of its logic irrelevant, it can
return immediately instead of wrapping the rest of the logic in a conditional block. This
pattern is called an **early return** or **guard clause**.

The alternative — nested conditionals — moves the main logic deeper with each condition:

```go
// Nested: main logic at the bottom of a 3-level indent
if condition1 {
    if condition2 {
        if condition3 {
            // main logic here, buried
        }
    }
}
```

Early returns flatten this structure by exiting when conditions are not met:

```go
// Early returns: main logic at the top level
if !condition1 {
    return err
}
if !condition2 {
    return err
}
if !condition3 {
    return err
}
// main logic here, at the top level
```

The reader understands the preconditions upfront, then reads the main logic without
cognitive load from tracking nested indentation. The pattern is especially valuable in
service layers where authorization and validation checks often outnumber the business logic.

### Idiomatic Variation  [MID]

Meridian enforces early returns as a lint rule. Every service method in `service/` begins
with precondition checks: authorization, workspace membership, resource existence. Only
after all guards pass does the method execute the core business logic.

```go
// service/task.go — Meridian style
func (s *TaskService) AssignTask(ctx context.Context, taskID, userID, callerID uuid.UUID) error {
    // Guard 1: resource exists
    task, err := s.tasks.Get(ctx, taskID)
    if err != nil {
        return err
    }

    // Guard 2: caller is authorized
    callerWorkspace, err := s.workspaceForUser(ctx, callerID)
    if err != nil {
        return err
    }
    if task.WorkspaceID != callerWorkspace {
        return &domain.AuthorizationError{Action: "assign", Resource: "task"}
    }

    // Guard 3: assignee exists in workspace
    if err := s.users.VerifyMembership(ctx, callerWorkspace, userID); err != nil {
        return &domain.ValidationError{Field: "assignee_id", Message: "user is not a workspace member"}
    }

    // Main logic: perform the assignment
    if err := s.tasks.AddAssignee(ctx, taskID, userID); err != nil {
        return err
    }

    // Side effect: best-effort notification
    if err := s.notify.NotifyTaskAssigned(ctx, task); err != nil {
        log.Warn("notification failed", "task_id", taskID)
    }
    return nil
}
```

The pattern is enforceable: if a handler calls a service and receives an error, the handler
has already received the correct error type (domain.AuthorizationError, domain.ValidationError)
because the service's guard clauses translate boundary conditions into domain errors before
entering the main logic.

### Trade-offs and Constraints  [SENIOR]

Early returns can make error handling more visible (the caller sees each condition) or less
(the caller must trace through all guards to know what errors are possible). Meridian
chose visibility over conciseness: each guard is a one-liner, and the comments label their
intent clearly. The trade-off is slightly longer methods — but only in length, not in
cognitive complexity.

One cost: when a guard is missing, the bug is obvious. At Meridian's prior code review, a
missing authorization check in a 6-level-nested handler was missed in review because the
check lived at the bottom of the nesting. Switching to early returns made the missing guard
obvious: `AssignTask` had no workspace-membership guard, whereas every other method did.
This caught a CRITICAL access-control vulnerability before production. Early returns are a
lint-checklist aid for code reviewers.

### Example (Meridian)

The `AssignTask` method above demonstrates the pattern in action. The `AssignTask` handler
that calls this service method is a thin translator:

```go
// handler/task.go
func (h *TaskHandler) AssignTask(c *gin.Context) {
    var req AssignTaskRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, errorResponse(err))
        return
    }
    callerID := c.GetString("user_id") // from auth middleware
    if err := h.svc.AssignTask(c.Request.Context(), req.TaskID, req.UserID, callerID); err != nil {
        h.writeError(c, err)
        return
    }
    c.JSON(http.StatusOK, gin.H{"status": "assigned"})
}
```

The handler does not repeat the authorization checks — it relies on the service to enforce
them and translate violations into domain errors that `h.writeError` converts to HTTP
responses. This separation of concerns makes the handler testable without mocking the
permission system, and makes the service testable without an HTTP server.

### Related Sections

- [See review-taste → The Severity Ladder](./review-taste.md#the-severity-ladder)
  for why reviewers flag nested handlers as CRITICAL even if tests pass.
- [See error-handling → Domain Error Type Hierarchy](./error-handling.md#domain-error-type-hierarchy)
  for how guard clauses propagate errors as domain types, not HTTP errors.
- [See architecture → Hexagonal Split](./architecture.md#hexagonal-split) for how
  the handler layer relies on the service's guard clauses.

### Coach Illustration (default vs. hints)

> **Illustrative only.** The following is a worked example of how the two coaching styles
> differ for a task in this domain. It is not part of the live agent contract. Actual
> agent behavior is governed by the style files at
> `.claude/skills/learn/coach-styles/`.

**Scenario:** A learner is writing a service method to archive tasks and asks whether to
put the authorization check first or to check ownership inside an if statement after
reading the task.

**`default` style** — The agent refactors the code to use early returns, explains the
pattern, and shows why the guard-clauses style is reviewable (the reviewer can see all
preconditions at the top of the function). `## Learning:` trailers explain early returns
and Meridian's lint enforcement.

**`hints` style** — The agent identifies the pattern (early returns) and the placement
(guards first, main logic last), then emits:

```
## Coach: hint
Step: Reorder the archive logic: 1) check resource exists, 2) check authorization,
3) perform archive, 4) return.
Pattern: Guard clauses / early returns (authorization checks before business logic).
Rationale: Authorization errors must be detected before side effects. Early returns
make these checks reviewable — a reviewer can see all preconditions without tracing nested
blocks.
```

The learner rearranges the code. On the next turn, the agent responds to any errors
without re-writing the scaffold.

---

## Functional Options Pattern for Service Constructors  [MID]

### First-Principles Explanation  [JUNIOR]

When a type has optional configuration fields that may vary between instances, there are
two design approaches:

1. **Config struct**: Pass a single `Config` struct with all options.
2. **Functional options**: Pass variadic functions that each set one option.

Config structs are familiar: `NewService(cfg ServiceConfig)`. But when a caller only needs
to override one or two fields, they must construct the whole struct, potentially with
sentinel values for the omitted fields. Worse, adding a new field to the struct means all
call sites must decide whether to set it.

Functional options let each call site choose which settings to apply:

```go
// functional options style
s := NewService(repo,
    WithLogger(myLogger),
    WithTimeout(30*time.Second),
)
```

Each `With*` function is a `func(s *Service)` that modifies the service after default
construction. Call sites that do not need to set a value omit the corresponding `With*`
call entirely.

### Idiomatic Variation  [MID]

Meridian uses functional options for service constructors with optional observability or
behavior-override fields. The pattern appears in `service/task.go`:

```go
// service/task.go
type TaskService struct {
    tasks      domain.TaskRepository
    users      domain.UserRepository
    notify     NotificationService
    logger     Logger
    metricsCollector MetricsCollector
}

// Constructor with required dependencies
func NewTaskService(tasks domain.TaskRepository, users domain.UserRepository) *TaskService {
    return &TaskService{
        tasks:      tasks,
        users:      users,
        notify:     newDefaultNotifier(), // sensible default
        logger:     newNullLogger(),       // no-op by default
        metricsCollector: newNullMetrics(), // no-op by default
    }
}

// Functional options
func WithLogger(logger Logger) func(*TaskService) {
    return func(s *TaskService) {
        s.logger = logger
    }
}

func WithMetricsCollector(mc MetricsCollector) func(*TaskService) {
    return func(s *TaskService) {
        s.metricsCollector = mc
    }
}

func WithNotificationService(ns NotificationService) func(*TaskService) {
    return func(s *TaskService) {
        s.notify = ns
    }
}

// Usage: required args + optional functional options
func buildServices(db *sql.DB) (*TaskService, error) {
    taskRepo := repository.NewTaskRepository(db)
    userRepo := repository.NewUserRepository(db)

    return NewTaskService(taskRepo, userRepo,
        WithLogger(globalLogger),
        WithMetricsCollector(prometheus.DefaultRegistry),
    ), nil
}
```

The pattern separates concerns: core dependencies (the repository) are required parameters,
while observability hooks (logger, metrics) are optional.

### Trade-offs and Constraints  [SENIOR]

Each functional option allocates a closure at call time. For a service that is constructed
once at startup, this allocation cost is negligible. For a type that is constructed
millions of times per second (like a temporary request object), the overhead becomes
measurable.

Meridian uses functional options only for singletons or long-lived instances: services in
`cmd/server/main.go`, middleware factories, and repository factories. Request-scoped values
(like an HTTP request context) use config structs because they are short-lived and the
allocation pattern is different.

The other cost is that required options are not enforced by the compiler. A call to
`NewTaskService()` without passing a required repository compiles fine but panics or
behaves incorrectly at runtime. Meridian's convention: if a field is required for the
service to function, it is a named parameter in the constructor, not an option. The
pattern is reserved for truly optional fields.

### Example (Meridian)

```go
// cmd/server/main.go — service setup
func main() {
    db, err := sql.Open("postgres", os.Getenv("DATABASE_URL"))
    // ... error handling, validation ...

    logger := slog.New(slog.NewJSONHandler(os.Stderr, nil))

    taskService := service.NewTaskService(
        repository.NewTaskRepository(db),
        repository.NewUserRepository(db),
        service.WithLogger(logger),
        service.WithMetricsCollector(prometheus.DefaultRegistry),
    )

    // ... continue wiring ...
}
```

The service is constructed once at startup with the full observability stack. A test, by
contrast, may construct it without any observers:

```go
// service/task_test.go — simplified test setup
func TestArchiveTask(t *testing.T) {
    taskSvc := NewTaskService(mockTaskRepo, mockUserRepo)
    // logger and metrics are no-ops; tests focus on business logic

    err := taskSvc.ArchiveTask(ctx, taskID, callerID)
    // assert
}
```

### Related Sections

- [See ecosystem-fluency → Go Interface Naming Conventions](./ecosystem-fluency.md#go-interface-naming-conventions)
  for the general Go convention this pattern extends.
- [See testing-discipline → Fixtures Are Test-Local, Never Shared Mutable State](./testing-discipline.md#fixtures-are-test-local-never-shared-mutable-state)
  for how the no-op defaults simplify test setup.

---

## Immutability at the Domain Layer  [MID]

### First-Principles Explanation  [JUNIOR]

**Immutability** means once a value is created, it cannot be changed. Mutating code modifies
a value in place; immutable code creates a new value with the change applied.

In languages with language-level immutability (Rust, Haskell), the compiler enforces it.
Go has no such enforcement — a struct field can be modified by any code that holds a pointer
to the struct. Meridian enforces immutability by convention at the domain layer: domain
types never expose setters, and mutations (if needed) return a new instance rather than
modifying the original.

This is a discipline choice, not a language feature. The benefit is reasoning: a domain
value handed to two different service methods cannot be mutated by one without affecting
the other. The cost is the need to explicitly create copies.

### Idiomatic Variation  [MID]

Meridian's domain types in `domain/task.go` have private fields and a constructor that
validates and returns an immutable instance:

```go
// domain/task.go — immutable domain type
package domain

type Task struct {
    id          uuid.UUID
    workspaceID uuid.UUID
    title       string
    assigneeID  *uuid.UUID
    status      TaskStatus
    createdAt   time.Time
    archivedAt  *time.Time
}

// Constructor: only way to create a Task
func NewTask(id, workspaceID uuid.UUID, title string) (Task, error) {
    if title == "" {
        return Task{}, &ValidationError{Field: "title", Message: "title is required"}
    }
    if len(title) > 255 {
        return Task{}, &ValidationError{Field: "title", Message: "title must be <= 255 chars"}
    }
    return Task{
        id:          id,
        workspaceID: workspaceID,
        title:       title,
        status:      TaskStatusActive,
        createdAt:   time.Now(),
    }, nil
}

// Accessors: read-only
func (t Task) ID() uuid.UUID       { return t.id }
func (t Task) WorkspaceID() uuid.UUID { return t.workspaceID }
func (t Task) Title() string       { return t.title }
func (t Task) Status() TaskStatus  { return t.status }
func (t Task) IsArchived() bool    { return t.archivedAt != nil }

// No setters. Mutations return a new Task:
func (t Task) Archive() (Task, error) {
    if t.archivedAt != nil {
        return Task{}, &ValidationError{Field: "status", Message: "task is already archived"}
    }
    archived := t
    now := time.Now()
    archived.archivedAt = &now
    return archived, nil
}

func (t Task) Reassign(to *uuid.UUID) (Task, error) {
    if to != nil && *to == *t.assigneeID {
        return Task{}, &ValidationError{Field: "assignee_id", Message: "no change"}
    }
    updated := t
    updated.assigneeID = to
    return updated, nil
}
```

The repository layer receives tasks from the database and constructs domain instances using
`NewTask`. The service layer receives tasks from the repository and calls mutation methods
like `Archive()` or `Reassign()`. Each mutation returns a new instance. The service then
persists the mutated instance back to the repository.

### Trade-offs and Constraints  [SENIOR]

Go's lack of language-level immutability enforcement means this discipline is maintained
by code review, not by the compiler. A careless engineer can add a `SetTitle(title string)`
method and break the contract. Meridian's linter flags any method on a domain type that
takes a receiver of type `*Task` and modifies a field (the check is `receiverMutatesField`
and is implemented as a custom ESLint rule for frontend domain types, and a golangci-lint
plugin for backend).

The other cost is API friction: callers must be aware that mutations return new instances.
Without this awareness, a caller might write:

```go
// Wrong: mutation result is discarded
task.Archive()
// task is unchanged; Archive() returned a new instance
```

Instead of:

```go
// Correct: assign the mutated instance
task, err := task.Archive()
```

Meridian's documentation and examples emphasize this pattern. Tests that violate it are
flagged by the code-reviewer as HIGH (misunderstanding of the domain API).

### Example (Meridian)

In `service/task.go`, when archiving a task:

```go
func (s *TaskService) ArchiveTask(ctx context.Context, taskID uuid.UUID, callerID uuid.UUID) error {
    // Retrieve the immutable task
    task, err := s.tasks.Get(ctx, taskID)
    if err != nil {
        return err
    }

    // Authorization check
    if task.WorkspaceID != s.getMemberWorkspace(callerID) {
        return &domain.AuthorizationError{Action: "archive", Resource: "task"}
    }

    // Mutation: returns a new Task, does not modify the original
    archivedTask, err := task.Archive()
    if err != nil {
        return err
    }

    // Persist the mutated instance
    if err := s.tasks.Update(ctx, archivedTask.ID(), archivedTask); err != nil {
        return err
    }

    return nil
}
```

The task retrieved from the repository is immutable. The mutation creates a new task
instance. The new instance is persisted. If the persistence fails, the original task is
unchanged and can be retried or logged.

### Related Sections

- [See data-modeling → Tasks, Assignments, and Workspaces](./data-modeling.md#tasks-assignments-and-workspaces-the-core-aggregate)
  for how immutability is modeled at the persistence layer.
- [See testing-discipline → Fixtures Are Test-Local, Never Shared Mutable State](./testing-discipline.md#fixtures-are-test-local-never-shared-mutable-state)
  for how immutability simplifies test setup.

---

## Comment Policy: "Why" Not "What"  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

Code comments explain intent, not syntax. Good comments answer "why is this the way it is?"
Bad comments narrate what the code does — which the code itself already states more
precisely.

```go
// BAD: comment restates the code
var count int
// count is a counter
count++  // increment count

// GOOD: comment explains the decision
var count int
// count tracks the number of retries; capped at 3 to avoid infinite loops
count++
```

The bad comment is noise. Readers who understand Go already know `count++` increments.
The good comment answers a question a reader might have: "why is there a counter here?"

### Idiomatic Variation  [MID]

Meridian follows a single exception: **exported public functions and types must have godoc
comments** (Go's documentation format). Godoc comments are machine-readable and appear in
generated documentation. They are not optional.

```go
// TaskService orchestrates task operations and enforces authorization.
// It is the application's service layer for task-related business logic.
type TaskService struct { ... }

// ArchiveTask marks a task as archived if the caller is authorized.
// Returns an AuthorizationError if the caller is not a workspace member.
// Returns a ValidationError if the task is already archived.
func (s *TaskService) ArchiveTask(ctx context.Context, taskID, callerID uuid.UUID) error { ... }
```

Godoc comments describe the contract: what the function does, what errors it may return,
and what the caller must know. These are public API documentation.

For non-exported (private) functions and for local variables, comments explain the "why"
of non-obvious decisions. If the code is unclear without a comment, that is often a signal
to rename a variable or extract a function rather than add a comment.

```go
// BAD: comment because the code is unclear
if days > 30 {
    // delete old logs
    deleteOldLogs()
}

// GOOD: the variable name and function name are self-documenting
if daysOld > 30 {
    deleteLogsOlderThan(30 * time.Hour * 24)
}

// GOOD: if a "why" comment is needed, explain the business rule
// Tasks with no updates for 90 days are auto-archived per the retention policy.
// See https://internal.meridian.app/docs/data-retention
if daysUnmodified > 90 {
    archiveTasksSilently(workspace.ID)
}
```

### Trade-offs and Constraints  [SENIOR]

The "why not what" rule requires discipline. When code is unclear, the temptation is to
add a comment instead of refactoring. Meridian's code-reviewer flags comments that narrate
the code as MEDIUM ("rename the function or variable instead"). Over time, this pressure
drives better naming.

The cost is that junior developers sometimes under-comment because they assume the reader
understands the code. A godoc comment is mandatory; a "why" comment is encouraged when the
decision is non-obvious. The distinction requires judgment.

### Example (Meridian)

From `service/task.go`:

```go
// TaskService.resolveConflict removes duplicate task assignments.
// It is called when a task is re-assigned while an assignment is still pending,
// a race condition that can occur during high-load periods.
func (s *TaskService) resolveConflict(ctx context.Context, taskID, userID uuid.UUID) error {
    // Fetch current assignments to check for conflicts
    assignments, err := s.tasks.ListAssignees(ctx, taskID)
    if err != nil {
        return err
    }

    // If the user is already assigned, return early (no conflict to resolve)
    for _, a := range assignments {
        if a.UserID == userID {
            return nil
        }
    }

    // Multiple assignments to the same user are only possible if two concurrent
    // requests both passed the existence check before either persisted. Remove duplicates.
    return s.tasks.RemoveDuplicateAssignments(ctx, taskID, userID)
}
```

The godoc comment (the first paragraph) explains what the method does and why it exists.
The inline comments explain non-obvious control flow. The comment above the duplicate
removal explains the business context (race condition, not a logic bug).

### Related Sections

- [See review-taste → Naming Smells](./review-taste.md#naming-smells)
  for how reviewers evaluate comment quality.
- [See documentation-craft → Comment Policy in Code](./documentation-craft.md#comment-policy-in-code-why-not-what)
  for the Go-specific conventions Meridian follows.

---

## Naming Patterns: Receivers, Booleans, and Acronyms  [MID]

### First-Principles Explanation  [JUNIOR]

Naming is a form of documentation. A well-chosen name tells the reader what a value represents
without requiring a comment. Poorly chosen names create confusion and require comments to
clarify.

In function signatures, consistency in naming makes code predictable:

```go
// Consistent receiver names make the pattern learnable
func (t Task) Archive() (Task, error)
func (s TaskService) ArchiveTask(...) error
func (u User) IsActive() bool

// Boolean names use predicates to signal true/false clearly
func (t Task) IsArchived() bool
func (s Task) HasDueDate() bool
func (u User) CanEditWorkspace(wid uuid.UUID) bool
```

### Idiomatic Variation  [MID]

Meridian follows three naming conventions consistently across the codebase:

**Receiver names:** One letter, derived from the type name.
- `(t *Task)` for Task methods
- `(s *Service)` for Service methods
- `(u *User)` for User methods
- `(h *Handler)` for Handler methods

This is Go convention and is enforced by `go fmt`. The one-letter receiver is terse but
unambiguous because the type is visible in the method signature.

**Boolean predicates:** Always begin with `is`, `has`, `can`, or `should`.
- `IsArchived()` — state
- `HasAssignee()` — presence
- `CanEditWorkspace(wid)` — capability
- `ShouldNotify()` — conditional logic

Never name a boolean `Active` or `Complete` (state is unclear) or `Check` (sounds like an
imperative action, not a query).

**Acronyms:** Meridian uses contrarian casing for common acronyms.
- `URL` not `Url` (all-caps acronyms, matching the HTTP spec and common English)
- `ID` not `Id`
- `UUID` not `Uuid`
- `HTTP` not `Http`

This breaks Go's usual convention (`HTTPHandler` would be `HttpHandler` in idiomatic Go),
but Meridian chose it because the rest of the industry uses all-caps acronyms. The
trade-off is consistency with industry documentation over consistency with Go lint rules.
(Meridian's linter is configured to suppress the acronym-casing check.)

### Trade-offs and Constraints  [SENIOR]

Receiver names are a style choice with no functional impact. `(t Task)` vs. `(task Task)`
is a matter of convention. Go's community chose one-letter receivers for brevity; Meridian
inherited this choice from Go idiom.

The boolean naming convention can feel verbose: `if user.CanEditWorkspace(...)` is longer
than `if user.CanEdit(...)`, but the full name clarifies the scope of the permission. The
cost is verbosity; the benefit is unambiguous permission checks.

The acronym casing breaks Go's `go vet` rules (`ST1005: incorrect capitalization of "URL"`).
Meridian's linter disables this check globally. When new developers inherit Meridian's
codebase, they must learn that `URL` is intentional, not a style violation.

### Example (Meridian)

From `domain/task.go`:

```go
type Task struct {
    id          uuid.UUID
    url         string  // Meridian uses URL, not Url, to match HTTP spec
    status      TaskStatus
    archivedAt  *time.Time
}

// Receiver: one letter (t) derived from type (Task)
func (t Task) ID() uuid.UUID { return t.id }

// Boolean predicates: is/has/can
func (t Task) IsArchived() bool { return t.archivedAt != nil }
func (t Task) HasDueDate() bool { return t.dueDate != nil }

// Capability check: can/should pattern
func (t Task) CanBeAssignedBy(user User) bool {
    return !t.IsArchived() && user.CanEditWorkspace(t.workspaceID)
}
```

From `handler/task.go`:

```go
// Receiver: one letter (h) derived from type (TaskHandler)
type TaskHandler struct { ... }

func (h *TaskHandler) GetTask(c *gin.Context) { ... }
func (h *TaskHandler) CreateTask(c *gin.Context) { ... }

// Error variables always named 'err', not 'e' or 'error_value'
if err := h.svc.GetTask(...); err != nil {
    return err
}
```

### Related Sections

- [See ecosystem-fluency → Go Interface Naming Conventions](./ecosystem-fluency.md#go-interface-naming-conventions)
  for how Meridian's choices relate to broader Go idiom.
- [See review-taste → Naming Smells](./review-taste.md#naming-smells)
  for how reviewers evaluate names in code review.

---

## Prior Understanding: Deep Nesting Was Standard  [JUNIOR]

### Prior Understanding (revised 2026-03-15)

In Meridian's first month of development (pre-2026-03-01), service methods used deeply
nested conditional blocks to check authorization, validate input, and then execute business
logic:

```go
// Original style: deeply nested conditionals
func (s *TaskService) CreateTask(ctx context.Context, req CreateTaskRequest, callerID uuid.UUID) (Task, error) {
    if req.Title != "" {
        if len(req.Title) <= 255 {
            workspace, err := s.getWorkspace(callerID)
            if err == nil {
                task, err := s.tasks.Create(ctx, workspace.ID, req.Title)
                if err == nil {
                    return task, nil
                } else {
                    return Task{}, err
                }
            } else {
                return Task{}, fmt.Errorf("workspace error: %w", err)
            }
        } else {
            return Task{}, &ValidationError{Field: "title", Message: "title too long"}
        }
    } else {
        return Task{}, &ValidationError{Field: "title", Message: "title is required"}
    }
}
```

This style worked and the methods functioned correctly. However, during a security code
review in early March, a critical access-control bug was found in a similar method:

```go
// Security issue from original nested code
func (s *TaskService) DeleteTask(ctx context.Context, taskID uuid.UUID, callerID uuid.UUID) error {
    task, err := s.tasks.Get(ctx, taskID)
    if err == nil {
        if task.Status != Archived {
            // Nested deep: authorization check is 3 levels down
            if s.isOwner(task, callerID) {
                return s.tasks.Delete(ctx, taskID)
            } else {
                return ErrUnauthorized
            }
        } else {
            return ErrAlreadyArchived
        }
    } else {
        return ErrNotFound
    }
}
```

The reviewer missed the authorization check during the first pass because it was nested
6 levels deep, below the resource-existence and status checks. The bug could have allowed
a user to delete a task belonging to another workspace.

**Corrected understanding:**

Early returns (guard clauses) flatten this structure and make authorization checks visible
at the function entry point, where reviewers look first. The corrected style places all
guards at the top:

```go
// Corrected style: early returns, guards at the top
func (s *TaskService) DeleteTask(ctx context.Context, taskID uuid.UUID, callerID uuid.UUID) error {
    task, err := s.tasks.Get(ctx, taskID)
    if err != nil {
        return err
    }
    if task.Status == Archived {
        return &domain.ValidationError{Field: "status", Message: "archived tasks cannot be deleted"}
    }
    if !s.isOwner(task, callerID) {
        return &domain.AuthorizationError{Action: "delete", Resource: "task"}
    }

    // Main logic: now at the top level, after all guards
    return s.tasks.Delete(ctx, taskID)
}
```

The authorization check is now visible immediately after the resource-existence check —
at the level a reviewer scans first. This is not just a style preference; it is a security
pattern. Meridian's linter was updated post-incident to enforce early returns in service
methods, and the code-reviewer now checks that authorization guards are not nested deeper
than one level.

### Related Sections

- [See implementation-patterns → Early Returns and Guard Clauses](#early-returns-and-guard-clauses)
  for the corrected pattern and its justification.
- [See security-mindset → Authorization: Workspace RBAC + Task-Level ABAC](./security-mindset.md#authorization-workspace-rbac--task-level-abac)
  for the security implications of this refactoring.
- [See review-taste → The 2000-Line Refactoring PR](./review-taste.md#the-2000-line-refactoring-pr)
  for the full incident postmortem.

---

## Coach Illustration

> **Illustrative only.** The following is a worked example of how the two coaching styles
> differ for a task in this domain. It is not part of the live agent contract. Actual
> agent behavior is governed by the style files at
> `.claude/skills/learn/coach-styles/`.

**Scenario:** A learner is writing a service method to update a task and asks where the
authorization check should go and how to structure the error handling.

**`default` style** — The agent provides the complete implementation with guard clauses at
the top, immutability discipline (mutation returns a new instance), and proper error
propagation. The handler that calls this service is written as a thin translator. The
agent appends `## Learning:` trailers explaining early returns, immutability, and error
boundary translation.

**`hints` style** — The agent scaffolds the method signature and the initial guard clause
(resource existence check), then emits:

```
## Coach: hint
Step 1: Add authorization guard (check caller is workspace member and task owner).
Step 2: Call the mutation method on the task (Task.Update returns a new Task).
Step 3: Persist the mutated task via repository.
Pattern: Guard clauses (early returns); immutability (mutations return new instances).
Rationale: Guards at the top are reviewable — no buried authorization checks. Immutability
prevents the service from leaking mutable state to callers; mutations are explicit.
```

The learner fills in the authorization guard, calls the mutation method, and handles errors.
On the next turn, the agent responds to any errors without re-writing the scaffold.
