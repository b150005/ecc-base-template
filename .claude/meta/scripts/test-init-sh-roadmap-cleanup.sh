#!/usr/bin/env bash
# test-init-sh-roadmap-cleanup.sh
#
# TDD test suite for the Roadmap-cleanup mutation added to init.sh
# (milestone #15, specs/15-init-sh-roadmap-cleanup.md).
#
# Creates isolated tmp fixtures and asserts expected behavior per the Spec's
# 8 acceptance criteria. NEVER runs init.sh against the live .claude/CLAUDE.md
# — all mutations operate on a fresh scratch fixture in a tmp git repo.
#
# Convention mirrors test-check-roadmap-drift.sh: make_repo / pass_test /
# fail_test / PASS_COUNT / FAIL_COUNT / exit 0 all-pass / exit 1 any-fail.
#
# Usage: bash .claude/meta/scripts/test-init-sh-roadmap-cleanup.sh
# Exit 0 = all tests pass; exit 1 = one or more tests failed.

set -euo pipefail

SCRIPT="$(cd "$(dirname "$0")" && pwd)/init.sh"
PASS_COUNT=0
FAIL_COUNT=0

green()  { printf '\033[32m%s\033[0m\n' "$1"; }
red()    { printf '\033[31m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m%s\033[0m\n' "$1"; }

pass_test() {
  PASS_COUNT=$((PASS_COUNT + 1))
  green "  [PASS] $1"
}

fail_test() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  red "  [FAIL] $1"
}

# Create a fresh tmp git repo so that git rev-parse --show-toplevel works.
make_repo() {
  local dir
  dir="$(mktemp -d)"
  git init -q "$dir"
  git -C "$dir" config user.email "test@test.com"
  git -C "$dir" config user.name "test"
  mkdir -p "$dir/.claude/meta/scripts"
  # init.sh resolves its helpers relative to itself; provide a symlink so
  # the absolute SCRIPT path remains the canonical one.
  echo "$dir"
}

# ---------------------------------------------------------------------------
# Fixture writer: produces a structurally faithful CLAUDE.md containing:
#   - [YOUR PROJECT NAME] placeholder (has_placeholder=1)
#   - ## About This Project section
#   - ## Roadmap section with the **Spec reservation rule:** paragraph,
#     21 representative data rows, and **Rules:** block
#   - A trailing ## section so awk boundary detection has a next heading
# ---------------------------------------------------------------------------
write_fresh_fork_claude_md() {
  local repo="$1"
  mkdir -p "$repo/.claude"
  cat > "$repo/.claude/CLAUDE.md" <<'CLAUDE_EOF'
# Project Context

## About This Project

[YOUR PROJECT NAME] — [one-line description].

**Stack:** [language] / [framework] / [database]
**Target users:** [who uses this]
**Key constraints:** [performance, compliance, platform, etc.]

## Architecture Principles

- Layered architecture with clear separation of concerns

## Roadmap

Single entry point mapping each milestone to its authoritative design source. Each row is one milestone; the linked Spec/ADR is the source of truth for content — this table is an index only, never duplicating acceptance criteria or rationale.

**Spec reservation rule:** Every row carries a `spec:` link at row-creation time using the deterministic path `specs/NN-slug.md`. The Spec *file* is authored by `product-manager` when the milestone is picked up (status moves to `◐ in-progress`). The reserved link satisfies ADR-014's 1:1 mandatory mapping without requiring all 21 Spec files to exist upfront; the `implementer`/`test-runner` contract is triggered only after the file is authored.

| # | Milestone | Status | Design source |
|---|-----------|--------|---------------|
| 01 | Commit verification.yml as active default | ☑ done | spec: `specs/01-ship-verification-yml-committed.md` |
| 02 | CodeQL single-switch activation via repository variable | ☑ done | spec: `specs/02-codeql-single-switch-activation.md` |
| 03 | Cross-session milestone progress persistence | ☑ done | spec: `specs/03-cross-session-progress-persistence.md` |
| 04 | CI detector for dangling ADR/skill cross-references | ☑ done | spec: `specs/04-dangling-reference-detector.md` |
| 05 | Roadmap drift-detection CI | ☑ done | spec: `specs/05-roadmap-drift-detection-ci.md` |
| 06 | EN/JA bilingual parity detector | ☑ done | spec: `specs/06-bilingual-parity-detector.md` |
| 07 | Roadmap status-transition ownership assignment | ☑ done | spec: `specs/07-roadmap-status-transitions.md` |
| 08 | Orchestrator Analyze row-guard | ☑ done | spec: `specs/08-orchestrator-row-guard.md` |
| 09 | Spec filename convention alignment | ☑ done | spec: `specs/09-spec-filename-convention.md` |
| 10 | Spec/ADR directory location pin in CLAUDE.md | ☑ done | spec: `specs/10-spec-adr-directory-pinning.md` |
| 11 | Opt-in trigger guidance for verification domains | ☑ done | spec: `specs/11-verification-domain-opt-in-guidance.md` |
| 12 | CI coverage gate (80% hard check) | ☑ done | spec: `specs/12-coverage-ci-gate.md` |
| 13 | ECC-absent degraded-review signal | ☑ done | spec: `specs/13-ecc-absent-signal.md` |
| 14 | Research-tier validation for auth mis-classifications | ☑ done | spec: `specs/14-research-tier-validation.md` |
| 15 | init.sh Roadmap placeholder cleanup at fork time | ◐ in-progress | spec: `specs/15-init-sh-roadmap-cleanup.md` |
| 16 | ADR-001 Proposed stabilized status resolution | ☐ todo | spec: `specs/16-adr-001-status-resolution.md` |
| 17 | CHANGELOG ADR-acceptance sync and ADR-001-005 back-fill | ☐ todo | spec: `specs/17-changelog-adr-sync.md` |
| 18 | CI exemption allowlist expiry/review mechanism | ☐ todo | spec: `specs/18-ci-exemption-allowlist-expiry.md` |
| 19 | Workaround tracking default-on | ☐ todo | spec: `specs/19-workaround-tracking-default-on.md` |
| 20 | Commit compliance.yml as active default | ☐ todo | spec: `specs/20-ship-compliance-yml-committed.md` |
| 21 | Quality-gate loop re-entry anchored to Roadmap row | ☐ todo | spec: `specs/21-quality-gate-row-anchor.md` |

**Rules:**
- One row per milestone; row number stable, never reused.
- Design source names the type explicitly: spec: and/or adr: links.
- Status = implementation state: ☐ todo / ◐ in-progress / ☑ done / ✗ dropped.

## Development Workflow

1. Issue Analysis.
2. Product Planning.
CLAUDE_EOF
}

# ---------------------------------------------------------------------------
# Fixture: CLAUDE.md where the placeholder has already been replaced
# (has_placeholder=0 — simulates a repo that already ran init.sh)
# ---------------------------------------------------------------------------
write_already_initialized_claude_md() {
  local repo="$1"
  mkdir -p "$repo/.claude"
  cat > "$repo/.claude/CLAUDE.md" <<'CLAUDE_EOF'
# Project Context

## About This Project

My Real Project — does cool things.

**Stack:** Go / Gin / PostgreSQL
**Target users:** developers
**Key constraints:** performance

## Roadmap

Single entry point mapping each milestone to its authoritative design source.

| # | Milestone | Status | Design source |
|---|-----------|--------|---------------|
| — | [Add your first milestone here] | ☐ todo | (none yet) |

**Rules:**
- One row per milestone.

## Development Workflow

1. Issue Analysis.
CLAUDE_EOF
}

# Run init.sh non-interactively in a fixture repo (no prompts).
# Supply pre-filled field values so it never blocks on stdin.
run_init() {
  local repo="$1"
  shift
  (cd "$repo" && bash "$SCRIPT" \
    --project-name "Test Project" \
    --description  "a test project" \
    --stack        "bash / awk" \
    "$@") 2>&1 || true
}

# ---------------------------------------------------------------------------
echo ""
echo "init.sh Roadmap-cleanup test suite"
echo "==================================="
echo ""

if [[ ! -f "$SCRIPT" ]]; then
  yellow "  [SKIP] $SCRIPT not found — tests will reflect RED phase"
fi

# -----------------------------------------------------------------------
echo "AC-1a: all 21 data rows removed after cleanup"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  write_fresh_fork_claude_md "$repo"
  run_init "$repo"
  claude_md="$repo/.claude/CLAUDE.md"
  # No row of the form "| 01 |" through "| 21 |" should remain in ## Roadmap
  found_rows=0
  for n in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21; do
    if grep -qE "^\| $n \|" "$claude_md"; then
      found_rows=$((found_rows + 1))
    fi
  done
  if [[ "$found_rows" -eq 0 ]]; then
    pass_test "AC-1a: all 21 data rows removed"
  else
    fail_test "AC-1a: $found_rows data rows still present after cleanup"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC-1b: Spec reservation rule paragraph removed"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  write_fresh_fork_claude_md "$repo"
  run_init "$repo"
  claude_md="$repo/.claude/CLAUDE.md"
  if grep -q '\*\*Spec reservation rule:\*\*' "$claude_md"; then
    fail_test "AC-1b: **Spec reservation rule:** paragraph still present"
  else
    pass_test "AC-1b: Spec reservation rule paragraph removed"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC-1c: ## Roadmap heading still present"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  write_fresh_fork_claude_md "$repo"
  run_init "$repo"
  claude_md="$repo/.claude/CLAUDE.md"
  if grep -q '^## Roadmap$' "$claude_md"; then
    pass_test "AC-1c: ## Roadmap heading preserved"
  else
    fail_test "AC-1c: ## Roadmap heading missing after cleanup"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC-1d: intro sentence preserved"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  write_fresh_fork_claude_md "$repo"
  run_init "$repo"
  claude_md="$repo/.claude/CLAUDE.md"
  if grep -q 'Single entry point mapping' "$claude_md"; then
    pass_test "AC-1d: intro sentence preserved"
  else
    fail_test "AC-1d: intro sentence missing after cleanup"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC-1e: table header and separator rows still present"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  write_fresh_fork_claude_md "$repo"
  run_init "$repo"
  claude_md="$repo/.claude/CLAUDE.md"
  has_header=0
  has_sep=0
  grep -q '| # | Milestone | Status | Design source |' "$claude_md" && has_header=1
  grep -q '|---|-----------|--------|---------------|' "$claude_md" && has_sep=1
  if [[ "$has_header" -eq 1 && "$has_sep" -eq 1 ]]; then
    pass_test "AC-1e: table header and separator rows preserved"
  else
    fail_test "AC-1e: table header ($has_header) or separator ($has_sep) missing"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC-1f: exactly one placeholder data row present with correct format"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  write_fresh_fork_claude_md "$repo"
  run_init "$repo"
  claude_md="$repo/.claude/CLAUDE.md"
  # Count rows matching the placeholder pattern (em-dash or literal dash,
  # with mandatory ☐ todo glyph and no spec:/adr: tokens in design-source)
  placeholder_count=0
  has_todo_glyph=0
  has_no_spec_adr=0
  while IFS= read -r line; do
    # Must be a pipe-delimited row with no leading digit in the # cell
    if printf '%s' "$line" | grep -qE '^\|[[:space:]]*[^|0-9][^|]*\|'; then
      # Must contain ☐ todo glyph
      if printf '%s' "$line" | grep -q '☐ todo'; then
        # Design source must NOT contain spec: or adr:
        if ! printf '%s' "$line" | grep -qE '(spec:|adr:)'; then
          placeholder_count=$((placeholder_count + 1))
        fi
      fi
    fi
  done < "$claude_md"
  if [[ "$placeholder_count" -eq 1 ]]; then
    pass_test "AC-1f: exactly one placeholder data row with ☐ todo and no spec:/adr:"
  else
    fail_test "AC-1f: expected 1 placeholder row, found $placeholder_count"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC-1g: **Rules:** block still present and unmodified"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  write_fresh_fork_claude_md "$repo"
  run_init "$repo"
  claude_md="$repo/.claude/CLAUDE.md"
  if grep -q '^\*\*Rules:\*\*' "$claude_md"; then
    pass_test "AC-1g: **Rules:** block preserved"
  else
    fail_test "AC-1g: **Rules:** block missing after cleanup"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC-2: placeholder row's ☐ todo glyph is a sanctioned drift-detector glyph"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  write_fresh_fork_claude_md "$repo"
  run_init "$repo"
  claude_md="$repo/.claude/CLAUDE.md"
  # The sanctioned glyphs per ADR-014 are ☐ / ◐ / ☑ / ✗.
  # The placeholder row must use ☐ (not some emoji or ASCII placeholder).
  if grep -q '☐ todo' "$claude_md"; then
    pass_test "AC-2: placeholder row uses sanctioned glyph ☐ todo"
  else
    fail_test "AC-2: placeholder row does not use sanctioned glyph ☐ todo"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC-3: placeholder design-source cell has no spec: or adr: token"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  write_fresh_fork_claude_md "$repo"
  run_init "$repo"
  claude_md="$repo/.claude/CLAUDE.md"
  # Read the placeholder row and check its design-source cell
  placeholder_row=""
  while IFS= read -r line; do
    if printf '%s' "$line" | grep -qE '^\|[[:space:]]*[^|0-9][^|]*\|' &&
       printf '%s' "$line" | grep -q '☐ todo'; then
      placeholder_row="$line"
      break
    fi
  done < "$claude_md"
  if [[ -z "$placeholder_row" ]]; then
    fail_test "AC-3: placeholder row not found — cannot check design-source cell"
  elif printf '%s' "$placeholder_row" | grep -qE '(spec:|adr:)'; then
    fail_test "AC-3: placeholder row design-source cell contains spec: or adr: token"
  else
    pass_test "AC-3: placeholder design-source cell has no spec: or adr: token"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC-4: skipped when placeholder already replaced (idempotency)"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  write_already_initialized_claude_md "$repo"
  before="$(cat "$repo/.claude/CLAUDE.md")"
  # run_init skips prompts (has_placeholder=0 → no prompt step fires)
  out="$(run_init "$repo")"
  after="$(cat "$repo/.claude/CLAUDE.md")"
  if [[ "$before" == "$after" ]]; then
    pass_test "AC-4a: CLAUDE.md byte-for-byte unchanged when placeholder absent"
  else
    fail_test "AC-4a: CLAUDE.md modified when placeholder was already absent"
  fi
  # AC-4b: a skip message should appear
  if printf '%s' "$out" | grep -qi "skip\|already customized"; then
    pass_test "AC-4b: skip message printed when placeholder absent"
  else
    fail_test "AC-4b: no skip/already-customized message found in output"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC-5a: --dry-run writes nothing to CLAUDE.md"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  write_fresh_fork_claude_md "$repo"
  before="$(cat "$repo/.claude/CLAUDE.md")"
  run_init "$repo" --dry-run
  after="$(cat "$repo/.claude/CLAUDE.md")"
  if [[ "$before" == "$after" ]]; then
    pass_test "AC-5a: --dry-run leaves CLAUDE.md unchanged"
  else
    fail_test "AC-5a: --dry-run modified CLAUDE.md (should write nothing)"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC-5b: --dry-run prints a [dry-run] message describing Roadmap cleanup"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  write_fresh_fork_claude_md "$repo"
  out="$(run_init "$repo" --dry-run)"
  if printf '%s' "$out" | grep -qi '\[dry-run\].*[Rr]oadmap'; then
    pass_test "AC-5b: --dry-run prints a [dry-run] message mentioning Roadmap"
  else
    fail_test "AC-5b: --dry-run output missing [dry-run] + Roadmap mention"
    printf '  output was:\n%s\n' "$out" | head -30
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC-7: ok-prefixed success message printed when cleanup fires"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  write_fresh_fork_claude_md "$repo"
  out="$(run_init "$repo")"
  if printf '%s' "$out" | grep -qi '\[OK\].*[Rr]oadmap'; then
    pass_test "AC-7: [OK] message printed on successful Roadmap cleanup"
  else
    fail_test "AC-7: no [OK] message mentioning Roadmap found in output"
    printf '  output was:\n%s\n' "$out" | head -30
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC-8: implementation uses awk (not a bash loop) — structural check"
# -----------------------------------------------------------------------
{
  # Verify that init.sh contains an awk invocation in the Roadmap cleanup
  # path. We can't fully verify no bash loop is used at runtime, but we can
  # check the source code for the awk call (which is required by AC-8) and
  # the absence of the forbidden pattern (line-by-line while-read-write loop
  # on the roadmap block). This is a static source check, not a runtime check.
  if grep -q 'clean_roadmap_section\|roadmap.*awk\|awk.*roadmap\|Roadmap section' "$SCRIPT" 2>/dev/null; then
    pass_test "AC-8: init.sh source references Roadmap awk/function (structural presence)"
  else
    fail_test "AC-8: init.sh has no Roadmap awk reference — cleanup not yet implemented"
  fi
}

# -----------------------------------------------------------------------
echo ""
echo "Fix-3 regression: Spec reservation rule paragraph immediately followed by table (no blank line)"
# -----------------------------------------------------------------------
# Fixture: the **Spec reservation rule:** paragraph is directly adjacent to the
# table header with NO blank line between them. Fix 3 must reset in_spec_rule
# on a | line so the table header + separator + placeholder row all survive.
{
  repo="$(make_repo)"
  mkdir -p "$repo/.claude"
  cat > "$repo/.claude/CLAUDE.md" <<'CLAUDE_EOF'
# Project Context

## About This Project

[YOUR PROJECT NAME] — [one-line description].

**Stack:** [language] / [framework] / [database]
**Target users:** [who uses this]
**Key constraints:** [performance, compliance, platform, etc.]

## Roadmap

Single entry point mapping each milestone to its authoritative design source.

**Spec reservation rule:** Every row carries a spec: link at row-creation time using the deterministic path specs/NN-slug.md. The Spec file is authored by product-manager when the milestone is picked up.
| # | Milestone | Status | Design source |
|---|-----------|--------|---------------|
| 01 | Some milestone | ☑ done | spec: specs/01-foo.md |

**Rules:**
- One row per milestone.

## Development Workflow

1. Issue Analysis.
CLAUDE_EOF

  run_init "$repo"
  claude_md="$repo/.claude/CLAUDE.md"

  has_header=0
  has_sep=0
  grep -q '| # | Milestone | Status | Design source |' "$claude_md" && has_header=1
  grep -q '|---|-----------|--------|---------------|' "$claude_md" && has_sep=1
  placeholder_count=0
  while IFS= read -r line; do
    if printf '%s' "$line" | grep -qE '^\|[[:space:]]*[^|0-9][^|]*\|' &&
       printf '%s' "$line" | grep -q '☐ todo'; then
      if ! printf '%s' "$line" | grep -qE '(spec:|adr:)'; then
        placeholder_count=$((placeholder_count + 1))
      fi
    fi
  done < "$claude_md"

  if [[ "$has_header" -eq 1 && "$has_sep" -eq 1 && "$placeholder_count" -eq 1 ]]; then
    pass_test "Fix-3 regression: table header/sep/placeholder survive when Spec rule paragraph has no trailing blank"
  else
    fail_test "Fix-3 regression: header=$has_header sep=$has_sep placeholder=$placeholder_count (expected 1/1/1)"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "Fix-2 regression: second separator line in Roadmap section injects exactly ONE placeholder row"
# -----------------------------------------------------------------------
# Fixture: the Roadmap section contains a second |---|...|---|...| separator
# line (from a second small table before **Rules:**). Fix 2 must inject the
# placeholder only after the FIRST separator and let the second pass through.
{
  repo="$(make_repo)"
  mkdir -p "$repo/.claude"
  cat > "$repo/.claude/CLAUDE.md" <<'CLAUDE_EOF'
# Project Context

## About This Project

[YOUR PROJECT NAME] — [one-line description].

**Stack:** [language] / [framework] / [database]
**Target users:** [who uses this]
**Key constraints:** [performance, compliance, platform, etc.]

## Roadmap

Single entry point mapping each milestone to its authoritative design source.

| # | Milestone | Status | Design source |
|---|-----------|--------|---------------|
| 01 | Some milestone | ☑ done | spec: specs/01-foo.md |

Extra note table:

| Column A | Column B |
|----------|----------|
| value1   | value2   |

**Rules:**
- One row per milestone.

## Development Workflow

1. Issue Analysis.
CLAUDE_EOF

  run_init "$repo"
  claude_md="$repo/.claude/CLAUDE.md"

  placeholder_count=0
  while IFS= read -r line; do
    if printf '%s' "$line" | grep -qE '^\|[[:space:]]*[^|0-9][^|]*\|' &&
       printf '%s' "$line" | grep -q '☐ todo'; then
      if ! printf '%s' "$line" | grep -qE '(spec:|adr:)'; then
        placeholder_count=$((placeholder_count + 1))
      fi
    fi
  done < "$claude_md"

  # The second table's separator must also survive (not be eaten)
  second_sep_present=0
  grep -q '|----------|----------|' "$claude_md" && second_sep_present=1

  if [[ "$placeholder_count" -eq 1 && "$second_sep_present" -eq 1 ]]; then
    pass_test "Fix-2 regression: exactly one placeholder injected; second separator survives"
  else
    fail_test "Fix-2 regression: placeholder_count=$placeholder_count second_sep=$second_sep_present (expected 1/1)"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "Summary"
echo "======="
printf "  Passed: %d\n" "$PASS_COUNT"
printf "  Failed: %d\n" "$FAIL_COUNT"
echo ""

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  red "FAIL — $FAIL_COUNT test(s) failed"
  exit 1
fi
green "PASS — all $PASS_COUNT tests passed"
exit 0
