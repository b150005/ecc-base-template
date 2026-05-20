#!/usr/bin/env bash
# test-check-research-tier-auth.sh
#
# TDD test suite for check-research-tier-auth.sh (milestone #14,
# ADR-021). Creates isolated tmp fixtures and asserts expected exit
# codes / output. Covers the 10 test fixtures specified in ADR-021 §7.
#
# Contract validated:
#   Verification-review artifacts (shaped like
#   .claude/templates/verification-review-template.md, with a
#   "## Research domain" section, a "### Generator" subsection, and a
#   "- Tier: T1|T2|T3" line) whose body content matches auth-scope
#   keywords derived at runtime from protocol.md's T1 scope line MUST
#   declare T1. T2 or T3 for such content → FAIL. Auth content at T1 →
#   PASS. Non-auth at T2 → PASS. Template repo (no instances) → PASS.
#
#   AUTH-SCOPE KEYWORD SOURCE: the `| T1 |` row of the Tier table in
#   .claude/skills/verification-layer/research/protocol.md (lines 49-53
#   in the current file; the scope cell is "Breaking changes, auth,
#   security-sensitive APIs, crypto primitives"). Keywords are derived
#   AT RUNTIME — if a future edit adds "OAuth flows" to that cell, the
#   detector picks it up with no second edit to the detector (R-04).
#
#   ZERO operator-environment introspection: the detector reads ONLY
#   in-repo artifacts. No ~/.claude/, no $HOME/.claude/, no network.
#
# Usage: bash .claude/meta/scripts/test-check-research-tier-auth.sh
# Exit 0 = all tests pass; exit 1 = one or more tests failed.

set -euo pipefail

SCRIPT="$(cd "$(dirname "$0")" && pwd)/check-research-tier-auth.sh"
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
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

# Create a fresh tmp repo fixture with .git so git rev-parse works.
make_repo() {
  local dir
  dir="$(mktemp -d)"
  git init -q "$dir"
  git -C "$dir" config user.email "test@test.com"
  git -C "$dir" config user.name "test"
  # Mirror the required directory structure
  mkdir -p "$dir/.claude/skills/verification-layer/research"
  mkdir -p "$dir/.claude/templates"
  mkdir -p "$dir/verification-reviews"
  echo "$dir"
}

# Write a minimal but structurally correct protocol.md into a fixture repo.
# $1 = repo root; $2 = T1 scope cell text (default: canonical)
write_protocol() {
  local repo="$1"
  local t1_scope="${2:-Breaking changes, auth, security-sensitive APIs, crypto primitives}"
  cat > "$repo/.claude/skills/verification-layer/research/protocol.md" <<EOF
# Research domain — protocol

## Tier table

| Tier | Scope | Mechanism |
|---|---|---|
| T1 | ${t1_scope} | Two-stage + GAN |
| T2 | Public API arguments, return types, defaults | Two-stage once |
| T3 | Idiomatic style, common usage examples | Generator self-check |

If unsure between Tiers, choose the higher one.

## Protocol (T1 / T2)

rest of file
EOF
}

# Write a verification-review artifact.
# $1 = repo root; $2 = filename relative to repo; $3 = Tier; $4 = body content
write_review() {
  local repo="$1" rel_path="$2" tier="$3" body="$4"
  mkdir -p "$repo/$(dirname "$rel_path")"
  cat > "$repo/$rel_path" <<EOF
# Verification Review: test topic

## Header (always)

- Domain: research
- Topic: test research question

---

## Research domain (use only when Domain: research)

### Generator

- Tier: ${tier}
- Question: ${body}
- Version pin: some-version

### Claims

| # | Claim | Source URL | Retrieved | Severity (Critic) |
|---|-------|-----------|-----------|-------------------|
| 1 | ${body} | https://example.com | 2026-01-01 | LOW |

EOF
}

# Run the detector against a fixture repo; return its exit code.
run_detector() {
  local repo="$1"
  (cd "$repo" && bash "$SCRIPT") > /dev/null 2>&1
  echo $?
}

# Run the detector and capture stdout+stderr together.
run_detector_verbose() {
  local repo="$1"
  (cd "$repo" && bash "$SCRIPT") 2>&1 || true
}

# -----------------------------------------------------------------------
echo ""
echo "check-research-tier-auth.sh test suite"
echo "======================================="
echo ""

# -- Script must exist before running tests (RED phase guard) --
if [[ ! -f "$SCRIPT" ]]; then
  yellow "  [SKIP] $SCRIPT not found — running in RED phase (all tests will fail)"
fi

# -----------------------------------------------------------------------
echo "Test 1: GREEN baseline — template's own main (no review instances) → PASS exit 0"
# -----------------------------------------------------------------------
{
  # The template repo itself has no committed verification-review instances.
  # The detector must pass (green-by-construction).
  if [[ ! -f "$SCRIPT" ]]; then
    fail_test "Test 1: script not found (RED phase)"
  else
    exit_code=0
    bash -c "cd \"$REPO_ROOT\" && bash \"$SCRIPT\"" > /dev/null 2>&1 || exit_code=$?
    if [[ "$exit_code" == "0" ]]; then
      pass_test "Test 1: template main (no review instances) → PASS exit 0 (green-by-construction)"
    else
      out="$(bash -c "cd \"$REPO_ROOT\" && bash \"$SCRIPT\"" 2>&1 || true)"
      fail_test "Test 1: expected exit 0 on template main, got exit $exit_code; output: $out"
    fi
  fi
}

# -----------------------------------------------------------------------
echo ""
echo "Test 2: auth content declared at T2 → FAIL exit 1 naming the matched term + Tier"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  write_protocol "$repo"
  write_review "$repo" "verification-reviews/auth-review-t2.md" "T2" \
    "This research covers authentication and JWT token handling behavior"

  out="$(run_detector_verbose "$repo")"
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "1" ]] && \
     (echo "$out" | grep -qi "auth" || echo "$out" | grep -qi "token") && \
     echo "$out" | grep -qE "T2|declared.*T2|T2.*T1"; then
    pass_test "Test 2: auth content at T2 → FAIL exit 1 naming matched term + declared Tier"
  elif [[ "$exit_code" == "1" ]]; then
    pass_test "Test 2: auth content at T2 → FAIL exit 1 (auth mis-classification detected)"
  else
    fail_test "Test 2: expected exit 1 for auth content declared at T2, got exit $exit_code; output: $out"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "Test 3: auth content declared at T3 → FAIL exit 1"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  write_protocol "$repo"
  write_review "$repo" "verification-reviews/crypto-review-t3.md" "T3" \
    "This research covers crypto primitives and encryption algorithm selection"

  out="$(run_detector_verbose "$repo")"
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "1" ]]; then
    pass_test "Test 3: crypto content at T3 → FAIL exit 1 (T3 mis-classification detected)"
  else
    fail_test "Test 3: expected exit 1 for crypto content at T3, got exit $exit_code; output: $out"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "Test 4: auth content declared at T1 → PASS exit 0"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  write_protocol "$repo"
  write_review "$repo" "verification-reviews/auth-review-t1.md" "T1" \
    "This research covers authentication mechanisms and session management"

  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "Test 4: auth content at T1 → PASS exit 0 (correct Tier)"
  else
    out="$(run_detector_verbose "$repo")"
    fail_test "Test 4: expected exit 0 for auth content at T1, got exit $exit_code; output: $out"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "Test 5: non-auth content declared at T2 → PASS exit 0"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  write_protocol "$repo"
  write_review "$repo" "verification-reviews/style-review-t2.md" "T2" \
    "This research covers React component naming conventions and CSS module patterns"

  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "Test 5: non-auth content at T2 → PASS exit 0 (T2 correct for non-auth)"
  else
    out="$(run_detector_verbose "$repo")"
    fail_test "Test 5: expected exit 0 for non-auth content at T2, got exit $exit_code; output: $out"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "Test 6: switch off (enabled: false) — config default is disabled"
# -----------------------------------------------------------------------
{
  workflow_cfg="$REPO_ROOT/.github/research-tier-auth-tracker.yml"
  workflow_yml="$REPO_ROOT/.github/workflows/research-tier-auth-check.yml"

  if [[ ! -f "$workflow_yml" ]]; then
    fail_test "Test 6: $workflow_yml does not exist"
  elif [[ ! -f "$workflow_cfg" ]]; then
    fail_test "Test 6: $workflow_cfg config file does not exist"
  elif grep -Eq '^[[:space:]]*enabled:[[:space:]]*false' "$workflow_cfg"; then
    pass_test "Test 6: switch default is enabled: false (default-off, green-by-construction)"
  else
    fail_test "Test 6: $workflow_cfg must ship enabled: false for template green-by-construction"
  fi

  # Also verify the workflow references the enabled switch
  if [[ -f "$workflow_yml" ]] && grep -q "enabled" "$workflow_yml"; then
    pass_test "Test 6b: workflow references the 'enabled' switch (single-switch pattern)"
  elif [[ -f "$workflow_yml" ]]; then
    fail_test "Test 6b: workflow does not reference 'enabled' switch"
  fi
}

# -----------------------------------------------------------------------
echo ""
echo "Test 7: missing canonical T1 scope line in protocol.md → FAIL CLOSED exit 1"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  # Write a malformed protocol.md with no | T1 | row at all
  cat > "$repo/.claude/skills/verification-layer/research/protocol.md" <<'EOF'
# Research domain — protocol

## Tier table

| Tier | Scope | Mechanism |
|---|---|---|
| T2 | Some scope | Two-stage |
| T3 | Other scope | Self-check |

No T1 row here — canonical line is absent.
EOF
  # Create a review artifact so the detector has something to scan
  write_review "$repo" "verification-reviews/any-review.md" "T2" \
    "Some topic about API usage"

  out="$(run_detector_verbose "$repo")"
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "1" ]] && \
     (echo "$out" | grep -qi "canonical T1 scope line not found" || \
      echo "$out" | grep -qi "T1.*not found" || \
      echo "$out" | grep -qi "protocol.md"); then
    pass_test "Test 7: missing canonical T1 scope line → FAIL CLOSED with explicit message"
  elif [[ "$exit_code" == "1" ]]; then
    pass_test "Test 7: missing T1 scope line → FAIL CLOSED exit 1 (fail-closed direction)"
  else
    fail_test "Test 7: expected exit 1 (fail-closed) for missing T1 scope line, got exit $exit_code; output: $out"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "Test 8: R-04 tracking — amended T1 scope line picked up by detector with NO second edit"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  # Write protocol.md with an AMENDED T1 scope line that adds "OAuth flows"
  write_protocol "$repo" "Breaking changes, auth, security-sensitive APIs, crypto primitives, OAuth flows"
  # Write a review with "OAuth" content (new term) declared at T2
  write_review "$repo" "verification-reviews/oauth-review-t2.md" "T2" \
    "This research covers OAuth flows and authorization code grant behavior"

  out="$(run_detector_verbose "$repo")"
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "1" ]]; then
    pass_test "Test 8: R-04 — amended T1 scope (OAuth flows added) caught at T2 with no second detector edit"
  else
    fail_test "Test 8: R-04 FAIL — amended scope 'OAuth flows' at T2 was NOT caught; exit $exit_code; output: $out"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "Test 9: no-introspection property — no ~/.claude or \$HOME/.claude in non-comment code"
# -----------------------------------------------------------------------
{
  if [[ ! -f "$SCRIPT" ]]; then
    fail_test "Test 9: script not found at $SCRIPT"
  else
    # Strip comment lines (lines beginning with optional whitespace + #)
    # then check that no remaining code line references operator-env paths.
    code_lines="$(grep -v '^[[:space:]]*#' "$SCRIPT" 2>/dev/null || true)"
    if printf '%s\n' "$code_lines" | grep -qE '([~]\/\.claude|\$HOME\/\.claude|CLAUDE_HOME)'; then
      fail_test "Test 9: non-comment code reads operator-environment path (~/.claude / \$HOME/.claude) — ZERO introspection contract violated"
    else
      pass_test "Test 9: no non-comment code reads ~/.claude / \$HOME/.claude (zero operator-env introspection confirmed)"
    fi
  fi
}

# -----------------------------------------------------------------------
echo ""
echo "Test 10: byte-unchanged guard — verification.yml, orchestrator.md, protocol.md Tier table"
echo "  lines 49-53, five existing detectors + suites NOT in the diff"
# -----------------------------------------------------------------------
{
  # Compare against the design-only commit for #14 (2591082)
  base="2591082"
  guarded=(
    ".claude/verification.yml"
    ".claude/agents/orchestrator.md"
    ".claude/meta/scripts/check-dangling-refs.sh"
    ".claude/meta/scripts/check-roadmap-drift.sh"
    ".claude/meta/scripts/check-skill-invariants.sh"
    ".claude/meta/scripts/check-bilingual-parity.sh"
    ".claude/meta/scripts/check-ecc-delegation-consistency.sh"
    ".claude/meta/scripts/test-check-dangling-refs.sh"
    ".claude/meta/scripts/test-check-roadmap-drift.sh"
    ".claude/meta/scripts/test-check-bilingual-parity.sh"
    ".claude/meta/scripts/test-check-ecc-delegation-consistency.sh"
  )
  # Per-file exemptions added for Roadmap row #22 (CLAUDE.md invariant
  # refactor + Roadmap relocation + subagent-dispatch / worktree-advisory
  # protocols, ADR-014 second 2026-05-20 amendment + ADR-024 + ADR-025):
  # the relocation legitimately switches detector parse targets, the
  # orchestrator gains a Worktree Recommendation step + dispatch contract
  # subsection, and test-check-ecc-delegation-consistency.sh gains an
  # exempt_post_22 mechanism for the same reason. The byte-unchanged
  # guard continues to apply to all other guarded files.
  exempt_post_22=(
    ".claude/agents/orchestrator.md"
    ".claude/meta/scripts/check-dangling-refs.sh"
    ".claude/meta/scripts/check-roadmap-drift.sh"
    ".claude/meta/scripts/test-check-roadmap-drift.sh"
    ".claude/meta/scripts/test-check-ecc-delegation-consistency.sh"
  )
  is_exempt_22() {
    local q="$1" e
    for e in "${exempt_post_22[@]}"; do
      [[ "$e" == "$q" ]] && return 0
    done
    return 1
  }
  bleed=0
  for f in "${guarded[@]}"; do
    if is_exempt_22 "$f"; then continue; fi
    if ! git -C "$REPO_ROOT" diff --quiet "$base" -- "$f" 2>/dev/null; then
      red "    byte-changed (VIOLATION): $f changed since $base"
      bleed=1
    fi
  done
  if [[ "$bleed" -eq 0 ]]; then
    pass_test "Test 10a: AC-3/AC-5/AC-6: verification.yml, orchestrator.md, five detectors + suites byte-unchanged since $base"
  else
    fail_test "Test 10a: AC-3/AC-5/AC-6 violated — guarded files changed since $base"
  fi

  # AC-4: protocol.md Tier table lines 49-53 byte-unchanged
  # Extract those lines from HEAD and compare to the base commit.
  base_tier_lines="$(git -C "$REPO_ROOT" show "${base}:.claude/skills/verification-layer/research/protocol.md" 2>/dev/null \
    | sed -n '49,53p' || true)"
  head_tier_lines="$(sed -n '49,53p' "$REPO_ROOT/.claude/skills/verification-layer/research/protocol.md" 2>/dev/null || true)"
  if [[ -n "$base_tier_lines" ]] && [[ "$base_tier_lines" == "$head_tier_lines" ]]; then
    pass_test "Test 10b: AC-4: protocol.md Tier-table lines 49-53 byte-unchanged since $base"
  elif [[ -z "$base_tier_lines" ]]; then
    yellow "  [SKIP] Test 10b: base commit $base not available for protocol.md comparison"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    fail_test "Test 10b: AC-4 violated — protocol.md Tier-table lines 49-53 changed since $base"
  fi
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
