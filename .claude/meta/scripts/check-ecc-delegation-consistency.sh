#!/usr/bin/env bash
# check-ecc-delegation-consistency.sh
#
# Validates the INTERNAL CONSISTENCY of code-reviewer.md's ECC delegation
# table: every ECC reviewer name referenced in the "Delegate to ECC agent"
# column of the manifest→ECC-agent table must be consistent with the intro
# list of ECC reviewers declared in the same file, accounting for the
# documented flutter-reviewer / dart-reviewer indirection.
#
# This is milestone #13; the authoritative scope is
# specs/13-ecc-absent-signal.md (eight acceptance criteria, Non-goals,
# Out of scope); the structural decisions are
# .claude/meta/adr/020-ecc-absent-signal.md.
#
# ─────────────────────────────────────────────────────────────────────────
# STANDING DEGRADED-REVIEW POSTURE (ADR-020 §5, Spec AC-1/AC-7):
#
#   code-reviewer.md's language-specific layer delegates to ECC's
#   *-reviewer agents (typescript-reviewer, python-reviewer, go-reviewer,
#   rust-reviewer, cpp-reviewer, java-reviewer, kotlin-reviewer,
#   flutter-reviewer / dart-reviewer, csharp-reviewer). When ECC is absent
#   from the operator's ~/.claude/, the language-specific depth is skipped
#   and code-reviewer falls back to its generic checklist, stating so
#   explicitly in the verdict. See README.md ## Prerequisites for the full
#   standing posture and code-reviewer.md lines 72-92 for the per-review
#   three-case rule. This detector validates that the delegation table is
#   internally consistent — it does NOT probe whether ECC is installed
#   (that is impossible from inside a repository and forbidden by
#   code-reviewer.md lines 84-87).
#
# ─────────────────────────────────────────────────────────────────────────
# WHAT THIS SCRIPT CHECKS (the consistency predicate):
#
#   1. TABLE-VS-INTRO: every ECC reviewer name in the delegation-table
#      rows' "Delegate to ECC agent" column must appear in the intro list
#      of ECC reviewers declared in code-reviewer.md's Why-dispatcher
#      section. The documented flutter-reviewer / dart-reviewer indirection
#      is explicitly accounted for: flutter-reviewer in the table satisfies
#      dart-reviewer in the intro (and vice versa) because the same
#      indirection is declared inline.
#
#   2. INTRO-VS-TABLE: every ECC reviewer name from the intro list must be
#      covered by at least one delegation-table row, applying the same
#      flutter-reviewer / dart-reviewer aliasing rule.
#
#   A drift in either direction is a "delegation row going stale silently"
#   — the concrete, detectable failure mode ADR-012's Negative section named
#   and left open, and that #13 closes.
#
# ─────────────────────────────────────────────────────────────────────────
# ZERO OPERATOR-ENVIRONMENT INTROSPECTION (ADR-020 §3, Spec AC-5):
#
#   This script reads ONLY repository artifacts (primarily
#   .claude/agents/code-reviewer.md). It never reads ~/.claude/,
#   $HOME/.claude/, or any operator-level agent registry. Attempting to
#   detect whether ECC is installed would be unreliable by construction
#   (ECC is user-level, outside the repo and CI), and is explicitly
#   forbidden by code-reviewer.md lines 84-87. The subject of this check
#   is intra-file consistency, not live ECC presence.
#
# ─────────────────────────────────────────────────────────────────────────
# MECE BOUNDARY (ADR-020 §2):
#
#   This script's owned question: "Is code-reviewer.md's ECC delegation
#   table internally consistent?" It overlaps with no existing detector:
#   - check-dangling-refs.sh (#04): owns RESOLUTION (does a pointer resolve
#     to a real file/ADR?). This script does not resolve paths.
#   - check-roadmap-drift.sh (#05): owns Roadmap INDEX CONSISTENCY.
#   - check-bilingual-parity.sh (#06): owns EN↔JA PARITY.
#   - check-skill-invariants.sh: owns SKILL.md structural contracts.
#   None of those own "is code-reviewer.md's delegation table consistent
#   with its own intro list?"
#
# ─────────────────────────────────────────────────────────────────────────
# FLUTTER-REVIEWER / DART-REVIEWER INDIRECTION:
#
#   code-reviewer.md's intro list documents the indirection inline:
#     "dart-reviewer (via flutter-reviewer)"
#   The delegation table uses `flutter-reviewer` for the pubspec.yaml row.
#   The consistency check treats flutter-reviewer and dart-reviewer as
#   aliases of the same slot: a table row naming flutter-reviewer satisfies
#   the intro's dart-reviewer entry, and vice versa. This indirection is
#   the only canonical alias documented in code-reviewer.md; no other
#   aliasing is assumed.
#
# ─────────────────────────────────────────────────────────────────────────
# TEMPLATE-CI-GREEN CONTRACT (ADR-020 §4):
#
#   The delegation table in the template's code-reviewer.md is consistent
#   by design (it is the source of truth). This detector therefore passes
#   on the template's own main with no special-casing or suppression —
#   the #12/ADR-019 precedent applied to a consistency check rather than
#   a coverage gate.
#
# ─────────────────────────────────────────────────────────────────────────
# ESCAPE HATCH (inherited from #04/#05/#06 unmodified):
#   Add `<!-- ref-allow: <reason> -->` on the same line to suppress a
#   specific finding on that line. Use sparingly; the goal is a consistent
#   table, not a blanket suppression.
#
# Structure mirrors check-bilingual-parity.sh (#06, ADR-018):
#   set -euo pipefail, git rev-parse root resolution, pass/warn/fail_check
#   helpers, fail=0 accumulator, exit "$fail", GITHUB_STEP_SUMMARY support,
#   single-awk-pass scanning.
#
# See also: ADR-020, ADR-012, specs/13-ecc-absent-signal.md,
#   .claude/agents/code-reviewer.md

set -euo pipefail

# Resolve repo root robustly: prefer git, fall back to a relative walk.
if repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  :
else
  repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
fi
cd "$repo_root"

CODE_REVIEWER=".claude/agents/code-reviewer.md"

fail=0
pass()       { printf "  [PASS] %s\n" "$1"; }
warn()       { printf "  [WARN] %s\n" "$1" >&2; }
fail_check() {
  printf "  [FAIL] %s\n" "$1" >&2
  fail=1
}

# ---------------------------------------------------------------------------
# GITHUB_STEP_SUMMARY support (mirrors check-bilingual-parity.sh)
# ---------------------------------------------------------------------------
SUMMARY_LINES=0
SUMMARY_MAX=200
summary_append() {
  local text="$1"
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ] && [ "$SUMMARY_LINES" -lt "$SUMMARY_MAX" ]; then
    printf '%s\n' "$text" >> "$GITHUB_STEP_SUMMARY"
    SUMMARY_LINES=$((SUMMARY_LINES + 1))
  fi
}

summary_header() {
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    summary_append "## ECC Delegation Consistency Findings"
    summary_append ""
    summary_append "**Standing posture:** code-reviewer.md delegates language-specific depth to ECC"
    summary_append "*-reviewer agents. When ECC is absent, code-reviewer falls back to generic"
    summary_append "checklist and says so. See README.md ## Prerequisites."
    summary_append ""
    summary_append "| Check | Kind | Detail |"
    summary_append "|-------|------|--------|"
  fi
}

summary_finding() {
  summary_append "| $1 | $2 | $3 |"
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Return true (0) if the line carries the ref-allow escape hatch.
has_ref_allow() {
  case "$1" in
    *"<!-- ref-allow:"*) return 0 ;;
  esac
  return 1
}

# Normalize a reviewer name for comparison purposes.
# The only canonical alias: flutter-reviewer and dart-reviewer are the same slot.
# Returns the canonical form used for set comparison: always use flutter-reviewer
# as the canonical name (it is what the delegation table uses).
normalize_reviewer() {
  local name="$1"
  case "$name" in
    dart-reviewer) printf 'flutter-reviewer' ;;
    *)             printf '%s' "$name" ;;
  esac
}

# Extract the ECC reviewer names from the delegation table in code-reviewer.md.
# The table format is:
#   | Manifest file present | Delegate to ECC agent |
#   |---|---|
#   | `package.json` | `typescript-reviewer` |
# We extract the second column's backtick-quoted agent name.
# Output: one reviewer name per line (backticks stripped), normalized.
# Fenced code blocks are skipped. Lines with ref-allow are skipped.
extract_table_reviewers() {
  local file="$1"
  awk '
    BEGIN { in_fence=0; fence_char=""; in_table=0 }
    /^```/ {
      if (in_fence && fence_char == "```") { in_fence=0; fence_char="" }
      else if (!in_fence) { in_fence=1; fence_char="```" }
      next
    }
    /^~~~/ {
      if (in_fence && fence_char == "~~~") { in_fence=0; fence_char="" }
      else if (!in_fence) { in_fence=1; fence_char="~~~" }
      next
    }
    in_fence { next }
    /<!-- ref-allow:/ { next }
    # Detect the delegation table header: "Manifest file present" header row
    /Manifest file present.*Delegate to ECC agent/ { in_table=1; next }
    # Exit table on a blank line or a heading
    in_table && /^[[:space:]]*$/ { in_table=0; next }
    in_table && /^#/ { in_table=0; next }
    in_table && /^\*\*/ { in_table=0; next }
    # Table separator row (|---|---| or similar)
    in_table && /^\|[-: |]+\|/ { next }
    # Data rows: | <manifest> | <reviewer> |
    in_table && /^\|/ {
      # Split on pipe, take the last non-empty cell (the reviewer column)
      line = $0
      n = split(line, cells, "|")
      # Find the second data cell (cells[3] for a | a | b | table)
      # We look for the cell containing a backtick-quoted reviewer name.
      for (i = 2; i <= n; i++) {
        cell = cells[i]
        # Strip surrounding whitespace
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", cell)
        # Check if this cell has a backtick-quoted reviewer name ending in -reviewer
        if (match(cell, /`[a-z][a-z-]+-reviewer`/)) {
          name = substr(cell, RSTART+1, RLENGTH-2)
          print name
        }
      }
    }
  ' "$file" | sort -u
}

# Extract the ECC reviewer names from the intro list in code-reviewer.md.
# The intro is the sentence mentioning "ECC ships" or listing the reviewer names.
# We look for backtick-quoted *-reviewer names outside fenced blocks.
# Output: one reviewer name per line (normalized), sorted unique.
extract_intro_reviewers() {
  local file="$1"
  awk '
    BEGIN { in_fence=0; fence_char="" }
    /^```/ {
      if (in_fence && fence_char == "```") { in_fence=0; fence_char="" }
      else if (!in_fence) { in_fence=1; fence_char="```" }
      next
    }
    /^~~~/ {
      if (in_fence && fence_char == "~~~") { in_fence=0; fence_char="" }
      else if (!in_fence) { in_fence=1; fence_char="~~~" }
      next
    }
    in_fence { next }
    /<!-- ref-allow:/ { next }
    # Stop scanning once we hit the delegation table header (table reviewers
    # are extracted separately; do not double-count them from the table rows).
    /Manifest file present.*Delegate to ECC agent/ { exit }
    # Extract backtick-quoted *-reviewer names from prose
    {
      line = $0
      while (match(line, /`[a-z][a-z-]+-reviewer`/)) {
        name = substr(line, RSTART+1, RLENGTH-2)
        print name
        line = substr(line, RSTART+RLENGTH)
      }
    }
  ' "$file" | sort -u
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
echo "ECC delegation consistency checks"
echo "=================================="
echo ""
echo "Standing degraded-review posture:"
echo "  code-reviewer.md delegates language-specific depth to ECC *-reviewer"
echo "  agents. When ECC is absent from the operator environment, the language-"
echo "  specific layer is skipped; code-reviewer falls back to its generic"
echo "  checklist and states so explicitly in the verdict (three-case rule,"
echo "  code-reviewer.md lines 72-92). See README.md ## Prerequisites."
echo "  This detector validates INTERNAL CONSISTENCY of the delegation table;"
echo "  it does NOT probe whether ECC is installed (see ADR-020 §3)."
echo ""

summary_header

if [ ! -f "$CODE_REVIEWER" ]; then
  fail_check "code-reviewer.md not found at $CODE_REVIEWER — cannot check delegation consistency"
  echo ""
  echo "ECC delegation consistency checks: FAIL"
  exit 1
fi

# -----------------------------------------------------------------------
echo "Check 1: Delegation table rows vs. intro list (TABLE-VS-INTRO)"
echo "  Every reviewer named in the delegation table must be in the intro list."
echo "  The flutter-reviewer / dart-reviewer indirection is the only alias."
# -----------------------------------------------------------------------
table_fail_before="$fail"

# Extract sorted unique names from the table and intro.
table_reviewers="$(extract_table_reviewers "$CODE_REVIEWER")"
intro_reviewers="$(extract_intro_reviewers "$CODE_REVIEWER")"

if [ -z "$table_reviewers" ]; then
  fail_check "no reviewer names found in the delegation table — is the table format correct?"
  summary_finding "table-parse" "parse-error" "no reviewer names extracted from delegation table"
fi

if [ -z "$intro_reviewers" ]; then
  fail_check "no reviewer names found in the intro list — is the intro format correct?"
  summary_finding "intro-parse" "parse-error" "no reviewer names extracted from intro list"
fi

# Build a normalized set from the intro (applying flutter=dart alias).
# For each table reviewer, check that its normalized form appears in the
# normalized intro set, or its alias does.
if [ -n "$table_reviewers" ] && [ -n "$intro_reviewers" ]; then
  # Normalize both sets: treat flutter-reviewer and dart-reviewer as the same.
  normalized_intro=""
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    normalized="$(normalize_reviewer "$name")"
    normalized_intro="${normalized_intro}${normalized}"$'\n'
  done <<< "$intro_reviewers"
  normalized_intro="$(printf '%s' "$normalized_intro" | sort -u)"

  while IFS= read -r tname; do
    [ -z "$tname" ] && continue
    tnorm="$(normalize_reviewer "$tname")"
    if ! printf '%s\n' "$normalized_intro" | grep -qx "$tnorm"; then
      fail_check "Table-vs-intro: delegation table names '$tname' but this reviewer is not in the intro list (drift: 'delegation rows go stale silently')"
      summary_finding "table-vs-intro" "table-extra" "$tname not in intro"
    fi
  done <<< "$table_reviewers"
fi

if [ "$fail" = "$table_fail_before" ] && [ -n "$table_reviewers" ]; then
  pass "All delegation-table reviewer names appear in the intro list"
fi

# -----------------------------------------------------------------------
echo ""
echo "Check 2: Intro list vs. delegation table rows (INTRO-VS-TABLE)"
echo "  Every reviewer in the intro list must have a delegation-table row."
echo "  The flutter-reviewer / dart-reviewer indirection is applied."
# -----------------------------------------------------------------------
intro_fail_before="$fail"

if [ -n "$intro_reviewers" ] && [ -n "$table_reviewers" ]; then
  # Normalize the table set
  normalized_table=""
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    normalized="$(normalize_reviewer "$name")"
    normalized_table="${normalized_table}${normalized}"$'\n'
  done <<< "$table_reviewers"
  normalized_table="$(printf '%s' "$normalized_table" | sort -u)"

  while IFS= read -r iname; do
    [ -z "$iname" ] && continue
    inorm="$(normalize_reviewer "$iname")"
    if ! printf '%s\n' "$normalized_table" | grep -qx "$inorm"; then
      fail_check "Intro-vs-table: intro list names '$iname' but no delegation-table row delegates to it (drift: intro and table out of sync)"
      summary_finding "intro-vs-table" "intro-extra" "$iname not in table"
    fi
  done <<< "$intro_reviewers"
fi

if [ "$fail" = "$intro_fail_before" ] && [ -n "$intro_reviewers" ]; then
  pass "All intro-list reviewer names have a corresponding delegation-table row"
fi

# -----------------------------------------------------------------------
echo ""
if [ "$fail" -gt 0 ]; then
  echo "ECC delegation consistency checks: FAIL"
  echo ""
  echo "To fix: align the delegation table rows and the intro list in"
  echo "$CODE_REVIEWER so both sets name the same ECC reviewers."
  echo "The flutter-reviewer / dart-reviewer indirection is documented"
  echo "inline and is the only canonical alias."
  exit 1
fi
echo "ECC delegation consistency checks: PASS"
