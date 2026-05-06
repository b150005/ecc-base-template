# ADR-006: Upstream workaround tracking — lifecycle management for library/framework-induced issues

## Status

Accepted — 2026-05-06

## Context

When a derived project encounters a defect, the cause may lie in the project's
own code or in an upstream library/framework dependency. ecc-base-template
already places **Research & Reuse** at step 0 of the development workflow,
which structurally increases the rate at which dependencies become the
suspected source. However, no part of the template currently codifies what
to do once an upstream root cause is suspected or confirmed. The four-agent
council (architect / docs-researcher / devops-engineer / technical-writer)
identified the following gaps:

1. **Triage protocol gap.** No agent owns the "is this our bug or upstream's?"
   decision. The implementer and code-reviewer both touch the symptom; nobody
   owns the cut-over.
2. **Upstream issue search gap.** `docs-researcher` has freshness-safe
   guidelines for documentation lookup but none for issue-tracker search,
   making duplicate-report risk and stale-result risk both elevated.
3. **Workaround record gap.** Once a workaround is shipped, no template
   artifact captures the upstream issue URL, the affected version range, the
   verification steps, or the removal trigger. The workaround tends to outlive
   its cause.
4. **Removal-trigger gap.** When the upstream patch lands, nothing in CI flags
   that a previously applied workaround can now be removed. Dependabot alone
   ships a version bump but does not connect that bump back to local
   workarounds.

The cumulative effect is that workarounds silently accumulate as technical
debt with no expiry mechanism — exactly the pattern the template's
"explicit > implicit" architecture principle is meant to prevent.

## Decision

Introduce a **default-off, opt-in** upstream-workaround tracking layer that
divides responsibility across existing agents (no new agent), records each
workaround as a single file under `workarounds/NNN-*.md`, and provides a
language-agnostic CI scaffold that derived projects can enable when their
inventory of workarounds reaches the point where manual tracking breaks down.

### Principles

1. **Default-off, single switch.** Activation is a single config flip:
   `enabled: true` in `.github/workaround-tracker.yml`. The workflow itself
   has no second `if: false` to remove — every job reads the config and
   short-circuits when disabled. This prevents "I flipped one but forgot
   the other" failures.
2. **Decision (ADR) and tracking (registry) are separated.** "Whether to adopt
   a workaround" is captured in the project's ADR stream when it changes
   architecture (e.g., forking the upstream library). "What workaround exists,
   for which issue, until which version" is a registry entry under
   `workarounds/NNN-*.md`. The two cross-reference each other but do not
   duplicate content.
3. **Code marker is line-level, registry carries everything else.** A
   structured comment marker
   (`WORKAROUND-UPSTREAM(<owner>/<repo>#<issue>, fixed=>=<version>)`)
   identifies the upstream issue and the expected fix at the source line.
   Package identity, security impact, verification steps, and CHANGELOG
   mapping live in the registry entry. CI cross-references the two; neither
   alone is sufficient.
4. **Triage is a documented protocol, not a heuristic.** The "ours vs.
   upstream" cut-over is a three-step protocol (minimal repro → fixed-deps
   repro → known-issues search) that `orchestrator` invokes and
   `docs-researcher` executes.
5. **Language-agnostic CI scope only.** The shipped workflow uses `git grep`
   for marker detection, `yq` for YAML parsing (preinstalled on
   `ubuntu-latest`), and `gh pr comment` for Dependabot annotation.
   Version-comparison logic, which requires per-ecosystem lockfile parsing,
   is intentionally **not** shipped. Derived projects add it when they
   commit to a stack.
6. **Orthogonal to Learning Mode.** Tracking is a production runtime
   concern; Learning Mode is a default-off learning concern. Workaround
   records may become reference material for the `dependency-management`
   knowledge domain (one-way reference), but the tracking layer must
   function whether Learning Mode is enabled or not.

### Responsibilities (mapped to existing agents)

| Step | Agent |
|---|---|
| Triage entry — "ours or upstream?" | `orchestrator` |
| 3-step cut-over (minimal repro / fixed-deps repro / known-issues search) | `docs-researcher` |
| Decision to adopt the workaround (when architecturally significant) | `architect` |
| Code marker placement and structured comment | `implementer` |
| Marker structural review | `code-reviewer` |
| CI scaffold + Dependabot connection | `devops-engineer` |
| Registry maintenance + CHANGELOG mapping on removal | `technical-writer` |

Each of these agents has a corresponding short addition to its agent
definition file under `.claude/agents/` so the responsibility is
discoverable by single-agent invocations.

### Required workaround record fields

The CI scaffold requires the following YAML front-matter fields. The
"Required" column is enforced by convention and reflects what the CI
parser actually reads.

| Field | Required | Note |
|---|---|---|
| `id` | Yes | Numeric, zero-padded (e.g. `001`) |
| `status` | Yes | `active` / `resolved` / `superseded` — drives marker-consistency |
| `upstream.package` | Yes | Package name as it appears in the manifest; used by Dependabot annotation. Allowlist: `[A-Za-z0-9@/_.+:-]+` (the `:` accommodates Maven `groupId:artifactId`) |
| `upstream.ecosystem` | Yes | One of `npm` / `pypi` / `go` / `crates` / `maven` / `pub` / `swift` / `other` |
| `upstream.issue_url` | Yes | Permalink to upstream issue or PR; CI extracts `<owner>/<repo>#<n>` for cross-reference with markers |
| `affected_versions` | Yes | semver range, e.g. `>=2.1.0 <2.3.0` |
| `verification_steps` | Yes (body) | Minimum steps to confirm correctness after removal |
| `security_impact` | Yes | One of `none` / `low` / `medium` / `high` |
| `expected_fix_version` | Optional | Filled when upstream milestone is public |
| `expires_on` | Optional | `YYYY-MM-DD`; used by CI to flag stale workarounds |
| `user_impact` | Optional | Drives CHANGELOG categorization on removal — see below |

### CHANGELOG mapping on removal

When a workaround flips to `status: resolved`, `technical-writer` maps
`user_impact` to a CHANGELOG section per Keep a Changelog 1.1.0:

| `user_impact` | CHANGELOG action |
|---|---|
| `internal` | **Omit from CHANGELOG.** Keep a Changelog 1.1.0 reserves the file for user-visible changes; internal-only removals do not appear. |
| `changed` | Add an entry under `### Changed`. |
| `fixed` | Add an entry under `### Fixed`. |

Projects that maintain a separate internal release log are free to record
internal removals there, but the user-facing `CHANGELOG.md` follows Keep
a Changelog strictly.

### Removal-detection strategy

Per `docs-researcher`'s evaluation, the primary signal is **dependency
version comparison** (compare currently-installed version against
`affected_versions`). CHANGELOG parsing is supplementary; GitHub issue
`closed` events are unreliable due to backport patterns and are not used
as the basis for action.

The CI scaffold shipped by the template performs only the
language-agnostic part: it greps for `WORKAROUND-UPSTREAM` markers,
cross-references them against active registry entries, and posts an
idempotent (sticky) comment on Dependabot PRs that touch a referenced
package. Version-range satisfaction is left to the derived project,
which adds an ecosystem-specific job that reads its own lockfile.

### Provided artifacts

| Path | Purpose |
|---|---|
| `.claude/templates/workaround-template.md` | Per-workaround registry entry template (YAML front-matter + body) |
| `.github/workflows/workaround-check.yml` | Reusable CI scaffold; gated by config |
| `.github/workaround-tracker.yml` | Configuration file (`enabled: false` default) |
| `.claude/meta/references/upstream-workaround-tracking.md` | Long-form explainer, including the triage protocol and Issue-Tracker search guidelines |
| Updates to seven agent files (`orchestrator`, `docs-researcher`, `architect`, `implementer`, `code-reviewer`, `devops-engineer`, `technical-writer`) | Agent responsibility additions |
| Updates to `.claude/CLAUDE.md`, `README.md`, `README.ja.md` | Workflow step + discoverability |

### Out of scope (deliberately)

- Per-ecosystem lockfile parsers
- CodeQL queries for workaround detection
- Bidirectional sync with upstream issue trackers
- Automatic Issue creation when an `expires_on` date passes (left as a
  derived-project decision; the CI scaffold can post a PR comment but does
  not auto-create issues)
- **Switching the workflow to `pull_request_target` for any job other
  than `dependabot-annotate`.** The `dependabot-annotate` job uses
  `pull_request_target` because it is the only trigger that grants
  `pull-requests: write` for Dependabot, and it is gated to
  `github.actor == 'dependabot[bot]'` AND
  `pull_request.head.repo.full_name == github.repository`, and it does
  **not** check out PR head code. Adding `pull_request_target` to other
  jobs (or relaxing those gates) is a known foot-gun and is forbidden.

## Consequences

### Positive

- Makes the lifecycle of an upstream workaround visible from the moment it
  is suspected to the moment it is removed.
- Single-switch opt-in (`enabled: true`) eliminates the "two-toggle drift"
  failure mode that would otherwise let a half-enabled workflow silently
  do nothing.
- No new agent — distributes responsibility across the seven agents already
  present in the council, keeping the team size stable.
- Code marker + registry separation lets mechanical CI checks have a
  source of truth at the line level (issue identity) and a richer one in
  the registry (package identity, verification, security) without forcing
  humans to read YAML to understand a comment in source code.
- Cross-reference (markers ↔ registry) catches both directions of drift:
  marker without entry, and active entry without marker.

### Negative

- Adds a new template-internal reference document and a new template file,
  expanding the surface area derived projects may need to read.
- The CI scaffold ships intentionally incomplete (no version comparison),
  which can confuse adopters who expect a turn-key solution. Mitigated by
  documenting the gap explicitly.
- `dependabot-annotate` requires `pull_request_target`, which is a
  high-risk trigger. The accompanying gates (actor check, same-repo
  check, no PR-head checkout) are mandatory and must not be relaxed.
- Risk of registry drift if the marker and the registry entry fall out
  of sync semantically (e.g., the workaround code evolves but
  `verification_steps` does not). The CI scaffold catches structural
  drift only.

### Neutral

- The template's bilingual policy (English source / Japanese translation)
  applies to ADR-006 (`.md` + `.ja.md`) and to the README sections, but
  **not** to:
  - The workaround registry entries (engineers read upstream issues in
    English; translation drift on fast-moving content is undesirable).
  - `.claude/meta/references/upstream-workaround-tracking.md`. This
    document is a deliberate exception, consistent with
    `.claude/meta/references/domain-taxonomy.md` (also English-only):
    its audience is engineers/agents that already read the English
    upstream content, and bilingual maintenance would lag the
    fast-moving guidance it carries.
- ADR template is **not** modified. Workaround records are a separate
  artifact with a different lifecycle, and conflating them would muddy the
  ADR's "decisions, not status" character.

## Alternatives considered

| Alternative | Pros | Cons | Why not chosen |
|---|---|---|---|
| Add a "Workaround" section to `adr-template.md` | Single template to maintain | Conflates immutable decisions with mutable status; ADRs are not meant to be edited as state changes | Rejected by architect and technical-writer for lifecycle mismatch |
| Code marker as the only artifact (no registry) | Maximum simplicity | Unstructured grep-only data; cannot capture multi-line context (verification steps, security impact); not searchable for non-engineers | Rejected by technical-writer for poor discoverability |
| Registry as the only artifact (no marker) | One source of truth | CI cannot verify "every marker has a registry entry" without round-tripping through the registry; reviewers must look up the registry to understand a comment | Rejected for review ergonomics |
| Default-on CI workflow | Higher adoption rate | Inflicts maintenance cost on projects with zero workarounds; conflicts with the template's existing default-off convention | Rejected by devops-engineer for ergonomics and convention |
| Two-toggle activation (workflow `if: false` + config `enabled: false`) | Belt-and-suspenders | Drift between the two is a silent-failure mode (one flipped, one not); doubles the on-boarding friction | Rejected after Round 1 review for fail-unsafe ergonomics |
| Ship per-ecosystem version-comparison jobs (TS/Go/Python/etc.) | Turn-key for adopters | Versions and tooling drift; the same reason `ci-base.yml` does not include language setup applies | Rejected for the same reason as `ci-base.yml`'s language-agnostic stance |

## References

- ADR-005 — template-internal vs consumer-layer separation; this ADR
  follows the same partitioning principle.
- `.claude/agents/docs-researcher.md` — Search Guidelines; this ADR
  extends them to issue-tracker search.
- `.github/workflows/security.yml` — `if: false` default-off precedent
  (this ADR uses a different mechanism — a single config switch — for
  the reasons in Principle 1, but the family resemblance is intentional).
- Multi-agent review of the initial implementation surfaced the issues
  addressed in the final form (single-switch opt-in, 8-field required
  schema, `pull_request_target` discipline, `internal` →
  omit-from-CHANGELOG, bilingual exception for the reference doc).
  Findings are folded into §Decision and §Alternatives considered
  above; no separate review log is committed.
