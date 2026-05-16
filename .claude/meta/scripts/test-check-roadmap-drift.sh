#!/usr/bin/env bash
# test-check-roadmap-drift.sh
#
# TDD test suite for check-roadmap-drift.sh (milestone #05, ADR-017).
# Creates isolated tmp fixtures and asserts expected exit codes / output.
# Covers all acceptance criteria in specs/05-roadmap-drift-detection-ci.md,
# each expressed Given/When/Then, plus the ADR-017 §4 multi-adr <br>-cell
# parsing requirement and the absence-of-claim exemption.
#
# Structure mirrors test-check-dangling-refs.sh: make_repo / run_detector /
# pass_test / fail_test / tmp fixtures.
#
# Usage: bash .claude/meta/scripts/test-check-roadmap-drift.sh
# Exit 0 = all tests pass; exit 1 = one or more tests failed.

set -euo pipefail

SCRIPT="$(cd "$(dirname "$0")" && pwd)/check-roadmap-drift.sh"
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

# Create a fresh tmp repo fixture with .git so git rev-parse works.
make_repo() {
  local dir
  dir="$(mktemp -d)"
  git init -q "$dir"
  git -C "$dir" config user.email "test@test.com"
  git -C "$dir" config user.name "test"
  mkdir -p "$dir/.claude/meta/adr"
  echo "$dir"
}

# Write a minimal CLAUDE.md with a ## Roadmap section. $2 is the raw table
# body (data rows). The header + separator are added automatically.
write_roadmap() {
  local repo="$1" rows="$2"
  cat > "$repo/.claude/CLAUDE.md" <<EOF
# Project Context

## Roadmap

Single entry point.

| # | Milestone | Status | Design source |
|---|-----------|--------|---------------|
$rows

## Development Workflow

Steps here.
EOF
}

# Write an ADR file. $4 (optional) is an extra ## References body line; if
# given, it is placed under a ## References heading.
write_adr() {
  local repo="$1" num="$2" slug="$3" backlink="${4:-}"
  local f
  f="$repo/.claude/meta/adr/$(printf '%03d' "$num")-${slug}.md"
  {
    printf '# ADR-%03d: %s\n\n## Status\n\nAccepted\n\n## Decision\n\nA decision.\n\n## References\n\n' "$num" "$slug"
    if [ -n "$backlink" ]; then
      printf -- '%s\n' "$backlink"
    fi
  } > "$f"
}

run_detector() {
  local repo="$1"
  (cd "$repo" && bash "$SCRIPT") > /dev/null 2>&1
  echo $?
}

run_detector_verbose() {
  local repo="$1"
  (cd "$repo" && bash "$SCRIPT") 2>&1 || true
}

echo ""
echo "check-roadmap-drift.sh test suite"
echo "================================="
echo ""

if [[ ! -f "$SCRIPT" ]]; then
  yellow "  [SKIP] $SCRIPT not found — all tests will fail (RED phase)"
fi

# -----------------------------------------------------------------------
echo "AC#1 — forward drift: row adr: exists on disk but ADR lacks matching back-link → FAIL"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  write_adr "$repo" 90 "thing" ""   # ADR exists but NO Roadmap back-link
  write_roadmap "$repo" \
'| 05 | A milestone | ◐ in-progress | spec: `specs/05-x.md`<br>adr: `.claude/meta/adr/090-thing.md` |'
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "1" ]]; then
    pass_test "AC#1: row adr: target present but no matching back-link → FAIL"
  else
    fail_test "AC#1: expected exit 1 (forward drift), got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#1b — forward direction satisfied (back-link present and matching) → PASS"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  write_adr "$repo" 90 "thing" "- Roadmap row: #05 (back-link)."
  write_roadmap "$repo" \
'| 05 | A milestone | ◐ in-progress | spec: `specs/05-x.md`<br>adr: `.claude/meta/adr/090-thing.md` |'
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "AC#1b: matching back-link present → PASS"
  else
    fail_test "AC#1b: expected exit 0 (forward satisfied), got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#2 — reverse drift: ADR back-links #NN but row #NN's cell lacks that adr: → FAIL"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  # ADR claims row #05, but row #05's Design-source cell has NO adr: link.
  write_adr "$repo" 90 "thing" "- Roadmap row: #05 (back-link)."
  write_roadmap "$repo" \
'| 05 | A milestone | ◐ in-progress | spec: `specs/05-x.md` |'
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "1" ]]; then
    pass_test "AC#2: ADR claims row but row's cell omits the adr: link → FAIL"
  else
    fail_test "AC#2: expected exit 1 (reverse drift), got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#2b — reverse drift: ADR back-links the WRONG row number → FAIL"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  # ADR is listed under row #05 but back-links #04 (forward-mismatch).
  write_adr "$repo" 90 "thing" "- Roadmap row: #04 (back-link)."
  write_roadmap "$repo" \
'| 05 | A milestone | ◐ in-progress | spec: `specs/05-x.md`<br>adr: `.claude/meta/adr/090-thing.md` |'
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "1" ]]; then
    pass_test "AC#2b: ADR listed under #05 but back-links #04 → FAIL"
  else
    fail_test "AC#2b: expected exit 1 (back-link row mismatch), got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#3 — unsanctioned Status glyph → FAIL with row number"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  write_adr "$repo" 90 "thing" "- Roadmap row: #05 (back-link)."
  write_roadmap "$repo" \
'| 05 | A milestone | ✅ done | spec: `specs/05-x.md`<br>adr: `.claude/meta/adr/090-thing.md` |'
  out="$(run_detector_verbose "$repo")"
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "1" ]] && echo "$out" | grep -q "row #05"; then
    pass_test "AC#3: unsanctioned glyph ✅ → FAIL naming row #05"
  else
    fail_test "AC#3: expected exit 1 + 'row #05' in output, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#3b — all four sanctioned glyphs (☐ ◐ ☑ ✗) → PASS"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  write_roadmap "$repo" \
'| 06 | Todo one | ☐ todo | spec: `specs/06-x.md` |
| 07 | Prog one | ◐ in-progress | spec: `specs/07-x.md` |
| 08 | Done one | ☑ done | spec: `specs/08-x.md` |
| 09 | Drop one | ✗ dropped | spec: `specs/09-x.md` |'
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "AC#3b: all four sanctioned glyphs accepted → PASS"
  else
    fail_test "AC#3b: expected exit 0 for sanctioned glyphs, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#4 — row adr: link to a non-existent path → FAIL (no reservation carve-out)"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  # No ADR file written; the adr: link dangles. Unlike spec: links, an
  # absent adr: target is never valid-by-design (ADR-017 §1).
  write_roadmap "$repo" \
'| 05 | A milestone | ◐ in-progress | spec: `specs/05-x.md`<br>adr: `.claude/meta/adr/090-missing.md` |'
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "1" ]]; then
    pass_test "AC#4: non-existent adr: target → FAIL (no carve-out)"
  else
    fail_test "AC#4: expected exit 1 for absent adr: target, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#5 — ADR with NO Roadmap back-link at all → does NOT fail (absence-of-claim exemption)"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  # A pre-Roadmap-style ADR: exists, no back-link, NOT listed in any row.
  write_adr "$repo" 1 "developer-growth-mode" ""
  write_roadmap "$repo" \
'| 05 | A milestone | ◐ in-progress | spec: `specs/05-x.md` |'
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "AC#5: back-link-less ADR exempt (absence-of-claim) → PASS"
  else
    fail_test "AC#5: expected exit 0 (exemption), got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#6 — template's own repo passes (self-baseline)"
# -----------------------------------------------------------------------
{
  repo_root="$(git -C "$(dirname "$SCRIPT")" rev-parse --show-toplevel 2>/dev/null || echo "")"
  if [[ -z "$repo_root" ]]; then
    fail_test "AC#6: could not determine repo root for self-baseline test"
  else
    exit_code=0
    DRIFT_SCRIPT="$SCRIPT" DRIFT_ROOT="$repo_root" \
      bash -c 'cd "$DRIFT_ROOT" && bash "$DRIFT_SCRIPT"' 2>/dev/null \
      || exit_code="$?"
    if [[ "$exit_code" == "0" ]]; then
      pass_test "AC#6: template's own repo passes with exit 0 (green-by-construction)"
    else
      fail_test "AC#6: template's own repo failed with exit $exit_code (real drift found)"
    fi
  fi
}

# -----------------------------------------------------------------------
echo ""
echo "AC#7 — always-on: workflow exists, job named, no configuration requirement"
# -----------------------------------------------------------------------
{
  workflow=".github/workflows/roadmap-drift-check.yml"
  repo_root="$(git -C "$(dirname "$SCRIPT")" rev-parse --show-toplevel 2>/dev/null || echo "")"
  if [[ -z "$repo_root" ]]; then
    fail_test "AC#7: could not determine repo root"
  elif [[ -f "$repo_root/$workflow" ]]; then
    if grep -q "enabled:" "$repo_root/$workflow"; then
      fail_test "AC#7: $workflow has an 'enabled:' config check (must be always-on)"
    elif ! grep -q "roadmap-drift-check:" "$repo_root/$workflow"; then
      fail_test "AC#7: $workflow does not define the job named 'roadmap-drift-check'"
    else
      pass_test "AC#7: $workflow exists, job named roadmap-drift-check, no config requirement"
    fi
  else
    fail_test "AC#7: $workflow does not exist"
  fi
}

# -----------------------------------------------------------------------
echo ""
echo "AC#8 — ref-allow escape hatch suppresses a drift finding on that line"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  # Row #05 carries a deliberately-dangling adr: but the ref-allow comment is
  # on the same row line — the #04 escape hatch reused unmodified.
  write_roadmap "$repo" \
'| 05 | A milestone | ◐ in-progress | spec: `specs/05-x.md`<br>adr: `.claude/meta/adr/090-missing.md` | <!-- ref-allow: forward ref, ADR not yet written -->'
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "AC#8: ref-allow on the row line suppresses the drift finding"
  else
    fail_test "AC#8: expected exit 0 with ref-allow suppression, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "New#1 — <br>-joined cell with TWO adr: links: BOTH are parsed (ADR-017 §4 / Spec R-01)"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  # ADR-090 back-links #05 correctly; ADR-091 does NOT. A line-greedy parser
  # that stops at the first adr: token would miss the 091 drift → exit 0
  # (wrong). A correct multi-adr parser FAILs on 091.
  write_adr "$repo" 90 "first"  "- Roadmap row: #05 (back-link)."
  write_adr "$repo" 91 "second" ""
  write_roadmap "$repo" \
'| 05 | A milestone | ◐ in-progress | spec: `specs/05-x.md`<br>adr: `.claude/meta/adr/090-first.md`<br>adr: `.claude/meta/adr/091-second.md` |'
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "1" ]]; then
    pass_test "New#1: second adr: in a <br>-joined cell is parsed (091 drift caught)"
  else
    fail_test "New#1: expected exit 1 (second adr: must be parsed), got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "New#1b — <br>-joined cell with TWO adr: links, BOTH correctly back-linked → PASS"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  write_adr "$repo" 90 "first"  "- Roadmap row: #05 (back-link)."
  write_adr "$repo" 91 "second" "- Roadmap row: #05 (back-link)."
  write_roadmap "$repo" \
'| 05 | A milestone | ◐ in-progress | spec: `specs/05-x.md`<br>adr: `.claude/meta/adr/090-first.md`<br>adr: `.claude/meta/adr/091-second.md` |'
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "New#1b: both adr: links in a 1:N cell back-linked → PASS"
  else
    fail_test "New#1b: expected exit 0 (both back-linked), got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "New#2 — .ja.md translation is NOT an independent claim-bearer (#06 boundary)"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  # Canonical .md is correctly back-linked & listed. The .ja.md translation
  # carries the same back-link line but the Roadmap cell links only the .md.
  # The .ja.md must NOT be treated as a drifted independent claim (that is
  # bilingual-parity, milestone #06, a Spec Non-goal here).
  write_adr "$repo" 90 "thing" "- Roadmap row: #05 (back-link)."
  cp "$repo/.claude/meta/adr/090-thing.md" "$repo/.claude/meta/adr/090-thing.ja.md"
  write_roadmap "$repo" \
'| 05 | A milestone | ◐ in-progress | spec: `specs/05-x.md`<br>adr: `.claude/meta/adr/090-thing.md` |'
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "New#2: .ja.md excluded from reverse scan (not an independent claim-bearer)"
  else
    fail_test "New#2: expected exit 0 (.ja.md is a derived artifact), got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "New#3 — zero-padding robustness: row '05' ↔ back-link '#5' are equal"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  # Row written as 05; back-link written as #5 (no zero-pad). Must match.
  write_adr "$repo" 90 "thing" "- Roadmap row: #5 (back-link)."
  write_roadmap "$repo" \
'| 05 | A milestone | ◐ in-progress | spec: `specs/05-x.md`<br>adr: `.claude/meta/adr/090-thing.md` |'
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "New#3: row '05' and back-link '#5' compared by integer value → PASS"
  else
    fail_test "New#3: expected exit 0 (zero-pad robust), got exit $exit_code"
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
