# Changelog — ecc-base-template (template itself)

All notable changes to **the template** are recorded here. This file is for
maintainers of the template, not for derived projects. Derived projects have
their own `/CHANGELOG.md` at the repo root.

Full history prior to v3.0.0 lives in [`CHANGELOG.legacy.md`](CHANGELOG.legacy.md).

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Removed

- **`.devcontainer/devcontainer.json` scaffold** (2026-05-21, ADR-028).
  The fully-commented-out Dev Containers scaffold introduced in v3.0.0
  (commit `c25140d`, ADR-less) is removed from both `main` and
  `develop`. The file's only live keys were `"name"` and `"remoteUser"`;
  every meaningful key (`image`, `features`, extensions, lifecycle
  commands, ports, environment) was commented out, and its header
  comment pointed at `.claude/meta/references/devcontainer.md` which
  did not exist on either branch. The "fork-reusable scaffold"
  rationale recorded in the payload manifest was hypothetical: a fork
  that genuinely adopts Dev Containers picks a base image and writes
  ~10 lines anyway, so the empty scaffold added nothing beyond what
  one README sentence covers. Removing it eliminates 4 downstream
  surfaces (README.md tree row, README.ja.md tree row, init.sh
  next-step 4, `payload-manifest.txt` section). See ADR-028 for the
  full reasoning and the four alternatives considered.

### Changed

- **Integrated `.gitignore.example` into `.gitignore` as a comment block**
  (2026-05-21, ADR-027). The Learning Mode opt-in inversion pattern now
  lives as a commented-out block inside `.gitignore` itself; the separate
  `.gitignore.example` file is deleted. Rationale: the `.example` suffix
  misled fork operators into reading it as "a sample `.gitignore` to copy
  wholesale" rather than "documentation of an opt-in inversion to splice
  into your existing `.gitignore`." Consolidating the posture into one
  file cuts the synchronization debt (20+ references → ~5) and improves
  discoverability — anyone editing `.gitignore` sees the opt-in path
  immediately. The design intent of ADR-001 Decision 4 (knowledge files
  gitignored by default; opt-in is the only allowed sharing mechanism)
  is preserved; only the documentation mechanism changes. Related
  amendments added to ADR-001, ADR-003, ADR-005, PRD developer-learning-
  mode, references (domain-taxonomy / learning-mode-explained EN+JA /
  v1-to-v2 migration EN+JA), and `.claude/skills/learn/SKILL.md`. The
  `check-learn-invariants.sh` Check 3 logic and `learn-invariants.yml`
  triggers updated to the new shape; Check 3 still passes (13 PASS / 0
  FAIL). The manifest entry for `.gitignore.example` remains in
  `payload-manifest.txt` during the payload PR (so the deletion passes
  the manifest gate) and is removed in a separate develop-only cleanup
  commit after the payload PR merges — sequencing detailed in ADR-027.

### Fixed

- **`main:.claude/settings.json` dead hook reference** (2026-05-21,
  ADR-028 Consequences). Commit `b9256c7`
  (`refactor(template): remove develop-only skills, hooks, output-styles
  from main (Roadmap #23)`) deleted `.claude/hooks/coaching-context.sh`
  from `main` as part of AC-2 cleanup but did not update
  `settings.json`'s `hooks.UserPromptSubmit` block, which still
  registered the now-missing hook. Fork users starting Claude Code saw
  a hook-resolution warning on the first user prompt of every session.
  The block is removed; `"hooks": {}` is left in place as a documented
  extension point. `develop`'s `settings.json` is intentionally
  untouched — the hook is functional on `develop` because
  `coaching-context.sh` is present there (maintainer-facing Learning
  Mode coaching depends on it). The `main`/`develop` divergence in
  `settings.json` is now load-bearing (ADR-026 amendment 2026-05-21
  precedent: `main` and `develop` settings legitimately differ).
- **Realigned root `/CHANGELOG.md` with ADR-005** (2026-05-21). The root
  `CHANGELOG.md` had drifted from its design intent: while ADR-005 and this
  file's own header explicitly designate the root file as "for derived
  projects, starting from `[Unreleased]`," the root file had accumulated
  1728 lines of template-internal history (Milestones #11 through #23,
  verification-layer work, payload-manifest follow-ups). This remediation
  relocates all template-internal history from the root file to this one
  (preserving Keep a Changelog version sections), and resets the root to a
  12-line Keep a Changelog stub that satisfies `init.sh`'s
  `changelog_is_pristine` predicate. Forks see a clean `[Unreleased]`
  starting point; the template's own history lives here as designed.
- **`payload-manifest-check.yml` — fork cognitive tax** (2026-05-21,
  ADR-026 third amendment). The second-amendment graceful-skip preserved
  correctness but not invisibility: forks still saw a "Payload Manifest
  Check" entry in Actions on every PR, paid runner-startup cost, and paid
  cognitive tax for an opaque workflow they did not opt into. Defense in
  depth via two orthogonal layers: (1) job-level
  `if: github.repository == 'b150005/ecc-base-template'` guard so the job
  evaluates to `skipped` on any non-upstream repository (0 runner minutes,
  no Actions-tab noise beyond the skip marker); (2)
  `.claude/meta/scripts/init.sh` prompt offering physical removal of the
  workflow file (kept by default; `--non-interactive` and `--dry-run`
  honored). Spec `specs/23` AC-6 verification refined to include the
  fork-context check.

- **Milestone #23 follow-up — `payload-manifest-check` architecture +
  `**` glob bug** (2026-05-21, post-ship). Two issues discovered during
  AC-6/AC-12 verification:
  - **Workflow location**: GitHub Actions resolves `pull_request` workflow
    files from the PR head ref, not base ref. A workflow living only on
    `develop` never triggered for main-derived feature branches, making
    the required `payload-manifest-check` status unsatisfiable and blocking
    all PRs to `main` indefinitely. **Fix**: workflow now ships on both
    `main` and `develop` with a dual-checkout pattern that fetches the
    manifest from `develop` at runtime and gracefully skips (SUCCESS) when
    `develop` is absent (so forks are unaffected). The single permitted
    workflow on `main` is documented in payload-manifest as an explicit
    payload path. PR #11 (merge `d287480`) shipped the workflow to `main`.
  - **`**` recursive glob**: the original sed pipeline treated `**` as `*`
    (single-segment), breaking nested paths like `.claude/agents/nested/foo.md`.
    **Fix**: placeholder-protect pattern (`**` → marker → single-`*`
    substitution → restore marker as `.*`); unit-tested with 20 paths
    covering nested cases.
  - **End-to-end verified**: positive test (PR #11) → SUCCESS in 6 sec;
    negative test (PR #12, `specs/test-manifest-negative.md`) → FAILURE
    in 6 sec with the offending path named.
  - Spec `specs/23-template-fork-branch-separation.md` + ADR-026 carry
    "Amendment 2026-05-21 (second)" documenting the discovery and fix.

### Added

- **Milestone #23 — SHIPPED: Template / fork structural separation — `main`
  payload-only + `develop` template-dev branch split** (Phase B implementation
  complete 2026-05-21; all 12 AC of Spec `specs/23-template-fork-branch-separation.md`
  satisfied locally; AC-12 branch-protection requires user GitHub UI action).
  Nine commits across `develop` and `main` branches:
  - **Two-branch model adopted**: `main` carries only fork-facing payload;
    `develop` is the template-development branch (Spec, ADRs, CI, skills, etc.).
  - **`main` purged of template-internal artifacts**: 12 workflows, 5 trackers,
    meta-scripts (`init.sh` kept), `specs/`, `meta/{adr,prd,references}/`,
    `ROADMAP.md`, opt-in yml configs (`.claude/{skills,hooks,output-styles}/`).
    A `.gitkeep` placeholder marks the empty `.github/workflows/` directory;
    fork CI is opt-in, zero workflows by default.
  - **Payload manifest** (`develop`): `.claude/payload-manifest.txt` lists every
    path that should be present on `main`; `payload-manifest-check.yml` CI gate
    enforces the allowlist on PRs targeting `main`.
  - **Reduced `CLAUDE.md` + `orchestrator.md`** on `main`: fork-compatible
    stubs only; template-internal references removed.
  - **`README.md` rewritten** on `main`: Forking, CI, and Contributing-to-template
    sections added; fork audience oriented.
  - **`init.sh` shrunk** on `main`: reduced from 303 to 231 lines (-72 / -24%)
    by removing `clean_roadmap_section()` and related awk machinery;
    `bash` syntax check passes, no `.claude/meta/` or `specs/` path
    references remain.
  - **Spec `specs/23-template-fork-branch-separation.md` + ADR-026 amended
    2026-05-21** for leaner-main scope (Phase B scope shift documented).
  - Restore point: local tag `pre-phase-b` pinned to `9d2b00d` (Phase A ship).
  - Reference: ADR-026 (`.claude/meta/adr/026-template-fork-branch-separation.md`).
  (Roadmap #23)

- **Milestone #23 — ACTIVATED (Spec authored, ADR-026 accepted; implementation
  deferred to follow-up session)** (Agent Team consultation on 2026-05-21
  producing one new ADR at triad 3/3 and a Spec with 12 acceptance criteria;
  branch-cutover and main-side artifact purge are out of scope for this
  activation). Three artifacts:
  (1) **Spec `specs/23-template-fork-branch-separation.md`** (and `.ja.md`
  sibling preserving EN ↔ JA heading-tree parity per #06) — Approved. Twelve AC
  covering branch creation order (AC-1: `develop` branched from the
  `pre-phase-b`-tagged SHA), deletion completeness on `main` (AC-2:
  template-internal artifacts purged; AC-4: workflow inventory partitioned —
  4 fork-reusable workflows kept on `main`, 8 template-internal workflows
  develop-only, 1 new `payload-manifest-check.yml` on develop targeting
  main-bound PRs), payload-manifest mechanism (AC-3, AC-6), `init.sh` shrink
  target ≤ 30 lines (AC-5), fork-facing `README.md` rewrite (AC-7), GitHub
  "Use this template" default-branch behavior (AC-9), restore path via the
  `pre-phase-b` tag (AC-10), and bilingual-parity check continuity on `develop`
  (AC-11). Each AC is independently verifiable with a git or file command.
  Forward references to `.claude/payload-manifest.txt` are suppressed via
  `<!-- ref-allow: ... forward reference -->` markers (created during Phase B
  implementation, not yet on disk).
  (2) **ADR-026** (`Accepted — 2026-05-21`) — template/fork branch separation
  strategy; triad 3/3 per ADR-018 Alternative-B discriminator (new contract
  boundary: `main` = fork-clean payload / `develop` = template-development +
  new keying mechanism: `.claude/payload-manifest.txt` allowlist enforced by a
  CI gate + new structural artifact: long-lived `develop` branch plus the
  `payload-manifest-check.yml` workflow). Cites ADR-014 (Roadmap index
  residency) and ADR-018 (parity detector) for precedent; cites
  `docs.github.com` template-repo and branch-protection pages as primary
  source for `Use this template` default-branch semantics. JA sibling
  preserves EN ↔ JA heading-tree parity (#06). Back-links Roadmap row #23.
  (3) **`.claude/ROADMAP.md` row #23** — status flipped `☐ todo → ◐ in-progress`;
  `adr:` cell appended with the ADR-026 link. Local-only restore tag
  `pre-phase-b` created on commit `9d2b00d` (the Phase A ship commit) before
  this activation so Phase B's destructive operations (branch cutover,
  main-side artifact purge, `init.sh` shrink, README rewrite,
  `payload-manifest-check.yml` authoring) have a known-good restore target.

  **Why ADR-026 (not an ADR-014 amendment).** ADR-014 keys *Roadmap index
  location*; the new decision keys *branch-scoped file-tree membership* — an
  orthogonal contract. All three triad axes pass independently (new
  boundary, new keying, new artifact), so a new ADR is the correct vehicle,
  matching the convention used for ADR-024 and ADR-025 in Milestone #22.

  **Phase B implementation deferred.** This activation only ships the Spec
  and the ADR. The branch creation, file deletions, `init.sh` shrink,
  `README.md` rewrite, and `payload-manifest-check.yml` workflow are deferred
  to a follow-up session. The Roadmap row stays `◐ in-progress` until
  step-6 quality-gate pass per #07/#21; on pass it flips `◐ → ☑`.

- **Milestone #22 — CLAUDE.md invariant-only refactor + Roadmap relocation +
  subagent-dispatch / worktree-advisory protocols** (single session; Agent Team
  consultation on 2026-05-20 producing two new ADRs each at triad 3/3 and one
  ADR-014 amendment at triad 1.5/3). Eleven artifacts:
  (1) **`.claude/ROADMAP.md`** — new file holding the Roadmap *index* (21
  historical rows + new rows #22 ☑ done and #23 ☐ todo) plus the Rules block
  co-located with the data it governs. English-only by design (#06 bilingual-
  parity contract exempt; per-pair keying auto-excludes).
  (2) **`.claude/CLAUDE.md`** — trimmed to invariant-only content. `## Roadmap`
  section reduced to a 1-paragraph pointer + write-ownership summary; the 21-row
  table and Rules block removed (now in ROADMAP.md). Two new sections added:
  `## Subagent dispatch contract` (5-slot prompt template + delegate-and-stop
  rule, ≤ 30 lines) and `## Worktree advisory protocol` (6-question rubric +
  Roadmap-owner-worktree designation + SAFE/UNSAFE write-zone summary, ≤ 25
  lines). The 2026-05-16 line-budget exception paragraph is removed from
  `## CLAUDE.md authoring guidance` (its premise no longer holds — see ADR-014
  second 2026-05-20 amendment).
  (3) **`.claude/meta/references/dispatch-contract.md`** — new canonical
  reference. 5-slot template, MUST/MAY/MUST NOT information-density rules,
  delegate-and-stop tool restrictions, pre-dispatch checklist (4 questions),
  worked 614→174-word before/after example.
  (4) **`.claude/meta/references/worktree-advisory.md`** — new canonical
  reference. 6-question suitability rubric (file-disjoint / Roadmap-disjoint /
  state-disjoint / mergeable / reversible / net-faster), advisory output
  template with two worked examples, per-worktree shared-header + slice-block
  dispatch format, Roadmap-owner-worktree designation rule, full SAFE / UNSAFE
  write-zone list.
  (5) **ADR-024** (`Accepted — 2026-05-20`) — subagent dispatch contract;
  triad 3/3 (new contract boundary + new keying/mechanism + new structural
  artifact); back-links Roadmap row #22.
  (6) **ADR-025** (`Accepted — 2026-05-20`) — worktree advisory protocol;
  triad 3/3; back-links Roadmap row #22. (ADR-023 is reserved as the
  deliberately-rejected counter-proposal per ADR-014's first 2026-05-20
  amendment; the new ADRs skip to 024 and 025.)
  (7) **ADR-014 second 2026-05-20 amendment** — "Roadmap relocation to
  `.claude/ROADMAP.md`; line-budget exception withdrawn"; triad 1.5/3
  (refinement of an existing boundary + new file artifact) → amendment, not
  new ADR. Documents the Invariant 2 trade-off, the English-only bilingual
  posture, and the CI check script updates. ADR-014 JA sibling receives the
  corresponding amendment preserving EN ↔ JA heading-tree parity (#06).
  (8) **`.claude/skills/claude-md-authoring/invariants.md` Invariant 2 Note**
  — 2026-05-20 Note documenting the trade-off: the Invariant 2 *statement*
  is unchanged; what changes is which content is governed by it.
  `.claude/ROADMAP.md` is **not** Invariant-2-protected; the compensating
  mechanism is the orchestrator's explicit Read at session start.
  (9) **`.claude/agents/orchestrator.md`** — Analyze step now reads
  `.claude/ROADMAP.md` (not CLAUDE.md `## Roadmap`); a mandatory
  `## Worktree Recommendation` block fires after G1–G3 and before any
  dispatch; a new `## Subagent dispatch contract` subsection summarizes both
  layers (5-slot template + delegate-and-stop) inline.
  (10) **CI check scripts updated**:
  `.claude/meta/scripts/check-roadmap-drift.sh` parses `.claude/ROADMAP.md`
  (variable renamed `CLAUDE_MD` → `ROADMAP_MD`, section guard removed);
  `.claude/meta/scripts/check-dangling-refs.sh` adds `.claude/ROADMAP.md` to
  Check 1 and Check 2 scan sets;
  `.claude/meta/scripts/check-bilingual-parity.sh` requires no change
  (per-pair keying auto-excludes EN-only files).
  (11) Spec **`specs/22-claude-md-invariant-refactor.md`** (Approved) — twelve
  acceptance criteria covering ROADMAP.md content, CLAUDE.md trim, new
  references, two new ADRs, ADR-014 amendment, invariants.md note,
  orchestrator update, and CI script updates.

  **Why two new ADRs and one amendment.** Both ADR-024 and ADR-025 score
  triad 3/3 on ADR-018 Alternative-B's discriminator (new contract boundary +
  new keying/mechanism + new structural artifact) and correctly are new ADRs.
  The Roadmap relocation scores 1.5/3 (a refinement of ADR-014's existing
  entry-point decision plus one new file) and correctly is an ADR-014
  amendment, following the ECC convention recorded in the eight prior ADR-014
  amendments.

  **Roadmap row #23 (Phase B placeholder).** `☐ todo` row added for the
  template / fork structural separation work (`main` payload-only + `develop`
  template-dev branch split). Spec reserved at
  `specs/23-template-fork-branch-separation.md`, file not yet authored on
  disk per ADR-014 reservation rule. Will be picked up in a future session.

- **Milestone #18 — now IMPLEMENTED** (single session; **ADR-022** — the
  ADR-018 Alternative-B triad scored 3/3: new contract boundary [AC-10 (c)
  technical-writer step-7 review responsibility], new keying/mechanism
  [extended ref-allow syntax `<!-- ref-allow: <reason> | expires: YYYY-MM-DD -->`],
  new structural artifact [a sixth detector + shared library forming a new MECE
  partition in the ref-allow family]). Six artifacts: (1)
  **`.claude/meta/scripts/check-ref-allow-expiry.sh`** — the sixth detector,
  scanning the union of the five ref-allow consumers' scopes (CLAUDE.md,
  `specs/`, `.claude/meta/adr/`, `.claude/agents/`) for expired markers and
  emitting WARN-not-FAIL diagnostics; (2)
  **`.claude/meta/scripts/lib/ref-allow-expiry.sh`** — shared library providing
  `parse_ref_allow_expiry`, `check_ref_allow_expiry`, and
  `parse_and_warn_ref_allow` functions, sourced by the sixth detector; (3)
  **`.claude/meta/scripts/test-check-ref-allow-expiry.sh`** — 27-test suite
  covering AC-1 through AC-13 (ISO 8601 format enforcement, extended syntax
  parsing, WARN-not-FAIL on past dates, future/today silence, grandfather
  behavior, scope coverage across CLAUDE.md / `specs/` / `adr/` / `agents/`,
  progress-md exclusion, repo-wide grandfather verification, existing
  seven-suite regression check); (4) **ADR-022** (`Accepted — 2026-05-20`) —
  records the syntax decision, the WARN-not-FAIL semantic, the three-tier
  review-cadence ownership, and the new-ADR-vs-amendment discriminator
  rationale; (5) Spec `specs/18-ci-exemption-allowlist-expiry.md` (Approved)
  — thirteen acceptance criteria; (6) AC-10 review-cadence ownership snippet
  added to `.claude/CLAUDE.md` to satisfy the AC-10 documentation requirement.

  **Implementation-shape note (AC-12):** The implementer chose option (c) — a
  separate sixth detector — over option (a)/(b) (per-detector amendment or
  shared library sourced by the five existing detectors) because AC-7
  hard-requires that "all existing tests pass without modification" and the
  scope-bleed guards in `test-check-ecc-delegation-consistency.sh`,
  `test-check-research-tier-auth.sh`, and `test-coverage-threshold.sh`
  byte-compare the five ref-allow-consuming detectors against earlier
  milestones' design commits. A per-detector amendment would fail those guards;
  the sixth-detector shape preserves the existing five detectors byte-for-byte
  while delivering identical observable behavior (AC-6 union scope).

  **Grandfather corpus (AC-13):** 372 existing `<!-- ref-allow:` markers across
  template artifact scope (CLAUDE.md + `specs/` + `.claude/meta/adr/` +
  `.claude/agents/`) are grandfathered unconditionally and permanently. No
  marker produces a new WARN or FAIL at ship time. The grandfather rule is not
  time-limited per AC-8.

  Bilingual `.md` and `.ja.md` (ADR-022 EN/JA both landed this session; Spec
  JA sibling `specs/18-ci-exemption-allowlist-expiry.ja.md` also lands this
  session per Roadmap #06 ownership).

- **Compliance config** (`.claude/compliance.yml`): committed to template
  baseline for the first time (Roadmap #20 / ADR-011 amendment 2026-05-20).
  Architect applied the ADR-018 Alternative-B triad and scored Path B (ADR-011
  amendment, not a new ADR-023) — new contract boundary (committed vs. absent
  file), same keying/mechanism (single `enabled` toggle), no new structural
  artifact beyond the committed file itself. File ships with `enabled: false`
  and `target_jurisdictions: []`; inline comments document the operator-assertion
  requirement and explain that the Skill refuses to run on an empty list
  (Invariant 5 preserved at the config layer). `.claude/compliance.yml.example`
  retained unchanged as fully-annotated documentation reference (AC-4).
  `SKILL.md` is byte-for-byte unchanged (AC-6). Existing forks that forked
  before #20 and have no `.claude/compliance.yml` on disk are not auto-migrated;
  they adopt by pulling this upstream change or by
  `cp .claude/compliance.yml.example .claude/compliance.yml`. Spec
  `specs/20-ship-compliance-yml-committed.md` (Approved, 11 AC) and JA sibling
  `specs/20-ship-compliance-yml-committed.ja.md` land this session per Roadmap
  #06 ownership.

### Changed

- **Workaround tracking** (`.github/workaround-tracker.yml`): default `enabled` value flipped from `false` to `true` (Roadmap #19 / ADR-006 amendment 2026-05-20). The `marker-consistency` job now runs on every PR by default; `expiry-warning` runs on schedule/dispatch. `annotate_dependabot_prs` and `fail_on_marker_drift` remain `false` by default (conservative opt-in overlays). Existing forks with `enabled: false` explicitly committed continue to override the new template default; only new forks and forks that pull this change inherit `enabled: true`.

- **Quality-gate loop re-entry** (`.claude/CLAUDE.md` `## Roadmap` Rules block):
  one bullet added formalizing the unnamed "loop owner" interim practice exercised across
  all prior milestones (Roadmap #21 / ADR-014 amended 2026-05-20). Triad 0/3 (no new
  contract boundary, no new keying/mechanism, no new structural artifact) ⇒ ADR-014
  amendment, not a new ADR-023. The bullet names `orchestrator` as the routing owner when
  a step-6 quality-gate agent (code-reviewer, linter, security-reviewer,
  performance-engineer) returns CRITICAL or HIGH findings, states the row-anchor invariant
  (the `◐ in-progress` row stays `◐` for the full loop duration; `◐→☑` fires only after
  every gate agent passes), and restates the MECE boundaries against ADR-016 progress files
  (cross-session boundary, not in-session loop) and #08 G1–G3 (pre-dispatch, not
  post-review). No agent prompts edited; no CI detector added (AC-7 bounds canonical
  detectors at seven; AC-8 bounds canonical test suites at eight). JA mirror of
  ADR-014 amendment and Spec sibling `specs/21-quality-gate-row-anchor.ja.md` landed
  this session per Roadmap #06 ownership.

### Documentation

- **Milestone #14 — design only; implementation deferred.**
  Spec `specs/14-research-tier-validation.md` (Approved) closes the
  gap where the auth→T1 requirement exists only as a descriptive
  Tier-table row in `research/protocol.md` and as the orchestrator's
  runtime keyword scan — neither expressing the rule as a testable,
  independently-checkable written contract separate from the
  orchestrator's runtime judgement. A Generator output whose topic
  description says "login flow" or "session management" (auth content,
  no "auth" keyword) can declare T2 and silently reach the Critic at
  T2 without the orchestrator guardrail firing; neither `protocol.md`
  nor `verification.yml` states the auth→T1 rule as a contract
  independently checkable against the artifact. ADR-021
  (`Research-tier auth→T1 validation — a new default-off detector
  validating auth-touching verification-review artifacts against the
  protocol.md T1 scope, contract co-located with the Tier table, new
  MECE partition not pre-reserved by ADR-014 §(d)`, status
  `Proposed — 2026-05-18`) records the structural decisions. The
  ADR-018 Alternative-B discriminator triad was applied
  clause-by-clause and scored **3/3** (new default-off content-keyed
  detector + new MECE partition NOT pre-reserved by ADR-014 §(d),
  which names #04/#05/#07/#08 and its lineage extends to
  #09/#10/#11/#12/#13 but does not include #14 + new keying:
  auth-keyword presence in a verification-review artifact's content
  versus the Tier declared on that same artifact, deliberately
  scanning the body to catch the topic-description-omission the
  orchestrator's topic-line scan misses) → a **new ADR-021**, not an
  ADR-008 amendment — the #04/#05/#06/#12/#13 precedent
  (ADR-015/ADR-017/ADR-018/ADR-019/ADR-020), the opposite call from
  #11 (which took an ADR-014 amendment precisely because it populated
  a pre-reserved §(d) slot; #14 has none, exactly as #12/#13 had
  none). Key ADR-021 resolutions: (1) **mechanism** = (c) + (d) —
  a new prose subsection in `protocol.md` immediately below the Tier
  table stating the auth→T1 obligation as a mandatory rule
  (independently readable without `orchestrator.md`), referencing the
  existing T1 scope line by pointer rather than reproducing it (R-04
  single-source binding, the ADR-019 §3 "reference don't re-declare"
  discipline applied to the T1 scope line), PLUS a new default-off
  `check-research-tier-auth.sh` detector that audits
  verification-review artifact *bodies* (not topic lines) for
  auth-scope keyword presence at T2/T3, catching the
  topic-description-omission the orchestrator guardrail misses; (a)
  (elevate the Tier-table line to a machine-readable rule) and (b)
  (new agent-prompt constraint) rejected with reasons; (2) **no
  operator-environment introspection** — the detector reads only
  repository artifacts and runtime-derives its auth-scope keyword set
  from `protocol.md`'s T1 scope line, so the template CI is
  deterministic and AC-8 is satisfied by construction; (3)
  **template-CI-green for the expected no-verification-review-artifact
  case** = default-off single-switch (the
  `workaround-check.yml`/`coverage-gate.yml`/
  `ecc-delegation-consistency-check.yml` precedent; the template's own
  CI is green-by-construction without any special case); (4)
  **contract placement** = co-located under the Tier table in
  `protocol.md` so a future T1-scope amendment tracks with zero second
  edit — closing R-04 by single-source reference; (5) **MECE
  boundary** = #14 owns "Is a research-verification output with
  auth-touching content declared at T1, as an independently-checkable
  written contract?", a seventh partition distinct from
  #04/#05/#06/#12/#13, stated in ADR-021 §3. The serious
  Counter-proposal (Alternative E — documentation/convention statement
  only, no detector, mirroring #11's prose-only collapse) is recorded
  seriously: #11 was correctly prose-only because it had no detectable
  failure mode (adoption guidance) and populated a pre-reserved §(d)
  slot; #14 has a concrete detectable failure mode (auth content +
  declared T2/T3) and no reserved slot, so the same discrimination
  that made #11 prose-only makes #14 detector-required. Implementation
  (the detector script, its forkable default-off workflow, the
  activation config, the `protocol.md` subsection, and the dedicated
  test suite) is deferred to a subsequent session as a
  `feat(roadmap):` commit; the architect transitions ADR-021
  `Proposed → Accepted` and reconciles the present-tense
  "not yet implemented" self-narrative to past-tense at that point
  (the ADR-017/ADR-019/ADR-020 two-session lifecycle). Roadmap row
  #14 flipped `☐ todo → ◐ in-progress` with the `adr:` link added
  (the CLAUDE.md diff is the single row line only, Invariant 2
  preserved).

- **Milestone #13 — design only; implementation deferred.**
  Spec `specs/13-ecc-absent-signal.md` (Approved) closes the gap
  where ADR-012's Negative recorded "no CI check on the existence
  of the target [ECC] agents" and "the dispatcher's delegation
  rows go stale silently" as costs left unmitigated, with the
  only ECC-absent signals being `code-reviewer.md`'s per-review
  verdict line (fires only when a review runs) and a `README.md`
  `## Prerequisites` paragraph (surfaced at no agent/CI
  checkpoint). ADR-020 (`ECC-absent degraded-review signal`,
  status `Proposed — 2026-05-18`) records the structural
  decisions. The ADR-018 Alternative-B discriminator triad was
  applied clause-by-clause and scored **3/3** (new default-off
  detector + new MECE partition NOT pre-reserved by ADR-014 §(d),
  which names #04/#05/#09/#10/#11 and is amended for #12 but does
  not include #13 + new keying: intra-prompt delegation-table
  consistency with zero operator-environment introspection) → a
  **new ADR-020**, not an ADR-012 amendment — the #04/#05/#06/#12
  precedent (ADR-015/ADR-017/ADR-018/ADR-019), the opposite call
  from #11 (which took an ADR-014 amendment precisely because it
  populated a pre-reserved §(d) slot; #13 has none, exactly as
  #12 had none). Key ADR-020 resolutions: (1) **mechanism** = a
  new default-off detector script + forkable workflow validating
  `code-reviewer.md`'s nine-row ECC delegation table for internal
  consistency (the `check-*.sh` family shape #04 established,
  #05/#06/#12 reused); (2) **no operator-environment
  introspection** — the detector reads only repository artifacts,
  never probes `~/.claude/` for live ECC presence (impossible
  from a repo/CI by construction; forbidden by `code-reviewer.md`
  lines 84–87), so it checks *internal consistency*, not *live
  presence*; (3) **template-CI-green for the expected ECC-absent
  case** = because the check is repository-internal, it passes on
  the template's own `main` with no special-casing (the
  #12/ADR-019 green-by-construction precedent applied to a
  consistency detector); (4) **standing-posture placement** =
  co-located with the artifact the relevant checkpoint already
  consults, no new always-read file, complementing — not
  restating — the per-review three-case rule; (5) **MECE
  boundary** = #13 owns "is `code-reviewer.md`'s ECC delegation
  table internally consistent, and is the standing degraded-review
  posture discoverable?", a sixth partition distinct from
  #04/#05/#06/#11/#12, stated in ADR-020 §2 (the twice-applied
  #12/ADR-019 not-pre-reserved-by-§(d) pattern). The rejected
  Counter-proposal (Alternative C — prose-only, #11-style) is
  recorded seriously: #11 was correctly prose-only because it had
  no detectable failure mode (adoption guidance); #13 has a
  concrete one (a drifted delegation-table row, the exact "rows
  go stale silently" failure ADR-012 named), which a prose
  paragraph cannot catch. Implementation (the detector script,
  its workflow, its dedicated test suite — a fifth separated-run
  suite) is deferred to a subsequent session as a `feat(roadmap):`
  commit; the architect transitions ADR-020 `Proposed → Accepted`
  and reconciles the present-tense "not yet implemented"
  self-narrative to past-tense at that point (the ADR-017/ADR-019
  two-session lifecycle). EN/JA ADR-020 shipped this session with
  17 headings, identical level sequence, full-width parens
  ASCII-normalized per the ADR-019.ja house-style. Roadmap row
  #13 flipped `☐ todo → ◐ in-progress` with the `adr:` link
  added (the CLAUDE.md diff is the single row line only,
  Invariant 2 preserved).

- ADR-014 (`Roadmap Index as the Single Entry Point for
  Design Artifacts`, status `Accepted`) adds a `## Roadmap`
  index table to `.claude/CLAUDE.md`, placed immediately
  before `## Development Workflow`. Each row maps one
  milestone 1:1 to its authoritative Spec (`spec:` link,
  mandatory) and 0:1 or 1:N to ADRs (`adr:` link, only
  when a structural decision occurred). The table is an
  index only — acceptance criteria and rationale are never
  duplicated; the linked Spec/ADR remains the source of
  truth. Write-ownership is role-separated: `product-manager`
  creates/updates the row and `spec:` link; `architect` adds
  the `adr:` link; `orchestrator` only reads. Four agent
  prompts (`orchestrator`, `architect`, `implementer`,
  `product-manager`) and the spec/adr templates were amended.
  A new `.claude/templates/roadmap-section.md`
  (+ `.ja.md`) paste-in fragment ships with this release.
  The counter-proposal to collapse to one document type
  (Alternative A) was raised and rejected during user
  dialogue because it breaks the `implementer`/`architect`
  reference contracts; it is permanently recorded in the
  ADR per ADR-012 precedent. Bilingual `.md` and `.ja.md`.
- ADR-014 gains two amendments (2026-05-16). (1) **Spec
  reservation rule**: every Roadmap row carries a `spec:`
  link at row-creation time using the deterministic path
  `specs/NN-slug.md`; the Spec *file* is authored by
  `product-manager` only when the milestone is picked up
  (status moves to `◐ in-progress`). This satisfies the
  original 1:1 mandatory mapping without requiring all Spec
  files to exist upfront; the `implementer`/`test-runner`
  contract fires only after the file is authored, so no
  window exists where `implementer` resolves the pointer
  and finds nothing. (2) **CLAUDE.md line-budget sanctioned
  exception**: the `## Roadmap` section is exempt from the
  ~200-line CLAUDE.md guidance because it must survive
  compaction per Invariant 2 and cannot be relocated to a
  subdirectory `CLAUDE.md` or a Skill without defeating its
  purpose as the single always-read entry point. The "around
  200" rule is a volatile guideline, explicitly never a hard
  CI failure (SKILL.md §"Volatile rules"); it yields to the
  Roadmap by design. Budget is reclaimed by compressing
  Roadmap row text (index-only) and trimming genuinely
  relocatable sections elsewhere — not by moving the Roadmap.
  Bilingual `.md` and `.ja.md`.
- ADR-015 (`Dangling-Reference Detector — always-on,
  subject-matter-keyed CI posture`, status `Accepted —
  2026-05-16`) records the structural decisions for
  milestone #04: the always-on CI posture (vs. default-off)
  decided by the subject-matter-presence rule ("a check is
  always-on when its subject matter is present in every fork
  from day one; default-off when absent until the adopter
  opts in"); the MECE scope boundary against
  `check-skill-invariants.sh` Check 4 (Check 4 owns relative-
  path links inside `SKILL.md` files; the new detector owns
  `ADR-NNN` textual references and `.claude/`-rooted path
  mentions in `CLAUDE.md`, ADRs, Specs, and agent files —
  a link is validated by exactly one check, never both); the
  ADR-014 reservation-rule carve-out as a hard constraint
  (`spec: specs/NN-slug.md` links in the Roadmap `Design
  source` column are valid-by-design even when the file
  does not yet exist on disk); and the pattern reuse
  rule (#05 Roadmap drift CI and #06 bilingual parity CI
  inherit the always-on posture by the same rule). The
  subject-matter-presence rule is stated once here so #05
  and #06 inherit a decided posture rather than re-arguing
  it. The serious counter-position (Alternative A —
  default-off / single-switch, consistent with ADR-006) is
  permanently recorded in the ADR per ADR-012 precedent,
  with real pros and explicit re-evaluation triggers.
  ADR-015 also carries a 2026-05-16 amendment adding two
  carve-outs surfaced during the #04 quality gate: (1)
  **Class A literal-`N` placeholder skip** — `specs/NN-slug.md`
  and `ADR-NNN` with literal `N` numeric slots are
  metasyntactic documentation placeholders, categorically
  identical to the existing glob/template-token skip, and
  are not failed; (2) **Class B opt-in/default-off config
  WARN-not-FAIL** — references to intentionally-absent
  `.claude/`-rooted `.json`/`.yml`/`.yaml` config files
  are WARN (not FAIL) when a co-located opt-in signal is
  present (a sibling `<path>.example` exists on disk, or
  the referencing-line paragraph carries an `absent`,
  `default-off`, or `opt-in` vocabulary token); a bare
  absent config path without co-located signal remains FAIL.
  The line-level `<!-- ref-allow: -->` escape hatch absorbs
  genuinely forward-looking references per-line without
  disabling the check. Bilingual `.md` and `.ja.md`.
- **Milestone #03 — design only; implementation deferred.**
  Spec `specs/03-cross-session-progress-persistence.md`
  (Approved) defines cross-session per-milestone in-progress
  persistence: a `◐` milestone is resumable across a
  session or compaction boundary without violating ADR-014's
  index-only Roadmap contract. ADR-016 (`Cross-session
  milestone progress persistence — repo-local, row-keyed,
  boundary-triggered`, status `Accepted — 2026-05-16`)
  records four structural decisions: (1) **Storage location
  and path convention** — a single repo-local Markdown file
  at the deterministic path `specs/NN-progress.md`, keyed to
  the stable, never-reused Roadmap row number; on disk and
  git-tracked, so compaction-durable without operator action
  (Invariant 2); outside the Roadmap table (ADR-014); within
  the already-scoped `specs/` tree (no detector change). (2)
  **Trigger model** — boundary-triggered (created/updated
  only when a session or compaction boundary occurs during a
  `◐` milestone, decided by the inherited subject-matter-
  presence rule from ADR-015; never on the ☐→◐ transition
  and never by operator command). (3) **Staleness recognition**
  — layered: glyph mirror (`status_glyph` must equal the
  Roadmap row glyph; mismatch ⇒ stale by definition), `head_sha`
  pin (enables bounded delta reconciliation via
  `git log <sha>..HEAD`), and `last_updated` date (coarse
  secondary signal). (4) **Retirement on ◐ → ☑** — the agent
  that flips the glyph deletes `specs/NN-progress.md` in the
  same change; deletion not archival (retained record
  misleads per Spec R-03; git history recovers if needed).
  The record runs alongside (not replacing) `/save-session`
  ↔ `/resume-session` by a clean scope partition: the global
  commands answer "what was I doing this session"; the
  milestone record answers "what is the in-flight state of
  this specific milestone." The counter-proposal (Alternative
  A — rely entirely on `~/.claude/session-data/`, add no
  repo-local record) is permanently recorded in ADR-016 per
  ADR-012/ADR-014/ADR-015 precedent, with concrete re-
  evaluation triggers. **Implementation is deliberately
  deferred to a future session**: no progress-template file,
  no agent-prompt amendments, no `## Development Workflow`
  sentence, and no detector-fixture test have been added in
  this change. Roadmap row #03 remains `◐ in-progress`.
  Bilingual `.md` and `.ja.md`.
- **Milestone #03 — ADR-016 now IMPLEMENTED.** The design
  (ADR-016, `Accepted — 2026-05-16`) landed in a prior
  session; this session ships the full implementation. Four
  artifacts: (1) **`.claude/templates/progress-template.md`**
  (+ **`.ja.md`**) — a paste-in skeleton with YAML front-matter
  (`roadmap_row`, `milestone`, `status_glyph`, `workflow_step`,
  `last_updated`, `head_sha`, `spec_exists`, `adr_links`) and
  three body sections (Done / Next concrete action / Notes /
  why work stopped), matching the schema in ADR-016 Decision 1.
  The template is English-only by convention (same as the
  upstream-workaround registry: transient in-flight state, no
  translation drift); the `.ja.md` sibling covers template
  usage instructions per ADR-005 bilingual convention.
  (2) **Agent-prompt boundary-persistence contracts** — three
  agent prompts (`product-manager`, `implementer`,
  `orchestrator`) each gain one boundary-triggered
  responsibility: `product-manager`/`implementer` create
  `specs/NN-progress.md` at the first session/compaction
  boundary while a milestone is `◐`; `implementer` updates
  it when a boundary is anticipated and deletes it on the
  `◐→☑`/`✗` glyph flip; `orchestrator` reads it at the
  Analyze step and states explicitly when absent. (3) **One
  sentence in `.claude/CLAUDE.md` `## Development Workflow`**
  describing the boundary-persistence contract (per ADR-016,
  composable with `/save-session`). (4) **Two detector
  fixtures** added to `test-check-dangling-refs.sh` confirming
  that an on-disk `specs/NN-progress.md` produces no
  dangling-reference finding, and that the boundary-trigger
  create-before-reference ordering holds. Roadmap row #03
  remains `◐ in-progress` (this session is step 7 Documentation;
  steps 8–9 Release/Commit are pending). Bilingual `.md` and
  `.ja.md` for the template.
- **Milestone #05 — design only; implementation deferred.**
  Spec `specs/05-roadmap-drift-detection-ci.md` (Approved) defines the
  Roadmap index↔reality drift-detection CI — the deferred mitigation
  ADR-014 §Consequences → Negative explicitly names. ADR-017 (`Roadmap
  drift-detection CI — bidirectional-link contract, status-glyph
  well-formedness, MECE-bounded against #04`, status `Accepted —
  2026-05-16`) records four structural decisions for this milestone:
  (1) **Three drift classes** — forward direction of the bidirectional
  contract (a Roadmap row's `adr:` link points to an ADR that exists on
  disk but whose `## References` section lacks a matching
  `Roadmap row: #NN` back-link); reverse direction (an ADR's
  `Roadmap row: #NN` back-link names a row whose `adr:` cell does not
  list that ADR); and status-glyph well-formedness (any glyph other than
  ☐ / ◐ / ☑ / ✗). Non-existent `adr:` targets also FAIL — unlike
  `spec:` reserved links, an `adr:` link is added only when the ADR is
  written so a missing target is never valid-by-design. (2) **MECE
  contract-partition boundary against the #04 detector** — the split is
  drawn on *contract*, not file type: #04's `check-dangling-refs.sh`
  owns reference *resolution* ("does the pointer resolve?"); #05's
  `check-roadmap-drift.sh` owns index *consistency* ("does the
  bidirectional contract hold and is every glyph sanctioned?"). A single
  defect maps to exactly one owner. The deliberate narrow overlap — a
  Roadmap `adr:` link to a non-existent file FAILing both checks — is a
  stronger signal, not a boundary violation. (3) **Absence-of-claim
  exemption** — an ADR is exempt from the bidirectional contract iff its
  `## References` section carries no `Roadmap row:` line at all.
  Absence is the valid-by-design state; only a present claim that is
  inconsistent is drift. This mirrors the discipline of ADR-015's
  reservation carve-out and Reference-intent rule: keyed to a
  co-located structural signal, never a path allowlist. (4) **Always-on
  CI posture inherited from ADR-015** — ADR-015 §Decision point 3 fixed
  this milestone's always-on posture via the subject-matter-presence
  rule (naming #05 explicitly); ADR-017 records the posture as inherited
  and does not re-litigate it. The serious counter-proposal (Alternative
  A — extend `check-dangling-refs.sh` to also check bidirectional
  consistency, one script and one workflow) is permanently recorded in
  ADR-017 with real pros and explicit re-evaluation triggers per the
  ADR-012/ADR-014/ADR-015/ADR-016 convention. **Implementation is
  deliberately deferred to a future session**: no detector script
  (`check-roadmap-drift.sh`), no workflow (`roadmap-drift-check.yml`),
  and no test suite have been written in this change — they are recorded
  as downstream `implementer` tasks in ADR-017 §Consequences → Neutral
  for traceability. Roadmap row #05 remains `◐ in-progress`. Bilingual
  `.md` and `.ja.md` for both `specs/05-roadmap-drift-detection-ci.md`
  and ADR-017.
- **Milestone #10 — design only; implementation deferred.**
  Spec `specs/10-spec-adr-directory-pinning.md` defines the Spec/ADR
  directory location pin. The structural decision (ADR-014 amendment
  vs. new ADR-019) was decided this session by the architect as
  ADR-014's `## Amendment — 2026-05-17 (spec/adr directory pin)` — a
  consequence-clarification of ADR-014's existing Spec-reservation
  Decision, not a new ADR-019 (the counter-proposal is permanently
  recorded in the amendment per the
  ADR-012/ADR-014/ADR-015/ADR-016/ADR-017/ADR-018 convention). Key
  resolutions: directory pin `specs/` (Specs) + `.claude/meta/adr/`
  (ADRs); (a) placement = CLAUDE.md `## Document Templates` rewritten
  audience-scoped (fork = free; this repo = ADR-014-pinned) + a
  one-clause MECE pointer in the `## Roadmap` Rules block; (c)
  claude-md-authoring Skill IS required for the #10 CLAUDE.md edit —
  the genuine divergence from #09: #10 rewrites existing
  `## Document Templates` prose semantics (restructuring class), vs
  #09's single-bullet routine-edit carve-out; no agent-prompt edits,
  no spec/adr-template edits, no CI workflow/script, no moves/renames;
  (d) MECE boundary: #10 (directory) vs #09 (filename) vs #04 vs #05
  vs #11 vs `## Document Templates` fork-facing guidance vs ADR-014
  reservation rule — MECE by owner and by audience; serious
  Counter-proposal (standalone ADR-019) recorded and rejected with 4
  re-evaluation trigger conditions; Roadmap row #10 stays `spec:`-only
  (ADR-014 has no milestone row of its own; identical to #07/#08/#09
  amendments). Implementation deferred to a future session. Bilingual
  `.md` and `.ja.md` (JA mirror lands in the same session to keep
  `check-bilingual-parity.sh` green).
- **Milestone #09 — design only; implementation deferred.**
  Spec `specs/09-spec-filename-convention.md` (Approved) defines the
  Spec filename convention: the canonical form `specs/NN-slug.md` where
  `NN` is the Roadmap row number zero-padded to a two-digit minimum
  (`1→01`; rows >=100 written without extra padding) and `slug` is the
  kebab-case slug already fixed in the row's reserved `spec:` path. The
  JA sibling form is `specs/NN-slug.ja.md` (heading-tree parity owned
  by #06/ADR-018). `specs/NN-progress.md` (ADR-016 cross-session state
  files) are excluded — `progress` is a reserved suffix under ADR-016's
  lifecycle, not governed by this convention. All eight existing Spec
  files (`specs/01-*.md` through `specs/08-*.md`) already conform,
  confirming this is a convention-statement milestone, not a bulk-rename.
  The structural decision (ADR-014 amendment vs. new ADR-019,
  documentation placement, edit scope, Skill necessity, MECE boundary
  against #04/#05/#10/ADR-014-reservation-rule/ADR-016) was decided this
  session by the architect as ADR-014's `## Amendment — 2026-05-17 (spec
  filename convention)` — a consequence-clarification of ADR-014's
  existing Spec-reservation Decision (the reserved `spec:` path is
  `specs/NN-slug.md`; this amendment names that form normative), not a
  new ADR-019 (the counter-proposal is permanently recorded in the
  amendment per the ADR-012/ADR-014/ADR-015/ADR-016/ADR-017/ADR-018
  convention). Key resolutions: (a) convention placement = CLAUDE.md
  `## Roadmap` Rules block, one added bullet after the existing
  reservation-rule guidance, zero extra file reads; (c) CLAUDE.md
  Rules-block-only edit, claude-md-authoring Skill NOT required (single
  bullet, routine-edit carve-out); (d) MECE boundary on contract type
  (#04 reference resolution, #05 index consistency, #10 directory pin,
  #09 filename form, ADR-014 reservation rule, ADR-016 progress-file
  lifecycle). No new ADR, no CI workflow, no agent-prompt edits, no
  renames — all deferred to a future implementation session. Roadmap row
  #09 moves from `☐ todo` to `◐ in-progress`. Bilingual `.md` and
  `.ja.md` (EN amendment + JA mirror land in the same commit to keep
  `check-bilingual-parity.sh` green).
- **Milestone #08 — design only; implementation deferred.**
  Spec `specs/08-orchestrator-row-guard.md` (Approved) defines the
  Orchestrator Analyze row-guard: three named pre-dispatch guard
  conditions (G1 — a Roadmap row exists for the incoming task; G2 —
  the row's `spec:` file exists on disk when the next action would
  dispatch to `implementer` or `test-runner`; G3 — for a `◐
  in-progress` row, `specs/NN-progress.md` is present or its absence
  is stated explicitly) with three named routing outcomes, all
  MECE-bounded against #04 (commit-time reference resolution), #05
  (commit-time Roadmap consistency), and #07 (process glyph
  write-ownership) on trigger point + contract. The structural
  decision (ADR-014 amendment vs. new ADR-019, documentation
  placement, orchestrator.md edit scope, Skill necessity, MECE
  boundary) was decided this session by the architect as ADR-014's
  `## Amendment — 2026-05-17 (orchestrator Analyze row-guard)` — a
  consequence-clarification of ADR-014's existing Decision (the
  Roadmap-single-entry-point invariant the orchestrator's Analyze
  step depends on), not a new ADR-019 (the counter-proposal is
  permanently recorded in the amendment per the
  ADR-012/ADR-014/ADR-015/ADR-016/ADR-017/ADR-018 convention).
  Key resolutions: (a) guard placement = orchestrator.md Workflow
  step 1 (Analyze) as a named in-step guard, zero extra file reads;
  (c) orchestrator.md Workflow-step-1-only edit, claude-md-authoring
  Skill NOT required (in-step extension, not restructuring); (d)
  MECE boundary on trigger point (#04/#05 commit-time vs. #07
  process vs. #08 runtime); R-02 resolved to the simpler heuristic
  (a ☐ or ◐ row with an absent `spec:` file routes to
  `product-manager` first, no downstream-agent introspection at the
  guard). No new ADR, no CI workflow, no agent-prompt edits — all
  deferred to a future implementation session. Roadmap row #08 moves
  from `☐ todo` to `◐ in-progress`. Bilingual `.md` and `.ja.md`.
- **Milestone #07 — design only; implementation deferred.**
  Spec `specs/07-roadmap-status-transitions.md` (Approved) defines
  Roadmap status-transition ownership assignment: explicit named-role
  ownership for each of the four glyph transitions (☐→◐, ◐→☑,
  ◐→✗, ☑→✗) with gate conditions, compatibility with ADR-014's
  row/link write-ownership, and composability with ADR-016's
  progress-file deletion trigger. The structural decision
  (ownership matrix, placement, agent-prompt impact, Skill
  necessity) was decided this session by the architect as
  ADR-014's `## Amendment — 2026-05-17 (status-transition ownership
  matrix)` — a consequence-clarification of ADR-014's existing
  Decision, not a new ADR-019 (the counter-proposal is permanently
  recorded in the amendment per the ADR-012/ADR-014/ADR-015/ADR-016/
  ADR-017/ADR-018 convention). Ownership matrix: `product-manager`
  flips ☐→◐ atomically with Spec authoring; `product-manager`
  flips ◐→☑ after the step-6 quality gate passes (deleting
  `specs/NN-progress.md` in the same change per ADR-016); drops
  (◐→✗ and ☑→✗) are decided by `orchestrator` at Analyze and
  written by `product-manager`, row retained. No new ADR, no CI
  workflow, no agent-prompt edits — all deferred to a future
  implementation session. Roadmap row #07 moves from `☐ todo` to
  `◐ in-progress`. Bilingual `.md` and `.ja.md`.
- **Milestone #06 — design only; implementation deferred.**
  Spec `specs/06-bilingual-parity-detector.md` (Approved) defines the
  EN/JA bilingual parity detector — three parity dimensions (heading-tree
  parity by level+position, full-width-parenthesis detection in `.ja.md`
  files, presence parity) across 11 acceptance criteria, with an always-on
  CI posture inherited from ADR-015 §Decision point 3 (which names #06
  explicitly). ADR-018 (`EN/JA bilingual parity detector —
  convention-presence in-scope keying, level+position heading
  normalization, three-way MECE-by-contract against #04 and #05`, status
  `Accepted — 2026-05-16`) records four structural decisions: (1)
  **In-scope tree set keyed to the presence of the bilingual convention
  itself** — a tree is in-scope iff it contains at least one `.ja.md`
  file. This is a structural pattern-keyed rule, not an enumerated
  allowlist (the ADR-017 §4 anti-pattern). It supersedes the Spec's
  conservative interim default and auto-includes new bilingual trees on
  first `.ja.md` arrival, auto-excludes trees that drop their last
  `.ja.md`, with no script edit. (2) **EN-only carve-out subsumed by
  Decision 1** — no separate per-file carve-out signal is required. A
  tree with zero `.ja.md` files is not in-scope by Decision 1; an
  unpaired `.md` inside an otherwise-bilingual tree is a presence-parity
  failure. The only sanctioned EN-only state is "the whole tree is
  EN-only," eliminating the forbidden per-file path allowlist. (3)
  **Heading-normalization compares (level, position) only, never heading
  text** — JA heading text is a translation and must never be
  string-compared against EN. Numbered prefixes (e.g. `## 1. Context`
  vs. `## 1. コンテキスト`) are already handled by level+position
  matching; no prefix-stripping is introduced (it would be dead code and
  speculative generality). Fenced code block skipping is inherited from
  #04/#05 unmodified. (4) **Parsing-approach: single-pass with
  fence-skip, `<!-- ref-allow: -->` escape hatch reused UNMODIFIED from
  #04/#05** — the same token, same per-line semantics, no new escape
  syntax, keeping the conceptual load flat across all three detectors.
  Three-way MECE-by-contract boundary against #04 and #05: #04 owns
  reference *resolution*, #05 owns Roadmap *index consistency*, #06 owns
  EN↔JA *translation parity*; the concrete proof the boundary is
  load-bearing before #06 ships is that `check-roadmap-drift.sh`
  (milestone #05, shipped this session) already excludes `.ja.md` from
  its reverse-direction scan, citing #06 as the contract owner. The
  serious counter-proposal (fold bilingual parity into
  `check-roadmap-drift.sh` or `check-dangling-refs.sh` — Alternative A)
  is permanently recorded in ADR-018 with real pros and explicit
  re-evaluation triggers, per the ADR-012/ADR-014/ADR-015/ADR-016/ADR-017
  convention. **Implementation is deliberately deferred to a future
  session**: no detector script
  (`.claude/meta/scripts/check-bilingual-parity.sh`), no workflow
  (`.github/workflows/bilingual-parity-check.yml`), and no test suite
  have been written in this change — they are recorded as downstream
  `implementer` tasks in ADR-018 §Consequences → Neutral for
  traceability. Roadmap row #06 remains `◐ in-progress`. Bilingual `.md`
  and `.ja.md` for `specs/06-bilingual-parity-detector.md` (both authored
  by `product-manager` this session). Note: the Japanese counterpart of
  ADR-018 itself (`018-bilingual-parity-detector.ja.md`) has **not** been
  written in this change — it is owned by `technical-writer` and deferred
  to a future session, exactly as ADR-017's `.ja.md` was deferred at its
  design-only landing.
- **Milestone #12 — design only; implementation deferred.**
  Spec `specs/12-coverage-ci-gate.md` (Approved) closes the gap where
  `.claude/CLAUDE.md` `## Testing Requirements` mandates "Minimum 80%
  test coverage" with no CI enforcement (`ci-base.yml` runs tests
  with no threshold). ADR-019 (`CI coverage gate (80% hard check)`,
  status `Proposed — 2026-05-18`) records the structural decisions for
  this milestone. The ADR-018 Alternative-B discriminator triad was
  applied clause-by-clause and scored **3/3** (new CI hard-check +
  new MECE partition NOT pre-reserved by ADR-014 §(d), which names
  #04/#05/#09/#10/#11 but not #12 + new structural keying) → a
  **new ADR-019**, not an ADR-014 amendment and not an ADR-010
  amendment — the #04/#05/#06 precedent (ADR-015/ADR-017/ADR-018),
  the opposite call from #11 (which took an ADR-014 amendment
  precisely because it populated a pre-reserved §(d) slot; #12 has
  none). Key ADR-019 resolutions: (1) **CI structural form** = a
  standalone forkable `.github/workflows/coverage-gate.yml` (NOT a
  `ci-base.yml` modification — preserves `ci-base.yml`'s unchanged
  `test-command` contract); (2) **activation posture** = default-off
  single-switch (the `workaround-check.yml` precedent; chosen because
  the template has no coverage subject matter so ADR-015's subject-
  matter-presence rule rejects always-on — this makes the template
  green-by-construction with no inert branch, satisfying Spec AC-5);
  (3) **single source of truth** = the 80% number stays canonical in
  `.claude/CLAUDE.md` `## Testing Requirements`, read at CI runtime;
  the activation config carries the on/off switch only and no number
  (satisfies AC-2/AC-8, mitigates R-02 drift); (4) **language-agnostic
  forkability** = the scaffold accepts the derived repo's already-
  computed coverage percentage as a `workflow_call` input (mirrors
  `ci-base.yml`'s input pattern, satisfies AC-3/R-04); (5) **MECE
  boundary** = #12 owns "coverage-threshold enforcement at CI time", a
  new partition distinct from #04 (path resolution) / #05 (Roadmap
  drift, ADR-017) / #06 (bilingual parity, ADR-018) / #11
  (verification-domain opt-in guidance, doc/convention) and explicitly
  NOT pre-reserved by ADR-014 §(d). Serious counter-proposal (fold
  into an ADR-014 amendment / extend `ci-base.yml`) recorded and
  rejected with exactly 3 re-evaluation trigger conditions, per the
  ADR-012/ADR-014/ADR-015/ADR-016/ADR-017/ADR-018 convention. Roadmap
  row #12 moves `☐ todo` → `◐ in-progress` (product-manager, #07
  rule) and gains an `adr:` link to ADR-019 (architect write-ownership
  for a new ADR — unlike the #07–#11 amendments which stayed
  `spec:`-only because ADR-014 has no milestone row of its own; #12
  gets `adr:` because ADR-019 is a new ADR, the #03/#04/#05/#06
  precedent). Implementation deferred to a future session. Bilingual
  `.md` and `.ja.md` (ADR-019 JA mirror landed the same session to
  keep `check-bilingual-parity.sh` green; the Spec JA sibling
  `specs/12-coverage-ci-gate.ja.md` also lands this session).
- **Milestone #17 — now IMPLEMENTED** (single session; no ADR — the
  ADR-018 Alternative-B triad scored 0/3: no new contract boundary,
  no new keying/mechanism, no new structural artifact; a mechanical
  Status-format normalization of three existing ADRs). Six lines
  changed across six files: ADR-002 EN (`.claude/meta/adr/002-growth-domains-location.md`)
  and JA (`.claude/meta/adr/002-growth-domains-location.ja.md`) Status
  lines normalized from `Accepted. 2026-04-23.` to `Accepted — 2026-04-23`;
  ADR-003 EN (`.claude/meta/adr/003-learning-mode-relocate-and-rename.md`)
  and JA (`.claude/meta/adr/003-learning-mode-relocate-and-rename.ja.md`)
  Status lines normalized (EN: `Accepted. 2026-04-24.` → `Accepted — 2026-04-24`;
  JA: `採択済み。2026-04-24。` → `Accepted — 2026-04-24`);
  ADR-004 EN (`.claude/meta/adr/004-coaching-pillar.md`) and JA
  (`.claude/meta/adr/004-coaching-pillar.ja.md`) Status lines normalized
  (EN: `Accepted. 2026-04-25.` → `Accepted — 2026-04-25`;
  JA: `採択済み。2026-04-25。` → `Accepted — 2026-04-25`).
  All six changes use U+2014 em-dash, matching the template standard
  (`Accepted — YYYY-MM-DD`) confirmed by Roadmap #16, which corrected
  ADR-001's Status to `Accepted — 2026-04-22` in the same em-dash form.
  ADR-001 and ADR-005 are already in template-standard format and are
  not touched. Historical narrative (body text, rationale, Alternatives,
  Consequences, Metadata, blockquotes) in each of the six files is
  preserved verbatim; only the Status line changes in each file.
  Spec `specs/17-changelog-adr-sync.md` (Approved) is the source of truth.

### Added

- **Milestone #16 — now IMPLEMENTED** (single session; no ADR — the
  ADR-018 Alternative-B triad scored 0/3: no new contract boundary,
  no new keying/mechanism, no new structural artifact; a mechanical
  Status-vocabulary correction of an existing historical ADR). One
  corrected line in each of two files: (1)
  **`.claude/meta/adr/001-developer-growth-mode.md`** line 5 is
  whole-line replaced from `Proposed (stabilized). Supersedes earlier
  drafts...` to `Accepted — 2026-04-22` (U+2014 em-dash, matching the
  ADR-005 through ADR-021 dominant pattern; date from ADR-001 Metadata
  `Date: 2026-04-22`), bringing ADR-001's Status into conformance with
  the ADR template vocabulary (`Proposed | Accepted | Deprecated |
  Superseded by ADR-NNN`). (2)
  **`.claude/meta/adr/001-developer-growth-mode.ja.md`** the
  corresponding JA Status line is whole-line replaced in the same way
  (to `Accepted — 2026-04-22`, EN em-dash form confirmed by the
  architect as the consistent corpus pattern: 17 of 20 JA ADR siblings
  already use this form). Historical narrative preserved verbatim:
  ADR-001 body text, rationale, alternatives, and the existing
  "Partially superseded 2026-04-24 by ADR-003" blockquote (EN lines
  7-9 / JA lines 1-5) are unchanged — the correction is the Status
  line only (EN net 1-line change, JA net 1-line change). MECE scope:
  this milestone is ADR-001 Status expression only; CHANGELOG↔ADR
  acceptance-date sync, ADR-002–005 back-fill, and repo-wide ADR
  Status format normalization are explicitly out of scope (Roadmap #17
  / `specs/17-changelog-adr-sync.md`). Spec
  `specs/16-adr-001-status-resolution.md` (Approved) is the source of
  truth, with a JA sibling `specs/16-adr-001-status-resolution.ja.md`
  at exact heading-tree parity. Roadmap row #16 flipped `☐ todo →
  ◐ in-progress` at pickup (atomic with Spec authoring);
  `product-manager` flips `◐ in-progress → ☑ done` after the step-6
  quality gate passes, in this same change (the CLAUDE.md diff is the
  single row-16 line only, Invariant 2 preserved).

- **Milestone #15 — now IMPLEMENTED** (single session; no ADR — the
  ADR-018 Alternative-B triad scored 0/3: no new contract boundary,
  no new keying/mechanism, no new structural artifact; a
  straightforward extension of `init.sh`'s existing
  `has_placeholder`-gated CLAUDE.md mutation scope). Two artifacts:
  (1) **`.claude/meta/scripts/init.sh`** gains a
  `clean_roadmap_section()` function (called inside the existing
  `if [[ $has_placeholder -eq 1 ]]` block) that, at fork time,
  strips the 21 template dogfooding Roadmap rows and the `**Spec
  reservation rule:**` paragraph from the fork's `.claude/CLAUDE.md`
  and injects exactly one placeholder row `| — | [Add your first
  milestone here] | ☐ todo | (none yet) |` (em-dash in the `#` cell
  is invisible to `check-roadmap-drift.sh`'s digit parser;
  `(none yet)` carries no `spec:` or `adr:` token so
  `check-dangling-refs.sh` stays green); the `## Roadmap` heading,
  intro sentence, table header+separator, and `**Rules:**` block are
  preserved; honors `--dry-run`; idempotent (gated on
  `has_placeholder`); single awk pass + temp-file/mv (no bash
  read-loop); byte-count guard aborts rather than truncating
  CLAUDE.md on malformed output. (2)
  **`.claude/meta/scripts/test-init-sh-roadmap-cleanup.sh`** — 17
  tests covering AC-1a–AC-1g (all seven post-cleanup structural
  invariants), AC-2 (glyph well-formedness), AC-3 (no
  dangling-ref token), AC-4a/b (idempotency + skip message),
  AC-5a/b (dry-run parity), AC-7 (ok message), AC-8 (structural
  awk presence), and two regression guards (Fix-2, Fix-3); all 17
  pass; fixture-isolated, never runs non-dry-run `init.sh` against
  the live template CLAUDE.md. Spec `specs/15-init-sh-roadmap-cleanup.md`
  (Approved) is the source of truth, with a JA sibling
  `specs/15-init-sh-roadmap-cleanup.ja.md` at exact heading-tree
  parity. Roadmap row #15 flipped `☐ todo → ◐ in-progress` at
  pickup (atomic with Spec authoring); `product-manager` flips
  `◐ in-progress → ☑ done` after the step-6 quality gate passes,
  in this same change (the CLAUDE.md diff is the single row-15 line
  only, Invariant 2 preserved).

- **Milestone #14 — now IMPLEMENTED** (two-session split — design
  landed under commit `2591082` / ADR-021 `Proposed`;
  implementation completed this session per ADR-021 §Consequences →
  Neutral downstream tasks and Decision 7 implementation-session
  contract). Six artifacts: (1)
  **`.claude/meta/scripts/check-research-tier-auth.sh`** — new
  default-off detector auditing verification-review artifact *bodies*
  for auth-scope keyword presence (auth, authn, authz, crypto,
  security-sensitive APIs — derived at run time from `protocol.md`'s
  Tier-table T1 scope line, never hardcoded) while the declared Tier
  is T2 or T3; scans the artifact body not just the topic line,
  catching the topic-description-omission the orchestrator guardrail
  misses; fails closed with a human-readable message naming the
  artifact, matched auth term, and declared Tier vs required T1; if
  the canonical T1 scope line is not found in `protocol.md`, the
  detector fails closed loudly ("canonical T1 scope line not found"),
  never silently passes — R-04 closed by construction. (2)
  **`.github/workflows/research-tier-auth-check.yml`** — forkable
  default-off standalone workflow (`push` / `pull_request` triggers,
  the `ecc-delegation-consistency-check.yml` precedent); single
  activation switch
  `enabled: false` in **`.github/research-tier-auth-tracker.yml`**
  (the `workaround-check.yml` / `coverage-gate.yml` /
  `ecc-delegation-consistency-check.yml` single-switch precedent;
  `ci-base.yml` byte-unchanged; `permissions: contents: read`;
  `timeout-minutes: 5`; no `${{ inputs.* }}` ever interpolated into
  a `run:` block). (3)
  **`.claude/meta/scripts/test-check-research-tier-auth.sh`** —
  dedicated 12-test TDD suite, making the separated-run test suite
  count six (alongside `test-check-dangling-refs.sh`,
  `test-check-roadmap-drift.sh`, `test-check-bilingual-parity.sh`,
  `test-coverage-threshold.sh`,
  `test-check-ecc-delegation-consistency.sh`); fixtures cover: auth
  content at T2 FAILs naming term + Tier; auth content at T3 FAILs;
  auth content at T1 passes; non-auth content at T2 passes; switch
  off makes the job inert (template green-by-construction, AC-8);
  missing canonical T1 scope line fails closed; a `protocol.md`
  T1-scope amendment is tracked with zero second edit (R-04); and
  `verification.yml`, `orchestrator.md`, the `protocol.md`
  Tier-table lines, and the five existing detectors + suites are
  byte-unchanged (AC-3/AC-4/AC-5/AC-6). (4) **`### Auth→T1 mandatory
  rule` subsection** appended under the Tier table in
  `.claude/skills/verification-layer/research/protocol.md` —
  the auth→T1 written contract stated as a mandatory rule
  (independently readable without `orchestrator.md`), referencing
  the existing T1 scope line by pointer rather than reproducing it;
  the Tier-table row lines themselves are byte-unchanged (AC-4). (5)
  **ADR-021 status transitioned `Proposed → Accepted — 2026-05-19`**
  (the ADR-017/ADR-019/ADR-020 two-session lifecycle); the
  now-false present-tense "deferred / will" self-narrative reconciled
  to past-tense in EN + JA (heading-tree parity 18 == 18, level-seq
  identical, JA full-width parens 0). (6) **`specs/14-research-tier-validation.ja.md`**
  — JA sibling of the Spec authored by `technical-writer` this
  session (18 headings EN/JA parity, JA parens 0; the
  `specs/13-ecc-absent-signal.ja.md` precedent). AC-1..AC-8 all
  verified; the five existing detectors + suites,
  `verification.yml`, `orchestrator.md`, and `ci-base.yml`
  byte-unchanged (AC-3/AC-4/AC-5/AC-6); default-off
  green-by-construction (AC-8). Roadmap row #14 flips
  `◐ in-progress` → `☑ done`. Spec and ADR are the source of
  truth: `specs/14-research-tier-validation.md` and
  `.claude/meta/adr/021-research-tier-auth-validation.md`.

- **Milestone #13 — now IMPLEMENTED** (two-session split — design
  landed under commit `92aaa0a` / ADR-020 `Proposed — 2026-05-18`;
  implementation completed this session per ADR-020 §Consequences →
  Neutral downstream tasks). Five artifacts: (1)
  **`.claude/meta/scripts/check-ecc-delegation-consistency.sh`** —
  new default-off detector validating `code-reviewer.md`'s nine-row
  ECC delegation table for internal consistency (every
  manifest→ECC-agent row references a name declared in the file's
  own reviewer intro list), with zero operator-environment
  introspection — reads only repository artifacts, consistent with
  `code-reviewer.md` lines 84–87 forbidding unreliable runtime
  introspection (Spec AC-5); green-by-construction on the
  template's own `main` (Spec AC-3). (2)
  **`.github/workflows/ecc-delegation-consistency-check.yml`** —
  forkable default-off `workflow_call` workflow; single activation
  switch `enabled: false` in `.github/ecc-delegation-tracker.yml`
  (the `workaround-check.yml` / `coverage-gate.yml` single-switch
  precedent, ADR-019 Decision 2 / ADR-006). (3)
  **`.claude/meta/scripts/test-check-ecc-delegation-consistency.sh`**
  — dedicated 10-test TDD suite, making the separated-run test suite
  count five (alongside `test-check-dangling-refs.sh`,
  `test-check-roadmap-drift.sh`, `test-check-bilingual-parity.sh`,
  `test-coverage-threshold.sh`). (4) **Standing-posture pointer
  in `code-reviewer.md`** — a co-located, discoverable statement
  of the degraded-review standing posture placed immediately before
  the three-case delegation rule (lines 72–92 byte-unchanged per
  Spec AC-6), making the posture discoverable at the checkpoint
  where it is actionable without requiring a new always-read file
  (Spec AC-7). (5) **ADR-020 status transitioned `Proposed →
  Accepted — 2026-05-18`** (the ADR-017/ADR-019 two-session
  lifecycle). Roadmap row #13 flips `◐ in-progress` → `☑ done`.
  Spec and ADR are the source of truth:
  `specs/13-ecc-absent-signal.md` and
  `.claude/meta/adr/020-ecc-absent-signal.md`.

- **Milestone #12 — now IMPLEMENTED** (two-session split — design
  landed under commit `1390206` / ADR-019 `Proposed — 2026-05-18`;
  implementation completed this session per ADR-019 §Consequences →
  Neutral downstream tasks). Four artifacts: (1)
  **`.github/workflows/coverage-gate.yml`** — standalone forkable
  `workflow_call` workflow accepting the derived repo's already-computed
  coverage percentage as input, gated default-off, deriving the 80%
  threshold by reading `.claude/CLAUDE.md` `## Testing Requirements` at
  CI runtime, failing closed with a non-zero exit and a human-readable
  message naming both the measured coverage and the threshold when below
  it (Spec AC-1), `permissions: contents: read`,
  `timeout-minutes: 5`. `ci-base.yml` is byte-unchanged (Spec
  Key-interaction 1 / Spec AC-6). (2)
  **`.github/coverage-tracker.yml`** — default-off single-switch
  activation config carrying one `enabled` boolean and no threshold
  number (Decision 2/3); mirrors the `workaround-check.yml` /
  `.github/workaround-tracker.yml` shape; the one in-repository
  change a derived repo makes to opt in (Spec AC-4). (3)
  **`.claude/meta/scripts/coverage-threshold.sh`** — single-source
  threshold extractor: reads "Minimum NN% test coverage" out of
  `.claude/CLAUDE.md` `## Testing Requirements` at runtime, so the
  enforced threshold tracks the canonical declaration with zero second
  edit (Decision 3 / Spec AC-2/AC-8). (4)
  **`.claude/meta/scripts/test-coverage-threshold.sh`** — 13-test TDD
  suite proving: coverage below threshold FAILs naming measured +
  threshold; coverage at/above threshold passes; switch off makes the
  job inert (template green-by-construction, Spec AC-5); missing
  `## Testing Requirements` line fails closed (Decision 3); threshold
  tracks a changed `## Testing Requirements` value with no second edit
  (Spec AC-2/AC-8); `ci-base.yml` and the four detector scripts + three
  existing test suites are byte-unchanged (Spec AC-6 no scope bleed).
  ADR-019 Status moved **Proposed → Accepted**. Roadmap row #12 flips
  `◐ in-progress` → `☑ done`.

- **Milestone #11 — now IMPLEMENTED** (designed AND implemented this
  same session — no prior-session design-only bullet exists; this is a
  deliberate single-session collapse, and the architect's `### Downstream
  implementer tasks` heading was updated to record it). A SKILL.md-only
  prose change: one new `## Project adoption triggers` section inserted
  between `## Configuration` and `## When to invoke` in
  `.claude/skills/verification-layer/SKILL.md`. The section contains
  ≥3 project-characteristic adoption triggers per domain
  (`implementation` and `design`), framed additively — partial match as
  a guide, not a checklist gate. Triggers are distinct from and do not
  duplicate the per-change runtime triggers in
  `implementation/protocol.md` and `design/protocol.md` `## When to
  invoke`; an outbound pointer directs readers to those files for the
  subsequent question. Structural decision: **ADR-014 amendment** (NOT
  new ADR-019, NOT ADR-010 amendment). The ADR-018 Alternative-B
  discriminator triad was applied clause-by-clause: no new detector
  (eliminates new ADR-019 trigger 1), no new MECE partition
  (eliminates trigger 2), no new keying (eliminates trigger 3);
  ADR-010's default-off Decision is preserved verbatim, disqualifying
  an ADR-010 amendment. A serious counter-proposal (author ADR-019 to
  record a new structural convention) was raised and rejected with
  explicit re-evaluation trigger conditions recorded in the ADR-014
  amendment. MECE/scope facts: populates the slot pre-reserved for #11
  at ADR-014 §(d) MECE table line 1800 (classification:
  "documentation/convention"); no new CI detector, no new MECE
  partition, no `.claude/verification.yml` active-default change
  (`implementation.enabled`/`design.enabled` remain `false`); no
  agent-prompt edits, no spec/adr-template edits, no script or
  workflow. The CLAUDE.md change is a single Roadmap-row glyph flip
  (`☐→◐` at pickup by `product-manager`) — the lightest routine edit;
  claude-md-authoring Skill correctly NOT invoked (identical to
  #07/#08/#09/#10). Bilinguality: SKILL.md is English-only by design
  (frontmatter declares it; correctly no `.ja.md` sibling exists or was
  created). The ADR-014 amendment shipped with its `.ja.md` mirror
  same-session (51/51 heading parity verified). The JA Spec sibling
  `specs/11-verification-domain-opt-in-guidance.ja.md` is authored by
  `technical-writer` in this same step-7 documentation pass.
  Roadmap row #11 flips ◐→☑ done.

- **Milestone #10 — now IMPLEMENTED** (design landed previously under
  Documentation as ADR-014's 2026-05-17 `(spec/adr directory pin)`
  amendment; implementation completed this session). A
  CLAUDE.md-only change in two places. (1) The `## Document
  Templates` placement paragraph was **rewritten in place** to be
  audience-scoped: forks decide their own layout (the template
  imposes no layout on forks — preserved, not reversed), while *this
  repository's* dogfooding posture pins Spec files to `specs/` and
  ADR files to `.claude/meta/adr/` (three-digit zero-padded prefix),
  both at the repo root, with EN/JA Spec siblings co-located in the
  **same** `specs/` directory (`specs/NN-slug.md`,
  `specs/NN-slug.ja.md`, not language-split) and heading-tree parity
  owned by #06. The two audiences are explicitly framed as
  non-conflicting (R-03). (2) The existing #09 filename bullet in
  the `## Roadmap` **Rules:** block gained **one pointer clause**
  ("see `## Document Templates` for the pinned `specs/` and
  `.claude/meta/adr/` directories") — a pointer only, not a
  restatement of the rule (no forbidden second source). Because the
  `## Document Templates` edit rewrites existing prose semantics
  (restructuring class, the genuine divergence from #09's
  single-bullet routine carve-out), the **claude-md-authoring Skill
  was invoked** (Pre/Post checklists + all four invariants verified
  against the edited section; Invariant 2 compaction-durability and
  template-layout-neutrality specifically checked). No agent-prompt
  edits, no spec/adr-template edits, no CI workflow or script, no
  moves or renames (all 16 existing `specs/*` and 36 existing
  `.claude/meta/adr/*` files already conform — a
  convention-statement, not a bulk-move; verified empirically). No
  new ADR (this is an ADR-014 amendment, identical reasoning to
  #07/#08/#09); Roadmap row #10 stays `spec:`-only (no `adr:`
  link — ADR-014 has no milestone row of its own). `CLAUDE.md` is
  EN-only; no bilingual mirror needed. All eight `specs/10`
  acceptance criteria verified directly against the edited file.
  Roadmap row #10 flips ◐→☑ done.

- **Milestone #09 — now IMPLEMENTED** (design landed previously under
  Documentation as ADR-014's 2026-05-17 `(spec filename convention)`
  amendment; implementation completed this session). A
  CLAUDE.md-only change: one bullet appended to the `## Roadmap`
  **Rules:** block immediately after the reservation-rule bullet,
  stating the normative Spec filename convention — a Spec file is
  `specs/NN-slug.md` (`NN` zero-padded to a two-digit minimum,
  `1→01`, rows ≥100 without extra padding; `slug` copied from the
  row's reserved `spec:` path, not re-derived); the JA sibling is
  `specs/NN-slug.ja.md` with heading-tree parity owned by #06;
  `specs/NN-progress.md` is excluded as ADR-016's reserved suffix;
  #10 pins the directory and #09 pins the filename (MECE). The
  bullet text is the verbatim wording the ADR-014 amendment
  supplied. Single bullet, no sub-heading, no table — within the
  routine-edit carve-out, so no claude-md-authoring Skill
  invocation. No agent-prompt edits, no spec-template edit, no CI
  workflow or script, no renames (all eight existing `specs/01-*`
  … `specs/08-*` already conform — a convention-statement, not a
  bulk-rename). No new ADR (this is an ADR-014 amendment); Roadmap
  row #09 stays `spec:`-only (no `adr:` link — ADR-014 has no
  milestone row of its own, identical to #07/#08). `CLAUDE.md` is
  EN-only; no bilingual mirror needed. All seven `specs/09`
  acceptance criteria verified directly against the edited file.
  Roadmap row #09 flips ◐→☑ done.

- **Milestone #08 — now IMPLEMENTED** (design landed previously under
  Documentation as ADR-014's 2026-05-17 amendment; implementation
  completed this session). An agent-prompt-only change: a named
  **Analyze pre-dispatch guard** (G1/G2/G3) added in-step to
  `.claude/agents/orchestrator.md` Workflow step 1 (Analyze) with no
  new `##`-level section and no Workflow-list restructuring. G1 —
  a Roadmap row must exist before any sub-agent dispatch (missing row
  routes to `product-manager`). G2 — the row's `spec:` file must
  exist on disk for `☐`/`◐` rows (absent Spec routes to
  `product-manager`; guard fires on row status + `spec:`-file presence
  alone, with no downstream-agent introspection at guard-evaluation
  time — the R-02 simpler heuristic adopted per the amendment). G3 —
  for a `◐ in-progress` row, `specs/NN-progress.md` must be present;
  if absent, state explicitly that no progress record exists and
  re-derive state from `git log` (G3 is a promote-and-replace: the
  prior informal fallback sentence in Workflow step 1 is absorbed into
  the named G3, not duplicated). `orchestrator` remains read-only
  throughout (ADR-014 §Decision). No new ADR (this is an ADR-014
  amendment), no CI workflow, no other agent-prompt edits. `orchestrator.md`
  is EN-only; no bilingual mirror needed. Roadmap row #08 flips ◐→☑ done.

- **Milestone #07 — now IMPLEMENTED** (design landed previously under
  Documentation as ADR-014's 2026-05-17 amendment; implementation
  completed this session). A documentation-only change: one bullet
  appended to the `## Roadmap` **Rules:** block in `CLAUDE.md`,
  formalizing the status-transition ownership matrix. `product-manager`
  flips ☐→◐ atomically with Spec authoring at milestone pickup;
  `product-manager` flips ◐→☑ after the step-6 quality gate passes
  (deleting `specs/NN-progress.md` in the same change per ADR-016);
  drops (◐→✗, ☑→✗) are decided by `orchestrator` at Analyze and
  written by `product-manager`, row retained (history not rewritten).
  This is MECE with Milestone #05 (which governs glyph *value*
  well-formedness) — #07 governs *who* flips and *when*. No new ADR,
  no CI workflow, no agent-prompt edits. CLAUDE.md is EN-only; no
  bilingual mirror needed. Roadmap row #07 flips ◐→☑ done.

- **Milestone #06 — now IMPLEMENTED** (design landed previously
  under Documentation; implementation completed this session per
  ADR-018 §Consequences → Neutral downstream tasks, including a
  2026-05-17 in-scope-granularity amendment). An always-on CI
  detector enforcing three EN/JA bilingual parity dimensions. Four
  artifacts:
  - `.claude/meta/scripts/check-bilingual-parity.sh` — the
    detector (`set -euo pipefail`, `pass`/`warn`/`fail_check`
    accumulator, `GITHUB_STEP_SUMMARY` support, line-level
    `<!-- ref-allow: -->` escape hatch reused unmodified from
    #04/#05). Three checks: (1) **Presence parity** — an orphaned
    `.ja.md` with no `.md` counterpart FAILs; a lone `.md` in an
    otherwise-bilingual tree is a sanctioned EN-only complement
    per ADR-018's 2026-05-17 per-file-pair-granularity amendment.
    (2) **Heading-tree parity by (level, position) only** — text-
    blind so correct translations never false-positive; fenced-code-
    skip and `<!-- ref-allow: -->` reused unmodified from #04/#05.
    (3) **Full-width-parenthesis scan** — U+FF08/U+FF09 in in-scope
    `.ja.md` files per the Japanese typography rules.
  - `.github/workflows/bilingual-parity-check.yml` — always-on
    (no per-fork config; posture inherited from ADR-015's
    subject-matter-presence rule naming #06), single
    `bilingual-parity-check` job, `permissions: contents: read`,
    `timeout-minutes: 5`. Modeled on `dangling-ref-check.yml`.
  - `.claude/meta/scripts/test-check-bilingual-parity.sh` — TDD
    suite (22 tests) covering all 11 Spec/06 acceptance criteria
    plus edge cases. `check-dangling-refs.sh` and
    `check-roadmap-drift.sh` each gain a reciprocal MECE-boundary
    header note extending the two-way (#04↔#05) note to three-way
    (#04/#05/#06), so the resolution / consistency / parity
    partition is discoverable from all three scripts.
  - ADR-018 gains a 2026-05-17 amendment refining in-scope
    granularity to per-file-pair (not per-directory), so the
    template is green-by-construction at fork time. ADR-018's
    Japanese counterpart (`018-bilingual-parity-detector.ja.md`)
    was authored this session. Two pre-existing bilingual-parity
    defects corrected so green-by-construction holds:
    `.claude/meta/references/learning-mode-explained.ja.md`
    (EN/JA heading count restored 24↔24) and two ADR-018.ja.md
    body lines reworded to reference forbidden full-width-paren
    characters by codepoint only. Roadmap row #06 flips
    `◐ in-progress` → `☑ done`.
- **Milestone #05 — now IMPLEMENTED** (design landed previously
  under Documentation; implementation completed this session per
  ADR-017 §Consequences → Neutral downstream tasks). An always-on
  CI detector for Roadmap index↔reality drift. Three artifacts:
  - `.claude/meta/scripts/check-roadmap-drift.sh` — the detector
    (`set -euo pipefail`, `git rev-parse` root resolution,
    `pass`/`warn`/`fail_check` accumulator, `fail=0`,
    `GITHUB_STEP_SUMMARY` support, line-level
    `<!-- ref-allow: -->` escape hatch reused unmodified from
    #04). Three checks: (1) Status-glyph well-formedness — every
    Roadmap row's Status cell must hold one of the four
    ADR-014-sanctioned glyphs (☐ / ◐ / ☑ / ✗). (2) Forward
    bidirectional contract — a row's `adr:` target must exist on
    disk AND back-link the row via `Roadmap row: #NN` in its
    `## References`; a non-existent `adr:` target also FAILs (no
    reservation carve-out, unlike `spec:` links). (3) Reverse
    bidirectional contract — an ADR carrying a `Roadmap row: #NN`
    back-link must be listed in row `#NN`'s `adr:` cell. The
    Design-source cell is parsed as a `<br>`-joined unit and
    *every* `adr:` link is extracted (ADR-014 permits 1:N;
    line-greedy single-match parsing is forbidden per ADR-017
    §4). The absence-of-claim exemption is keyed structurally:
    an ADR with no `Roadmap row:` back-link line is exempt — no
    ADR-filename allowlist (the anti-pattern ADR-015's amendment
    rejected). `.ja.md` translations are excluded from the
    reverse scan as derived artifacts (EN/JA back-link parity is
    milestone #06's distinct contract, a Spec Non-goal here).
  - `.github/workflows/roadmap-drift-check.yml` — always-on,
    path-scoped workflow modeled on `dangling-ref-check.yml`:
    runs on every push and pull request to `main` touching
    `.claude/CLAUDE.md`, the ADR tree, or the script/workflow
    themselves; single `roadmap-drift-check` job;
    `permissions: contents: read`; `timeout-minutes: 5`. The
    always-on posture is **inherited** from ADR-015's
    subject-matter-presence rule (§Decision point 3 names #05),
    not re-litigated (ADR-017 §3). No per-fork configuration.
  - `.claude/meta/scripts/test-check-roadmap-drift.sh` — TDD
    suite (15 tests) covering all eight `specs/05` acceptance
    criteria Given/When/Then plus the multi-`adr:` `<br>`-cell
    parse, the `.ja.md` boundary, and zero-pad robustness.
    `.claude/meta/scripts/check-dangling-refs.sh` gains a
    reciprocal one-line MECE-boundary header note so the
    resolution-vs-consistency partition is discoverable from
    both sides (ADR-017 §2). Template passes its own
    `check-roadmap-drift.sh` at ship time with zero
    suppressions — the Spec's Leading metric and the
    green-by-construction requirement satisfied verbatim.
    Roadmap row #05 flips `◐ in-progress` → `☑ done`.
- Milestone #04 ships an always-on CI detector for dangling
  ADR/skill cross-references. Two artifacts:
  - `.github/workflows/dangling-ref-check.yml` — always-on,
    path-scoped workflow modeled on `skill-invariants.yml`:
    runs on every push and pull request to `main` touching
    the scanned document trees or the script/workflow
    themselves; single `check` job; `permissions: contents:
    read`; `timeout-minutes: 5`. No per-fork configuration
    variable or config file required.
  - `.claude/meta/scripts/check-dangling-refs.sh` — the
    detector script (`set -euo pipefail`, `pass`/`warn`/
    `fail_check` accumulator, `exit "$fail"`). Implements
    two checks: (1) `ADR-NNN` textual references in
    `CLAUDE.md`, ADRs, Specs, and agent files — normalized
    to 3-digit zero-pad, verified against `.claude/meta/adr/`;
    fenced code blocks and inline code spans skipped.
    (2) `.claude/`-rooted path mentions and non-reservation
    `specs/` references in `CLAUDE.md` and Specs — verified
    to resolve on disk; ADR and agent files excluded
    (historical/conceptual references). The two checks are
    MECE-bounded against `check-skill-invariants.sh` Check 4
    (per ADR-015): Check 4 owns relative-path links inside
    `SKILL.md` files; this detector owns the rest. ADR-014
    reservation-rule carve-out applied: `specs/NN-slug.md`
    references in the Roadmap `Design source` column pass
    even when the file does not yet exist on disk.
    Class A literal-`N` placeholder paths (e.g.
    `specs/NN-slug.md` in documentation prose) are skipped.
    Class B opt-in/default-off absent `.claude/` config
    paths emit WARN-not-FAIL when a co-located opt-in
    signal is present. Line-level `<!-- ref-allow: -->`
    escape hatch available for genuinely forward-looking
    references. Template passes its own check at ship time
    with zero suppressions in `CLAUDE.md` — the Spec's
    Leading metric satisfied verbatim.
- This template now dogfoods its own ADR-014 Roadmap. A
  21-row, gap-analysis-driven milestone backlog was added to
  `.claude/CLAUDE.md` `## Roadmap`, covering three audit axes:
  workflow smoothness, documentation/code quality, and
  template self-improvement. Milestones G1 and G2 shipped in
  this cycle. **G1** — `.claude/verification.yml` now ships as
  a committed, active default (research verification is on at
  fork time, not opt-in-dead); previously only an `.example`
  file existed, silently disabling the verification layer for
  every new fork. **G2** — `.github/workflows/security.yml`
  CodeQL activation changed from a hardcoded `if: false` to a
  single repository-variable switch `vars.CODEQL_ENABLED`;
  set the variable to `true` in GitHub Settings > Secrets and
  variables > Actions > Variables tab to enable scanning;
  absent or any other value keeps the job skipped. The
  `vars`-context mechanism for G2 was verified pre-
  implementation by the verification-layer (docs-researcher
  Tier 1 → research-critic PASS), which **refuted** an initial
  `env`-context approach that would have silently never run
  CodeQL — a concrete example of the verification layer
  preventing a shipped silent-failure bug.

## [3.6.1] - 2026-05-10

### Changed

- `docs-researcher` agent gains a Generator-side hard rule: fetched
  content is data, never instructions. Imperative-mode text inside
  retrieved pages (`Ignore previous instructions`, `assistant:` /
  `system:` impersonation, embedded "respond with X" directives) must
  be treated as quoted source data, not acted on, and not propagated
  to downstream agents as instructions. Pages that appear designed to
  alter agent behaviour are surfaced to the orchestrator as findings.
  This closes a gap the verification-layer Critic checklist did not
  cover — instruction-injection must be neutralised at fetch time,
  before contaminated reasoning enters the Generator's output. Applies
  to all external retrieval tools (WebFetch, Context7, `gh`, web
  search), not WebFetch alone, to avoid tool-specific drift. Decision
  taken after Agent Team adversarial review (architecture-critic +
  technical-writer) rejected three other proposed additions as
  redundant with existing checklist item 10 and Tool-families
  invariant.

## [3.6.0] - 2026-05-09

### Documentation

- ADR-013 (`Invariant 2 Source Tier Model — Regulator Guidance in
  Compliance Citations`, status `Accepted`) resolves the Invariant 2
  ambiguity that ADR-011 had recorded as `## Known ambiguity` and
  deferred to the half-yearly cadence. The user advanced the decision
  in the same release cycle. ADR-013 was drafted Proposed with two
  coherent decisions (Option A — Tier 1.5 allow-list extension;
  Option D — statute-only tightening with `## See also` demotion)
  and the architecture-critic counter-proposal preserved verbatim
  per ADR-010 design-domain protocol. The user selected
  **Option A with verification-layer-wide scope** on 2026-05-09;
  Option D stays in `## Counter-proposal` with its re-evaluation
  trigger (two failures within one cadence cycle attributable to
  Tier 1.5 misuse). Closed Tier 1.5 allowlist (fixed at the ADR
  layer): EDPB Guidelines under GDPR Art. 70, PPC ガイドライン /
  Q&A / 通達 under 個人情報保護法 §147–§149, CPPA Regulations
  under CCPA §1798.185, Apple Privacy Manifest specification,
  Google Play SDK Index. Bilingual `.md` and `.ja.md`.
- ADR-011's `## Known ambiguity` section is rewritten to
  `## Known ambiguity — Resolved by ADR-013 (2026-05-09)`,
  preserving the original ambiguity quote and pointing forward to
  the resolution. Bilingual.
- ADR-008 and ADR-010 each gain a 2026-05-09 amendment section
  recording the verification-layer-wide Tier 1.5 propagation,
  parallel to ADR-008's existing 2026-05-08 amendment for ADR-010.
  The original Decision text in those ADRs is unchanged. Bilingual.

### Added

- ADR-011 (`Compliance Checklist Skill`, status `Accepted`) and ADR-012
  (`Code Reviewer as Dispatcher to ECC Language-Specific Reviewers`,
  status `Accepted`). Both records were drafted, reviewed by the
  Agent Team (`product-manager`, `architect`, `architecture-critic`,
  `security-reviewer`, `technical-writer`, plus the new dispatcher
  `code-reviewer` itself), and accepted in this release cycle.
  ADR-012 permanently records the `architecture-critic`-generated
  counter-proposal that argued for in-repo language-specific reviewers
  instead of dispatcher delegation (Alternative B), with explicit
  re-evaluation triggers, per ADR-010's design-domain protocol.
  Bilingual `.md` and `.ja.md` for both ADRs.
- `.claude/skills/compliance-checklist/` — the Skill body that
  ADR-011 specifies. Ships default-off and refuses to run unless the
  project sets `compliance.enabled: true` and a non-empty
  `target_jurisdictions` in `.claude/compliance.yml`.
  - `SKILL.md` — overview, six invariant rules (no
    negative-applicability claims, primary-source-only citations,
    PII path refusal, default-off, project-declared jurisdictions,
    capability-based triggers), output contract, override protocol,
    half-yearly re-verification cadence (quarterly for platform).
  - `disclaimers.md` — mandatory disclaimer block in EN and JA,
    locked from override; staleness banner rendered conditionally
    after 365 days without re-verification.
  - `triggers.md` — capability-based trigger detection rules
    (`messaging`, `payments`, `pii`, `data-egress`) keyed off
    manifest dependencies and source patterns, plus PII path
    refusal globs and an output-mask regex layer.
  - `jurisdictions/JP.md` — 電気通信事業法, 特定商取引法,
    改正個人情報保護法, 資金決済法 with primary citations to
    e-Gov 法令検索.
  - `jurisdictions/EU.md` — GDPR (Reg. 2016/679 incl. Art. 3
    extraterritorial scope), ePrivacy Directive 2002/58/EC, DSA
    (Reg. 2022/2065) with primary citations to EUR-Lex and EDPB.
  - `jurisdictions/US-CA.md` — CCPA / CPRA, CalOPPA, Shine the
    Light with primary citations to California Legislative
    Information.
  - `jurisdictions/platform.md` — Apple App Store Review
    Guidelines and Google Play Policy Center with primary
    citations to the platform documentation surfaces themselves.
  Vertical-specific regimes (healthcare PHI, financial KYC, etc.)
  are explicitly deferred to existing ECC Skills (`hipaa-compliance`,
  `healthcare-phi-compliance`) and to specialized counsel.
- `.claude/compliance.yml.example` — sample per-project Skill
  activation config. Sibling to `.claude/verification.yml.example`;
  both are default-off opt-in surfaces.
- README `## Prerequisites` section (EN + JA). Documents that the
  template is designed for developers who already have ECC
  (Everything Claude Code) installed at the user level (`~/.claude/`).
  Soft prerequisite — the template still runs without ECC, but agent
  quality is degraded; the `code-reviewer` dispatcher's verdict
  always notes which delegation outcome occurred so a missing ECC
  layer is visible per review, not silent.

### Changed

- `.claude/agents/code-reviewer.md` refactored from a generic reviewer
  into a **meta-reviewer / dispatcher**. The agent now detects the
  ecosystem from project manifests and delegates language-specific
  depth to the matching ECC `*-reviewer` (`typescript-reviewer`,
  `python-reviewer`, `go-reviewer`, `rust-reviewer`, `cpp-reviewer`,
  `java-reviewer`, `kotlin-reviewer`, `flutter-reviewer`,
  `csharp-reviewer`), then layers on cross-cutting checks that no
  language-specific reviewer can perform: ADR conformance,
  workaround-marker validation (ADR-006), CLAUDE.md / agent-prompt
  structure (ADR-007), verification-layer hand-off (ADR-008/010), and
  the compliance-checklist Skill trigger (ADR-011, when enabled). Falls
  back to the original generic checklist if no ECC reviewer matches.
  Resolves the audit finding that the project's generic reviewer was
  strictly weaker than ECC's language-specific reviewers for any single
  ecosystem.
- `.claude/CLAUDE.md` — `code-reviewer` row in the Agent Team table
  updated to reflect the meta-reviewer role; Quality Gate step in
  Development Workflow updated to mention the compliance-checklist
  Skill activation conditions (default-off, opt-in per project).
- `.claude/skills/compliance-checklist/SKILL.md` Invariant 2 rewritten
  from a single-rule statement into a three-tier structure (Tier 1
  primary statute / first-party platform spec, Tier 1.5 issuing-regulator
  official interpretive guidance with closed allowlist and pairing
  rule, disqualifying secondary sources) per ADR-013. Override
  Protocol updated to reflect that Invariant 2 now carries the
  Tier 1.5 sub-rules.
- `.claude/skills/compliance-checklist/jurisdictions/EU.md`,
  `JP.md`, `platform.md` — each currently-cited regulator-guidance
  reference (EDPB Guidelines on DPIA, EDPB Guidelines 03/2022 on
  dark patterns, PPC adequate-protection list, Apple Privacy
  Manifest specification, Google Play SDK Index) annotated with a
  `[Tier 1.5]` marker, paired with the Tier 1 statute or
  platform-spec citation on the same item. Each file's preamble
  updated to describe the three-tier structure.
- `.claude/skills/verification-layer/SKILL.md` — shared invariant 3
  (primary-source-only citation) updated to reference ADR-013 as
  the Tier 1.5 single source of truth. Tier 1 allowlist remains in
  `research/checklist.md`.
- `.claude/skills/verification-layer/research/checklist.md` — adds
  a `## Tier 1.5` section after the primary-source allowlist,
  defining the closed regulator allowlist, pairing rule, exclusions,
  and topic-scope rule (Tier 1.5 applies only when the question
  intersects a delegated-regulator domain).

## [3.5.0] - 2026-05-08

### Added

- ADR-010 implementation (`Verification Layer Generalization`).
  Generalizes ADR-008's Generator-vs-Critic, primary-source-only
  philosophy across three independently-toggled domains: research,
  implementation, design.
  - `.claude/skills/verification-layer/` — replaces
    `.claude/skills/research-verification/`. Top-level `SKILL.md`
    holds the shared invariants (Generator/Critic separation,
    different tool family, primary-source-only citation, shared
    severity vocabulary, bounded iteration, per-domain opt-in).
    Per-domain subdirectories (`research/`, `implementation/`,
    `design/`) each ship `protocol.md`, `checklist.md`, and
    `failure-modes.md`.
  - `.claude/agents/adversarial-implementer.md` — new Critic agent
    for the implementation domain. Implements the same acceptance
    criteria as the implementer with a deliberately different
    approach, runs the test suite against both, and reports the
    behavioural delta. Constrained by a four-level ranking
    (control flow → idiom → library → blocked), permanent
    user-library precedence (an explicit pin disables levels 3-4
    for that task), and an environment-safety contract (no system
    tooling installation, no Docker pulls, no manifest edits).
  - `.claude/agents/architecture-critic.md` — new Critic agent
    for the design domain. For every ADR in `Status: Proposed`
    that affects downstream work, produces one concrete
    counter-proposal that takes a rejected alternative seriously
    — same Context, same constraints, different decision, full
    Consequences, citations from a different evidence base.
    Counter-proposal stays in the ADR file as permanent record
    once the ADR moves to Accepted.
  - `.claude/templates/verification-review-template.md` —
    replaces `research-review-template.md`. Per-domain sections
    (research / implementation / design) plus shared findings,
    verdict, escalation, and audit-trail blocks.
  - `.claude/verification.yml.example` — replaces
    `research-verification.yml.example`. Per-domain `enabled`
    switches; research default-on (when file present),
    implementation and design default-off, citation-discipline
    default-on.
  - `.claude/meta/scripts/check-citation-discipline.sh` — CI
    script that scans `.claude/learn/knowledge/`, `.claude/meta/adr/`,
    and `.claude/meta/prd/` for blocked secondary-source links.
    Honours an inline `<!-- cite-allow: <reason> -->` escape on
    or above the same line. Blocklist hostnames live in the
    script (CI's source of truth) and are referenced from the
    Critic allowlist (single rule, two consumers).
  - `.github/workflows/learn-invariants.yml` — extended with a
    `citation-discipline` job that runs the script above. Path
    triggers updated to cover `verification-layer/`,
    `verification.yml`, and the new script.

### Changed

- `.claude/agents/docs-researcher.md`, `orchestrator.md`,
  `research-critic.md` — paths and Skill name updated from
  `research-verification` to `verification-layer / research`.
  No behaviour change in the research domain.
- `.claude/CLAUDE.md` — Agent Team table grows by two entries
  (`adversarial-implementer`, `architecture-critic`). Workflow
  step 3 references the verification-layer SKILL with the
  three-domain framing.
- `README.md` and `README.ja.md` — `Research verification`
  section rewritten as `Verification layer (adversarial review
  across three domains)`. Project structure tree references
  `verification-layer/` and the two new Critic agents.
- `.claude/output-styles/ecc-learn.md` — section renamed from
  `Interaction with research-verification` to
  `Interaction with the verification layer`.

### Removed

- `.claude/skills/research-verification/` (renamed via `git mv`
  to `.claude/skills/verification-layer/`).
- `.claude/templates/research-review-template.md` (renamed via
  `git mv` to `.claude/templates/verification-review-template.md`).
- `.claude/research-verification.yml.example` (renamed via
  `git mv` to `.claude/verification.yml.example`).

## [3.4.0] - 2026-05-08

### Added

- ADR-009 (`Plan-First & Learning-Aware Defaults`) — accepted 2026-05-07.
  - `permissions.defaultMode: "plan"` is now set in
    `.claude/settings.json`. New sessions boot in Plan Mode by default;
    Claude proposes a plan and waits for explicit approval before any
    write or shell side effect. Toggle for the current session with
    Shift+Tab, or override per developer in `.claude/settings.local.json`.
  - `.claude/output-styles/ecc-learn.md` — bundled custom output style
    that builds on the built-in `Learning` style (`TODO(human)`
    markers) and adds short `Insight:` notes explaining *why* a
    non-obvious choice was made. Opt-in via `/output-style ecc-learn`.
  - `.claude/hooks/coaching-context.sh` — `UserPromptSubmit` hook that
    injects the active coaching style's preamble into every prompt's
    `additionalContext` when Developer Learning Mode is enabled and a
    non-`default` style is set. Fails open and is silent when Learning
    Mode is disabled, the style is `default`, or `jq` is unavailable.
  - `claude-md-authoring` Skill checklist gains an explicit
    "agent `description` is trigger-shaped" item in both the Pre- and
    Post-writing sections, codifying the convention forward. The 16
    existing agents already conform; no rewrites were necessary.
- ADR-010 (`Verification Layer Generalization`) — accepted 2026-05-07.
  Architectural decision only at this release; implementation lands
  in a follow-up.

### Changed

- `.claude/CLAUDE.md` — new `## Plan-First & Learning-Aware Defaults`
  section describes the three opt-in/default surfaces above.
- `README.md` and `README.ja.md` — Quick Start step 4 now explains
  the default Plan Mode behaviour and the optional `ecc-learn`
  output style. Project structure tree updated to include
  `.claude/output-styles/` and `.claude/hooks/`.

## [3.3.0] - 2026-05-07

### Added

- `research-verification` Skill at
  `.claude/skills/research-verification/` and a new `research-critic`
  agent for adversarial review of external-research outputs. Generator
  (`docs-researcher`) declares a Tier (T1/T2/T3) on every research
  output; Critic (`research-critic`) reviews using a *different tool
  family* and must cite at least one **primary source** the Generator
  did not — secondary sources (blogs, Q&A sites, AI summaries,
  translations of primary sources) are explicitly disallowed as the
  Critic's independent citation. Bounded GAN iteration (default 2
  rounds) with explicit escalation to the orchestrator when consensus
  is not reached. Designed to catch confirmation echo,
  secondary-source drift, and hallucinated APIs at the research step
  rather than at build/test time. See ADR-008 for the rationale.
- `.claude/skills/research-verification/SKILL.md` — protocol overview,
  Tier table, Pre/Post checklist.
- `.claude/skills/research-verification/checklist.md` — Critic
  checklist (10 items) and primary-source allowlist.
- `.claude/skills/research-verification/failure-modes.md` — five
  typical research-error patterns the checklist is designed to catch.
- `.claude/agents/research-critic.md` — new agent with
  primary-source-only citation as a hard rule.
- `.claude/templates/research-review-template.md` — output artifact
  format shared by Generator and Critic.
- `.claude/research-verification.yml.example` — opt-out config
  template (`enabled`, `max_iterations`, `default_tier`,
  `external_facts_only`). Adopters copy to
  `.claude/research-verification.yml` to activate; absent file =
  defaults apply.
- ADR-008 (`.claude/meta/adr/008-research-verification-layer.md` and
  `.ja.md`) documenting the design and the primary-source-only
  Critic constraint.

### Changed

- `.claude/CLAUDE.md` — added `research-critic` to the Agent Team
  table; expanded Workflow §3 (Research & Reuse) with a one-paragraph
  reference to the research-verification Skill (CLAUDE.md remains
  under the 200-line guard).
- `.claude/agents/docs-researcher.md` — output format aligned with
  the Critic input contract; Tier declaration documented; Generator
  role in the research-verification protocol described inline.
- `.claude/agents/orchestrator.md` — added `research-critic` to the
  delegation table and a new "Routing external research" section
  with the Tier-based routing rules and escalation flow.

## [3.2.0] - 2026-05-07

### Added

- `claude-md-authoring` Skill at `.claude/skills/claude-md-authoring/`
  for writing and reviewing `CLAUDE.md`, `README.md`, and
  `.claude/agents/*.md`. Hybrid design (per ADR-007): four invariant
  rules are inlined and dated; volatile values (numeric thresholds,
  UI surfaces) are looked up at runtime via a Context7 → URL →
  `llms.txt` chain with graceful degradation. Progressive Disclosure
  (`SKILL.md` + `invariants.md` + `docs-protocol.md` + `examples.md`)
  keeps the entry point under the Anthropic-recommended 500-line
  cap. Manual-invoke only (`disable-model-invocation: true`) — zero
  context cost unless explicitly invoked. All Anthropic-sourced facts
  in the Skill were verified on 2026-05-06 via two independent paths
  (Context7 MCP and direct URL fetch) against
  `code.claude.com/docs/en/{memory,best-practices,skills,features-overview}`.
- `.claude/meta/scripts/check-skill-invariants.sh` — CI script
  enforcing structural invariants on Skills (line cap, required
  frontmatter fields, local link resolution).
- `.github/workflows/skill-invariants.yml` — default-on workflow
  running the script on Skill changes.
- `.github/workflows/docs-freshness.yml` — default-off, monthly
  workflow that diffs `code.claude.com/docs/llms.txt` against the
  previous snapshot for re-verification triggers.
- `.github/docs-freshness.yml` — configuration for the freshness
  workflow (`enabled: false` default).
- ADR-007 (`.claude/meta/adr/007-claude-md-authoring-skill.md` and
  `.ja.md`) documenting the hybrid design decision and the
  invariant/volatile classification.
- Responsibility additions to seven agent files
  (`technical-writer`, `docs-researcher`, `architect`,
  `devops-engineer`, `code-reviewer`, `implementer`,
  `orchestrator`) anchoring the Skill into the existing workflow.
- README and `.claude/CLAUDE.md` discoverability sections.

## [3.1.0] - 2026-05-06

### Added

- Upstream-workaround tracking layer (default-off, single-switch opt-in).
  When a defect is traced to a library or framework, the template now
  codifies the lifecycle: 3-step triage (`orchestrator` +
  `docs-researcher`), code marker (`WORKAROUND-UPSTREAM(...)` placed by
  `implementer`), per-entry registry under `workarounds/NNN-*.md` (or a
  configured `registry_dir`), and a language-agnostic CI scaffold that
  flags marker/registry drift in both directions, scans expiry dates,
  and posts an idempotent (sticky) comment on Dependabot PRs touching
  tracked packages. Activation is a single config flip — no second
  toggle to remove from the workflow.
  - New: `.claude/templates/workaround-template.md`
  - New: `.github/workflows/workaround-check.yml` (config-gated)
  - New: `.github/workaround-tracker.yml` (`enabled: false` by default;
    all settings are honored — `registry_dir`, `fail_on_marker_drift`,
    `annotate_dependabot_prs`, `expiry_warning_days`)
  - New: `.claude/meta/adr/006-upstream-workaround-tracking.md` (and
    `.ja.md`)
  - New: `.claude/meta/references/upstream-workaround-tracking.md`
    (English-only by design; deliberate exception to the bilingual
    convention, consistent with `domain-taxonomy.md`)
  - Updated: seven agent files with workaround-tracking responsibilities
    (`orchestrator`, `docs-researcher`, `architect`, `implementer`,
    `code-reviewer`, `devops-engineer`, `technical-writer`)
  - Updated: `.claude/CLAUDE.md` Development Workflow with workaround
    lifecycle step and single-switch activation note
  - Updated: `README.md` and `README.ja.md` with discoverability section
  - Note: the `dependabot-annotate` job uses `pull_request_target` with
    strict actor + same-repo gates and does not check out PR head code,
    per the security discipline in ADR-006. Other jobs use the
    `pull_request` trigger.

## [3.0.0] — 2026-04-25

### Breaking

- **Repository structure fully restructured for template-repository UX.** The
  root directory now contains zero visible directories. All template-internal
  metadata (ADRs, PRDs, references, scripts, the Learning Mode runtime state)
  moved under `.claude/`. Derived projects inherit a clean slate. The complete
  v2.x → v3.0 path mapping is recorded in
  [`adr/005-template-restructure.md`](adr/005-template-restructure.md).
- ADR and spec templates moved to `.claude/templates/adr-template.md` and
  `spec-template.md` (each with a `.ja.md` bilingual counterpart). Derived
  projects decide where to place filled-in copies — the template no longer
  reserves `adr/`, `prd/`, `specs/`, or any other directory.
- The root-level `docs/` directory was removed. Derived projects are free to
  create or omit a `docs/` directory as their project demands.
- Bilingual docs now follow the `filename.md` (EN source-of-truth) +
  `filename.ja.md` (JA translation) convention throughout `.claude/meta/`,
  matching the existing `README.md` / `README.ja.md` pattern.

### Changed

- `CHANGELOG.md` at the repo root now starts from `[Unreleased]` for derived
  projects. The template's own history lives here in `.claude/meta/CHANGELOG.md`
  and the pre-v3 history in `.claude/meta/CHANGELOG.legacy.md`.
- `README.md` and `README.ja.md` rewritten from the adopter's perspective:
  release banners removed, quick-start rewritten for a new derived project, and
  the template-maintainer sections relocated to `.claude/meta/references/`.
- `.gitignore` gained language-agnostic starter patterns (OS, editor, env, logs)
  with commented hints for Node / Python / Go / Rust / Java / Kotlin stacks.
- `.github/workflows/learn-invariants.yml` updated to the new script path and
  documents the expectation that projects not using Learning Mode delete both
  this workflow and `.claude/meta/`.
- The Learning Mode runtime state moved from `learn/config.json` and
  `learn/knowledge/` to `.claude/learn/config.json` and `.claude/learn/knowledge/`
  to free the root `learn/` namespace for adopter use.

### Added

- `.claude/meta/scripts/init.sh` — interactive post-fork initializer. Replaces
  the `## About This Project` placeholder in `.claude/CLAUDE.md`, copies
  `.env.example` to `.env`, and prints a next-steps checklist.
- `.claude/templates/spec-template.md` (+ `.ja.md`) — feature spec template
  for product-manager output, complementing `adr-template.md`.
- `.claude/meta/adr/005-template-restructure.md` — records the v3 restructure
  rationale and the template-layer vs consumer-layer separation principle.

### Removed

- Root-level `learn/`, `scripts/`, and `docs/` directories. All contents
  relocated as documented in ADR-005.
- Pre-v3 release announcement banners from `README.md` and `README.ja.md`.

### Note on historical paths

ADRs and other documents under `.claude/meta/` written before v3.0.0 reference
v2.x-era paths (`docs/en/...`, `learn/...`, `scripts/...`). Those references
are preserved as historical record. The current canonical locations are listed
in [`adr/005-template-restructure.md`](adr/005-template-restructure.md).
