# ADR-011: Compliance Checklist Skill

## Status

Accepted — 2026-05-09

## Context

AI agents have lowered the cost of shipping an application to the point
that legal compliance — historically gated by professional legal review —
is now the part of the release process most likely to be skipped. The
failure mode is no longer "we couldn't build it"; it is "we shipped it
without checking whether it was legal to ship."

The user has identified concrete examples that recur across hobby and
small-team projects:

- Chat or messaging features that fall under Japan's
  **Telecommunications Business Act** (電気通信事業法) registration or
  notification regime.
- Subscription or one-time purchase flows that fall under Japan's
  **Specified Commercial Transactions Act** (特定商取引法) §11 disclosure
  requirements, plus Apple App Store / Google Play platform policies.
- Personal-data collection that triggers Japan's **Act on the Protection
  of Personal Information** (個人情報保護法), the EU **GDPR** Art. 3
  extraterritorial scope, or California's **CCPA**.
- Industry-specific records-retention obligations (e.g. the **Electronic
  Books Preservation Act** for invoices/receipts) that depend on
  vertical, not on the codebase.

The template's existing agent team handles *what to build* and *how to
build it well*, but no agent or Skill currently surfaces *what laws
apply to what got built*. The user has asked whether a dedicated legal
agent should be added.

The Agent Team has now debated the question across five voices
(`product-manager`, `architect`, `architecture-critic`, `security-reviewer`,
`technical-writer`). The relevant findings:

1. **No equivalent exists upstream.** ECC ships
   `hipaa-compliance`, `healthcare-phi-compliance`, and
   `customs-trade-compliance` Skills, but no general-purpose application
   compliance Skill or agent. The template can lead here.
2. **Agent vs. Skill is a design choice, not a foregone conclusion.**
   The original proposal called for a new agent (`compliance-reviewer`).
   The `architecture-critic` produced a counter-proposal arguing that a
   Skill is the better fit, with reasons that survive review:
   - Skills are designed for "checklist + reference material" workloads;
     agents are designed for autonomous decision roles.
   - The template already implements regulatory-style invariant checking
     as a Skill (`claude-md-authoring`) with Pre/Post checklists. Breaking
     that symmetry needs justification the proposal did not supply.
   - A Skill keeps the agent count at 18 and avoids enlarging the
     orchestrator's routing surface.
   - Skill content is plain markdown, which is more pedagogically useful
     for a learning template than agent prompts that hide reasoning.
3. **Six blocking preconditions emerged from security review.** Without
   them, the Skill is *worse* than nothing — it generates false
   confidence:
   - Output must never assert applicability negatively ("this law does
     not apply"). Permitted forms are "may apply, verify" and "verify
     before assuming exemption".
   - Every applicability claim must cite a primary source (e-Gov 法令
     検索, official EU regulation text, state code, platform policy
     page). Secondary sources are disqualifying — same rule as the
     research domain of ADR-008/010.
   - PII must not be ingested. The Skill must refuse to operate on
     paths likely to contain test data, seeds, environment files, or
     database dumps, and output must pass a regex-based PII mask
     before being returned. The concrete path-glob list and PII
     mask regexes live in the Skill's own `triggers.md` reference
     file, not in this ADR — ADRs record *what and why*; the *how*
     evolves with the Skill and may not need an ADR amendment for
     each tightening.
   - The Skill ships **default-off** and is enabled per project, in line
     with the verification-layer domains (ADR-010).
   - The set of jurisdictions to evaluate is project-declared, not
     guessed. `.claude/CLAUDE.md` (or a sibling config) declares
     `target_jurisdictions: [JP, EU, US-CA, ...]`. The Skill refuses to
     run if the field is missing.
   - Triggers must be code-grounded, not name-grounded. Detect the
     *capabilities* that imply legal exposure (a websocket dependency, a
     Stripe SDK, a form that collects personal data) rather than file or
     route names.

## Decision

Implement compliance support as a **Skill**, not an agent:

- Path: `.claude/skills/compliance-checklist/SKILL.md`, with sibling
  reference files (`disclaimers.md`, `triggers.md`, `jurisdictions/`).
- Status: ships **default-off**. Activation is per-project: a single
  field `compliance.enabled: true` in `.claude/compliance.yml` (created
  on opt-in; absent by default).
- Generators: existing agents call the Skill — primarily
  `product-manager` (acceptance criteria), `security-reviewer` (PII /
  consent surfaces), and `technical-writer` (terms-of-service / privacy
  policy authoring). The Skill itself runs no autonomous loop.
- Output contract: every invocation returns (a) a checklist of
  potentially applicable obligations, (b) the primary-source citation
  for each item, (c) a mandatory disclaimer block, and (d) a
  human-review-required marker. Items can be "applicable", "may apply
  — verify", or "out of scope for declared jurisdictions". The Skill
  never marks items as "complied with" — only the human reviewer can.
- The six blocking preconditions from security review are encoded as
  invariants in the Skill, parallel to `claude-md-authoring`'s four
  invariants: deviation from any of them is a defect, not a tuning
  choice.
- MVP jurisdiction set: **JP** (電気通信事業法, 特定商取引法, 改正
  個人情報保護法, 資金決済法), **EU** (GDPR), **US-CA** (CCPA),
  **platform** (Apple App Store Review Guidelines, Google Play Policy
  Center). Vertical-specific regimes (healthcare, fintech KYC/AML,
  public broadcasting, etc.) are explicitly out of MVP scope and are
  pointed at existing ECC Skills (`hipaa-compliance`,
  `healthcare-phi-compliance`) when applicable.
- Trigger model: capability detection via dependency manifest scan
  (presence of `socket.io`, `firebase-messaging`, `stripe`, `expo-auth-session`,
  etc.) plus an explicit "does this feature involve user-to-user
  communication / monetary exchange / personal data collection?" prompt
  to the human when the dependency signal is ambiguous. No name-based
  matching.
- Disclaimer is structural: the Skill output template hardcodes a
  disclaimer block at the top, including an explicit statement that the
  output is not legal advice and that a qualified attorney must review
  the release before launch. The Skill cannot remove this block.
- The Skill does not author legal documents (terms of service, privacy
  policy, refund policy). It produces a *requirements list* that
  `technical-writer` can use as input, with the same disclaimer.

## Consequences

### Positive

- Closes the largest gap in the template's release-readiness story
  without inventing a new abstraction: Skills already exist for this
  shape of work.
- Agent count stays at 18; orchestrator routing surface unchanged.
- Symmetric with `claude-md-authoring` (regulatory-style invariant
  checking via Skill + Pre/Post checklist), which is what makes the
  template internally consistent.
- Plain-markdown content makes the legal reasoning auditable by the
  human reviewer and learnable by the user — the template's pedagogical
  goal benefits.
- Primary-source-only citation extends ADR-008/010's discipline into
  legal reasoning, where it matters most. A blog summary of GDPR
  Art. 3 is exactly the kind of source that should never make it into
  a compliance recommendation.
- ECC user-level installs gain something they did not have before. The
  Skill is template-local, but the design is portable: if it proves
  useful, it can graduate to ECC.

### Negative

- A Skill is invoked, not auto-triggered. Forgetting to invoke is a
  real failure mode and is more likely than for an always-on agent.
  Mitigation: `.claude/templates/spec-template.md` will be updated to
  include a mandatory "compliance check performed?" line in the
  acceptance criteria, and `product-manager`'s prompt will reference
  this Skill explicitly.
- The Skill is fundamentally a checklist. It cannot synthesize
  cross-jurisdictional analysis the way a junior in-house lawyer
  could — and must not pretend to. The disclaimer makes this explicit;
  the practical limit is that complex cross-border releases still need
  human counsel and the Skill says so.
- Maintenance cost is real. Laws change. The MVP jurisdiction set must
  be re-verified at a stated cadence (initially: half-yearly manual
  pass via `docs-researcher`, recorded in
  `.claude/skills/compliance-checklist/SKILL.md`'s update-cadence
  section, identical to `claude-md-authoring`'s pattern). If we cannot
  commit to that cadence, the Skill's value erodes silently.

### Neutral

- A new config file `.claude/compliance.yml` joins
  `.claude/verification.yml.example` as a domain-specific opt-in
  config. The two files are siblings, both default-off, both single
  toggles. We accept the file proliferation in exchange for keeping
  each domain's configuration locally legible.
- `target_jurisdictions` becomes a declared project property. Projects
  that fork the template and never enable the Skill pay nothing.
  Projects that enable it without declaring jurisdictions get a clear
  refusal-to-run error, not a guess.
- Vertical-specific compliance (healthcare PHI, financial KYC, etc.)
  remains delegated to existing ECC Skills. The compliance-checklist
  Skill points at them rather than duplicating their content.

## Alternatives considered

| Alternative | Pros | Cons | Why not chosen |
|---|---|---|---|
| Add a new `compliance-reviewer` agent (the original proposal) | Auto-trigger via orchestrator; produces decision-shaped output | Inflates agent count; breaks symmetry with `claude-md-authoring`; hides reasoning inside agent prompts; `architecture-critic` produced a counter-proposal that survived review | Skill form fits the workload better and preserves template internal consistency |
| Do nothing; rely on `product-manager` acceptance criteria to mention legal review | Lowest cost | Acceptance criteria are project-specific; legal requirements are cross-cutting and recur. Without a Skill, every project re-derives them, badly | The user's framing (recurring violation pattern across many releases) is exactly what cross-cutting infrastructure is for |
| Push this upstream to ECC immediately as `~/.claude/skills/app-compliance/` | Benefits all ECC users, not just template adopters | ECC has not yet committed to maintaining a half-yearly law-update cadence; pushing premature increases risk of stale legal content under the ECC name | Build it template-local first, prove the cadence, then propose graduation to ECC |
| Make the Skill default-on | Maximum coverage by default | Forces every fork to declare jurisdictions before any session can run, even forks that have nothing to do with end-user releases | Default-off respects the template's role; opt-in is one config line |
| Allow the Skill to mark items "complied with" automatically | Closes the loop without requiring human sign-off | Catastrophic when wrong — generates legal cover where none exists | Only humans can mark compliance status. The Skill produces a checklist, not an attestation |
| Author legal documents (terms of service, privacy policy) inside the Skill | One-stop release prep | Drafting legal documents from a checklist generator is the highest-risk use of LLMs in this entire space; would directly contradict the disclaimer | Skill produces the *requirements list*; document drafting stays with `technical-writer` and ultimately with human counsel |

## References

- ADR-007 (CLAUDE.md Authoring Skill) — the structural template for this
  Skill: invariants + Pre/Post checklists + half-yearly re-verification
  cadence.
- ADR-008 (Research Verification Layer) — the primary-source-only
  citation discipline this Skill inherits.
- ADR-010 (Verification Layer Generalization) — the default-off,
  per-domain opt-in pattern this Skill follows.
- `.claude/skills/claude-md-authoring/SKILL.md` — concrete reference for
  the Skill shape (frontmatter, Invariant Core, Override Protocol,
  update cadence section).
- e-Gov 法令検索 (https://elaws.e-gov.go.jp/) — primary source for
  Japanese statutes; will be the citation backbone for the JP
  jurisdiction in the Skill body.
- EUR-Lex (https://eur-lex.europa.eu/) — primary source for EU
  regulations and directives, including GDPR.
- California Legislative Information (https://leginfo.legislature.ca.gov/)
  — primary source for CCPA / CPRA.
- Apple App Store Review Guidelines (https://developer.apple.com/app-store/review/guidelines/)
  and Google Play Policy Center (https://support.google.com/googleplay/android-developer/topic/9858052)
  — primary platform policies. Treated as primary because they are the
  authoritative platform-side text.
- ECC Skills `hipaa-compliance`, `healthcare-phi-compliance`,
  `customs-trade-compliance` — vertical compliance Skills the
  compliance-checklist Skill defers to rather than duplicating.
