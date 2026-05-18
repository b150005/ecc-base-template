#!/usr/bin/env bash
# test-coverage-threshold.sh
#
# TDD test suite for coverage-threshold.sh and the coverage-gate scaffold
# (milestone #12). Creates isolated tmp fixtures and asserts expected
# exit codes / output. Covers the eight Spec acceptance criteria
# (specs/12-coverage-ci-gate.md) and the six fixture obligations ADR-019
# Neutral §(a)–(f) enumerates.
#
# Usage: bash .claude/meta/scripts/test-coverage-threshold.sh
# Exit 0 = all tests pass; exit 1 = one or more tests failed.

set -euo pipefail

SCRIPT="$(cd "$(dirname "$0")" && pwd)/coverage-threshold.sh"
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PASS_COUNT=0
FAIL_COUNT=0

# Helpers ----------------------------------------------------------------
green()  { printf '\033[32m%s\033[0m\n' "$1"; }
red()    { printf '\033[31m%s\033[0m\n' "$1"; }

pass_test() {
  PASS_COUNT=$((PASS_COUNT + 1))
  green "  [PASS] $1"
}

fail_test() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  red "  [FAIL] $1"
}

# Write a minimal CLAUDE.md fixture whose `## Testing Requirements`
# section declares the given threshold integer.
make_claude_md() {
  local dir="$1" threshold="$2"
  cat > "$dir/CLAUDE.md" <<EOF
# Project Context

## Testing Requirements

- Minimum ${threshold}% test coverage
- Unit tests for individual functions

## Code Quality Standards

- Functions: < 50 lines
EOF
}

# Write a CLAUDE.md fixture with NO canonical threshold line.
make_claude_md_no_line() {
  local dir="$1"
  cat > "$dir/CLAUDE.md" <<'EOF'
# Project Context

## Code Quality Standards

- Functions: < 50 lines
EOF
}

# ───────────────────────────────────────────────────────────────────────
# Fixture (b) [ADR-019 Neutral; Spec AC-1]: coverage AT/ABOVE threshold
# passes (exit 0) and names measured + threshold.
# ───────────────────────────────────────────────────────────────────────
t_at_or_above_passes() {
  local d; d="$(mktemp -d)"
  make_claude_md "$d" 80
  local out rc
  out="$(bash "$SCRIPT" gate 80 "$d/CLAUDE.md" 2>&1)"; rc=$?
  if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q '80%' ; then
    pass_test "coverage exactly at threshold (80 vs 80) PASSES, names both values"
  else
    fail_test "coverage exactly at threshold should pass (rc=$rc, out=$out)"
  fi

  out="$(bash "$SCRIPT" gate 92.5 "$d/CLAUDE.md" 2>&1)"; rc=$?
  if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q '92.5%'; then
    pass_test "coverage above threshold (92.5 vs 80) PASSES"
  else
    fail_test "coverage above threshold should pass (rc=$rc, out=$out)"
  fi
  rm -rf "$d"
}

# ───────────────────────────────────────────────────────────────────────
# Fixture (a) [ADR-019 Neutral; Spec AC-1]: coverage BELOW threshold
# FAILS (non-zero) with a message naming measured + threshold — a hard
# build-failing check, not an advisory warning.
# ───────────────────────────────────────────────────────────────────────
t_below_fails_naming_both() {
  local d; d="$(mktemp -d)"
  make_claude_md "$d" 80
  local out rc
  set +e
  out="$(bash "$SCRIPT" gate 73 "$d/CLAUDE.md" 2>&1)"; rc=$?
  set -e
  if [ "$rc" -ne 0 ] \
     && printf '%s' "$out" | grep -q '73%' \
     && printf '%s' "$out" | grep -q '80%' \
     && printf '%s' "$out" | grep -qi 'below'; then
    pass_test "coverage below threshold (73 vs 80) FAILS hard, names measured AND threshold"
  else
    fail_test "coverage below threshold should fail naming both (rc=$rc, out=$out)"
  fi
  rm -rf "$d"
}

# ───────────────────────────────────────────────────────────────────────
# Fixture (e) [Spec AC-2 / AC-8]: the threshold TRACKS a changed
# `## Testing Requirements` value with NO second edit — single source of
# truth. Same measured %, two different canonical thresholds, opposite
# verdicts proves the number is read from the canonical line, not a
# hardcoded literal.
# ───────────────────────────────────────────────────────────────────────
t_threshold_tracks_canonical() {
  local d85; d85="$(mktemp -d)"
  local d70; d70="$(mktemp -d)"
  make_claude_md "$d85" 85
  make_claude_md "$d70" 70
  local rc85 rc70
  set +e
  bash "$SCRIPT" gate 75 "$d85/CLAUDE.md" >/dev/null 2>&1; rc85=$?
  bash "$SCRIPT" gate 75 "$d70/CLAUDE.md" >/dev/null 2>&1; rc70=$?
  set -e
  if [ "$rc85" -ne 0 ] && [ "$rc70" -eq 0 ]; then
    pass_test "same measured 75% FAILS at canonical 85, PASSES at canonical 70 (threshold is single-sourced, not hardcoded)"
  else
    fail_test "threshold must track the canonical line (rc@85=$rc85 expected !=0, rc@70=$rc70 expected 0)"
  fi
  # `extract` returns exactly the canonical integer.
  local ext
  ext="$(bash "$SCRIPT" extract "$d85/CLAUDE.md" 2>/dev/null)"
  if [ "$ext" = "85" ]; then
    pass_test "extract returns the exact canonical integer (85)"
  else
    fail_test "extract should return 85, got '$ext'"
  fi
  rm -rf "$d85" "$d70"
}

# ───────────────────────────────────────────────────────────────────────
# Fixture (d) [ADR-019 Decision 3]: a missing `## Testing Requirements`
# canonical line FAILS CLOSED with an explicit message — never silently
# passes.
# ───────────────────────────────────────────────────────────────────────
t_missing_canonical_fails_closed() {
  local d; d="$(mktemp -d)"
  make_claude_md_no_line "$d"
  local out rc
  set +e
  out="$(bash "$SCRIPT" gate 100 "$d/CLAUDE.md" 2>&1)"; rc=$?
  set -e
  if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -qi 'fail-closed'; then
    pass_test "missing canonical line FAILS CLOSED even with measured 100% (loud, not silent)"
  else
    fail_test "missing canonical line must fail closed (rc=$rc, out=$out)"
  fi

  # extract on a wholly absent file also fails closed.
  set +e
  out="$(bash "$SCRIPT" extract "$d/nonexistent.md" 2>&1)"; rc=$?
  set -e
  if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -qi 'fail-closed'; then
    pass_test "extract on absent CLAUDE.md fails closed with explicit message"
  else
    fail_test "extract on absent file must fail closed (rc=$rc, out=$out)"
  fi
  rm -rf "$d"
}

# ───────────────────────────────────────────────────────────────────────
# Bad-input guard [Spec AC-3 boundary]: a non-numeric measured value
# fails (the caller supplies the measurement; garbage must not pass).
# ───────────────────────────────────────────────────────────────────────
t_bad_input_fails() {
  local d; d="$(mktemp -d)"
  make_claude_md "$d" 80
  local rc
  set +e
  bash "$SCRIPT" gate "9; rm -rf /" "$d/CLAUDE.md" >/dev/null 2>&1; rc=$?
  set -e
  if [ "$rc" -ne 0 ]; then
    pass_test "non-numeric / injection-shaped measured value FAILS (not silently passed)"
  else
    fail_test "bad measured input must fail (rc=$rc)"
  fi
  set +e
  bash "$SCRIPT" gate "" "$d/CLAUDE.md" >/dev/null 2>&1; rc=$?
  set -e
  if [ "$rc" -ne 0 ]; then
    pass_test "empty measured value FAILS"
  else
    fail_test "empty measured input must fail (rc=$rc)"
  fi
  rm -rf "$d"
}

# ───────────────────────────────────────────────────────────────────────
# The real repository CLAUDE.md resolves to the canonical 80.
# ───────────────────────────────────────────────────────────────────────
t_real_repo_threshold() {
  local ext
  ext="$(bash "$SCRIPT" extract "$REPO_ROOT/.claude/CLAUDE.md" 2>/dev/null || true)"
  if [ "$ext" = "80" ]; then
    pass_test "real .claude/CLAUDE.md canonical threshold extracts to 80"
  else
    fail_test "real CLAUDE.md should extract 80, got '$ext'"
  fi
}

# ───────────────────────────────────────────────────────────────────────
# Fixture (c) [Spec AC-5]: switch OFF makes the job inert — the template
# is green-by-construction. The config default is `enabled: false`; with
# the switch off the workflow's gate step never runs, so the template
# never invokes coverage-threshold.sh at all. Assert the shipped default.
# ───────────────────────────────────────────────────────────────────────
t_switch_default_off_for_template_green() {
  local cfg="$REPO_ROOT/.github/coverage-tracker.yml"
  if [ -f "$cfg" ] && grep -Eq '^[[:space:]]*enabled:[[:space:]]*false[[:space:]]*$' "$cfg"; then
    pass_test "shipped .github/coverage-tracker.yml is enabled: false (template green-by-construction, Spec AC-5)"
  else
    fail_test "coverage-tracker.yml must ship enabled: false for template green-by-construction"
  fi
  # And the config carries NO threshold-number DIRECTIVE (ADR-019
  # Decision 3 / R-02): a number in a YAML *key* would be the second
  # drifting declaration R-02 forbids. Explanatory comment prose that
  # *points at* the canonical source (e.g. "the 80% value has a single
  # source of truth: ## Testing Requirements") is documentation, not a
  # competing declaration — so the assertion scopes to non-comment,
  # non-blank directive lines only, not to any digit in any comment.
  local directives
  directives="$(grep -vE '^[[:space:]]*(#|$)' "$cfg" || true)"
  if [ -f "$cfg" ] \
     && ! printf '%s' "$directives" | grep -Eqi 'threshold|minimum|coverage[-_]?(pct|percent)|:[[:space:]]*[0-9]'; then
    pass_test "coverage-tracker.yml carries NO threshold-number directive (single-source, ADR-019 Decision 3)"
  else
    fail_test "coverage-tracker.yml must not carry a threshold-number directive"
  fi
}

# ───────────────────────────────────────────────────────────────────────
# Fixture (f) [Spec AC-6]: ci-base.yml and the four detector scripts +
# three test suites are byte-unchanged by milestone #12 (no scope bleed).
# Verified against the pre-#12-implementation HEAD (commit 1390206, the
# design-only commit).
# ───────────────────────────────────────────────────────────────────────
t_no_scope_bleed() {
  local base="1390206"
  local guarded=(
    ".github/workflows/ci-base.yml"
    ".claude/meta/scripts/check-dangling-refs.sh"
    ".claude/meta/scripts/check-roadmap-drift.sh"
    ".claude/meta/scripts/check-skill-invariants.sh"
    ".claude/meta/scripts/check-bilingual-parity.sh"
    ".claude/meta/scripts/test-check-dangling-refs.sh"
    ".claude/meta/scripts/test-check-roadmap-drift.sh"
    ".claude/meta/scripts/test-check-bilingual-parity.sh"
  )
  local bleed=0 f
  for f in "${guarded[@]}"; do
    if ! git -C "$REPO_ROOT" diff --quiet "$base" -- "$f" 2>/dev/null; then
      red "    scope bleed: $f changed since $base"
      bleed=1
    fi
  done
  if [ "$bleed" -eq 0 ]; then
    pass_test "ci-base.yml + 4 detectors + 3 test suites byte-unchanged since $base (no scope bleed, Spec AC-6)"
  else
    fail_test "milestone #12 must not modify the existing detector layer or ci-base.yml"
  fi
}

# Run ───────────────────────────────────────────────────────────────────
echo "Running coverage-threshold.sh test suite..."
echo ""
t_at_or_above_passes
t_below_fails_naming_both
t_threshold_tracks_canonical
t_missing_canonical_fails_closed
t_bad_input_fails
t_real_repo_threshold
t_switch_default_off_for_template_green
t_no_scope_bleed

echo ""
echo "  Passed: $PASS_COUNT"
echo "  Failed: $FAIL_COUNT"
echo ""
if [ "$FAIL_COUNT" -eq 0 ]; then
  green "PASS — all $PASS_COUNT tests passed"
  exit 0
else
  red "FAIL — $FAIL_COUNT test(s) failed"
  exit 1
fi
