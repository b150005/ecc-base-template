---
domain: release-and-deployment
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
> `.claude/learn/knowledge/release-and-deployment.md` and starts empty until agents enrich it
> during real work. Agents never read, cite, or write under `.claude/meta/references/examples/` —
> this tree is for human readers only. See
> [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md) for the design rationale.

---

## How to Read This File

Level markers indicate the intended audience for each section:
- `[JUNIOR]` — first-principles explanation; assumes no prior exposure
- `[MID]` — non-obvious idiomatic application in this stack
- `[SENIOR]` — non-default trade-off evaluation; names what is given up

---

## CI/CD Pipeline Shape  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

A **CI/CD pipeline** is an automated sequence of checks and operations that runs whenever
code changes. CI (Continuous Integration) validates every change automatically: compile,
lint, test. CD (Continuous Deployment or Delivery) packages validated changes and makes
them available for deployment, with or without a manual gate before production.

Without a pipeline, deployments are manual: a developer runs build commands locally,
pushes an artifact, and edits the server in place. This produces inconsistent builds
(different developer environments), skipped tests, and steps that cannot be reproduced.
A pipeline eliminates all three failure modes because the same sequence runs in a
controlled environment every time.

### Idiomatic Variation  [MID]

Meridian's pipeline runs in GitHub Actions and splits CI from deployment into two distinct
workflow files. CI runs on every push to any branch and on every pull request. The deploy
workflow runs only after CI passes on `main` — automatically for the frontend, with a
manual confirmation gate for the backend.

**CI workflow (`.github/workflows/ci.yml` — backend matrix):**

```yaml
jobs:
  backend:
    name: Backend — ${{ matrix.job }}
    runs-on: ubuntu-latest
    strategy:
      matrix:
        job: [lint, vet, unit, integration, build]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
          cache: true

      - name: lint
        if: matrix.job == 'lint'
        run: golangci-lint run ./...

      - name: unit
        if: matrix.job == 'unit'
        run: go test -race -count=1 ./... -short

      - name: integration
        if: matrix.job == 'integration'
        run: go test -race -count=1 -run Integration ./...
        env:
          TEST_DB_DSN: ${{ secrets.TEST_DB_DSN }}

      - name: build
        if: matrix.job == 'build'
        run: go build -o /dev/null ./cmd/server
```

The matrix fans five jobs out in parallel. The `integration` job is the only one touching
a real database (via a secret-injected DSN). The `build` job compiles to `/dev/null` to
catch "works in test, breaks at compile" failures that mocked tests miss.

**Image build and staging deploy (triggered on `main`):**

```yaml
  image:
    name: Build and push image
    needs: [ci-gate]     # reuses the CI workflow as a required gate
    runs-on: ubuntu-latest
    steps:
      - uses: docker/build-push-action@v5
        with:
          push: true
          tags: ghcr.io/meridian/backend:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy-staging:
    needs: image
    environment: staging
    steps:
      - name: Update staging image tag
        run: |
          kubectl set image deployment/meridian-backend \
            backend=ghcr.io/meridian/backend:${{ github.sha }} \
            --namespace=staging
```

Production deploy is a separate `workflow_dispatch` workflow. A team member triggers it
manually after observing staging for at least one hour.

### Trade-offs and Constraints  [SENIOR]

The matrix strategy produces nine concurrent jobs (5 backend + 4 frontend) per push —
roughly 900 runner-minutes per day at the team's commit cadence. Sequential CI would be
cheaper in runner cost but would push wall-clock feedback from ~3 minutes to ~12 minutes.
The team treats 3-minute CI feedback as a developer-experience priority; context-switching
during a 12-minute wait costs more than the runner budget.

The `ci-gate` job that re-runs CI inside the deploy workflow is redundant when the push
just triggered a fresh run. It costs ~2 minutes and makes the deploy workflow
self-contained: a manually re-triggered deploy still validates before building the image.

### Related Sections

- [See operational-awareness → Alerting Without On-Call Burnout](./operational-awareness.md#alerting-without-on-call-burnout)
  for the Datadog integration that fires a deployment marker when the K8s rollout completes.
- [See dependency-management → Transitive Dependency Auditing](./dependency-management.md#transitive-dependency-auditing)
  for how `go mod verify` and `pnpm --frozen-lockfile` enforce supply-chain integrity
  inside CI.

---

## Rolling Deploy in Kubernetes  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

A **deployment strategy** controls how a new version replaces the old one. Three are
common: **direct replacement** (stop old, start new — causes downtime), **blue-green**
(run two full environments simultaneously, switch traffic atomically), and **rolling**
(replace instances one at a time while the rest continue serving requests).

A rolling deploy works by gradually replacing old pods with new ones. The load balancer
routes traffic to healthy pods only. As each new pod passes its readiness probe, it joins
the pool. An old pod is terminated only after at least one new pod is ready. If the new
pods fail the readiness probe, the rollout pauses automatically — Kubernetes does not
proceed to the next replacement until the current one stabilizes.

### Idiomatic Variation  [MID]

Meridian's backend runs as 6 replicas. The `Deployment` manifest:

```yaml
# k8s/production/deployment.yaml
spec:
  replicas: 6
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    spec:
      containers:
        - name: backend
          image: ghcr.io/meridian/backend:PLACEHOLDER
          readinessProbe:
            httpGet:
              path: /healthz/ready
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
            failureThreshold: 3
          livenessProbe:
            httpGet:
              path: /healthz/live
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 10
```

`maxSurge: 1` allows one extra pod above the desired count during the rollout — up to 7
pods briefly. `maxUnavailable: 0` ensures no pod is terminated until a replacement is
ready. The cluster never drops below 6 pods during a deploy.

`/healthz/ready` checks Postgres and Redis connectivity before reporting ready. A pod that
cannot reach the database stays out of the load balancer pool; Kubernetes does not count
it as a successful replacement and does not terminate an old pod in its place.

### Trade-offs and Constraints  [SENIOR]

**Why not blue-green?** A blue-green strategy would require 12 pods during each deploy
instead of the normal 7, doubling compute cost for the deploy window. Meridian's 99.9%
SLA (~43 minutes error budget per month) is achievable with rolling updates; blue-green's
cost is not justified until the SLA tightens or the rollout window grows materially.

**Why not canary?** At 6 replicas, a canary pod receives ~1/7 of traffic — too small a
sample to detect errors with statistical significance before a monitoring window closes.
Canary becomes valuable when traffic volume is high enough that 5% of traffic provides
meaningful signal within a few minutes. The question is worth revisiting at ~500K daily
active users.

**Why `maxUnavailable: 0`?** Allowing one pod to be unavailable during the rollout would
reduce rollout time but drop Meridian from 6 to 5 pods at peak load windows. The 6-
replica count was sized for p99 load; operating at 5 during a deploy risks pushing p95
response times above the 200ms target the SLA is built around.

### Related Sections

- [See persistence-strategy → Online Migrations on the 50M-Row Tasks Table](./persistence-strategy.md#online-migrations-on-the-50m-row-tasks-table)
  for the migration patterns that must complete before new pods come up — enforced by the
  deploy workflow's migration-job gate.

---

## Database Migrations as a Deploy Gate  [MID]

### First-Principles Explanation  [JUNIOR]

A database migration is a versioned schema change. New application code that expects a
column not yet in the schema fails immediately. The ordering question is: should the
migration run before or after the new pods come up?

If the migration runs after the new pods, the new code runs against the old schema for
a brief window — queries fail. If the migration runs before the new pods, the old code
runs against the new schema. This is safe as long as the migration is **additive**:
new columns, new tables, new indexes. Old code ignores new columns; it does not break
when they exist.

This is the **expand-contract pattern**: expand the schema in a backward-compatible way;
the old code continues to work; the new code uses the expanded schema. Destructive changes
(drops, renames) require a separate, explicitly planned window and a separate runbook.

### Idiomatic Variation  [MID]

Meridian runs a Kubernetes `Job` before the rolling update starts. The job uses the same
container image but overrides the entrypoint to run `golang-migrate`:

```yaml
# k8s/production/migration-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: meridian-migrations-${{ github.sha }}
  namespace: production
spec:
  backoffLimit: 0   # fail fast; do not retry a partial migration
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: migrate
          image: ghcr.io/meridian/backend:${{ github.sha }}
          command:
            - /app/migrate
            - -database
            - $(DATABASE_URL)
            - -path
            - /app/migrations
            - up
```

The deploy workflow gates the rolling update on the job:

```yaml
      - name: Run migrations
        run: |
          kubectl apply -f k8s/production/migration-job.yaml
          kubectl wait --for=condition=complete \
            job/meridian-migrations-${{ github.sha }} \
            --timeout=300s --namespace=production
      # Step fails if kubectl wait times out or exits non-zero.
      # The rolling update step is never reached on migration failure.
```

`backoffLimit: 0` prevents a failed partial migration from retrying silently. If the job
fails, the deploy stops and the team investigates before proceeding. `golang-migrate`
tracks applied versions in a `schema_migrations` table, so re-running after a partial
failure is safe for idempotent DDL.

The additive-migration rule is enforced by code review, not by tooling. Deprecated columns
are left in place; application code stops writing them. Removal is scheduled in a separate
deploy window during low-traffic hours with an explicit runbook.

### Trade-offs and Constraints  [SENIOR]

The additive-migration rule accumulates dead schema weight. On the 50M-row `tasks` table,
an unused `TIMESTAMPTZ` column with a non-null default adds ~8 bytes per row — roughly
400 MB at full scale. The team schedules quarterly destructive windows paired with a
maintenance announcement and an explicit rollback plan.

The alternative — allowing destructive migrations in normal deploys — simplifies schema
cleanup but creates a rollback hazard. If a deploy is rolled back within 5 minutes (see
the Rollback section), a dropped column is gone and the reverted code cannot read it.
Rolling back a destructive migration is a restore operation, not a one-command undo. The
additive rule trades schema accumulation for guaranteed rollback safety; the quarterly
destructive window handles cleanup with an explicitly planned risk window.

### Related Sections

- [See persistence-strategy → Online Migrations on the 50M-Row Tasks Table](./persistence-strategy.md#online-migrations-on-the-50m-row-tasks-table)
  for the `NOT VALID`, `CONCURRENTLY`, and two-deploy column-drop patterns that
  additive migrations within a deploy window follow.
- [See testing-discipline → Contract Testing the Slack Integration](./testing-discipline.md#contract-testing-the-slack-integration)
  for how CI integration jobs run against a migrated schema to catch migration-code
  mismatches before they reach staging.

---

## Rollback Procedure  [MID]

### First-Principles Explanation  [JUNIOR]

A rollback reverts a deployed version to the previous known-good state. Every deployment
needs a defined rollback procedure. The procedure answers: what is the fastest path from
"this deploy is bad" to "the service is healthy again"?

Rolling back application code is cheap: the container image of the previous version is
cached in the registry; Kubernetes can redeploy it in under a minute. Rolling back a
database migration is expensive: it requires the inverse migration, which may be slow on
a large table and may not be possible without data loss if data was already written to
the new schema. This asymmetry shapes Meridian's design: additive migrations decouple the
code rollback from any schema decision.

### Idiomatic Variation  [MID]

**Policy:** If a deploy causes a production incident, the team has 5 minutes to decide:
roll back, or roll forward with a fix. After 5 minutes without a decision, the on-call
engineer initiates rollback by default.

**Application rollback (< 2 minutes):**

```bash
# Roll back to the previous Deployment revision
kubectl rollout undo deployment/meridian-backend --namespace=production

# Watch until all pods are on the previous image
kubectl rollout status deployment/meridian-backend --namespace=production

# Verify with a smoke test
curl -s https://api.meridian.app/healthz/ready | jq .
```

Because `maxUnavailable: 0` is set, the rollback itself is a rolling replacement — zero
downtime.

**Migration rollback decision tree:**

```
1. Is the rolled-back code compatible with the new schema?
   (Does it read/write only columns that existed in both old and new schemas?)
   YES → Leave the schema as-is. No migration rollback needed.

2. Was the forward migration additive only?
   YES → New schema has extra columns/tables the old code ignores. Safe; no rollback.
   NO  → Migration dropped or renamed something the old code needs.
         Escalate to DBA. Run inverse migration from runbook at
         docs/en/runbooks/migration-recovery.md. Accept possible data loss.
```

Under Meridian's additive-migration policy, the answer to step 1 or 2 is always "yes."
The decision tree is a safety check and an escalation path for rare destructive windows.

**Roll forward vs. roll back:** Rolling forward (deploying a fix) is preferred when the
defect is understood, the fix is small, and the deploy can complete within 15 minutes.
Rolling forward avoids re-deploying code with older regressions and avoids re-running
migrations on the next real deploy. The 5-minute window forces a choice: if the fix is
not ready in 5 minutes, roll back and debug under stable conditions.

### Trade-offs and Constraints  [SENIOR]

`kubectl rollout undo` reverts to the immediately preceding revision. If two deploys
happened in quick succession, `rollout undo` may land on an intermediate state that is not
actually safe. Meridian handles this by tagging every production deploy with the git SHA:

```bash
kubectl set image deployment/meridian-backend \
  backend=ghcr.io/meridian/backend:<known-good-sha> \
  --namespace=production
```

This bypasses revision history entirely and is appropriate when the revision stack does
not reflect the rollback target.

The 5-minute decision window is calibrated against the 99.9% SLA (43 minutes error budget
per month). An incident that runs 10 minutes before a rollback consumes 23% of the monthly
budget. Faster decisions preserve headroom for other incidents in the same period.

### Related Sections

- [See operational-awareness → SLO Design and Error Budget Management](./operational-awareness.md#slo-design-and-error-budget-management)
  for how the 43-minute monthly error budget is tracked and how deploy incidents consume it.
- [See persistence-strategy → Online Migrations on the 50M-Row Tasks Table](./persistence-strategy.md#online-migrations-on-the-50m-row-tasks-table)
  for the migration patterns that make the migration rollback decision always answer "safe"
  in the normal case.

---

## Prior Understanding: Deploy on Every PR Merge  [MID]

### Prior Understanding (revised 2026-01-15)

The original Meridian CI/CD design deployed the backend to production automatically on
every merge to `main`. The rationale was to minimize the gap between "code merged" and
"code in production." In practice, two recurring problems emerged:

1. **Migration timing surprises.** On three occasions, a migration that verified quickly
   locally took far longer against the 50M-row production database. The migration job
   exceeded its 5-minute timeout; the deploy workflow failed mid-way; the backend
   Deployment was left pointing at the old image while the migration had partially applied.
   Each incident required manual recovery.

2. **Insufficient staging soak time.** Auto-deploying to production meant staging existed
   for the duration of CI — roughly 3 minutes between staging and production deploys.
   Errors that appeared only under sustained load or specific customer data were invisible
   in that window.

**Corrected understanding:**

The current policy gates production backend deploys on a manual `workflow_dispatch` after
at least one hour of staging observation. The frontend (a static React build served via
CDN) continues to auto-deploy: frontend rollbacks are trivially fast (CDN cache
invalidation, no migration), and the one-hour soak is disproportionate to that risk
profile.

The lesson: "deploy on every merge" is appropriate for stateless services with trivial
rollback paths and is a risk to manage for services where rollback involves database
migrations or where production load conditions differ materially from staging. The right
cadence depends on rollback cost and environment parity, not a uniform principle.

---

## Coach Illustration (default vs. hints)

> **Illustrative only.** The following is a worked example of how the two coaching styles
> differ for a task in this domain. It is not part of the live agent contract. Actual
> agent behavior is governed by the style files at
> `.claude/skills/learn/coach-styles/`.

**Scenario:** A learner is implementing a new bulk-export feature for Meridian and asks
how to ship it safely given the 99.9% SLA requirement and the fact that the feature
requires a new database table and a schema migration.

**`default` style** — The agent produces the complete implementation plan: the additive
migration file (`bulk_export_jobs` table, nullable columns only), the feature flag
declaration in `config/flags.go`, the Kubernetes `Job` manifest for the migration, the
updated deploy workflow gating the rollout on migration completion, and a rollback
decision tree for this specific schema change. It appends `## Learning:` trailers
explaining the expand-contract migration pattern and the reasoning behind the manual
production deploy gate. The learner receives finished, actionable artifacts.

**`hints` style** — The agent writes the migration file stub (table name and columns
declared, indexes left as TODOs) and the feature flag stub in `config/flags.go`. It then
emits:

```
## Coach: hint
Step: Write the Kubernetes Job manifest for the migration and add the kubectl wait gate
to the deploy workflow before the rolling update step.
Pattern: Migration job gating (expand-contract; migrations run before new pods come up).
Rationale: If new pods start before the migration completes, queries to the new table
fail until the migration finishes — a window of errors consuming error budget. The Job
manifest ensures migrations complete successfully before Kubernetes proceeds with the
image swap.
```

`<!-- coach:hints stop -->`

The learner writes the Job manifest and the workflow gate. On the next turn, the agent
responds to follow-up questions about rollback without re-writing the migration or flag
scaffold.
