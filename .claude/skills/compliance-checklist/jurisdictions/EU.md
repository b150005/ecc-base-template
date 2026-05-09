# Jurisdiction Reference: European Union (EU)

This file enumerates the EU regulations the compliance-checklist
Skill evaluates when `EU` is in `target_jurisdictions`. Each row
cites a **Tier 1 primary source** (EUR-Lex consolidated text) for the
active regulation. **Tier 1.5** EDPB official interpretive guidance
(per ADR-013) appears alongside Tier 1 citations on the same item,
marked `[Tier 1.5]` and never standalone. Secondary sources (blog
summaries, news, law-firm explainers, EDPB blog posts or press
releases) are disqualifying.

The agent reading this file must follow the citation links directly
when generating an applicability finding — the URLs are the source
of truth, this file is the navigation index.

## 1. GDPR — Regulation (EU) 2016/679

- **Triggered by**: `pii` capability (see
  [`../triggers.md`](../triggers.md) §3) and `data-egress` capability
  (see [`../triggers.md`](../triggers.md) §4), in projects that may
  serve end users in the EU.
- **Primary source**:
  https://eur-lex.europa.eu/eli/reg/2016/679/oj
  (EUR-Lex — General Data Protection Regulation, consolidated).
- **What the human reviewer must verify**:
  - **Art. 3 territorial scope** — the GDPR applies to processing of
    personal data of subjects in the EU regardless of where the
    controller is established, when the activity relates to offering
    goods or services to those subjects or monitoring their
    behaviour. The Skill always asks the human "Does this project
    serve end users in the EU?" when the `pii` trigger fires; a
    "Yes" answer makes Art. 3 active.
  - **Lawful basis** under Art. 6 — the project must select and
    document a basis for each processing activity (consent,
    contract, legal obligation, vital interests, public task, or
    legitimate interests). Consent is the most common but also the
    most fragile.
  - **Art. 7 conditions for consent** — explicit, informed,
    revocable; separate from other terms; not bundled.
  - **Art. 13–14 information obligations** at the point of data
    collection — what information must be provided to the data
    subject.
  - **Art. 15–22 data-subject rights** — access, rectification,
    erasure, restriction, portability, objection, automated-decision
    safeguards. The project must have an operational process for
    each.
  - **Chapter V international transfers** — when data leaves the
    EU/EEA, the project must rely on an adequacy decision, standard
    contractual clauses (the 2021 SCCs at
    https://eur-lex.europa.eu/eli/dec_impl/2021/914/oj ), binding
    corporate rules, or a derogation under Art. 49.
  - **Art. 33–34 breach notification** — 72-hour controller-to-DPA
    notification for breaches likely to result in risk; data-subject
    notification when the risk is high.
  - **Art. 35 DPIA** — required for processing likely to result in
    high risk to rights and freedoms; the EDPB guidelines at
    https://edpb.europa.eu/our-work-tools/our-documents/guidelines_en
    are the authoritative reference for when one is required.
    `[Tier 1.5]` per ADR-013 — EDPB Guidelines under GDPR Art. 70.
    Cite paired with the GDPR Art. 35 Tier 1 reference above.
- **Form of finding**: `applies` when the human confirms EU-user
  service for `pii`; `may apply, verify` when the answer is
  uncertain.

## 2. ePrivacy Directive — Directive 2002/58/EC (cookies, tracking)

- **Triggered by**: `pii` capability when an analytics or tracking
  SDK is present (see [`../triggers.md`](../triggers.md) §3).
- **Primary source**:
  https://eur-lex.europa.eu/eli/dir/2002/58/oj
  (EUR-Lex — Directive on privacy and electronic communications,
  consolidated).
- **What the human reviewer must verify**:
  - **Art. 5(3)** — storing or accessing information on a user's
    terminal equipment requires informed consent except for the
    strictly-necessary exception. This is the basis of the "cookie
    banner" obligation in EU member states.
  - That the project's cookie banner satisfies the consent
    requirements (granular, free choice, easily withdrawn). The
    EDPB Guidelines 03/2022 on dark patterns (
    https://edpb.europa.eu/our-work-tools/our-documents/guidelines/guidelines-032022-deceptive-design-patterns-social-media_en )
    define what does *not* satisfy them. `[Tier 1.5]` per ADR-013 —
    cite paired with the ePrivacy Art. 5(3) Tier 1 reference above.
- **Form of finding**: `applies` whenever a tracking SDK is present
  *and* EU-user service is confirmed.

## 3. Digital Services Act — Regulation (EU) 2022/2065

- **Triggered by**: `messaging` capability when the service hosts
  user-generated content visible to other users (an additional
  human-disambiguation question fires).
- **Primary source**:
  https://eur-lex.europa.eu/eli/reg/2022/2065/oj
  (EUR-Lex — Digital Services Act).
- **What the human reviewer must verify**:
  - Whether the service is an "intermediary service", a "hosting
    service", an "online platform", or a "very large online
    platform" — obligations scale with classification.
  - Notice-and-action procedures, statement-of-reasons obligations,
    transparency reporting, and protection-of-minors obligations
    that apply to online platforms.
- **Form of finding**: `may apply, verify` by default; the Skill
  asks the human a closed-form question about user-content
  visibility before escalating to `applies`.

## Out of scope (in this file)

The following EU regimes are intentionally **not** covered by this
Skill and should be raised separately when relevant:

- **NIS2 Directive** (Directive (EU) 2022/2555 — cybersecurity for
  essential and important entities). Sector-specific.
- **AI Act** (Regulation (EU) 2024/1689) — relevant when the
  project deploys AI systems classified as high-risk under Annex III.
  This Skill does not detect AI-system risk classification.
- **DMA** (Digital Markets Act) — applies only to "gatekeepers"
  designated by the Commission.
- **Member-state-specific** consumer protection, advertising, and
  health/medical/financial regimes layered on top of EU directives.
- **UK GDPR** post-Brexit — the UK regime is separate and is not
  covered here even when an `EU` jurisdiction is declared.

> Last re-verified: 2026-05-09 (initial draft, citations from
> EUR-Lex as of this date).
