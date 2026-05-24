# Jurisdiction Reference: California, United States (US-CA)

This file enumerates the California statutes the compliance-checklist
Skill evaluates when `US-CA` is in `target_jurisdictions`. Each row
cites the **primary source** (California Legislative Information) for
the active text. Secondary sources are not used.

The agent reading this file must follow the citation links directly
when generating an applicability finding — the URLs are the source
of truth, this file is the navigation index.

## 1. CCPA / CPRA — California Consumer Privacy Act, as amended by the California Privacy Rights Act

- **Triggered by**: `pii` capability (see
  [`../triggers.md`](../triggers.md) §3) and `data-egress` capability
  (see [`../triggers.md`](../triggers.md) §4), in projects that may
  serve end users in California **and** meet the Act's size
  thresholds.
- **Primary source**:
  https://leginfo.legislature.ca.gov/faces/codes_displayexpandedbranch.xhtml?tocCode=CIV&division=3.&title=1.81.5.&part=4.&chapter=&article=
  (California Legislative Information — Civil Code Division 3, Part 4,
  Title 1.81.5: California Consumer Privacy Act of 2018, as amended).
- **What the human reviewer must verify**:
  - **Applicability thresholds** under Civ. Code §1798.140(d) — a
    business is subject to the Act if any of: (i) gross revenue over
    $25 million, (ii) buys/sells/shares personal information of
    100,000+ consumers or households, (iii) derives 50%+ of revenue
    from selling/sharing personal information. The Skill flags this
    as `may apply, verify` because the thresholds are size-dependent
    and the codebase does not know the operator's revenue.
  - **Consumer rights** — to know, to delete, to correct, to opt-out
    of sale/sharing, to limit use of sensitive personal information,
    and the right not to be retaliated against.
  - **Notice at collection** under §1798.100(b) — the project must
    inform consumers at or before collection of the categories
    collected, the purposes, the retention period, and (for sensitive
    PI) the categories disclosed.
  - **Privacy policy** content requirements under §1798.130 and the
    CCPA Regulations.
  - **"Do Not Sell or Share My Personal Information"** link or
    Global Privacy Control honoring under §1798.135.
  - **Service-provider / contractor / third-party** distinctions
    and the contractual obligations attached to each — the
    classification determines which onward-transfer obligations
    apply.
- **Form of finding**:
  - When `pii` trigger fires but operator size is unknown:
    `may apply, verify`, with the size-threshold note above.
  - When the human confirms the operator meets at least one
    threshold: `applies`.
  - When the operator confirms it does not meet any threshold:
    `out of scope for declared jurisdictions` is **not** correct
    (the Skill must not assert non-applicability per Invariant 1);
    instead the Skill renders the row as
    `may apply, verify (operator-asserted below threshold —
    re-verify if revenue or scale changes)`.

## 2. California Online Privacy Protection Act (CalOPPA)

- **Triggered by**: any commercial website that collects personally
  identifiable information from California consumers — almost any
  `pii`-triggered project serving California users.
- **Primary source**:
  https://leginfo.legislature.ca.gov/faces/codes_displayText.xhtml?division=8.&chapter=22.&lawCode=BPC
  (California Legislative Information — Business and Professions
  Code Division 8, Chapter 22).
- **What the human reviewer must verify**:
  - The privacy policy content requirements under
    §22575–22579, including conspicuous posting and disclosure of
    collected categories, third-party sharing, change-notification
    process, and DNT response.
- **Form of finding**: `may apply, verify` when `pii` is triggered
  and California users are served.

## 3. California Shine the Light Law

- **Triggered by**: `pii` capability when the project shares
  personal information with third parties for the third parties'
  direct-marketing purposes.
- **Primary source**:
  https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?sectionNum=1798.83.&lawCode=CIV
  (California Legislative Information — Civil Code §1798.83).
- **What the human reviewer must verify**:
  - The disclosure-on-request obligation when sharing PII with
    third parties for direct marketing.
- **Form of finding**: `may apply, verify` when the relevant
  sharing pattern is detected.

## Out of scope (in this file)

The following US regimes are intentionally **not** covered by this
Skill and should be raised separately when relevant:

- **HIPAA** (US healthcare privacy). Defer to ECC's
  `hipaa-compliance` Skill.
- **Other state privacy laws** — Virginia VCDPA, Colorado CPA,
  Connecticut CTDPA, Utah UCPA, Texas TDPSA, etc. The Skill covers
  California only when `US-CA` is declared. Operators serving other
  US states must add those jurisdictions explicitly to
  `target_jurisdictions` and contribute jurisdiction reference
  files for them — the Skill will not silently extrapolate from
  California to other states.
- **COPPA** (children under 13) — federal, applies independently
  of state declaration. The Skill flags `pii` triggers with a note
  to evaluate COPPA when the project serves users under 13, but
  COPPA is not enumerated here as a US-CA row.
- **Federal sectoral statutes** — GLBA (financial), FERPA
  (educational records), FCRA (consumer reporting), TCPA
  (telephone consumer protection). All require separate evaluation.

> Last re-verified: 2026-05-09 (initial draft, citations from
> California Legislative Information as of this date).
