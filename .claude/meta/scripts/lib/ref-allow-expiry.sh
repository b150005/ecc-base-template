#!/usr/bin/env bash
# lib/ref-allow-expiry.sh
#
# Shared library for ref-allow expiry detection (Roadmap #18, ADR-022).
#
# PURPOSE
#   Provides two functions sourced by the five ref-allow-consuming detectors:
#     1. parse_ref_allow_expiry  -- extracts the ISO 8601 expiry date from a
#                                   ref-allow marker, if present
#     2. check_ref_allow_expiry  -- compares the expiry date to today and
#                                   emits a [WARN] when it has passed
#
# SYNTAX FORMS (ADR-022 §2)
#   Grandfather / no-expiry (permanent, never WARNs):
#     <!-- ref-allow: <reason> -->
#   Optional-expires form (WARNs if date is past):
#     <!-- ref-allow: <reason> | expires: YYYY-MM-DD -->
#
# GRANDFATHER RULE (AC-5, ADR-022 §2)
#   A marker with no `expires:` clause produces no WARN, no FAIL, and no
#   changed behaviour. The no-expiry form is permanent and never deprecated.
#
# WARN-NOT-FAIL (AC-3, ADR-022 §3)
#   When a date has passed, a [WARN] is emitted to stderr and the function
#   returns 0. The marker's suppression is NOT withdrawn; the line is still
#   considered suppressed for the current detector run. Only the WARN signal
#   is emitted.
#
# DATE COMPARISON (ADR-022 §2)
#   Comparison is against `date -u +%Y-%m-%d` (UTC calendar date).
#   Lexicographic string comparison of YYYY-MM-DD is equivalent to
#   chronological comparison for zero-padded ISO 8601 dates (portable on
#   macOS bash and Linux bash without date arithmetic).
#   A past date satisfies: today > expiry_date (lexicographic).
#
# ISO 8601 FORMAT (AC-1)
#   Only `YYYY-MM-DD` (four-digit year, two-digit month, two-digit day,
#   hyphen-separated) is accepted. Any other format is treated as absent
#   (no expiry), which means the marker behaves as a permanent grandfather.
#
# USAGE IN A DETECTOR
#   After `has_ref_allow "$line"` returns 0 (i.e., the line is suppressed),
#   parse the expiry date and conditionally emit a WARN:
#
#     if has_ref_allow "$line"; then
#       expiry="$(parse_ref_allow_expiry "$line")"
#       check_ref_allow_expiry "$file" "$lineno" "$reason" "$expiry"
#       return 0  # (or `continue`, depending on context)
#     fi
#
#   The calling detector passes the reason string for the WARN message.
#   A convenience wrapper parse_and_warn_ref_allow is also provided (see below).
#
# MECE NOTE
#   This library is only for the five ref-allow-consuming detectors:
#     check-bilingual-parity.sh, check-dangling-refs.sh,
#     check-ecc-delegation-consistency.sh, check-roadmap-drift.sh,
#     check-research-tier-auth.sh
#   check-skill-invariants.sh uses a separate is_exempt() mechanism and is
#   NOT amended by this library (Spec Non-goals, ADR-022 §6).
#
# See: ADR-022, specs/18-ci-exemption-allowlist-expiry.md

# ---------------------------------------------------------------------------
# parse_ref_allow_expiry  <line>
#
# Extracts the ISO 8601 expiry date from a ref-allow marker line.
# Returns (prints) the date string if found, or empty string if absent.
#
# Accepts the form: <!-- ref-allow: <reason> | expires: YYYY-MM-DD -->
# The `|` delimiter may have surrounding whitespace.
# Only strict YYYY-MM-DD (digits only in each slot) is accepted; any other
# form is treated as absent.
#
# Exit code: always 0.
# ---------------------------------------------------------------------------
parse_ref_allow_expiry() {
  local line="$1"
  local date_part=""

  # Extract the substring after "expires:" up to the end of the comment "-->"
  # Strategy: match "expires:" followed by optional whitespace and a date token,
  # stopping at whitespace, " -->" or end-of-string.
  # We use printf + sed for portability (no bash regex extension needed).
  date_part="$(printf '%s' "$line" \
    | sed -n 's/.*expires:[[:space:]]*\([^ \t|>-][^ \t|>]*\).*/\1/p' \
    | head -1 \
    | sed 's/[[:space:]]*-*>[[:space:]]*$//' \
    | sed 's/[[:space:]]*$//')"

  # Validate: must match exactly YYYY-MM-DD (four digits - two digits - two digits)
  case "$date_part" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
      printf '%s' "$date_part"
      ;;
    *)
      # Any other format: treat as absent (no expiry, grandfather rule)
      printf ''
      ;;
  esac
}

# ---------------------------------------------------------------------------
# check_ref_allow_expiry  <file> <lineno> <reason> <expiry_date>
#
# Compares <expiry_date> (YYYY-MM-DD) to today's UTC calendar date.
# If the date has passed (today > expiry_date, lexicographic), emits:
#   [WARN] <file>:<lineno> ref-allow expired <expiry_date>: <reason>
# to stderr and returns 0.
#
# If <expiry_date> is empty (no-expiry / grandfather), returns 0 silently.
# If <expiry_date> is today or in the future, returns 0 silently.
#
# Exit code: always 0 (WARN-not-FAIL per AC-3 / ADR-022 §3).
# ---------------------------------------------------------------------------
check_ref_allow_expiry() {
  local file="$1"
  local lineno="$2"
  local reason="$3"
  local expiry_date="$4"

  # Empty expiry_date: no-expiry / grandfather form — silent pass
  [ -z "$expiry_date" ] && return 0

  # Compare lexicographically: YYYY-MM-DD is monotone under lexicographic order
  local today
  today="$(date -u +%Y-%m-%d)"

  # A date is expired when today is strictly greater than expiry_date.
  # In bash, [[ "a" > "b" ]] is true when "a" sorts after "b".
  if [[ "$today" > "$expiry_date" ]]; then
    printf '[WARN] %s:%s ref-allow expired %s: %s\n' \
      "$file" "$lineno" "$expiry_date" "$reason" >&2
  fi

  return 0
}

# ---------------------------------------------------------------------------
# parse_and_warn_ref_allow  <file> <lineno> <line>
#
# Convenience wrapper: parses the expiry date from <line> and calls
# check_ref_allow_expiry. The reason string is extracted from the ref-allow
# marker's reason clause (text between "ref-allow:" and " |" or "-->").
#
# Callers that already have the reason string separately should call
# parse_ref_allow_expiry + check_ref_allow_expiry directly.
#
# Exit code: always 0.
# ---------------------------------------------------------------------------
parse_and_warn_ref_allow() {
  local file="$1"
  local lineno="$2"
  local line="$3"

  local expiry_date
  expiry_date="$(parse_ref_allow_expiry "$line")"

  # Extract the reason string: text between "ref-allow:" and either " |" or "-->"
  local reason
  reason="$(printf '%s' "$line" \
    | sed -n 's/.*<!-- ref-allow:[[:space:]]*\([^|>-][^|]*\).*/\1/p' \
    | head -1 \
    | sed 's/[[:space:]]*|[[:space:]]*expires:.*$//' \
    | sed 's/[[:space:]]*-->.*$//' \
    | sed 's/[[:space:]]*$//')"

  check_ref_allow_expiry "$file" "$lineno" "$reason" "$expiry_date"
  return 0
}
