# Jurisdiction Reference: Japan (JP)

This file enumerates the JP statutes the compliance-checklist Skill
evaluates when `JP` is in `target_jurisdictions`. Each row cites a
**Tier 1 primary source** (e-Gov 法令検索) for the active text of the
statute. **Tier 1.5** PPC official interpretive guidance (ガイドライン,
Q&A, 通達 issued under 個人情報保護法 §147–§149 delegation, per
ADR-013) appears alongside Tier 1 citations on the same item, marked
`[Tier 1.5]` and never standalone. Secondary sources (commentary,
blog summaries, AI overviews, PPC press releases) are disqualifying.

The agent reading this file must follow the citation links directly
when generating an applicability finding — the URLs are the source of
truth, this file is the navigation index.

## 1. 電気通信事業法 (Telecommunications Business Act)

- **Triggered by**: `messaging` capability (see
  [`../triggers.md`](../triggers.md) §1).
- **Primary source**:
  https://elaws.e-gov.go.jp/document?lawid=359AC0000000086
  (e-Gov 法令検索 — current text of 電気通信事業法).
- **What the human reviewer must verify**:
  - Whether the service constitutes "電気通信事業" (telecommunications
    business) under §2 — most user-to-user messaging features do, but
    the threshold and notification regime depend on whether the
    service is "third-party communication intermediation" or merely a
    closed group within a single service.
  - Whether the project must file a 届出 (notification) or pursue a
    登録 (registration) under §16 / §17, and which threshold the
    service crosses.
  - Whether the 2023 amendment (effective 2023-06-16) on
    "外部送信規律" (external-transmission rules) applies — it covers
    web services that send user information to third parties, and is
    a frequent miss for projects assuming the law is only about
    telecom carriers.
- **Form of finding**: `applies` only when the messaging capability
  is between separate end users *and* the human disambiguation prompt
  in [`../triggers.md`](../triggers.md) §1 was answered "Yes". Otherwise
  `may apply, verify`.

## 2. 特定商取引法 (Act on Specified Commercial Transactions)

- **Triggered by**: `payments` capability (see
  [`../triggers.md`](../triggers.md) §2).
- **Primary source**:
  https://elaws.e-gov.go.jp/document?lawid=351AC0000000057
  (e-Gov 法令検索 — current text of 特定商取引に関する法律).
- **What the human reviewer must verify**:
  - **§11 disclosure obligations** for "通信販売" (mail-order /
    e-commerce): operator name, address, phone, payment timing,
    delivery timing, return policy. Most consumer-facing apps with
    paid features fall under §11 and the ordinance fleshing out the
    required disclosures (`特定商取引に関する法律施行規則`,
    https://elaws.e-gov.go.jp/document?lawid=351M50000040089 ).
  - The 2022-06-01 amendment introducing the
    "特定申込み画面" (specified-application-screen) requirements for
    final purchase confirmation screens.
  - Refund policy obligations and whether the project's actual
    behavior matches what is disclosed.
- **Form of finding**: `applies` for any consumer-facing payment
  capability targeting Japanese end users; `may apply, verify` if the
  user base is unclear.

## 3. 個人情報の保護に関する法律 (Act on the Protection of Personal Information, "改正個人情報保護法")

- **Triggered by**: `pii` capability (see
  [`../triggers.md`](../triggers.md) §3) and `data-egress` capability
  (see [`../triggers.md`](../triggers.md) §4).
- **Primary source**:
  https://elaws.e-gov.go.jp/document?lawid=415AC0000000057
  (e-Gov 法令検索 — current text of 個人情報の保護に関する法律,
  reflecting the 2022-04 effective amendment).
- **What the human reviewer must verify**:
  - Whether the project handles "個人情報" (personal information)
    under §2 — the threshold is low and almost any user-identifying
    data qualifies.
  - The §17–§21 obligations on purpose specification, acquisition
    method disclosure, and use limited to the disclosed purpose.
  - The §27 third-party provision rules and whether opt-in consent
    or opt-out notification is required.
  - The §28 cross-border transfer rules — relevant when the project
    sends user data to servers outside Japan, including to common US
    SaaS vendors. The PPC (個人情報保護委員会) maintains a list of
    "適切な保護措置を講じている国" at
    https://www.ppc.go.jp/personalinfo/legal/kaiseihogohou/ which
    operationalizes the cross-border framework. `[Tier 1.5]` per
    ADR-013 — PPC ガイドライン issued under 個人情報保護法 §147.
    Cite paired with the §28 Tier 1 reference above.
  - The 漏えい等 (data breach) notification requirement under §26
    and the implementing PPC guidelines.
- **Form of finding**: `applies` for any project that meets the
  `pii` trigger; `may apply, verify` for `data-egress` alone (the
  cross-border rules apply only when personal information is
  actually involved in the egress).

## 4. 資金決済に関する法律 (Payment Services Act)

- **Triggered by**: `payments` capability with prepaid-balance or
  wallet signal (see [`../triggers.md`](../triggers.md) §2).
- **Primary source**:
  https://elaws.e-gov.go.jp/document?lawid=421AC0000000059
  (e-Gov 法令検索 — current text of 資金決済に関する法律).
- **What the human reviewer must verify**:
  - Whether the prepaid balance qualifies as "前払式支払手段" under
    §3 — single-purpose prepaid (used only within the service) versus
    multi-purpose prepaid (usable across operators) trigger different
    regimes.
  - Whether the project must register as a 資金移動業者 (funds
    transfer service provider) under §37 if it intermediates
    monetary transfers between users.
  - The 2023-06 amendment introducing electronic-payment-instrument
    rules for stablecoin and similar.
- **Form of finding**: `applies` only when both the `payments`
  trigger and a balance/wallet model are detected; `may apply,
  verify` when only one signal is present.

## Out of scope (in this file)

The following JP regimes are intentionally **not** covered by this
Skill and should be raised separately when relevant:

- **Healthcare-specific** statutes (医療法, 医薬品医療機器等法,
  健康保険法). Defer to ECC's `hipaa-compliance` (which is
  US-focused) is **insufficient**; consult specialized counsel.
- **Financial-instrument-specific** statutes (金融商品取引法,
  銀行法, 信託業法). Defer to specialized counsel.
- **Telecommunications carrier** licensing beyond the
  "電気通信事業" notification surface covered above.
- **Broadcasting** (放送法).
- **Records retention** under industry-specific rules
  (電子帳簿保存法 for tax records, 労働基準法 §109 for HR records,
  道路運送車両法 for vehicle records, etc.). These are
  vertical-specific and require domain knowledge this Skill does
  not have.
- **Gambling, alcohol, tobacco, controlled substances, firearms,
  obscene material, real estate brokerage, used-goods dealing** —
  any of these triggers regimes (風営法, 酒税法, 銃刀法, 古物
  営業法, etc.) far outside the Skill's scope. The Skill's output
  must include a one-line note when any of these vertical signals
  are detected by capability scan, telling the operator to seek
  specialized counsel.

> Last re-verified: 2026-05-09 (initial draft, citations from
> e-Gov as of this date).
