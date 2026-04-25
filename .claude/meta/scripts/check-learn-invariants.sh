#!/usr/bin/env bash
# check-learn-invariants.sh
#
# Enforces the deterministic preconditions that guard the Developer Learning Mode
# default-off invariant. Runs in CI on every PR.
#
# Why this script and not golden-file regression against agent output:
# LLM output is non-deterministic across runs, model versions, and prompt
# compaction. Hashing agent responses against committed goldens produces flaky
# tests that get disabled. See .claude/meta/adr/001-developer-growth-mode.md
# ("Enforcement: default-off invariant") and
# .claude/meta/adr/003-learning-mode-relocate-and-rename.md for the rename and
# relocation rationale. ADR-005 records the v3 restructure that relocated all
# template-internal artifacts under .claude/meta/.
#
# Checks:
#   1. `disable-model-invocation: true` is present in .claude/skills/learn/SKILL.md
#   2. Every .claude/agents/*.md file that declares a `## Learning Domains` section
#      also contains the guard-branch marker referencing .claude/learn/config.json
#   3. .gitignore ignores .claude/learn/knowledge/ and .claude/learn/config.json,
#      and .gitignore.example contains the opt-in inversion block
#   4. Every learning-aware agent also references coach.style (coach guard branch)
#   5. Coach styles directory exists with all 6 canonical files, each containing
#      a behavior-rule: frontmatter key

set -euo pipefail

# Resolve repo root robustly: prefer git (handles symlinks and unusual cwd),
# fall back to a relative walk from this script's location.
if repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  :
else
  repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
fi
cd "$repo_root"

fail=0
pass() { printf "  [PASS] %s\n" "$1"; }
fail_check() { printf "  [FAIL] %s\n" "$1" >&2; fail=1; }

printf "Learning Mode invariant checks\n"
printf "==============================\n\n"

# ---------------------------------------------------------------------------
# Check 1: Skill disables model invocation
# ---------------------------------------------------------------------------
printf "Check 1: Skill invocation boundary\n"
skill_file=".claude/skills/learn/SKILL.md"
if [[ ! -f "$skill_file" ]]; then
  fail_check "$skill_file not found"
elif grep -Fq "disable-model-invocation: true" "$skill_file"; then
  pass "$skill_file declares disable-model-invocation: true"
else
  fail_check "$skill_file missing 'disable-model-invocation: true'"
fi
printf "\n"

# ---------------------------------------------------------------------------
# Check 2: Every learning-aware agent has the guard branch
# ---------------------------------------------------------------------------
printf "Check 2: Agent guard branch\n"
guard_marker=".claude/learn/config.json"
agents_without_guard=()

while IFS= read -r -d '' agent_file; do
  if grep -Eq '^## Learning Domains$' "$agent_file"; then
    if ! grep -Fq "$guard_marker" "$agent_file"; then
      agents_without_guard+=("$agent_file")
    fi
  fi
done < <(find .claude/agents -maxdepth 1 -name '*.md' -print0 2>/dev/null)

if [[ ${#agents_without_guard[@]} -eq 0 ]]; then
  pass "every agent with ## Learning Domains section references $guard_marker"
else
  for a in "${agents_without_guard[@]}"; do
    fail_check "$a has ## Learning Domains section but lacks guard-branch reference to $guard_marker"
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
  check_ignore_line ".claude/learn/knowledge/"
  check_ignore_line ".claude/learn/config.json"
fi

if [[ ! -f "$example" ]]; then
  fail_check "$example not found"
elif grep -Fq "!.claude/learn/knowledge/" "$example"; then
  pass "$example documents the opt-in inversion"
else
  fail_check "$example missing opt-in inversion pattern"
fi
printf "\n"

# ---------------------------------------------------------------------------
# Check 4: Every learning-aware agent has the coach guard marker
# ---------------------------------------------------------------------------
printf "Check 4: Agent coach guard branch\n"
coach_marker="coach.style"
agents_without_coach_guard=()

while IFS= read -r -d '' agent_file; do
  if grep -Eq '^## Learning Domains$' "$agent_file"; then
    if ! grep -Fq "$coach_marker" "$agent_file"; then
      agents_without_coach_guard+=("$agent_file")
    fi
  fi
done < <(find .claude/agents -maxdepth 1 -name '*.md' -print0 2>/dev/null)

if [[ ${#agents_without_coach_guard[@]} -eq 0 ]]; then
  pass "every agent with ## Learning Domains section references $coach_marker (coach guard)"
else
  for a in "${agents_without_coach_guard[@]}"; do
    fail_check "$a has ## Learning Domains section but lacks coach guard marker '$coach_marker'"
  done
fi
printf "\n"

# ---------------------------------------------------------------------------
# Check 5: Coach styles directory exists with all 6 canonical files, each
#           containing a behavior-rule: frontmatter key
# ---------------------------------------------------------------------------
printf "Check 5: Coach styles directory and canonical style files\n"
coach_styles_dir=".claude/skills/learn/coach-styles"
canonical_styles=("default" "hints" "socratic" "pair" "review-only" "silent")

if [[ ! -d "$coach_styles_dir" ]]; then
  fail_check "$coach_styles_dir directory not found"
else
  pass "$coach_styles_dir directory exists"
  for style in "${canonical_styles[@]}"; do
    style_file="$coach_styles_dir/${style}.md"
    if [[ ! -f "$style_file" ]]; then
      fail_check "missing canonical style file: $style_file"
    elif ! grep -Fq "behavior-rule:" "$style_file"; then
      fail_check "$style_file exists but is missing 'behavior-rule:' frontmatter key"
    else
      pass "$style_file present with behavior-rule:"
    fi
  done
fi
printf "\n"

# ---------------------------------------------------------------------------
# Result
# ---------------------------------------------------------------------------
if [[ $fail -eq 0 ]]; then
  printf "All Learning Mode invariant checks passed.\n"
  exit 0
else
  printf "One or more Learning Mode invariant checks failed.\n" >&2
  exit 1
fi
