---
domain: ecosystem-fluency
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
> `.claude/learn/knowledge/ecosystem-fluency.md` and starts empty until agents enrich it during
> real work. Agents never read, cite, or write under `.claude/meta/references/examples/` — this
> tree is for human readers only. See [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md)
> for the design rationale.
>
> **Knowledge file for this domain:** `.claude/learn/knowledge/ecosystem-fluency.md`

---

## How to Read This File

Level markers indicate the intended audience for each section:
- `[JUNIOR]` — first-principles explanation; assumes no prior exposure
- `[MID]` — non-obvious idiomatic application in this stack
- `[SENIOR]` — non-default trade-off evaluation; names what is given up

---

## Go Stdlib vs. Third-Party: The Meridian Policy  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

Go ships with a large, stable standard library. Many tasks that require a third-party
package in other ecosystems — HTTP serving, JSON encoding, sorting, crypto — have
idiomatic stdlib answers in Go. This creates a decision that every Go project faces early:
for any given problem, reach for `net/http` or for a framework?

The distinction matters because stdlib choices and third-party choices carry different
costs. Stdlib packages are versioned with the Go toolchain, never go unmaintained, and
carry zero import overhead in `go.mod`. Third-party packages add a dependency, introduce
a transitive graph, and must be evaluated for maintenance health and API stability.

The naive answer — "always use stdlib for simplicity" — is correct until it isn't.
Standard `net/http` can serve production traffic, but it provides no routing parameters
(`/tasks/:id`), no middleware chaining, and no JSON binding. Writing those on top of
`net/http` for a project with 20+ routes is rebuilding a framework — a poor use of time
and a source of bugs. Conversely, importing a framework for a five-route internal tool
adds complexity without benefit.

### Idiomatic Variation  [MID]

Meridian's policy is documented in a brief decision record and enforced by code review:

**Use stdlib when:**
- The operation is self-contained and the stdlib API is complete for the use case.
  `encoding/json` for marshaling simple domain structs to the API response satisfies
  this: `json.Marshal(task)` requires no configuration.
- The project would otherwise write a thin wrapper around stdlib that adds no
  abstraction value. `context.WithTimeout` needs no wrapper.
- The package is invoked at a single callsite. A one-off use rarely justifies a
  framework dependency.

**Justify third-party when:**
- The stdlib gap is real and the gap-filling would be maintained hand-rolled code.
  Meridian uses `github.com/gin-gonic/gin` for HTTP routing because path parameters,
  middleware groups, and JSON binding via `ShouldBindJSON` would require ~200 lines of
  boilerplate per service otherwise.
- The third-party package solves a problem class with known edge cases that are easy
  to get wrong. Meridian uses `github.com/jackc/pgx/v5` (pgx) rather than the
  `database/sql` + `lib/pq` pairing because pgx handles PostgreSQL-specific types
  (arrays, UUID, JSONB) natively without the extra scan-adapter layer that `database/sql`
  requires.
- The package is the de-facto standard in the Go community with demonstrated maintenance
  health. `go.uber.org/zap` for structured logging was chosen over a hand-rolled
  `log/slog` wrapper because zap's performance characteristics at high-throughput writes
  are well-documented.

### Trade-offs and Constraints  [SENIOR]

The stdlib-first policy gives up some ergonomics. `encoding/json` does not support
field-level validation, struct tags beyond `json:"-"` and `omitempty`, or streaming
JSONB from Postgres. When those needs arise, the project adds a library (`github.com/go-playground/validator/v10`
for validation) rather than abandoning the stdlib-first default. Each addition is
deliberate, not automatic.

The policy also means Meridian explicitly avoids "kitchen sink" frameworks. A framework
that provides routing, an ORM, a migration tool, a CLI generator, and a test harness
all in one import is convenient initially but creates version coupling: upgrading the
router forces an upgrade across all other framework components simultaneously. Meridian
separates concerns across focused packages instead: gin for routing, pgx for database,
zap for logging, each independently versioned.

The concrete `go.mod` entries for the backend reflect this:

```
require (
    github.com/gin-gonic/gin      v1.9.1
    github.com/jackc/pgx/v5       v5.5.2
    github.com/redis/go-redis/v9  v9.4.0
    go.uber.org/zap               v1.27.0
    github.com/google/uuid        v1.6.0
)
```

No ORM. No migration library in the runtime binary (migrations run via a separate
`cmd/migrate/` command using `github.com/golang-migrate/migrate/v4`, invoked only in CI
and during local setup — not imported by the API server).

### Related Sections

- [See architecture → Hexagonal Split](./architecture.md#hexagonal-split) for how the
  package boundaries that this policy protects map to the layer structure.
- [See ecosystem-fluency → Go Interface Naming Conventions](#go-interface-naming-conventions)
  for the naming idiom that applies once an interface-accepting library is in place.

---

## Go Interface Naming Conventions  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

Naming in Go is unusually opinionated. The language's official style guide (the Effective
Go document and the Go Code Review Comments document) gives concrete rules that differ
from conventions in most other languages. The most visible differences:

- **No `I` prefix for interfaces.** A Java or C# codebase might name an interface
  `IUserRepository`. Go treats that prefix as noise. The type is an interface; the name
  should describe what the type does, not what kind of type it is.
- **Single-method interfaces get verb-derived names.** An interface with one method
  `Read(p []byte) (n int, err error)` is named `Reader`, not `ReadInterface` or
  `IReadable`.
- **Multi-method interfaces get noun names that describe the capability.** A type that can
  both read and close is a `ReadCloser`. A type that can write tasks is a
  `TaskRepository`, not `TaskRepositoryInterface` or `ITaskRepository`.

The rationale is that Go interfaces are satisfied implicitly — a type satisfies an
interface simply by having the required methods. Because there is no `implements` keyword,
the interface name carries the full semantic weight of the contract. A name that describes
the capability ("a thing that fetches") conveys more than a name that describes the type
kind ("an interface called IFetcher").

### Idiomatic Variation  [MID]

Meridian enforces three naming rules, two of which are standard Go and one of which is a
project-specific decision:

**Rule 1 — No `I` prefix.** All interfaces in `domain/`, `service/`, and `repository/`
are named without any prefix. `TaskRepository`, not `ITaskRepository`.

**Rule 2 — Single-method interfaces use the `-er` suffix.** Meridian's
`NotificationService` interface has multiple methods, so it is named as a noun. But when
the project introduced a narrow webhook-validation interface with a single method, it was
named `Validator`, not `WebhookValidator` or `IValidator`.

**Rule 3 — Constructor functions are `New<T>`, not `Make<T>`.** This is a Meridian
project decision that aligns with the majority of Go standard library and popular packages
(`http.NewRequest`, `json.NewDecoder`, `zap.NewProduction`). The team briefly used
`Make<T>` during an early sprint influenced by a team member's Rust background, but
changed to `New<T>` after a code review established that the `Make` prefix had no precedent
in Go community conventions and would confuse contributors expecting the standard naming.

```go
// domain/task.go — consistent constructor naming
func NewTask(workspaceID uuid.UUID, title string) Task {
    return Task{
        ID:          uuid.New(),
        WorkspaceID: workspaceID,
        Title:       title,
        Status:      TaskStatusActive,
        CreatedAt:   time.Now().UTC(),
    }
}
```

**Receiver names** follow a strict rule: single-letter abbreviated from the type name.
`TaskService` uses `s`, `postgresTaskRepository` uses `r`, `TaskHandler` uses `h`.
Multi-letter receivers (`ts`, `repo`) are rejected in code review. This aligns with the
Go Code Review Comments recommendation and keeps method signatures compact.

### Trade-offs and Constraints  [SENIOR]

The `-er` suffix convention for single-method interfaces creates occasional awkward names.
An interface with a single `Execute(ctx context.Context, cmd Command) error` method would
conventionally be named `Executor` — this works. But an interface with a single
`Notify(ctx context.Context, event Event) error` method becomes `Notifier`, which is
fine; and an interface with `CheckAndRecord(ctx context.Context, key string) (bool, error)`
becomes `CheckAndRecorder`, which is strained. In that case, Meridian opts for a noun
form (`IdempotencyChecker`) rather than forcing an awkward `-er` name. The principle is
"follow the convention; depart when the result is obviously worse than the alternative."

The `New<T>` convention gives up the distinction some Rust-influenced engineers find
useful: `make` for zero-argument constructors, `new` for constructors that take
parameters. Go does not use this distinction anywhere in stdlib or major packages, and
imposing it on a Go codebase creates friction for new contributors who arrive with Go
experience from other projects.

### Related Sections

- [See architecture → Hexagonal Split](./architecture.md#hexagonal-split) for the
  interface declaration locations that these naming rules apply to (interfaces defined
  in `domain/`, consumed in `service/`).
- [See ecosystem-fluency → Go Stdlib vs. Third-Party](#go-stdlib-vs-third-party-the-meridian-policy)
  for the policy that determines when an interface-backed abstraction is worth defining at all.

---

## Project Layout: Where Meridian Landed on the `pkg/` Debate  [MID]

### First-Principles Explanation  [JUNIOR]

Go project layout is a topic with more community debate than the language's syntax. The
`cmd/` + `internal/` + `pkg/` structure used in the
[golang-standards/project-layout](https://github.com/golang-standards/project-layout)
GitHub repository is widely copied but is not an official Go recommendation. The Go team
has explicitly stated that there is no required directory structure for Go modules.

The key distinction between the three directories:

- `cmd/<name>/main.go` — entry points. Each `cmd/` subdirectory produces one binary.
  Code here is thin: parse flags, wire dependencies, call `Run(ctx)`.
- `internal/` — packages importable only by code in the same module. The Go toolchain
  enforces this: `go build` will reject an import of `mymodule/internal/service` from
  outside `mymodule`. This is the primary encapsulation mechanism in Go.
- `pkg/` — packages intended to be imported by external modules. This is the convention
  for library code. Whether a project needs `pkg/` depends on whether the project exports
  reusable packages.

### Idiomatic Variation  [MID]

Meridian does not have a `pkg/` directory. The decision was made explicitly: Meridian is
an application, not a library. No external module is expected to import any Meridian
package. Adding `pkg/` would signal that some packages are intended for external reuse —
a signal that would be false and potentially misleading to new contributors.

The layout is:

```
cmd/
  server/
    main.go          # API server entry point — wires deps, starts Gin
  migrate/
    main.go          # Migration runner — separate binary, not imported by server

internal/
  domain/            # Pure types, interfaces, error types — no infrastructure imports
  handler/           # Gin handler structs
  service/           # Business logic services
  repository/        # PostgreSQL and Redis implementations
  middleware/        # Gin middleware (auth, request ID, logging)
  config/            # Configuration loading from environment
```

The `config/` package is in `internal/` despite being simple. It is not exported because
configuration is application-specific. The `middleware/` package contains Gin-specific
code and has no value outside this application.

The absence of `pkg/` avoids a common confusion in Go monorepos: contributors who see
`pkg/` assume it is a place to put shared utilities. In Meridian's case, shared utilities
live in `internal/` because they are not shared with external modules, only with other
packages within the same module.

### Trade-offs and Constraints  [SENIOR]

Not having `pkg/` means that if Meridian ever wants to share a utility with a
hypothetical second service (a background job runner, a webhook forwarder), the utility
must either be duplicated, extracted into a separate module, or the second service must be
added to the same module. At the time of the layout decision, the team had no second
service and no concrete plan for one. Adding `pkg/` preemptively would have been YAGNI.

The `internal/` enforcement is the stronger benefit. The Go toolchain prevents `internal`
packages from being imported outside the module, which means Meridian's database layer,
configuration, and domain types cannot be accidentally imported by another team's service
even if they share a monorepo. The encapsulation is compiler-enforced, not
convention-enforced.

If a second service is added to the repository later, the decision point is: create a
`pkg/` directory for genuinely shared packages, or keep each service's code entirely
under its own `internal/`. Meridian's current consensus is that `internal/` per service
is preferable until the sharing need is concrete and the shared package's API is stable
enough to be treated as a library contract.

### Related Sections

- [See architecture → Hexagonal Split](./architecture.md#hexagonal-split) for the layer
  diagram showing how these directories map to the hexagonal layer structure.
- [See ecosystem-fluency → Go Stdlib vs. Third-Party](#go-stdlib-vs-third-party-the-meridian-policy)
  for how the package layout interacts with the third-party dependency policy.

---

## TanStack Query as Meridian's Data Layer  [MID]

### First-Principles Explanation  [JUNIOR]

React applications that fetch data from a server face a recurring set of problems:
loading states, error states, caching, background refresh, deduplication of concurrent
requests for the same resource, and optimistic updates. The naive approach handles each
of these inline in components using `useState` and `useEffect`. This works for one
component fetching one resource, but as the application grows, every component reinvents
the same patterns inconsistently: some components show a spinner, others show nothing,
some cache data in a global store, others refetch on every mount.

A **server state library** pulls this concern into a dedicated layer. The library owns
the cache, the loading state, the error state, the deduplication logic, and the
background refresh scheduling. Components declare what data they need; the library
decides whether to serve it from cache or fetch it.

The distinction between server state and client state is important. Server state
represents data owned by the server (tasks, workspaces, users). It is asynchronous,
has a known staleness model, and may be shared across components. Client state represents
UI behavior (which drawer is open, which tab is selected). These two kinds of state
have different lifecycles and should not be managed by the same tool.

### Idiomatic Variation  [MID]

Meridian uses TanStack Query (`@tanstack/react-query`) for all server state. The pattern
is consistent across every data-fetching component:

```tsx
// hooks/useTaskList.ts
import { useQuery } from '@tanstack/react-query';
import { fetchTasks } from '../api/tasks';

export function useTaskList(workspaceId: string) {
  return useQuery({
    queryKey: ['tasks', workspaceId],
    queryFn: () => fetchTasks(workspaceId),
    staleTime: 30_000,   // treat data as fresh for 30 seconds
  });
}
```

```tsx
// components/TaskList.tsx
function TaskList({ workspaceId }: { workspaceId: string }) {
  const { data, isLoading, error } = useTaskList(workspaceId);

  if (isLoading) return <Skeleton />;
  if (error) return <ErrorBanner error={error} />;
  return <ul>{data.tasks.map(t => <TaskItem key={t.id} task={t} />)}</ul>;
}
```

The `queryKey` array is the cache identifier. `['tasks', workspaceId]` means that task
lists for different workspaces are cached independently, and invalidating
`['tasks', workspaceId]` after a task creation or update triggers a background refetch
for only that workspace.

Meridian's frontend has no Redux store and no Zustand store. Client-only state (which
panel is expanded, which modal is open) is managed with `useState` or `useReducer` inside
the component or a shared context. The rule is: if the data lives on the server, it lives
in TanStack Query. If the data is purely UI behavior with no server representation, it
lives in local component state.

### Trade-offs and Constraints  [SENIOR]

TanStack Query was chosen over React's own server-fetching primitives (React Server
Components with `use` + Suspense) because Meridian's frontend is a single-page
application deployed on Vercel as a static site talking to a separate Go backend. React
Server Components require a Node.js rendering environment that controls both the React
tree and the data fetching. Meridian's architecture places those responsibilities in
separate services — Go handles data, React handles UI — and RSCs would require either
a Node.js backend-for-frontend layer or a hosting architecture change. The team evaluated
this during the frontend architecture phase and concluded that the operational cost of
adding a Node.js layer outweighed the developer-experience benefits of RSCs at Meridian's
current scale.

TanStack Query gives up the ability to eliminate client-side JavaScript for static
pages. For a dashboard application where every page requires authentication and dynamic
data, this is not a meaningful loss.

The cache invalidation model is explicit: after a mutation, the calling code calls
`queryClient.invalidateQueries({ queryKey: ['tasks', workspaceId] })`. This is slightly
more mechanical than RSC's implicit server re-render, but it is also more predictable:
invalidations are visible at the callsite, not implied by framework conventions.

### Related Sections

- [See api-design → Error Envelope: RFC 9457](./api-design.md#error-envelope-rfc-9457)
  for how TanStack Query's error handling interacts with the RFC 9457 error format the
  backend returns.
- [See api-design → Cursor-Based Pagination on Task Lists](./api-design.md#cursor-based-pagination-on-task-lists)
  for how TanStack Query's `useInfiniteQuery` consumes the cursor-based pagination
  response shape.

---

## Prior Understanding: Meridian's Router Migration from gorilla/mux to Gin  [MID]

### Prior Understanding (revised 2026-01-14)

The original backend used `github.com/gorilla/mux` for HTTP routing. The choice was
made in the project's first week because `gorilla/mux` was familiar to the lead engineer
from a prior project, offered path parameter routing that `net/http` lacks, and had a
well-established track record.

The prior understanding was: `gorilla/mux` is sufficient for a project of this size and
adds minimal surface area compared to a larger framework.

**What changed:**

By the time Meridian added authentication middleware, request-ID injection, logging
middleware, and the Slack webhook endpoint, the team had written approximately 180 lines
of hand-rolled middleware infrastructure on top of `gorilla/mux`:

- A middleware chain runner (gorilla/mux has no built-in middleware chaining)
- A context propagation helper for passing authenticated user IDs to handlers
- A JSON binding helper (`json.NewDecoder(r.Body).Decode(&req)` called in every handler)
- A response helper wrapping `json.NewEncoder(w).Encode(body)`

A code review surfaced that this middleware infrastructure was essentially reproducing
what `gin-gonic/gin` ships out of the box: `c.ShouldBindJSON`, `c.JSON`, middleware via
`router.Use()`, and route groups. The team migrated to Gin, deleted the 180 lines of
infrastructure, and gained middleware group support (which allowed the auth middleware to
be applied per-route-group rather than globally).

**Corrected understanding:**

The principle is not "prefer minimal routing libraries." The principle is "prefer the
library that ships the capabilities your project will need, at the level of abstraction
you intend to use." `gorilla/mux` is the right choice for projects that need routing
parameters and nothing else. For a project that also needs middleware groups, JSON binding,
and response helpers, a more complete framework amortizes those additions across zero
hand-rolled code. The switching cost (updating handler signatures from
`func(w http.ResponseWriter, r *http.Request)` to `func(c *gin.Context)`) was two days
of work. In retrospect, starting with Gin would have been more efficient, but the correct
decision was not obvious until the middleware surface had grown.

The lesson is ecosystem-specific: in Go, the gap between "routing library" and
"framework" is smaller than in other ecosystems. Gin is not a Rails-style full-stack
framework — it is a focused HTTP toolkit. The term "framework" should not trigger an
automatic preference for the minimal option; the question is always "what capabilities
will this project need across its first year of development?"

### Related Sections

- [See ecosystem-fluency → Go Stdlib vs. Third-Party](#go-stdlib-vs-third-party-the-meridian-policy)
  for the policy that now governs these choices before they accumulate into technical debt.

---

## Coach Illustration (default vs. hints)

> **Illustrative only.** The following is a worked example of how the two coaching styles
> differ for a task in this domain. It is not part of the live agent contract. Actual
> agent behavior is governed by the style files at
> `.claude/skills/learn/coach-styles/`.

**Scenario:** A learner is adding a Prometheus metrics endpoint to Meridian and asks
whether to use `github.com/prometheus/client_golang` or roll a simple counter using
`expvar` from the standard library.

**`default` style** — The agent applies the stdlib-vs-third-party policy: `expvar`
provides basic counters readable via `GET /debug/vars`, but Prometheus's exposition
format (the `/metrics` scrape endpoint) is what Meridian's Kubernetes monitoring stack
expects. The agent imports `github.com/prometheus/client_golang/prometheus` and
`promhttp`, registers the handler at `/metrics`, and wraps the Gin engine's existing
route group. It appends `## Learning:` trailers explaining when stdlib wins (self-contained
operation, no external consumers) versus when third-party is justified (the external
consumer — Prometheus scraper — requires a specific format that stdlib cannot produce
without reimplementing the exposition format specification).

**`hints` style** — The agent names the decision (`prometheus/client_golang` not
`expvar`, because the scrape consumer determines the format), names the policy
("stdlib-vs-third-party: the consuming system dictates the format"), and emits:

```
## Coach: hint
Step: Register a Prometheus metrics handler at /metrics using promhttp.Handler().
Pattern: Stdlib vs. third-party — the external consumer (Prometheus scraper) requires
the exposition format; expvar cannot produce it.
Rationale: The policy prefers stdlib unless the gap-filling code would be
non-trivial; reimplementing Prometheus exposition format is non-trivial.
```

`<!-- coach:hints stop -->`

The learner wires the handler and registers the counter metrics. On the next turn, the
agent responds to follow-up questions without re-explaining the policy.
