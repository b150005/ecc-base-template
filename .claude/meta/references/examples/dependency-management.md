---
domain: dependency-management
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: implementer
contributing-agents: [implementer, security-reviewer, devops-engineer]
---

> **Read-only reference.** This file is shipped with the ECC Base Template as a worked
> example to illustrate what a populated knowledge file looks like after many sessions on
> a real project. It is **not** your knowledge file. Your own knowledge file lives at
> `.claude/learn/knowledge/dependency-management.md` and starts empty until agents enrich it
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

## The "Add a Dependency" Decision Tree  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

Every dependency added to a project is a long-term commitment. The dependency introduces
code that the project did not write, cannot fully audit on every update, and must maintain
compatibly as the dependency's own authors evolve it. The question "should I add this
package?" is not answered by asking "does it solve the problem?" Almost every package
solves the problem it advertises. The question is whether the cost of owning that
dependency over time is less than the cost of the alternative.

Three alternatives exist for any dependency candidate:

1. **Use the standard library.** Most languages ship with implementations of common
   operations: HTTP clients, JSON parsing, sorting, cryptographic primitives, time
   formatting. Standard library code is maintained by the language authors, changes only
   on major language versions, and introduces no external supply chain surface.

2. **Use a battle-tested third-party package.** When the standard library lacks the
   capability, or when a community package provides a materially better interface
   (fewer footguns, richer error messages, broader test coverage), a well-established
   package may be the right answer. "Battle-tested" means: in wide use, actively
   maintained, with a clear release cadence and a public issue tracker.

3. **Write it yourself.** When the problem is small, the interface requirements are
   unusual, and no existing package fits without significant wrapping, rolling the
   implementation reduces dependency surface and keeps the interface under the project's
   own control.

The decision tree Meridian applies at every candidate:

```
Does stdlib solve it cleanly?
  Yes → Use stdlib. Stop.
  No  →
    Is the capability non-trivial to implement correctly?
    (crypto, protocol parsing, distributed coordination)
      Yes → Is there a battle-tested package with >1 maintainer
             and a release in the past 12 months?
             Yes → Add the dependency with pinning policy (see below).
             No  → Re-evaluate; a single-maintainer package in this
                   category is a supply chain risk.
      No  → Is the implementation < 100 lines and well-bounded?
             Yes → Write it. Zero dependency surface.
             No  → Evaluate packages against the vendor risk checklist.
```

The "non-trivial to implement correctly" criterion is the hardest judgment. Cryptographic
operations are universally in this category: the correct answer is always a maintained
library (`golang.org/x/crypto`), never hand-rolled. HTTP client configuration is not in
this category: Go's `net/http` is full-featured enough that a thin wrapper on stdlib is
almost always sufficient.

### Idiomatic Variation  [MID]

In Meridian's Go backend, the stdlib boundary is drawn at the HTTP client and at standard
JSON marshaling. The project uses `net/http` directly for outbound HTTP calls to the Slack
SDK and to webhook consumers. It does not add a third-party HTTP client library.

On the TypeScript frontend, the boundary is drawn at data fetching. Rather than using
`fetch` with custom retry and caching logic, Meridian uses TanStack Query (`@tanstack/query`).
This is a deliberate exception to "use stdlib." The decision rests on the fact that
TanStack Query's stale-while-revalidate semantics, cache invalidation, and background
refetch behavior would require roughly 600–800 lines of correct hand-rolled code. That
line count and the associated edge cases (race conditions on concurrent fetches, memory
leak prevention on unmount) make this a "non-trivial" implementation in the decision tree.

### Trade-offs and Constraints  [SENIOR]

The decision tree forces an explicit cost/benefit articulation before any package lands in
`go.mod` or `package.json`. The cost of the tree is that it is slower than "find a
package, add it." The benefit is that it prevents dependency sprawl — a codebase where
dozens of packages each solve one small problem, each with its own release cadence,
security advisory surface, and potential for abandonment.

Meridian's Go `go.mod` has 14 direct dependencies after two years of development. A
comparable project that did not apply this filter might have 40–60. Each additional direct
dependency adds transitive dependencies, each of which is a potential supply chain risk
(see the section on transitive dependency auditing below). The filter cost at add-time is
roughly 10 minutes of evaluation; the ongoing cost of each removed dependency is zero.

The one failure mode of the decision tree: it can produce false confidence in the stdlib
path. `net/http` in Go is capable but verbose for outbound calls with retries and
backoff. The project has absorbed that verbosity; a future session that judges it
excessive should revisit whether a narrow HTTP client library is warranted.

### Related Sections

- [See ecosystem-fluency.md: Stdlib vs. External Packages](./ecosystem-fluency.md#go-stdlib-vs-third-party-the-meridian-policy)
  for the language-level principle that the decision tree operationalizes.
- [See security-mindset.md: Secrets Handling](./security-mindset.md#secrets-handling-vault-in-prod-env-example-in-repo-log-redaction-always)
  for the threat model that motivates the vendor risk checklist.

---

## Version Pinning Policy  [MID]

### First-Principles Explanation  [JUNIOR]

A dependency version constraint tells the package manager which versions of a package are
acceptable at install time. Constraints fall into two shapes:

- **Exact pin**: Install exactly version `1.4.2`. No newer patch or minor release will be
  used, even if available. The installed version is fully deterministic.
- **Range constraint**: Install the latest version satisfying `^1.4.0` (compatible with
  1.4.x through 1.x.x in npm's semver semantics). The installed version may change
  across installs if a newer compatible release is published.

The difference matters because a range constraint means two developers cloning the
repository on different days may install different versions of the same package. One may
have `1.4.3`; the other may have `1.5.1`. If `1.5.1` introduced a regression, their
development environments differ in a way that is difficult to diagnose.

Lockfiles (`go.sum`, `package-lock.json`, `pnpm-lock.yaml`) solve this problem by
recording the exact resolved version — and its cryptographic hash — at the time of
installation. Every subsequent install reads from the lockfile and resolves identically,
regardless of what the constraint says. Lockfiles are the pinning mechanism in practice;
the version constraint in `package.json` or `go.mod` is a statement of intent, not the
enforcement surface.

### Idiomatic Variation  [MID]

**Go side.** Go modules are exact by design. `go.mod` records the minimum version;
`go.sum` records the cryptographic hash of the resolved module tree. `go get` and
`go mod tidy` update both files explicitly. No implicit upgrades occur between those
operations. The policy consequence for Meridian is simple: commit `go.sum` to source
control, never gitignore it, and treat any unexplained `go.sum` change in a PR as
a code-review flag.

**npm/TypeScript side.** `package.json` uses caret ranges (`^`) for application
dependencies by convention, but this requires the lockfile to enforce determinism:

```json
// package.json — caret ranges with lockfile enforcement
{
  "dependencies": {
    "@tanstack/react-query": "^5.28.0",
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "typescript": "^5.4.5",
    "vite": "^5.2.8"
  }
}
```

The lockfile (`pnpm-lock.yaml`) records the exact resolved versions. Meridian's CI
runs `pnpm install --frozen-lockfile`, which refuses to install if the lockfile is
out of sync with `package.json`. This makes the lockfile the enforcement surface, not
the caret range.

The caret range is retained because it communicates intent: "we track the minor line."
If a developer runs `pnpm update @tanstack/react-query` to pull in a new minor, that is
expected behavior; the updated lockfile is committed in a dedicated update PR with a
CI-green gate. Automated patch updates are handled by Dependabot (see the Prior
Understanding section below).

**Exact pinning for GitHub Actions.** CI workflow files pin third-party actions to a
commit SHA, not to a version tag:

```yaml
# .github/workflows/ci.yml
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
- uses: actions/setup-go@d35c59abb061a4a6fb18e82ac0862c26744d6ab5  # v5.5.0
```

Tag-based pinning (`actions/checkout@v4`) is insufficient for supply chain security:
tags are mutable. A compromised tag can be moved to point at a malicious commit without
changing the workflow file. Commit SHAs are immutable; the pinned hash is cryptographically
bound to the exact code that ran at evaluation time. The human-readable version comment
(`# v4.2.2`) maintains readability without introducing the mutable reference.

### Trade-offs and Constraints  [SENIOR]

Exact SHA pinning for GitHub Actions means Dependabot opens PRs to update both the SHA
and the version comment when upstream actions release. The cost is one more Dependabot
PR class to review; the benefit is that a malicious tag move cannot silently run
arbitrary code in CI without a visible PR.

The caret-plus-lockfile strategy has one local-environment risk: a developer running
`pnpm install` without `--frozen-lockfile` may silently pull a new minor and commit
the lockfile change. Meridian closes this with a pre-commit hook that runs
`pnpm install --frozen-lockfile` and fails if the lockfile would change.

### Related Sections

- [See release-and-deployment.md: CI/CD Pipeline Shape](./release-and-deployment.md#ci-cd-pipeline-shape)
  for how Meridian's Dependabot policy maps to the pinning strategy described here.
- [See security-mindset.md: Secrets Handling](./security-mindset.md#secrets-handling-vault-in-prod-env-example-in-repo-log-redaction-always)
  for the threat model that motivates SHA pinning of GitHub Actions.

---

## Transitive Dependency Auditing  [MID]

### First-Principles Explanation  [JUNIOR]

A direct dependency is a package the project explicitly declares in `go.mod` or
`package.json`. A transitive dependency is a package that a direct dependency declares,
or that a transitive dependency of a transitive dependency declares. In large projects,
the transitive dependency graph can be 10–50x larger than the direct dependency list.

Transitive dependencies are code that runs in the project's process but that the project
did not select, did not review, and often does not know exists. A vulnerability in a
transitive dependency is the project's vulnerability: the project ships that code to
production. Supply chain attacks (a maintainer account is compromised, a package is
hijacked after abandonment, a dependency is quietly modified) often target transitive
packages because they are less visible than direct dependencies.

Two classes of risk exist in the transitive graph:

1. **Known vulnerabilities (CVEs).** A published Common Vulnerability and Exposure entry
   identifies a specific version range of a specific package as exploitable. Audit tools
   match the installed version graph against the CVE database and report matches.

2. **Unknown vulnerabilities.** No CVE exists yet, but the package has qualities that
   raise risk: unmaintained, single-maintainer, unusual post-install scripts, requests
   unexpected permissions. These require policy and human judgment, not automated tools.

### Idiomatic Variation  [MID]

Meridian runs two audit tools in CI, one per stack:

**Go side — `govulncheck`:**

```yaml
# .github/workflows/ci.yml (security job)
- name: Run govulncheck
  run: govulncheck ./...
```

`govulncheck` (from `golang.org/x/vuln`) cross-references the full module graph against
the Go vulnerability database and reports only vulnerabilities that are reachable from
code actually called in the binary. Unlike a naive CVE database match, `govulncheck`
performs dataflow analysis to eliminate false positives from packages that are imported
but never exercised on reachable code paths. This matters in practice: a vulnerability
in a database driver subpackage that Meridian never calls will not generate a finding.

**npm side — `npm audit`:**

```yaml
# .github/workflows/ci.yml (security job)
- name: Run npm audit
  run: pnpm audit --audit-level=high
```

The `--audit-level=high` flag filters out low and moderate severity advisories. This is
a deliberate policy choice: low-severity advisories in frontend transitive dependencies
are common, often theoretical (an attack that requires local code execution on the
developer's machine), and generate noise that causes teams to tune out all audit output.
Meridian treats moderate and low advisories as a backlog item reviewed monthly rather
than a CI gate. High and critical advisories block the build.

The monthly review of moderate and low advisories runs as a calendar-gated task: the
devops-engineer produces an audit report, evaluates each finding against Meridian's
attack surface (a B2B SaaS, not a public npm package; the frontend runs in user
browsers, not servers), and either resolves, accepts, or escalates each advisory.

### Trade-offs and Constraints  [SENIOR]

The `--audit-level=high` filter accepts that moderate and low vulnerabilities will exist
without blocking CI. Meridian accepts this for two documented reasons: most moderate
advisories in the frontend's transitive graph (Vite plugins, esbuild wrappers) describe
developer-environment attack scenarios that are not in scope for a cloud-deployed B2B
SaaS; and blocking on every moderate advisory would erode confidence in the CI gate by
requiring constant manual lockfile intervention unrelated to product changes. The accepted
posture is recorded in `docs/en/adr/` and reviewed quarterly by the security-reviewer.

### Related Sections

- [See security-mindset.md: Secrets Handling](./security-mindset.md#secrets-handling-vault-in-prod-env-example-in-repo-log-redaction-always)
  for the triage matrix that governs monthly moderate/low advisory review.
- [See release-and-deployment.md: CI/CD Pipeline Shape](./release-and-deployment.md#ci-cd-pipeline-shape)
  for the full CI workflow where `govulncheck` and `pnpm audit` run.

---

## Deprecation Handling: Migrating Away from a Replaced Package  [MID]

### First-Principles Explanation  [JUNIOR]

A dependency becomes deprecated when its authors stop maintaining it, announce an
official successor, or publish a version that breaks backward compatibility on a schedule
the project cannot absorb. Deprecation is not instant: a package can be formally
deprecated while still functioning correctly in production for months or years. The risk
accumulates over time — security vulnerabilities go unpatched, Go module compatibility
guarantees erode, incompatibilities with newer language versions appear.

The response to deprecation is migration: replacing the deprecated package with its
successor or with a stdlib equivalent, updating all call sites, re-running tests, and
removing the old import. The migration cost depends on how deeply the deprecated package
is coupled to application code. A package that is used in one file through a narrow
interface migrates in an afternoon. A package whose types appear throughout the codebase
migrates over weeks.

The coupling depth at migration time is almost always determined by decisions made when
the package was first added. A thin wrapper isolates the package's types from the
application; removing the wrapper requires changing one file. Direct use of the package's
types in domain types, service method signatures, and repository interfaces requires
changing every one of those sites.

### Idiomatic Variation  [MID]

Meridian encountered this directly when `github.com/gorilla/mux` — the HTTP router used
in the first version of the service — was archived by its maintainers in December 2022.
At the time of the migration decision (approximately 8 months after archival), `gorilla/mux`
was still functional but had received no security patches for two CVEs affecting versions
Meridian was using.

The migration target was Gin (`github.com/gin-gonic/gin`), which Meridian was evaluating
for its middleware ecosystem and performance characteristics. The coupling assessment before
migration:

- `gorilla/mux` types appeared only in `cmd/server/main.go` (router setup) and
  `internal/handler/*.go` (handler signatures accepting `http.ResponseWriter` and
  `*http.Request`).
- No domain types or service interfaces referenced `gorilla/mux` types directly.
  Handler functions accepted stdlib `http.ResponseWriter` and `*http.Request`, not
  `mux`-specific types.

This coupling profile meant the migration was a handler-layer change: swap the router
initialization in `main.go`, update handler signatures to accept `*gin.Context`, and
update the parameter extraction calls (from `mux.Vars(r)["id"]` to `c.Param("id")`).
The service layer, repository layer, and domain types were untouched.

The migration took two working days end-to-end: one day for the handler rewrites and one
day for CI stabilization (one integration test that constructed a full `gorilla/mux`
router needed to be updated to use `gin.New()`). The shallow coupling — stdlib interfaces
in handler signatures, not `gorilla/mux` types — was the deciding factor in migration
cost.

The lesson Meridian carried forward: when evaluating a new dependency, assess whether
the package's types will appear in signatures or types that span layers. If yes, wrap
the package in a thin adapter so the application-facing interface uses the project's own
types. The adapter changes; the call sites do not.

### Trade-offs and Constraints  [SENIOR]

The shallow coupling that made the `gorilla/mux` migration tractable was not a
deliberate architectural choice. It was the idiomatic Go approach — stdlib `http.Handler`
signatures — which happens to create a natural isolation layer. Teams that stored
`gorilla/mux`-specific types in domain structs or service method signatures had migration
costs an order of magnitude higher.

Gin itself now carries single-maintainer concentration risk. The decision tree criterion
("at least one maintainer actively releasing in the past 12 months") is currently met,
but if Gin were archived today, handler signatures using `*gin.Context` would require
touching all handler files. The service and domain layers would again be unaffected.
The criterion for triggering a new migration evaluation: no release in 18 months, or a
CVE that affects Meridian's routing code path directly.

### Related Sections

- [See ecosystem-fluency.md: Go Interface Naming Conventions](./ecosystem-fluency.md#go-interface-naming-conventions)
  for why stdlib interface types in handler signatures produced the shallow coupling
  that made this migration tractable.
- [See release-and-deployment.md: CI/CD Pipeline Shape](./release-and-deployment.md#ci-cd-pipeline-shape)
  for the PR process that larger dependency updates (including migrations) follow.

---

## Prior Understanding: Auto-Merging All Dependabot Updates  [MID]

### Prior Understanding (revised 2025-11-14)

Meridian's original Dependabot configuration enabled auto-merge for all dependency
update PRs — patch, minor, and major — provided CI passed:

```yaml
# .github/dependabot.yml — original (incorrect)
version: 2
updates:
  - package-ecosystem: "gomod"
    directory: "/"
    schedule:
      interval: "weekly"
    auto-merge: true   # ← applied to all update types
  - package-ecosystem: "npm"
    directory: "/frontend"
    schedule:
      interval: "weekly"
    auto-merge: true   # ← applied to all update types
```

This configuration was applied after reading Dependabot documentation that described
auto-merge as safe when CI is thorough. Two incidents revealed the assumption to be
incorrect:

1. A minor update to `@tanstack/react-query` from `5.17.x` to `5.28.0` included a
   behavioral change to the `staleTime` default. CI passed because the existing tests
   did not cover the stale data cache behavior. The change reached production and caused
   a cache-related regression where data was refetched more aggressively than expected,
   producing visible loading flickers in the task list view. The root cause was identified
   two days after the merge.

2. A minor update to a Go module (`github.com/redis/go-redis/v9`) changed the error
   type returned when a Redis connection is refused, from a wrapped `net.OpError` to
   a custom client error type. Meridian's error translation layer in
   `repository/idempotency.go` checked for `net.OpError` specifically. The check
   silently stopped working after the update; Redis connection failures began surfacing
   as 500 errors instead of the expected circuit-breaker behavior. The regression was
   detected by alerting, not by CI.

**Corrected understanding:**

Patch updates auto-merge after CI passes. Minor updates open a PR and require human
review before merge. Major updates are never auto-merged; they require an explicit
migration evaluation and a dedicated PR with a test coverage expansion.

The corrected Dependabot configuration:

```yaml
# .github/dependabot.yml — corrected
version: 2
updates:
  - package-ecosystem: "gomod"
    directory: "/"
    schedule:
      interval: "weekly"
    groups:
      go-patch-updates:
        update-types: ["patch"]
    # Minor and major updates open PRs without auto-merge; reviewed before merge.
  - package-ecosystem: "npm"
    directory: "/frontend"
    schedule:
      interval: "weekly"
    groups:
      npm-patch-updates:
        update-types: ["patch"]
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "monthly"
    # All Actions updates are SHAs; grouped monthly, reviewed before merge.
```

Patch-only auto-merge is defensible because semver patch versions are contractually
bug-fix-only — behavioral changes in a patch release are a semver violation and the
responsibility of the upstream maintainer. Minor versions by semver convention may add
new behavior; that new behavior may interact with application code in ways CI does not
cover. Human review catches behavioral change notes in the changelog before the merge.

The revised policy also introduced a requirement: every Dependabot minor-update PR
must be reviewed with the package's changelog open, not just with CI results. A CI-green
minor update that introduces a behavioral change the changelog documents but the tests
do not cover is a candidate for a test addition before merge.

### Related Sections

- [See testing-discipline.md: Prior Understanding: E2E Coverage Scope](./testing-discipline.md#prior-understanding-e2e-coverage-scope)
  for the test coverage gaps that allowed the TanStack Query regression to pass CI.
- [See release-and-deployment.md: CI/CD Pipeline Shape](./release-and-deployment.md#ci-cd-pipeline-shape)
  for the full Dependabot YAML and the PR review checklist that accompanies minor updates.

---

## Coach Illustration (default vs. hints)

> **Illustrative only.** The following is a worked example of how the two coaching styles
> differ for a task in this domain. It is not part of the live agent contract. Actual
> agent behavior is governed by the style files at
> `.claude/skills/learn/coach-styles/`.

**Scenario:** A learner is about to add a third-party Go rate-limiting middleware package
(`golang.org/x/time/rate` was the alternative considered) to Meridian's Gin router.
They ask the agent which package to use.

**`default` style** — The agent evaluates the decision against the "add a dependency"
decision tree. It notes that `golang.org/x/time/rate` is the Go extended standard library
(maintained by the Go team, no independent release risk) and provides a token bucket
limiter. It then contrasts a third-party middleware like `github.com/ulule/limiter` which
provides an HTTP middleware wrapper and Redis-backed distributed rate limiting. The agent
reasons through the two options: if Meridian needs per-IP rate limiting with Redis-backed
state shared across pods, the third-party package solves a genuinely non-trivial
coordination problem; if per-process in-memory limiting is sufficient, `x/time/rate` is
the right answer with a thin middleware wrapper written in-project. The agent asks which
scope is needed, then implements the chosen path. `## Learning:` trailers explain the
decision tree applied and the stdlib-extended vs. third-party trade-off.

**`hints` style** — The agent names the decision framework ("add a dependency decision
tree") and emits:

```
## Coach: hint
Step: Evaluate golang.org/x/time/rate vs. a third-party middleware against the dependency
      decision tree before choosing.
Pattern: Dependency decision tree — stdlib wins unless non-trivial implementation is needed.
Rationale: x/time/rate covers single-process limiting without an external dependency.
           If Redis-backed distributed limiting is required across Kubernetes pods,
           that need justifies a third-party package; otherwise, it does not.
```

`<!-- coach:hints stop -->`

The learner evaluates the scope requirement and returns with their chosen direction. On
the next turn, the agent implements the chosen path without re-explaining the decision
framework.
