#!/usr/bin/env bash
# check-bilingual-parity.sh
#
# Enforces EN↔JA translation PARITY for the template's bilingual paired
# artifacts. This is milestone #06; the authoritative acceptance contract is
# specs/06-bilingual-parity-detector.md; the structural decisions (in-scope
# keying, carve-out, heading normalization, parsing approach, three-way MECE
# boundary) are ADR-018 and its 2026-05-17 per-pair-granularity amendment.
#
# ─────────────────────────────────────────────────────────────────────────
# THREE PARITY DIMENSIONS CHECKED (and ONLY these), per ADR-018 §Decision:
#
#   1. PRESENCE PARITY.
#      A <stem>.ja.md file with no <stem>.md counterpart is ALWAYS a FAIL
#      (orphaned JA — translation of nothing). A lone <stem>.md with no
#      <stem>.ja.md is NOT a FAIL — it is the sanctioned EN-only state
#      (the complement of the in-scope rule). There is NO "every .md must
#      have a .ja.md" scan; that is the directory-granularity reading the
#      2026-05-17 amendment explicitly removes.
#
#   2. HEADING-TREE PARITY.
#      For every pair where BOTH <stem>.md and <stem>.ja.md exist, compare
#      the heading level sequences by (level, position) ONLY. Heading TEXT
#      is NEVER compared — JA heading text is a translation; comparing text
#      makes every correct translation a false positive. Heading TEXT is used
#      only for the human-readable failure message, never for the comparison
#      predicate. A length mismatch FAILs with the count pair (EN vs JA). An
#      equal-length positional level mismatch FAILs naming the first ordinal
#      position where the levels differ.
#      A heading is "^#{1,4} " — one to four # followed by a space (levels
#      1–4, per Spec). CRITICAL: "^#" alone is WRONG — prose lines like
#      "#05 (issue ref)" start with # but have no space after the hashes;
#      requiring the space after hashes excludes them. Numbered prefixes
#      (e.g. "## 1. Context" vs "## 1. コンテキスト") are NOT special-cased
#      (moot under level+position comparison — text is never the predicate).
#      Fenced code blocks are SKIPPED (``` and ~~~, same in_fence/fence_char
#      logic as check-dangling-refs.sh and check-roadmap-drift.sh).
#
#   3. FULL-WIDTH-PARENTHESIS SCAN.
#      For every <stem>.ja.md (presence is enough to be in scope), scan for
#      U+FF08 (（) and U+FF09 (）) on any line. FAIL with file path + line
#      number for each occurrence. Lines carrying <!-- ref-allow: --> are
#      skipped (escape hatch). ASCII "(" and ")" do NOT trigger this check.
#
# ─────────────────────────────────────────────────────────────────────────
# IN-SCOPE KEYING — per-pair, not per-directory (ADR-018 §1 + 2026-05-17
# amendment):
#
#   In-scope is keyed PER FILE-PAIR: an EN .md is in-scope for presence-
#   parity iff its OWN co-located <stem>.ja.md sibling exists. Operationally:
#   for every <stem>.ja.md found (recursively, excluding .git/ and
#   workarounds/), that is a declared pair. In-scope is computed from the
#   artifact at scan time — no filename or path is enumerated in this script.
#   A future bilingual tree auto-includes when its first .ja.md lands; a
#   dropped pair auto-excludes when its .ja.md is removed.
#
#   The carve-out is not a second rule — it is the COMPLEMENT of the in-scope
#   rule: a lone <stem>.md with no <stem>.ja.md is simply not a pair and was
#   never in scope (same as a whole EN-only tree). This reasoning holds the
#   exemption surface flat (ADR-017's recorded Negative — "a maintainer must
#   hold N exemption concepts" — is answered by adding zero new concepts here).
#
#   workarounds/ is out of scope by the Spec's own Non-goals: registry entries
#   are not bilingual artifacts, so the convention-presence rule excludes them
#   without a special case. This is the rule subsuming a would-be exception.
#
#   NO ENUMERATED PATH ALLOWLIST ANYWHERE IN THIS SCRIPT (ADR-017 §4, ADR-018
#   §Decision 3): in-scope is always computed at scan time from .ja.md presence.
#
# ─────────────────────────────────────────────────────────────────────────
# THREE-WAY MECE-BY-CONTRACT BOUNDARY (ADR-018 §5):
#
#   The partition is drawn on CONTRACT, not file type. All three detectors
#   scan overlapping files (CLAUDE.md, ADRs, Specs), so the partition is on
#   what question each check answers:
#
#   | Check | Owns the question | Verb |
#   |-------|-------------------|------|
#   | #04 check-dangling-refs.sh    | Does the pointer RESOLVE to a real file/ADR?                             | resolution |
#   | #05 check-roadmap-drift.sh    | Does the bidirectional ROADMAP-INDEX CONTRACT hold + glyph well-formed? | Roadmap-index consistency |
#   | #06 check-bilingual-parity.sh | Does the EN↔JA PAIR AGREE structurally (heading tree, parens, presence)?| translation parity (THIS SCRIPT) |
#
#   A defect maps to exactly one owner:
#     - Broken pointer (target absent) → #04.
#     - Consistent pointer, broken Roadmap contract → #05.
#     - Structurally divergent EN/JA pair (heading count/order mismatch,
#       full-width paren in .ja.md, or orphaned .ja.md) → #06 (this script).
#   The Spec R-04 overlap zone — a .ja.md containing a broken ADR-NNN ref in
#   heading text — is #04's by resolution; #06 does NOT validate reference
#   resolution inside JA files at all (no two-owner ambiguity).
#
#   Concrete proof the boundary is load-bearing before #06 ships:
#   check-roadmap-drift.sh lines 349–357 already exclude .ja.md from its
#   reverse-direction scan, explicitly naming "milestone #06 (bilingual parity)"
#   as the contract owner. See ADR-018 §5.
#
# ─────────────────────────────────────────────────────────────────────────
# ESCAPE HATCH — `<!-- ref-allow: <reason> -->` (reused UNMODIFIED from
# #04/#05, per ADR-018 §Decision 4):
#   Add on the same line as the content to suppress. Applies ONLY to that
#   line. No `<!-- parity-allow: -->` variant — one escape vocabulary across
#   all three detectors keeps the conceptual load flat.
#
# Structure mirrors check-roadmap-drift.sh (#05, ADR-017): set -euo pipefail,
# git rev-parse root resolution, pass/warn/fail_check helpers, fail=0
# accumulator, exit "$fail", GITHUB_STEP_SUMMARY support, single-awk-pass
# scanning. ADR-018 is the design source; specs/06 the acceptance contract.
#
# See also: ADR-018, ADR-017, ADR-015, specs/06-bilingual-parity-detector.md

set -euo pipefail

# Resolve repo root robustly: prefer git, fall back to a relative walk.
if repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  :
else
  repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
fi
cd "$repo_root"

fail=0
pass()       { printf "  [PASS] %s\n" "$1"; }
warn()       { printf "  [WARN] %s\n" "$1" >&2; }
fail_check() {
  printf "  [FAIL] %s\n" "$1" >&2
  fail=1
}

# ---------------------------------------------------------------------------
# GITHUB_STEP_SUMMARY support (mirrors check-roadmap-drift.sh)
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
    summary_append "## Bilingual Parity Findings"
    summary_append ""
    summary_append "| File | Dimension | Detail |"
    summary_append "|------|-----------|--------|"
  fi
}

summary_finding() {
  summary_append "| \`$1\` | $2 | $3 |"
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

# Extract heading level sequence from a file (fence-aware, ref-allow-aware).
# Output: one level number (1-4) per line, in document order.
# Heading regex: ^#{1,4} (one to four # followed by a space).
# Fenced blocks (``` and ~~~) are skipped entirely.
# Lines with <!-- ref-allow: --> are skipped.
extract_heading_levels() {
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
    /^#{1,4} / {
      level = 0
      line = $0
      while (substr(line,1,1) == "#") { level++; line = substr(line,2) }
      # Double-check: only emit if level is 1-4 (the regex already ensures this)
      if (level >= 1 && level <= 4) print level
    }
  ' "$file"
}

# Extract the text of heading at ordinal position $2 (1-based) in file $1.
# Used only for human-readable failure messages, never for comparison.
heading_text_at() {
  local file="$1" target_pos="$2"
  awk -v target="$target_pos" '
    BEGIN { in_fence=0; fence_char=""; pos=0 }
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
    /^#{1,4} / {
      pos++
      if (pos == target) { print $0; exit }
    }
  ' "$file"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
echo "Bilingual parity checks"
echo "======================="

summary_header

# ---------------------------------------------------------------------------
echo ""
echo "Check 1: Presence parity (orphaned .ja.md detection)"
echo "  Scope: all *.ja.md files recursively, excluding .git/ and workarounds/"
echo "  FAIL if: <stem>.ja.md exists but <stem>.md does NOT."
echo "  PASS if: <stem>.md exists (regardless of whether <stem>.ja.md exists)."
echo "  NO EN→JA scan (a lone .md is the per-pair complement, NOT a failure)."
# ---------------------------------------------------------------------------
presence_fail_before="$fail"

while IFS= read -r ja_file; do
  # Derive the EN stem by stripping the .ja.md suffix
  en_file="${ja_file%.ja.md}.md"
  if [ ! -f "$en_file" ]; then
    fail_check "Presence parity: orphaned .ja.md with no .md counterpart: $ja_file"
    summary_finding "$ja_file" "presence-orphan" "no counterpart: $en_file"
  fi
done < <(find . -name "*.ja.md" \
    ! -path "./.git/*" \
    ! -path "./workarounds/*" \
    | sort)

if [ "$fail" = "$presence_fail_before" ]; then
  pass "No orphaned .ja.md files found"
fi

# ---------------------------------------------------------------------------
echo ""
echo "Check 2: Heading-tree parity (level+position, text-blind)"
echo "  Scope: every <stem>.md ∧ <stem>.ja.md pair (same exclusions as Check 1)."
echo "  FAIL if: heading level sequences differ in length OR positional level."
echo "  Heading regex: ^#{1,4} (space required; prose #-lines excluded)."
echo "  Fenced code blocks (and ~~~) are skipped."
# ---------------------------------------------------------------------------
heading_fail_before="$fail"

while IFS= read -r ja_file; do
  en_file="${ja_file%.ja.md}.md"
  [ -f "$en_file" ] || continue  # Skip orphans (caught by Check 1)

  # Extract level sequences into arrays via temp files
  en_levels_file="$(mktemp)"
  ja_levels_file="$(mktemp)"
  extract_heading_levels "$en_file" > "$en_levels_file"
  extract_heading_levels "$ja_file" > "$ja_levels_file"

  en_count="$(wc -l < "$en_levels_file" | tr -d ' ')"
  ja_count="$(wc -l < "$ja_levels_file" | tr -d ' ')"

  if [ "$en_count" != "$ja_count" ]; then
    fail_check "Heading-tree parity: heading count mismatch in pair: $en_file ↔ $ja_file (EN: $en_count, JA: $ja_count)"
    summary_finding "$ja_file" "heading-count" "EN=$en_count JA=$ja_count"
    rm -f "$en_levels_file" "$ja_levels_file"
    continue
  fi

  # Equal counts: compare level at each position
  mismatch_found=0
  pos=0
  while IFS= read -r en_level && IFS= read -r ja_level <&3; do
    pos=$((pos + 1))
    if [ "$en_level" != "$ja_level" ]; then
      en_text="$(heading_text_at "$en_file" "$pos")"
      ja_text="$(heading_text_at "$ja_file" "$pos")"
      fail_check "Heading-tree parity: level mismatch at heading position $pos in pair: $en_file ↔ $ja_file (EN level $en_level: '$en_text' / JA level $ja_level: '$ja_text')"
      summary_finding "$ja_file" "heading-level" "position $pos EN=L$en_level JA=L$ja_level"
      mismatch_found=1
      break
    fi
  done < "$en_levels_file" 3< "$ja_levels_file"

  rm -f "$en_levels_file" "$ja_levels_file"
done < <(find . -name "*.ja.md" \
    ! -path "./.git/*" \
    ! -path "./workarounds/*" \
    | sort)

if [ "$fail" = "$heading_fail_before" ]; then
  pass "All EN/JA pairs have matching heading-tree level sequences"
fi

# ---------------------------------------------------------------------------
echo ""
echo "Check 3: Full-width-parenthesis scan of .ja.md files"
echo "  Scope: every *.ja.md (same exclusions). Lines with <!-- ref-allow: --> skipped."
echo "  FAIL if: U+FF08 (（) or U+FF09 (）) appears on any unescaped line."
# ---------------------------------------------------------------------------
paren_fail_before="$fail"

while IFS= read -r ja_file; do
  # Single awk pass: fence-tracking + ref-allow skip + paren scan.
  # Use awk with a Unicode-safe approach: check for the UTF-8 byte sequences
  # of U+FF08 (（) = \xEF\xBC\x88 and U+FF09 (）) = \xEF\xBC\x89.
  # LC_ALL=C ensures awk treats the file as raw bytes (portable on macOS+Linux).
  while IFS=$'\t' read -r lineno; do
    [ -z "$lineno" ] && continue
    fail_check "Full-width-parenthesis: U+FF08/FF09 found in $ja_file at line $lineno"
    summary_finding "$ja_file" "full-width-paren" "line $lineno"
  done < <(LC_ALL=C awk '
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
    {
      # Match U+FF08 (（) UTF-8: \xEF\xBC\x88 and U+FF09 (）) UTF-8: \xEF\xBC\x89
      # In LC_ALL=C, these appear as raw byte sequences.
      # We match the three-byte sequence for each character.
      line = $0
      if (line ~ /\357\274\210/ || line ~ /\357\274\211/) {
        print NR
      }
    }
  ' "$ja_file")
done < <(find . -name "*.ja.md" \
    ! -path "./.git/*" \
    ! -path "./workarounds/*" \
    | sort)

if [ "$fail" = "$paren_fail_before" ]; then
  pass "No full-width parentheses found in any .ja.md file"
fi

# ---------------------------------------------------------------------------
echo ""
if [ "$fail" -gt 0 ]; then
  echo "Bilingual parity checks: FAIL"
  exit 1
fi
echo "Bilingual parity checks: PASS"
