# ADR-027: Integrate `.gitignore.example` into `.gitignore` as a comment block

## Status

Accepted — 2026-05-21

## Context

ADR-001 (Developer Growth Mode, since renamed to Learning Mode in ADR-003), ADR-003, and ADR-005 established a two-file pattern for documenting the Learning Mode privacy posture:

- `.gitignore` — default-ignores `.claude/learn/knowledge/` and `.claude/learn/config.json`. This is the posture every fork inherits unless they opt in.
- `.gitignore.example` — documents the opt-in inversion (`!.claude/learn/knowledge/` block) that teams can copy into their real `.gitignore` if they want a shared team knowledge base.

The two-file split was chosen for "clean default `.gitignore`" and "explicit opt-in surface that teams must consciously copy." Both invariants are checked by `.claude/meta/scripts/check-learn-invariants.sh` and `.github/workflows/learn-invariants.yml`.

In practice the split has produced friction:

1. **Naming misleads.** A fork operator (2026-05-21) read `.gitignore.example` as "an example `.gitignore`" (i.e., a sample to copy wholesale), not as "documentation of an opt-in inversion to splice into your existing `.gitignore`." The `.example` suffix overloads a convention used elsewhere (`.env.example` is a sample to copy wholesale).
2. **Two files for one posture.** Maintaining default + opt-in documentation in two separate files multiplies the surface area: 20+ files reference `.gitignore.example` by name (ADRs, PRD, references, skills, README, CI workflow, the invariant-check script, payload manifest). Every such reference is a synchronization debt.
3. **Discoverability is worse, not better.** A team considering opt-in must (a) know `.gitignore.example` exists, (b) open it, (c) copy the right lines into `.gitignore`. If the inversion lived as a commented block inside `.gitignore` itself, step (a) and (b) collapse — anyone editing `.gitignore` sees the opt-in path immediately.

The original design intent (default ignore + opt-in inversion is the only allowed shape) is sound and is preserved. What changes is the **documentation mechanism**: from a separate file to a comment block within the file that already governs the behavior.

## Decision

Integrate `.gitignore.example` into `.gitignore` as a comment block. Specifically:

1. **Add** an `## Optional: opt-in to a shared team knowledge base` comment block to `.gitignore`, immediately after the Learning Mode default-ignore lines. The block contains:
   - The rationale (one paragraph) — why the knowledge base is gitignored by default.
   - The inversion pattern as commented-out lines (`# !.claude/learn/knowledge/` and `# !.claude/learn/knowledge/**`) that teams uncomment to opt in.
   - The trade-off note (one paragraph) — what teams should expect when they share knowledge files (revision history visibility, mixed-seniority entries, psychological-safety implications).

2. **Delete** `.gitignore.example` from the repository.

3. **Update** all references:
   - `.claude/payload-manifest.txt` — remove `.gitignore.example` line. **Sequencing note:** the manifest entry must remain in place *during* the payload PR that deletes the file, otherwise the manifest gate (which validates `git diff --name-only` against the manifest pattern set) rejects the deletion as an off-manifest path. The manifest entry is removed in a separate develop-only commit *after* the payload PR has merged, so the manifest reflects the final state without ever forbidding the deletion that produced that state.
   - `.github/workflows/learn-invariants.yml` — remove `.gitignore.example` from `paths:` triggers.
   - `.claude/meta/scripts/check-learn-invariants.sh` — replace the "file existence + inversion block" check with a "comment block exists in `.gitignore`" check.
   - `README.md` + `README.ja.md` — remove `.gitignore.example` from the Project structure tree.
   - ADR-001 (EN+JA), ADR-003 (EN+JA), ADR-005 (EN+JA) — append amendments noting that the documentation mechanism is superseded by ADR-027 (the design intent remains intact).
   - PRD `.claude/meta/prd/developer-learning-mode.md` (EN+JA) — update FR-009 and acceptance-criteria wording to reference the comment block in `.gitignore`.
   - References `.claude/meta/references/domain-taxonomy.md`, `learning-mode-explained.md` (EN+JA), `migration/v1-to-v2.md` (EN+JA) — update prose pointers.
   - Skill `.claude/skills/learn/SKILL.md` — update opt-in pointer.

4. **Preserve** historical references in `.claude/meta/CHANGELOG.legacy.md` (those entries describe the past state and are not rewritten).

The design intent of ADR-001 Decision 4 ("knowledge files gitignored by default; opt-in is the only allowed sharing mechanism") and ADR-003 Decision 6 (Learning Mode's gitignore posture) is **unchanged**. ADR-005's path-mapping consequence stands.

## Consequences

### Positive

- **One file, one posture.** Anyone reading `.gitignore` sees the full Learning Mode privacy story (default + opt-in path) without opening a second file.
- **Naming is honest.** `.gitignore` is the file that controls ignores; the opt-in inversion lives where the operator already looks. No `.example` suffix to misread.
- **Synchronization debt cut.** The number of files referencing the documentation mechanism drops from 20+ to ~5 (after this PR: `.gitignore`, ADR-027, the invariant-check script, the workflow, and CHANGELOG entries).
- **Discoverability up.** Teams considering opt-in see the path on the same screen as the default — no separate file to find.

### Negative

- **`.gitignore` is longer.** About 20 lines of comment are added (rationale + commented inversion + trade-off note). This is a one-time addition and lives in a single place that operators already read.
- **One-PR migration cost.** 20+ files need their `.gitignore.example` references updated. The cost is paid once; future maintenance is simpler.
- **Hardcoded knowledge inside `.gitignore`.** If the Learning Mode runtime path layout changes (e.g., `.claude/learn/knowledge/` → some other path), the comment block in `.gitignore` must also be updated. This was already true for the default-ignore lines, so the new exposure surface is small.

### Neutral

- ADR-001 / ADR-003 / ADR-005 retain their decision wording; only the **documentation mechanism** clause is superseded. The design intent (default ignore + opt-in inversion as the sole sharing path) is unchanged.
- The `check-learn-invariants.sh` Check 3 logic changes shape (no longer checks file existence + inversion-in-second-file; now checks default-ignore + opt-in-comment-block-in-same-file). The invariant being protected is the same.
- The `learn-invariants.yml` workflow no longer triggers on `.gitignore.example` changes (the file no longer exists). Triggers on `.gitignore` itself are unchanged.

## Alternatives considered

| Alternative | Pros | Cons | Why not chosen |
|---|---|---|---|
| **A. Keep `.gitignore.example` as-is** | Zero migration cost; preserves the explicit "you must copy this somewhere" affordance | Naming continues to mislead; 20+ files remain coupled to the dual-file scheme; ergonomic friction persists | The friction is real and documented in user feedback; preserving status quo means re-litigating this repeatedly |
| **B. Rename `.gitignore.example` to `gitignore-share-opt-in.md`** | Honest filename; preserves file separation; smaller scope than C | Two files still; 20+ references still need updating; markdown extension breaks `git diff` ergonomics on a file whose content is shell-comment-flavored | Solves the naming problem but not the two-file-management problem |
| **C. Defer to a broader Learning Mode opt-in / footprint reduction milestone** | Bundles related concerns | Postpones the user-visible friction indefinitely; Learning Mode footprint reduction is a separate scope and timing decision | The integration is cheap enough to land standalone; coupling delays the fix without benefit |

## References

- `.claude/meta/adr/001-developer-growth-mode.md` — partial supersede of Decision 4 documentation mechanism (intent preserved).
- `.claude/meta/adr/003-learning-mode-relocate-and-rename.md` — partial supersede of Decision 6 documentation mechanism (intent preserved).
- `.claude/meta/adr/005-template-restructure.md` — Consequences note about `.gitignore` / `.gitignore.example` superseded by this ADR.
- `.claude/meta/prd/developer-learning-mode.md` — FR-009 wording update follows from this decision.
- `.claude/meta/scripts/check-learn-invariants.sh` — Check 3 logic update follows from this decision.
- `.github/workflows/learn-invariants.yml` — `paths:` trigger update follows from this decision.
- User feedback (2026-05-21) on the dual-file naming.
- Roadmap row: (none — this is a follow-on from #23 design hygiene, not its own milestone)
