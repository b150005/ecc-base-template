#!/usr/bin/env bash
# check-dangling-refs.sh
#
# Enforces cross-reference integrity for the template's design artifacts:
# CLAUDE.md, ADR files (.claude/meta/adr/*.md), Spec files (specs/*.md),
# and agent files (.claude/agents/*.md).
#
# This script complements check-skill-invariants.sh. The two checks are
# MECE by file-type/link-type partition (ADR-015, § Consequences):
#   - THIS SCRIPT owns: ADR-NNN textual references and .claude/-rooted
#     path mentions in CLAUDE.md, ADRs, Specs, and agent files.
#   - check-skill-invariants.sh Check 4 owns: relative-path links
#     (./foo, ../foo) INSIDE SKILL.md files only.
# A link is validated by exactly one of these two checks, never both.
# See ADR-015 for the full scope-boundary rationale.
#
# ADR-014 Reservation-rule carve-out (KEYED TO ROADMAP Design-source COLUMN ONLY):
#   ADR-014's Spec reservation rule makes a Roadmap `spec: specs/NN-slug.md`
#   link valid-by-design even when the file does not yet exist on disk.
#   This carve-out applies ONLY to references that:
#     1. Match the deterministic pattern: specs/<two-digit-NN>-<slug>.md
#     2. Appear inside a Roadmap table's Design-source cell (the last
#        column of a Markdown table row containing "spec:").
#   A non-reservation-shaped specs/ reference, or a specs/ path written
#   in prose elsewhere, is still validated normally.
#
# ADR-015 Amendment (2026-05-16) — Opt-in/default-off config WARN carve-out:
#   References to intentionally-absent .claude/-rooted .json/.yml/.yaml config
#   files are WARN, not FAIL, when the absence is documented as a valid state
#   co-located with the reference. The exemption is keyed to structural context:
#     - A sibling <path>.example file exists on disk, OR
#     - The referencing-line paragraph (within ±10 lines) carries one of the
#       fixed opt-in vocabulary tokens: "absent", "default-off", "opt-in".
#   An absent .claude/ config WITHOUT a co-located opt-in signal and WITHOUT
#   an .example sibling stays FAIL — a bare typo'd config path has no
#   "absent is fine" context beside it.
#   See ADR-015 Amendment 2026-05-16 for the full Reference-intent rule.
#
# Class A — Placeholder-token skip (applied in check_path_refs_in_file):
#   In addition to the existing glob/template skip (*, ?, <, >), path tokens
#   whose deterministic numeric slot is a run of ≥2 literal "N" characters
#   (e.g. specs/NN-slug.md, specs/NNN-slug.md) are treated as metasyntactic
#   documentation placeholders and skipped. A real-digit path like
#   specs/14-foo.md is still validated. This is identical in spirit to the
#   existing glob/template-token skip.
#   For Check 1 (ADR references): ADR-NNN (literal N) is already NOT matched
#   by the ADR-[0-9]+ awk regex, so no code change is needed there.
#
# Escape hatch — suppress a specific reference on one line:
#   Add `<!-- ref-allow: <reason> -->` on the same line as the reference.
#   Example:
#     See ADR-999 for details. <!-- ref-allow: placeholder, not yet written -->
#   The escape applies ONLY to that line; the rest of the file is unaffected.
#
# Checks:
#   1. ADR-NNN textual references in CLAUDE.md, ADRs, Specs, and agents:
#      normalize to 3-digit zero-pad and verify .claude/meta/adr/NNN-*.md exists.
#      Fenced code blocks are skipped. Inline code spans are also stripped
#      (ADR-NNN inside `backticks` is a variable name / example, not a ref).
#   2. .claude/-rooted path strings in CLAUDE.md and Specs (NOT ADR files or
#      agent files — see decision below) must resolve to a real file or directory.
#      Also checks specs/ prose references in CLAUDE.md and Specs (non-reservation).
#      Fenced code blocks are skipped. Inline code spans ARE scanned because
#      `.claude/skills/foo/SKILL.md` in prose backticks is a genuine reference.
#
#      SCOPE DECISION — why ADR files are excluded from Check 2:
#      ADR files are historical design records. ADRs document paths as they
#      existed at time of writing; when a path is later renamed (e.g. ADR-003
#      renamed .claude/growth/ to .claude/learn/), the older ADR correctly
#      records the pre-rename path. Validating those historical paths would
#      produce false positives on every prior-architecture reference and would
#      force adding ref-allow to every historical ADR line. The meaningful
#      Check 2 surface is CLAUDE.md (always-read by agents) and Specs (the
#      implementation contract). Agent files are also excluded for similar
#      reasons (conceptual/example paths).
#
# See also: ADR-015, specs/04-dangling-reference-detector.md

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
# GITHUB_STEP_SUMMARY support
# ---------------------------------------------------------------------------
# Append a markdown line to $GITHUB_STEP_SUMMARY when running under GitHub
# Actions. Guards against the 1 MiB/step soft limit by capping at 200 lines.
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
    summary_append "## Dangling Reference Findings"
    summary_append ""
    summary_append "| File | Line | Kind | Reference |"
    summary_append "|------|------|------|-----------|"
  fi
}

summary_finding() {
  summary_append "| \`$1\` | $2 | $3 | \`$4\` |"
}

# ---------------------------------------------------------------------------
# Normalization helpers
# ---------------------------------------------------------------------------

# Normalize an ADR number (possibly with leading zeros) to exactly 3 digits.
# Strips leading zeros before printf to avoid bash treating "009" as octal.
normalize_adr_num() {
  local raw="$1"
  local stripped
  stripped=$(printf '%s' "$raw" | sed 's/^0*//')
  stripped="${stripped:-0}"
  printf '%03d' "$stripped"
}

# Return true (0) if a matching .claude/meta/adr/NNN-*.md exists.
adr_exists() {
  local num="$1"  # already 3-digit padded
  local pattern=".claude/meta/adr/${num}-*.md"
  local found
  found="$(compgen -G "$pattern" 2>/dev/null || true)"
  [ -n "$found" ]
}

# Return true (0) if the line carries the ref-allow escape hatch.
has_ref_allow() {
  case "$1" in
    *"<!-- ref-allow:"*) return 0 ;;
  esac
  return 1
}

# Return true (0) if the path is a Roadmap reservation link (ADR-014 carve-out).
# Criteria: path matches specs/NN-slug.md AND the line is a Roadmap table row.
is_reservation_link() {
  local path="$1" line="$2"
  # Pattern: specs/ + exactly 2 digits + hyphen + slug + .md
  case "$path" in
    specs/[0-9][0-9]-*.md)
      # Must appear in a Roadmap table row (pipe-delimited, contains "spec:")
      case "$line" in
        *"|"*"spec:"*) return 0 ;;
      esac
      ;;
  esac
  return 1
}

# Return true (0) if the absent .claude/ config path is exempt under the
# ADR-015 Amendment 2026-05-16 opt-in/default-off WARN carve-out.
# Exemption conditions (either/or):
#   1. A sibling <path>.example exists on disk.
#   2. The paragraph context (±10 lines around lineno in file) carries
#      one of the fixed vocabulary tokens: "absent", "default-off", "opt-in".
# This is keyed to co-located structural context, not a blanket config exemption.
is_optin_absent_config() {
  local file="$1" lineno="$2" path="$3"

  # Condition 1: .example sibling exists
  if [ -e "${path}.example" ]; then
    return 0
  fi

  # Condition 2: paragraph context carries opt-in vocabulary (±10 lines)
  local ctx_start ctx_end context
  ctx_start=$((lineno > 10 ? lineno - 10 : 1))
  ctx_end=$((lineno + 10))
  context="$(sed -n "${ctx_start},${ctx_end}p" "$file" 2>/dev/null || true)"
  case "$context" in
    *absent* | *"default-off"* | *"opt-in"*)
      return 0
      ;;
  esac

  return 1
}

# Strip inline code spans from a line (`...` → removed).
strip_inline_code() {
  printf '%s' "$1" | sed 's/`[^`]*`//g'
}

# ---------------------------------------------------------------------------
# Check 1: ADR-NNN references
# ---------------------------------------------------------------------------
# Scans a file in a single awk pass (no per-line subshells).
# Skips fenced code blocks (``` and ~~~) and inline code spans.
# Skips lines with the <!-- ref-allow: --> escape hatch.
# Outputs "LINENO:RAW_LINE:ADR_NUM" for each ADR reference found outside fences.
#
# Note: ADR-NNN where the numeric slot contains literal "N" characters (e.g.
# ADR-NNN in prose) is already NOT matched by the ADR-[0-9]+ regex, so no
# additional code is needed for Class A placeholder recognition in Check 1.
check_adr_refs_in_file() {
  local file="$1"

  # Single awk pass: fence tracking + escape-hatch + inline-code-strip + ADR extraction.
  # Output format per hit: LINENO\tRAW_LINE\tADR_NUM
  while IFS=$'\t' read -r lineno raw_line adr_num; do
    [ -z "$adr_num" ] && continue
    local padded
    padded="$(normalize_adr_num "$adr_num")"
    if ! adr_exists "$padded"; then
      fail_check "$file:$lineno: dangling-adr: ADR-${adr_num} (normalized ADR-${padded}) — no .claude/meta/adr/${padded}-*.md"
      printf "    line: %s\n" "$raw_line" >&2
      summary_finding "$file" "$lineno" "dangling-adr" "ADR-${padded}"
    fi
  done < <(awk '
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
      raw = $0
      line = $0
      # Strip inline code spans (ADR-NNN inside backticks is a code example)
      while (match(line, /`[^`]*`/)) {
        line = substr(line, 1, RSTART-1) substr(line, RSTART+RLENGTH)
      }
      # Extract each ADR-NNN token on this line (digits only; ADR-NNN with
      # literal-N numeric slots is not matched by [0-9]+, so no extra skip needed)
      while (match(line, /ADR-[0-9]+/)) {
        num = substr(line, RSTART+4, RLENGTH-4)
        print NR "\t" raw "\t" num
        line = substr(line, RSTART+RLENGTH)
      }
    }
  ' "$file")
}

# ---------------------------------------------------------------------------
# Check 2: .claude/-rooted and specs/ path references
# ---------------------------------------------------------------------------
# Scans fenced code blocks (skipped) but scans inline code spans (genuine refs).
# Uses a single awk pass per file to avoid per-line subshells.
# Output format per hit: LINENO\tRAW_LINE\tPATH_TYPE\tPATH
#   PATH_TYPE: "claude" for .claude/ paths, "specs" for specs/ paths
#
# NOTE on path extraction: We scan the RAW line (not inline-code-stripped)
# because `.claude/skills/bar/SKILL.md` in backtick prose IS a genuine reference.
# Path terminators excluded from the character class: whitespace, backtick, quote,
# paren, pipe. We do NOT include \] — BSD grep treats \] inside a bracket
# expression inconsistently; the simpler class is portable and correct.
#
# Placeholder-token skip (Class A):
#   Paths containing *, ?, <, > are skipped (existing glob/template skip).
#   Additionally, paths whose segment at the deterministic numeric slot is a
#   run of ≥2 literal "N" characters are skipped as metasyntactic placeholders
#   (e.g. specs/NN-slug.md, specs/NNN-slug.md, any path matching */NN-* or
#   */NNN-*). A real-digit path like specs/14-foo.md is still validated.
#
# ADR-014 reservation carve-out is applied in the bash loop (not in awk)
# because the is_reservation_link helper uses bash case patterns.
#
# ADR-015 Amendment opt-in-config WARN carve-out is applied in the bash loop
# via the is_optin_absent_config helper.
check_path_refs_in_file() {
  local file="$1"

  while IFS=$'\t' read -r lineno raw_line path_type path; do
    [ -z "$path" ] && continue

    # Skip glob/template paths (existing Class A — *, ?, <, >, ..)
    case "$path" in *".."* | *"*"* | *"?"* | *"<"* | *">"*) continue ;; esac

    # Skip literal-N numeric-slot placeholder paths (Class A extension):
    # specs/NN-* and specs/NNN-* are metasyntactic (ADR-014 reservation notation).
    # Any path with /NN- or /NNN- in a segment is also a placeholder.
    case "$path" in
      specs/NN-* | specs/NNN-* | */NN-* | */NNN-*) continue ;;
    esac

    if [ "$path_type" = "specs" ]; then
      # Apply the ADR-014 reservation carve-out for Roadmap Design-source cells.
      is_reservation_link "$path" "$raw_line" && continue
    fi

    if [ ! -e "$path" ]; then
      # Class B: opt-in/default-off absent .claude/ config WARN carve-out
      # (ADR-015 Amendment 2026-05-16). Only applies to .json/.yml/.yaml under
      # .claude/ when co-located structural context signals "absence is valid".
      case "$path" in .claude/*.json | .claude/*.yml | .claude/*.yaml)
        if is_optin_absent_config "$file" "$lineno" "$path"; then
          warn "$file:$lineno: opt-in-config-absent (WARN not FAIL): $path — intentionally absent opt-in/default-off config (ADR-015 amendment)"
          continue
        fi
        ;;
      esac

      fail_check "$file:$lineno: dangling-path: $path"
      printf "    line: %s\n" "$raw_line" >&2
      summary_finding "$file" "$lineno" "dangling-path" "$path"
    fi
  done < <(awk '
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
      raw = $0
      # Extract .claude/-rooted paths
      line = $0
      while (match(line, /\.claude\/[^ \t`"'"'"'()|]+/)) {
        path = substr(line, RSTART, RLENGTH)
        # Strip trailing punctuation
        gsub(/[,;.]+$/, "", path)
        print NR "\t" raw "\t" "claude" "\t" path
        line = substr(line, RSTART+RLENGTH)
      }
      # Extract specs/ paths
      line = $0
      while (match(line, /specs\/[^ \t`"'"'"'()|]+/)) {
        path = substr(line, RSTART, RLENGTH)
        gsub(/[,;.]+$/, "", path)
        print NR "\t" raw "\t" "specs" "\t" path
        line = substr(line, RSTART+RLENGTH)
      }
    }
  ' "$file")
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
echo "Dangling reference checks"
echo "========================="

summary_header

# -----------------------------------------------------------------------
echo ""
echo "Check 1: ADR-NNN textual references"
echo "  Scope: CLAUDE.md, .claude/meta/adr/*.md, specs/*.md, .claude/agents/*.md"
echo "  Normalization: ADR-7 = ADR-007. Fenced code blocks and inline code spans skipped."
# -----------------------------------------------------------------------

adr_fail_before="$fail"
shopt -s nullglob

# CLAUDE.md
[ -f ".claude/CLAUDE.md" ] && check_adr_refs_in_file ".claude/CLAUDE.md"

# ADR files (including .ja.md)
for f in .claude/meta/adr/*.md; do
  [ -f "$f" ] && check_adr_refs_in_file "$f"
done

# Spec files
for f in specs/*.md; do
  [ -f "$f" ] && check_adr_refs_in_file "$f"
done

# Agent files
for f in .claude/agents/*.md; do
  [ -f "$f" ] && check_adr_refs_in_file "$f"
done

shopt -u nullglob

if [ "$fail" = "$adr_fail_before" ]; then
  pass "All ADR-NNN references resolve"
fi

# -----------------------------------------------------------------------
echo ""
echo "Check 2: .claude/-rooted and specs/ path references"
echo "  Scope: CLAUDE.md, specs/*.md (ADR and agent files excluded — see script header)."
echo "  ADR-014 carve-out: specs/NN-slug.md in Roadmap Design-source cells."
echo "  ADR-015 amendment: absent .claude/ config with opt-in signal → WARN not FAIL."
# -----------------------------------------------------------------------

path_fail_before="$fail"
shopt -s nullglob

[ -f ".claude/CLAUDE.md" ] && check_path_refs_in_file ".claude/CLAUDE.md"

# ADR files excluded from Check 2 (historical records; see scope decision in script header).

for f in specs/*.md; do
  [ -f "$f" ] && check_path_refs_in_file "$f"
done

shopt -u nullglob

if [ "$fail" = "$path_fail_before" ]; then
  pass "All .claude/-rooted and specs/ path references resolve"
fi

# -----------------------------------------------------------------------
echo ""
if [ "$fail" -gt 0 ]; then
  echo "Dangling reference checks: FAIL"
  exit 1
fi
echo "Dangling reference checks: PASS"
