# Upstream Workaround Tracking

> Reference for ADR-006. The ADR captures *why* and *what to provide*.
> This document captures *how to use it* day-to-day.
>
> This file is **English-only by design** (see ADR-006 §Neutral). Its
> audience is engineers and agents who already read upstream English
> content directly; bilingual maintenance would lag the fast-moving
> guidance below.

## When this applies

You are working on a defect, and the most likely cause is a library or
framework you depend on rather than your own code. Examples:

- A regression appears only after a dependency bump.
- Documented behavior of a library does not match observed behavior.
- A long-standing bug report exists in the upstream issue tracker that
  matches your symptom.

If the bug is in your own code, none of this applies — fix it and move on.

## The triage protocol (3 steps)

The cut-over from "ours" to "upstream" is decided by `docs-researcher`,
invoked by `orchestrator`. All three steps are required before a workaround
is recorded.

### Step 1 — Minimal reproduction

Reduce the case to the smallest possible script that exhibits the symptom
*with no project-specific code*. If the symptom disappears when the
project is removed from the picture, the cause is on your side and the
protocol stops here.

### Step 2 — Fixed-deps reproduction

Take the lockfile that exhibits the bug and apply it to a freshly
generated scaffold project (`create-next-app`, `cargo new`, `flutter
create`, etc.) of the same shape. If the symptom reproduces in the
scaffold with the same lockfile, the cause is in the dependency graph.

### Step 3 — Known-issues search

Search the upstream issue tracker (and adjacent forums) for the symptom.
Three outcomes:

- **Existing report, open** → record its URL; this is the workaround entry's
  `upstream.issue_url`. Do not file a duplicate.
- **Existing report, closed without fix** → the upstream stance is
  effectively "wontfix". Treat the workaround as a long-lived constraint
  rather than a temporary measure.
- **No existing report** → file a new upstream issue using the upstream's
  CONTRIBUTING / Issue template, then record that URL. Always file before
  recording the workaround so the ID is real.

### Issue-tracker search guidelines (extension to docs-researcher)

The same freshness-safe principle from `docs-researcher.md` applies, with
issue-tracker-specific additions:

- **Do not put years in the query.** Use status filters instead:
  `is:issue is:open label:bug <symptom>`, then expand to `is:closed` if
  no open match exists.
- **Search the upstream's primary tracker first**, then mirrors
  (StackOverflow tag, official Discussions, Discourse forums). Public
  JIRA only if the upstream uses one.
- **Search by error message verbatim, then by behavior.** Verbatim
  matches dominate; behavioral queries surface adjacent reports that may
  be the same root cause filed under a different symptom.
- **Capture the timestamp of the search** in the registry entry's
  `added_on` field. Issue trackers move; a search result is valid as of a
  date.

## Recording the workaround

### Code marker

Place a single-line marker in source where the workaround code lives. The
strict format is enforced by the CI regex:

```
// WORKAROUND-UPSTREAM(facebook/react#12345, fixed=>=18.3.0)
```

Components:

- `<owner>/<repo>` — exactly as in `upstream.issue_url`
- `#<issue>` — the issue or PR number
- `fixed=>=<version>` — the version at which the workaround can be
  removed (matches `expected_fix_version` in the registry entry)

The CI scaffold (`workaround-check.yml`) cross-references the
`<owner>/<repo>#<issue>` portion against active registry entries via
their `upstream.issue_url`.

### Registry entry

Copy `.claude/templates/workaround-template.md` to your registry
directory (e.g., `workarounds/NNN-*.md` or `docs/workarounds/NNN-*.md`)
and adjust `registry_dir` in `.github/workaround-tracker.yml` to match
if non-default. Required fields (CI parser reads these):

| Field | Required |
|---|---|
| `id` | yes |
| `status` | yes (`active` / `resolved` / `superseded`) |
| `upstream.package` | yes (allowlist `[A-Za-z0-9@/_.+:-]+`; `:` for Maven `groupId:artifactId`) |
| `upstream.ecosystem` | yes |
| `upstream.issue_url` | yes |
| `affected_versions` | yes (semver range) |
| `verification_steps` | yes (in body) |
| `security_impact` | yes (`none` / `low` / `medium` / `high`) |

`expected_fix_version`, `expires_on`, and `user_impact` are optional but
strongly recommended.

**Front-matter is bare YAML, not fenced.** The first line of the file is
`---` and the YAML keys begin on line 2. Do not wrap in a `yaml` code
fence — the CI YAML parser reads the file directly.

### When to also write an ADR

The workaround entry is sufficient for the *tracking* concern. Write an
ADR (in your project's ADR stream, *not* under `.claude/meta/adr/`) only
when adopting the workaround changes architecture. Examples:

- Forking the upstream library and vendoring it.
- Switching to an alternative library because the workaround cost is too
  high.
- Designing around the bug in a way that affects module boundaries.

In those cases, cross-link the ADR and the workaround entry via
`related_adr` in the YAML and a `## References` link in the ADR.

## Removing the workaround

When the upstream patch lands and Dependabot bumps the dependency past
`affected_versions`:

1. The CI workflow's Dependabot-annotation job posts (or updates) a
   sticky comment on the bump PR identifying the registry entry.
2. The author of the bump PR (or whoever picks it up) runs the
   `verification_steps` from the registry entry.
3. If verification passes, remove the marker(s) and the workaround code
   in the same PR.
4. Flip the registry entry: `status: resolved`, fill
   `resolved_in_version` and `resolved_on`.
5. Update `CHANGELOG.md` based on `user_impact` (Keep a Changelog 1.1.0):
   - `internal` → **omit from CHANGELOG.** Keep a Changelog 1.1.0
     reserves the file for user-visible changes; internal-only removals
     do not appear.
   - `changed` → entry under `### Changed` describing the user-visible
     behavior change.
   - `fixed` → entry under `### Fixed` describing the user-visible bug
     that is now fixed.

## CI scaffold scope

The shipped workflow (`workaround-check.yml`) does only the
language-agnostic part:

- Reads `.github/workaround-tracker.yml` for `enabled`, `registry_dir`,
  `fail_on_marker_drift`, `annotate_dependabot_prs`, `expiry_warning_days`.
  All settings are honored — none are decorative.
- `git grep` for markers using a strict regex
  (`WORKAROUND-UPSTREAM\([A-Za-z0-9._-]+/[A-Za-z0-9._-]+#[0-9]+, *fixed=>=[A-Za-z0-9._+-]+\)`).
- Cross-references markers against active registry entries (drift
  detection in both directions).
- Scans `expires_on` dates and warns on overdue/imminent (scheduled and
  manual runs only — not on every PR).
- Posts an idempotent (sticky) Dependabot PR comment when a bumped
  package is referenced by an active entry, edited in place on
  re-pushes.

It does **not** parse lockfiles to verify whether a bump actually crosses
out of `affected_versions`. That part is per-ecosystem and lives in a
job that the derived project adds. A typical addition:

- TypeScript: `npm ls <pkg> --json | jq -r '.dependencies."<pkg>".version'`
- Python: `pip show <pkg> | awk '/^Version:/ {print $2}'`
- Go: `go list -m <pkg>`

The result is then compared to `affected_versions` (semver range) using
the ecosystem's standard semver tool. Adding this step turns the warning
into an actionable green/red signal.

## Default-off opt-in (single switch)

Both the workflow and the config file ship in the off position, but
activation is **a single config flip**. The workflow contains no
`if: false` to remove — every job reads `.github/workaround-tracker.yml`
and short-circuits when `enabled: false`.

The opt-in path:

1. Create your first registry entry under your chosen `registry_dir`.
2. Place the corresponding `WORKAROUND-UPSTREAM(...)` marker in source.
3. Set `enabled: true` in `.github/workaround-tracker.yml`. (Optionally
   set `annotate_dependabot_prs: true` if you want Dependabot PR
   comments; it is `false` by default.)
4. Push. The next CI run picks up the new state.

There is no penalty for staying off. Projects with zero workarounds get
zero CI noise.

## Trigger discipline (security)

The `dependabot-annotate` job uses `pull_request_target` because
Dependabot PRs cannot otherwise post a comment (GITHUB_TOKEN is
read-only on `pull_request` from forks, which is what Dependabot looks
like to the trigger). To stay safe:

- The job is gated to `github.actor == 'dependabot[bot]'` AND
  `pull_request.head.repo.full_name == github.repository`.
- The job does **not** check out PR head code. Only base ref is
  fetched.
- ADR-006 forbids extending `pull_request_target` to other jobs or
  relaxing these gates.

If you need to extend the workflow, keep the `pull_request_target`
trigger isolated to the annotation job and avoid running PR-author
scripts under it.

## Failure modes the scaffold cannot catch

- **Semantic drift in `verification_steps`.** If the workaround code
  evolves but the registry's verification steps do not, removal will
  silently miss things. Treat verification steps as part of the
  workaround code; review them whenever the marker line moves.
- **Issue closed-but-not-fixed.** Upstream sometimes closes issues for
  reasons unrelated to a fix (stale, wontfix, dup). The scaffold does
  not consume issue state precisely because of this; humans confirm.
- **Workarounds without markers.** If a workaround is committed without
  the marker, no scan can find it. Code review catches this; the marker
  is a hard requirement, not a suggestion.
- **Markdown / comment injection from a malicious registry edit.** The
  CI applies an allowlist to `upstream.package`
  (`[A-Za-z0-9@/_.+:-]+`) before posting it in PR comments. Code review
  must still inspect new registry entries against the allowlist; the
  CI rejects out-of-band characters by skipping the entry rather than
  running them.

## See also

- ADR-006 — `.claude/meta/adr/006-upstream-workaround-tracking.md`
- Workaround entry template — `.claude/templates/workaround-template.md`
- Agent responsibilities — `orchestrator.md`, `docs-researcher.md`,
  `architect.md`, `implementer.md`, `code-reviewer.md`,
  `devops-engineer.md`, `technical-writer.md`
- CI scaffold — `.github/workflows/workaround-check.yml`
- Configuration — `.github/workaround-tracker.yml`
