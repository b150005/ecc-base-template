# Roadmap

This file is the Roadmap **index** — the row-by-row state of each
milestone. It is the source of truth for milestone numbering, status,
and design-source links.

The Roadmap **protocol** (write-ownership, status-glyph definitions,
the spec-reservation rule, status-transition triggers, quality-gate
loop re-entry, phase-split convention) lives below in the **Rules**
section of this file, co-located with the data it governs. A short
pointer in `.claude/CLAUDE.md` § Roadmap names this file as the
canonical Roadmap location and summarizes write-ownership.

`orchestrator` reads this file at session start, **before** the
Analyze-step row-guard (G1–G3). See
`.claude/meta/adr/014-roadmap-index-single-entry-point.md` (and its
2026-05-20 second amendment — *Roadmap relocation to
`.claude/ROADMAP.md`*) for the rationale.

## Index

| # | Milestone | Status | Design source |
|---|-----------|--------|---------------|
| 01 | Commit `verification.yml` as active default | ☑ done | spec: `specs/01-ship-verification-yml-committed.md` |
| 02 | CodeQL single-switch activation via repository variable | ☑ done | spec: `specs/02-codeql-single-switch-activation.md` |
| 03 | Cross-session milestone progress persistence | ☑ done | spec: `specs/03-cross-session-progress-persistence.md`<br>adr: `.claude/meta/adr/016-cross-session-progress-persistence.md` |
| 04 | CI detector for dangling ADR/skill cross-references | ☑ done | spec: `specs/04-dangling-reference-detector.md`<br>adr: `.claude/meta/adr/015-dangling-reference-detector.md` |
| 05 | Roadmap drift-detection CI | ☑ done | spec: `specs/05-roadmap-drift-detection-ci.md`<br>adr: `.claude/meta/adr/017-roadmap-drift-detector.md` |
| 06 | EN/JA bilingual parity detector | ☑ done | spec: `specs/06-bilingual-parity-detector.md`<br>adr: `.claude/meta/adr/018-bilingual-parity-detector.md` |
| 07 | Roadmap status-transition ownership assignment | ☑ done | spec: `specs/07-roadmap-status-transitions.md` |
| 08 | Orchestrator Analyze row-guard | ☑ done | spec: `specs/08-orchestrator-row-guard.md` |
| 09 | Spec filename convention alignment (`NN-slug.md`) | ☑ done | spec: `specs/09-spec-filename-convention.md` |
| 10 | Spec/ADR directory location pin in CLAUDE.md | ☑ done | spec: `specs/10-spec-adr-directory-pinning.md` |
| 11 | Opt-in trigger guidance for implementation/design verification domains | ☑ done | spec: `specs/11-verification-domain-opt-in-guidance.md` |
| 12 | CI coverage gate (80% hard check) | ☑ done | spec: `specs/12-coverage-ci-gate.md`<br>adr: `.claude/meta/adr/019-coverage-ci-gate.md` |
| 13 | ECC-absent degraded-review signal | ☑ done | spec: `specs/13-ecc-absent-signal.md`<br>adr: `.claude/meta/adr/020-ecc-absent-signal.md` |
| 14 | Research-tier validation for auth→T2 mis-classifications | ☑ done | spec: `specs/14-research-tier-validation.md`<br>adr: `.claude/meta/adr/021-research-tier-auth-validation.md` |
| 15 | `init.sh` Roadmap placeholder cleanup at fork time | ☑ done | spec: `specs/15-init-sh-roadmap-cleanup.md` |
| 16 | ADR-001 "Proposed (stabilized)" status resolution | ☑ done | spec: `specs/16-adr-001-status-resolution.md` |
| 17 | CHANGELOG↔ADR-acceptance sync and ADR-001–005 back-fill | ☑ done | spec: `specs/17-changelog-adr-sync.md` |
| 18 | CI exemption allowlist expiry/review mechanism | ☑ done | spec: `specs/18-ci-exemption-allowlist-expiry.md`<br>adr: `.claude/meta/adr/022-ci-exemption-expiry.md` |
| 19 | Workaround tracking default-on | ☑ done | spec: `specs/19-workaround-tracking-default-on.md`<br>adr: `.claude/meta/adr/006-upstream-workaround-tracking.md` (amended 2026-05-20) |
| 20 | Commit `compliance.yml` as active default | ☑ done | spec: `specs/20-ship-compliance-yml-committed.md`<br>adr: `.claude/meta/adr/011-compliance-checklist-skill.md` (amended 2026-05-20) |
| 21 | Quality-gate loop re-entry anchored to Roadmap row | ☑ done | spec: `specs/21-quality-gate-row-anchor.md`<br>adr: `.claude/meta/adr/014-roadmap-index-single-entry-point.md` (amended 2026-05-20) |
| 22 | CLAUDE.md invariant-only refactor + Roadmap relocation + subagent-dispatch/worktree-advisory protocols | ☑ done | spec: `specs/22-claude-md-invariant-refactor.md`<br>adr: `.claude/meta/adr/024-subagent-dispatch-contract.md`<br>adr: `.claude/meta/adr/025-worktree-advisory-protocol.md` |
| 23 | Template / fork structural separation (`main` payload-only + `develop` template-dev branch split) | ☐ todo | spec: `specs/23-template-fork-branch-separation.md` |

## Rules

- One row per milestone; row number stable, never reused (follows ADR-number convention). A split = new row + note on old row.
- `Design source` names the type explicitly: `spec:` and/or `adr:` links. `spec:` paths are reserved at row-creation even if the file does not yet exist on disk.
- Spec filename convention: a Spec file is `specs/NN-slug.md` where `NN` is the row number zero-padded to a two-digit minimum (`1→01`; rows ≥100 written without extra padding) and `slug` is the kebab-case slug already fixed in the row's reserved `spec:` path (copy it from the row, do not re-derive). The JA sibling is `specs/NN-slug.ja.md` (same `NN`/`slug`, `.ja` before `.md`); its heading-tree parity is owned by #06. `specs/NN-progress.md` is excluded — `progress` is ADR-016's reserved suffix, governed by ADR-016's lifecycle, not by this convention. #10 pins the directory; #09 pins the filename — MECE; see `## Document Templates` in `.claude/CLAUDE.md` for the pinned `specs/` and `.claude/meta/adr/` directories.
- Milestone ↔ Spec is 1:1 mandatory; Milestone → ADR is 0:1 or 1:N (only when a structural decision occurred; the ADR's `## References` back-links the row number).
- Status = implementation state: ☐ todo / ◐ in-progress / ☑ done / ✗ dropped. Dropped rows stay (history not rewritten).
- Index only — never duplicate acceptance criteria or rationale; the linked Spec/ADR is the source of truth.
- Write-ownership: `product-manager` creates/updates the row + `spec:` link; `architect` adds the `adr:` link; `orchestrator` only reads.
- Status glyph transitions: `product-manager` flips `☐→◐` atomically with authoring the Spec at pickup, and `◐→☑` after the step-6 quality gate passes (deleting `specs/NN-progress.md` in the same change per ADR-016); drops (`◐→✗`, `☑→✗`) are decided by `orchestrator` at Analyze and written by `product-manager`, row retained (history not rewritten). #05 checks glyph *value* well-formedness; #07 governs *who* flips and *when* — no CI enforces #07.
- Quality-gate loop re-entry (#21): while a row is `◐ in-progress` and one or more CRITICAL/HIGH findings from any step-6 quality-gate agent (code-reviewer, linter, security-reviewer, performance-engineer) remain open, `orchestrator` routes the fix task back to `implementer` and the row stays `◐` for the full loop duration. The `◐→☑` flip per #07 fires only after every quality-gate agent passes for that milestone — the loop's exit condition, not a mid-loop action. ADR-016 progress files apply only when the loop crosses a session or compaction boundary; an in-session loop creates no progress file. #08 G1–G3 govern initial dispatch (pre-dispatch); #21 governs re-entry after a quality-gate agent has returned findings (post-review) — non-overlapping triggers, same `orchestrator` router. No CI enforces #21 (process rule; #05 owns glyph-value well-formedness, the orthogonal check axis).
- Worktree write-safety (#22): this file mutates as status glyphs flip. In multi-worktree work, exactly one **Roadmap-owner worktree** writes to `.claude/ROADMAP.md`, `.claude/CLAUDE.md`, `CHANGELOG.md`, and `specs/NN-progress.md`. Other worktrees produce hand-off artifacts only. See `.claude/meta/references/worktree-advisory.md` for the full SAFE/UNSAFE zone list.
- Bilingual posture (#22 / ADR-014 amendment 2026-05-20 second amendment): this file is English-only. It is exempt from the #06 EN↔JA heading-tree parity contract (no `.claude/ROADMAP.ja.md` sibling shipped). <!-- ref-allow: .claude/ROADMAP.ja.md is intentionally not created (English-only posture) — counterfactual reference --> The bilingual-parity detector (`.claude/meta/scripts/check-bilingual-parity.sh`) is per-pair-keyed and auto-excludes a file with no `.ja.md` counterpart, so the exemption is structural — no allowlist entry needed.
- At 100+ milestones, split into `### Phase N` sub-tables under `## Index`.
