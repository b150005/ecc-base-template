# Triggers and PII-Path Refusal

This file defines (a) the **capability-based triggers** the Skill uses
to decide which jurisdiction obligations may be in scope for a given
diff or release, and (b) the **PII path refusal** rules that prevent
the Skill from ingesting test data, seeds, environment files, or
database dumps.

Both lists are intentionally **conservative on the false-positive
side**: it is far better for the Skill to surface a regime that
turns out not to apply than to silently miss one that does. The
human reviewer can dismiss false positives; they cannot recover from
a missed obligation discovered after launch.

## Capability triggers

Triggers are matched by **manifest dependency presence** plus
**code-pattern detection in the project's source tree**, in that
order. Name-based heuristics on file paths or routes are not
sufficient and are not used.

### 1. User-to-user communication (`messaging`)

Detected when **any one** of these is true:

- A real-time messaging dependency is present in the project
  manifest:
  - npm: `socket.io`, `socket.io-client`, `ably`, `pusher`,
    `pubnub`, `centrifuge`, `@supabase/realtime-js`, `mqtt`,
    `paho-mqtt`, `mqtt.js`
  - PyPI: `socketio`, `python-socketio`, `channels`, `redis-py`
    used with pub/sub patterns, `paho-mqtt`
  - pub.dev: `web_socket_channel`, `socket_io_client`,
    `firebase_messaging`
  - go.mod: `github.com/gorilla/websocket`, `github.com/centrifugal/centrifuge`
- A push-notification SDK whose primary use case is user-to-user
  delivery: `firebase-admin` with `messaging` API surface,
  `@react-native-firebase/messaging`, `expo-notifications` with
  user-targeted send patterns.
- A WebSocket route is defined in the project's HTTP framework
  (Express `ws`, FastAPI `websocket_route`, Gin `GET ws`, etc.)
  and a separate authenticated user model exists.

When triggered, the JP `電気通信事業法` row in the output may apply.

**Disambiguation prompt to the human (when uncertain):**
"Does this feature carry messages between separate end users
(rather than between an end user and your own server)?
Yes / No / Skip and re-run later"

### 2. Monetary exchange (`payments`)

Detected when **any one** of these is true:

- A payment-processing SDK is present:
  - npm: `stripe`, `@stripe/stripe-js`, `@adyen/api-library`,
    `square`, `paypal-rest-sdk`, `@paypal/checkout-server-sdk`,
    `braintree`, `mercadopago`, `omise`, `kondoteck`, `pay.jp`
  - PyPI: `stripe`, `paypalrestsdk`, `square`, `mercadopago`
  - pub.dev: `stripe_checkout`, `flutter_stripe`, `pay`
  - csproj: `Stripe.net`, `PayPalCheckoutSdk`
- A subscription-management SDK: `revenuecat-server-side-api`,
  `@revenuecat/purchases-server`, `chargebee`, `recurly`.
- An invoicing or billing module the project itself authors that
  produces customer-facing receipts. Detection signal: presence of a
  PDF-generation dependency (`pdfkit`, `puppeteer`, `weasyprint`,
  `reportlab`) plus an `invoices/` or equivalent directory in source.

When triggered:

- JP: `特定商取引法 §11` may apply.
- JP: `資金決済法` may apply when prepaid balances or wallet
  balances are involved (presence of a "balance" or "wallet" data
  model in the project's own schemas).
- platform: `App Store Review Guidelines §3.1` and
  `Google Play Policy: Payments` may apply for in-app purchase
  surfaces in mobile apps.

### 3. Personal data collection (`pii`)

Detected when **any one** of these is true:

- An authentication SDK is present and exposes a registration flow:
  - npm: `firebase-auth`, `@auth0/nextjs-auth0`, `next-auth`,
    `passport`, `lucia`, `clerk`, `supabase-auth-helpers`
  - PyPI: `django.contrib.auth`, `flask-login`, `authlib`
  - pub.dev: `firebase_auth`, `supabase_auth`
- A form schema in the project source asks for any of:
  full name, date of birth, postal address, phone number, national
  ID, payment-card number, biometric data, geolocation precise to
  ≤100 m, employment information, health information, sexual
  orientation, religious affiliation, political affiliation, racial
  or ethnic origin, criminal record.
- An analytics or tracking SDK that produces user-identifying
  events is present: `@datadog/browser-rum` with user identification
  on, `posthog-js` with `identify()` calls, `@amplitude/analytics-browser`
  with user properties enabled, `mixpanel-browser` with `identify()`,
  `segment` with `identify()`.

When triggered:

- JP: `改正個人情報保護法` may apply (almost always — the threshold
  for "personal information" under the Act is low).
- EU: `GDPR Art. 3` extraterritorial scope may apply if the project
  serves end users in the EU; the Skill always asks the human about
  EU-user serving when this trigger fires.
- US-CA: `CCPA / CPRA` may apply if the project meets the Act's
  size thresholds; the Skill flags this as `may apply, verify`
  with the size threshold cited.

### 4. Data export to third party (`data-egress`)

Detected when **any one** of these is true:

- An outbound HTTP client makes calls to non-self domains in code
  paths that pass user data through their request bodies. Signal:
  `fetch(...)`, `axios.post(...)`, `httpx.post(...)`, `http.NewRequest`
  to URLs that are not the project's own.
- A data-warehousing or analytics-pipeline SDK is present:
  `bigquery`, `@google-cloud/bigquery`, `snowflake-sdk`,
  `@aws-sdk/client-redshift`, `clickhouse`.
- A Webhook-out pattern is implemented (project sends payloads
  to operator-configured external URLs containing user data).

When triggered:

- JP: `改正個人情報保護法 §28` (cross-border data transfer rules)
  may apply.
- EU: `GDPR Chapter V` (international transfers, including the
  adequacy framework and standard contractual clauses) may apply.
- US-CA: `CCPA` "sale or sharing" provisions may apply.

## PII path refusal (Invariant 3)

The Skill **refuses to read** any path matching these globs and
emits a single-line refusal message instead. The list is
deliberately broad. False positives (refusing a legitimate file)
are recoverable; false negatives (ingesting a real PII fixture
into Anthropic's API) may not be.

```text
**/.env
**/.env.*
**/secrets.*
**/credentials.*
**/*credential*
**/*.pem
**/*.key
**/*.p12
**/fixtures/**
**/*fixture*
**/__fixtures__/**
**/seeds/**
**/seed.*
**/seeders/**
**/*.dump
**/*.sql.gz
**/*.bak
**/dumps/**
**/test-data/**
**/sample-data/**
**/users.csv
**/customers.csv
**/email-list*
**/contacts.*
**/*pii*
**/*PII*
```

The Skill also refuses to operate when the working tree contains
any file matching `**/*.csv` whose first non-header row contains a
recognizable email address, phone number in E.164 format, Japanese
mobile number (`090-/080-/070-` prefix), or US SSN format
(`NNN-NN-NNNN`). On detection, the message includes the path and a
note that the operator should move it out of the tree or add it to
`.gitignore` before re-running.

## PII output mask

After refusing PII path inputs, the Skill also masks any of the
following patterns in its **output text** before returning it.
Mask format: `[redacted-pii:<type>]`.

- Email addresses (RFC 5322 simplified pattern).
- E.164 phone numbers (`+<digits>`, length 7–15).
- Japanese mobile numbers (`(070|080|090)-\d{4}-\d{4}` and the
  hyphen-less variants).
- Japanese postal codes (`\d{3}-\d{4}`) when adjacent to text that
  looks like an address (presence of `都|道|府|県|市|区|町|村` in
  the same paragraph).
- US Social Security number format (`\d{3}-\d{2}-\d{4}`).
- US ZIP codes (`\d{5}(-\d{4})?`) when adjacent to address-shaped
  text.
- 16-digit sequences with Luhn-valid checksums (probable payment
  card numbers).
- IBAN-shaped strings.
- IP addresses in v4 and v6 form (because user IP is itself
  considered personal data under GDPR Art. 4(1)).

The mask runs **after** the model has produced the report text,
not before — the model never sees the raw PII because Invariant 3
prevented ingestion. The output mask is a defense-in-depth layer
in case a triggered capability detection accidentally surfaces a
sample value the model encoded from manifest schema fields.

## Update cadence

This file is updated whenever:

- A new pattern of capability emerges in the ecosystem (a new
  payment SDK gains material market share, a new messaging
  protocol becomes load-bearing).
- A jurisdiction's primary statute changes its triggering surface
  (e.g. an amendment that brings a new SDK pattern under scope).
- A false-negative is reported by an operator (a triggered
  capability that should have been flagged but was not).

The half-yearly re-verification pass for `jurisdictions/*.md` is
the natural moment to also re-walk this file. Record the
re-verification date in this file's footer:

> Last re-verified: 2026-05-09.
