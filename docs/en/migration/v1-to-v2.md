# Migration Guide: v1.x to v2.0.0

> Audience: maintainers of forks created from ecc-base-template v1.x who want to upgrade to v2.0.0.

## What Changed

v2.0.0 is a breaking release driven by [ADR-003](../adr/003-learning-mode-relocate-and-rename.md). Three independent defects were fixed atomically:

1. The output term `notes` was replaced with `knowledge` throughout to match the artifact's actual shape — a curated, domain-organized reference rather than informal scratch notes.
2. The feature directory moved from `.claude/growth/` to `learn/` at the repository root, restoring the harness-config vs. project-artifact boundary.
3. The 19 pre-seeded placeholder files were removed. `learn/knowledge/` is now empty at install; files are created on first teaching moment per domain (lazy-materialization).

As a consequence, the feature umbrella was also renamed: **Developer Growth Mode** is now **Developer Learning Mode**, and the Skill command changed from `/growth` to `/learn`.

## Path Migration Table

The following paths changed between v1.x and v2.0.0.

| v1.x path | v2.0.0 path |
|---|---|
| `.claude/growth/` | `learn/` |
| `.claude/growth/config.json` | `learn/config.json` |
| `.claude/growth/preamble.md` | `learn/preamble.md` |
| `.claude/growth/notes/<domain>.md` | `learn/knowledge/<domain>.md` |
| `.claude/skills/growth/SKILL.md` | `.claude/skills/learn/SKILL.md` |
| `docs/en/growth/` | `docs/en/learn/` |
| `docs/en/growth/domain-taxonomy.md` | `docs/en/learn/domain-taxonomy.md` |
| `docs/ja/growth/` | `docs/ja/learn/` |
| `docs/ja/growth/domain-taxonomy.md` | `docs/ja/learn/domain-taxonomy.md` |
| `docs/en/growth-mode-explained.md` | `docs/en/learning-mode-explained.md` |
| `docs/ja/growth-mode-explained.md` → | `docs/ja/learning-mode-explained.md` |
| `docs/en/prd/developer-growth-mode.md` | `docs/en/prd/developer-learning-mode.md` |
| `docs/ja/prd/developer-growth-mode.md` | `docs/ja/prd/developer-learning-mode.md` |
| `scripts/check-growth-invariants.sh` | `scripts/check-learn-invariants.sh` |

New paths added in v2.0.0 with no v1.x equivalent:

| New path | Purpose |
|---|---|
| `docs/en/migration/v1-to-v2.md` | This file |
| `docs/ja/migration/v1-to-v2.md` | Japanese translation of this file |
| `docs/en/learn/examples/<domain>.md` | 19 Meridian-grounded worked examples (read-only reference) |
| `docs/en/adr/003-learning-mode-relocate-and-rename.md` | ADR recording the v2.0.0 decisions |

## If Your Fork Has Never Enabled Learning Mode

If you have never run `/growth on` (v1.x command) or `/learn on` (v2.0.0 command), your fork has no accumulated knowledge files and no `config.json`. The migration is documentation-only:

1. Pull the v2.0.0 template changes into your fork.
2. Confirm that `learn/knowledge/` exists as an empty directory and is listed in `.gitignore`.
3. No further action is required. The feature remains off by default.

## If Your Fork Has Enabled Learning Mode and Accumulated Knowledge

If `learn/config.json` (or `.claude/growth/config.json` in v1.x) exists and you have knowledge files you want to preserve, follow these steps.

### Step 1: Move the config file

```bash
git mv .claude/growth/config.json learn/config.json
```

### Step 2: Move accumulated knowledge files

Each domain file moves from `.claude/growth/notes/` to `learn/knowledge/`. Run one command to move all of them at once:

```bash
git mv .claude/growth/notes learn/knowledge
```

If you have a custom directory structure under `.claude/growth/notes/`, adjust the `git mv` command accordingly.

### Step 3: Remove the now-empty growth directory

```bash
git rm -r .claude/growth/
```

If `.claude/growth/preamble.md` was customized in your fork, review the new `learn/preamble.md` that ships with v2.0.0 before discarding the old file. The v2.0.0 preamble reflects the new paths and terminology; your customizations may need to be reapplied.

### Step 4: Update .gitignore

Replace any existing entry that ignores `.claude/growth/notes/` with one that ignores `learn/knowledge/`:

```
# old (remove)
.claude/growth/notes/

# new (add)
learn/knowledge/
```

If you opted in to committing knowledge files (opted out of gitignore), update the opt-in entry:

```
# old (remove)
!.claude/growth/notes/

# new (add)
!learn/knowledge/
```

### Step 5: Search and replace terminology in committed knowledge files

Inside your committed knowledge files (if any), replace occurrences of the old terminology. Apply these substitutions in the order listed to avoid double-replacement:

| Replace | With |
|---|---|
| `## Growth: notebook diff` | `## Learning: knowledge diff` |
| `## Growth: taught this session` | `## Learning: taught this session` |
| `.claude/growth/notes/` | `learn/knowledge/` |
| `.claude/growth/` | `learn/` |
| `notes/` (as a path component) | `knowledge/` |
| `notebook` | `knowledge` |
| `Growth Mode` | `Learning Mode` |
| `Growth Domains` | `Learning Domains` |
| `/growth` | `/learn` |

You can apply these with your editor's project-wide find and replace, or with a sequence of `sed` invocations. No automated script is provided — the migration is mechanical and the population of affected forks is small.

### Step 6: Update CLAUDE.md (if customized)

If your fork's `CLAUDE.md` references `.claude/growth/`, update those references to `learn/`. Pull the updated block from the v2.0.0 template's `CLAUDE.md` and merge your customizations in.

### Step 7: Update agent prompts

Each Learning Mode-aware agent prompt contains a "Developer Learning Mode contract" section. In v1.x these referenced `.claude/growth/config.json` and `.claude/growth/notes/`. Pull the updated agent files from v2.0.0 or apply the path substitutions from the table in Step 5.

The section marker `## Growth Domains` in agent front matter also changed to `## Learning Domains`. The CI script `check-learn-invariants.sh` now anchors on the new marker. If you have custom agents with the old marker, update them before running CI.

## Verify the Migration

After completing the steps above, run the CI invariant script to confirm your fork is consistent:

```bash
bash scripts/check-learn-invariants.sh
```

The script checks three things:

1. The `/learn` Skill has `disable-model-invocation: true`.
2. Every agent that declares `## Learning Domains` contains the guard-branch text that reads `learn/config.json`.
3. `learn/knowledge/` is listed in `.gitignore` (or `.gitignore.example`).

All three checks must pass before merging.

## Summary for Forks That Never Enabled the Feature

Pull v2.0.0. The only observable change is that `learn/` is present at the repository root (empty `knowledge/` subdirectory, gitignored) and the Skill command is `/learn` instead of `/growth`. No accumulated content is at risk. The migration is zero-effort.
