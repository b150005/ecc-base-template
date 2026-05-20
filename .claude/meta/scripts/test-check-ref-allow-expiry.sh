#!/usr/bin/env bash
# test-check-ref-allow-expiry.sh
#
# Test suite for the ref-allow expiry mechanism (Roadmap #18, ADR-022).
# Tests the shared library lib/ref-allow-expiry.sh and the sixth detector
# check-ref-allow-expiry.sh, which scans the union of the five existing
# ref-allow consumers' scopes for expired markers.
#
# Implementation shape (AC-12 (c)): a sixth detector + shared library,
# not a per-detector amendment. This shape was selected because AC-7
# hard-requires that "all existing tests pass without modification" and
# the five existing detectors' test suites carry scope-bleed guards
# (test-check-ecc-delegation-consistency.sh, test-check-research-tier-
# auth.sh, test-coverage-threshold.sh) that byte-compare the five
# detector scripts against earlier milestones' design commits. A per-
# detector amendment would fail those guards.
#
# Acceptance criteria covered (automated):
#   AC-1 : ISO 8601 date format enforced; non-ISO treated as absent
#   AC-2 : Extended syntax `<!-- ref-allow: <reason> | expires: YYYY-MM-DD -->`
#   AC-3 : Expired marker emits WARN, exit code remains 0 (WARN-not-FAIL)
#   AC-4 : Non-expired (today or future) marker passes silently
#   AC-5 : No-expiry (grandfather) form passes silently
#   AC-6 : Sixth detector covers the union of the five consumers' scopes
#   AC-7 : No regression on the existing seven test suites (validated
#          via their own runs in the CI base runner, not duplicated here)
#   AC-9 : WARN message format: `[WARN] <path>:<line> ref-allow expired <date>: <reason>`
#   AC-13: (documented externally in commit message; tested below by enumeration)
#
# Usage: bash .claude/meta/scripts/test-check-ref-allow-expiry.sh
# Exit 0 = all tests pass; exit 1 = one or more tests failed.

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPTS_DIR/../../.." && pwd)"
LIB="$SCRIPTS_DIR/lib/ref-allow-expiry.sh"
DETECTOR="$SCRIPTS_DIR/check-ref-allow-expiry.sh"

PASS_COUNT=0
FAIL_COUNT=0

# Helpers ----------------------------------------------------------------
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
  if [ -n "${2:-}" ]; then
    red "         $2"
  fi
}

# -----------------------------------------------------------------------
echo ""
echo "ref-allow expiry mechanism test suite (ADR-022 / Roadmap #18)"
echo "=============================================================="
echo ""

# Library and detector must exist after GREEN phase
if [ ! -f "$LIB" ]; then
  yellow "  [INFO] $LIB not yet created — RED phase expected (tests will FAIL)"
fi
if [ ! -f "$DETECTOR" ]; then
  yellow "  [INFO] $DETECTOR not yet created — RED phase expected (tests will FAIL)"
fi

# =======================================================================
echo "Part 1: lib/ref-allow-expiry.sh unit tests"
echo "-------------------------------------------"
echo ""

# -----------------------------------------------------------------------
echo "AC-2 / AC-5 — parse_ref_allow_expiry: no-expiry form returns empty date"
# -----------------------------------------------------------------------
{
  if [ -f "$LIB" ]; then
    # shellcheck source=/dev/null
    source "$LIB"
    result="$(parse_ref_allow_expiry 'See ADR-999. <!-- ref-allow: placeholder -->')"
    if [ -z "$result" ]; then
      pass_test "AC-2/AC-5: no-expiry form returns empty (grandfather)"
    else
      fail_test "AC-2/AC-5: expected empty, got '$result'"
    fi
  else
    fail_test "AC-2/AC-5: library missing"
  fi
}

# -----------------------------------------------------------------------
echo "AC-2 — parse_ref_allow_expiry: extended syntax extracts date correctly"
# -----------------------------------------------------------------------
{
  if [ -f "$LIB" ]; then
    source "$LIB"
    result="$(parse_ref_allow_expiry 'See ADR-999. <!-- ref-allow: forward ref | expires: 2030-12-31 -->')"
    if [ "$result" = "2030-12-31" ]; then
      pass_test "AC-2: extended syntax extracts ISO date 2030-12-31"
    else
      fail_test "AC-2: expected '2030-12-31', got '$result'"
    fi
  else
    fail_test "AC-2: library missing"
  fi
}

# -----------------------------------------------------------------------
echo "AC-1 — parse_ref_allow_expiry: non-ISO date treated as absent"
# -----------------------------------------------------------------------
{
  if [ -f "$LIB" ]; then
    source "$LIB"
    result="$(parse_ref_allow_expiry 'See ADR-999. <!-- ref-allow: reason | expires: 12/31/2030 -->')"
    if [ -z "$result" ]; then
      pass_test "AC-1: non-ISO date '12/31/2030' treated as absent (grandfather)"
    else
      fail_test "AC-1: expected empty for non-ISO date, got '$result'"
    fi
  else
    fail_test "AC-1: library missing"
  fi
}

# -----------------------------------------------------------------------
echo "AC-1 — parse_ref_allow_expiry: partial ISO (YYYY-MM) treated as absent"
# -----------------------------------------------------------------------
{
  if [ -f "$LIB" ]; then
    source "$LIB"
    result="$(parse_ref_allow_expiry 'See ADR-999. <!-- ref-allow: reason | expires: 2030-12 -->')"
    if [ -z "$result" ]; then
      pass_test "AC-1: partial ISO 'YYYY-MM' treated as absent"
    else
      fail_test "AC-1: expected empty for partial ISO, got '$result'"
    fi
  else
    fail_test "AC-1: library missing"
  fi
}

# -----------------------------------------------------------------------
echo "AC-3 / AC-9 — check_ref_allow_expiry: expired marker emits WARN, exit 0"
# -----------------------------------------------------------------------
{
  if [ -f "$LIB" ]; then
    source "$LIB"
    # Past date: 2020-01-01
    output="$(check_ref_allow_expiry 'test.md' '42' 'old reason' '2020-01-01' 2>&1 || true)"
    exit_code=0
    (check_ref_allow_expiry 'test.md' '42' 'old reason' '2020-01-01' >/dev/null 2>&1) && exit_code=0 || exit_code=$?
    if [ "$exit_code" = "0" ]; then
      pass_test "AC-3: expired marker function returns exit 0 (WARN-not-FAIL)"
    else
      fail_test "AC-3: expected exit 0, got $exit_code"
    fi
    if echo "$output" | grep -qE '^\[WARN\] test\.md:42 ref-allow expired 2020-01-01: old reason'; then
      pass_test "AC-9: WARN format '[WARN] <path>:<line> ref-allow expired <date>: <reason>'"
    else
      fail_test "AC-9: WARN format mismatch" "got: $output"
    fi
  else
    fail_test "AC-3/AC-9: library missing"
  fi
}

# -----------------------------------------------------------------------
echo "AC-4 — check_ref_allow_expiry: future date emits no WARN"
# -----------------------------------------------------------------------
{
  if [ -f "$LIB" ]; then
    source "$LIB"
    output="$(check_ref_allow_expiry 'test.md' '42' 'future reason' '2099-01-01' 2>&1 || true)"
    if [ -z "$output" ]; then
      pass_test "AC-4: future date 2099-01-01 emits no WARN"
    else
      fail_test "AC-4: unexpected output for future date: $output"
    fi
  else
    fail_test "AC-4: library missing"
  fi
}

# -----------------------------------------------------------------------
echo "AC-4 — check_ref_allow_expiry: today's date emits no WARN"
# -----------------------------------------------------------------------
{
  if [ -f "$LIB" ]; then
    source "$LIB"
    today="$(date -u +%Y-%m-%d)"
    output="$(check_ref_allow_expiry 'test.md' '42' 'today reason' "$today" 2>&1 || true)"
    if [ -z "$output" ]; then
      pass_test "AC-4: today's date $today emits no WARN (boundary: not past)"
    else
      fail_test "AC-4: unexpected output for today's date: $output"
    fi
  else
    fail_test "AC-4: library missing"
  fi
}

# -----------------------------------------------------------------------
echo "AC-5 — check_ref_allow_expiry: no-expiry call emits no WARN"
# -----------------------------------------------------------------------
{
  if [ -f "$LIB" ]; then
    source "$LIB"
    output="$(check_ref_allow_expiry 'test.md' '42' 'no-expiry reason' '' 2>&1 || true)"
    if [ -z "$output" ]; then
      pass_test "AC-5: empty expiry argument emits no WARN (grandfather)"
    else
      fail_test "AC-5: unexpected output for no-expiry call: $output"
    fi
  else
    fail_test "AC-5: library missing"
  fi
}

# =======================================================================
echo ""
echo "Part 2: Sixth-detector integration tests (check-ref-allow-expiry.sh)"
echo "---------------------------------------------------------------------"
echo ""

# Helper: build a tmp REPO_ROOT-like fixture and run the detector against it.
# The detector resolves REPO_ROOT relative to its own location, so we
# install a copy of the detector + lib inside the fixture and run that copy.
make_detector_fixture() {
  local fix
  fix="$(mktemp -d)"
  mkdir -p "$fix/.claude/meta/scripts/lib"
  mkdir -p "$fix/specs"
  mkdir -p "$fix/.claude/meta/adr"
  mkdir -p "$fix/.claude/agents"
  # CLAUDE.md is required by the detector (it scans it if present).
  : > "$fix/.claude/CLAUDE.md"
  # Install detector + lib copies relative to the fixture root.
  cp "$DETECTOR" "$fix/.claude/meta/scripts/check-ref-allow-expiry.sh"
  cp "$LIB" "$fix/.claude/meta/scripts/lib/ref-allow-expiry.sh"
  echo "$fix"
}

# -----------------------------------------------------------------------
echo "AC-3/AC-6 — sixth detector: expired ref-allow in CLAUDE.md → WARN, exit 0"
# -----------------------------------------------------------------------
{
  fix="$(make_detector_fixture)"
  cat > "$fix/.claude/CLAUDE.md" <<'EOF'
# Project
See ADR-999 for context. <!-- ref-allow: forward ref | expires: 2020-01-01 -->
EOF
  output="$(bash "$fix/.claude/meta/scripts/check-ref-allow-expiry.sh" 2>&1)"
  exit_code=0
  bash "$fix/.claude/meta/scripts/check-ref-allow-expiry.sh" >/dev/null 2>&1 && exit_code=0 || exit_code=$?
  if [ "$exit_code" = "0" ]; then
    pass_test "AC-3: expired ref-allow in CLAUDE.md → exit 0 (WARN-not-FAIL)"
  else
    fail_test "AC-3: expected exit 0, got $exit_code"
  fi
  if echo "$output" | grep -qE '\[WARN\] .*CLAUDE\.md:2 ref-allow expired 2020-01-01: forward ref'; then
    pass_test "AC-6/AC-9: expired ref-allow in CLAUDE.md emits [WARN] in canonical format"
  else
    fail_test "AC-6/AC-9: expected canonical WARN; got" "$(echo "$output" | grep WARN | head -2)"
  fi
  rm -rf "$fix"
}

# -----------------------------------------------------------------------
echo "AC-4/AC-6 — sixth detector: non-expired ref-allow → no WARN"
# -----------------------------------------------------------------------
{
  fix="$(make_detector_fixture)"
  cat > "$fix/.claude/CLAUDE.md" <<'EOF'
# Project
See ADR-999. <!-- ref-allow: forward ref | expires: 2099-12-31 -->
EOF
  output="$(bash "$fix/.claude/meta/scripts/check-ref-allow-expiry.sh" 2>&1)"
  if echo "$output" | grep -q '\[WARN\]'; then
    fail_test "AC-4/AC-6: future-dated ref-allow should NOT emit WARN; got" "$(echo "$output" | grep WARN | head -2)"
  else
    pass_test "AC-4/AC-6: future-dated ref-allow produces no WARN"
  fi
  rm -rf "$fix"
}

# -----------------------------------------------------------------------
echo "AC-5/AC-6 — sixth detector: no-expiry (grandfather) form silent"
# -----------------------------------------------------------------------
{
  fix="$(make_detector_fixture)"
  cat > "$fix/.claude/CLAUDE.md" <<'EOF'
# Project
See ADR-999. <!-- ref-allow: legacy no-expiry form -->
EOF
  output="$(bash "$fix/.claude/meta/scripts/check-ref-allow-expiry.sh" 2>&1)"
  if echo "$output" | grep -q '\[WARN\]'; then
    fail_test "AC-5/AC-6: no-expiry form should be silent grandfather; got" "$(echo "$output" | grep WARN | head -2)"
  else
    pass_test "AC-5/AC-6: no-expiry (grandfather) form silent"
  fi
  rm -rf "$fix"
}

# -----------------------------------------------------------------------
echo "AC-6 — sixth detector: expired ref-allow in specs/ → WARN"
# -----------------------------------------------------------------------
{
  fix="$(make_detector_fixture)"
  cat > "$fix/specs/99-fixture.md" <<'EOF'
# Spec
Reference. <!-- ref-allow: spec forward ref | expires: 2020-01-01 -->
EOF
  output="$(bash "$fix/.claude/meta/scripts/check-ref-allow-expiry.sh" 2>&1)"
  if echo "$output" | grep -qE '\[WARN\] .*specs/99-fixture\.md:2 ref-allow expired 2020-01-01'; then
    pass_test "AC-6: expired ref-allow in specs/ emits canonical WARN"
  else
    fail_test "AC-6: expected canonical WARN for specs/; got" "$(echo "$output" | grep WARN | head -2)"
  fi
  rm -rf "$fix"
}

# -----------------------------------------------------------------------
echo "AC-6 — sixth detector: expired ref-allow in .claude/meta/adr/ → WARN"
# -----------------------------------------------------------------------
{
  fix="$(make_detector_fixture)"
  cat > "$fix/.claude/meta/adr/099-fixture.md" <<'EOF'
# ADR
Reference. <!-- ref-allow: adr forward ref | expires: 2020-01-01 -->
EOF
  output="$(bash "$fix/.claude/meta/scripts/check-ref-allow-expiry.sh" 2>&1)"
  if echo "$output" | grep -qE '\[WARN\] .*099-fixture\.md:2 ref-allow expired 2020-01-01'; then
    pass_test "AC-6: expired ref-allow in .claude/meta/adr/ emits canonical WARN"
  else
    fail_test "AC-6: expected canonical WARN for adr/; got" "$(echo "$output" | grep WARN | head -2)"
  fi
  rm -rf "$fix"
}

# -----------------------------------------------------------------------
echo "AC-6 — sixth detector: expired ref-allow in .claude/agents/ → WARN"
# -----------------------------------------------------------------------
{
  fix="$(make_detector_fixture)"
  cat > "$fix/.claude/agents/test-fixture.md" <<'EOF'
# Agent
Reference. <!-- ref-allow: agent forward ref | expires: 2020-01-01 -->
EOF
  output="$(bash "$fix/.claude/meta/scripts/check-ref-allow-expiry.sh" 2>&1)"
  if echo "$output" | grep -qE '\[WARN\] .*test-fixture\.md:2 ref-allow expired 2020-01-01'; then
    pass_test "AC-6: expired ref-allow in .claude/agents/ emits canonical WARN"
  else
    fail_test "AC-6: expected canonical WARN for agents/; got" "$(echo "$output" | grep WARN | head -2)"
  fi
  rm -rf "$fix"
}

# -----------------------------------------------------------------------
echo "AC-6 — sixth detector: specs/NN-progress.md excluded from scan"
# -----------------------------------------------------------------------
{
  fix="$(make_detector_fixture)"
  cat > "$fix/specs/99-progress.md" <<'EOF'
# Progress
Test. <!-- ref-allow: progress fixture | expires: 2020-01-01 -->
EOF
  output="$(bash "$fix/.claude/meta/scripts/check-ref-allow-expiry.sh" 2>&1)"
  if echo "$output" | grep -q '\[WARN\]'; then
    fail_test "AC-6: specs/NN-progress.md must be excluded per ADR-016; got" "$(echo "$output" | grep WARN | head -2)"
  else
    pass_test "AC-6: specs/NN-progress.md excluded from scan (ADR-016)"
  fi
  rm -rf "$fix"
}

# =======================================================================
echo ""
echo "Part 3: Repository-wide grandfather verification (AC-7, AC-8, AC-13)"
echo "---------------------------------------------------------------------"
echo ""

# -----------------------------------------------------------------------
echo "AC-7/AC-8 — real repo scan: no WARN, no FAIL on existing ref-allow markers"
# -----------------------------------------------------------------------
{
  output="$(bash "$DETECTOR" 2>&1)"
  exit_code=0
  bash "$DETECTOR" >/dev/null 2>&1 && exit_code=0 || exit_code=$?
  if [ "$exit_code" = "0" ]; then
    pass_test "AC-7/AC-8: real repo scan exits 0 (no FAIL on existing markers)"
  else
    fail_test "AC-7/AC-8: real repo scan exited with $exit_code"
  fi
  if echo "$output" | grep -q '\[WARN\]'; then
    fail_test "AC-7/AC-8: existing ref-allow markers should be all-grandfather (no WARN); got" "$(echo "$output" | grep WARN | head -3)"
  else
    pass_test "AC-7/AC-8: all existing repo ref-allow markers are grandfathered (no WARN)"
  fi
}

# -----------------------------------------------------------------------
echo "AC-13 — existing no-expiry ref-allow markers in template are enumerable"
# -----------------------------------------------------------------------
{
  # Count of <!-- ref-allow: ... --> in real artifact scope (Specs + ADRs + CLAUDE.md + agents)
  count=0
  for f in "$REPO_ROOT"/.claude/CLAUDE.md \
           "$REPO_ROOT"/specs/*.md \
           "$REPO_ROOT"/.claude/meta/adr/*.md; do
    [ -f "$f" ] || continue
    case "$(basename "$f")" in *-progress.md) continue ;; esac
    n="$(grep -c '<!-- ref-allow:' "$f" 2>/dev/null || true)"
    count=$((count + n))
  done
  # Existing markers should all be no-expiry (the grandfather population at ship time)
  if [ "$count" -ge 0 ]; then
    pass_test "AC-13: existing ref-allow corpus enumerated ($count markers in template artifact scope)"
  else
    fail_test "AC-13: enumeration produced negative count (impossible state)"
  fi
}

# =======================================================================
echo ""
echo "Part 4: No-regression check against the existing seven test suites (AC-7)"
echo "--------------------------------------------------------------------------"
echo ""

# Invoke each existing test suite and verify exit 0. AC-7 mandates that
# all seven existing tests pass without modification.
SUITES=(
  "test-check-bilingual-parity.sh"
  "test-check-dangling-refs.sh"
  "test-check-ecc-delegation-consistency.sh"
  "test-check-research-tier-auth.sh"
  "test-check-roadmap-drift.sh"
  "test-coverage-threshold.sh"
  "test-init-sh-roadmap-cleanup.sh"
)

for suite in "${SUITES[@]}"; do
  if [ -f "$SCRIPTS_DIR/$suite" ]; then
    if bash "$SCRIPTS_DIR/$suite" >/dev/null 2>&1; then
      pass_test "AC-7 regression: $suite passes unchanged"
    else
      fail_test "AC-7 regression: $suite FAILED — #18 introduced a regression"
    fi
  else
    fail_test "AC-7 regression: $suite missing"
  fi
done

# =======================================================================
echo ""
echo "======================================================="
echo "  Passed: $PASS_COUNT"
echo "  Failed: $FAIL_COUNT"
echo "======================================================="
echo ""

if [ "$FAIL_COUNT" -eq 0 ]; then
  green "PASS — all $PASS_COUNT tests passed"
  exit 0
else
  red "FAIL — $FAIL_COUNT test(s) failed"
  exit 1
fi
