---
domain: review-taste
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: code-reviewer
contributing-agents: [code-reviewer]
---

> **Read-only reference.** This file is shipped with the ECC Base Template as a worked
> example to illustrate what a populated knowledge file looks like after many sessions on
> a real project. It is **not** your knowledge file. Your own knowledge file lives at
> `.claude/learn/knowledge/review-taste.md` and starts empty until agents enrich it during real
> work. Agents never read, cite, or write under `.claude/meta/references/examples/` — this tree is
> for human readers only. See [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md)
> for the design rationale.

> This file's home in the knowledge pillar is `.claude/learn/knowledge/review-taste.md`.

---

## How to Read This File

Level markers indicate the intended audience for each section:
- `[JUNIOR]` — first-principles explanation; assumes no prior exposure
- `[MID]` — non-obvious idiomatic application in this stack
- `[SENIOR]` — non-default trade-off evaluation; names what is given up

---

## The Severity Ladder  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

A code review finding without a severity label is noise. The reviewer sees a problem; the
author sees a comment. Without a shared scale, the author cannot distinguish "this will
cause data loss" from "I would have named this differently." Both appear as review
comments. One is a merge-blocker. The other is optional polish.

A severity ladder assigns every finding to a tier. The tier determines what must happen
before the PR can be merged, what must happen before the feature ships, and what is left
to the author's judgment. Meridian uses four tiers:

| Severity | What it means | Action required |
|----------|---------------|-----------------|
| **CRITICAL** | Security vulnerability, data loss risk, or crash | Must fix before merge |
| **HIGH** | Bug or significant quality issue | Should fix before merge |
| **MEDIUM** | Maintainability concern, missing test for a critical path | Consider fixing |
| **LOW** | Style or minor suggestion | Optional |

The levels do not soften with context. A CRITICAL finding in a one-line PR is still
CRITICAL. A CRITICAL finding in code authored by a senior engineer is still CRITICAL. The
label describes the consequence of the problem, not the likelihood that the author will
accept the feedback. See [preamble §4](../../../../learn/preamble.md) for the explicit rule:
severity labels must not be softened by level.

### Idiomatic Variation  [MID]

Meridian applies the ladder consistently. These illustrative scenarios show how each level
is applied in practice.

**CRITICAL scenario — missing authorization check.**

A PR adds a `PATCH /v1/tasks/:task_id` endpoint and the handler calls `svc.UpdateTask`
directly without checking workspace membership. Any authenticated user can update any
task in the system regardless of which workspace they belong to.

The reviewer flags this finding:

```
CRITICAL: handler/task.go UpdateTask — no authorization check before svc.UpdateTask.
Any authenticated caller can update any task. Service layer must verify that
callerID is a member of task.WorkspaceID before applying the update.
Fix: add s.workspaces.IsMember(ctx, task.WorkspaceID, callerID) check in
service/task.go:UpdateTask, returning domain.AuthorizationError if false.
```

This is CRITICAL because it exposes every Meridian customer's tasks to every other
Meridian customer. The PR cannot merge. See
[security-mindset → Authorization: Workspace RBAC + Task-Level ABAC](./security-mindset.md#authorization-workspace-rbac--task-level-abac)
for the workspace membership check pattern.

**HIGH scenario — incorrect error propagation in a repository method.**

A repository method returns a raw `*pq.Error` instead of translating it through
`translatePostgresError`. The handler's `writeError` does not recognize `*pq.Error` and
returns HTTP 500. Callers cannot distinguish a genuine server error from a constraint
violation they could handle.

```
HIGH: repository/task.go Create — returns raw *pq.Error on unique constraint violation.
The handler cannot classify this as 409; the caller receives 500 instead of a
meaningful error code. Wrap with translatePostgresError(err) before returning.
```

This is HIGH because it is a bug — the contract between the repository and the service
layer is violated — but it does not expose data or crash the process. The PR should fix
it before merge. See
[error-handling → Boundary Translation](./error-handling.md#boundary-translation-postgres-to-domain-errors)
for the translation pattern Meridian enforces.

**MEDIUM scenario — missing test for a non-trivial code path.**

A PR implements task archival and covers the happy path in tests. The case where the
caller tries to archive an already-archived task is reachable in production (a race
condition between two users) but untested.

```
MEDIUM: service/task_test.go — no test for archive-idempotency (archiving an already-
archived task). The service path is reachable. Consider adding a test that verifies the
service returns domain.ErrConflict or is idempotent, whichever the product decision is.
```

This is MEDIUM, not HIGH, because the current code does not actively misbehave — the
branch exists and returns an error — but the behavior is unverified. The team may merge
and address it in a follow-up. See
[testing-discipline → The Meridian Test Pyramid](./testing-discipline.md#the-meridian-test-pyramid)
for when untested paths escalate to HIGH.

**LOW scenario — naming that could be more precise.**

A function named `processData` appears in a utility file. It reads task status counts
from the database and formats them for a dashboard widget.

```
LOW: internal/util/process.go processData — the name does not communicate intent.
Suggestion: FormatTaskStatusCounts or BuildDashboardSummary.
```

This is LOW: the code is correct and readable on inspection. The name is a smell, not a
defect. The reviewer raises it; the author decides whether to rename before merge or in a
subsequent cleanup.

### Trade-offs and Constraints  [SENIOR]

The risk in a consistent severity ladder is label inflation: if reviewers file HIGH for
every imperfection, authors stop distinguishing HIGH from MEDIUM and the signal degrades.
Meridian's practice: when a finding could be MEDIUM or HIGH, prefer MEDIUM unless the
consequence of shipping the code is a user-visible bug or a violation of a documented
contract. A missed HIGH is more costly than an incorrect downgrade to MEDIUM.

The risk in the other direction is under-escalation from social pressure. Meridian's PR
policy requires two approvals for changes to the authorization layer regardless of
seniority, which reduces the temptation to soften labels on security-sensitive code.

---

## Defensive Programming as Antipattern: Catch-Everything Recovery  [MID]

### First-Principles Explanation  [JUNIOR]

Defensive programming is the practice of writing code that anticipates unexpected
conditions. In Go, this often takes the form of wrapping large code sections in
`recover()` calls to prevent a `panic` from crashing the process. The intent is to make
the system more resilient. The effect, when applied carelessly, is the opposite.

A `recover()` call that catches every panic and silently returns a generic error hides the
evidence that a programming invariant was violated. The process continues running in a
state that the author declared impossible. The system appears healthy; the underlying data
may be corrupted. The panic was a signal. Recovering from it without logging the condition
and halting the affected operation discards the signal.

### Idiomatic Variation  [MID]

Meridian encountered this pattern during a feature that introduced bulk task assignment.
The service method looped over a list of user IDs, called the repository's `AddAssignee`
method for each, and wrapped the entire loop in a deferred `recover`:

```go
// service/task.go — antipattern: catch-everything recover
func (s *TaskService) BulkAssign(ctx context.Context, taskID uuid.UUID, userIDs []uuid.UUID) error {
    defer func() {
        if r := recover(); r != nil {
            log.Warn("recovered panic in BulkAssign", "recover", r)
        }
    }()

    for _, uid := range userIDs {
        if err := s.tasks.AddAssignee(ctx, taskID, uid); err != nil {
            log.Warn("failed to add assignee", "user_id", uid, "err", err)
            // continue — do not fail the whole operation for one user
        }
    }
    return nil
}
```

The deferred `recover` was added because a previous panic in this path had crashed the
server. The correct response was to find and fix the panic's cause. Instead, the team
wrapped it and moved on. Two weeks later, a data integrity check revealed that
approximately 400 task assignments had been silently skipped — `AddAssignee` was
panicking on a nil pointer in the idempotency key logic, the `recover` was catching it
and returning nil, and the caller assumed the assignments had succeeded. Meridian's billing
code charges per-seat based on assignment records; 400 silently skipped assignments meant
incorrect seat counts for the affected workspaces.

The reviewer caught the pattern:

```
CRITICAL: service/task.go BulkAssign — deferred recover() swallows panics and
returns nil, masking errors as success. The caller cannot distinguish
"all assignments succeeded" from "assignments silently failed." If a panic
indicates a programming error, it must be surfaced, not swallowed.
Fix: remove the recover(). Let the panic crash this goroutine. The root
cause of the panic (nil pointer in idempotency key logic) must be fixed
separately. Use explicit error returns, not panic recovery, for operational
errors.
```

The finding is CRITICAL because recovering from the panic returned `nil` — indicating
success — while the operation had partially failed. The caller's contract ("nil means all
assignments were recorded") was violated silently.

### Trade-offs and Constraints  [SENIOR]

There is one legitimate use of `recover` in Meridian: Gin's built-in recovery middleware
wraps each HTTP handler invocation and converts panics into HTTP 500 responses. This is
acceptable because it operates at the topmost layer and logs the panic before converting
it. It is a safety net, not a design strategy. The logged panic is visible in monitoring
and triggers an alert. The difference between a safety-net `recover` and a swallowing
`recover` is what happens to the error information: a safety-net `recover` preserves and
surfaces it; a swallowing `recover` discards it.

See
[error-handling → Panic Usage Policy](./error-handling.md#panic-usage-policy) for the
full policy on when panics are appropriate in Meridian's Go service.

---

## Naming Smells  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

A function or variable name is a claim. `isTaskArchived` claims to return a boolean
indicating whether a task has been archived. `processData` claims to process some data.
The first claim is specific enough to verify: the reader can check the return type and
the implementation. The second claim is so broad that any implementation satisfies it.

When a name is too broad to be verifiable, the reader is forced to read the implementation
to understand what the code does. The name has failed its job. Reviewers learn to treat
certain name patterns as smells — not bugs, but signals that the code needs a second look.

### Idiomatic Variation  [MID]

Meridian's review practice flags these naming patterns:

**Generic function names.** `processData`, `handleRequest`, `doWork`, `run`, `execute`,
`manage`. These names are red flags. In review, the question is not "what should this be
called?" but "what does this function actually do?" The answer to that question is the
correct name.

A PR review scenario:

```go
// internal/reporting/report.go — flagged in review
func processData(tasks []domain.Task) map[string]int {
    result := make(map[string]int)
    for _, t := range tasks {
        result[string(t.Status)]++
    }
    return result
}
```

Review comment:

```
LOW: reporting/report.go processData — "process" communicates nothing.
This function counts tasks by status. Rename to CountByStatus or GroupTasksByStatus.
The caller receiving map[string]int will read much more clearly as
statusCounts := CountByStatus(tasks).
```

**Boolean names without a predicate prefix.** A boolean named `flag`, `status`, `check`,
`value`, or `result` tells the reader nothing. Meridian's convention: booleans use
`is`, `has`, `should`, or `can` prefixes. `isArchived`, `hasPendingAssignee`,
`shouldNotify` — these read as propositions. `flag` reads as nothing.

```go
// service/task.go — flagged in review
var flag bool
for _, assignee := range assignees {
    if assignee.ID == callerID {
        flag = true
    }
}
if !flag {
    return &domain.AuthorizationError{...}
}
```

Review comment:

```
MEDIUM: service/task.go — bool named 'flag' does not communicate what is being
checked. Rename to isCallerAssigned or callerIsAssignee. The loop condition
and the authorization check will read correctly without needing to trace
the variable's assignment.
```

### Trade-offs and Constraints  [SENIOR]

Naming review comments have the lowest ROI in the reviewer's attention budget if left as
LOW findings without rationale. Authors who receive "rename this" without a reason tend to
dismiss the finding. The convention at Meridian is that any naming comment states what the
reader is forced to do without a better name: "the caller must read the body to understand
the return value." This reframes the comment from personal preference to user-experience
consequence. That distinction determines whether the author treats the comment as
subjective taste or as a real readability problem.

See
[implementation-patterns → Naming Patterns: Receivers, Booleans, and Acronyms](./implementation-patterns.md#naming-patterns-receivers-booleans-and-acronyms)
for the project-level naming rules that inform these review judgments.

---

## Abstraction With One Caller  [MID]

### First-Principles Explanation  [JUNIOR]

Abstraction is the practice of grouping repeated or related logic behind a named
boundary — a function, a type, an interface — so that the caller does not need to know
the details. When used at the right time, abstraction reduces duplication and clarifies
intent. When introduced too early, it adds indirection without reducing complexity.

The smell that signals premature abstraction: a function, type, or interface that has
exactly one caller in the codebase. A single caller cannot reveal whether the abstraction
captures the right boundary. It may have been written in anticipation of a second caller
that never arrives. The abstraction now imposes a layer of indirection on every reader
without paying any of the benefits (reuse, replaceability, testability) that justify it.

### Idiomatic Variation  [MID]

Meridian encountered this in a refactoring PR. A developer noticed that task creation and
task update both called `validateTaskTitle`. They extracted a `TitleValidator` interface
with a `Validate(title string) error` method and a concrete `DefaultTitleValidator` struct.
The interface had exactly one implementation and two callers.

The reviewer's comment:

```
MEDIUM: service/validation.go TitleValidator — this interface has one
implementation and two callers, both inside service/task.go. The interface
adds a layer of indirection (type definition, struct, constructor, method)
without enabling testing via a mock (both callers are tested directly) or
swapping (there is no foreseeable alternative implementation).

The two callsites can share a plain function:

  func validateTaskTitle(title string) error { ... }

When a second distinct implementation appears — for example, a workspace-
specific title validator with different length limits — the interface is
the right tool. Introduce it at that forcing function, not before.
```

The guidance is not "never use interfaces." It is "introduce an interface when the
interface enables something — a test double, a second implementation, a stable API for
external callers — that a plain function does not." See
[architecture → Hexagonal Split](./architecture.md#hexagonal-split) for where Meridian
does use interfaces: at the layer boundaries between handler, service, and repository.
Those interfaces have multiple implementations (production and test doubles). The `domain.TaskRepository` interface is not premature; it is load-bearing.

The decision rule Meridian applies: before introducing an abstraction, name the second
caller or the second implementation. If naming either requires speculative future
scenarios, the abstraction is premature.

### Trade-offs and Constraints  [SENIOR]

The one-caller heuristic has a genuine exception: abstraction for testability. A function
that writes to the database or calls an external API cannot be unit-tested without an
abstraction for injection. An interface with one production implementation and one
test-double is not premature — the second "implementation" is the mock. The forcing
function is present in the test layer, not the production layer.

Meridian's code-reviewer flags one-caller abstractions with a single question: "Is this
needed for testability?" If yes, the finding does not apply. If no, it stands as MEDIUM.

---

## The 2000-Line Refactoring PR  [SENIOR]

### First-Principles Explanation  [JUNIOR]

A refactoring PR reorganizes code without changing behavior. No new features. No bug
fixes. Only restructuring. The implicit contract of a refactoring PR is that every test
passes before and after, and that no behavioral change has been introduced. Reviewers tend
to give refactoring PRs lighter scrutiny because "nothing changed." This is a mistake
that correlates strongly with the PR size.

A 2000-line refactoring PR is not a refactoring; it is a rewrite with refactoring labels.
At that size, the reviewer cannot hold the full context of what each changed line used to
do and now does. Behavioral changes are easy to introduce and easy to miss. Tests may
still pass because the tests were also rewritten as part of the refactoring.

### Idiomatic Variation  [MID]

Meridian's PR policy states: a PR labeled "refactor" may touch at most 400 net lines of
Go code (excluding test files). PRs that exceed this limit must be split into sequential
commits where each commit is independently green on the test suite.

The policy was established after a 2,000-line "rename and reorganize" PR introduced a
behavioral change in task permission checks. The original `canArchive` method checked
workspace ownership. After the refactoring, the extracted `ArchivePermission` struct
omitted the ownership check and only checked task status. Both the old and new
implementations passed the existing tests because the test doubles had been refactored
alongside the production code and the mock's behavior was simplified in the process.

The bug was caught two days after merge by a customer support ticket. Archiving a task
required only that the task be in `active` status; workspace membership was no longer
required. Any authenticated user could archive any active task.

The reviewer had flagged the PR size:

```
HIGH: This PR touches 2,134 lines across 23 files labeled as "refactor only."
A refactoring of this size cannot be reviewed for behavioral preservation.
Request: split into a sequence of smaller PRs, each independently green.
Suggested sequence:
  1. Rename + move files (no logic change) — ~300 lines
  2. Extract ArchivePermission — ~200 lines, must include a test that
     asserts the workspace membership check is preserved
  3. Wire the new type into the service — ~100 lines
```

The author merged without addressing the finding (one of the approvers did not check
whether the HIGH had been resolved). The permission bug was the result. Meridian's process
now requires that HIGH findings be resolved or explicitly deferred before the second
approval is granted. See
[testing-discipline → The Meridian Test Pyramid](./testing-discipline.md#the-meridian-test-pyramid)
for how the test suite was strengthened afterward to prevent test-double drift.

### Trade-offs and Constraints  [SENIOR]

The 400-line limit creates friction when a large rename is genuinely behavior-preserving.
Splitting such a PR involves coordinating branch dependencies and intermediate CI runs.
Meridian accepts this cost because the cost of a missed behavioral change in the
authorization layer is higher. The limit is a floor, not an aspiration.

The exception: automated refactorings applied by a tool across the entire codebase with
no manual edits. A 3000-line PR that is the output of `goimports -l ./...` or a
mechanical `sed` rename is reviewable because the reviewer can verify the tool's behavior
rather than reading every changed line. The key criterion is mechanical verifiability.
Human-authored refactorings at this scale are not verifiable that way.

---

## Prior Understanding: Every Style Nit Is a Review Comment  [JUNIOR]

### Prior Understanding (revised 2026-01-14)

> The original Meridian review practice required reviewers to call out every style
> deviation in PR comments, including formatting, import ordering, and variable naming
> conventions. The intent was to enforce consistency. The effect was that PRs accumulated
> 30–50 LOW comments on a 200-line feature addition, most of which the author addressed
> mechanically without reading the rationale.

> Original practice: "Flag every deviation from the style guide in review comments,
> regardless of severity."

**Corrected understanding:**

Linters and formatters exist to enforce mechanical style rules so that reviewers do not
have to. When a CI check runs `gofmt`, `golangci-lint`, and `goimports` on every PR and
fails the build on any violation, a human reviewer who re-raises those findings in a
comment is duplicating the linter's work and occupying the review queue with information
the author already has.

Meridian revised its practice: the reviewer's attention is reserved for findings that
linters cannot catch — design issues, naming that is technically valid but misleading,
missing tests for observable behavior, premature abstraction, copy-paste logic, and
severity-escalating patterns. Style nits that the linter already enforces are not
repeated in human review comments.

The practical consequence: average review comment count on a 200-line PR dropped from
~35 to ~8. Remaining comments averaged higher signal: design-level observations, MEDIUM
and HIGH findings, and cross-domain notes (authorization, error handling). Author
response rate on those comments improved.

The underlying principle: reviewer attention is finite. Spending it on findings a
machine already reported reduces the attention available for findings only a human can
make. Trusting the linter for style is not a lower bar — it is a higher bar for the
human reviewer.

### Related Sections

- [See review-taste → Naming Smells](#naming-smells) for the naming findings that do
  remain in scope for human reviewers (where the linter cannot detect meaning, only syntax).
- [See testing-discipline → The Meridian Test Pyramid](./testing-discipline.md#the-meridian-test-pyramid)
  for the untested-path scenarios that belong in human review, not in the linter.

---

### Coach Illustration (default vs. review-only)

> **Illustrative only.** The following is a worked example of how the two coaching styles
> differ for a task in this domain. It is not part of the live agent contract. Actual
> agent behavior is governed by the style files at
> `.claude/skills/learn/coach-styles/`.

**Scenario:** A learner submits a PR that adds a bulk-cancel endpoint for tasks.
The service method catches all errors in a `recover()` block and logs them as warnings.
The reviewer agent is invoked to review the diff.

**`default` style** — The agent reviews the full diff and produces a complete findings
report. It classifies the `recover()` block as CRITICAL (masks operation failures as
success, same pattern as the BulkAssign incident), the missing authorization check as
CRITICAL (any authenticated user can cancel any task), the boolean named `done` as LOW
(rename to `isCancelled`), and the absence of a test for partial-cancellation failure as
MEDIUM. The report lists all four findings with severity, location, and suggested fix. The
agent appends `## Learning:` trailers explaining the catch-everything antipattern and
the severity ladder.

**`review-only` style** — When the learner writes the service method and submits it, the
agent declines to write the handler or the tests. It responds:

```
## Coach: review

The active coach style is review-only. Production code submission is not available.
Reviewing the submitted service method:

CRITICAL [service/task.go:BulkCancel]: deferred recover() returns nil on panic,
masking partial failures as success. Remove the recover(); fix the underlying
nil-pointer dereference directly.

CRITICAL [service/task.go:BulkCancel]: no workspace membership check before
modifying tasks. Add s.workspaces.IsMember(ctx, ...) before the loop.

MEDIUM [service/task_test.go]: no test for the case where one task in the
batch cannot be cancelled (wrong status). The expected behavior (fail fast vs.
partial success) should be documented in a test.

LOW [service/task.go:39]: bool named 'done' — rename to isCancelled.
```

`<!-- coach:review-only stop -->`

The learner fixes the CRITICAL findings and resubmits. The agent reviews the updated diff,
confirms the authorization check is present, and reports the residual MEDIUM finding.
