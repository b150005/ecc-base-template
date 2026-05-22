---
domain: testing-discipline
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: test-runner
---

> **Read-only reference.** This file is shipped with the ECC Base Template as a worked
> example to illustrate what a populated knowledge file looks like after many sessions on
> a real project. It is **not** your knowledge file. Your own knowledge file lives at
> `.claude/learn/knowledge/testing-discipline.md` and starts empty until agents enrich it during
> real work. Agents never read, cite, or write under `.claude/meta/references/examples/` — this
> tree is for human readers only. See [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md)
> for the design rationale.

---

## How to Read This File

Level markers indicate the intended audience for each section:
- `[JUNIOR]` — first-principles explanation; assumes no prior exposure
- `[MID]` — non-obvious idiomatic application in this stack
- `[SENIOR]` — non-default trade-off evaluation; names what is given up

---

## The Meridian Test Pyramid  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

A test proves a claim about behavior. Different claims require different levels of
evidence, and different levels of evidence cost different amounts of time to gather.

The **test pyramid** encodes this asymmetry. At the base: many fast unit tests — each
proving one function, one method, one module. In the middle: fewer integration tests —
proving that components work together at real system boundaries. At the apex: few E2E
tests — proving that a user can complete a critical flow.

Skipping the middle of the pyramid is tempting. Unit tests and E2E tests feel like they
cover everything. They do not. A unit test proves that a function builds the correct SQL
query string. It cannot prove that PostgreSQL accepts that string, that the result is
deserialized correctly, or that the database index the query relies on exists. An E2E test
proves the UI renders after a button click. It cannot tell you whether the failure was in
the handler, the service, the repository, or the database connection.

Each level proves something the other levels cannot. Skipping a level means deferring
that class of failure to production.

### Idiomatic Variation  [MID]

Meridian's test layers map to tooling as follows:

| Layer | Tool | Scope | Typical run time |
|-------|------|-------|-----------------|
| Unit | Go `testing` package, `testify` | Single function or method, all deps mocked | < 10 ms per test |
| Integration | Go `testing` + real PostgreSQL in Docker via `testcontainers-go` | Repository methods against a real schema | 1–5 s per test |
| E2E | Playwright | Critical user flows through the deployed React frontend | 10–60 s per test |

The integration tests use a real database — not an in-process SQLite or a mock — because
Meridian discovered that SQLite behavior diverged from PostgreSQL on several edge cases
involving constraint violations and timestamp precision. Running against a real Postgres
image is slower but eliminates the divergence entirely.

The E2E suite runs against a staging deployment in CI, not against localhost. This adds
latency but catches environment-specific failures (missing environment variables,
mis-configured CORS) that a localhost run cannot catch.

### Trade-offs and Constraints  [SENIOR]

The cost of a real database in integration tests is CI latency and image pull time. The
Meridian integration suite runs in approximately 4 minutes on a GitHub Actions runner
with the `postgres:16` image pre-cached in the workflow. The decision to accept this cost
was made after a production incident caused by a PostgreSQL constraint that SQLite silently
ignored in tests. The 4-minute overhead per PR is cheaper than a production rollback.

The cost of staging-based E2E tests is flakiness risk when staging is unstable. Meridian
mitigated this by adding a pre-E2E smoke check in the CI workflow that verifies staging
health before running Playwright. If the smoke check fails, the E2E step is skipped and
the PR is flagged for re-run after staging recovers.

### Example (Meridian)

```go
// integration/task_repository_test.go
func TestTaskRepository_Create_ReturnsCreatedTask(t *testing.T) {
    // Arrange
    db := testhelper.MustOpenTestDB(t) // starts postgres container, runs migrations
    repo := repository.NewTaskRepository(db)
    params := domain.CreateTaskParams{
        WorkspaceID: uuid.New(),
        Title:       "Write integration tests",
        AssigneeID:  uuid.New(),
    }

    // Act
    task, err := repo.Create(context.Background(), params)

    // Assert
    require.NoError(t, err)
    assert.Equal(t, params.Title, task.Title)
    assert.NotZero(t, task.ID)
    assert.NotZero(t, task.CreatedAt)
}
```

The `testhelper.MustOpenTestDB` helper starts a fresh Postgres container per test
package (not per test), runs all migrations, and registers a `t.Cleanup` to tear down
the container. Each test function that needs database state creates its own rows.

### Related Sections

- [See error-handling → Boundary Translation](./error-handling.md#boundary-translation-postgres-to-domain-errors)
  for how integration tests surface Postgres constraint errors as domain errors.
- [See architecture → Hexagonal Split](./architecture.md#hexagonal-split) for why
  integration tests target the repository layer specifically and not the service layer.

### Coach Illustration (default vs. hints)

> **Illustrative only.** Not part of the live agent contract. Governed by
> `.claude/skills/learn/coach-styles/`.

**Scenario:** A learner asks the agent to write integration tests for `TaskRepository.Archive`.

**`default` style** — The agent produces the complete test function: arrange (create a
task, verify it is active), act (call `repo.Archive`), assert (task status is `archived`,
`archived_at` timestamp is set). It appends `## Learning:` trailers explaining the
integration-vs-unit choice and why this belongs at the integration layer.

**`hints` style** — The agent writes the test stub skeleton with the Arrange/Act/Assert
sections commented but empty, and emits:

```
## Coach: hint
Step: Arrange a real task row in the test database, then assert the archived_at column is set.
Pattern: Arrange-Act-Assert with testcontainers-go real database.
Rationale: repo.Archive changes a database row; only an integration test against real
Postgres can verify the SQL and the constraint that prevents archiving already-archived tasks.
```

`<!-- coach:hints stop -->`

---

## Fixtures Are Test-Local, Never Shared Mutable State  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

A test fixture is any data or state a test requires before it can exercise the code under
test. The most tempting fixture design is a shared setup: one function that creates the
database state, called before every test in the suite. The shared setup is an anti-pattern
because tests that share state couple silently. Test A may rely on a row that Test B
deletes. Test C may pass only when run after Test A, which happens to create a row Test C
needs but does not declare.

The result is a test suite where tests pass in isolation but fail in certain orderings, or
where a change to Test A's setup breaks Test C without any obvious connection.

The Meridian rule: **every test creates exactly the data it needs and no more**. If two
tests need the same user row, each creates it independently. Verbosity is acceptable; false
coupling is not.

### Idiomatic Variation  [MID]

Meridian uses a builder pattern for test data rather than global fixtures. A builder is a
struct with fluent methods that produce a domain object with sensible defaults, overridable
per test:

```go
// testhelper/builders.go
type TaskBuilder struct {
    title      string
    workspaceID uuid.UUID
    assigneeID  uuid.UUID
    status     domain.TaskStatus
}

func NewTaskBuilder() *TaskBuilder {
    return &TaskBuilder{
        title:      "Default Task Title",
        workspaceID: uuid.New(),
        assigneeID:  uuid.New(),
        status:     domain.TaskStatusActive,
    }
}

func (b *TaskBuilder) WithTitle(title string) *TaskBuilder {
    b.title = title
    return b
}

func (b *TaskBuilder) Build(t *testing.T, db *sql.DB) domain.Task {
    t.Helper()
    // inserts into DB, returns the created task
    task, err := insertTask(db, b.title, b.workspaceID, b.assigneeID, b.status)
    require.NoError(t, err)
    return task
}
```

A test that needs a specific task title calls `NewTaskBuilder().WithTitle("…").Build(t, db)`.
Every test declares its own data. No test depends on another test's side effects.

### Trade-offs and Constraints  [SENIOR]

Builder verbosity is a real cost. A complex scenario with five related entities requires
five builder calls, which is more code than one shared setup. Meridian accepted this cost
after a two-hour debugging session caused by a shared `beforeEach` fixture that
accumulated requirements from five tests that had been written by three different engineers
over six months. The debugging session cost more than the verbosity.

The builder pattern also keeps test helpers in the production package's type system.
Builders use the same domain types as production code. When a domain type changes, the
builder breaks at compile time rather than silently producing stale test data.

### Example (Meridian)

The `NewTaskBuilder()` code above is from Meridian's actual test helper. The alternative
considered was a global `TestDB` variable with a transaction-rollback approach (each test
runs in a transaction that is rolled back at cleanup). The rollback approach was rejected
because it breaks tests that test multi-transaction behavior — specifically, tests for
Meridian's optimistic locking logic, which involves two concurrent transactions and cannot
be tested within a single rolled-back transaction.

### Related Sections

- [See testing-discipline → The Meridian Test Pyramid](#the-meridian-test-pyramid) for
  which test layer the builder pattern is used in.
- [See persistence-strategy → Indexing Strategy on the Tasks Table](./persistence-strategy.md#indexing-strategy-on-the-tasks-table)
  for why test data uses realistic UUIDs rather than sequential integers.

---

## Contract Testing the Slack Integration  [MID]

### First-Principles Explanation  [JUNIOR]

When Meridian sends a task notification to Slack, it makes an HTTP call to Slack's API.
Testing that call with a real Slack workspace in CI is impractical: it requires a real
token, it produces real messages, it is rate-limited, and it depends on Slack's
availability. The alternative — skipping the test entirely — means a Slack integration
bug is found by a user.

**Contract testing** sits between these options. Instead of calling the real Slack API,
the test uses an HTTP mock that asserts on the shape of the outgoing request (the
"contract"). If the real Slack API later changes its contract, the mock does not catch
that — a separate contract test run against Slack's sandbox environment does. Within the
unit test suite, the mock proves that Meridian's code produces the correct request shape
for the documented API.

### Idiomatic Variation  [MID]

Meridian uses `httpmock` (github.com/jarcoal/httpmock) to intercept outgoing HTTP calls
from the Slack client. The mock registers a responder for the specific Slack webhook URL
and asserts on the request body:

```go
// service/notification_test.go
func TestNotificationService_NotifyTaskAssigned_PostsToSlack(t *testing.T) {
    httpmock.Activate()
    defer httpmock.DeactivateAndReset()

    var capturedBody slackMessage
    httpmock.RegisterResponder(
        "POST",
        "https://slack.com/api/chat.postMessage",
        func(req *http.Request) (*http.Response, error) {
            json.NewDecoder(req.Body).Decode(&capturedBody)
            return httpmock.NewStringResponse(200, `{"ok":true}`), nil
        },
    )

    svc := notification.NewService(slackClient, ...)
    err := svc.NotifyTaskAssigned(ctx, task, assignee)

    require.NoError(t, err)
    assert.Equal(t, "#task-alerts", capturedBody.Channel)
    assert.Contains(t, capturedBody.Text, task.Title)
    assert.Equal(t, 1, httpmock.GetTotalCallCount())
}
```

The assertion `httpmock.GetTotalCallCount()` verifies the Slack API was called exactly
once — not zero times (silent failure), not twice (duplicate notification).

### Trade-offs and Constraints  [SENIOR]

An `httpmock`-based contract test proves the outgoing request shape but cannot prove
that Slack will accept the request. Meridian runs a nightly job against Slack's sandbox
environment to verify the actual API contract has not changed. The nightly job is separate
from the unit test suite and does not block PRs; it alerts on failure. This separation is
deliberate: blocking PRs on external API availability would make CI unreliable.

The cost of this approach is that a Slack API change can go undetected until the nightly
run. The business decision: task notifications are important but not mission-critical;
a 24-hour detection window is acceptable. If notifications were mission-critical, the
nightly job would run hourly and alert on PagerDuty.

### Example (Meridian)

See the `httpmock` snippet above. The deduplication key for Slack webhook calls (to
prevent double-sending on retries) is tested separately in an integration test that
exercises the Redis idempotency store — see
[error-handling → Idempotent Retry on Slack Webhook](./error-handling.md#idempotent-retry-on-the-slack-webhook).

### Related Sections

- [See error-handling → Idempotent Retry on Slack Webhook](./error-handling.md#idempotent-retry-on-the-slack-webhook)
  for the retry and deduplication logic that these tests exercise.
- [See api-design → Idempotency Key Handling](./api-design.md#idempotency-key-handling) for
  the broader idempotency pattern across Meridian's inbound webhook endpoints.

---

## Prior Understanding: E2E Coverage Scope  [SENIOR]

### Prior Understanding (revised 2026-02-14)

The original approach (shipped in Meridian's first CI configuration, circa 2025-09) was
to cover the entire user-facing application with Playwright E2E tests: every page, every
interaction, every edge case. The intent was "if it's in the UI, it has an E2E test."

This was revised because:

1. The E2E suite grew to 340 tests and took 47 minutes to run on a GitHub Actions runner.
   PRs sat waiting for CI for nearly an hour. Developer feedback loops collapsed.
2. Approximately 60% of E2E failures were flaky — caused by timing issues, animation
   delays, and test environment instability — rather than real defects. Engineers learned
   to re-run CI rather than investigate failures, defeating the suite's purpose.
3. The business logic being tested in those 340 tests was already covered by unit and
   integration tests. The E2E tests added confidence in the UI rendering and the API
   contract, but not in the business logic.

**Corrected understanding:**

E2E tests cover **critical user paths only** — the flows where a failure would directly
block a user from their primary goal: creating a workspace, assigning a task, viewing the
task board, and the Slack integration confirmation screen. Non-critical flows (profile
settings, notification preferences, billing page) rely on unit and integration tests.

After the scope reduction, the E2E suite has 28 tests and runs in 6 minutes. Flakiness
dropped to under 5% by removing animation-dependent assertions and replacing them with
deterministic `waitForSelector` conditions.

The principle: E2E tests are expensive to write, expensive to maintain, and expensive to
run. Reserve them for the flows where a failure is a user-facing incident, not merely an
inconvenience.

### Related Sections

- [See testing-discipline → The Meridian Test Pyramid](#the-meridian-test-pyramid) for
  the broader test strategy this revised understanding shaped.
- [See operational-awareness → Three-Pillar Observability](./operational-awareness.md#three-pillar-observability-logs-metrics-and-traces)
  for the production incident that prompted the scope reduction.
