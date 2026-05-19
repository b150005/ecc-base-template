# init.sh Roadmap Placeholder Cleanup at Fork Time

## Status

Approved

**Owner:** product-manager
**Target release:** next minor — no versioned release cycle in this repo

## Problem

When someone forks ecc-base-template, `.claude/CLAUDE.md` ships with a
fully populated `## Roadmap` section containing 21 dogfooding rows (#01–#21)
specific to the template's own development, plus a `**Spec reservation rule:**`
paragraph that documents the template's internal `specs/NN-slug.md` reservation
convention. None of these rows or the reservation-rule paragraph belong in a
derived project's Roadmap — the fork's `product-manager` should own a blank
Roadmap and grow it from zero, not inherit 21 rows whose Spec files do not
exist in the fork (most `specs/NN-slug.md` paths in the table are real files in
the template repo and would become dangling references the moment the fork drops
the `specs/` directory content). The `## Extending This File` item 6 already
says "Fill the Roadmap section as you plan milestones", implying an empty start,
but `init.sh` does not automate this. Fork owners today either manually delete
the rows (tedious, error-prone) or leave the inherited rows in place (pollutes
their Roadmap index with irrelevant history).

## Goals

- `init.sh` removes the 21 template dogfooding rows and the `**Spec reservation
  rule:**` paragraph from a fork's `## Roadmap` section at initialization time.
- The post-cleanup `## Roadmap` section is well-formed: it passes the #04
  dangling-refs detector and the #05 roadmap-drift detector when those CI
  scripts are retained in the fork.
- Cleanup is gated on the existing `has_placeholder` sentinel (`[YOUR PROJECT
  NAME]` still present), so this template repo's own Roadmap is never touched.
- Cleanup is idempotent: a second `init.sh` run after the placeholder has been
  replaced does not corrupt the fork's Roadmap.
- `--dry-run` prints what would change without writing files (parity with all
  other `init.sh` mutations).

## Non-goals

- Does not touch `README.md`, `README.ja.md`, or any file other than
  `.claude/CLAUDE.md`.
- Does not modify the template repo's own Roadmap (protected by the
  `has_placeholder` gate).
- Does not add a new CI detector or change how existing detectors (#04, #05,
  #06) work — the post-cleanup CLAUDE.md must simply satisfy their existing
  rules unchanged.
- Does not delete the `specs/` directory or any Spec files; only CLAUDE.md is
  edited.
- Does not clean up the `**Rules:**` block (the multi-bullet block following
  the table) — those rules are universal governance for any Roadmap and belong
  in every fork.
- Does not clean up the intro sentence or the `## Roadmap` heading itself —
  the section is kept, just emptied of template-specific content.
- Does not introduce a separate Roadmap-specific sentinel; the existing
  `has_placeholder` gate is the sole discriminator (see Key Interactions).
- Does not decide whether forks should retain or delete the CI detector
  workflows (`.github/workflows/`) — that is the fork owner's choice and
  orthogonal to this cleanup.
- Does not add a new ADR unless the architect determines the `init.sh`
  contract boundary meets the ADR-018 triad. As designed, this is a
  straightforward extension of init.sh's existing mutation scope.

## User stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| developer forking the template | run `init.sh` once and get a clean, empty Roadmap | I don't have to manually delete 21 irrelevant rows before planning my own milestones |
| developer re-running init.sh on an already-initialized fork | see "Roadmap already customized — skipping" | my Roadmap is not corrupted on repeat runs |
| developer previewing changes before committing | use `--dry-run` | I can review what init.sh would change before it writes anything |

## Acceptance criteria

The following criteria are written to be verified directly against the script
behavior and file contents, not just test-suite assertions.

1. **Cleanup fires on a fresh fork.**
   Given a CLAUDE.md that contains `[YOUR PROJECT NAME]` (has_placeholder=1),
   when `init.sh` runs (non-dry-run), then:
   a. All 21 data rows (`| 01 |` through `| 21 |`) are absent from the
      `## Roadmap` section of the resulting CLAUDE.md.
   b. The `**Spec reservation rule:**` paragraph (the block beginning with
      `**Spec reservation rule:**` and ending before the blank line before the
      table header) is absent.
   c. The `## Roadmap` section heading is still present.
   d. The intro sentence (starting "Single entry point mapping…") is still
      present.
   e. The table header row (`| # | Milestone | Status | Design source |`) and
      its separator row (`|---|-----------|--------|---------------|`) are still
      present.
   f. Exactly one placeholder data row is present in the table:
      `| — | [Add your first milestone here] | ☐ todo | (none yet) |`
   g. The `**Rules:**` block (the multi-bullet list following the table) is
      still present, unmodified.

2. **Post-cleanup CLAUDE.md passes the #05 glyph well-formedness check.**
   Given the placeholder row inserted by criterion 1f, the `☐ todo` glyph
   satisfies the four-glyph contract (☐/◐/☑/✗) and the drift detector
   (`check-roadmap-drift.sh`) does not emit a FAIL for that row.

3. **Post-cleanup CLAUDE.md passes the #04 dangling-refs check.**
   Given the placeholder row inserted by criterion 1f, the `(none yet)` design
   source cell contains no `spec:` or `adr:` link tokens, so the dangling-refs
   detector (`check-dangling-refs.sh`) emits no FAIL originating from that row.

4. **Cleanup is skipped when the placeholder is already gone (idempotency /
   re-run safety).**
   Given a CLAUDE.md where `[YOUR PROJECT NAME]` has already been replaced
   (has_placeholder=0), when `init.sh` runs a second time, then:
   a. The `## Roadmap` section is byte-for-byte unchanged.
   b. A line matching `ok "… already customized — skipping"` is printed (or
      equivalent skip signal), consistent with the existing About This Project
      skip path.

5. **`--dry-run` parity.**
   Given a fresh-fork CLAUDE.md (has_placeholder=1), when `init.sh --dry-run`
   runs, then:
   a. No bytes of `.claude/CLAUDE.md` are modified.
   b. A `[dry-run]` message is printed describing that the Roadmap section
      would be cleaned up, mirroring the `[dry-run] would replace the
      placeholder block…` style used for the About cleanup.

6. **Template repo protection.**
   Given the actual template repo at HEAD (where `[YOUR PROJECT NAME]` is still
   the literal placeholder text in `## About This Project`), the Roadmap
   cleanup path IS entered (has_placeholder=1). Therefore the template repo's
   Roadmap rows (all 21) WOULD be removed if `init.sh` were run against the
   template itself. This is the correct and intended behavior: the template repo
   is expected to run `init.sh` only once as a "dogfood" check during
   development, never in production. The `has_placeholder` gate is documented
   as the discriminator — any repo that has already completed init (placeholder
   replaced) retains its Roadmap intact.

   **Implementation note for AC-6:** The description above is intentional
   design, not a defect. The template repo's own CI does NOT run `init.sh`
   against itself. The protection for the template's own Roadmap in day-to-day
   development is the fact that `init.sh` is never invoked in the template
   repo's CI pipeline and is only meant to be run once by a human after
   forking.

7. **`ok` message on success.**
   When the cleanup fires and writes changes, a line matching
   `ok "Updated .claude/CLAUDE.md (Roadmap section cleaned)"` (or equivalent
   `[OK]`-prefixed message) is printed to stdout.

8. **awk implementation constraint.**
   The Roadmap cleanup MUST be implemented as an `awk` (or equivalent single
   sed/awk pass) mutation of CLAUDE.md, consistent with how the About
   This Project block is replaced — no line-by-line bash loops reading/writing
   the file. This ensures the operation is atomic (temp file + mv) and safe
   against partial writes.

## Key interactions

### Sentinel decision: `has_placeholder` gate (no separate Roadmap sentinel)

The Roadmap cleanup is gated on the existing `has_placeholder` flag (`[YOUR
PROJECT NAME]` present in CLAUDE.md). Rationale:

- A fresh fork has the placeholder in `## About This Project` AND has the 21
  dogfooding rows in `## Roadmap`. Both indicate an uninitialized state.
- A fork that has completed `init.sh` has no placeholder AND has an
  already-cleaned Roadmap. Both are post-initialization states.
- There is no valid intermediate state where the placeholder is gone but the
  Roadmap still has the 21 template rows (or vice versa), assuming `init.sh` is
  the only mutation path.
- A separate Roadmap-specific sentinel (e.g., a comment marker inside the
  Roadmap section) would add complexity with no additional safety margin.

The Roadmap cleanup is therefore added as a second mutation inside the
`if [[ $has_placeholder -eq 1 ]]; then` block alongside the existing About
This Project replacement.

### CI detector compatibility

The `check-roadmap-drift.sh` (#05) parser keys on `## Roadmap` as a heading
and scans pipe-delimited data rows (cells matching `| <digits> |`). The
placeholder row `| — | [Add your first milestone here] | ☐ todo | (none yet) |`
uses an em-dash in the `#` cell, which does NOT match `[0-9]+`, so it is
invisible to the drift detector's row parser. The `☐ todo` glyph is present for
human readability but the row is not scanned for bidirectional-link consistency.
This is correct behavior: there is no `spec:` or `adr:` claim to verify.

The `check-dangling-refs.sh` (#04) Check 2 scans CLAUDE.md for `specs/` and
`.claude/`-rooted path strings. The placeholder row contains `(none yet)` with
no path tokens, so no dangling-ref is possible.

The `**Rules:**` block retained in the section contains `specs/NN-slug.md` and
`specs/NN-progress.md` as metasyntactic placeholders — these match the
`specs/NN-*` skip pattern in check-dangling-refs.sh and are already handled
correctly in the template repo.

### Order of operations in init.sh

The Roadmap cleanup runs after the About This Project replacement (step 2 in
the current script) and before the `.env` copy (step 3). Both mutations target
the same file (CLAUDE.md); performing them in sequence on separate awk passes
(About first, then Roadmap) is the safest approach. Alternatively, a single
combined awk pass may be used if it keeps the logic readable — the implementer
decides.

### `--dry-run` behavior

When `--dry-run=1`, print a `[dry-run]` message describing the Roadmap cleanup
(e.g., `[dry-run] would clean up the ## Roadmap section (remove 21 template
rows and Spec reservation rule paragraph)`). Do not modify CLAUDE.md. This
mirrors the existing About dry-run message pattern exactly.

## Metrics

- **Leading:** `init.sh --dry-run` output includes a Roadmap cleanup description line
  on a fresh-fork CLAUDE.md.
- **Lagging:** Zero GitHub issues or PR comments from fork users reporting that
  their Roadmap contains ecc-base-template's 21 dogfooding rows after initialization.

## Risks and open questions

- **Risk: awk section boundary.** The awk pass must identify the `## Roadmap`
  section start and end correctly. The end is defined as the next `## ` heading.
  This is the same boundary-detection pattern used for the About This Project
  block — the implementation can reuse that proven approach.
- **Risk: Roadmap section order changes.** If a future CLAUDE.md edit moves
  `## Roadmap` after another `## ` section that itself contains a table, the awk
  parser (keyed on `^## Roadmap$`) is unaffected — the heading match is explicit.
- **Open question: combined vs. sequential awk pass.** The implementer may choose
  to combine the About and Roadmap mutations into a single awk pass for
  efficiency, or keep them as sequential passes for clarity. Either is acceptable;
  the Spec does not prescribe this.
- **Open question: exact wording of placeholder row.** The AC specifies
  `| — | [Add your first milestone here] | ☐ todo | (none yet) |`. The
  implementer may adjust the wording slightly (e.g., the em-dash `—` vs.
  a literal dash `-`) as long as the `☐ todo` glyph is present and no
  `spec:` or `adr:` token appears in the design-source cell.

## Out of scope

- Cleaning up the `specs/` directory in the fork (files remain; only CLAUDE.md
  is edited).
- Cleaning up `.claude/meta/adr/` directory (historical ADR files remain).
- Automating any other section of CLAUDE.md beyond About This Project and
  Roadmap.
- Adding new CI workflows to verify that `init.sh` ran successfully.
- Handling the case where a fork completely deletes `.claude/CLAUDE.md` before
  running `init.sh` (already handled by the existing preflight check that exits
  if CLAUDE.md is absent).

## References

- Roadmap row: #15
- `init.sh` post-fork initializer: `.claude/meta/scripts/init.sh`
- Roadmap drift detector: `.claude/meta/scripts/check-roadmap-drift.sh`
- Dangling-refs detector: `.claude/meta/scripts/check-dangling-refs.sh`
- ADR-014 (Roadmap index, single entry point): `.claude/meta/adr/014-roadmap-index-single-entry-point.md`
- ADR-015 (dangling-reference detector): `.claude/meta/adr/015-dangling-reference-detector.md`
- ADR-017 (roadmap drift detector): `.claude/meta/adr/017-roadmap-drift-detector.md`
