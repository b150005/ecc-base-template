---
domain: security-mindset
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: security-reviewer
contributing-agents: [security-reviewer, code-reviewer]
---

> **Read-only reference.** This file is shipped with the ECC Base Template as a worked
> example to illustrate what a populated knowledge file looks like after many sessions on
> a real project. It is **not** your knowledge file. Your own knowledge file lives at
> `learn/knowledge/security-mindset.md` and starts empty until agents enrich it during
> real work. Agents never read, cite, or write under `docs/en/learn/examples/` — this
> tree is for human readers only. See [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md)
> for the design rationale.

---

## How to Read This File

Level markers indicate the intended audience for each section:
- `[JUNIOR]` — first-principles explanation; assumes no prior exposure
- `[MID]` — non-obvious idiomatic application in this stack
- `[SENIOR]` — non-default trade-off evaluation; names what is given up

Severity labels (CRITICAL, HIGH, MEDIUM, LOW) describe the consequence of the
vulnerability, not the audience reading the entry. A CRITICAL finding is CRITICAL at
every level. See [preamble §4](../../../../learn/preamble.md) for the rule that severity
must not be softened by level.

---

## Multi-Tenant Isolation: workspace_id on Every Query  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

A multi-tenant system stores data for many independent customers in the same database.
Tenant A's tasks live next to Tenant B's tasks in the same `tasks` table, distinguished
only by a `workspace_id` column. The integrity of the entire product depends on one
rule: every query that reads or writes a tenant-scoped table must filter by the
caller's workspace_id.

The naive failure is `SELECT * FROM tasks WHERE id = $1` — fetch a task by its primary
key, return it. The query is correct in isolation. It is a tenant data leak in
context: any authenticated user who guesses or enumerates a UUID receives the
corresponding task regardless of which workspace owns it. The defense is positive: the
workspace_id is part of every query's WHERE clause, derived from the authenticated
session, so the caller cannot forget the check — it is an inseparable clause in the SQL.

### Idiomatic Variation  [MID]

In Meridian's repository layer, every tenant-scoped query carries `workspace_id` as
the first WHERE clause, sourced from the request context, never from the request body
or path:

```go
// repository/task.go
func (r *postgresTaskRepository) Get(ctx context.Context, id uuid.UUID) (domain.Task, error) {
    workspaceID, ok := tenant.FromContext(ctx)
    if !ok {
        return domain.Task{}, domain.ErrUnauthenticated
    }
    row := r.db.QueryRowContext(ctx, `
        SELECT id, workspace_id, title, assignee_id, status, created_at, archived_at
        FROM tasks
        WHERE workspace_id = $1 AND id = $2 AND deleted_at IS NULL
    `, workspaceID, id)
    // ... scan and translate errors
}
```

The repository never accepts a workspace_id as a function parameter — that would let a
service-layer caller pass any value, defeating the isolation. A custom golangci-lint
rule enforces the discipline: any SQL string literal in `internal/repository/` that
references a tenant-scoped table (`tasks`, `task_assignments`, `comments`,
`attachments`) and does not contain the substring `workspace_id` fails the build.
Bypass requires an explicit `//nolint:tenantscope` comment with a justification line;
the security-reviewer agent flags every bypass on PR.

### Trade-offs and Constraints  [SENIOR]

The rule has one documented exception: cross-tenant admin queries used by Meridian's
internal support tooling. These queries deliberately span workspaces — for example, an
engineer investigating a customer ticket needs to look up a task by its public URL ID
without first proving workspace membership. The exception lives in a separate
`adminRepository` in `internal/admin/repository/`, accessible only behind the
`/admin/` route group, gated by a separate auth middleware bound to staff identities
issued by the company's SSO provider. Every admin query is wrapped in a deferred audit
log write that records the staff user, the workspace IDs touched, and the query.

The cost is duplication — the admin repository reimplements common queries with the
workspace filter relaxed — but the alternative (a flag on the production repository
methods) was rejected because a flag is one missed review away from being passed
`true` from a non-admin path. A failed audit write is logged but does not fail the
underlying operation: a partial audit trail is more useful than no operation at all
when staff are mid-incident, and the audit pipeline has its own monitoring that pages
on dropped writes.

### Related Sections

- [See architecture → Hexagonal Split](./architecture.md#hexagonal-split) for where
  the tenant context is injected into the request flow.
- [See error-handling → Boundary Translation](./error-handling.md#boundary-translation-postgres-to-domain-errors)
  for how a missing-row result from the workspace-filtered query becomes
  `domain.ErrNotFound` rather than a permission error — a deliberate choice that hides
  the existence of cross-tenant resources from probing callers.

---

## Authentication: Redis-Backed Sessions over Stateless JWT  [MID]

### First-Principles Explanation  [JUNIOR]

An authenticated request must carry proof of identity. **Stateless tokens** (JWT) are
self-contained: the server validates the signature and reads claims from the token, no
lookup required. JWTs cannot be revoked before they expire without introducing the
very server-side state the JWT was meant to avoid. **Session identifiers** are random
opaque strings mapped to session data in a shared store; revocation is trivial (delete
the entry), at the cost of a per-request lookup.

### Idiomatic Variation  [MID]

Meridian uses Redis-backed sessions. The session ID is a 256-bit `crypto/rand` value,
base64url-encoded, set as an HttpOnly, Secure, SameSite=Lax cookie scoped to
`meridian.app`. The session record carries the user ID, the active workspace ID, the
issued-at timestamp, the absolute expiry, and a rolling activity timestamp. A session
is rotated (new ID issued, old one invalidated) on every privilege-changing event:
login, logout from another device, password change, MFA enrollment, workspace switch.

```go
// middleware/auth.go
func (m *AuthMiddleware) Require() gin.HandlerFunc {
    return func(c *gin.Context) {
        cookie, err := c.Cookie(sessionCookieName)
        if err != nil || len(cookie) != expectedCookieLength {
            c.AbortWithStatusJSON(http.StatusUnauthorized, unauthorizedResponse())
            return
        }
        sess, err := m.sessions.Get(c.Request.Context(), cookie)
        if err != nil || sess == nil || time.Now().After(sess.ExpiresAt) {
            c.AbortWithStatusJSON(http.StatusUnauthorized, unauthorizedResponse())
            return
        }
        ctx := tenant.WithWorkspace(c.Request.Context(), sess.WorkspaceID)
        ctx = identity.WithUser(ctx, sess.UserID)
        c.Request = c.Request.WithContext(ctx)
        c.Next()
    }
}
```

### Trade-offs and Constraints  [SENIOR]

The default in greenfield Go services is JWT. Meridian deliberately rejected it for
two reasons. Instant revocation is a hard requirement for a B2B product where a
customer admin must remove a departing employee's access immediately, not at the next
token expiry. Second, the workspace context changes mid-session when a user switches
workspaces, and embedding mutable state in a signed token is a recipe for confusion:
either the token is reissued on every switch (negating the statelessness benefit) or
the workspace claim goes stale.

The cost is the per-request Redis lookup. Meridian colocates API pods and Redis in
the same Kubernetes namespace, putting the lookup at sub-millisecond p99. If Redis
itself becomes unavailable, the auth middleware fails closed: requests return 503
rather than serving traffic without authentication. There is no in-process session
cache; the performance cost is acceptable at current traffic. If it becomes a
bottleneck, the correct response is a short-TTL local cache with an explicit
invalidation channel — not JWTs.

### Related Sections

- [See api-design → Idempotency Key Handling](./api-design.md#idempotency-key-handling)
  for the other Redis-backed pattern Meridian relies on; the same operational concerns
  apply to both.
- [See architecture → Hexagonal Split](./architecture.md#hexagonal-split) for the
  layer in which middleware lives.

---

## Authorization: Workspace RBAC + Task-Level ABAC  [MID]

### First-Principles Explanation  [JUNIOR]

Authorization answers "what is the caller allowed to do." **RBAC** assigns users to
roles; roles have permissions; permissions gate operations. Roles are coarse-grained
and easy to reason about. **ABAC** computes permissions from attributes of the caller,
the resource, and the context. ABAC handles fine-grained, relationship-driven rules
that RBAC cannot express cleanly.

### Idiomatic Variation  [MID]

Meridian uses RBAC at the workspace boundary and ABAC at the task boundary. Workspace
policy is a constant table; task policy is a pure Go function in `service/policy/`:

```go
// service/policy/task.go
func CanEditTask(task domain.Task, caller domain.Member) bool {
    if caller.Role == RoleAdmin || caller.Role == RoleOwner {
        return true
    }
    if task.AssigneeID != nil && *task.AssigneeID == caller.UserID {
        return true
    }
    if task.AssigneeID == nil && caller.Role == RoleMember {
        return true // unassigned tasks are editable by any member
    }
    return false
}
```

The policy engine has no DSL, no rule file, no external evaluator. The functions are
pure — input arguments only, no I/O — which means every decision is unit-testable and
every test covers a real production code path.

### Trade-offs and Constraints  [SENIOR]

A pure-Go policy engine cannot be reconfigured without a code change and a deploy.
Policy-as-data systems (Open Policy Agent, Cedar) win on flexibility and lose on
traceability and testability. Meridian chose code because policy bugs in a B2B product
are CRITICAL: an incorrect rule that grants edit access to the wrong user is a tenant
data exposure, and the fastest way to reason about a rule's correctness is to read the
function and run its tests.

The policy engine's location matters: it lives in the service layer, not in
middleware. Middleware can only check attributes available before the resource is
loaded — typically caller identity and URL path. Task-level rules need the task itself
(to read the assignee), so the service must load the task before the policy runs:

```go
// service/task.go
func (s *TaskService) UpdateTask(ctx context.Context, taskID uuid.UUID, params domain.UpdateTaskParams) (domain.Task, error) {
    task, err := s.tasks.Get(ctx, taskID) // workspace-scoped fetch
    if err != nil {
        return domain.Task{}, err
    }
    callerID, _ := identity.FromContext(ctx)
    member, err := s.workspaces.GetMember(ctx, task.WorkspaceID, callerID)
    if err != nil {
        return domain.Task{}, err
    }
    if !policy.CanEditTask(task, member) {
        return domain.Task{}, &domain.AuthorizationError{Action: "edit", Resource: "task"}
    }
    return s.tasks.Update(ctx, taskID, params)
}
```

Three layers of defense in one method: the workspace_id filter on the fetch (so a
cross-tenant ID returns `ErrNotFound`, not the task), the membership lookup (so a
former member cannot act after their session was supposed to be invalidated), and the
policy check.

### Related Sections

- [See review-taste → The Severity Ladder](./review-taste.md#the-severity-ladder) for
  how an absent authorization check is classified CRITICAL in code review.
- [See error-handling → Domain Error Type Hierarchy](./error-handling.md#domain-error-type-hierarchy)
  for the `AuthorizationError` type returned by the policy gate.

---

## Slack Webhook Signature: HMAC-SHA256, Timing-Safe, Replay-Bounded  [MID]

### First-Principles Explanation  [JUNIOR]

A webhook endpoint must verify that requests actually came from the claimed sender.
The standard mechanism is a shared secret plus HMAC: the sender computes a hash-based
MAC over the body using the secret, sends the MAC as a header, the receiver
recomputes and compares.

Three failure modes are easy to introduce. **Timing-attackable comparison**: comparing
two MAC strings with `==` short-circuits at the first mismatch, leaking byte-by-byte
information; the defense is constant-time comparison. **Replay**: a valid MAC over a
captured payload is valid forever; the defense is a timestamp window. **Algorithm
trust**: trusting the sender's algorithm choice lets an attacker downgrade; the
receiver pins the algorithm.

### Idiomatic Variation  [MID]

Meridian's middleware verifies signatures per Slack's documented contract:
HMAC-SHA256 over `v0:{timestamp}:{raw_body}`, with the `v0=` prefix on the header
value:

```go
// middleware/slack_signature.go
const slackSignatureWindow = 5 * time.Minute

func (m *SlackSignatureMiddleware) Verify(c *gin.Context) {
    timestampStr := c.GetHeader("X-Slack-Request-Timestamp")
    signature := c.GetHeader("X-Slack-Signature")
    if timestampStr == "" || signature == "" {
        c.AbortWithStatus(http.StatusUnauthorized); return
    }
    ts, err := strconv.ParseInt(timestampStr, 10, 64)
    if err != nil {
        c.AbortWithStatus(http.StatusUnauthorized); return
    }
    if time.Since(time.Unix(ts, 0)).Abs() > slackSignatureWindow {
        c.AbortWithStatus(http.StatusUnauthorized); return // bilateral replay window
    }
    body, err := io.ReadAll(c.Request.Body)
    if err != nil {
        c.AbortWithStatus(http.StatusBadRequest); return
    }
    c.Request.Body = io.NopCloser(bytes.NewReader(body))

    secret := m.secrets.Get("<SLACK_SIGNING_SECRET_FROM_VAULT>")
    mac := hmac.New(sha256.New, secret)
    mac.Write([]byte("v0:" + timestampStr + ":"))
    mac.Write(body)
    expected := "v0=" + hex.EncodeToString(mac.Sum(nil))

    if subtle.ConstantTimeCompare([]byte(expected), []byte(signature)) != 1 {
        c.AbortWithStatus(http.StatusUnauthorized); return
    }
    c.Next()
}
```

The signing secret is fetched from the secrets provider (Vault in production). The
placeholder `<SLACK_SIGNING_SECRET_FROM_VAULT>` is the lookup key, not the secret.
The replay window is bilateral: timestamps too far in the past **or** too far in the
future are rejected. Future-dated timestamps are an attempt to extend the window;
rejecting them is cheap and defensive.

### Trade-offs and Constraints  [SENIOR]

The five-minute window is the value Slack publishes. A tighter window (one minute)
would reduce the replay surface at the cost of false rejections under clock drift.
Meridian relies on chrony for time sync and ran clock-drift telemetry for a month
before adopting five minutes as the operational default. The middleware reads the
entire request body into memory before computing the MAC. For Slack payloads (a few
kilobytes) this is fine; if Meridian ever accepts larger webhook payloads, the same
pattern needs a streaming MAC computation — only the `io.ReadAll` would change.

Order of middleware on the route matters: signature verification is the cheapest
filter that proves the caller is Slack, so it runs first; idempotency uses Redis and
is more expensive, so it runs after. Unauthenticated requests do not consume Redis
lookups.

### Related Sections

- [See error-handling → Idempotent Retry on the Slack Webhook](./error-handling.md#idempotent-retry-on-the-slack-webhook)
  for the defense-in-depth layer that handles legitimate Slack retries within the
  signature window.
- [See dependency-management → Pinning Strategy](./dependency-management.md#version-pinning-policy)
  for why `crypto/subtle` and `crypto/hmac` from stdlib are preferred over third-party
  HMAC packages — keeping cryptographic primitives in stdlib reduces supply-chain
  surface.

---

## Secrets Handling: Vault in Prod, .env.example in Repo, Log Redaction Always  [MID]

### First-Principles Explanation  [JUNIOR]

A secret is any value whose disclosure lets an attacker impersonate the system or a
user. Three failure modes account for almost all real leaks: **secrets committed to
version control** (a `.env` file checked in once is exposed forever — rewriting
history does not undo disclosure to anyone who fetched the repo before the rewrite);
**secrets logged in production** (debug logs that print request bodies, stack traces
with connection strings, error messages that echo tokens — logs are aggregated and
often shared with third parties); **secrets passed through environment to processes
that do not need them**.

### Idiomatic Variation  [MID]

Meridian's discipline:

- **Never `.env` in the repo.** The repository contains `.env.example` with placeholder
  values pointing to where the real value lives (Vault path or local dev stub).
  `.gitignore` lists `.env`; the pre-commit hook rejects commits introducing one.
- **Vault in production.** Kubernetes manifests use Vault Agent Injector to mount
  secrets as in-memory files at `/var/run/secrets/meridian/`. The application reads at
  startup and caches in memory; rotation triggers a SIGHUP to reload.
- **Log redaction middleware.** Every log line passes through a `slog.Handler` wrapper
  that replaces values matching known secret patterns (Slack signing secret format,
  JWT-like strings, AWS keys, the project's session cookie format) with a fixed
  marker. The filter operates on the marshaled log entry, so it catches secrets
  embedded in error messages, request bodies, and stack traces.

```go
// internal/log/redact.go
type RedactHandler struct {
    next     slog.Handler
    patterns []*regexp.Regexp
}

func (h *RedactHandler) Handle(ctx context.Context, r slog.Record) error {
    redacted := slog.NewRecord(r.Time, r.Level, redactString(r.Message, h.patterns), r.PC)
    r.Attrs(func(a slog.Attr) bool {
        redacted.AddAttrs(redactAttr(a, h.patterns))
        return true
    })
    return h.next.Handle(ctx, redacted)
}
```

The patterns match the **shape** of a secret, not its value. A pattern that matched
the actual value would be a secret itself. The shape-based approach catches both known
secrets and unknown values that happen to look like secrets — a defensive
false-positive bias.

### Trade-offs and Constraints  [SENIOR]

Pattern-based redaction has false negatives: a custom-format secret matching no known
pattern slips through. The mitigation in `internal/auth/` and `internal/payments/` is
a stricter rule: any structured-log call must use one of an approved set of attribute
keys, and `password`, `token`, `secret`, and `key` attributes must wrap their value in
a `Redacted` type that prints `[REDACTED]`. The cost is occasional debugging friction;
the operational practice is that secret-touching code paths emit a hash of the value
(`sha256(value)[:8]`) alongside the redacted value, which is enough to confirm two log
entries refer to the same secret without disclosing it.

The Vault-in-production decision over plain Kubernetes secrets was made because
Kubernetes secrets are base64-encoded (not encrypted at rest unless KMS integration is
enabled), and any pod with the right service account can read any secret in its
namespace. Vault adds per-secret access policies, audit logs, and rotation, at the
cost of an additional operational dependency. Meridian's customer base includes
regulated industries that ask "where do your secrets live" during procurement, and
Kubernetes secrets is not a satisfying answer for those buyers.

### Related Sections

- [See dependency-management → Pinning Strategy](./dependency-management.md#version-pinning-policy)
  for how Vault client library updates are gated through a security review.

---

## Corrected: bcrypt Cost Factor of 10  [MID]

> Superseded 2026-02-09: A CPU profile of the login endpoint at peak traffic showed
> bcrypt was not the latency bottleneck the original cost-factor choice assumed it
> was; the cost factor was set conservatively low for a problem the system did not have.

The original Meridian password hashing call used a bcrypt cost factor of 10, the
library's default and a common choice in the Go ecosystem at the time. The reasoning
was performance: a higher cost factor would slow login.

```go
// service/identity.go — original
hash, err := bcrypt.GenerateFromPassword([]byte(password), 10)
```

**Corrected understanding:**

A CPU profile showed bcrypt at cost 10 consuming approximately 12ms per call, while
the rest of the login path — Redis session write, audit log emit, response
serialization, network — accounted for 80ms+. Bcrypt was not the bottleneck.

The corrected value is 14, chosen to push the bcrypt step to roughly 200ms per call.
This adds latency to login but raises the brute-force cost for an attacker who
exfiltrates the password hash table by approximately 16x. The login endpoint is
rate-limited to five attempts per minute per IP and per account, so the user-facing
impact of the additional latency is bounded to the legitimate login path.

```go
// service/identity.go — current
hash, err := bcrypt.GenerateFromPassword([]byte(password), 14)
```

The principle: cost-factor decisions for password hashing should be calibrated against
the offline attack cost, not against the worst case of online login latency. The
online path can be rate-limited; the offline cost is set once and cannot be raised
after a hash is leaked. The default of 10 was a 2010-era calibration that ten years
of Moore's Law has eroded.

The migration was applied lazily: existing hashes were marked with their original
cost, and a re-hash to cost 14 happened on the next successful login. New accounts
started at 14 from the migration date. This avoided a re-hash storm and let the
migration drain over a few weeks.

### Related Sections

- [See dependency-management → Pinning Strategy](./dependency-management.md#version-pinning-policy)
  for how `golang.org/x/crypto/bcrypt` is pinned and how upgrades are reviewed for
  algorithmic changes that could invalidate stored hashes.

---

### Coach Illustration (default vs. review-only)

> **Illustrative only.** Not part of the live agent contract. Governed by
> `.claude/skills/learn/coach-styles/`.

**Scenario:** A learner submits a PR adding an admin endpoint that fetches a task by
its public ID across all workspaces. The handler calls a new repository method that
does `SELECT * FROM tasks WHERE public_id = $1` (no workspace filter, by design).

**`default` style** — The agent reviews the diff and writes findings: CRITICAL on the
missing audit log wrapper (the cross-tenant query is deliberate but unaudited), HIGH
on the missing staff-identity assertion in the handler, MEDIUM on the absence of a
test asserting that a non-staff session is rejected. Suggested fixes reference the
`withAudit` wrapper and the staff context check.

**`review-only` style** — The agent declines to write production code and produces only
the structured review with the same severity labels. CRITICAL stays CRITICAL regardless
of the learner's declared level — see [preamble §4](../../../../learn/preamble.md).
