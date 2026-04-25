---
domain: market-reasoning
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: market-analyst
---

> **Read-only reference.** This file is shipped with the ECC Base Template as a worked
> example to illustrate what a populated knowledge file looks like after many sessions on
> a real project. It is **not** your knowledge file. Your own knowledge file lives at
> `learn/knowledge/market-reasoning.md` and starts empty until agents enrich it during
> real work. Agents never read, cite, or write under `docs/en/learn/examples/` — this
> tree is for human readers only. See [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md)
> for the design rationale.

---

## How to Read This File

Level markers indicate the intended audience for each section:
- `[JUNIOR]` — first-principles explanation; assumes no prior exposure
- `[MID]` — non-obvious idiomatic application in this stack
- `[SENIOR]` — non-default trade-off evaluation; names what is given up

---

## Meridian's Positioning vs. Linear and Asana  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

Positioning describes what a product is for, who it is for, and why those people should
choose it over alternatives. Positioning is not marketing copy — it is an internal
compass that determines which features get built, which customers are pursued, and which
competitive battles are worth fighting.

A product with no positioning tries to win against everyone. In a competitive market like
task management, a product that attempts to beat Linear, Asana, Jira, Trello, Notion, and
every other alternative simultaneously is competing on every axis and likely winning on
none.

**Positioning as a decision tool:** when an engineer asks "should we build SSO?" and the
answer depends on whether the feature moves Meridian toward or away from its target
customer, positioning provides the answer. This is why market-reasoning is a
domain in a technical knowledge base: positioning is not just a sales deck — it shapes
what the engineering team builds.

### Idiomatic Variation  [MID]

Meridian's positioning, as established in the founding brief and validated against the
first 50 customers:

**Target segment:** Teams of 5–50 people who run primarily in Slack and do not want to
teach their team members a new task-management workflow. These teams have tried Asana
and found it too process-heavy; they have seen Linear but it targets engineering teams
with a strong opinions on issue tracking and is not built for cross-functional teams
(design, marketing, support working alongside engineering).

**Primary differentiator:** Slack-native. Meridian tasks can be created, assigned, and
updated directly from Slack commands and shortcuts, with no requirement to open the
Meridian web app for common operations. The web app is the "deep work" surface; Slack is
the "quick action" surface. This matches how small teams actually work: they live in Slack,
they do not want context-switching to manage tasks.

**Competitive comparison:**

| Dimension | Meridian | Linear | Asana |
|-----------|----------|--------|-------|
| Target team size | 5–50 | 5–200 (eng focus) | 10–500+ |
| Core workflow | Slack-native | Issue tracker | Project/portfolio |
| Pricing model | Per seat | Per seat | Per seat (tiered) |
| Setup time | < 1 hour | 2–4 hours | 4–8 hours |
| Key integration | Slack (primary) | GitHub (primary) | Multiple (none dominant) |

Meridian does not try to win on feature count or on price. It wins on reduced friction
for Slack-native teams.

### Trade-offs and Constraints  [SENIOR]

Slack-native positioning carries a dependency risk: Meridian's primary differentiator
depends on Slack's API stability, pricing, and platform governance. If Slack changes its
API (as it did when it deprecated the Outgoing Webhooks API in 2022), or if Slack's
pricing changes make it uneconomical for small teams, Meridian's primary integration
loses value. This dependency is accepted because the alternative — building a
collaboration layer from scratch — is not achievable at the current team and funding
level. The risk is tracked as a strategic dependency, and the product roadmap includes
a "calendar integration" workstream intended to reduce concentration on Slack alone.

The positioning also excludes the enterprise segment deliberately. Enterprise customers
need SSO, audit logs, SCIM provisioning, and compliance certifications. Building for
enterprise would shift the engineering team's focus away from Slack-native features and
toward compliance infrastructure. The market research team modeled the enterprise
opportunity as high revenue per customer but also high cost-to-serve and long sales
cycles; at Meridian's current ARR, the enterprise opportunity costs more to pursue than
it returns.

### Example (Meridian)

During the product-market fit phase, Meridian ran a positioning test: it presented two
variants of the landing page to different cohorts — one emphasizing "all-in-one task
management" (competing against Asana on breadth) and one emphasizing "Slack-first task
management for small teams" (the narrow positioning). The narrow positioning produced a
2.3x higher trial-to-paid conversion rate among teams of 5–50, validating the hypothesis.
The "all-in-one" positioning attracted larger teams (20–200) but with a much lower
conversion rate, confirming that the broader positioning was attracting users who were
comparing Meridian to Asana on feature completeness — a comparison Meridian was not yet
able to win.

### Related Sections

- [See market-reasoning → ICP Revision After 50 Customers](#prior-understanding-icp-revision-after-50-customers)
  for how this positioning was sharpened by real customer data.
- [See market-reasoning → Deferred Enterprise SSO](#deferring-enterprise-sso) for the
  product decision that enforces this positioning boundary in the roadmap.

### Coach Illustration (default vs. hints)

> **Illustrative only.** Not part of the live agent contract. Governed by
> `.claude/skills/learn/coach-styles/`.

**Scenario:** A learner (market-analyst) is asked to evaluate whether Meridian should add
Notion-style document embedding to compete for content-heavy teams.

**`default` style** — The agent evaluates the feature against Meridian's positioning
(Slack-native, small teams, low friction), assesses whether content-heavy teams are
adjacent to the current ICP, estimates the engineering cost vs. the TAM expansion, and
concludes that document embedding would attract a different segment and risk diluting the
Slack-native identity. The `## Learning:` trailers explain positioning as a decision
filter.

**`hints` style** — The agent names the evaluation framework (positioning filter: does
this feature move toward or away from our ICP?), names the risk (segment dilution), and
asks the learner to apply the framework to the specific feature. The learner produces the
evaluation; the agent responds to the analysis.

---

## SAM Calculation Methodology  [MID]

### First-Principles Explanation  [JUNIOR]

Market sizing uses three terms with specific meanings:

- **TAM (Total Addressable Market):** the total revenue if every possible customer
  bought the product at full price. TAM is theoretical; it ignores competition,
  distribution limits, and product fit.
- **SAM (Serviceable Addressable Market):** the portion of TAM that a given product
  can realistically pursue given its positioning, distribution channel, and geography.
  SAM filters TAM by "who can we actually reach and sell to?"
- **SOM (Serviceable Obtainable Market):** the portion of SAM that is realistically
  capturable given current team size, sales motion, and competitive position.

The most common mistake in market sizing is using TAM as the planning number. TAM
includes customers that the product cannot serve, cannot reach, or would not choose this
product even if they could be reached. SAM is the planning number because it represents
the actual competitive arena.

### Idiomatic Variation  [MID]

Meridian's SAM calculation used two methods and triangulated:

**Top-down method:**
- Global project management software market: ~$6B ARR (2025, third-party analyst estimate)
- Teams of 5–50 people (SMB segment): approximately 35% of total seats sold in the
  project management category (based on per-seat distribution from public earnings data
  from Asana and Monday.com)
- Slack users who run primary workflow in Slack: estimated 40–50% of SMB teams
  (based on Slack's published MAU data and third-party survey data on workflow tools)
- SAM: ~$6B × 35% × 45% ≈ **$945M**

**Bottom-up method:**
- US + EU companies with 5–50 employees using Slack as primary communication tool:
  estimated 2.1M companies (based on Slack's published workspace count and distribution
  models for team size)
- Willingness to pay $8–12 per user per month, average team size 18 users:
  ~$12/user × 18 users × 12 months = ~$2,600 ACV per company
- SAM: 2.1M companies × $2,600 ACV = **$5.5B**

The two methods diverge significantly, which is expected — top-down and bottom-up market
sizing almost never agree. Meridian used the bottom-up estimate as the planning number
because it is grounded in observable inputs (workspace count, team size distribution)
rather than analyst extrapolation. The top-down estimate provided a rough sanity check.

### Trade-offs and Constraints  [SENIOR]

Both methods carry significant uncertainty because the key input — the number of teams
that "run primarily in Slack" — is not publicly disclosed with precision. The 45%
estimate is derived from a 2024 survey of 1,200 SMB teams by a third-party researcher,
with a confidence interval wide enough that the real number could be anywhere from 30%
to 60%. This uncertainty propagates through the bottom-up calculation: the SAM could be
as low as $3.7B or as high as $8.2B.

For planning purposes, Meridian treats the SAM as "a few billion dollars, enough that
capturing a small fraction of it supports a large independent business." Precise SAM
figures matter for investor presentations more than for product decisions. For product
decisions, the more useful question is: "is this specific feature likely to expand our
SAM or contract it?" Positioning analysis (above) answers that question without requiring
precise market size numbers.

### Example (Meridian)

The bottom-up SAM model is maintained in a spreadsheet and reviewed quarterly. The key
driver assumptions (Slack workspace count, team size distribution, conversion rate) are
updated when Slack publishes new data. The model is not a forecast — it is a reality
check on whether the business has room to grow before hitting market saturation.

### Related Sections

- [See market-reasoning → Meridian Positioning](./market-reasoning.md#meridians-positioning-vs-linear-and-asana)
  for the segment boundaries that define the SAM.
- [See business-modeling → Unit Economics](./business-modeling.md#unit-economics-at-15m-arr) for
  how the SAM feeds into revenue projections and growth targets.

---

## Deferring Enterprise SSO  [SENIOR]

### First-Principles Explanation  [JUNIOR]

Enterprise software buyers have security and compliance requirements that small-team
buyers do not have. Single sign-on (SSO) via SAML or OIDC allows enterprise IT
departments to manage access centrally — one policy controls access to all enterprise
tools, including Meridian. For a team of 5, SSO is unnecessary complexity. For a 500-person
company with an active IT security function, SSO is a non-negotiable purchase requirement.

Building SSO is not simply adding an OAuth flow. It requires SAML/OIDC protocol support,
a just-in-time provisioning system, a directory sync for offboarding, and usually an audit
log to satisfy security review. The engineering investment is significant — typically 6–12
weeks for a backend team of two.

### Idiomatic Variation  [MID]

Meridian deferred enterprise SSO until reaching $1.5M ARR. This was a deliberate product
decision made in the founding sprint and reviewed quarterly. The reasoning:

1. Meridian's target ICP (5–50 person teams) does not require SSO. The first 50
   customers were surveyed; zero cited SSO as a purchase blocker.
2. The engineering investment (6–12 weeks) is better spent on Slack integration depth
   and calendar integration — features that directly move the product toward the ICP.
3. Enterprise deals without SSO close more slowly and with higher churn. Attempting
   enterprise sales before SSO is ready costs more in sales time than it returns in
   ARR.

The $1.5M ARR trigger was chosen because at that ARR level, a single enterprise deal
worth $50K ARR represents meaningful expansion, and the engineering investment in SSO
has a clear payback period.

### Trade-offs and Constraints  [SENIOR]

Deferring SSO means turning down enterprise inbound leads. Meridian received seven
inbound requests from companies with 100+ employees during the period when SSO was
deferred. All seven cited SSO as a requirement. Six of the seven did not convert; one
converted without SSO after a manual exception process (shared-credential management
via a password manager, which is a security risk the customer accepted in writing).

The counterfactual — what would those six deals have been worth if SSO were already
built — is a recurring board conversation. The market-analyst team modeled the scenario:
assuming the six leads would have converted at an average ACV of $18K (100-person company,
$15/user), that is $108K ARR left on the table over the deferral period. The engineering
cost of building SSO (6–12 weeks of two engineers) at Meridian's fully-loaded cost was
approximately $120K–$180K. The net expected value of deferral was approximately zero in
the short term but positive in the long term because the 6–12 weeks were spent on
Slack-native features that drove SMB conversion rates — the core business.

The decision to defer is not permanent and is not a statement that enterprise is not
worth pursuing. It is a resource allocation decision made under uncertainty, reviewed
quarterly, and subject to reversal if the inbound enterprise pipeline grows large enough
that the deferral cost exceeds the opportunity cost of building SSO.

### Example (Meridian)

The $1.5M ARR trigger was hit in Q1 2026. SSO development began in March 2026 and is
targeting a Q3 2026 launch. The first enterprise deals in the pipeline have been notified
of the launch timeline.

### Related Sections

- [See market-reasoning → Meridian Positioning](./market-reasoning.md#meridians-positioning-vs-linear-and-asana)
  for the segment boundaries that made enterprise SSO non-critical in the SMB phase.
- [See business-modeling → Unit Economics](./business-modeling.md#unit-economics-at-15m-arr) for
  the ACV and CAC differences between SMB and enterprise that inform this trade-off.

---

## Prior Understanding: ICP Revision After 50 Customers  [SENIOR]

### Prior Understanding (revised 2026-01-09)

The original Ideal Customer Profile (ICP) defined Meridian's target customer as
"any team that uses Slack" — a broad framing intended to maximize the addressable
market. After the first 12 months and 50 paying customers, the ICP was revised based on
cohort analysis.

**Original ICP (incorrect):** Any team using Slack as its primary communication tool,
across all team sizes and industries.

**What the data showed:**

Cohort analysis across 50 customers revealed two distinct behavioral patterns:

1. **Fast-to-value, high-retention cohort (team size 5–30, Slack-first workflow):**
   These customers activated the Slack integration within 48 hours, created their first
   task in Slack within the first week, and retained at 85% after 6 months. Average ACV:
   $1,200. Support tickets per customer per month: 0.8.

2. **Slow-to-value, high-churn cohort (team size 30–200, multi-tool workflow):**
   These customers often bypassed the Slack integration entirely, used the web app as
   their primary surface, and retained at 42% after 6 months. Average ACV: $4,100 (higher
   because of larger team size, but churn-adjusted LTV was lower). Support tickets per
   customer per month: 2.4.

The second cohort was also buying Meridian for reasons unrelated to the Slack
integration — they wanted a lighter-weight Asana. Meridian was not differentiated for
them; it simply appeared as "Asana but cheaper" during a trial. When those customers
found Asana's features they needed but Meridian lacked, they churned.

**Corrected ICP (2026-01-09):** Teams of 5–50 people where Slack is the primary
communication and coordination tool, where the team works across functions (not
engineering-only), and where the team lead has expressed dissatisfaction with the
complexity of Asana or Jira.

**Operational impact:** Marketing removed broad Slack-user targeting and added explicit
"Asana is too complex for us" messaging. Sales qualified out leads where the primary
use case was replacing Jira (engineering-only teams, which skew toward Linear). The
product roadmap de-prioritized features requested only by the second cohort (Gantt
charts, portfolio views) and prioritized features the first cohort requested (Slack
reminder integration, recurring task support).

**The principle this illustrates:** ICP is a hypothesis at founding. It should be treated
as a falsifiable prediction and revised when cohort data contradicts it. The revision cost
(deactivating some marketing campaigns, declining some sales leads) is lower than the cost
of building a product for a customer who will churn at 42%.

### Related Sections

- [See market-reasoning → Meridian Positioning](./market-reasoning.md#meridians-positioning-vs-linear-and-asana)
  for the positioning that this revised ICP now informs.
- [See market-reasoning → SAM Calculation Methodology](./market-reasoning.md#sam-calculation-methodology)
  for how this ICP revision affected the SAM estimate.
