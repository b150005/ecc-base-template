---
domain: operational-awareness
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: devops-engineer
contributing-agents: [devops-engineer]
---

> **Read-only reference.** This file is shipped with the ECC Base Template as a worked
> example to illustrate what a populated knowledge file looks like after many sessions on
> a real project. It is **not** your knowledge file. Your own knowledge file lives at
> `learn/knowledge/operational-awareness.md` and starts empty until agents enrich it during
> real work. Agents never read, cite, or write under `docs/en/learn/examples/` — this tree
> is for human readers only. See [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md)
> for the design rationale.

> **Knowledge domain**: `learn/knowledge/operational-awareness.md`

---

## How to Read This File

Level markers indicate the intended audience for each section:
- `[JUNIOR]` — first-principles explanation; assumes no prior exposure
- `[MID]` — non-obvious idiomatic application in this stack
- `[SENIOR]` — non-default trade-off evaluation; names what is given up

---

## Three-Pillar Observability: Logs, Metrics, and Traces  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

A service in production is a black box. No engineer watches it continuously. The only way
to know what the service is doing — and what it was doing during an incident — is through
the signals it emits. Three signal types exist, and each answers a different question:

**Logs** record discrete events. A request was received. An error was returned. A
background job completed. Logs answer: "what happened, and in what sequence?" A log entry
captures the moment in time when something occurred, with whatever context the engineer
chose to include. The weakness of logs is that they are expensive to store and search at
volume, and they are poor for computing aggregates ("how many requests took more than 500ms
in the last five minutes?").

**Metrics** record numeric measurements over time. Request rate, latency percentiles,
error rate, queue depth, memory usage. Metrics answer: "how is the system behaving right
now, and how has that changed?" Metrics are efficient to store (time-series databases
compress repetitive numeric samples well) and efficient to query (pre-aggregated). The
weakness of metrics is that they lose individual event context. A spike in p99 latency
tells the engineer that something is slow; it does not say which requests were slow or why.

**Traces** record the path of a single request through multiple services or components.
Each step is a **span**: a named operation with a start time, end time, and key-value
attributes. A trace is a tree of spans. Traces answer: "where did this specific request
spend its time, and how did it flow through the system?" The weakness of traces is that
capturing every request is too expensive; in practice, only a sample of requests is traced.

No single pillar replaces the others. A latency spike (metric) prompts the engineer to
look at traces to find which request path is slow; traces point to a repository query; the
log shows that the query is hitting a lock. The three pillars are most useful when they
are correlated — when a trace ID appears in a log line, and when a log line points back to
the metric that first surfaced the anomaly.

### Idiomatic Variation  [MID]

Meridian's observability stack maps each pillar to a specific technology:

| Pillar | Technology | Where signals go |
|--------|-----------|-----------------|
| Structured logs | `uber-go/zap` | Loki (via Promtail on each K8s node) |
| Metrics | Prometheus client (`prometheus/client_golang`) | Prometheus (scraped on 15s interval) |
| Traces | OpenTelemetry SDK → Jaeger | Jaeger via OTLP exporter |

**Logs with zap.** Meridian uses `zap.Logger` in structured mode: every log call emits a
JSON object rather than a human-readable string. Fields are key-value pairs, not
interpolated text. This is what separates structured logging from `fmt.Println`: the log
is machine-readable, so Loki can filter and aggregate on any field without scanning the
full message text.

```go
// internal/middleware/logger.go — request logging middleware
func RequestLogger(log *zap.Logger) gin.HandlerFunc {
    return func(c *gin.Context) {
        start := time.Now()
        c.Next()
        log.Info("request completed",
            zap.String("method", c.Request.Method),
            zap.String("path", c.FullPath()),
            zap.String("trace_id", traceIDFromContext(c.Request.Context())),
            zap.Int("status", c.Writer.Status()),
            zap.Duration("latency", time.Since(start)),
            zap.String("workspace_id", workspaceIDFromContext(c.Request.Context())),
        )
    }
}
```

The `trace_id` field is the correlation anchor. A Loki query can filter on `trace_id` and
return the full log sequence for a specific request; that same ID can be pasted into
Jaeger to view the trace tree for the same request.

**Metrics with Prometheus.** Meridian exposes a `/metrics` endpoint via Prometheus's Go
client, scraped by the in-cluster Prometheus instance. Gin HTTP metrics (request count,
duration histogram, active connections) are registered in `internal/metrics/http.go`.
Domain-specific gauges — pool connection counts, Redis pipeline queue depth — are
registered alongside them. Prometheus scrapes every 15 seconds; alerts fire on the metrics
Prometheus computes, not on log-derived queries. This is important: log-based alerting
(alerting from log queries) is slow and expensive; metric-based alerting is fast and cheap.

**Traces with OpenTelemetry.** Meridian initializes the OTel Go SDK at startup and
registers a Jaeger OTLP exporter. The trace context propagates through Go's `context.Context`
via the W3C `traceparent` header on inbound HTTP requests. The middleware extracts the
`traceparent` on arrival and creates or continues the trace:

```go
// cmd/server/main.go — OTel initialization (abbreviated)
func initTracer(cfg config.Telemetry) (func(context.Context) error, error) {
    exp, err := otlptracehttp.New(context.Background(),
        otlptracehttp.WithEndpoint(cfg.JaegerEndpoint),
        otlptracehttp.WithInsecure(),
    )
    if err != nil {
        return nil, err
    }
    tp := trace.NewTracerProvider(
        trace.WithBatcher(exp),
        trace.WithSampler(trace.TraceIDRatioBased(cfg.SampleRate)), // 0.1 in production
    )
    otel.SetTracerProvider(tp)
    otel.SetTextMapPropagator(propagation.TraceContext{})
    return tp.Shutdown, nil
}
```

The sample rate of 0.1 (10%) is a deliberate trade-off. Tracing every request at
Meridian's volume would produce roughly 2 TB of trace data per month; 10% sampling
reduces this to a manageable 200 GB while preserving statistical coverage of most
request-path types. Trace sampling is discussed further in the trade-offs section below.

### Trade-offs and Constraints  [SENIOR]

**The trap of logging metrics.** A common mistake is to derive operational metrics from
log volumes — counting log lines that contain "ERROR" and alerting when the count exceeds
a threshold. This pattern is expensive (log storage is 5–10x the cost of metric storage
at the same data rate), slow (log queries scan raw text rather than pre-aggregated numeric
time series), and imprecise (log levels are applied inconsistently; a single miscategorized
log level skews the alert). Meridian's rule: **alerts fire on Prometheus metrics, not on
log queries.** Logs are the drill-down tool, not the detection surface. The architectural
enforcement: the only Loki-based alerts in the alertmanager config are those that are
structurally impossible to express as metrics (for example, alerting on a specific error
message text that is not associated with a metric counter).

**Sampling removes rare requests from the trace record.** At 10% sampling, 90% of requests
produce no trace. This is acceptable for common request paths (there are many samples of
`GET /v1/tasks` to inspect), but it means a rare or intermittent error path may not be
represented in any trace. Meridian mitigates this with **priority sampling**: requests
that return a non-2xx response are always traced, regardless of the base sample rate. This
is configured via a custom Sampler in the OTel provider that checks the span status after
the request completes:

```go
// internal/telemetry/sampler.go
type errorForcedSampler struct {
    base trace.Sampler
}

func (s *errorForcedSampler) ShouldSample(p trace.SamplingParameters) trace.SamplingResult {
    // Always collect spans that carry an error attribute set by the handler
    if _, ok := p.Attributes.Value(attribute.Key("http.status_code")); ok {
        // Evaluated at span-end time; force-sample 5xx responses
        // (actual implementation hooks into the SpanProcessor, not the Sampler)
    }
    return s.base.ShouldSample(p)
}
```

The net effect: normal traffic is sampled at 10%, error traffic is sampled at 100%.
Engineers investigating incidents have a complete trace record for every failure path.

### Related Sections

- [See persistence-strategy → Connection Pooling with pgxpool](./persistence-strategy.md#connection-pooling-with-pgxpool)
  for the `pgxpool.Stat()` metrics that are exposed to Prometheus and used as pool-saturation signals.
- [See error-handling → Domain Error Type Hierarchy](./error-handling.md#domain-error-type-hierarchy)
  for how domain error types connect to metric labels (the HTTP status code on each metric data point
  derives from the domain error's `HTTPStatus()` method).
- [See operational-awareness → SLO Design and Error Budget Management](#slo-design-and-error-budget-management)
  for how the latency metrics produced here feed the SLO burn-rate alerts.

---

## SLO Design and Error Budget Management  [MID]

### First-Principles Explanation  [JUNIOR]

A **Service Level Objective (SLO)** is a target for a specific quality dimension of a
service — availability, latency, error rate — expressed as a percentage over a rolling
window. An SLO of 99.9% availability over 30 days means the service is allowed to be
unavailable for at most 0.1% of that window, or approximately 43 minutes per month.

The 0.1% that is permitted to be unavailable is the **error budget**. The error budget is
not a target to maximize; it is a risk pool. When the budget is full (no incidents this
month), the team can deploy more aggressively and take more risk. When the budget is nearly
depleted, the team should freeze risky changes and invest in reliability work. The error
budget makes the tension between velocity and reliability explicit and measurable.

An SLO requires a **Service Level Indicator (SLI)** — the metric that is actually
measured. Availability SLI: the ratio of successful responses to total responses. Latency
SLI: the fraction of requests that complete within a given time threshold.

### Idiomatic Variation  [MID]

Meridian maintains two SLOs for its core API surface:

**SLO-1: Availability on `GET /v1/tasks`**
- SLI: `(successful requests) / (total requests)` where successful means HTTP 2xx or 3xx
- Target: 99.9% over a 30-day rolling window
- Error budget: ~43 minutes per month of total downtime

**SLO-2: Latency on `POST /v1/tasks`**
- SLI: fraction of write requests that complete in under 1,000ms
- Target: 99.5% over a 30-day rolling window
- Error budget: 0.5% of write requests may exceed 1,000ms

The write SLO is looser than the read SLO (99.5% vs. 99.9%) because writes touch more
infrastructure: the pgxpool connection, the Postgres primary (writes cannot go to the
replica), the Redis idempotency key, and the Slack notification fanout. Each hop adds
latency variance. Setting the same SLO for writes as for reads would mean the error
budget is consumed primarily by expected write-path variance rather than by genuine
reliability problems — a signal-to-noise problem.

The SLOs are expressed as Prometheus recording rules and burn-rate alerts in the
alertmanager configuration:

```yaml
# prometheus/rules/slo-tasks.yaml
groups:
  - name: slo_tasks_availability
    rules:
      # SLI: request success rate (rolling 5-minute window for alerting)
      - record: meridian:task_read:success_rate5m
        expr: |
          sum(rate(http_requests_total{handler="GET /v1/tasks",code=~"2.."}[5m]))
          /
          sum(rate(http_requests_total{handler="GET /v1/tasks"}[5m]))

      # Burn-rate alert: if error budget depletes 14.4x faster than the SLO allows,
      # the budget is gone in 2 hours. Page immediately.
      - alert: TaskReadSLOCriticalBurn
        expr: |
          (1 - meridian:task_read:success_rate5m) > (14.4 * 0.001)
        for: 2m
        labels:
          severity: page
          slo: task_read_availability
        annotations:
          summary: "SLO critical burn: task read availability"
          description: >
            Error rate {{ $value | humanizePercentage }} is burning the 30-day error budget
            at 14.4x the sustainable rate. Runbook: https://runbooks.meridian.internal/slo/task-read
          runbook_url: "https://runbooks.meridian.internal/slo/task-read"
```

The **14.4x burn rate** is the multiwindow, multi-burn-rate alerting heuristic from the
Google SRE workbook: at 14.4x the normal error rate, the remaining monthly error budget
will be exhausted in approximately 2 hours. This is the threshold for an immediate page.
Slower burn rates (1x–5x) trigger ticket-priority alerts that do not wake engineers.

### Trade-offs and Constraints  [SENIOR]

**Choosing the SLO window matters more than choosing the target percentage.** A 30-day
rolling window means an incident from 29 days ago still affects today's error budget
balance. A 7-day window recovers faster but is more sensitive to short-term variation.
Meridian uses 30 days because the sales cycle is monthly and customers evaluate reliability
over the billing period. A different window would create a mismatch between the SLO
tooling's signals and the signals customers actually perceive.

**SLOs that are too tight teach the wrong lessons.** An SLO of 99.99% for a service that
genuinely achieves 99.9% means the error budget is always depleted and any change looks
risky. The team's behavior adapts accordingly: fewer deployments, more fear of change.
Meridian's 99.9% target was set by analyzing 12 months of historical uptime and setting
the SLO at the 10th percentile of historical performance — tight enough to represent a
real quality bar, loose enough that normal variation does not consume the budget. The
target is reviewed annually.

### Related Sections

- [See operational-awareness → Alerting Without On-Call Burnout](#alerting-without-on-call-burnout)
  for the full alert routing configuration that consumes these SLO burn-rate rules.
- [See release-and-deployment → Blast-Radius Reasoning Before Changes](#blast-radius-reasoning-before-changes)
  for how the error budget balance gates deployment risk decisions.
- [See performance-intuition → Latency Budgets](./performance-intuition.md) for the per-hop
  latency analysis that informed the 1,000ms write-latency SLO threshold.

---

## Alerting Without On-Call Burnout  [MID]

### First-Principles Explanation  [JUNIOR]

An alert fires when a metric crosses a threshold and wakes an engineer. If the engineer
can do nothing actionable — the metric is informational, the condition resolves itself, or
the threshold was set too low — the alert is noise. Repeated noise trains engineers to
ignore alerts. When a real incident fires the same-looking alert, it is ignored too.
Alert fatigue is the result: the alerting system loses its signal value.

Two principles mitigate alert fatigue:

**Alert on symptoms, not causes.** A symptom is something the user experiences: elevated
latency, elevated error rate, availability degradation. A cause is something in the system:
CPU usage, connection count, queue depth. Causes are often poor predictors of symptoms —
CPU can spike without causing user-visible latency; connection counts can be high without
causing errors. Alerting on causes produces high false-positive rates. Alert on symptoms
(the SLI degrading) and investigate causes once the alert fires.

**No alert without a runbook.** Every alert must include a `runbook_url` annotation that
links to a documented procedure for investigating and resolving the condition. An alert
without a runbook requires the on-call engineer to improvise under pressure, which is
slower and less reliable than following a documented procedure. If an alert cannot be
associated with a runbook because the response is always "wait and see," the alert should
be a ticket, not a page.

### Idiomatic Variation  [MID]

Meridian's alerting philosophy, in order of priority:

1. **SLO burn-rate alerts** (described above) are the primary paging surface. They fire on
   symptoms: the SLI is degrading at a rate that will exhaust the error budget.

2. **Saturation alerts** are secondary and generate tickets, not pages. They fire when a
   resource is approaching exhaustion and intervention is needed before the SLI degrades:

```yaml
# prometheus/rules/saturation.yaml
groups:
  - name: meridian_saturation
    rules:
      # pgxpool connection saturation — alert before the pool exhausts
      - alert: PgxpoolHighAcquireLatency
        expr: |
          histogram_quantile(0.95,
            rate(pgxpool_acquire_duration_seconds_bucket[5m])
          ) > 0.1
        for: 5m
        labels:
          severity: ticket
          component: postgres
        annotations:
          summary: "pgxpool acquire p95 > 100ms"
          description: >
            The connection pool is slow to hand out connections. Current p95 acquire
            time: {{ $value | humanizeDuration }}. Runbook: /runbooks/postgres/pool-saturation
          runbook_url: "https://runbooks.meridian.internal/postgres/pool-saturation"

      # Redis memory saturation
      - alert: RedisMemoryHighWatermark
        expr: |
          redis_memory_used_bytes / redis_memory_max_bytes > 0.85
        for: 10m
        labels:
          severity: ticket
          component: redis
        annotations:
          summary: "Redis memory > 85% of max"
          runbook_url: "https://runbooks.meridian.internal/redis/memory-saturation"
```

3. **Absence alerts** detect when a signal goes silent — which is often worse than the
   signal indicating a bad value. A Prometheus `absent()` alert fires if a pod stops
   emitting metrics entirely:

```yaml
      - alert: NoTaskMetricsReceived
        expr: absent(http_requests_total{handler="GET /v1/tasks"})
        for: 3m
        labels:
          severity: page
        annotations:
          summary: "No metrics from task read endpoint for 3 minutes"
          description: "Either all pods are down or the metrics pipeline has broken."
          runbook_url: "https://runbooks.meridian.internal/metrics/absent"
```

**The runbook contract.** Every alert annotation carries a `runbook_url`. The runbook at
that URL contains: (1) a one-paragraph description of what the alert means, (2) the first
three diagnostic commands to run, (3) the most common causes and how to confirm each, and
(4) the remediation steps. New alerts are not merged without a runbook — the CI pipeline
checks that every alert rule in `prometheus/rules/` has a `runbook_url` annotation.

### Trade-offs and Constraints  [SENIOR]

**CPU and memory alerts are not paging alerts at Meridian.** This is a deliberate departure
from legacy operations practice. High CPU does not automatically mean user impact; the
service has autoscaled, or the spike is transient, or the metric is misleading (CPU
includes Go's GC pressure which doesn't map linearly to user latency). High memory in a Go
service often indicates GC has not run yet, not a leak. Paging engineers for CPU or memory
produces fatigue without improving MTTR. The correct signal is the SLI (latency, error
rate); the saturation metrics exist for capacity planning, not for paging.

The cost of this choice: an engineer in the middle of a pool-exhaustion incident who has
not seen the saturation alert (because it was a ticket, not a page) will need to look at
the saturation dashboard proactively. The runbook for the SLO burn-rate alert includes
"check the saturation dashboard" as step two of the investigation sequence, so the
information is available without a separate page.

### Related Sections

- [See operational-awareness → SLO Design and Error Budget Management](#slo-design-and-error-budget-management)
  for the SLO burn-rate alert configuration these rules complement.
- [See operational-awareness → The pgxpool Exhaustion Incident](#prior-understanding-logging-everything-at-info-level-and-the-pgxpool-exhaustion-incident)
  for a real-ish scenario where the saturation alert (ticket-severity) did fire before the
  SLO burn-rate alert (page-severity).

---

## Tracing the Slack Webhook Fanout  [MID]

### First-Principles Explanation  [JUNIOR]

A distributed trace records the path of a single request as it moves through components.
Each component creates a **span** — a named unit of work with a start time, end time, and
attributes. Spans are connected in a tree: the root span is the inbound HTTP request; child
spans are the operations that request triggers. The trace tree makes it possible to see,
for a single request, exactly how time was spent at each step and in what sequence.

Logs cannot provide this. A log line tells the engineer what happened in one component at
one moment. If the same request touches five components, the engineer needs to correlate
five log lines by trace ID, mentally reconstruct the sequence, and estimate durations from
timestamps. The trace provides all of this automatically, structured, and visually.

### Idiomatic Variation  [MID]

Meridian's Slack webhook is an inbound endpoint: Slack sends HTTP POST requests when
workspace integrations fire events (a task is mentioned in a Slack channel, for example).
The request path is:

```
Slack → POST /v1/webhooks/slack → handler → idempotency check (Redis) →
event service → task repository (Postgres) → notification fanout
                                              ├── Slack outbound API call
                                              └── in-app notification (Postgres write)
```

Each step is instrumented as a span. The trace tree in Jaeger looks like:

```
[ROOT] POST /v1/webhooks/slack                        147ms total
  ├── [SPAN] idempotency.CheckAndRecord               3ms
  │     attrs: redis.command=SET, idempotency_key=evt_01HX...
  │     result: first_seen=true
  ├── [SPAN] event.ProcessSlackEvent                  138ms
  │     attrs: event_type=message.mentioned, workspace_id=ws_abc
  │     ├── [SPAN] task.repository.GetByExternalRef   12ms
  │     │     attrs: db.statement=SELECT tasks WHERE..., db.rows_affected=1
  │     ├── [SPAN] notification.fanout                122ms
  │     │     ├── [SPAN] slack.PostMessage            118ms  ← slowest child
  │     │     │     attrs: slack.channel=#ops, http.status_code=200
  │     │     └── [SPAN] notification.repository.Create  4ms
  │     │           attrs: db.statement=INSERT INTO notifications...
  └── [SPAN] response.write                           2ms
```

The trace immediately reveals that Slack's outbound API call consumed 118ms of the 147ms
total. This is not visible from logs without timestamp arithmetic, and it is not visible
from metrics (which aggregate across all requests — there is no per-request metric). Traces
answer the question that logs and metrics cannot: for this specific request, where did the
time go?

The instrumentation code in Go uses the OTel Go API directly:

```go
// service/notification.go — notification fanout with spans
func (s *notificationService) Fanout(ctx context.Context, event domain.SlackEvent) error {
    ctx, span := otel.Tracer("meridian").Start(ctx, "notification.fanout")
    defer span.End()

    // Slack outbound call
    slackCtx, slackSpan := otel.Tracer("meridian").Start(ctx, "slack.PostMessage")
    err := s.slackClient.PostMessage(slackCtx, event.Channel, formatMessage(event))
    if err != nil {
        slackSpan.RecordError(err)
        slackSpan.SetStatus(codes.Error, err.Error())
    }
    slackSpan.End()

    // In-app notification write
    notifCtx, notifSpan := otel.Tracer("meridian").Start(ctx, "notification.repository.Create")
    if writeErr := s.notifRepo.Create(notifCtx, event); writeErr != nil {
        notifSpan.RecordError(writeErr)
    }
    notifSpan.End()

    return err
}
```

What the trace surfaces that logs alone miss:

- **Concurrency visibility**: if the Slack call and the notification write were parallel,
  the trace shows overlapping spans. Logs would show interleaved lines without a clear
  parallel structure.
- **Attribution**: the 118ms is attributed to `slack.PostMessage` specifically, not to
  "the webhook handler was slow."
- **Error context**: a failed span has an error event attached with the full error message
  and stack, correlated to the exact point in the trace tree where the failure occurred.

### Trade-offs and Constraints  [SENIOR]

Instrumenting every span manually with `otel.Tracer("meridian").Start(...)` and `defer span.End()`
adds boilerplate to every service method. The alternative — using auto-instrumentation
middleware that wraps entire HTTP handler calls — captures the root span but misses the
internal span tree. Meridian's choice is explicit instrumentation for service and repository
methods, with automatic instrumentation for the Gin HTTP layer and the pgx database driver
(which has OTel hooks). The pgx OTel integration means every SQL query appears as a span
without manual instrumentation in the repository.

The cost of explicit instrumentation: spans must be added consciously when new code is
written. An uninstrumented code path is invisible in Jaeger. The enforcement mechanism is
the on-call runbook: "if a step in the expected trace tree is missing, instrument it" is
a standing action item in the incident post-mortem template.

### Related Sections

- [See error-handling → Idempotent Retry on the Slack Webhook](./error-handling.md#idempotent-retry-on-the-slack-webhook)
  for the Redis `SET NX` idempotency check that appears as the first span in the trace tree above.
- [See architecture → Cross-Cutting Concern: Notifications](./architecture.md#cross-cutting-concern-notifications)
  for the service layer design that the notification fanout spans live within.
- [See operational-awareness → Three-Pillar Observability](#three-pillar-observability-logs-metrics-and-traces)
  for the OTel initialization that backs the tracer used in the span above.

---

## Blast-Radius Reasoning Before Changes  [SENIOR]

### First-Principles Explanation  [JUNIOR]

Every change to a production system carries risk. The **blast radius** of a change is the
scope of damage if the change goes wrong: which users are affected, which features break,
and how quickly the system can be returned to a known-good state. Blast-radius reasoning
is the discipline of estimating and limiting this scope before the change is applied, not
after.

A change with a large blast radius affects all users, breaks critical features, and takes
hours to roll back. A change with a small blast radius affects a subset of users, degrades
a non-critical path, and rolls back in seconds. The goal is not to eliminate all changes
with large blast radii (some necessary changes are inherently broad), but to ensure that
the team understands the scope and has a documented rollback path before proceeding.

### Idiomatic Variation  [MID]

Meridian's deployment process requires completing a "blast-radius checklist" for any change
that touches the production Kubernetes cluster, database schema, or external service
configuration. The checklist is not a bureaucratic gate — it is a five-minute structured
thinking exercise captured in the PR description.

**Meridian blast-radius checklist:**

```
## Blast-Radius Assessment

### Scope
- [ ] Which API endpoints or features does this change affect?
- [ ] What fraction of the active tenant population is affected?
      (All tenants / specific plan tier / specific workspace IDs)

### Failure Mode
- [ ] If this change fails silently, what is the user-visible symptom?
- [ ] If this change fails loudly (panic, crash), what is the user-visible symptom?
- [ ] Is the failure mode reversible without data loss?

### Rollback
- [ ] Rollback mechanism: K8s rollout undo / feature flag / migration revert
- [ ] Estimated time to rollback: ___
- [ ] If the rollback fails, what is the manual recovery path?

### Deployment Window
- [ ] Safe to deploy during business hours?
- [ ] Does this change require maintenance mode or a traffic blackout?
- [ ] Who is on-call and aware this is deploying?
```

A schema migration on the 50M-row tasks table has a large blast radius (all tenants) but
a known rollback path (the two-deploy column-drop sequence from
[persistence-strategy → Online Migrations](./persistence-strategy.md#online-migrations-on-the-50m-row-tasks-table)).
A change to the Slack notification adapter has a small blast radius (notification delivery
only, non-blocking in the task assignment flow) and rolls back immediately via K8s rollout
undo. The checklist makes this difference explicit and on record.

**Deployment safety nets in the Kubernetes config:**

```yaml
# k8s/deployment.yaml — safety net configuration
spec:
  replicas: 6
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2          # At most 2 extra pods during rollout
      maxUnavailable: 0    # No pod removed until the replacement is Ready
  minReadySeconds: 30      # New pod must be healthy for 30s before next step
  template:
    spec:
      containers:
        - name: api
          readinessProbe:
            httpGet:
              path: /healthz/ready
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
            failureThreshold: 3    # Remove from LB after 3 consecutive failures
          lifeycleHooks:
            preStop:
              exec:
                command: ["sleep", "5"]  # Drain in-flight requests before SIGTERM
```

`maxUnavailable: 0` ensures zero downtime during normal deploys: the rolling update
adds a new pod, waits for it to pass the readiness probe for 30 consecutive seconds, then
removes one old pod. The `preStop` sleep drains in-flight requests before Kubernetes
sends SIGTERM. Together these give a deployment blast radius of "zero additional errors
introduced by the pod rotation itself" — all errors during a deploy come from the code
change, not from the deploy mechanics.

### Trade-offs and Constraints  [SENIOR]

The blast-radius checklist adds friction to the deployment process. That friction is the
point. An unplanned Friday-afternoon deploy that skips the checklist and fails at 5pm is
a much worse outcome than a deploy that was blocked until Monday because the blast-radius
assessment revealed that the change affects all tenants and there is no on-call engineer
aware of it.

The Meridian rule for high blast-radius changes: deploy between Tuesday and Thursday, not
on Fridays or before long weekends. This is not a process rule enforced by tooling; it is
a team norm enforced by code review. A PR opened on Friday afternoon for a schema
migration gets a comment requesting that it wait until Tuesday. The SLA error budget
provides the quantitative justification: a Friday deploy that causes a 30-minute outage
consumes 70% of the monthly error budget in one incident.

### Related Sections

- [See persistence-strategy → Online Migrations on the 50M-Row Tasks Table](./persistence-strategy.md#online-migrations-on-the-50m-row-tasks-table)
  for the specific migration patterns that inform the blast-radius assessment for schema changes.
- [See operational-awareness → SLO Design and Error Budget Management](#slo-design-and-error-budget-management)
  for the error budget that quantifies the cost of a high-blast-radius incident.

---

## Prior Understanding: Logging Everything at INFO Level and the pgxpool Exhaustion Incident  [MID]

### Prior Understanding (revised 2026-02-14)

The original Meridian logging strategy logged every request event at `INFO` level,
including individual SQL query completions, Redis `GET` and `SET` operations, and every
call to the notification service. The intent was "maximum visibility during incidents."
The effect was a log volume of approximately 120 GB per day across 6 pods.

The problems that emerged:

1. **Cost.** At the Loki retention price, 120 GB/day for 30-day retention was costing
   $1,800/month — more than the PostgreSQL managed instance. The signal-to-noise ratio
   was poor: 98% of log volume was routine success events with no incident relevance.

2. **Search latency.** A Loki query across 30 days of 120 GB/day logs took 45–90 seconds.
   During an incident, a 90-second wait for a log query is an eternity. Engineers stopped
   using Loki during incidents and relied on `kubectl logs` instead — which showed no
   historical context beyond the current pod's lifetime.

3. **The pgxpool exhaustion incident.** On a Friday afternoon, a background job that
   performed a large workspace export held connections open for 8–12 minutes per run.
   With 6 replicas at 25 connections each, and the export job running on 4 pods
   simultaneously, approximately 100 of the 150 total connections were held by export
   jobs. Remaining connections were insufficient for the API pods under normal load.
   The SLO burn-rate alert fired at 16:47. The on-call engineer opened Loki to search
   for `pgxpool` events and waited 80 seconds for the query to return. Meanwhile, the
   alert had been firing for 6 minutes and the error budget was burning at 18x.

   The runbook step "check pool acquire latency in Prometheus" was not yet written. The
   engineer found the saturation metric manually, confirmed pool exhaustion at 16:54, and
   scaled the export job's pod count to 1 (reducing its connection consumption). By 17:02
   the pool had recovered and the SLO alert cleared.

   The 15-minute MTTR was acceptable, but the 80-second Loki query was a diagnostic
   obstacle. Post-mortem action item: reduce log volume so Loki queries return in under
   5 seconds.

**Corrected understanding:**

The revised logging strategy follows three rules:

1. **Log at DEBUG for routine success paths; DEBUG is disabled in production.** Individual
   SQL query completions, Redis cache hits, successful notification deliveries — these are
   DEBUG-level events. In production, the logger's level is set to INFO, so these lines
   are never written. In development, setting `LOG_LEVEL=debug` enables them.

2. **Log at INFO for significant state transitions.** A request completed with an unexpected
   status. A background job started or finished. A configuration value was loaded. INFO
   events are the operational narrative — they tell the story of what the service did
   without every micro-step.

3. **Log at WARN for conditions that may require attention but are not errors.** A
   notification delivery was retried. A cache miss resulted in a slow path. Pool acquire
   latency exceeded 50ms on a single request.

4. **Log at ERROR for conditions that returned an error response to a user.** The domain
   error type's category (see
   [error-handling → Domain Error Type Hierarchy](./error-handling.md#domain-error-type-hierarchy))
   determines whether an error is logged at WARN (expected errors: 404, 422) or ERROR
   (unexpected errors: 500, 503). The distinction: a 404 means the user requested a
   resource that does not exist — not an operator concern. A 500 means the service
   failed to fulfill a valid request — always an operator concern.

After the revision, log volume dropped to 8 GB per day. Loki query time dropped to 2–4
seconds for a 30-day window. The $1,800/month logging cost dropped to $120/month. Log
query speed during the next incident (a Redis timeout in May 2026) was fast enough that
the on-call engineer used Loki as the primary investigation tool rather than falling back
to `kubectl logs`.

The post-mortem also produced two permanent runbook additions:

- The pgxpool saturation runbook (`/runbooks/postgres/pool-saturation`) now includes the
  Prometheus query for pool acquire latency p95 as step 1, before any log search.
- The export job's Kubernetes `Job` spec now sets `spec.parallelism: 1` to prevent
  multi-pod connection monopolization.

### Related Sections

- [See persistence-strategy → Connection Pooling with pgxpool](./persistence-strategy.md#connection-pooling-with-pgxpool)
  for the `MaxConns=25` and 6-replica configuration that determined the pool's ceiling.
- [See operational-awareness → Three-Pillar Observability](#three-pillar-observability-logs-metrics-and-traces)
  for the structured log levels and zap configuration that replaced the original strategy.
- [See operational-awareness → Alerting Without On-Call Burnout](#alerting-without-on-call-burnout)
  for the `PgxpoolHighAcquireLatency` saturation alert (ticket-severity) that was written
  as a post-mortem action item after this incident.

---

## Coach Illustration (default vs. hints)

> **Illustrative only.** The following is a worked example of how the two coaching styles
> differ for a task in this domain. It is not part of the live agent contract. Actual
> agent behavior is governed by the style files at
> `.claude/skills/learn/coach-styles/`.

**Scenario:** A learner is adding a new background job to Meridian that recomputes
workspace-level task statistics on a schedule, and asks the agent to instrument it for
observability.

**`default` style** — The agent produces the complete instrumentation: a `zap.Logger`
field injected into the job struct, a `prometheus.Histogram` for job duration, and an OTel
span wrapping the job's main loop. It adds the histogram registration to
`internal/metrics/` and the log calls at INFO (job started, job completed) and DEBUG
(per-workspace batch progress). It appends `## Learning:` trailers explaining the three-
pillar model, why per-batch progress is DEBUG not INFO, and the rule about not alerting
on log-derived metrics. The learner receives finished, working instrumentation.

**`hints` style** — The agent writes the logger and tracer fields on the job struct and
the histogram registration stub (name, help text, buckets — no registration call yet). It
emits:

```
## Coach: hint
Step: Register the job-duration histogram in internal/metrics/ and record observations
      at the end of each workspace batch.
Pattern: Three-pillar observability (metrics pillar) — histogram for duration, not gauge.
Rationale: A histogram captures the full latency distribution (p50, p95, p99) across
batch sizes; a gauge would only show the most recent duration, losing the distribution
shape needed to detect slow outlier workspaces.
```

`<!-- coach:hints stop -->`

The learner implements the registration and `Observe` call. On the next turn, the agent
responds to follow-up on where to add the OTel span without re-writing the metric code.
