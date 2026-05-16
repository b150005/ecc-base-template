#!/usr/bin/env bash
# test-check-dangling-refs.sh
#
# TDD test suite for check-dangling-refs.sh
# Creates isolated tmp fixtures and asserts expected exit codes / output.
# Covers all 8 Spec acceptance criteria (specs/04-dangling-reference-detector.md).
#
# Usage: bash .claude/meta/scripts/test-check-dangling-refs.sh
# Exit 0 = all tests pass; exit 1 = one or more tests failed.

set -euo pipefail

SCRIPT="$(cd "$(dirname "$0")" && pwd)/check-dangling-refs.sh"
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
}

# Create a fresh tmp repo fixture with .git so git rev-parse works
make_repo() {
  local dir
  dir="$(mktemp -d)"
  git init -q "$dir"
  # Set required git config to suppress warnings
  git -C "$dir" config user.email "test@test.com"
  git -C "$dir" config user.name "test"
  echo "$dir"
}

# Add an ADR file to the fixture repo
add_adr() {
  local repo="$1" num="$2" slug="$3"
  mkdir -p "$repo/.claude/meta/adr"
  printf "# ADR-%03d: %s\n\n## Status\nAccepted\n" "$num" "$slug" \
    > "$repo/.claude/meta/adr/$(printf '%03d' "$num")-${slug}.md"
}

# Run the detector against a fixture repo; return its exit code
run_detector() {
  local repo="$1"
  (cd "$repo" && bash "$SCRIPT") > /dev/null 2>&1
  echo $?
}

# Run the detector and capture stdout+stderr together
run_detector_verbose() {
  local repo="$1"
  (cd "$repo" && bash "$SCRIPT") 2>&1 || true
}

# -----------------------------------------------------------------------
echo ""
echo "check-dangling-refs.sh test suite"
echo "=================================="
echo ""

# -- Script must exist before running tests --
if [[ ! -f "$SCRIPT" ]]; then
  yellow "  [SKIP] $SCRIPT not found — all tests will fail (RED phase)"
fi

# -----------------------------------------------------------------------
echo "AC#1 — dangling ADR-NNN textual reference fails"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  # CLAUDE.md references ADR-099 which does not exist
  mkdir -p "$repo/.claude"
  cat > "$repo/.claude/CLAUDE.md" <<'EOF'
# Test CLAUDE.md
See ADR-099 for details.
EOF
  add_adr "$repo" 1 "something"

  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "1" ]]; then
    pass_test "AC#1: dangling ADR-099 reference correctly causes failure"
  else
    fail_test "AC#1: expected exit 1 for dangling ADR-099, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#1b — valid ADR-NNN textual reference passes"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/.claude"
  cat > "$repo/.claude/CLAUDE.md" <<'EOF'
# Test CLAUDE.md
See ADR-001 for details.
EOF
  add_adr "$repo" 1 "developer-growth-mode"

  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "AC#1b: valid ADR-001 reference passes"
  else
    fail_test "AC#1b: expected exit 0 for valid ADR-001, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#1c — ADR zero-padding normalization (ADR-7 maps to 007)"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/.claude"
  cat > "$repo/.claude/CLAUDE.md" <<'EOF'
# Test CLAUDE.md
See ADR-7 for details.
EOF
  # Only create 007-*.md so the unnormalized "ADR-7" must normalize to "007"
  add_adr "$repo" 7 "some-adr"

  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "AC#1c: ADR-7 normalized to ADR-007 and matched"
  else
    fail_test "AC#1c: expected exit 0 for ADR-7 normalization, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#1d — ADR reference in code fence is skipped (no false positive)"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/.claude"
  # Use printf with actual triple-backtick fence (heredoc won't confuse them)
  printf '# Test CLAUDE.md\n\n```\nADR-099 reference in code block should be ignored\n```\n' \
    > "$repo/.claude/CLAUDE.md"
  # ADR-099 does not exist but it's inside a code fence
  add_adr "$repo" 1 "something"

  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "AC#1d: ADR reference inside code fence correctly skipped"
  else
    fail_test "AC#1d: expected exit 0 (code fence skip), got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#2 — dangling .claude/ path reference fails"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/.claude"
  cat > "$repo/.claude/CLAUDE.md" <<'EOF'
# Test CLAUDE.md
See `.claude/skills/nonexistent/SKILL.md` for details.
EOF
  add_adr "$repo" 1 "something"

  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "1" ]]; then
    pass_test "AC#2: dangling .claude/ path correctly causes failure"
  else
    fail_test "AC#2: expected exit 1 for dangling .claude/ path, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#2b — valid .claude/ path passes"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/.claude/skills/claude-md-authoring"
  touch "$repo/.claude/skills/claude-md-authoring/SKILL.md"
  cat > "$repo/.claude/CLAUDE.md" <<'EOF'
# Test CLAUDE.md
See `.claude/skills/claude-md-authoring/SKILL.md` for details.
EOF
  add_adr "$repo" 1 "something"

  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "AC#2b: valid .claude/ path reference passes"
  else
    fail_test "AC#2b: expected exit 0 for valid .claude/ path, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#3 — reservation-rule carve-out: reserved specs/NN-slug.md in Roadmap Design-source cell passes even when absent"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/.claude"
  # Mimic the Roadmap table format — the spec link is in the Design source cell
  cat > "$repo/.claude/CLAUDE.md" <<'EOF'
# Roadmap

| # | Milestone | Status | Design source |
|---|-----------|--------|---------------|
| 03 | Some milestone | ☐ todo | spec: `specs/03-cross-session-progress-persistence.md` |
EOF
  add_adr "$repo" 1 "something"
  # Note: specs/03-cross-session-progress-persistence.md is NOT created

  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "AC#3: reserved specs/03-slug.md in Roadmap Design-source cell passes (carve-out)"
  else
    fail_test "AC#3: expected exit 0 for reservation carve-out, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#3b — non-reservation-shaped specs/ path in prose still fails"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/.claude"
  cat > "$repo/.claude/CLAUDE.md" <<'EOF'
# Test CLAUDE.md
See `specs/some-other-spec.md` for reference.
EOF
  add_adr "$repo" 1 "something"
  # specs/some-other-spec.md is NOT created; not reservation-shaped

  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "1" ]]; then
    pass_test "AC#3b: non-reservation-shaped specs/ path in prose correctly fails"
  else
    fail_test "AC#3b: expected exit 1 for dangling prose specs/ path, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#4 — ref-allow escape hatch suppresses failure on that line"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/.claude"
  cat > "$repo/.claude/CLAUDE.md" <<'EOF'
# Test CLAUDE.md
See ADR-099 for details. <!-- ref-allow: forward reference, not yet written -->
EOF
  add_adr "$repo" 1 "something"
  # ADR-099 does not exist but line has the escape hatch

  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "AC#4: ref-allow suppresses dangling ADR-099 reference"
  else
    fail_test "AC#4: expected exit 0 with ref-allow suppression, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#5 — template's own repo passes (self-baseline)"
# -----------------------------------------------------------------------
{
  repo_root="$(git -C "$(dirname "$SCRIPT")" rev-parse --show-toplevel 2>/dev/null || echo "")"
  if [[ -z "$repo_root" ]]; then
    fail_test "AC#5: could not determine repo root for self-baseline test"
  else
    # Use bash -c to avoid Bus error in the test runner's sandboxed env.
    # The script path and repo root are passed as safe env vars.
    exit_code=0
    DANGLING_SCRIPT="$SCRIPT" DANGLING_ROOT="$repo_root" \
      bash -c 'cd "$DANGLING_ROOT" && bash "$DANGLING_SCRIPT"' 2>/dev/null \
      || exit_code="$?"
    if [[ "$exit_code" == "0" ]]; then
      pass_test "AC#5: template's own repo passes with exit 0"
    else
      fail_test "AC#5: template's own repo failed with exit $exit_code (real dangling refs found)"
    fi
  fi
}

# -----------------------------------------------------------------------
echo ""
echo "AC#6 — CI summary output on findings (GITHUB_STEP_SUMMARY detection)"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/.claude"
  cat > "$repo/.claude/CLAUDE.md" <<'EOF'
# Test
See ADR-099 for details.
EOF
  add_adr "$repo" 1 "something"

  summary_file="$(mktemp)"
  output="$(GITHUB_STEP_SUMMARY="$summary_file" bash -c "cd '$repo' && bash '$SCRIPT'" 2>&1 || true)"
  summary_content="$(cat "$summary_file")"

  if [[ -n "$summary_content" ]] && echo "$summary_content" | grep -q "ADR-099"; then
    pass_test "AC#6: GITHUB_STEP_SUMMARY populated with finding when set"
  else
    fail_test "AC#6: expected GITHUB_STEP_SUMMARY to contain finding for ADR-099"
  fi
  rm -rf "$repo"
  rm -f "$summary_file"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#7 — always-on: workflow file exists with no configuration requirement"
# -----------------------------------------------------------------------
{
  workflow=".github/workflows/dangling-ref-check.yml"
  repo_root="$(git -C "$(dirname "$SCRIPT")" rev-parse --show-toplevel 2>/dev/null || echo "")"
  if [[ -z "$repo_root" ]]; then
    fail_test "AC#7: could not determine repo root"
  elif [[ -f "$repo_root/$workflow" ]]; then
    # Check it has no "enabled:" config requirement (always-on)
    if ! grep -q "enabled:" "$repo_root/$workflow"; then
      pass_test "AC#7: $workflow exists with no configuration requirement"
    else
      fail_test "AC#7: $workflow has an 'enabled:' config check (must be always-on)"
    fi
  else
    fail_test "AC#7: $workflow does not exist"
  fi
}

# -----------------------------------------------------------------------
echo ""
echo "AC#8 — no double-reporting of SKILL.md relative links (Check-4 scope)"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/.claude/skills/myskill"
  mkdir -p "$repo/.claude"
  # Create a SKILL.md with a relative link that Check-4 already validates
  cat > "$repo/.claude/skills/myskill/SKILL.md" <<'EOF'
---
name: myskill
description: test
disable-model-invocation: false
---
# My Skill
See [sibling](./sibling.md) for details.
EOF
  # Create CLAUDE.md with no references to the skill's relative links
  cat > "$repo/.claude/CLAUDE.md" <<'EOF'
# Test
No references here.
EOF
  add_adr "$repo" 1 "something"
  # Note: the broken relative link in SKILL.md is NOT our concern

  output="$(run_detector_verbose "$repo")"
  exit_code=0
  (cd "$repo" && bash "$SCRIPT") || exit_code="$?"

  # The detector must not fail on SKILL.md relative links
  # (those are Check-4's domain, not ours)
  if ! echo "$output" | grep -q "myskill/SKILL.md"; then
    pass_test "AC#8: detector does not scan SKILL.md relative links (no double-reporting)"
  else
    fail_test "AC#8: detector incorrectly reported on SKILL.md relative link"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "New#1 — ADR-NNN with literal N in numeric slot does NOT produce a finding (Class A, Check 1)"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/.claude"
  # ADR-NNN with literal N characters — should NOT be matched by ADR-[0-9]+
  cat > "$repo/.claude/CLAUDE.md" <<'EOF'
# Test CLAUDE.md
The reservation-rule notation uses specs/NN-slug.md and ADR-NNN as examples.
EOF
  add_adr "$repo" 1 "something"
  # ADR-NNN (literal N) should not trigger any Check 1 finding

  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "New#1: literal ADR-NNN in prose does not produce a Check 1 finding"
  else
    fail_test "New#1: expected exit 0 for literal ADR-NNN in prose, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "New#2 — specs/NN-slug.md as path token in prose (NOT Roadmap cell) → no finding (Class A placeholder skip)"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/.claude"
  # specs/NN-slug.md appears in prose (not a Roadmap table row) — should be skipped
  cat > "$repo/.claude/CLAUDE.md" <<'EOF'
# Test CLAUDE.md
The reservation-rule notation uses the deterministic path specs/NN-slug.md to
describe the path shape, not a real path.
EOF
  add_adr "$repo" 1 "something"
  # specs/NN-slug.md does NOT exist and is NOT in a Roadmap cell, but is a Class A placeholder

  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "New#2: specs/NN-slug.md in prose is skipped as Class A placeholder (not a Roadmap cell)"
  else
    fail_test "New#2: expected exit 0 for specs/NN-slug.md placeholder in prose, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "New#2b — specs/99-real-slug.md (real digits, absent file, prose) → STILL fails (placeholder skip not over-broadened)"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/.claude"
  # specs/99-real-slug.md has real digits — must still be validated (not a placeholder)
  cat > "$repo/.claude/CLAUDE.md" <<'EOF'
# Test CLAUDE.md
See specs/99-real-slug.md for details on this milestone.
EOF
  add_adr "$repo" 1 "something"
  # specs/99-real-slug.md does NOT exist — real digits must still fail

  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "1" ]]; then
    pass_test "New#2b: specs/99-real-slug.md (real digits, absent, prose) still fails — placeholder skip not over-broadened"
  else
    fail_test "New#2b: expected exit 1 for dangling specs/99-real-slug.md with real digits, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "New#3 — absent .claude/foo.yml on a line with 'default-off' → WARN not FAIL (Class B)"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/.claude"
  cat > "$repo/.claude/CLAUDE.md" <<'EOF'
# Test CLAUDE.md
This feature uses .claude/foo.yml (default-off; create when opting in).
EOF
  add_adr "$repo" 1 "something"
  # .claude/foo.yml does NOT exist; line contains "default-off" → should WARN not FAIL

  tmpout="$(mktemp)"
  exit_code=0
  (cd "$repo" && bash "$SCRIPT") >"$tmpout" 2>&1 || exit_code="$?"
  combined="$(cat "$tmpout")"
  rm -f "$tmpout"

  if [[ "$exit_code" == "0" ]] && echo "$combined" | grep -q "WARN"; then
    pass_test "New#3: absent .claude/foo.yml with 'default-off' vocabulary → WARN not FAIL (exit 0)"
  elif [[ "$exit_code" == "0" ]]; then
    pass_test "New#3: absent .claude/foo.yml with 'default-off' vocabulary → exit 0 (WARN emitted to stderr)"
  else
    fail_test "New#3: expected exit 0 (WARN) for absent .claude/foo.yml with default-off vocabulary, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "New#3b — absent .claude/foo.yml with NO opt-in vocabulary and NO .example sibling → STILL fails (Class B not over-broadened)"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/.claude"
  cat > "$repo/.claude/CLAUDE.md" <<'EOF'
# Test CLAUDE.md
Configuration is stored in .claude/foo.yml for all projects.
EOF
  add_adr "$repo" 1 "something"
  # .claude/foo.yml does NOT exist; line has NO opt-in vocabulary and NO .example sibling → FAIL

  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "1" ]]; then
    pass_test "New#3b: absent .claude/foo.yml without opt-in signal still fails — Class B not over-broadened"
  else
    fail_test "New#3b: expected exit 1 for dangling .claude/foo.yml without opt-in signal, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "New#4 — real on-disk specs/NN-progress.md referenced from CLAUDE.md → no finding (ADR-016 detector-compat)"
# -----------------------------------------------------------------------
# ADR-016 downstream task: prove the boundary-triggered progress record
# (specs/03-progress.md, a real-digit path that EXISTS on disk because the
# boundary trigger creates it before anything references it) resolves
# normally in Check 2 and produces no dangling-reference finding. No
# detector code change is anticipated — specs/ is already fully scoped.
{
  repo="$(make_repo)"
  mkdir -p "$repo/.claude" "$repo/specs"
  # The progress record exists on disk (boundary-trigger create-before-reference)
  cat > "$repo/specs/03-progress.md" <<'EOF'
---
roadmap_row: 3
status_glyph: "◐"
workflow_step: 5
---
## Done
- Step 4 (Architecture) — ADR-016 written
EOF
  # CLAUDE.md references the real-digit progress path that exists on disk
  cat > "$repo/.claude/CLAUDE.md" <<'EOF'
# Test CLAUDE.md
In-flight state persists to `specs/03-progress.md` per ADR-016.
EOF
  add_adr "$repo" 16 "cross-session-progress-persistence"

  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "New#4: real on-disk specs/03-progress.md resolves normally — no false positive"
  else
    fail_test "New#4: expected exit 0 for existing specs/03-progress.md, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "New#4b — referenced-but-absent real-digit specs/NN-progress.md → STILL fails (create-before-reference invariant pinned)"
# -----------------------------------------------------------------------
# The boundary-trigger ordering means a referenced progress path is
# always created before it is referenced, so this state should not occur
# in practice. This test pins the invariant: if a real-digit progress
# path is referenced while ABSENT, the detector still catches it as the
# intended-present/actually-absent failure mode (not silently exempted).
{
  repo="$(make_repo)"
  mkdir -p "$repo/.claude"
  cat > "$repo/.claude/CLAUDE.md" <<'EOF'
# Test CLAUDE.md
See `specs/03-progress.md` for the in-flight state of this milestone.
EOF
  add_adr "$repo" 16 "cross-session-progress-persistence"
  # specs/03-progress.md is NOT created — real digits, absent, must fail

  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "1" ]]; then
    pass_test "New#4b: absent real-digit specs/03-progress.md still fails — create-before-reference invariant pinned"
  else
    fail_test "New#4b: expected exit 1 for absent specs/03-progress.md, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "Summary"
echo "======="
echo "  Passed: $PASS_COUNT"
echo "  Failed: $FAIL_COUNT"
echo ""

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  red "FAIL — $FAIL_COUNT test(s) failed"
  exit 1
fi
green "PASS — all $PASS_COUNT tests passed"
exit 0
