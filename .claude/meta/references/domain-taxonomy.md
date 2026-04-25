# Domain Taxonomy: Developer Learning Mode

> **Partially superseded.** [ADR-003](../adr/003-learning-mode-relocate-and-rename.md) (2026-04-24) renamed the feature from "Growth Mode" to "Learning Mode," moved domain files from `.claude/growth/notes/` to `.claude/learn/knowledge/`, and replaced the terms "notes/notebook" with "knowledge." The domain definitions, ownership matrix, and enrichment protocol in this document remain current. This file has been updated to reflect the new terminology and paths. The prior location of this file was `docs/en/growth/domain-taxonomy.md`.

This document defines the canonical knowledge domains into which Learning Mode knowledge accumulates, the agents that contribute to each domain, and the structure that domain files follow as they grow over time. This taxonomy describes the **knowledge pillar** only. The coaching pillar — which controls how agents work during a session rather than what they record afterward — is domain-agnostic and governed separately by the style files at `.claude/skills/learn/coach-styles/` and [ADR-004](../adr/004-coaching-pillar.md).

Developer Learning Mode is not a feature with a fixed curriculum. It is a mechanism for capturing teaching moments as they arise during real work. Knowledge is organized by domain, not by date. Over time, a domain file becomes a personal reference text built incrementally across many sessions — what this project calls a "textbook-in-progress."

---

## Purpose and Design Philosophy

### What Learning Notes Are

A Learning Note is a short, verifiable explanation attached to agent output that teaches *why* a decision was made. It names a pattern, cites a trade-off, or points to canonical documentation. Learning Notes never alter the artifact; they are post-deliverable annotations.

### What Knowledge Becomes

Individual knowledge entries accumulate in domain files under `.claude/learn/knowledge/`. A domain file is not a journal (chronological, session-keyed), not a wiki (curated by editors), and not a curriculum (ordered by pedagogical sequence). It is a **domain-organized reference text** where entries deepen, refine, and occasionally supersede each other over time. A developer who revisits a domain file weeks or months later should find it richer and more confident than the last time they read it.

### Why Domains, Not Sessions

Session-keyed notes (e.g., "2026-04-22 session notes") are useful for reflection but are ephemeral. A developer working on error handling benefits more from "all error-handling wisdom from all sessions in one file, cross-linked" than from "error-handling notes scattered across 20 session logs." Domains organize for reuse.

---

## Canonical Domain List (19 domains)

Each domain is a distinct knowledge area that grows as agents contribute during their work. Domains are listed here with their file names, scope definitions, and the lens by which each experience level learns in that domain. Beyond these 19 canonical domains, learners may open custom domain files as needed (e.g., "on-call-readiness," "accessibility-audit") organized under `.claude/learn/knowledge/custom/`.

### 1. architecture

**File**: `architecture.md`  
**Scope**: High-level system structure, module boundaries, layering, data flow, integration patterns, and architectural styles (layered, event-driven, microservices, etc.). Includes domain modeling and aggregate design. Does NOT include implementation details (loops, conditionals, variable naming), which belong in `implementation-patterns`.

**Junior lens**: Learns the vocabulary of architectural styles and why one is chosen over another for a given problem.  
**Mid lens**: Understands trade-offs between styles and recognizes when the chosen style is non-obvious for the problem domain.  
**Senior lens**: Evaluates architectural decisions against current and future constraints; recognizes cost/risk shifts that might warrant a style change.

**Likely sections over time**:
- Layered architecture — when to use it, costs of over-layering
- Event-driven patterns — event sourcing, CQRS, when they're justified
- Microservices — versus monolith, when scale justifies the complexity
- Domain-driven design — aggregate boundaries, ubiquitous language
- Anti-patterns — when the chosen style creates a mismatch with the problem

---

### 2. api-design

**File**: `api-design.md`  
**Scope**: API contracts, request/response shapes, versioning strategies, error codes, pagination, filtering, rate limiting, and idempotency. Covers REST conventions, gRPC patterns, and webhook design. Does NOT cover implementation (how to route or deserialize), which belongs in `implementation-patterns`.

**Junior lens**: Learns REST conventions and why endpoints are grouped/named the way they are.  
**Mid lens**: Understands versioning trade-offs and when to break vs. extend an API.  
**Senior lens**: Evaluates API design against client coupling, change velocity, and long-term maintenance cost.

**Likely sections over time**:
- REST resource hierarchy — flat vs. nested, why nesting is limited
- Error response formats — why this project uses the chosen envelope
- Pagination — cursor-based vs. offset-based, when each is appropriate
- API versioning — header-based vs. URL path, sunset windows
- Rate limiting and quotas — signal vs. denial, client experience

---

### 3. data-modeling

**File**: `data-modeling.md`  
**Scope**: Entity design, relationships, normalization vs. denormalization, aggregate boundaries (in the DDD sense), temporal data, state machines, and immutability of records. Does NOT cover schema syntax (SQL DDL) or database-specific features, which belong in `persistence-strategy`.

**Junior lens**: Learns why entities are structured the way they are and what aggregate boundary means.  
**Mid lens**: Understands when to normalize vs. denormalize and how to model temporal data (audit trails, SCD).  
**Senior lens**: Evaluates data model for consistency, auditability, and future query patterns.

**Likely sections over time**:
- Aggregate design — what belongs in one aggregate vs. separate
- Temporal modeling — audit logs, soft deletes, event timestamps
- Denormalization rationale — when copying data buys more than it costs
- State machines — modeling states vs. boolean flags
- Immutability contracts — append-only records, copy-on-write

---

### 4. persistence-strategy

**File**: `persistence-strategy.md`  
**Scope**: Database technology choice, schema design, indexing, query patterns, transactions, consistency models (ACID vs. eventual), and CRUD operation design. Covers relational, document, key-value, and time-series databases. Does NOT cover business logic on data, which belongs in `data-modeling`.

**Junior lens**: Learns why a particular database was chosen and basic indexing/query patterns.  
**Mid lens**: Understands consistency trade-offs and when eventual consistency is acceptable.  
**Senior lens**: Evaluates persistence decisions against availability, latency, and operational cost.

**Likely sections over time**:
- Database selection — relational vs. document vs. cache, why this project chose what it chose
- Indexing strategy — why certain columns are indexed, trade-offs with write latency
- Query patterns — N+1 prevention, JOIN strategies, aggregation
- Consistency models — ACID transactions vs. eventual consistency
- Operational concerns — backup, recovery, scaling

---

### 5. error-handling

**File**: `error-handling.md`  
**Scope**: Error types, error propagation, user-facing error messages, logging and observability of errors, recovery strategies, and defensive programming. Does NOT cover syntax (Result types vs. exceptions), which belongs in `language-idioms`.

**Junior lens**: Learns the error categories in this project and when each is used.  
**Mid lens**: Understands error propagation boundaries and when to translate errors across layers.  
**Senior lens**: Evaluates error strategy for observability, user experience, and operational recovery.

**Likely sections over time**:
- Error taxonomy — recoverable vs. fatal, user errors vs. system errors
- Boundary crossing — how errors are transformed between layers
- User-facing messaging — what information is safe to show, what is logged only
- Logging for observability — structured logs, context threads
- Fault tolerance — retry logic, circuit breakers, graceful degradation

---

### 6. testing-discipline

**File**: `testing-discipline.md`  
**Scope**: Test strategy, test structure, when to use mocks vs. integration tests, fixtures and test data, and the test pyramid. Does NOT cover test syntax (assertion libraries), which belongs in `language-idioms`.

**Junior lens**: Learns the AAA pattern and why each section matters.  
**Mid lens**: Understands when to mock, when to integrate, and how to avoid test coupling.  
**Senior lens**: Evaluates test strategy for speed, confidence, and maintenance cost.

**Likely sections over time**:
- The invariant ladder — what each test level (unit, integration, E2E) proves and why
- Mocking vs. integration — trade-offs, when each adds value
- Fixture design — inline vs. shared, preventing state coupling
- Test data strategies — factories, builders, realistic data
- Flakiness root causes and prevention

---

### 7. concurrency-and-async

**File**: `concurrency-and-async.md`  
**Scope**: Concurrent patterns, async/await, promises, callbacks, channel patterns, locks and synchronization, race conditions, and deadlock prevention. Language-specific idioms are noted, but the focus is on the patterns themselves.

**Junior lens**: Learns the mental model for concurrent execution and why certain patterns prevent race conditions.  
**Mid lens**: Understands async boundaries and when to block vs. wait.  
**Senior lens**: Evaluates concurrency strategy for throughput, latency, and resource utilization.

**Likely sections over time**:
- Concurrent execution models — threads, async/await, green threads, goroutines
- Synchronization patterns — locks, channels, atomic operations
- Race condition avoidance — immutability, isolation, synchronization
- Deadlock prevention — lock ordering, timeouts
- Async boundaries — when to spawn, when to join

---

### 8. ecosystem-fluency

**File**: `ecosystem-fluency.md`  
**Scope**: Language idioms, toolchain conventions, framework patterns, and community best practices. Covers Go interface design, Flutter null safety, Python dataclass vs. NamedTuple, TypeScript moduleResolution, idiomatic error types, and when to reach for stdlib vs. a package (the latter being the *principle* of choice, not the *decision* of which package). Does NOT cover package selection or version management, which belongs in `dependency-management`.

**Junior lens**: Learns the conventions of the language/framework—what "idiomatic" means and why it matters.  
**Mid lens**: Understands non-obvious idiom variations and when to apply each.  
**Senior lens**: Evaluates idiom trade-offs and knows when to break convention intentionally.

**Likely sections over time**:
- Language conventions — Go interfaces, Python dataclasses, Rust trait bounds, TypeScript generics
- Framework patterns — Flutter widget composition, Django ORM idioms, Axum macro-driven routing
- Idiomatic error handling — Go's error returns, Rust's Result type, Python's exception hierarchy
- Stdlib vs. external packages — principles of when to reach for each
- Standard naming and style — enum casing, function naming, struct field conventions
- Concurrency idioms — goroutines/channels, async/await, actor models

---

### 9. dependency-management

**File**: `dependency-management.md`  
**Scope**: Package selection, version constraints, transitive dependency management, vendor lock-in, and upgrade strategies. Covers both direct and transitive dependencies. Focuses on *supply chain* concerns and *version pinning decisions*, not idiom variations.

**Junior lens**: Learns why certain packages are chosen and how to reason about their stability.  
**Mid lens**: Understands transitive dependency risks and when to pin vs. allow ranges.  
**Senior lens**: Evaluates dependency cost (maintenance, security, vendor risk) vs. benefit.

**Likely sections over time**:
- Package selection — why this project depends on X instead of Y
- Version constraints — pinning vs. ranges, how to manage risk
- Transitive dependencies — when a transitive dep causes trouble
- Security updates — frequency, urgency, how to prioritize
- Vendor risk — when a package becomes unmaintained or hostile

---

### 10. implementation-patterns

**File**: `implementation-patterns.md`  
**Scope**: Code organization within modules, helper functions, variable naming, control flow (loops, conditionals), refactoring strategies, and code smells. Does NOT cover architecture or data modeling; does NOT cover syntax.

**Junior lens**: Learns the patterns the project uses for common tasks (pagination, filtering, state updates).  
**Mid lens**: Understands when to extract, when to inline, how to name for clarity.  
**Senior lens**: Evaluates implementation for readability, testability, and maintenance cost.

**Likely sections over time**:
- Common patterns — pagination, filtering, state updates in this stack
- Early return vs. nested conditionals — when to use each
- Extraction heuristics — when a helper function clarifies intent
- Naming conventions — booleans, collections, state variables
- Code smell indicators — duplication, long functions, god objects

---

### 11. review-taste

**File**: `review-taste.md`  
**Scope**: Code review heuristics, what signals a good design, common mistakes reviewers catch, and how to give actionable feedback without being prescriptive. This is the codification of taste — learned patterns about "good" that are hard to formalize.

**Junior lens**: Learns what reviewers look for and why certain patterns are preferred.  
**Mid lens**: Understands the reasoning behind preferences and when to challenge them.  
**Senior lens**: Develops a consistent, principled review philosophy and knows when to break rules.

**Likely sections over time**:
- CRITICAL vs. HIGH vs. MEDIUM signals — what each implies about severity
- Design review heuristics — what smells like a problem even if tests pass
- Testing depth — when tests are sufficient, when they're incomplete
- Naming clarity — when a name is a code smell in itself
- Trade-off judgment — when good-enough is better than perfect

---

### 12. security-mindset

**File**: `security-mindset.md`  
**Scope**: Common vulnerabilities, input validation, secret management, authentication and authorization design, and threat modeling. Does NOT cover security tools or scanning, which belongs in `operational-awareness`.

**Junior lens**: Learns the OWASP Top 10 in the context of this project's stack.  
**Mid lens**: Understands threat models and when a particular vulnerability is in scope.  
**Senior lens**: Evaluates architectural security choices and long-term risk posture.

**Likely sections over time**:
- Input validation — where to validate, how much to trust
- Secrets management — environment variables, secret vaults, rotation
- Authentication boundaries — where to trust tokens, where to re-check
- Authorization patterns — role-based, attribute-based, capability-based
- Common exploits in this stack — SQL injection, XSS, CSRF for this framework

---

### 13. performance-intuition

**File**: `performance-intuition.md`  
**Scope**: Algorithmic complexity, memory profiling, query optimization, caching strategies, and performance budgets. Does NOT cover observability/monitoring tools, which belongs in `operational-awareness`.

**Junior lens**: Learns O(n) notation and when linear becomes a bottleneck.  
**Mid lens**: Understands caching trade-offs and when optimization is premature.  
**Senior lens**: Evaluates performance against production constraints and user impact.

**Likely sections over time**:
- Algorithmic complexity — when O(n²) is acceptable, when it's not
- N+1 queries — recognition patterns, prevention strategies
- Caching trade-offs — hit rate, staleness, invalidation cost
- Memory profiling — when memory is the bottleneck
- Performance budgets — latency targets, why they're set

---

### 14. operational-awareness

**File**: `operational-awareness.md`  
**Scope**: Monitoring, logging, alerting, observability, incident response, capacity planning, and production concerns. The bridge between development and operations.

**Junior lens**: Learns what ops teams need from code and why structured logs matter.  
**Mid lens**: Understands SLOs/SLIs and how to instrument for operational visibility.  
**Senior lens**: Evaluates operational cost and long-term maintainability in production.

**Likely sections over time**:
- Logging for ops — structured logs, context threads, log levels
- Monitoring and alerting — what to expose, what thresholds matter
- Incident response — how to debug from logs/metrics, runbook patterns
- Capacity planning — what metrics predict scaling needs
- Cost drivers — what operations costs the most to run

---

### 15. release-and-deployment

**File**: `release-and-deployment.md`  
**Scope**: Release strategy, versioning schemes (semantic versioning), deployment pipelines, rollback procedures, and feature flags.

**Junior lens**: Learns the release cadence and what "semver" means in practice.  
**Mid lens**: Understands when to backport fixes and how to manage breaking changes.  
**Senior lens**: Evaluates release strategy against business velocity and risk tolerance.

**Likely sections over time**:
- Semantic versioning — when to bump major/minor/patch, backward compatibility
- Release candidates and testing — how much validation before production
- Deployment strategies — blue-green, canary, rolling, feature flags
- Rollback procedures — how to recover quickly from bad deployments
- Change management — how teams stay synchronized on releases

---

### 16. market-reasoning

**File**: `market-reasoning.md`  
**Scope**: Market sensing, competitor analysis, user segmentation, and understanding why a product wins or loses. Covers market forces, customer needs, positioning, and the business context that informs technical decisions.

**Junior lens**: Learns to connect code changes to user needs and market pressures.  
**Mid lens**: Understands competitive positioning and when market dynamics shift.  
**Senior lens**: Evaluates technical trade-offs against market opportunity and risk.

**Likely sections over time**:
- User segmentation — who uses this product, their needs, their pain points
- Competitor analysis — what other solutions exist, their strengths/weaknesses
- Market trends — what shifts are happening, how do they affect roadmap
- Positioning — why this product matters, what makes it win
- Go-to-market signals — which features drive adoption, which don't

---

### 17. business-modeling

**File**: `business-modeling.md`  
**Scope**: Unit economics, pricing strategy, revenue model reasoning, and business-model trade-offs. Covers how the business sustains itself, grows, and what technical decisions enable (or constrain) business goals.

**Junior lens**: Learns how the business model shapes what gets built and why.  
**Mid lens**: Understands unit economics and when a feature helps or hurts margins.  
**Senior lens**: Evaluates architectural decisions against revenue models and growth constraints.

**Likely sections over time**:
- Unit economics — per-customer cost, margins, break-even analysis
- Pricing models — subscription, tiered, usage-based, how each trades off
- Revenue levers — what drives growth, what limits it
- Customer lifetime value — retention, churn, expansion
- Cost structure — where the business spends, where it saves

---

### 18. documentation-craft

**File**: `documentation-craft.md`  
**Scope**: What makes documentation good, README architecture, ADR discipline, bilingual documentation strategy, doc freshness contracts, and how to write for maintenance. Covers the craft of clarity and structure that serves users years later.

**Junior lens**: Learns why documentation matters and how to write for clarity.  
**Mid lens**: Understands documentation as a design tool and debt repayment.  
**Senior lens**: Evaluates documentation strategy as a lever for team velocity and product quality.

**Likely sections over time**:
- README architecture — what sections serve what audience, front-matter patterns
- Architecture Decision Records — when to write them, what structure works
- Bilingual documentation — synchronization strategy, translation discipline, freshness contracts
- Doc-as-code — versioning, review, enforcement, drift prevention
- Technical clarity — when prose is better than examples, when to show code
- Deprecation messaging — how to retire features and APIs with minimal pain

---

### 19. ui-ux-craft

**File**: `ui-ux-craft.md`  
**Scope**: Design principles, visual hierarchy, typography, color and contrast, accessibility, interaction patterns, and what makes a user interface clear and usable. Covers the craft of design quality that delights users and communicates intent. Does NOT cover implementation (CSS, component code), which belongs in `implementation-patterns`.

**Junior lens**: Learns why design choices matter and how to recognize good hierarchy, spacing, and typography.  
**Mid lens**: Understands accessibility requirements and when design choices harm usability.  
**Senior lens**: Evaluates design system consistency and long-term design maintainability.

**Likely sections over time**:
- Visual hierarchy — scale contrast, color emphasis, spatial grouping
- Typography — font pairing, readability, scale systems (clamp, modular scales)
- Spacing and rhythm — intentional gaps, alignment, breathing room
- Color and contrast — semantic color use, WCAG AA/AAA compliance
- Interaction patterns — hover/focus/active states, feedback clarity
- Accessibility (a11y) — screen readers, keyboard navigation, reduced-motion preferences
- Design consistency — maintaining systems across components and states
- White space and composition — editorial layout, bento grids, depth

---

## Per-Agent Ownership Matrix

This table maps each of the 15 agents to the domains they primarily enrich (✓ primary) and secondarily contribute to (◐ secondary).

| Agent | Architecture | API Design | Data Modeling | Persistence | Error Handling | Testing | Concurrency | Ecosystem | Dependency | Implementation | Review Taste | Security | Performance | Operational | Release | Market | Business | Documentation | UI-UX Craft |
|-------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **orchestrator** | ◐ | ◐ | — | — | — | — | — | — | — | — | — | — | — | — | ✓ | — | — | — | — |
| **architect** | ✓ | ✓ | ✓ | ◐ | ◐ | — | — | ◐ | ◐ | — | — | ◐ | — | — | — | — | — | — | — |
| **product-manager** | ◐ | ✓ | ◐ | — | — | — | — | — | — | — | ◐ | — | — | — | ◐ | ◐ | — | — | — |
| **market-analyst** | — | — | — | — | — | — | — | — | — | — | — | — | — | — | — | ✓ | ◐ | — | — |
| **monetization-strategist** | — | — | — | — | — | — | — | — | — | — | — | — | — | — | — | — | ✓ | — | — |
| **ui-ux-designer** | ◐ | ◐ | — | — | — | — | — | — | — | ◐ | — | — | ◐ | — | — | — | — | — | ✓ |
| **docs-researcher** | — | — | — | — | — | — | — | ✓ | ◐ | — | — | — | — | — | — | — | — | — | — |
| **implementer** | ◐ | ◐ | ◐ | ◐ | ✓ | ◐ | ✓ | ✓ | — | ✓ | ◐ | ◐ | ◐ | ◐ | — | — | — | — | — |
| **code-reviewer** | ◐ | ◐ | ◐ | ◐ | ◐ | ✓ | ◐ | ◐ | — | ✓ | ✓ | ✓ | ◐ | — | — | — | — | — | — |
| **test-runner** | — | — | — | — | ◐ | ✓ | — | — | — | ◐ | ◐ | ◐ | ✓ | — | — | — | — | — | — |
| **linter** | — | — | — | — | — | ◐ | — | ◐ | — | ✓ | ◐ | ◐ | — | — | — | — | — | — | — |
| **security-reviewer** | ◐ | ◐ | — | ◐ | ◐ | ◐ | — | — | ◐ | ◐ | — | ✓ | — | — | — | — | — | — | — |
| **performance-engineer** | — | — | — | ◐ | — | ◐ | ✓ | — | — | ◐ | ◐ | — | ✓ | ◐ | — | — | — | — | — |
| **devops-engineer** | — | — | — | ◐ | — | — | — | — | ◐ | — | — | ◐ | — | ✓ | ✓ | — | — | — | — |
| **technical-writer** | — | — | — | — | — | — | — | — | — | — | — | — | — | — | — | — | — | ✓ | — |

**Key observations**:
- Every agent now has at least one primary domain ownership.
- **Implementer** leads in ecosystem-fluency (language/framework idioms), error-handling, concurrency, and implementation-patterns, reflecting that implementation depth requires fluency in the chosen stack.
- **Code-reviewer** owns review-taste and provides secondary depth in ecosystem-fluency and review-critical domains.
- **Linter** focuses on implementation-patterns, with secondary ecosystem-fluency (style rules reflect idiom).
- **Docs-researcher** leads ecosystem-fluency (verifying framework behavior) and supports dependency-management (checking package docs).
- **Devops-engineer** owns release-and-deployment and operational-awareness, with secondary dependency-management (for deployment supply chain).
- **Market-analyst** leads market-reasoning and supports business-modeling; **monetization-strategist** leads business-modeling.
- **Technical-writer** owns documentation-craft, the sole primary owner of that domain; other agents support secondarily through their own knowledge entries.
- **Architect** informs architecture, api-design, and data-modeling but delegates implementation details to implementer and reviewer.
- **UI-UX-designer** owns ui-ux-craft, the sole primary owner of design quality and user interface principles; provides secondary input to architecture and implementation on design integration.

---

## Note Entry Structure

Domain files grow over time. This section defines the shape they take.

### Front Matter

Every domain file starts with metadata:

```markdown
---
domain: architecture
last-updated: 2026-04-22
contributing-agents: architect, implementer, code-reviewer
---
```

Update `last-updated` whenever the file receives a new section or significant revision. Update `contributing-agents` as new agents add content.

### Body Organization

Content is organized by **concept**, not by date or session. Concepts are durable topics within the domain. For example, `architecture.md` might have concepts like "Aggregate Design," "Event-Driven Patterns," "Layering Anti-Patterns."

Within each concept:

1. **Concept Title** (H2, e.g. `## Aggregate Design`)
2. **First-Principles Explanation** (300-500 words, junior-grade) — Assume the reader has not encountered this concept before. Explain it clearly, concretely, with examples anchored to real code in the project.
3. **Idiomatic Variation** (200-300 words, mid-grade) — How does this project do it? What is non-obvious compared to textbook examples?
4. **Trade-offs and Constraints** (200-300 words, senior-grade) — When is this the right choice, and what does it cost? What are the alternatives and why were they rejected?
5. **Example (if applicable)** — A code snippet, a diagram (ASCII or description), or a reference to an ADR in `docs/en/adr/`.
6. **Related Sections** — Links to other concepts in this domain or neighboring domains that inform this one.
7. **Revision History** (if the concept evolved) — A dated sub-section titled "Prior understanding (revised YYYY-MM-DD)" containing the previous version or a summary of what changed.

### Example: Fully Worked Section

Below is a complete worked example from `testing-discipline.md` to show the shape. This is a real-depth entry (~500 words) that agents can reference and iteratively refine.

---

#### [From testing-discipline.md]

## The Invariant Ladder

The **invariant ladder** is a mental model for test coverage that clarifies what each test level *proves* and why you cannot skip intermediate rungs.

### First-Principles Explanation

A unit test proves that a function, given known inputs, produces the expected output. It runs in isolation: the database is mocked, external APIs are stubbed, only the function-under-test is real. Unit tests are fast (milliseconds).

An integration test proves that two or more components interact correctly. It mocks external boundaries (payment gateways, third-party APIs) but runs real database queries, real file I/O, and real network calls within your control. Integration tests are slower (seconds).

An E2E test proves that the system works as a user experiences it. A real browser, real backend, real database (or a production-like replica). E2E tests are slow (minutes).

Why these three levels? Because each level proves something the previous level cannot. A unit test cannot prove that your function works with the database schema it actually uses. An integration test cannot prove that the UI correctly interprets the API response. An E2E test is the final gatekeeper, but it is expensive to run frequently.

The project uses the **test pyramid**: many unit tests (cheap, fast), fewer integration tests (more expensive), few E2E tests (very expensive). The pyramid ensures that failures are caught early and expensive tests are reserved for the user-visible surface.

### Idiomatic Variation

This project structures unit tests as Arrange-Act-Assert (AAA):

```
Arrange: Set up all inputs and mocks
Act: Call the function
Assert: Check the result
```

The assertion section has no logic — no conditionals, no loops. If an assertion fails, the test line number points directly to the assertion, not to branching logic that decided which assertion to run. This makes failures immediately interpretable.

Integration tests here use fixtures constructed inline rather than shared via `beforeEach` hooks. Shared fixtures that accumulate requirements become a source of coupling: Test A and Test B both use the shared fixture, so changing Test A's requirements breaks Test B silently. Inline fixtures are slightly more verbose but prevent that coupling.

### Trade-offs and Constraints

Unit tests are cheap but can give false confidence: your function may work in isolation but fail when integrated. The cost of insufficient integration tests is failures that slip to staging or production. The cost of too many E2E tests is slow CI and long feedback cycles.

This project targets 80% unit test coverage, reserves integration tests for boundary-crossing code (database queries, API calls), and runs E2E tests for critical user flows only. This balances confidence against CI latency.

When you see an older file with 40% coverage, that is a migration candidate. When you see a new feature with zero tests, that is a CRITICAL code-review finding.

### Example

For a paginated query function:

- Unit test: Mock the database; assert that the function builds the correct SQL and handles an empty result set.
- Integration test: Use a real test database; assert that a query with 15 results correctly returns page 1 with 10 results and the correct `nextToken`.
- E2E test: A user clicks "load more," and the page appends new items without flickering.

Each test level proves something different. Skipping the integration test means you might not catch a SQL syntax error until the user tries it.

### Related Sections

- `error-handling` → "Logging for Observability": Failed tests are more useful when failures are logged with rich context.
- `review-taste` → "Testing Depth": How to judge whether a code reviewer's feedback on test coverage is constructive.
- `implementation-patterns` → "Early Return vs. Nested Conditionals": AAA tests prefer early return to keep assertions flat.

### Prior Understanding (revised 2026-04-20)

Earlier versions of this section conflated "unit test" with "mocked test." The distinction is sharpened here: a unit test isolates the function-under-test; an integration test integrates real components while mocking external boundaries. A test can be "isolated" but still integration-level if it runs real database code.

---

#### [From ecosystem-fluency.md]

## Accept Interfaces, Return Concrete Types (and Its Counterparts)

This principle describes one of the most idiomatic patterns across multiple languages: how to design boundaries that are flexible for the caller and clear for the implementer. The specific form varies by language, but the principle is consistent.

### First-Principles Explanation

When you design a function, you make two asymmetric choices: what you *require* from the caller (inputs) and what you *guarantee* to the caller (output).

Inputs: If you require the caller to pass a specific concrete type (e.g., a `DatabaseConnection` class), the caller can only use your function with that type. If the caller has a compatible thing (e.g., a mock connection) that is not that exact type, they cannot use your function. So the idiomatic move is to accept an **interface**: "anything that can execute queries." Now the caller can pass the real connection, a mock, a query logger that wraps the real connection — anything with the right method signatures.

Outputs: If you return an interface (e.g., "anything that is database.Connection"), the caller sees an opaque type. The real connection might have methods the interface doesn't expose. If the caller needs those methods, they have to cast the return value, introducing a type assertion that can fail at runtime. So the idiomatic move is to return a **concrete type**: the real connection object. The caller can downcast it mentally; the interface is a *documentation* of what you promise, not a ceiling on what is actually returned.

### Idiomatic Variation

**Go**: Functions accept `io.Reader` (interface) but return `*os.File` (concrete). This is idiomatic everywhere.

**Java/C#**: Methods accept `List<T>` (interface) but return `ArrayList<T>` or `List<T>` (concrete, though Java libraries lean toward interface returns for historical reasons).

**Python**: Accept duck-typed inputs (anything with `read()`) and return concrete instances (a real file object). Type hints may annotate with protocols for clarity.

**TypeScript**: Accept a type parameter or union type for flexibility; return a concrete union. Example: accept `string | Buffer`, return `string`.

**Rust**: Accept `impl Trait` (impl block, not a trait object) and return a concrete type. The compiler enforces this asymmetry.

### Trade-offs and Constraints

Accepting interfaces gives the caller flexibility. It enables mocking, composition, and decoupling.

Returning concrete types gives the caller access to the full capability of the object. It avoids the runtime cost of interface dispatch (negligible in most languages) but more importantly avoids the cognitive cost of "what can I actually call on this?"

The tension: If you return an interface, the caller knows exactly what you promised and no more. If you return concrete, the caller might rely on undocumented methods. The solution is documentation: "you may call these methods; treat others as private."

In libraries, this is often reversed: return an interface to signal stability and hide implementation details. In application code, return concrete because the full object is often what you need.

### Example

Logging in a service:

```go
// Go: accept interface, return concrete
func NewOrderService(log Logger) *OrderService { /* log is an interface */ }
func (s *OrderService) Log(msg string) error { /* returns nil or an error, concrete */ }

// Compare to a weaker design:
func NewOrderService(log *SyslogLogger) *SyslogLogger { /* breaks on mock */ }
```

In tests, you pass a mock Logger (any type with the right methods). The service returns a concrete error or nil.

### Related Sections

- `implementation-patterns` → "Extraction Heuristics": Knowing when an interface is worth defining vs. when it overcomplicates.
- `testing-discipline` → "Mocking vs. Integration": Why accepting interfaces is the gateway to testable code.
- `review-taste` → "Design Review Heuristics": Spotting interfaces that are too broad or too narrow.

---

End of worked example.

---

## Enrichment Protocol

This section describes how agents and the developer maintain and refine domain knowledge files.

### When to Create, Deepen, Refine, or Correct

An agent encountering a teaching moment consults this decision tree:

1. **Does a concept section exist for this topic?**
   - **Yes, and it is accurate**: Append a new sub-section within "Trade-offs and Constraints" or "Related Sections" if the teaching moment adds a nuance or a warning the existing section missed.
   - **Yes, but it is incomplete**: Deepen the section (add more examples, clarify a step) without marking it as revised. The revision is implicit.
   - **Yes, but it is inaccurate**: Mark it as "Prior Understanding (revised YYYY-MM-DD)" and write the correct version. Preserve the old text in the marked section.
   - **No**: Create a new concept section within the appropriate domain file.

2. **Does the concept belong in an existing domain, or is a new domain needed?**
   - If the concept fits the scope of an existing domain (as defined in the domain list), use that domain.
   - If the concept does not fit any existing domain, it signals that the domain taxonomy is incomplete. Discuss with the team before creating a new domain; otherwise, the taxonomy diverges.

### Preserving Revision History Without Clutter

When a section is corrected, the old understanding is not deleted. Instead, create a dated sub-section at the end of the concept:

```markdown
### Prior Understanding (revised 2026-04-20)

The earlier version of this section stated that [old claim]. This was incorrect/incomplete because [reason]. The corrected understanding is reflected above.
```

This preserves the learning journey: a developer who re-reads the file weeks later can see what changed and why. It also serves as a record if a future session needs to revisit the same debate.

### Cross-Linking

Within a domain file, link to related concepts in the same file using Markdown heading anchors:

```markdown
[See also: Aggregate Boundaries in the same domain](#aggregate-boundaries)
```

Across domain files, link explicitly by file name:

```markdown
[Performance impact of denormalization](../performance-intuition.md#caching-trade-offs)
```

This creates a web of connections without requiring a separate index. A developer who is learning about data modeling can follow links into related sections about performance and error handling.

### Voice and Tense for Long-Term Readability

Write domain knowledge files as if the reader will re-read them months later, out of session context:

- **Voice**: Neutral, explanatory, not session-personal. Avoid "we discussed," "I discovered." Use "the project," "this pattern," "research shows."
- **Tense**: Present tense for enduring truths ("event sourcing separates writes from reads"), past tense for project decisions ("this project chose PostgreSQL over MongoDB in 2025 because...").
- **Naming**: Name patterns and concepts explicitly. Avoid pronouns that require session context ("it was better" → "event sourcing adds observability at the cost of eventual consistency").

### Anti-Patterns to Avoid

Do NOT include:

- **Session-specific context** ("We were debugging the cache miss when I realized..."). The debug story is useful, but extract the principle.
- **Inside jokes or references** ("Like what happened in the Slack thread yesterday..."). Future readers have no Slack thread.
- **Tool version numbers without principles** ("We upgraded from Jest 27 to Jest 28 and..."). If the lesson is about Jest, state it; if the lesson is framework-agnostic (e.g., test isolation), don't tie it to a version.
- **Outdated links to issues** ("See PR #1234..."). Issues are closed, PR numbering changes across forks, links rot. Use ADRs or permanent doc sections instead.
- **Private PII or internal secrets** (customer names, internal email addresses, private API keys). The domain file is in the repository.
- **Blame or judgment** ("The old code was a mess because..."). Focus on the pattern, not the author.

---

## Domain Lens: What Each Level Learns

For each domain, this section describes what junior, mid, and senior developers are learning when they encounter Learning Notes in that domain.

| Domain | Junior Lens | Mid Lens | Senior Lens |
|--------|-------------|----------|-------------|
| **Architecture** | Name and vocabulary of architectural styles; why one is chosen | Trade-offs of styles; recognizing non-obvious choices | Cost of architectural change; risk of lock-in |
| **API Design** | REST conventions; why endpoints are structured a certain way | Versioning strategies; when to extend vs. break | Client coupling; long-term maintainability cost |
| **Data Modeling** | Entity relationships; aggregate boundaries | Temporal modeling; when to denormalize | Consistency guarantees; auditability for compliance |
| **Persistence** | Database choice; basic query optimization | Consistency models; when eventual is acceptable | Operational cost; scaling bottlenecks |
| **Error Handling** | Error types and when each is used | Error translation across layers | Error observability; impact on MTTR |
| **Testing** | AAA pattern; why mocking isolates tests | When to mock vs. integrate; fixture coupling | Test strategy alignment with risk tolerance |
| **Concurrency** | Mental model of concurrent execution; race conditions | Async boundaries; when to block | Throughput vs. latency trade-offs |
| **Ecosystem Fluency** | Language conventions and what "idiomatic" means | Non-obvious idiom variations; when to apply each | Intentional idiom-breaking; cost of conformity |
| **Dependency Mgmt** | Why certain packages are chosen | Transitive risk; version constraints | Vendor risk; long-term maintenance |
| **Implementation** | Common patterns in this stack | When to extract; naming for clarity | Readability cost of abstraction |
| **Review Taste** | What reviewers look for | Why preferences exist; when to challenge | Principled philosophy; rule-breaking wisdom |
| **Security** | OWASP Top 10 in this stack | Threat models; scope decisions | Architectural security; risk posture |
| **Performance** | Big-O notation; when linear is too slow | Caching trade-offs; premature optimization | Performance budgets; user impact |
| **Operational** | Why ops teams need structured logs | SLOs/SLIs; instrumentation | Operational cost drivers |
| **Release** | Semver meaning; release cadence | Backporting; breaking change management | Business velocity vs. risk trade-offs |
| **Market Reasoning** | User needs and market pressures shaping product | Competitive positioning; market shift signals | Market opportunity vs. technical feasibility |
| **Business Modeling** | How the business works; unit economics at high level | Pricing trade-offs; customer LTV levers | Revenue model constraints on architecture |
| **Documentation Craft** | Why clarity and structure matter; README sections | Doc-as-code; freshness contracts; bilingual sync | Documentation as strategic leverage for team scaling |
| **UI-UX Craft** | Visual hierarchy; why elements are positioned/colored a way | Accessibility impact; when design choices harm usability | Design system consistency; long-term maintainability |

---

## Sample Ecosystems After 20 Sessions

To make the taxonomy concrete, here are two example "state of notes" snapshots after many sessions in two different project types.

### Example 1: Flutter Mobile App

After ~20 sessions working on a Flutter mobile app, the `.claude/learn/knowledge/` directory looks like:

```
.claude/learn/knowledge/
├── architecture.md
│   - Widget composition patterns (inherited from Flutter conventions)
│   - State management: when Riverpod, when local State<T>
│   - Navigation architecture: named routes vs. RouteInformation
│   - Offline-first data sync
│
├── ecosystem-fluency.md
│   - Null safety idioms in Dart: when to use ! vs. ?
│   - Widget naming conventions: _MyWidgetState vs. MyWidgetPage
│   - BuildContext lifecycle and when to access it
│   - Extension methods for readable chains
│
├── testing-discipline.md
│   - The invariant ladder (adapted for Flutter)
│   - Widget testing: finding by key vs. text
│   - Golden tests for visual regression
│   - Integration test flakiness: awaiting futures
│
├── data-modeling.md
│   - Local-first models (diverges from web CQRS)
│   - Temporal data: conflict resolution on sync
│
├── implementation-patterns.md
│   - Freezed for immutable models
│   - StateNotifier patterns for state management
│   - Early return with guards in build methods
│
├── persistence-strategy.md
│   - Sqlite as local cache; when to sync to server
│   - Hive for key-value; when Sqlite is overkill
│
├── operational-awareness.md
│   - Crash reporting: stack traces from production
│   - Device diversity: testing across OS versions
│
└── release-and-deployment.md
    - App Store review cycles and rejection risk
    - Build versioning: calendar versioning vs. semver
    - Beta distribution: TestFlight workflow
```

Domains like `api-design` and `security-mindset` exist but are sparse (API design is inherited from backend team; security focuses on local storage and permissions).

### Example 2: Go Microservice

After ~20 sessions on a Go backend service:

```
.claude/learn/knowledge/
├── architecture.md
│   - Interfaces for dependency injection
│   - When to split services: monolith to microservice
│   - Event-driven boundaries with Kafka
│
├── api-design.md
│   - REST over gRPC trade-off (REST chosen for simple ops)
│   - API versioning: header-based, deprecated fields
│   - OpenAPI spec as source of truth
│
├── ecosystem-fluency.md
│   - Go interfaces: accept interfaces, return concrete types
│   - Error wrapping with fmt.Errorf and %w
│   - Package naming: no underscores, no stuttering (errors.Error vs. package.PackageError)
│   - Goroutines and context cancellation idioms
│   - Interface minimalism: one method is often enough
│
├── data-modeling.md
│   - Aggregate design: order aggregate includes line items
│   - Temporal models: created_at, updated_at, deleted_at
│
├── persistence-strategy.md
│   - PostgreSQL choice: why not MongoDB
│   - Indexes: user_id, created_at for common queries
│   - Migrations: forward-only, reversible
│
├── error-handling.md
│   - Custom error types: domain.ErrNotFound
│   - Error wrapping with context
│   - User-facing vs. logged-only errors
│
├── testing-discipline.md
│   - The invariant ladder with Go's testing package
│   - Table-driven tests for exhaustive coverage
│   - Testcontainers for integration tests
│
├── concurrency-and-async.md
│   - Goroutine patterns: fan-out/fan-in
│   - When channels, when sync.Mutex
│   - Context cancellation and timeouts
│
├── implementation-patterns.md
│   - Named return values: clarity vs. conciseness
│   - Helper functions: when early return beats deep nesting
│   - Functional options pattern for flexible construction
│
├── security-mindset.md
│   - Database parameterization: prevent SQL injection
│   - JWT validation: when to cache, when to re-check
│
├── operational-awareness.md
│   - Structured logging with zap
│   - Metrics: request latency, cache hit rate
│   - Traces: distributed tracing with OpenTelemetry
│
├── performance-intuition.md
│   - Connection pooling: tuning max connections
│   - Caching: Redis for hot data, when to invalidate
│
├── release-and-deployment.md
│   - Docker image: alpine vs. scratch
│   - Kubernetes deployment: rolling updates, resource limits
│   - Helm for dependency management
│
└── dependency-management.md
    - Go modules: when to vendor, when to use go.mod only
    - Indirect dependencies: why they're listed
    - Security updates: how to prioritize patches
```

In both cases, the domains are the same, but the content and depth reflect the project's specific concerns. A Flutter app has little in `api-design` but deep sections on `testing-discipline` (visual regression). A Go service has extensive `operational-awareness` (logging, metrics, traces) and `concurrency-and-async`.

---

## What NOT to Put in Knowledge Files

Agents and developers should explicitly exclude:

- **Session-specific commit SHAs** — "See commit abc123" links rot. Use ADRs or permanent sections instead.
- **Ephemeral tool versions** — Unless the lesson is about the tool's behavior, don't anchor notes to version numbers.
- **User PII** — No customer names, email addresses, internal identifiers.
- **Private secrets** — No API keys, passwords, or private configuration values.
- **Dated references to "current" state** — "As of April 2026, the framework doesn't support X." In 6 months, that may be false. Say instead, "The framework historically lacked X; if this has changed, update this section."
- **Session-specific narration** — "In this session we decided…" phrasing. Domain knowledge files are distilled into timeless concepts; the per-response knowledge diff is the only session-level record.
- **Blame or emotion** — "The old code was terrible." Instead: "Earlier versions used [pattern]; this was replaced because [reason]."
- **Quizzes or homework** — "Can you think of why we use event sourcing?" No. Explain the reason.
- **Affirmation or praise** — "Great job recognizing this pattern!" Stick to facts.

---

## Relationship to Other Learning Mode Files

This taxonomy document is the **reference**. Alongside it exist:

- **`.claude/learn/config.json`** — User's active level and per-agent scope. Not a knowledge file. Gitignored by default.
- **`.claude/skills/learn/preamble.md`** — The enrichment contract shared by all 15 learning-aware agents. It references this taxonomy.
- **`.claude/learn/knowledge/<domain>.md`** — The 19 canonical domain files plus any learner-opened custom domains. Created lazily on first teaching moment; enriched, deepened, and refined by agents over time. Gitignored by default; opt-in to share via `.gitignore.example`.

The flow is: **Agent encounters a teaching moment → Agent reads the relevant domain file → Agent decides add/deepen/refine/correct/new-domain → Agent applies the change non-destructively and reports the diff in its response → Future sessions open the same domain file and layer on further understanding.**

There is no chronological journal. The per-response "knowledge diff" in the chat output is the session-level provenance record; git history is the long-term audit trail.

---

## Versioning and Evolution

The domain taxonomy itself evolves:

1. **Domains are added** when new knowledge areas emerge across multiple sessions (e.g., "team-scaling" for lessons about coordination).
2. **Domains are merged** if two domains consistently reference each other and would be clearer as one.
3. **Domains are split** if a domain becomes so large (e.g., `architecture.md` grows beyond 10 major sections) that it is hard to navigate.

Changes to the taxonomy are recorded in this file's revision history, and ADRs are created if a taxonomy change signals a shift in the project's priorities.

---

## Getting Started: First Session with Learning Mode

A developer enabling Learning Mode for the first time should:

1. Read this taxonomy document to understand what domains exist.
2. Run `/learn on junior` to activate.
3. Work normally; agents will create and enrich domain knowledge files as teaching moments arise.
4. At the end of a session, review the per-response "knowledge diff" trailers to see which domain files were touched.
5. Open `.claude/learn/knowledge/<domain>.md` for any domain that was enriched to read the accumulated material.

Domain files do not exist on a fresh clone; `.claude/learn/knowledge/` is empty until agents encounter real teaching moments. The first enrichment for a domain creates the file using the seed shape defined in `.claude/skills/learn/preamble.md`.

---

## FAQ

**Q: What if two domains seem to overlap?**  
A: Domains are organized by concern, not by artifact type. There will be some overlap (e.g., "error handling" and "testing discipline" both care about exception safety). That is expected. Link between them. If you find yourself constantly jumping between two domains and they feel like one concept, raise the question: should they be merged?

**Q: Who maintains the domain files?**  
A: Anyone can contribute — agents during their work, developers reflecting on sessions, code reviewers surfacing patterns. There is no centralized curator. The repository is the owner; PRs review changes to knowledge files the same way they review code.

**Q: Can I delete a domain if it becomes irrelevant?**  
A: Domains are rarely deleted. Instead, mark them deprecated in the taxonomy and archive the file. A future project or team might find value in that knowledge.

**Q: What if an agent's understanding of a domain is wrong?**  
A: The domain file is not an agent's source of truth; it is a record of the team's understanding so far. If an agent (or a developer) finds a section inaccurate, open it, write the corrected version, and archive the old one in "Prior Understanding." The knowledge base evolves toward truth over time.

