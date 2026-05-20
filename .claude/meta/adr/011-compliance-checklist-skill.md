# ADR-011: Compliance Checklist Skill

## Status

Accepted — 2026-05-09; Amended — 2026-05-20 (Roadmap #20): `.claude/compliance.yml` ships **committed-by-default with `enabled: false`** rather than "absent by default". See §Amendment — 2026-05-20 (commit-by-default transition) below. The Skill's six invariants are preserved unchanged; only the disk-presence polarity of the activation config flips.

## Known ambiguity — Resolved by ADR-013 (2026-05-09)

The Invariant 2 ambiguity recorded here was resolved ahead of the
half-yearly cadence. ADR-013 (Invariant 2 Source Tier Model) was
drafted, debated, and accepted on 2026-05-09 with **Option A —
Tier 1.5 allow-list extension** at **verification-layer-wide scope**.
The original ambiguity:

> Invariant 2 ("primary-source-only citation") names statute
> repositories (e-Gov, EUR-Lex, California Legislative Information)
> and platform policy pages as the allowed sources, and lists "blog
> summaries, Q&A sites, AI summaries, news articles, law-firm
> explainers" as disqualifying. **Regulator-issued official
> interpretive guidance** (EDPB Guidelines under GDPR Art. 70,
> 個人情報保護委員会 Q&A and 通達, California Privacy Protection
> Agency Regulations, Apple's Privacy Manifest spec, Google Play
> SDK Index) sits in neither list.

The architecture-critic counter-proposal (Option D — statute-only,
with `## See also` non-citation references) is preserved verbatim in
ADR-013's `## Counter-proposal` section under ADR-010's design-domain
protocol, with its re-evaluation trigger.

For the resolution, see
[`.claude/meta/adr/013-invariant-2-source-tier-model.md`](./013-invariant-2-source-tier-model.md).
The amendments to ADR-008 and ADR-010 record the verification-layer-wide
propagation. The Invariant 2 text in this Skill's `SKILL.md` was
updated to reflect the three-tier structure (Tier 1 / Tier 1.5 /
disqualifying) in the same release cycle.

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
| Make the Skill default-on | Maximum coverage by default | Forces every fork to declare jurisdictions before any session can run, even forks that have nothing to do with end-user releases | Default-off respects the template's role; opt-in is one config line _(Re-evaluated 2026-05-20 in Roadmap #20: Skill-level default-off is retained; what changed is `.claude/compliance.yml` disk-presence — see §Amendment — 2026-05-20 below)_ |
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
- Roadmap row: #20 (this ADR's 2026-05-20 amendment records the
  commit-by-default transition decided by that milestone; see
  §Amendment — 2026-05-20 below)

## Amendment — 2026-05-20 (commit-by-default transition)

This amendment flips the on-disk default of the compliance activation
config from **absent** (`.claude/compliance.yml.example` only) to
**committed-and-present** (`.claude/compliance.yml` shipped with
`enabled: false`). It records the design decision for Roadmap
milestone #20 ("Commit `compliance.yml` as active default") and
resolves the Spec AC-5 requirement that the ADR-011 §Decision "absent
by default" clause be addressed in writing. The amendment preserves
every load-bearing property of the original Decision — the Skill is
still default-off at the Skill layer (Invariant 4), still requires
operator jurisdiction declaration (Invariant 5), and still produces
zero output when `enabled: false`. Only the **disk-presence polarity
of the activation config** flips.

### Triad classification — 1/3, amendment-not-new-ADR

The Spec hands `architect` the ADR-018 Alternative-B triad
discriminator. Applied clause by clause to #20:

- **New contract boundary? Yes.** §Decision (original, 2026-05-09):
  "`compliance.enabled: true` in `.claude/compliance.yml` (created on
  opt-in; absent by default)". The Alternatives table rejected "Make
  the Skill default-on" with a recorded rationale. Inverting the
  disk-presence polarity of the activation config is a contract-level
  change to that direction-of-default, not a value tweak inside an
  unchanged contract.
- **New keying / mechanism? No.** The `compliance.enabled` YAML
  field, the `target_jurisdictions:` list shape, the SKILL.md
  Invariant 4 default-off refusal logic, the Invariant 5
  jurisdiction-declaration requirement, and the capability-detection
  trigger surface in `triggers.md` are byte-for-byte unchanged
  (Spec AC-6). No new YAML key, no new regex, no new short-circuit
  syntax. `operator_attestations` and `reverification_days` stay
  optional and commented-out in the committed file.
- **New structural artifact? No.** No new file type, no new
  directory, no new CI workflow, no new detector, no new test suite,
  no new SKILL invariant. `.claude/compliance.yml.example` is
  retained (Spec AC-4) as a fully-annotated reference alongside the
  committed active config. The committed `.claude/compliance.yml`
  is a disk-presence promotion of an artifact already named in the
  original §Neutral Consequences ("A new config file
  `.claude/compliance.yml` joins `.claude/verification.yml.example`
  as a domain-specific opt-in config"), not a new artifact category.

Triad total: **1/3**. Per ADR-018 Alternative-B and the explicit
ADR-022 §1 "new-ADR-vs-amendment" reasoning, 1-2/3 routes to an
**amendment of the existing ADR**, not a new ADR. This is the same
shape ADR-006 took for Roadmap #19 (also 1/3, also commit-default
polarity flip on a sibling opt-in CI scaffold). A new ADR-023 was <!-- ref-allow: counterfactual reference; ADR-023 deliberately not issued per triad 1/3 outcome | expires: 2026-06-20 -->
considered (Spec AC-5 uses that name in an OR-condition with this
amendment) and rejected: folding the resolution into ADR-011 itself
colocates the historical §Decision text, the rejected "default-on"
alternative, and the post-#20 reconciliation at a single source of
truth — matching the ADR-006 amendment shape and avoiding the
fragmentation a future reader would face across two ADRs.

### Why the original "absent by default" clause no longer holds

The original 2026-05-09 §Decision and the §Alternatives rejection of
"default-on" were sound at authoring time. Both are re-examined here
against concrete evidence available now:

1. **"Absent by default" was a procedural safety, not a Skill-level
   safety.** The load-bearing safety lives in the Skill: Invariant 4
   (the Skill never activates unless `compliance.enabled: true`),
   Invariant 5 (the Skill refuses to run on an empty or absent
   `target_jurisdictions:`), and the SKILL.md "When to invoke"
   contract that requires both conditions. Committing
   `.claude/compliance.yml` with `enabled: false` does not weaken any
   of these; the Skill remains structurally inert until the operator
   makes two explicit assertions (flip `enabled`, populate
   `target_jurisdictions`). The "absent" property contributed a
   procedural barrier ("you must locate and copy a file"), not a
   safety barrier.
2. **The template's "default-active for safe-empty-state CI scaffolds"
   convention has stabilized.** Roadmap #01 (`verification.yml`
   committed with `research.enabled: true`) and Roadmap #19
   (`.github/workaround-tracker.yml` flipped to `enabled: true`) both
   ship active defaults whose empty-inventory behavior is verifiably
   silent. The compliance config sits in the same family of opt-in
   scaffolds but carries a unique constraint: Invariant 5 forbids the
   template from asserting jurisdictions on behalf of forks. The
   commit-by-default form that respects Invariant 5 is therefore
   `enabled: false` with documented operator-assertion comments —
   not `enabled: true`.
3. **The "forgot to copy the `.example`" failure mode is real.**
   Spec §Problem records it: a fork maintainer who reads ADR-011 and
   intends to use the Skill must still locate and copy
   `.claude/compliance.yml.example` to `.claude/compliance.yml`. The
   step is easy to omit; there is no visible failure when it is, and
   no prompt to perform it. Shipping the active path committed
   eliminates this class of failure entirely.

The original "absent by default" choice was sound at 2026-05-09 (no
#01 precedent had landed; the `verification.yml` commit-by-default
pattern was not yet ratified). It does not hold at 2026-05-20.

### What this amendment changes

| Item | Before (2026-05-09) | After (2026-05-20) |
|---|---|---|
| `.claude/compliance.yml` on-disk state in fresh fork | Absent (only `.example` shipped) | **Committed with `enabled: false`** (Spec AC-1) |
| `.claude/compliance.yml.example` | Sole config artifact | Retained as fully-annotated reference (Spec AC-4) |
| `compliance.enabled` default in committed file | N/A (file absent) | `false` (preserves SKILL.md Invariant 4 wording byte-for-byte) |
| `target_jurisdictions:` in committed file | N/A (file absent) | **Empty list with operator-assertion inline comments** (Spec AC-2; Invariant 5 forbids template pre-population) |
| SKILL.md Invariant 4 ("Default-off, opt-in per project") | Default-off | Default-off (unchanged; the Skill is still inert until two explicit operator assertions) |
| SKILL.md Invariant 5 (project-declared jurisdictions, never guessed) | Required | Required (unchanged; Spec AC-6) |
| SKILL.md "When to invoke" contract | Requires `enabled: true` + non-empty `target_jurisdictions:` | Requires `enabled: true` + non-empty `target_jurisdictions:` (byte-for-byte unchanged) |
| SKILL.md refusal logic on empty list | Single-line refusal | Single-line refusal (unchanged) |
| Six invariants | Intact | Intact (Spec AC-6 — this amendment does not weaken any invariant) |
| Capability-detection trigger surface (`triggers.md`) | Per ADR-011 | Per ADR-011 (unchanged) |

### §Decision — amended clause text

The original §Decision second bullet read:

> Status: ships **default-off**. Activation is per-project: a single
> field `compliance.enabled: true` in `.claude/compliance.yml`
> (created on opt-in; absent by default).

The amended §Decision second bullet reads (effective 2026-05-20):

> Status: ships **default-off** at the Skill layer (Invariant 4 is
> unchanged). The activation config `.claude/compliance.yml` ships
> **committed-by-default with `enabled: false`** so fork maintainers
> who wish to enable the Skill edit one already-present file rather
> than copy an `.example`. Activation remains two explicit operator
> assertions: flip `enabled: true` and populate
> `target_jurisdictions:` with at least one declared jurisdiction.
> The committed file MUST NOT pre-populate `target_jurisdictions:`
> on behalf of forks — Invariant 5 forbids the template from
> asserting which legal jurisdictions apply. Commented illustrative
> entries are permitted as documentation; they are not live values.
> The `.claude/compliance.yml.example` is retained as a
> fully-annotated reference. The post-#20 form preserves every
> load-bearing safety of the original "absent by default" wording
> (which was a procedural barrier, not a Skill-level safety) while
> eliminating the "forgot to copy the `.example`" failure mode.

The load-bearing safety properties — Invariant 4's default-off
behavior, Invariant 5's no-guessing rule, the "When to invoke"
two-condition gate, and the refusal-on-empty-list contract — are
preserved unchanged. Only the disk-presence polarity of the
activation config flips.

### Counter-proposal

Per ADR-010 design-domain protocol, the rejected alternative
(new ADR-023 issuing `enabled: true` + empty `target_jurisdictions:` <!-- ref-allow: counterfactual reference; ADR-023 deliberately not issued per triad 1/3 outcome | expires: 2026-06-20 -->
in the committed file) is taken seriously here. Its shape would be:

- Issue ADR-023 at `.claude/meta/adr/023-compliance-yml-commit-default.md`. <!-- ref-allow: counterfactual reference; ADR-023 deliberately not issued per triad 1/3 outcome | expires: 2026-06-20 -->
- Ship committed `.claude/compliance.yml` with `enabled: true` and
  `target_jurisdictions: []`. The Skill activates on capability
  triggers, hits Invariant 5's refusal logic, and emits a single-line
  prompt asking the operator to declare jurisdictions.
- Treat the per-session refusal as **explicit operator pressure** to
  perform the declaration — symmetric with #19's "default-on CI
  workflow runs on every PR and reports `Markers found: 0`".

Why rejected:

1. **Triad scoring is 1/3.** The clause-(c) test (new structural
   artifact) is negative regardless of which `enabled:` value is
   committed; clause-(b) is negative because the YAML key shape is
   unchanged. The routing rule says amendment, not new ADR.
   Issuing ADR-023 to record the same triad-1/3 decision would <!-- ref-allow: counterfactual reference; ADR-023 deliberately not issued per triad 1/3 outcome | expires: 2026-06-20 -->
   fragment the §Decision text across two ADRs without changing the
   triad outcome.
2. **Invariant 4 wording would need reconsideration.** SKILL.md
   currently states "This Skill ships **default-off**". Shipping
   `enabled: true` in the committed config requires a SKILL.md edit
   to qualify that wording, which Spec AC-6 explicitly forbids
   (`SKILL.md` is read-only for this milestone). The chosen
   `enabled: false` form preserves SKILL.md byte-for-byte.
3. **Per-session refusal is noisier than the silent-inert state.**
   For a fork that has no plans to ship end-user releases, an
   `enabled: true` + empty list state generates a per-trigger
   refusal line every time a capability-detection signal fires.
   The chosen `enabled: false` form produces zero output (Spec AC-3,
   branch (a)).
4. **#01 precedent is not symmetric.** Spec §Risks notes that #01
   shipped `research.enabled: true` because research-tier
   verification is the safe subset by default. Compliance has no
   safe subset without operator jurisdiction declaration; the
   safe-default analog for compliance is **committed file + Skill
   inert**, not **committed file + Skill active + empty list**.

Re-evaluation trigger: if a future audit shows that fork maintainers
who adopt the compliance Skill consistently fail to flip
`enabled: true` after committing to using the Skill, the
counter-proposal's "explicit operator pressure" argument becomes
empirically supported and the choice between `enabled: false` and
`enabled: true` + structured refusal warrants re-opening. Until then,
`enabled: false` is the lower-blast-radius default.

### Scope of this amendment

- §Decision second bullet is amended as above. The other bullets
  (Path, Generators, Output contract, six invariants, MVP
  jurisdiction set, Trigger model, Disclaimer, document-authoring
  scope) are unchanged.
- Alternatives considered table — "Make the Skill default-on" row
  gains a "Re-evaluated 2026-05-20 in Roadmap #20" inline note; the
  historical rejection text is preserved verbatim alongside.
- Status line gains the `Amended — 2026-05-20` notation.
- §Neutral Consequences first bullet (the
  "`.claude/compliance.yml` joins `.claude/verification.yml.example`
  as a domain-specific opt-in config" text) describes a 2026-05-09
  state. Both sibling files have since transitioned to committed
  defaults (`verification.yml` via #01, `compliance.yml` via this
  amendment). The historical wording is preserved as authored.
- The six invariants in SKILL.md are untouched. The committed
  config exercises Invariants 4 and 5 exactly as designed.
- The Japanese counterpart (`011-compliance-checklist-skill.ja.md`)
  receives the equivalent amendment in the same change, per
  Roadmap #06 heading-tree parity ownership.
- The `## Development Workflow` §6a section in `.claude/CLAUDE.md`
  ("default-off") may require qualification to match the post-#20
  Skill-layer-vs-config-layer distinction; that edit is owned by
  `technical-writer` at step 7, not by this amendment.
- The CHANGELOG entry for the commit-by-default transition is
  owned by `technical-writer` at step 7.

### Implementation directive for `implementer`

The architect-level decision recorded above is: **commit
`.claude/compliance.yml` with `enabled: false` and an empty
`target_jurisdictions:` list**. Concrete shape:

```yaml
compliance:
  # Master switch. Default false in the template's committed config.
  # Flip to true once target_jurisdictions is populated by your project.
  # The Skill refuses to run on an empty or absent list (Invariant 5).
  enabled: false

  # Declared jurisdictions for evaluation. EMPTY in the template's
  # committed config — Invariant 5 forbids the template from asserting
  # which legal jurisdictions apply to any given fork. Your project
  # MUST declare at least one of JP / EU / US-CA / platform here
  # before flipping `enabled: true`. The Skill never infers
  # jurisdiction — declaration is a project assertion.
  #
  # Example (uncomment and edit for your project):
  #   - JP
  #   - EU
  #   - US-CA
  #   - platform
  target_jurisdictions: []
```

The alternative form (`enabled: true` + empty list with structured
refusal) is rejected for the four reasons recorded in the
Counter-proposal section above. The
`.claude/compliance.yml.example` is retained unchanged as a
fully-annotated reference (Spec AC-4); the `JP`-uncommented form
there remains illustrative documentation, not a live default.

No SKILL.md edit, no CLAUDE.md §6a edit, no CHANGELOG edit at the
implementation step — those are owned by `technical-writer` at
step 7 per Spec §Key interactions.
