#!/usr/bin/env bash
# check-research-tier-auth.sh
#
# Validates that verification-review artifacts whose content concerns items
# in protocol.md's T1 scope (auth, security-sensitive APIs, crypto
# primitives, etc.) are declared T1, not T2 or T3.
#
# ─────────────────────────────────────────────────────────────────────────
# AUTH→T1 CONTRACT (AC-1, ADR-021 §Decision 2c):
#
#   A verification-review output whose content concerns any item in the
#   Tier table's T1 scope line (protocol.md, the `| T1 |` row) MUST be
#   declared T1. T2 or T3 is non-conformant for such content regardless
#   of how the topic line is worded. The written contract lives in
#   protocol.md immediately under the Tier table. This detector enforces
#   that contract by scanning artifact CONTENT — not only the topic line
#   — so that a topic description of "login flow" (auth content, no "auth"
#   keyword) is still caught.
#
# ─────────────────────────────────────────────────────────────────────────
# ZERO OPERATOR-ENVIRONMENT INTROSPECTION (AC-8, ADR-021 §Decision 4):
#
#   This script reads ONLY repository artifacts. It never reads ~/.claude/,
#   $HOME/.claude/, or any operator-level agent registry. It never makes
#   network calls. The auth-scope keyword set is derived AT RUNTIME from
#   protocol.md's Tier-table T1 scope line — not hardcoded as an
#   independent list. If the canonical T1 scope line cannot be found in
#   protocol.md, the detector fails closed (never silently passes).
#
# ─────────────────────────────────────────────────────────────────────────
# R-04 SINGLE-SOURCE BINDING (ADR-021 §Decision 5):
#
#   The auth-keyword set is derived from the `| T1 |` row of the Tier table
#   in .claude/skills/verification-layer/research/protocol.md at run time.
#   A future amendment to the T1 scope line (e.g., adding "OAuth flows")
#   is automatically tracked by this detector with NO second edit here.
#   If the canonical line is absent, the detector fails closed with the
#   explicit message: "canonical T1 scope line not found in protocol.md
#   Tier table".
#
# ─────────────────────────────────────────────────────────────────────────
# MECE BOUNDARY (ADR-021 §Decision 3 — seven-way MECE table):
#
#   This script's owned question: "Is a research-verification output whose
#   content concerns the Tier table's T1 scope (auth/authn/authz/crypto/
#   security-sensitive APIs) declared at T1, as an independently-checkable
#   written contract independent of the orchestrator's runtime topic scan?"
#
#   - check-dangling-refs.sh (#04): owns path resolution (pointer → file).
#   - check-roadmap-drift.sh (#05): owns Roadmap bidirectional-link contract.
#   - check-bilingual-parity.sh (#06): owns EN↔JA structural parity.
#   - #11 (ADR-014 §(d)): owns verification-domain opt-in guidance (no det.)
#   - coverage-gate.yml (#12): owns coverage-percentage CI threshold.
#   - check-ecc-delegation-consistency.sh (#13): owns delegation-table
#     internal consistency for code-reviewer.md.
#   - THIS SCRIPT (#14): owns auth-touching content vs. declared Tier.
#
#   A defect maps to exactly one owner; no overlap with any existing check.
#   See ADR-021 §Decision 3 for the full seven-row table.
#
# ─────────────────────────────────────────────────────────────────────────
# ARTIFACT DISCOVERY:
#
#   Verification-review instances are identified by content shape: a file
#   containing both the "## Research domain" section marker and a
#   "- Tier:" line under "### Generator". The .claude/templates/ directory
#   is excluded (template file, not an instance). Only files with Domain:
#   research are relevant; the detector skips non-research artifacts.
#
# ─────────────────────────────────────────────────────────────────────────
# TEMPLATE-CI-GREEN CONTRACT (ADR-021 §Consequences/Positive):
#
#   The template repository commits no verification-review instances. This
#   detector therefore finds no candidates to scan and exits 0 on the
#   template's own main — green-by-construction, identical to the
#   #12/#13 precedent.
#
# ─────────────────────────────────────────────────────────────────────────
# ESCAPE HATCH (inherited from #04/#05/#06/#13 unmodified):
#   Add `<!-- ref-allow: <reason> -->` on the same line to suppress a
#   specific finding on that line. Use sparingly.
#
# Structure mirrors check-ecc-delegation-consistency.sh (#13, ADR-020):
#   set -euo pipefail, git rev-parse root resolution, pass/warn/fail_check
#   helpers, fail=0 accumulator, exit "$fail", GITHUB_STEP_SUMMARY support.
#
# See also: ADR-021, specs/14-research-tier-validation.md,
#   .claude/skills/verification-layer/research/protocol.md,
#   .claude/templates/verification-review-template.md

set -euo pipefail

# Resolve repo root robustly: prefer git, fall back to a relative walk.
if repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  :
else
  repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
fi
cd "$repo_root"

PROTOCOL=".claude/skills/verification-layer/research/protocol.md"

fail=0
pass()       { printf "  [PASS] %s\n" "$1"; }
warn()       { printf "  [WARN] %s\n" "$1" >&2; }
fail_check() {
  printf "  [FAIL] %s\n" "$1" >&2
  fail=1
}

# ---------------------------------------------------------------------------
# GITHUB_STEP_SUMMARY support (mirrors check-ecc-delegation-consistency.sh)
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
    summary_append "## Research Tier Auth Validation Findings"
    summary_append ""
    summary_append "**Contract:** auth-touching verification-review content must declare T1."
    summary_append "See protocol.md §\"Auth→T1 mandatory rule\" and ADR-021."
    summary_append ""
    summary_append "| Artifact | Matched term | Declared Tier | Required Tier |"
    summary_append "|----------|-------------|---------------|---------------|"
  fi
}

summary_finding() {
  summary_append "| $1 | $2 | $3 | T1 |"
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

# ---------------------------------------------------------------------------
# Step 1: Derive the auth-scope keyword set from protocol.md T1 scope line.
# Fails closed if the canonical line is not found.
# ---------------------------------------------------------------------------
derive_auth_keywords() {
  if [ ! -f "$PROTOCOL" ]; then
    fail_check "protocol.md not found at $PROTOCOL — cannot derive T1 keyword scope"
    exit 1
  fi

  # Extract the T1 scope cell from the Tier table: the line matching `| T1 |`
  t1_line="$(grep -m1 '| T1 |' "$PROTOCOL" 2>/dev/null || true)"
  if [ -z "$t1_line" ]; then
    fail_check "canonical T1 scope line not found in protocol.md Tier table — fail closed (ADR-021 §Decision 5)"
    exit 1
  fi

  # Extract the scope cell (second pipe-delimited column).
  # The Tier table format: | T1 | <scope text> | <mechanism text> |
  t1_scope="$(printf '%s' "$t1_line" | awk -F'|' '{print $3}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  if [ -z "$t1_scope" ]; then
    fail_check "could not extract T1 scope cell from Tier table line — fail closed"
    exit 1
  fi

  # Tokenize the scope cell into keywords.
  # Strategy: lowercase, replace non-alphanumeric-or-hyphen with space,
  # emit one token per word of 3+ chars. This derives naturally from
  # "Breaking changes, auth, security-sensitive APIs, crypto primitives":
  #   breaking, changes, auth, security-sensitive, security, sensitive,
  #   APIs, api, crypto, primitives, etc.
  # We emit the raw words from the scope cell so R-04 works automatically.
  printf '%s' "$t1_scope" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9 -]/ /g' \
    | tr ' ' '\n' \
    | grep -E '^[a-z].{2,}' \
    | sort -u
}

# ---------------------------------------------------------------------------
# Step 2: Find candidate verification-review artifacts.
# A candidate has "## Research domain" and "- Tier:" markers.
# Excludes .claude/templates/ (template file, not an instance).
# ---------------------------------------------------------------------------
find_review_candidates() {
  # Find all markdown files outside .claude/templates/
  find . -name "*.md" \
    ! -path "./.claude/templates/*" \
    ! -path "./.git/*" \
    2>/dev/null \
    | while IFS= read -r f; do
        # Must contain both the research domain section marker and a Tier line
        if grep -q "## Research domain" "$f" 2>/dev/null && \
           grep -q "^- Tier:" "$f" 2>/dev/null; then
          printf '%s\n' "$f"
        fi
      done
}

# ---------------------------------------------------------------------------
# Step 3: For each candidate, check declared Tier vs. content keywords.
# $1 = artifact path; $2 = newline-separated keyword string
# ---------------------------------------------------------------------------
check_artifact_str() {
  local artifact="$1"
  local keywords_str="$2"

  # Extract the declared Tier from the "### Generator" subsection.
  # The Tier line is: "- Tier: T1" or "- Tier: T2" or "- Tier: T3"
  declared_tier="$(grep -m1 '^- Tier:' "$artifact" 2>/dev/null \
    | sed 's/^- Tier:[[:space:]]*//' \
    | tr -d '[:space:]')"

  # Only check artifacts declaring T2 or T3 — T1 is already correct.
  case "$declared_tier" in
    T1) return 0 ;;
    T2|T3) : ;;
    *) return 0 ;;  # Unparseable Tier — skip silently
  esac

  # Read the artifact body for keyword matching.
  # We scan the entire file content (not only the topic line) so that
  # "login flow" (auth content without the "auth" keyword in the topic)
  # is still caught by content scanning.
  artifact_text="$(cat "$artifact" 2>/dev/null | tr '[:upper:]' '[:lower:]')"

  while IFS= read -r keyword; do
    [ -z "$keyword" ] && continue
    [ "${#keyword}" -lt 3 ] && continue

    # Skip generic English stop-words unlikely to be meaningful signals.
    # NOTE: `breaking` and `changes` are deliberately NOT skipped — they are
    # the first item of the T1 scope line ("Breaking changes, ...") and are
    # genuine T1 triggers. Suppressing them would contradict the R-04
    # single-source guarantee (ADR-021 §Decision 5): every word the T1 scope
    # line names must remain a live signal derived at runtime. The remaining
    # entries below are words that appear only in the T2/T3 scope cells or
    # in the table's prose framing, not in the T1 scope line.
    case "$keyword" in
      the|and|for|are|not|use|its|with|that|this|from) continue ;;
      common|public|return|types|defaults) continue ;;
      library|style|usage|examples|widely|known|patterns) continue ;;
      idiomatic|generator|self|check|source|stage|once) continue ;;
      unless|critical|high|iteration|reserved) continue ;;
    esac

    if printf '%s' "$artifact_text" | grep -qF "$keyword" 2>/dev/null; then
      # Check escape hatch on the Tier declaration line
      tier_line="$(grep -m1 '^- Tier:' "$artifact" 2>/dev/null || true)"
      if has_ref_allow "$tier_line"; then
        continue
      fi

      fail_check "auth-Tier mis-classification: $artifact — content matches auth-scope term '$keyword', declared $declared_tier, requires T1"
      summary_finding "$artifact" "$keyword" "$declared_tier"
      return 0
    fi
  done <<< "$keywords_str"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
echo "Research Tier auth→T1 validation"
echo "================================="
echo ""
echo "Auth→T1 contract:"
echo "  Verification-review outputs whose content concerns the T1 scope"
echo "  (protocol.md Tier table's T1 scope line: auth, security-sensitive"
echo "  APIs, crypto primitives, etc.) MUST be declared T1. T2/T3 for such"
echo "  content is a mis-classification. This detector scans artifact content,"
echo "  not only topic lines, to catch topic-description omissions."
echo "  Zero operator-environment introspection (reads only repo artifacts)."
echo "  See ADR-021 and specs/14-research-tier-validation.md."
echo ""

summary_header

# Derive keywords from protocol.md (fail-closed if canonical line absent).
auth_keywords_str="$(derive_auth_keywords)"

if [ -z "$auth_keywords_str" ]; then
  fail_check "no keywords derived from T1 scope line — fail closed"
  echo ""
  echo "Research Tier auth→T1 validation: FAIL"
  exit 1
fi

echo "T1 scope keywords (derived from protocol.md at runtime):"
printf '%s\n' "$auth_keywords_str" | while IFS= read -r kw; do
  [ -n "$kw" ] && printf '  %s\n' "$kw"
done
echo ""

# Find candidate artifacts.
candidates="$(find_review_candidates)"

if [ -z "$candidates" ]; then
  pass "No verification-review instances found in repository (green-by-construction on template)"
  echo ""
  echo "Research Tier auth→T1 validation: PASS"
  exit 0
fi

echo "Scanning verification-review artifacts..."
echo ""

artifact_count=0
# Read keywords into a local variable for passing to check_artifact
while IFS= read -r artifact; do
  [ -z "$artifact" ] && continue
  artifact_count=$((artifact_count + 1))
  # Pass keywords as a newline-separated string via check_artifact_str
  check_artifact_str "$artifact" "$auth_keywords_str"
done <<< "$candidates"

echo ""
echo "Scanned $artifact_count verification-review artifact(s)."
echo ""

if [ "$fail" -gt 0 ]; then
  echo "Research Tier auth→T1 validation: FAIL"
  echo ""
  echo "To fix: raise the declared Tier to T1 for each flagged artifact."
  echo "The auth→T1 rule is the mandatory written contract in protocol.md"
  echo "§\"Auth→T1 mandatory rule\"; see ADR-021 §Decision 2 for rationale."
  echo "Use <!-- ref-allow: <reason> --> on the Tier line to suppress"
  echo "a specific finding when T2/T3 is genuinely correct."
  exit 1
fi

echo "Research Tier auth→T1 validation: PASS"
