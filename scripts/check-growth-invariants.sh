#!/usr/bin/env bash
# check-growth-invariants.sh
#
# Enforces the three deterministic preconditions that guard the Developer
# Growth Mode default-off invariant. Runs in CI on every PR.
#
# Why this script and not golden-file regression against agent output:
# LLM output is non-deterministic across runs, model versions, and prompt
# compaction. Hashing agent responses against committed goldens produces
# flaky tests that get disabled. See docs/en/adr/001-developer-growth-mode.md
# ("Enforcement: default-off invariant") and docs/en/prd/developer-growth-mode.md
# (§8) for the full rationale.
#
# Checks:
#   1. `disable-model-invocation: true` is present in .claude/skills/growth/SKILL.md
#   2. Every .claude/agents/*.md file that declares a `## Growth Domains` section
#      also contains the guard-branch marker referencing .claude/growth/config.json
#   3. .gitignore ignores .claude/growth/notes/ and .claude/growth/config.json,
#      and .gitignore.example contains the opt-in inversion block
#
# Note: Check 2 re-anchored in ADR-002 (2026-04-23). Previously grepped for
# `growth_domains:` in frontmatter; now grepped for `## Growth Domains` in body.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

fail=0
pass() { printf "  [PASS] %s\n" "$1"; }
fail_check() { printf "  [FAIL] %s\n" "$1" >&2; fail=1; }

printf "Growth Mode invariant checks\n"
printf "============================\n\n"

# ---------------------------------------------------------------------------
# Check 1: Skill disables model invocation
# ---------------------------------------------------------------------------
printf "Check 1: Skill invocation boundary\n"
skill_file=".claude/skills/growth/SKILL.md"
if [[ ! -f "$skill_file" ]]; then
  fail_check "$skill_file not found"
elif grep -Fq "disable-model-invocation: true" "$skill_file"; then
  pass "$skill_file declares disable-model-invocation: true"
else
  fail_check "$skill_file missing 'disable-model-invocation: true'"
fi
printf "\n"

# ---------------------------------------------------------------------------
# Check 2: Every growth-aware agent has the guard branch
# ---------------------------------------------------------------------------
printf "Check 2: Agent guard branch\n"
guard_marker=".claude/growth/config.json"
agents_without_guard=()

while IFS= read -r -d '' agent_file; do
  if grep -Eq '^## Growth Domains$' "$agent_file"; then
    if ! grep -Fq "$guard_marker" "$agent_file"; then
      agents_without_guard+=("$agent_file")
    fi
  fi
done < <(find .claude/agents -maxdepth 1 -name '*.md' -print0 2>/dev/null)

if [[ ${#agents_without_guard[@]} -eq 0 ]]; then
  pass "every agent with ## Growth Domains section references $guard_marker"
else
  for a in "${agents_without_guard[@]}"; do
    fail_check "$a has ## Growth Domains section but lacks guard-branch reference to $guard_marker"
  done
fi
printf "\n"

# ---------------------------------------------------------------------------
# Check 3: Gitignore posture
# ---------------------------------------------------------------------------
printf "Check 3: Gitignore posture\n"
gitignore=".gitignore"
example=".gitignore.example"

check_ignore_line() {
  local pattern="$1"
  if grep -Fq "$pattern" "$gitignore"; then
    pass "$gitignore ignores $pattern"
  else
    fail_check "$gitignore missing entry: $pattern"
  fi
}

if [[ ! -f "$gitignore" ]]; then
  fail_check "$gitignore not found"
else
  check_ignore_line ".claude/growth/notes/"
  check_ignore_line ".claude/growth/config.json"
fi

if [[ ! -f "$example" ]]; then
  fail_check "$example not found"
elif grep -Fq "!.claude/growth/notes/" "$example"; then
  pass "$example documents the opt-in inversion"
else
  fail_check "$example missing opt-in inversion pattern"
fi
printf "\n"

# ---------------------------------------------------------------------------
# Result
# ---------------------------------------------------------------------------
if [[ $fail -eq 0 ]]; then
  printf "All Growth Mode invariant checks passed.\n"
  exit 0
else
  printf "One or more Growth Mode invariant checks failed.\n" >&2
  exit 1
fi
