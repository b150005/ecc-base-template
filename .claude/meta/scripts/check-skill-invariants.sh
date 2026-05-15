#!/usr/bin/env bash
# check-skill-invariants.sh
#
# Enforces structural invariants for the claude-md-authoring Skill (ADR-007)
# and any future Skill ecc-base-template ships. This is independent of
# check-learn-invariants.sh: failures here are about Skill authoring, not
# Learning Mode state.
#
# Checks:
#   1. SKILL.md exists for every directory under .claude/skills/
#   2. SKILL.md has YAML frontmatter with required fields
#      (name, description, disable-model-invocation)
#   3. SKILL.md is at most 500 lines (Anthropic recommendation, verified
#      2026-05-06 against code.claude.com/docs/en/skills). 450 lines is
#      a soft warn threshold.
#   4. Every relative-path link in SKILL.md (./foo.md, ../foo.md) resolves
#      to a real file. ADR-NNN references are not validated by this script
#      (they are checked by reviewers).
#
# This script is intentionally permissive: it warns on the soft threshold
# but only fails on the 500-line cap and structural problems (missing
# SKILL.md, missing required frontmatter field, broken local link).
#
# Grandfathering: the `learn` Skill predates this contract (ADR-001/003/004
# created it before ADR-007 introduced the 500-line cap). It is exempt
# from the line-cap check via SKILL_LINE_CAP_EXEMPT below. New skills
# are not exempt — adopters that ship a new skill must keep it under 500
# lines or move detail to sibling files.

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
fail_check() { printf "  [FAIL] %s\n" "$1" >&2; fail=1; }

SKILL_LINE_HARD_CAP=500
SKILL_LINE_SOFT_WARN=450

# Skills that predate ADR-007's line cap. New skills must not be added here;
# they are expected to use Progressive Disclosure to stay under 500 lines.
SKILL_LINE_CAP_EXEMPT=(
  ".claude/skills/learn/SKILL.md"
)

is_exempt() {
  local target="$1" e
  for e in "${SKILL_LINE_CAP_EXEMPT[@]}"; do
    [[ "$e" == "$target" ]] && return 0
  done
  return 1
}

echo "Skill invariant checks"
echo "======================"

if [[ ! -d .claude/skills ]]; then
  echo "  No .claude/skills directory; nothing to check."
  exit 0
fi

# Iterate over every immediate subdirectory of .claude/skills/
# Each subdirectory is expected to be a Skill.
shopt -s nullglob
skill_dirs=(.claude/skills/*/)
shopt -u nullglob

if [[ ${#skill_dirs[@]} -eq 0 ]]; then
  echo "  .claude/skills exists but is empty; nothing to check."
  exit 0
fi

echo ""
echo "Check 1: SKILL.md presence"
for d in "${skill_dirs[@]}"; do
  d="${d%/}"
  if [[ -f "$d/SKILL.md" ]]; then
    pass "$d/SKILL.md exists"
  else
    fail_check "$d is missing SKILL.md"
  fi
done

echo ""
echo "Check 2: required frontmatter fields"
for d in "${skill_dirs[@]}"; do
  d="${d%/}"
  f="$d/SKILL.md"
  [[ -f "$f" ]] || continue

  # Frontmatter is the first --- ... --- block at the top of the file.
  # Extract it once with awk and check required keys. Tolerate leading
  # blank lines by not pinning to NR==1. (BOM-prefixed files are not
  # supported — strip the BOM in the source file if you hit this.)
  fm="$(awk '/^---$/{if(!infm){infm=1; next} else {exit}} infm' "$f")"

  if [[ -z "$fm" ]]; then
    fail_check "$f has no YAML frontmatter"
    continue
  fi

  for key in name description; do
    if ! grep -qE "^${key}:" <<<"$fm"; then
      fail_check "$f frontmatter is missing '${key}:'"
    fi
  done

  # disable-model-invocation must be present (true or false). The Skill
  # author must make a deliberate choice; an absent field is a defect.
  if ! grep -qE "^disable-model-invocation:" <<<"$fm"; then
    fail_check "$f frontmatter is missing 'disable-model-invocation:' (must be true or false)"
  fi

  # If all three fields are present, count it as pass for this file.
  if grep -qE "^name:" <<<"$fm" \
     && grep -qE "^description:" <<<"$fm" \
     && grep -qE "^disable-model-invocation:" <<<"$fm"; then
    pass "$f frontmatter has name, description, disable-model-invocation"
  fi
done

echo ""
echo "Check 3: SKILL.md line cap (hard ${SKILL_LINE_HARD_CAP}, soft ${SKILL_LINE_SOFT_WARN})"
for d in "${skill_dirs[@]}"; do
  d="${d%/}"
  f="$d/SKILL.md"
  [[ -f "$f" ]] || continue

  lines=$(wc -l < "$f" | tr -d ' ')
  if is_exempt "$f"; then
    pass "$f is ${lines} lines (grandfathered exempt from the ${SKILL_LINE_HARD_CAP} cap)"
  elif (( lines > SKILL_LINE_HARD_CAP )); then
    fail_check "$f is ${lines} lines (exceeds Anthropic-recommended cap of ${SKILL_LINE_HARD_CAP}; move detail to sibling .md files)"
  elif (( lines > SKILL_LINE_SOFT_WARN )); then
    warn "$f is ${lines} lines (approaching the ${SKILL_LINE_HARD_CAP} cap; consider moving detail)"
  else
    pass "$f is ${lines} lines"
  fi
done

echo ""
echo "Check 4: local relative-path links resolve"
# Match markdown links whose target begins with ./ or ../ (any number of
# parent traversals). Absolute project paths (e.g. .claude/...) are not
# checked here because they may be resolved relative to the repo root and
# would require richer parsing. Reviewers cover those.
# NOTE: ADR-NNN references and .claude/-rooted path mentions in CLAUDE.md,
# ADR files, Spec files, and agent files are owned by check-dangling-refs.sh
# (per ADR-015). This check 4 owns relative-path links in SKILL.md only.
for d in "${skill_dirs[@]}"; do
  d="${d%/}"
  f="$d/SKILL.md"
  [[ -f "$f" ]] || continue

  # Extract link targets matching the pattern.
  # Pattern: `](./foo)`, `](../foo)`, `](../../foo)` etc.
  while IFS= read -r target; do
    # Strip optional anchor and query.
    clean="${target%%#*}"
    clean="${clean%%\?*}"
    [[ -z "$clean" ]] && continue

    # Resolve relative to the SKILL.md file's directory.
    abs_target="$d/$clean"
    if [[ -f "$abs_target" ]]; then
      pass "$f → $clean (exists)"
    else
      fail_check "$f references missing file: $clean (resolved as $abs_target)"
    fi
  done < <(grep -oE '\]\((\.\./)*\.\.?/[^)]+\)' "$f" | sed -E 's/^\]\(//; s/\)$//')
done

echo ""
if (( fail > 0 )); then
  echo "Skill invariant checks: FAIL"
  exit 1
fi
echo "Skill invariant checks: PASS"
