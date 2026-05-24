# Jurisdiction Reference: Platform Stores (Apple App Store, Google Play)

This file enumerates the platform policies the compliance-checklist
Skill evaluates when `platform` is in `target_jurisdictions`. The
target operating context is mobile applications distributed through
Apple's App Store and Google's Play Store.

These policies are treated as **Tier 1 primary sources** because they
are the authoritative platform-side text — there is no higher source.
**Tier 1.5** Apple Privacy Manifest specification and Google Play SDK
Index documentation (per ADR-013) appear alongside Tier 1 citations on
the same item, marked `[Tier 1.5]` and never standalone. Secondary
sources (blog posts, news summaries, third-party policy explainers)
are disqualifying.

The agent reading this file must follow the citation links directly
when generating an applicability finding — the URLs are the source
of truth, this file is the navigation index.

## 1. Apple App Store Review Guidelines

- **Triggered by**: any iOS or iPadOS distribution surface in the
  project (presence of an Xcode project, a Flutter `ios/` directory,
  a React Native `ios/` directory, an `Info.plist`, or a `Capacitor`
  iOS configuration).
- **Primary source**:
  https://developer.apple.com/app-store/review/guidelines/
  (Apple — App Store Review Guidelines, current version).
- **What the human reviewer must verify** (a non-exhaustive
  selection driven by the most common rejection causes):
  - **§3.1 In-App Purchase** — digital goods and services consumed
    inside the app must use Apple's in-app-purchase system; the
    project may not direct users to external payment surfaces for
    the same goods. Significant 2024–2025 amendments around
    external-link entitlements and the EU/JP regulatory carve-outs
    must be re-verified at the cited URL — this row's specifics may
    have changed.
  - **§4.0 Design** and **§4.5 Site-specific Policies** — including
    the App Tracking Transparency framework requirements.
  - **§5.1 Privacy** — consent for personal data collection, data
    minimization, the app privacy questionnaire, and the
    SDK-disclosure obligations introduced for SDKs identified by
    Apple in the "Required Reasons API" framework. The Privacy
    Manifest specification at
    https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
    is `[Tier 1.5]` per ADR-013 (Apple's first-party platform
    interpretive document), cited paired with the §5.1 Tier 1
    Review Guideline reference above.
  - **§5.4** — VPN apps, parental controls, and other regulated
    surfaces.
  - **Subscription disclosure** under §3.1.2 — exact pricing,
    billing period, renewal mechanics, free-trial conversion, and
    cancellation path.
- **Form of finding**: `applies` whenever an iOS distribution
  surface is detected; specific subsections become `may apply,
  verify` based on triggered capabilities (e.g. §3.1 when
  `payments` is triggered).

## 2. Google Play Policy Center

- **Triggered by**: any Android distribution surface in the project
  (presence of an `AndroidManifest.xml`, a Flutter `android/`
  directory, a React Native `android/` directory, or a Capacitor
  Android configuration).
- **Primary source**:
  https://support.google.com/googleplay/android-developer/topic/9858052
  (Google Play — Developer Program Policies, top-level navigation).
- **What the human reviewer must verify** (a non-exhaustive
  selection driven by the most common rejection causes):
  - **Payments policy**
    (https://support.google.com/googleplay/android-developer/answer/9858738)
    — broadly parallel to Apple's §3.1 with its own carve-outs;
    subscription, in-app purchase, and consumable distinctions.
  - **User Data policy**
    (https://support.google.com/googleplay/android-developer/answer/10144311)
    — disclosure, consent, prominent disclosure for sensitive uses,
    data-safety form completion, and the SDK Index obligations.
    The SDK Index documentation
    (https://developers.google.com/android/sdk-index) is
    `[Tier 1.5]` per ADR-013 (Google's first-party platform
    interpretive document), cited paired with the User Data policy
    Tier 1 reference above.
  - **Permissions and APIs that Access Sensitive Information**
    (https://support.google.com/googleplay/android-developer/answer/9888170)
    — special-permissions framework (SMS, Call Log, Background
    Location, etc.) and the manual-review processes attached.
  - **Families policy** — when the app's target audience includes
    children.
  - **Health Apps**, **Financial Services**, **Real-Money Gambling**
    — vertical-specific add-on policies that activate when the
    capability scan detects relevant signals.
- **Form of finding**: `applies` whenever an Android distribution
  surface is detected; specific sub-policies become `may apply,
  verify` based on triggered capabilities.

## Cross-platform interaction with other jurisdictions

Platform policies frequently **incorporate** legal regimes by
reference — Apple's §5.1 Privacy expects compliance with applicable
data-protection law (GDPR, CCPA, JP 個人情報保護法), and Google's
User Data policy makes parallel demands. The Skill therefore lists
platform findings *separately* from the underlying law findings;
both are surfaced when the relevant capabilities and jurisdictions
are declared. A platform policy violation can result in app
rejection or removal even when the underlying legal regime is
satisfied (e.g. an inadequate App Privacy questionnaire entry can
trigger §5.1 enforcement even if the project's actual data practice
is GDPR-compliant).

## Out of scope (in this file)

The following platform surfaces are intentionally **not** covered
by this Skill and should be raised separately when relevant:

- **Web distribution** through general-purpose browsers — no
  central platform policy. Subject only to the underlying legal
  regimes (JP / EU / US-CA in this Skill's scope).
- **Microsoft Store**, **Amazon Appstore**, **Samsung Galaxy Store**,
  **Huawei AppGallery**, **F-Droid**, **APKPure**, **Steam**,
  **Epic Games Store** — each has its own policy framework not
  covered here.
- **WebView / hybrid app** distribution that bypasses platform
  review (sideloading, enterprise deployment) — different
  obligation surface, often jurisdiction-specific.
- **Streaming-platform-specific** policies (Roku, Fire TV, Apple TV
  app store) — separate policy frameworks.

> Last re-verified: 2026-05-09 (initial draft, citations from
> Apple Developer and Google Play documentation as of this date).
> Apple App Store Review Guidelines and Google Play policies update
> frequently — re-verification cadence on these is **quarterly**, not
> half-yearly, given the higher rate of change on platform-side
> policy text.
