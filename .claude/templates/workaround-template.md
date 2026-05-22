# Upstream Workaround Template

## How to use this template

1. Decide where your workaround registry lives. Common choices:
   - `workarounds/NNN-short-slug.md` at the repo root
   - `docs/workarounds/NNN-short-slug.md` if you already have a `docs/`
     tree
2. Copy this file into that directory and rename it to
   `NNN-kebab-case-slug.md`. Numbering starts at `001` and is
   zero-padded.
3. Fill in the YAML front-matter and the body. **Use the front-matter
   block exactly as shown below — start the file with `---` on its own
   line, paste the keys, end with `---` on its own line. Do not wrap it
   in a code fence.** The example below is shown inside a code fence
   only for display; your actual file must contain the bare YAML.
4. Delete the "How to use this template" block before committing.
5. In the affected source code, place a marker comment that references
   this entry. The CI scaffold expects the strict marker form
   `WORKAROUND-UPSTREAM(<owner>/<repo>#<issue>, fixed=>=<version>)`. The
   `<owner>` and `<repo>` come from the `upstream.issue_url` URL.
6. When the upstream patch lands and the workaround is removed, change
   `status: active` to `status: resolved`, fill in `resolved_in_version`
   and `resolved_on`, and update the CHANGELOG per `user_impact`:
   - `internal` → omit from CHANGELOG (Keep a Changelog 1.1.0 reserves
     the file for user-visible changes; internal-only removals do not
     appear)
   - `changed` → entry under `### Changed`
   - `fixed` → entry under `### Fixed`

This registry is **English-only** by convention (see ADR-006 — the audience
is engineers reading upstream issues directly, and translation drift on
fast-moving content is undesirable).

---

### Front-matter (paste literally as the start of your file)

```yaml
---
id: NNN
status: active        # active | resolved | superseded
title: Short descriptive title
upstream:
  package: <package-name as it appears in your manifest>   # ^[A-Za-z0-9@/_.+:-]+$ (Maven groupId:artifactId allowed)
  ecosystem: npm | pypi | go | crates | maven | pub | swift | other
  issue_url: https://github.com/<owner>/<repo>/issues/<n>
  pr_url:                              # optional, if upstream has an open fix PR
affected_versions: ">=2.1.0 <2.3.0"    # semver range
expected_fix_version:                  # optional; e.g. "2.3.0"
expires_on:                            # optional; YYYY-MM-DD; CI flags stale entries
security_impact: none                  # none | low | medium | high
user_impact: internal                  # internal | changed | fixed
                                       # internal → omit from CHANGELOG
                                       # changed  → CHANGELOG "### Changed"
                                       # fixed    → CHANGELOG "### Fixed"
added_on: YYYY-MM-DD
added_by: <agent or person>
related_adr:                           # optional; e.g. "ADR-014"
resolved_in_version:                   # filled when status flips to resolved
resolved_on:                           # filled when status flips to resolved
---
```

## Symptom

What the user/system sees. Be concrete: stack trace, observed behavior,
broken acceptance criterion. One short paragraph.

## Triage evidence

The three-step cut-over from `docs-researcher` (see ADR-006). Fill all three.

1. **Minimal repro** — link or inline a script that reproduces the issue with
   no project-specific code.
2. **Fixed-deps repro** — confirmation that the same lockfile reproduces the
   issue in a fresh `create-*` / scaffold project, isolating the cause to
   the dependency.
3. **Known-issues search** — what queries were run against the upstream
   issue tracker, and what was found (existing report? duplicate? closed
   without fix?).

## Workaround

What was done in this repo to mitigate the issue. Show the diff intent (not
necessarily the literal diff) and the file paths affected. List every
location where the `WORKAROUND-UPSTREAM(...)` marker is placed.

## Verification steps

How to confirm the workaround is no longer needed once the upstream fix
lands. These steps will be executed when status flips from `active` to
`resolved`. Be specific enough that a future reader (possibly an agent)
can run them mechanically.

1. Bump `<package>` to `<expected_fix_version>` or later.
2. Remove the marker(s) and the workaround code.
3. Run [specific test command or reproduction script].
4. Confirm [specific observable signal].

## Removal trigger

What event makes this workaround removable? Common forms:

- "Upstream releases `<package>@<expected_fix_version>` with the fix from
  `<pr_url>` merged."
- "We migrate off `<package>` to `<alternative>` (tracked in ADR-NNN)."
- "Upstream closes the issue as `wontfix` and we accept the limitation
  permanently — convert this entry to a documented constraint."

## References

- Upstream issue: `issue_url` above
- Related ADR: `related_adr` above (if any)
- Related code locations: list paths or use the marker grep
  (`git grep "WORKAROUND-UPSTREAM(<owner>/<repo>#<issue>"`)
