---
domain: <replace-with-domain-key>
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
---

> **Read-only reference.** This file is shipped with the ECC Base Template as a worked
> example to illustrate what a populated knowledge file looks like after many sessions on
> a real project. It is **not** your knowledge file. Your own knowledge file lives at
> `learn/knowledge/<domain>.md` and starts empty until agents enrich it during real work.
> Agents never read, cite, or write under `docs/en/learn/examples/` — this tree is for
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

## Canonical Concept Entry Shape

The following is a fully worked example entry. Per-domain agents copy and adapt this
shape. All five sections are present when the entry is first written at `[JUNIOR]` level;
`[MID]` and `[SENIOR]` sections are added in later sessions as understanding deepens.

---

## Example Concept: Thin Handler Pattern  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

In a layered web service, an HTTP handler has two jobs: decode the incoming request into
domain types, and encode the outgoing response back into HTTP. It does not validate
business rules, execute database queries, or compute results. Those belong in the service
layer. When a handler grows beyond those two jobs, the service logic becomes untestable
without a running HTTP server, and every test must construct a full request/response cycle
to assert on business behavior.

The **thin handler pattern** enforces a strict responsibility split: the handler holds
only the translation logic. The service layer holds all business logic. The repository
layer holds all persistence logic. A handler that is 30 lines long and mostly type
conversions is working as designed.

### Idiomatic Variation  [MID]

In Meridian's Go + Gin stack, handlers accept `*gin.Context`, extract validated
parameters via `ShouldBindJSON`, call the service, and translate the service's return
value or error into a JSON response. The handler never calls the database directly — not
even for a quick existence check. If a check belongs in the flow, it belongs in the
service, which may delegate to the repository.

```go
// handler/task.go — thin handler, Meridian pattern
func (h *TaskHandler) CreateTask(c *gin.Context) {
    var req CreateTaskRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, errorResponse(err))
        return
    }
    task, err := h.svc.CreateTask(c.Request.Context(), req.ToParams())
    if err != nil {
        h.writeError(c, err)
        return
    }
    c.JSON(http.StatusCreated, task)
}
```

`h.writeError` translates domain errors to HTTP status codes. It is the only place in the
handler layer where the mapping between domain errors and HTTP errors is codified.

### Trade-offs and Constraints  [SENIOR]

The cost of thin handlers is that the service layer accumulates complexity. When a feature
touches five entities, the service method grows; the temptation is to push some logic back
into the handler "just this once." The trade-off is testability: keeping the service fat
means every business rule is testable with `go test` and no HTTP scaffold. Keeping the
handler thin means the routing layer can be swapped (Gin replaced by standard `net/http`)
without touching any business logic.

The pattern also means that validation lives in two places: schema validation (types,
required fields) in the handler, business validation (a user cannot assign a task to a
project they do not own) in the service. This split is intentional but requires discipline
to maintain. When a junior engineer is unsure which layer a validation belongs to, the
rule of thumb is: if the answer requires a database lookup, it belongs in the service.

### Example (Meridian)

See the `CreateTask` snippet in the Idiomatic Variation section above. The corresponding
service method `svc.CreateTask` contains the authorization check, duplicate detection, and
the Slack notification trigger — none of which appear in the handler.

### Related Sections

- [See api-design → Error Envelopes](./api-design.md#error-envelope-rfc-9457) for how
  `h.writeError` translates domain errors into the project's HTTP error format.
- [See architecture → Hexagonal Split](./architecture.md#hexagonal-split) for the
  full layer diagram showing where handlers, services, and repositories live.

### Coach Illustration (default vs. hints)

> **Illustrative only.** The following is a worked example of how the two coaching styles
> differ for a task in this domain. It is not part of the live agent contract. Actual
> agent behavior is governed by the style files at
> `.claude/skills/learn/coach-styles/`.

**Scenario:** A learner asks the agent to add an endpoint that lets Meridian users archive
a task.

**`default` style** — The agent produces the complete implementation: the handler method,
the service method, the repository `Archive` call, the error translation, and the test.
It then appends `## Learning:` trailers explaining the thin-handler split and the domain
error translation. The learner receives finished, working code.

**`hints` style** — The agent writes the handler stub (signature + `ShouldBindJSON` call,
body empty), the service interface method signature, and a test stub. It then emits:

```
## Coach: hint
Step: Implement TaskService.ArchiveTask — validate ownership, call repo.Archive, trigger notification.
Pattern: Service-layer orchestration (thin handler pattern).
Rationale: Business rules (ownership check, notification) belong in the service, not the
handler, so the handler stays testable without HTTP scaffolding.
```

`<!-- coach:hints stop -->`

The learner implements the service body. On the next turn, the agent responds to any
errors or follow-up questions without re-writing the scaffold.
