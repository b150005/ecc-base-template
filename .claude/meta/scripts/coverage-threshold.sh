#!/usr/bin/env bash
# coverage-threshold.sh
#
# Coverage-gate evaluator for milestone #12. The authoritative scope is
# specs/12-coverage-ci-gate.md; the structural keying/posture/single-source
# decisions are .claude/meta/adr/019-coverage-ci-gate.md (Decisions 1–5).
#
# ─────────────────────────────────────────────────────────────────────────
# WHAT THIS SCRIPT OWNS (and ONLY this), per ADR-019 Decision 5:
#
#   The question "Does the project's test coverage meet the canonical
#   minimum, enforced at CI time?" — a NEW MECE partition ADR-014 §(d)
#   does NOT pre-reserve. It is NOT a fourth detector: #04 owns reference
#   resolution, #05 owns Roadmap-index consistency, #06 owns EN↔JA parity,
#   #11 owns verification-domain opt-in guidance. None owns a
#   coverage-threshold enforcement contract. This script scans a wholly
#   different input — a runtime-supplied coverage percentage, not any
#   repository Markdown artifact — so the boundary is by input AND
#   contract (ADR-019 §5).
#
# ─────────────────────────────────────────────────────────────────────────
# SINGLE SOURCE OF TRUTH for the threshold (ADR-019 Decision 3; Spec
# R-02 / AC-2 / AC-8):
#
#   The canonical declaration is .claude/CLAUDE.md `## Testing
#   Requirements` — the literal line "- Minimum NN% test coverage". This
#   script DERIVES the integer from that line at CI runtime. It does NOT
#   carry an independent numeric literal that could drift. The activation
#   config (coverage-tracker.yml) carries the on/off switch ONLY and
#   deliberately does NOT carry the number — a number there would be the
#   exact second drifting declaration R-02 forbids. A future threshold
#   change (e.g. 80 → 85) is then a one-line edit to `## Testing
#   Requirements` and nothing else.
#
#   FAIL-CLOSED (ADR-019 Decision 3): if the canonical line cannot be
#   found (e.g. a fork deleted `## Testing Requirements`), this script
#   exits non-zero with an explicit message — it does NOT silently pass.
#   This is the same fail-closed direction the detector family takes.
#
# ─────────────────────────────────────────────────────────────────────────
# LANGUAGE-AGNOSTIC FORKABILITY (ADR-019 Decision 4; Spec R-04 / AC-3):
#
#   The caller (a derived repo) runs its own language-specific coverage
#   tool, computes a single project-level percentage by whatever means is
#   native to its toolchain, and passes that NUMBER in. This script
#   parses NO coverage report format. The threshold is NOT a caller
#   argument — it comes from the canonical source — so a caller cannot
#   weaken the gate by supplying a low threshold.
#
# ─────────────────────────────────────────────────────────────────────────
# Usage:
#   coverage-threshold.sh extract [CLAUDE_MD_PATH]
#       Print the canonical threshold integer to stdout. Exit 0 on
#       success; exit 1 (fail-closed) with a message on stderr if the
#       canonical line is absent. CLAUDE_MD_PATH defaults to the
#       repository's .claude/CLAUDE.md resolved from this script's
#       location.
#
#   coverage-threshold.sh gate MEASURED [CLAUDE_MD_PATH]
#       Compare the caller-supplied MEASURED coverage percentage against
#       the canonical threshold. Exit 0 if MEASURED >= threshold; exit 1
#       if below (a hard build-failing check, Spec AC-1) or if MEASURED
#       is not a valid number; exit 1 fail-closed if the canonical line
#       is absent. The human-readable message names BOTH the measured
#       coverage and the threshold (Spec AC-1).
#
# Exit 0 = pass; exit 1 = fail (below threshold, bad input, or
# fail-closed missing canonical line).

set -euo pipefail

# Resolve the default canonical CLAUDE.md from this script's location:
# .claude/meta/scripts/coverage-threshold.sh -> ../../CLAUDE.md
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_CLAUDE_MD="$(cd "$SCRIPT_DIR/../.." && pwd)/CLAUDE.md"

# extract_threshold CLAUDE_MD_PATH
#
# Reads the single canonical line "- Minimum NN% test coverage" under the
# `## Testing Requirements` heading and prints NN. Fails closed (exit 1,
# message on stderr) if the file or the canonical line is absent.
extract_threshold() {
  local claude_md="$1"

  if [ ! -f "$claude_md" ]; then
    echo "coverage-threshold: FAIL-CLOSED — canonical CLAUDE.md not found at '$claude_md'." >&2
    echo "coverage-threshold: the 80% rule lives in '## Testing Requirements'; without it the gate cannot resolve a threshold." >&2
    return 1
  fi

  # Scope the search to the `## Testing Requirements` section so a stray
  # "Minimum N% ..." elsewhere cannot be mistaken for the canonical line.
  # awk: enter the section on its heading, leave on the next `## ` heading,
  # and within the section capture the integer from the canonical bullet.
  local threshold
  threshold="$(awk '
    /^## Testing Requirements[[:space:]]*$/ { in_section = 1; next }
    in_section && /^## / { in_section = 0 }
    in_section && /^[[:space:]]*-[[:space:]]*Minimum[[:space:]]+[0-9]+%[[:space:]]+test coverage/ {
      match($0, /[0-9]+/)
      print substr($0, RSTART, RLENGTH)
      exit
    }
  ' "$claude_md")"

  if [ -z "$threshold" ]; then
    echo "coverage-threshold: FAIL-CLOSED — canonical '- Minimum NN% test coverage' line not found under '## Testing Requirements' in '$claude_md'." >&2
    echo "coverage-threshold: the threshold has a single source of truth (ADR-019 Decision 3); a removed canonical line is loud, not silent." >&2
    return 1
  fi

  printf '%s\n' "$threshold"
}

# is_number VALUE  -> 0 if VALUE is a non-negative integer or decimal
is_number() {
  case "$1" in
    '' | *[!0-9.]* ) return 1 ;;
    *.*.* ) return 1 ;;            # more than one dot
    . ) return 1 ;;               # lone dot
    * ) return 0 ;;
  esac
}

# numeric_lt A B  -> 0 (true) if A < B, supporting decimals via awk.
numeric_lt() {
  awk -v a="$1" -v b="$2" 'BEGIN { exit !(a + 0 < b + 0) }'
}

cmd_extract() {
  local claude_md="${1:-$DEFAULT_CLAUDE_MD}"
  extract_threshold "$claude_md"
}

cmd_gate() {
  local measured="${1:-}"
  local claude_md="${2:-$DEFAULT_CLAUDE_MD}"

  if [ -z "$measured" ]; then
    echo "coverage-threshold: FAIL — no measured coverage percentage supplied (Spec AC-3: caller supplies the measurement)." >&2
    return 1
  fi

  if ! is_number "$measured"; then
    echo "coverage-threshold: FAIL — measured coverage '$measured' is not a valid number." >&2
    return 1
  fi

  local threshold
  if ! threshold="$(extract_threshold "$claude_md")"; then
    return 1   # fail-closed message already emitted by extract_threshold
  fi

  if numeric_lt "$measured" "$threshold"; then
    echo "coverage-threshold: FAIL — measured coverage ${measured}% is below the required minimum of ${threshold}% (canonical source: '## Testing Requirements' in CLAUDE.md). This is a hard build-failing check (Spec AC-1)." >&2
    return 1
  fi

  echo "coverage-threshold: PASS — measured coverage ${measured}% meets the required minimum of ${threshold}% (canonical source: '## Testing Requirements' in CLAUDE.md)."
  return 0
}

main() {
  local subcommand="${1:-}"
  case "$subcommand" in
    extract)
      shift
      cmd_extract "$@"
      ;;
    gate)
      shift
      cmd_gate "$@"
      ;;
    *)
      echo "Usage: coverage-threshold.sh {extract [CLAUDE_MD] | gate MEASURED [CLAUDE_MD]}" >&2
      return 2
      ;;
  esac
}

main "$@"
