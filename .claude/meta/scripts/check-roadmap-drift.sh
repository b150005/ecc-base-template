#!/usr/bin/env bash
# check-roadmap-drift.sh
#
# Enforces Roadmap *index consistency* for the template's single always-read
# entry point: the `## Roadmap` table in .claude/CLAUDE.md (ADR-014) and the
# ADR back-links under .claude/meta/adr/. This is milestone #05; the
# authoritative scope is specs/05-roadmap-drift-detection-ci.md and the
# structural keying/boundary/parsing decisions are ADR-017.
#
# ─────────────────────────────────────────────────────────────────────────
# THE THREE DRIFT CLASSES THIS SCRIPT FAILS ON (and ONLY these), per ADR-017 §1:
#
#   1. FORWARD direction of the ADR-014 bidirectional-link contract.
#      A Roadmap row whose `Design source` cell carries an `adr:` link to a
#      file that EXISTS on disk, but whose `## References` section does NOT
#      contain a `Roadmap row: #NN` back-link matching that row's number.
#
#   2. REVERSE direction of the same contract.
#      An ADR under .claude/meta/adr/ whose `## References` section carries a
#      `Roadmap row: #NN` back-link line where Roadmap row #NN's `Design
#      source` cell does NOT list an `adr:` link to that ADR file.
#
#   3. STATUS-GLYPH well-formedness.
#      A Roadmap row whose Status cell contains any character other than the
#      four ADR-014-sanctioned glyphs: ☐ todo / ◐ in-progress / ☑ done /
#      ✗ dropped.
#
#   Also FAIL (no carve-out covers it): a Roadmap `adr:` link pointing to a
#   path that does NOT exist on disk. Unlike `spec:` reserved links (valid-
#   by-design absent — that is the #04 detector's ADR-014 reservation carve-
#   out), an `adr:` link is added by `architect` only at the moment the ADR
#   is written (ADR-014 write-ownership), so a non-existent `adr:` target is
#   never valid-by-design. This DELIBERATELY overlaps the #04 detector (see
#   the MECE boundary block below); the overlap is a stronger signal, not a
#   boundary violation — the two checks answer different questions ("does it
#   resolve?" vs. "is the contract satisfied?") about one symptom.
#
# ─────────────────────────────────────────────────────────────────────────
# ABSENCE-OF-CLAIM EXEMPTION (the false-positive guard), per ADR-017 §1/§4:
#
#   "Every ADR must carry a Roadmap back-link" is NOT checked. Per ADR-017 §1
#   there are two distinct exempt categories, not one numeric range: (a) ADRs
#   that predate Roadmap dogfooding, and (b) ADRs that record a decision for
#   the Roadmap mechanism itself (e.g. ADR-014) rather than for a discrete
#   milestone; future ADRs may also record cross-cutting decisions with no
#   single milestone. No ADR-number range is enumerated here — any range
#   would go stale as ADRs grow. An ADR is EXEMPT from the bidirectional
#   contract IFF its `## References` section contains no `Roadmap row: #<digit>`
#   back-link line at all. Absence of the claim is the valid-by-design state;
#   this detector keys *consistency when a claim is present*, never
#   *universality of claims*.
#
#   The exemption is computed PER-ADR at scan time from the artifact's own
#   structure (presence/absence of the back-link line). Enumerating exempt
#   ADR filenames in this script is FORBIDDEN (ADR-017 §4): it is the ad-hoc-
#   allowlist anti-pattern ADR-015's amendment explicitly rejected — it fails
#   open silently as ADRs are added and carries per-ADR maintenance cost.
#
# ─────────────────────────────────────────────────────────────────────────
# MECE SCOPE BOUNDARY against check-dangling-refs.sh (#04) and
# check-bilingual-parity.sh (#06), per ADR-017 §2 and ADR-018 §5:
#
#   The partition is drawn on CONTRACT, not file type (all three checks scan
#   overlapping files — CLAUDE.md, ADRs, Specs, .ja.md pairs):
#     - check-dangling-refs.sh (#04) owns RESOLUTION: does a pointer resolve
#       to a real file/ADR? (ADR-NNN refs, .claude/-rooted paths, specs/ refs)
#     - check-roadmap-drift.sh (#05, THIS SCRIPT) owns CONSISTENCY: does the
#       bidirectional index contract hold in BOTH directions, and is every
#       Status glyph well-formed?
#     - check-bilingual-parity.sh (#06) owns PARITY: does the EN↔JA pair
#       agree structurally (heading-tree, full-width-paren scan, presence)?
#   A defect maps to exactly one owner: a *broken pointer* (target absent) is
#   #04's; a *consistent-pointer-but-inconsistent-contract* defect (both
#   files exist, back-link missing or glyph unsanctioned) is #05's; a
#   *structurally divergent EN/JA pair* (heading count/order mismatch, full-
#   width paren in .ja.md, or orphaned .ja.md) is #06's. The single
#   deliberate overlap (a Roadmap `adr:` link whose target is absent) is
#   owned PRIMARILY by #04 for resolution; #05 ALSO fails it because an
#   absent `adr:` target is by definition a broken bidirectional contract.
#   check-dangling-refs.sh and check-bilingual-parity.sh carry reciprocal
#   notes so the partition is discoverable from all three sides.
#
# ─────────────────────────────────────────────────────────────────────────
# Parsing constraints (ADR-017 §4 — structural requirements, not the bash):
#
#   - Multi-line `Design source` cell. Roadmap rows join multiple design-
#     source links with `<br>` inside a single Markdown table cell (rows
#     #03/#04/#05 carry `spec: …<br>adr: …`). The parser treats the cell as
#     a `<br>`-joined unit and extracts EVERY `adr:` link in it, not only
#     the first/last. A line-greedy single-match parser is forbidden
#     (ADR-014 permits 1:N row→ADR).
#   - Exemption keyed to absence-of-claim, never a path allowlist (above).
#
# Escape hatch — suppress a specific reference on one line (reused from #04
# UNMODIFIED): add `<!-- ref-allow: <reason> -->` on the same line; the
# escape applies ONLY to that line.
#
# Structure mirrors check-dangling-refs.sh (#04, ADR-015): set -euo pipefail,
# git rev-parse root resolution, pass/warn/fail_check helpers, fail=0
# accumulator, exit "$fail", GITHUB_STEP_SUMMARY support, single-awk-pass
# scanning. ADR-017 is the design source; specs/05 the acceptance contract.
#
# See also: ADR-017, ADR-014, ADR-015, specs/05-roadmap-drift-detection-ci.md

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
# GITHUB_STEP_SUMMARY support (mirrors check-dangling-refs.sh)
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
    summary_append "## Roadmap Drift Findings"
    summary_append ""
    summary_append "| Row | Kind | Detail |"
    summary_append "|-----|------|--------|"
  fi
}

summary_finding() {
  summary_append "| $1 | $2 | \`$3\` |"
}

CLAUDE_MD=".claude/CLAUDE.md"
ADR_DIR=".claude/meta/adr"

# ---------------------------------------------------------------------------
# Roadmap table parsing
# ---------------------------------------------------------------------------
# The Roadmap table lives under the "## Roadmap" heading in CLAUDE.md. Rows
# look like:
#   | 03 | Milestone text | ☑ done | spec: `specs/03-x.md`<br>adr: `.claude/meta/adr/016-x.md` |
# We parse only rows whose first cell is a 1+ digit row number (data rows),
# skipping the header row and the `|---|` separator. The Design-source cell
# is the LAST pipe-delimited column; it is `<br>`-joined and may carry
# multiple `adr:` links (ADR-014 permits 1:N).
#
# Output of parse_roadmap_rows (one logical record per data row, tab-joined):
#   ROWNUM \t STATUS_CELL \t DESIGN_SOURCE_CELL
# A line carrying the ref-allow escape hatch is skipped entirely (the #04
# escape-hatch contract, reused unmodified — Spec acceptance criterion).
parse_roadmap_rows() {
  awk '
    BEGIN { in_roadmap=0 }
    /^## / {
      in_roadmap = ($0 ~ /^## Roadmap[[:space:]]*$/) ? 1 : 0
      next
    }
    !in_roadmap { next }
    /<!-- ref-allow:/ { next }
    # Data rows start with "| <digits> |"
    /^\|[[:space:]]*[0-9]+[[:space:]]*\|/ {
      n = split($0, cell, "|")
      # cell[1] is empty (leading pipe). Row number is cell[2].
      rownum = cell[2]
      gsub(/[[:space:]]/, "", rownum)
      # Trailing pipe yields an empty final element; the Design-source cell
      # is the last NON-empty cell. Status is the cell before it.
      last = n
      while (last > 1 && cell[last] ~ /^[[:space:]]*$/) last--
      design = cell[last]
      status = cell[last-1]
      print rownum "\t" status "\t" design
    }
  ' "$CLAUDE_MD"
}

# Extract every `adr:` target path from a Design-source cell value.
# The cell is `<br>`-joined; each segment may be `adr: \`.claude/..md\``.
# Emits one path per line (backticks and surrounding space stripped).
extract_adr_links() {
  local cell="$1"
  # Normalize <br> (and <br/>, <br />) to newlines, then pull adr: targets.
  printf '%s\n' "$cell" \
    | sed -E 's@<br[[:space:]]*/?>@\n@g' \
    | awk '
        /adr:/ {
          line = $0
          # adr: `path`  — capture between backticks if present, else the
          # first whitespace-delimited token after "adr:".
          if (match(line, /adr:[[:space:]]*`[^`]+`/)) {
            seg = substr(line, RSTART, RLENGTH)
            sub(/adr:[[:space:]]*`/, "", seg)
            sub(/`.*/, "", seg)
            print seg
          } else if (match(line, /adr:[[:space:]]*[^ \t|]+/)) {
            seg = substr(line, RSTART, RLENGTH)
            sub(/adr:[[:space:]]*/, "", seg)
            print seg
          }
        }
      '
}

# Normalize a row number to the bare integer form used in `Roadmap row: #NN`
# back-links (the back-link uses the row number as written; ADR-014 keeps
# row numbers stable and zero-pads to two digits in the table, e.g. "03",
# but back-links are written "#03"/"#3" interchangeably across ADRs). We
# compare on the integer value to be robust to zero-padding on either side.
to_int() {
  local raw="$1" stripped
  stripped=$(printf '%s' "$raw" | sed 's/^0*//')
  printf '%d' "${stripped:-0}"
}

# Return true (0) if ADR file $1 contains a real `Roadmap row: #<digit>`
# back-link LINE in its References section (a markdown list item), and echo
# the integer row number it claims. A prose/illustrative mention with a
# literal "#NN" (non-digit) is NOT a claim — this mirrors #04's discipline
# of keying on ADR-[0-9]+ (literal-N slots are never matched).
#
# ONE-CLAIM-PER-ADR ASSUMPTION (the `head -1`): an ADR claims at most one
# Roadmap row. ADR-014's cardinality is Milestone→ADR 0:1 or 1:N (one
# milestone, possibly many ADRs) — NOT one ADR claiming many milestones; no
# ADR in the template carries two `Roadmap row:` back-link lines. The
# narrowest surface is taken deliberately (ADR-017's "smallest surface"
# discipline): if a future cross-cutting ADR ever needs to claim two rows,
# this `head -1` and Check 3's single-claim loop become the documented
# extension point, not a silent miss.
adr_backlink_rownum() {
  local file="$1" m
  m="$(grep -Eo '^[[:space:]]*[-*][[:space:]]+Roadmap row: #[0-9]+' "$file" 2>/dev/null \
        | grep -Eo '#[0-9]+' | head -1 || true)"
  if [ -n "$m" ]; then
    to_int "${m#\#}"
    return 0
  fi
  return 1
}

# Return true (0) if the line carries the ref-allow escape hatch.
has_ref_allow() {
  case "$1" in
    *"<!-- ref-allow:"*) return 0 ;;
  esac
  return 1
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
echo "Roadmap drift checks"
echo "===================="

summary_header

if [ ! -f "$CLAUDE_MD" ]; then
  fail_check "no $CLAUDE_MD — cannot check Roadmap drift"
  echo ""
  echo "Roadmap drift checks: FAIL"
  exit 1
fi

# Build the parsed row table once (rownum -> status, design cell).
roadmap_records="$(parse_roadmap_rows)"

# -----------------------------------------------------------------------
echo ""
echo "Check 1: Status-glyph well-formedness (ADR-014 four-glyph contract)"
echo "  Sanctioned: ☐ todo / ◐ in-progress / ☑ done / ✗ dropped"
# -----------------------------------------------------------------------
glyph_fail_before="$fail"
if [ -n "$roadmap_records" ]; then
  while IFS=$'\t' read -r rownum status design; do
    [ -z "$rownum" ] && continue
    # The status cell must contain exactly one of the four sanctioned glyphs.
    case "$status" in
      *☐* | *◐* | *☑* | *✗*) : ;;
      *)
        bad="$(printf '%s' "$status" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        fail_check "Roadmap row #$rownum: Status cell has no sanctioned glyph (☐/◐/☑/✗); found: '$bad'"
        summary_finding "#$rownum" "status-glyph" "$bad"
        ;;
    esac
  done <<< "$roadmap_records"
fi
if [ "$fail" = "$glyph_fail_before" ]; then
  pass "All Roadmap Status cells use a sanctioned glyph"
fi

# -----------------------------------------------------------------------
echo ""
echo "Check 2: Forward bidirectional contract (Roadmap adr: → ADR back-link)"
echo "  A row's adr: target must exist AND back-link the row in ## References."
# -----------------------------------------------------------------------
fwd_fail_before="$fail"
if [ -n "$roadmap_records" ]; then
  while IFS=$'\t' read -r rownum status design; do
    [ -z "$rownum" ] && continue
    row_int="$(to_int "$rownum")"
    while IFS= read -r adr_path; do
      [ -z "$adr_path" ] && continue
      if [ ! -e "$adr_path" ]; then
        # No carve-out covers a non-existent adr: target (deliberate #04
        # overlap — see MECE boundary header). Always drift.
        fail_check "Roadmap row #$rownum: adr: target does not exist on disk: $adr_path"
        summary_finding "#$rownum" "adr-target-absent" "$adr_path"
        continue
      fi
      claimed=""
      if claimed="$(adr_backlink_rownum "$adr_path")"; then
        if [ "$claimed" != "$row_int" ]; then
          fail_check "Roadmap row #$rownum: $adr_path back-links 'Roadmap row: #$claimed' but is listed under row #$rownum (forward-direction drift)"
          summary_finding "#$rownum" "forward-mismatch" "$adr_path #$claimed"
        fi
      else
        fail_check "Roadmap row #$rownum: $adr_path has no 'Roadmap row: #$rownum' back-link in its ## References (forward-direction drift)"
        summary_finding "#$rownum" "forward-missing" "$adr_path"
      fi
    done < <(extract_adr_links "$design")
  done <<< "$roadmap_records"
fi
if [ "$fail" = "$fwd_fail_before" ]; then
  pass "All Roadmap adr: links are back-linked by their target ADR"
fi

# -----------------------------------------------------------------------
echo ""
echo "Check 3: Reverse bidirectional contract (ADR back-link → Roadmap adr:)"
echo "  An ADR claiming 'Roadmap row: #NN' must be listed in row #NN's adr: cell."
echo "  ABSENCE-OF-CLAIM EXEMPTION: an ADR with no back-link line is exempt."
# -----------------------------------------------------------------------
rev_fail_before="$fail"
shopt -s nullglob
for adr_file in "$ADR_DIR"/*.md; do
  [ -f "$adr_file" ] || continue
  # Scope: canonical .md ADRs only. A .ja.md file is the technical-writer-
  # owned translation of its .md parent (ADR-014 write-ownership / the
  # bilingual-ADR convention); the Roadmap `adr:` cell links the canonical
  # .md by convention, never the translation. A .ja.md is a DERIVED artifact,
  # not an independent claim-bearer, so it is excluded from the reverse-
  # direction scan — exactly as #04 excludes derived/historical artifacts
  # from a check. EN/JA back-link parity is a distinct contract owned by
  # milestone #06 (bilingual parity), explicitly a Spec Non-goal here.
  case "$adr_file" in *.ja.md) continue ;; esac
  # Absence-of-claim exemption (ADR-017 §1/§4): no back-link line → exempt.
  claimed=""
  claimed="$(adr_backlink_rownum "$adr_file" || true)"
  [ -z "$claimed" ] && continue

  # The ADR claims Roadmap row #$claimed. That row's Design-source cell must
  # list an adr: link to THIS file. Compare on resolved path.
  adr_rel="$adr_file"
  matched=0
  if [ -n "$roadmap_records" ]; then
    while IFS=$'\t' read -r rownum status design; do
      [ -z "$rownum" ] && continue
      [ "$(to_int "$rownum")" = "$claimed" ] || continue
      while IFS= read -r adr_path; do
        [ -z "$adr_path" ] && continue
        if [ "$adr_path" = "$adr_rel" ]; then
          matched=1
        fi
      done < <(extract_adr_links "$design")
    done <<< "$roadmap_records"
  fi
  if [ "$matched" -ne 1 ]; then
    fail_check "$adr_file: claims 'Roadmap row: #$claimed' but row #$claimed's Design-source cell does not list an adr: link to this file (reverse-direction drift)"
    summary_finding "#$claimed" "reverse-missing" "$adr_file"
  fi
done
shopt -u nullglob
if [ "$fail" = "$rev_fail_before" ]; then
  pass "All ADR Roadmap back-links are reflected in their claimed row's adr: cell"
fi

# -----------------------------------------------------------------------
echo ""
if [ "$fail" -gt 0 ]; then
  echo "Roadmap drift checks: FAIL"
  exit 1
fi
echo "Roadmap drift checks: PASS"
