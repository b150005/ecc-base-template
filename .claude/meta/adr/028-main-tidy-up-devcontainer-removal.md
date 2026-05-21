# ADR-028: Drop `.devcontainer/` scaffold from the template payload

## Status

Accepted — 2026-05-21

## Context

The `main` payload still carries two residual artifacts that do not pull
their weight as fork-facing defaults:

1. **`.devcontainer/devcontainer.json`** — a 3.6 KB file in which every
   meaningful key (`image`, `features`, `customizations.vscode.extensions`,
   lifecycle commands, `forwardPorts`, `remoteEnv`) is commented out. The
   only live lines are `"name": "Project Dev Container"` and
   `"remoteUser": "vscode"`. The header comment instructs the reader to
   `See .claude/meta/references/devcontainer.md` — but that file does not
   exist on `main` or `develop` (the references directory was never
   created on `main`; the legacy reference file was not preserved on
   `develop` either). The scaffold was introduced in v3.0.0 (`c25140d`,
   `feat!: v3.0.0 — restructure for template-repository UX`) without an
   ADR. No spec references it. The payload manifest on `develop`
   documents it as a "fork-reusable dev environment scaffold," but the
   reusability is hypothetical: a fork that genuinely wants Dev Containers
   will need to choose a base image, enable specific features, and pin
   extensions — all of which the scaffold deliberately refuses to
   prescribe because the template is framework-agnostic. The thing the
   scaffold is reusable *for* (showing a fork "you can use Dev Containers
   here") is already accomplished by mentioning Dev Containers in the
   README; the file itself adds no information beyond what a one-line
   "Add a `.devcontainer/devcontainer.json` if you want Dev Containers"
   sentence would.

2. **`main:.claude/settings.json`** has a dead hook reference. Commit
   `b9256c7` (2026-05-21, `refactor(template): remove develop-only
   skills, hooks, output-styles from main (Roadmap #23)`) deleted
   `.claude/hooks/coaching-context.sh` from `main` as part of AC-2
   cleanup, but did not update `settings.json`'s
   `hooks.UserPromptSubmit` block that registers the hook. The block
   still points at `"$CLAUDE_PROJECT_DIR"/.claude/hooks/coaching-context.sh`,
   which does not exist on `main`. Every fork user starting Claude Code
   sees a hook-resolution warning on the first user prompt of every
   session.

The two problems are bundled into one ADR because their fix sits in the
same PR set and shares the same underlying principle (ADR-026's
"`main` is the fork-clean payload"): items on `main` must either be
load-bearing for forks or must not be there.

## Decision

1. **Remove** `.devcontainer/` from both `main` and `develop`.
2. **Remove** the `hooks.UserPromptSubmit` block from
   `main:.claude/settings.json`, leaving `"hooks": {}` in place so the
   key exists as a documented extension point for forks. `develop`'s
   `settings.json` is **unchanged** — on `develop` the hook is live
   because `coaching-context.sh` is present, and the maintainer-facing
   Learning Mode coaching behavior depends on it.

The ADR-026 amendment 2026-05-21 already establishes that `main` and
`develop` versions of `settings.json` legitimately differ (the same way
`main` carries `.gitkeep` while `develop` carries the full workflows
set). This ADR records the second instance of that divergence.

## Consequences

### Positive

- **No more dead refs on `main`.** Fork users do not see hook-resolution
  warnings on session start. `find .devcontainer` and
  `grep coaching-context settings.json` both return empty on a fresh
  fork.
- **Honest payload.** `main` no longer ships an empty scaffold that the
  README has to footnote and `init.sh` has to mention. Removing the
  file removes three downstream surfaces (README tree row, README.ja
  tree row, `init.sh` next-steps step 4) that all existed only to
  point at the empty file.
- **Smaller payload-manifest surface.** The `.devcontainer/**` glob and
  its section header come out of `.claude/payload-manifest.txt`,
  removing one more line of "what is this for" documentation that the
  maintainers have to keep accurate.
- **Settings.json divergence is now load-bearing, not accidental.**
  `develop`'s hook block points at a file that exists; `main`'s empty
  hooks block exposes the extension point without the bad ref. The
  divergence is documented (here) instead of being a bug-in-waiting.

### Negative

- **Forks that adopt Dev Containers must author their own.** A fork that
  wanted to enable Dev Containers by uncommenting the scaffold now has
  to write the file from scratch. Mitigation: writing a working
  `devcontainer.json` from a base image (e.g.,
  `mcr.microsoft.com/devcontainers/typescript-node:20`) is about ten
  lines and is what the fork would have done anyway once it picked an
  ecosystem — the deleted scaffold added nothing beyond commented-out
  hints.
- **Existing forks that already extended the scaffold** will hit a
  template-sync conflict (they have a non-empty `.devcontainer/`, we
  remove ours). Mitigation: a fork that extended the file is by
  definition keeping its own copy — they need only refuse the upstream
  deletion when they pull, which is the standard `git merge` outcome
  for a file the local side has materially modified.

### Neutral

- README.md and README.ja.md lose their `.devcontainer/` tree row.
  Surrounding box-drawing characters must be revalidated (the row was
  not the last entry, so the deletion is a straight line removal — no
  `├─`/`└─` swap required).
- `.claude/meta/scripts/init.sh` loses its "Customize
  `.devcontainer/devcontainer.json` for your stack" next-step. The
  numbered list is renumbered (4→4 disappears; old 5/6/7 become new
  4/5/6).
- `.claude/payload-manifest.txt` loses the `.devcontainer/**` entry and
  its section header. Other allowlisted paths are unaffected.
- The settings.json fix is recorded in CHANGELOG `### Fixed` rather
  than as its own ADR — it is a regression-style bug (the original
  cleanup commit missed one file) and the design call is fully
  inherited from ADR-026.

## Alternatives considered

| Alternative | Pros | Cons | Why not chosen |
|---|---|---|---|
| **A. Keep `.devcontainer/` but materialize one working ecosystem (e.g., Node 20)** | Forks targeting that ecosystem get a real starting point | Contradicts the framework-agnostic principle (`main` payload must not preselect a language); excludes every fork not on that ecosystem; the ecosystem choice itself becomes a new design decision the template has no basis for making | The template's value is being unopinionated about stack; baking in one ecosystem is a worse defect than the current empty scaffold |
| **B. Keep `.devcontainer/` on `develop` only (as a reference)** | Preserves the file somewhere for maintainers to consult | Forks never see `develop`; the "reference" audience is already served by the comment block proposing `mcr.microsoft.com/devcontainers/...` images that ship in the README. No maintainer has needed this file as a reference since v3.0.0 introduced it | Solves no real problem; adds branch divergence without an audience |
| **C. Fix only the dead hook ref in `settings.json`; leave `.devcontainer/` in place** | Smaller blast radius; the hook bug is the genuine regression while `.devcontainer/` removal is a judgment call | Treats two instances of the same anti-pattern (orphan/dead items in the fork payload) as one fix-now and one defer-forever; AC-2 cleanup (PR #17) already established the pattern that low-value items on `main` come out | Splits a clean cleanup into a half-measure for no review-cost benefit |
| **D. Add `.devcontainer/devcontainer.json` to `init.sh`'s removal prompt set** | Preserves the scaffold for users who want it; lets opt-out remove it | The init.sh removal prompt is for files a fork *might* want to remove (e.g., bilingual files for monolingual projects). `.devcontainer/` does not pass that bar: the scaffold is empty, so there is nothing to opt out *of* | The opt-out mechanism presupposes the opted-out asset has value when retained; this one does not |

## References

- `.claude/meta/adr/026-template-fork-branch-separation.md` —
  establishes the "`main` is the fork-clean payload" principle this ADR
  applies and documents the legitimacy of `main`/`develop` divergence
  for files like `settings.json`.
- `specs/23-template-fork-branch-separation.md` — Spec AC-2 ("`.claude/meta/` absent on `main`") and the broader payload-cleanup
  rationale that PR #17 acted on.
- Commit `c25140d` (`feat!: v3.0.0 — restructure for template-repository UX`) — original introduction of `.devcontainer/devcontainer.json` (no ADR was filed).
- Commit `b9256c7` (`refactor(template): remove develop-only skills, hooks, output-styles from main (Roadmap #23)`) — removed `coaching-context.sh` from `main` but missed `settings.json`.
- PR #17 (`chore(main): remove orphan template-internal files (AC-2 cleanup)`) — prior cleanup that this ADR continues.
- ADR-027 (`Integrate .gitignore.example into .gitignore as a comment block`) — most recent precedent for removing a low-value payload file by collapsing what it documented into a place operators already look.
- Roadmap row: (none — this is a follow-on cleanup from #23, not a new milestone)
