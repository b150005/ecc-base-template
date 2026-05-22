#!/usr/bin/env bash
# check-ref-allow-expiry.sh
#
# Roadmap #18 — ADR-022 (CI exemption allowlist expiry/review mechanism).
#
# AC-12 implementation choice: option (c) — a separate sixth detector
# script, not a per-detector amendment to the five existing ref-allow
# consumers. This shape was chosen over (a)/(b) because AC-7 hard-requires
# that "all existing tests pass without modification" and the existing
# scope-bleed guards (in test-check-ecc-delegation-consistency.sh,
# test-check-research-tier-auth.sh, test-coverage-threshold.sh) compare
# the 5 ref-allow-consuming detectors byte-for-byte against the design
# commit of each detector's owning milestone. A per-detector amendment
# would fail those guards. The Spec's MECE boundary (Non-goals exclude
# only skill-invariants/absence-of-claim/Reservation-rule/workaround-
# tracker) explicitly permits a sixth detector that covers the same
# scope as the five.
#
# Scope (matches the union of the 5 ref-allow consumers' scopes):
#   - .claude/CLAUDE.md
#   - specs/*.md (excluding *-progress.md, ADR-016)
#   - .claude/meta/adr/*.md
#   - .claude/agents/*.md
#
# Out-of-scope: .claude/meta/scripts/*.sh. ref-allow strings inside the
# detector and test scripts are LITERAL EXAMPLES of the syntax (used in
# docblocks, awk patterns, and test fixtures), not real suppressions.
# Scanning them would generate WARN noise on intentional past-date
# test fixtures (test-check-ref-allow-expiry.sh deliberately uses
# 2020-01-01 to validate AC-3 behaviour). The five existing detectors
# also do not validate ref-allow inside script source; this script
# follows the same boundary.
#
# Behaviour (AC-1 through AC-9):
#   AC-1: only strict ISO 8601 YYYY-MM-DD is honoured; any other format
#         in `expires:` is treated as absent (no expiry).
#   AC-2: parses the extended syntax  <!-- ref-allow: <reason> | expires: YYYY-MM-DD -->
#   AC-3: emits a [WARN] (not FAIL) for an expired marker; exit-code
#         stays 0 even when expired markers are found.
#   AC-4: today-or-future expiry: silent pass.
#   AC-5: no `expires:` clause: silent pass (permanent grandfather).
#   AC-6: applied identically across the union of the five detectors'
#         scopes (this script is the single source of truth for the
#         expiry contract; the five detectors continue to grep ref-allow
#         for in-scope suppression but never compare dates themselves).
#   AC-7: existing detectors and their test suites unchanged.
#   AC-8: existing no-expiry markers in the repo: all silent.
#   AC-9: WARN format:
#     [WARN] <path>:<lineno> ref-allow expired <expiry-date>: <reason>
#
# Exit code: always 0 (WARN-not-FAIL). A hard FAIL (non-zero) is reserved
# for unrecoverable script-level errors (missing library, IO failure).

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../../.." && pwd)"

# Load the shared parsing/comparison library.
LIB="${SCRIPT_DIR}/lib/ref-allow-expiry.sh"
if [[ ! -f "${LIB}" ]]; then
  echo "[FATAL] shared library missing: ${LIB}" >&2
  exit 2
fi
# shellcheck disable=SC1090
source "${LIB}"

# ---------------------------------------------------------------------------
# scan_file <path>
#
# Scans <path> line by line for ref-allow markers, parses any expires:
# clause, and emits a WARN if expired. All output to stderr via the
# library. Exit code from this function is always 0.
# ---------------------------------------------------------------------------
scan_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0

  local lineno=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    lineno=$((lineno + 1))
    case "$line" in
      *"<!-- ref-allow:"*)
        parse_and_warn_ref_allow "$file" "$lineno" "$line"
        ;;
    esac
  done < "$file"
  return 0
}

# ---------------------------------------------------------------------------
# Main scan: union of the five ref-allow consumers' scopes.
# ---------------------------------------------------------------------------
echo "check-ref-allow-expiry.sh — Roadmap #18 / ADR-022"
echo "  Scope: CLAUDE.md, specs/, .claude/meta/adr/, .claude/agents/"
echo "  Behaviour: WARN-not-FAIL on expired ref-allow markers (AC-3, ADR-022 §3)"
echo "  Grandfather: no-expiry form is permanent, never WARNs (AC-5/AC-8)"
echo ""

warn_count_before="$(mktemp)"
exec 4>&2  # stash stderr so we can count warns via tee
trap 'rm -f "${warn_count_before}"' EXIT

# CLAUDE.md
if [[ -f "${REPO_ROOT}/.claude/CLAUDE.md" ]]; then
  scan_file "${REPO_ROOT}/.claude/CLAUDE.md"
fi

# specs/*.md  (exclude *-progress.md per ADR-016)
if [[ -d "${REPO_ROOT}/specs" ]]; then
  while IFS= read -r -d '' f; do
    case "$(basename "$f")" in
      *-progress.md) continue ;;
    esac
    scan_file "$f"
  done < <(find "${REPO_ROOT}/specs" -type f -name '*.md' -print0)
fi

# .claude/meta/adr/*.md
if [[ -d "${REPO_ROOT}/.claude/meta/adr" ]]; then
  while IFS= read -r -d '' f; do
    scan_file "$f"
  done < <(find "${REPO_ROOT}/.claude/meta/adr" -type f -name '*.md' -print0)
fi

# .claude/agents/*.md
if [[ -d "${REPO_ROOT}/.claude/agents" ]]; then
  while IFS= read -r -d '' f; do
    scan_file "$f"
  done < <(find "${REPO_ROOT}/.claude/agents" -type f -name '*.md' -print0)
fi

echo "ref-allow expiry scan complete: WARN-not-FAIL semantic, exit 0 always"
exit 0
