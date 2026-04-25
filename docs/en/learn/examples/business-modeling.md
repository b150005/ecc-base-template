---
domain: business-modeling
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: monetization-strategist
contributing-agents: [monetization-strategist, market-analyst]
---

> **Read-only reference.** This file is shipped with the ECC Base Template as a worked
> example to illustrate what a populated knowledge file looks like after many sessions on
> a real project. It is **not** your knowledge file. Your own knowledge file lives at
> `learn/knowledge/business-modeling.md` and starts empty until agents enrich it during
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

## Three-Tier Per-Seat Pricing  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

A **pricing tier** is a published bundle of capability sold at a fixed price per unit
(in B2B SaaS, per user per month). A **tiered structure** offers two or more bundles
so customers with different willingness-to-pay can self-select.

Tiering exists because willingness-to-pay is not uniform: a five-person agency cannot
justify what a 40-person team needing SSO will. A single price either leaves money on
the table or closes out the smaller buyer. The naive design is "more features = higher
price," producing a ladder with no **anchor tier** — the tier the pricing page is
designed to sell. A well-designed set has one anchor, one cheaper tier that widens the
funnel, and one premium tier that captures higher willingness-to-pay.

### Idiomatic Variation  [MID]

Meridian sells three tiers, all per user per month, billed annually:

| Tier | Price | Inclusions | Excludes |
|------|-------|------------|----------|
| Starter | $10/user/mo | Web app, task board, basic notifications | Slack/calendar, SSO, audit log |
| Team | $20/user/mo | Starter + Slack, calendar sync, recurring tasks | SSO, audit log |
| Business | $35/user/mo | Team + SSO (SAML/OIDC), audit log, advanced roles, priority support | — |

The **Team** tier is the anchor: it carries the Slack integration that defines
Meridian's positioning. Roughly 78% of paying seats sit on Team. The breakpoints
($10 → $20 → $35) are roughly geometric (2x, 1.75x), not linear. Geometric spacing
makes the upgrade decision qualitative ("do we need Slack integration?") rather than
quantitative. Linear spacing — $10, $15, $20 — invites negotiation downward; geometric
spacing makes the cheaper tier visibly less serious.

### Trade-offs and Constraints  [SENIOR]

Three tiers cost more to operate than two: three SKUs, three feature flags, three
sales motions, three cohorts. A single-paid-tier design would be simpler but would
miss the SSO segment and leak revenue from larger accounts.

Starter has a defensible critic: it converts low-quality trials and generates support
load disproportionate to its revenue. The counter-argument is that Starter doubles
top-of-funnel and ~14% of net new ARR comes from accounts that started on Starter and
grew. Standing rule: if Starter-to-Team conversion falls below 30% within 90 days, the
tier is reopened for review.

Business is constrained by capability, not price. Until SSO shipped (see
[market-reasoning → Deferring Enterprise SSO](./market-reasoning.md#deferring-enterprise-sso)),
Meridian could not list a real Business tier — only a "contact sales" placeholder that
produced one closed deal in 18 months.

### Example (Meridian)

```ts
// frontend/src/lib/pricing.ts
export const TIERS = [
  { key: 'starter',  monthly: 10, annual: 96,  badge: null },
  { key: 'team',     monthly: 20, annual: 192, badge: 'most-popular' },
  { key: 'business', monthly: 35, annual: 336, badge: 'enterprise-ready' },
] as const;
```

The `most-popular` badge on Team is the visual anchor. Removing it in an experiment
dropped Team's share of new conversions by ~9 percentage points over four weeks. The
cue is doing real work.

### Related Sections

- [See market-reasoning → Meridian Positioning](./market-reasoning.md#meridians-positioning-vs-linear-and-asana)
  for why Team carries the Slack integration.
- [See business-modeling → Unit Economics at $1.5M ARR](#unit-economics-at-15m-arr) for
  how tier prices feed LTV.
- [See documentation-craft](./documentation-craft.md) (when populated) for the
  pricing-page copy review process.

### Coach Illustration (default vs. hints)

> **Illustrative only.** Not part of the live agent contract. Governed by
> `.claude/skills/learn/coach-styles/`.

**Scenario:** A learner asks whether Meridian should add a fourth tier between Team
and Business at $28/user/mo for customers who want the audit log but not SSO.

**`default` style** — The agent evaluates against the existing geometry: a fourth
tier compresses the upgrade decision into a price comparison; splitting audit log
from SSO creates two compliance SKUs; operational cost typically exceeds incremental
revenue unless the segment is large. It recommends bundling the audit log into Team
(raising Team to ~$22) and keeping the three-tier shape, then explains in
`## Learning:` trailers.

**`hints` style** — The agent names the framework (geometric spacing preserves
qualitative upgrade decisions; tier count expands operational cost faster than revenue),
names the risk (a new tier becomes the comparison anchor and erodes Team conversion),
and emits:

```
## Coach: hint
Step: Evaluate the proposed fourth tier against operational cost vs. revenue.
Pattern: Tier-count discipline (anchor tier preservation).
Rationale: A tier near the anchor shifts the conversation from "do we need integrations?"
to "is $7/seat worth the audit log?" — the latter invites negotiation downward.
```

`<!-- coach:hints stop -->`

The learner produces the analysis. The agent responds on the next turn without redoing
the evaluation.

---

## Unit Economics at $1.5M ARR  [MID]

### First-Principles Explanation  [JUNIOR]

**Unit economics** is the per-customer view: what it costs to acquire a customer (CAC),
what that customer is worth (LTV), and the relationship between the two.

- **CAC:** sales-and-marketing spend in a period, divided by customers acquired.
- **ACV:** annualized revenue from one customer.
- **LTV:** gross profit a customer is expected to generate over the relationship. The
  standard SaaS approximation is `LTV ≈ (gross margin × ACV) / churn rate`.

The **3:1 LTV:CAC heuristic** is the most-cited rule in B2B SaaS: a healthy business
recovers at least three dollars of gross profit per dollar spent on acquisition. Below
1:1 the business loses money on every customer; between 1:1 and 3:1 acquisition is
recovered but growth and overhead are not funded. The heuristic is a starting point,
not a finish line.

### Idiomatic Variation  [MID]

Meridian's snapshot at $1.5M ARR (Q1 2026 trailing twelve months):

| Metric | Value | Notes |
|--------|-------|-------|
| ACV (blended) | $3,200 | All tiers, weighted by paying seats |
| Average team size at purchase | 14 seats | First invoice; not steady-state |
| Gross margin | 78% | Hosting + Slack/calendar API + payments |
| Annualized gross logo churn | 12% | See churn entry below |
| CAC (blended) | $1,200 | Mostly inbound + content; some outbound for Business |
| LTV (blended) | (0.78 × $3,200) / 0.12 ≈ **$20,800** | Standard SaaS approximation |
| LTV:CAC | ~17:1 | See trade-off section |

CAC of $1,200 is low because acquisition is heavily inbound: content, SEO from
comparison pages, and the Slack App Directory listing. Business deals carry higher
CAC (~$3,800) because they involve a sales-led motion with a security review. The
78% gross margin nets revenue against infrastructure, per-message Slack costs,
calendar API quotas, payment-processor fees, and customer success — not sales,
marketing, R&D, or overhead.

### Trade-offs and Constraints  [SENIOR]

The 17:1 ratio is a snapshot. Three forces compress it over time:

1. **CAC inflation as channels saturate.** The first $100K of content produced the
   bulk of inbound; the next $100K will not. A 4x CAC increase brings the ratio to
   ~4:1 — near the territory where growth investment needs reconsideration.
2. **Margin compression as enterprise grows.** Business-tier customers consume more
   support and ship audit-log volume costly to retain. The 78% margin is Team-weighted;
   a Business-heavy mix lands closer to 72%.
3. **Churn rebasing as the customer mix changes.** The 12% rate reflects the
   post-ICP-revision mix (see
   [market-reasoning → Prior Understanding: ICP Revision After 50 Customers](./market-reasoning.md#prior-understanding-icp-revision-after-50-customers)).
   The pre-revision cohort churned above 35%; reverting to broader targeting would
   re-introduce it.

The deeper issue: Meridian is two and a half years old, so every LTV is an
extrapolation from churn rates not observed across full lifetimes. The 17:1 is a model
output, not an observed fact. A more honest framing is "12-month payback recovers
~1.7x CAC" plus a churn-curve sensitivity table.

### Example (Meridian)

The model is refreshed monthly with three views: blended (board), per-tier (product),
and by cohort (retention across months 1–24). The per-tier view catches problems: a
Team-tier LTV that drifted downward across two quarters in 2025 was the leading
indicator that the Slack notification rate-limit issue was eroding satisfaction —
invisible in support tickets but visible in seat shrinkage.

### Related Sections

- [See business-modeling → Net Dollar Retention and Land-and-Expand](#net-dollar-retention-and-land-and-expand)
  for how expansion interacts with LTV.
- [See business-modeling → Annualized Gross Logo Churn](#annualized-gross-logo-churn)
  for the churn methodology behind the LTV approximation.
- [See market-reasoning → SAM Calculation Methodology](./market-reasoning.md#sam-calculation-methodology)
  and [operational-awareness](./operational-awareness.md) (when populated) for market sizing
  and the Slack rate-limit incident that surfaced as unit-economics drift.

---

## Net Dollar Retention and Land-and-Expand  [MID]

### First-Principles Explanation  [JUNIOR]

In a per-seat subscription business, customers are not static. Two metrics describe the
net effect of churn-and-expansion:

- **GDR (Gross Dollar Retention):** share of period-start revenue still collected at
  period end. Excludes new revenue from the same customers; bounded above by 100%.
- **NDR (Net Dollar Retention):** GDR plus expansion revenue from existing customers.
  Can exceed 100% when expansion outweighs churn and contraction.

NDR > 100% is the signature of strong "land and expand" mechanics: the existing base
grows faster than it shrinks, producing compounding revenue without acquiring new
logos. A product with these mechanics is one where success on the first team creates
demand on the second team without sales.

### Idiomatic Variation  [MID]

Meridian instruments four motions separately. Trailing twelve months (Q1 2026):

- New logo ARR: ~$540K
- Expansion ARR (seats + tier upgrade): ~$310K
- Contraction ARR (downgrade without cancellation): ~$60K
- Churned ARR (full cancellation): ~$140K
- **NDR ≈ 113%, GDR ≈ 86%**

NDR of 113% means the business would grow ~13% even with zero new logos. Expansion is
seat-growth dominant: each added seat is incremental ARR with no acquisition cost.
Tier upgrades (Team → Business) contribute a smaller share (~22% of expansion ARR) at
higher per-seat margin.

The dashboard separates expansion from new-logo growth deliberately: they are different
engines, constrained by different inputs. A quarter where new-logo slows but expansion
accelerates is not the same as one where both slow — the response differs (channel
investment vs. product investment).

### Trade-offs and Constraints  [SENIOR]

NDR has a quiet failure mode: a business can post strong NDR while **logo retention**
is weak. One large account doubling in seats can offset ten small churned accounts —
the dollar arithmetic looks fine while the customer base hollows out. Reporting NDR
and gross logo churn together exposes this.

Optimizing for NDR also risks under-investing in new-logo acquisition. Existing
customers have a natural seat ceiling; a business that runs out of new logos eventually
exhausts expansion. Standing rule: new-logo growth must be at least 60% of total ARR
growth — below that, the funnel investment plan is reopened.

Expansion is largely a function of customer hiring, which Meridian does not control.
In a hiring downturn, expansion slows for reasons unrelated to product quality. The
healthy response is to expose this in board reporting as a macro effect.

### Example (Meridian)

```sql
-- expansion attribution; baseline = 12-month-prior snapshot of MRR per account
SELECT
  SUM(GREATEST(c.mrr_now - b.mrr_then, 0))                                 AS expansion_mrr,
  SUM(GREATEST(b.mrr_then - c.mrr_now, 0)) FILTER (WHERE c.id IS NOT NULL) AS contraction_mrr,
  SUM(b.mrr_then) FILTER (WHERE c.id IS NULL)                              AS churned_mrr
FROM baseline b LEFT JOIN current_state c USING (account_id);
```

Seat changes and tier changes are treated as one MRR-delta signal because customers
experience pricing as a single monthly invoice. A separate report decomposes by motion
when needed.

### Related Sections

- [See business-modeling → Annualized Gross Logo Churn](#annualized-gross-logo-churn)
  for why logo churn is reported alongside NDR rather than buried inside it.
- [See market-reasoning → Meridian Positioning](./market-reasoning.md#meridians-positioning-vs-linear-and-asana)
  for the Slack-native positioning that drives the seat-growth expansion mechanic.

---

## Annualized Gross Logo Churn  [SENIOR]

### First-Principles Explanation  [JUNIOR]

**Churn** measures the rate at which customers leave, along two dimensions:

- **Logo vs. revenue:** logo churn counts accounts; revenue churn counts dollars.
- **Gross vs. net:** gross counts only what was lost; net subtracts expansion.

Annualization expresses the rate as a yearly figure (a 1% monthly rate annualizes to
~11.4% with compounding, not exactly 12%). Revenue churn can hide a customer-base
hollowing out; logo churn can overstate the financial impact when small accounts are
lost. Reporting one without the other is a common source of confusion.

### Idiomatic Variation  [MID]

Meridian's primary churn metric is **annualized gross logo churn**, currently ~12%.
The team chose this over revenue churn for three reasons:

1. **Logo count is unbiased by deal size.** Revenue churn is dominated by a small
   number of large accounts; one Business-tier loss distorts it. At ~120 paying
   accounts, logo churn is the smoothed signal.
2. **Gross (not net) exposes product failure.** A reliability problem causes affected
   accounts to churn while unaffected ones expand; net churn could stay negative
   through the entire incident.
3. **At early stage, customer count is the strategic constraint.** More logos build
   pricing-power leverage with Slack, with the App Directory ranking, and with
   prospects evaluating Meridian against Linear and Asana.

The cohort that churns most fits a single archetype: a single-team trial on Starter
that activated the web app, did not connect Slack, and went silent in weeks 2–4
(roughly 64% of churned logos). Two behaviors retain much better: Slack activation
within 7 days (~92% twelve-month retention) and a second team adopting Meridian within
90 days (~95% retention). The second is the seed of the expansion mechanic — once a
second team joins, the account has crossed an organizational threshold that makes
departure expensive.

### Trade-offs and Constraints  [SENIOR]

Reporting only logo churn is silent on the financial size of each loss. The board sees
"churned ARR by tier" alongside, but the headline remains logo churn because the
diagnostic question — "is the product failing customers?" — is answered by counts.

The 12% figure is the **post-ICP-revision** number. Pre-revision (when Meridian sold
to teams of 30+ that bypassed Slack), that cohort churned above 35%. The improvement
is largely customer-mix change, not product change. A narrative crediting "product
improvements" overstates the case. The honest narrative is that the ICP revision (see
[market-reasoning → Prior Understanding: ICP Revision After 50 Customers](./market-reasoning.md#prior-understanding-icp-revision-after-50-customers))
filtered out the high-churn cohort.

The metric will evolve. A Business churn at $50K ACV is not equivalent to a Starter
churn at $1,200 ACV. The plan: switch to **tier-weighted gross logo churn** when
Business reaches ~25% of ARR.

### Example (Meridian)

A weekly Looker query fires when the four-week trailing logo-churn rate exceeds the
trailing twelve-month rate by more than 1.5x. In Q3 2025 the trigger fired at 18%;
investigation traced to a Slack OAuth token-rotation bug that disconnected integrations
silently for ~40 accounts over six weeks. Three accounts churned before the bug was
patched. The post-mortem added an upstream alert on "integration disconnect rate
exceeds baseline."

### Related Sections

- [See business-modeling → Net Dollar Retention and Land-and-Expand](#net-dollar-retention-and-land-and-expand)
  for the expansion side of the retention equation.
- [See business-modeling → Unit Economics at $1.5M ARR](#unit-economics-at-15m-arr) for
  how this rate feeds into the LTV approximation.
- [See market-reasoning → Prior Understanding: ICP Revision After 50 Customers](./market-reasoning.md#prior-understanding-icp-revision-after-50-customers)
  for the customer-mix change that explains the post-revision drop.

---

## Starter Tier Pricing Experiment ($10 vs. $12)  [MID]

### First-Principles Explanation  [JUNIOR]

Pricing experiments in B2B SaaS are harder than in consumer software: low traffic
requires long windows, and the metric of interest (lifetime revenue) cannot be measured
inside the window. The team must optimize on a proxy (conversion) and accept that it
may not correlate with the long-term metric.

The structurally honest design is **two-stage measurement**: measure the proximate
metric inside the window, then measure the downstream metric in the same cohorts after
a defined interval. Skipping the second stage is the most common cause of experiments
that produce a "win" in conversion and a quiet long-term loss in retention.

### Idiomatic Variation  [MID]

In Q4 2025, Meridian tested raising Starter from $10 to $12. Hypothesis: a 20% lift
would have a small effect on conversion and a meaningful effect on annual revenue per
Starter customer. Stage 1 was trial-to-paid conversion at day 14; Stage 2 was
expansion to Team at day 90 in the same cohorts; window was ten weeks, sized to detect
a 15% relative change at 80% power.

Results: $12 cohort converted at 91% of the $10 rate (Stage 1, within range) and
upgraded to Team at 73% of the $10 rate (Stage 2, unexpected).

The decision was to revert to $10. Stage 1 alone would have been a marginal revenue
win. Stage 2 reframed the result: the higher price did not just cost some conversions;
it changed the type of customer who converted, in a way that made expansion less
likely. Post-experiment hypothesis: $12 selected for prospects who had already decided
Starter was sufficient; $10 selected for prospects who saw Starter as an evaluation
step.

### Trade-offs and Constraints  [SENIOR]

Two-stage measurement imposes 90 extra days between end-of-experiment and final
decision; the infrastructure cannot be reused for the next experiment without
contaminating Stage 2. Meridian's cadence is at most three to four pricing experiments
per year — a structural feature of B2B SaaS, not a process deficiency.

The result also cannot be cleanly generalized. The experiment tested $10 vs. $12 with
the then-current product, ICP, and positioning; a repeat in 2027 may produce a
different answer. Standing rule: pricing experiment results have a useful shelf life
of ~12 months.

A subtler constraint is selection bias. The 30-day bucket cookie meant returning
prospects were inconsistently bucketed, contaminating ~6% of assignments. The test
reached significance with margin so the conclusion held; a tighter test on a smaller
effect would have been unreliable.

### Example (Meridian)

```ts
// frontend/src/lib/pricing-experiment.ts
export function resolveStarterPrice(visitorId: string) {
  const flag = useFeatureFlag('starter-price-test-2025-q4', visitorId);
  if (flag === 'treatment') return { monthly: 12, bucket: 'treatment' };
  return { monthly: 10, bucket: 'control' };
}
```

The bucket label flows into every analytics event so both stages segment without
re-deriving assignment. After the experiment, the flag was removed; lingering flags
are a recurring source of pricing inconsistency.

### Related Sections

- [See Three-Tier Per-Seat Pricing](#three-tier-per-seat-pricing) for the structure
  being tested, and [Net Dollar Retention](#net-dollar-retention-and-land-and-expand)
  for the mechanic the Stage 2 metric protects.

---

## Prior Understanding: Tier Anchor Position  [SENIOR]

### Prior Understanding (revised 2025-09-14)

The original tier ladder was structured with the **middle tier as the anchor**: a low
tier as decoy, a middle tier as target, a high tier as ceiling-raising signal.

- **Free:** 5 users, no integrations, no SLA.
- **Pro:** $15/user/mo, Slack integration, recurring tasks.
- **Enterprise:** $30/user/mo, "contact sales".

The goal was "land Pro." Free was deliberately limited; Enterprise was vapor — no real
product behind it, and "contact sales" went to the founder's inbox.

**What the data showed across the first 18 months:**

1. **Tier-skipping at the high end.** Roughly 22% of prospects above 25 seats tried to
   negotiate a discounted Enterprise without going through Pro. The Enterprise price
   set expectations, but "contact sales" meant Meridian could not capture the demand.
2. **Pro was treated as the floor, not the anchor.** Pro customers asked, "what would
   we get if we paid more?" The middle-as-anchor model assumes the customer compares
   the anchor against a lower option only; B2B buyers also compare against a higher
   option, and a vapor high tier weakens the anchor.
3. **Free amplified support cost without amplifying the funnel.** Free converted under
   4% — below the cost of supporting it at scale — and converters had worse downstream
   behavior than paid-trial prospects.

**Corrected understanding (2025-09-14):**

The current ladder (Starter, Team, Business) was adopted with the **top tier as the
anchor**. Rationale:

- Business is real and shippable (SSO, audit log, advanced roles), so prospects who
  anchor on it can be sold into it. Vapor tiers fail at the anchor role.
- Team is the most-purchased tier (~78% of paying seats), but it is not the design
  anchor — it is the natural landing zone for the ICP. The pricing page makes Business
  look like the top of a credible ladder, which lifts Team by association.
- Starter replaced Free. A paid floor filters out non-buyers and protects support.

**Operational impact:** Free was migrated to a 14-day Team trial (existing Free
accounts grandfathered). The Enterprise placeholder was removed until Business was real
(shipped Q1 2026 alongside SSO — see
[market-reasoning → Deferring Enterprise SSO](./market-reasoning.md#deferring-enterprise-sso)).
During the ~18-month gap, the pricing page showed only Starter and Team — better than
a vapor anchor.

**The principle:** the textbook "decoy + anchor + ceiling" ladder assumes a one-shot
comparison among visible options. B2B SaaS buyers iterate on tier choice over the
customer lifetime and treat the top tier as a forward commitment ("we'll need this
when we get bigger"). A vapor top tier breaks that commitment and quietly costs both
the immediate sale and future expansion.

### Related Sections

- [See business-modeling → Three-Tier Per-Seat Pricing](#three-tier-per-seat-pricing)
  for the current ladder this revision produced.
- [See business-modeling → Net Dollar Retention and Land-and-Expand](#net-dollar-retention-and-land-and-expand)
  for the expansion mechanic that depends on a real top tier.
- [See market-reasoning → Deferring Enterprise SSO](./market-reasoning.md#deferring-enterprise-sso)
  for the product decision that gated when Business became real.
