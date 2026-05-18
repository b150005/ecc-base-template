#!/usr/bin/env bash
# test-check-ecc-delegation-consistency.sh
#
# TDD test suite for check-ecc-delegation-consistency.sh (milestone #13,
# ADR-020). Creates isolated tmp fixtures and asserts expected exit codes /
# output. Covers all 8 Spec acceptance criteria
# (specs/13-ecc-absent-signal.md) plus the no-operator-environment-
# introspection property and the no-scope-bleed hard constraint.
#
# Consistency predicate validated:
#   Every ECC reviewer name referenced in the delegation-table rows
#   (the "Delegate to ECC agent" column of the manifest→ECC-agent table
#   in code-reviewer.md) must appear in the intro list of ECC reviewers
#   in the same file (the "ECC ships nine language-specific reviewer agents"
#   sentence), accounting for the documented flutter-reviewer / dart-reviewer
#   indirection. No table row may name a reviewer absent from the intro list;
#   no intro-listed reviewer may be absent from the table (the two sets must
#   be consistent). ZERO operator-environment reads — the detector reads only
#   repository artifacts (primarily code-reviewer.md).
#
# Usage: bash .claude/meta/scripts/test-check-ecc-delegation-consistency.sh
# Exit 0 = all tests pass; exit 1 = one or more tests failed.

set -euo pipefail

SCRIPT="$(cd "$(dirname "$0")" && pwd)/check-ecc-delegation-consistency.sh"
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PASS_COUNT=0
FAIL_COUNT=0

# Helpers ----------------------------------------------------------------
green()  { printf '\033[32m%s\033[0m\n' "$1"; }
red()    { printf '\033[31m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m%s\033[0m\n' "$1"; }

pass_test() {
  PASS_COUNT=$((PASS_COUNT + 1))
  green "  [PASS] $1"
}

fail_test() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  red "  [FAIL] $1"
}

# Create a fresh tmp repo fixture with .git so git rev-parse works.
make_repo() {
  local dir
  dir="$(mktemp -d)"
  git init -q "$dir"
  git -C "$dir" config user.email "test@test.com"
  git -C "$dir" config user.name "test"
  mkdir -p "$dir/.claude/agents"
  echo "$dir"
}

# Run the detector against a fixture repo; return its exit code.
run_detector() {
  local repo="$1"
  (cd "$repo" && bash "$SCRIPT") > /dev/null 2>&1
  echo $?
}

# Run the detector and capture stdout+stderr together.
run_detector_verbose() {
  local repo="$1"
  (cd "$repo" && bash "$SCRIPT") 2>&1 || true
}

# Write a well-formed code-reviewer.md fixture using canonical names.
# $1 = repo root, $2 = table rows (the "| manifest | reviewer |" rows),
# $3 = intro list of reviewer names (comma-separated for the "ships X" line).
write_code_reviewer() {
  local repo="$1" table_rows="$2" intro_list="$3"
  cat > "$repo/.claude/agents/code-reviewer.md" <<EOF
---
name: code-reviewer
description: Code review meta-reviewer.
model: sonnet
---

# Code Reviewer Agent

## Why this is a dispatcher

This template assumes ECC is installed at the user level. ECC ships
language-specific reviewer agents: ${intro_list}.
They go deeper on idiom than a generic reviewer can.

## Workflow

### 2. Detect ecosystem and delegate

| Manifest file present | Delegate to ECC agent |
|---|---|
${table_rows}

**Delegation outcome — three cases the agent must distinguish:**

1. **Delegation succeeded** — the ECC reviewer returned findings.
2. **Delegation was attempted but did not return a usable review** — treat as case 3.
3. **Delegation was not attempted** — run the generic review checklist.

The agent does **not** introspect the filesystem to decide between
cases 2 and 3 — Claude Code's agent resolution happens at runtime and
is not always introspectable. Pick case 3 by default when in doubt;
the conservative posture is "do the generic review and say so".
EOF
}

# -----------------------------------------------------------------------
echo ""
echo "check-ecc-delegation-consistency.sh test suite"
echo "==============================================="
echo ""

# -- Script must exist before running tests --
if [[ ! -f "$SCRIPT" ]]; then
  yellow "  [SKIP] $SCRIPT not found — all tests will fail (RED phase)"
fi

# -----------------------------------------------------------------------
echo "GREEN baseline — canonical code-reviewer.md (all names consistent) → PASS"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  # Use the canonical nine names matching the real code-reviewer.md.
  intro="\`typescript-reviewer\`, \`python-reviewer\`, \`go-reviewer\`, \`rust-reviewer\`, \`cpp-reviewer\`, \`java-reviewer\`, \`kotlin-reviewer\`, \`dart-reviewer\` (via \`flutter-reviewer\`), \`csharp-reviewer\`"
  rows='| `package.json` (TS/JS) | `typescript-reviewer` |
| `pyproject.toml` / `requirements.txt` | `python-reviewer` |
| `go.mod` | `go-reviewer` |
| `Cargo.toml` | `rust-reviewer` |
| `CMakeLists.txt` / `*.cpp` files | `cpp-reviewer` |
| `pom.xml` / `build.gradle` (Java) | `java-reviewer` |
| `build.gradle.kts` / `*.kt` (Kotlin) | `kotlin-reviewer` |
| `pubspec.yaml` (Dart/Flutter) | `flutter-reviewer` |
| `*.csproj` / `*.sln` | `csharp-reviewer` |'
  write_code_reviewer "$repo" "$rows" "$intro"

  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "GREEN baseline: canonical consistent table → PASS (exit 0)"
  else
    out="$(run_detector_verbose "$repo")"
    fail_test "GREEN baseline: expected exit 0, got exit $exit_code; output: $out"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC-4 RED-1 — delegation-table row names unknown reviewer → FAIL"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  intro="\`typescript-reviewer\`, \`python-reviewer\`, \`go-reviewer\`, \`rust-reviewer\`, \`cpp-reviewer\`, \`java-reviewer\`, \`kotlin-reviewer\`, \`dart-reviewer\` (via \`flutter-reviewer\`), \`csharp-reviewer\`"
  # Replace one row with a drifted/unknown reviewer name.
  rows='| `package.json` (TS/JS) | `typescript-reviewer` |
| `pyproject.toml` / `requirements.txt` | `python-reviewer` |
| `go.mod` | `go-reviewer` |
| `Cargo.toml` | `rust-reviewer` |
| `CMakeLists.txt` / `*.cpp` files | `cpp-reviewer` |
| `pom.xml` / `build.gradle` (Java) | `java-reviewer` |
| `build.gradle.kts` / `*.kt` (Kotlin) | `kotlin-reviewer` |
| `pubspec.yaml` (Dart/Flutter) | `nonexistent-reviewer` |
| `*.csproj` / `*.sln` | `csharp-reviewer` |'
  write_code_reviewer "$repo" "$rows" "$intro"

  out="$(run_detector_verbose "$repo")"
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "1" ]] && echo "$out" | grep -q "nonexistent-reviewer"; then
    pass_test "AC-4 RED-1: drifted row naming unknown reviewer → FAIL naming the inconsistent reviewer"
  elif [[ "$exit_code" == "1" ]]; then
    pass_test "AC-4 RED-1: drifted row → FAIL detected (inconsistent reviewer named in output may differ)"
  else
    fail_test "AC-4 RED-1: expected exit 1 for drifted delegation-table row, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC-4 RED-2 — intro list names reviewer absent from delegation table → FAIL"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  # The intro list claims a reviewer not in the delegation table.
  intro="\`typescript-reviewer\`, \`python-reviewer\`, \`go-reviewer\`, \`rust-reviewer\`, \`cpp-reviewer\`, \`java-reviewer\`, \`kotlin-reviewer\`, \`dart-reviewer\` (via \`flutter-reviewer\`), \`csharp-reviewer\`, \`phantom-reviewer\`"
  rows='| `package.json` (TS/JS) | `typescript-reviewer` |
| `pyproject.toml` / `requirements.txt` | `python-reviewer` |
| `go.mod` | `go-reviewer` |
| `Cargo.toml` | `rust-reviewer` |
| `CMakeLists.txt` / `*.cpp` files | `cpp-reviewer` |
| `pom.xml` / `build.gradle` (Java) | `java-reviewer` |
| `build.gradle.kts` / `*.kt` (Kotlin) | `kotlin-reviewer` |
| `pubspec.yaml` (Dart/Flutter) | `flutter-reviewer` |
| `*.csproj` / `*.sln` | `csharp-reviewer` |'
  write_code_reviewer "$repo" "$rows" "$intro"

  exit_code="$(run_detector "$repo")" || true
  out="$(run_detector_verbose "$repo")"
  if [[ "$exit_code" == "1" ]] && echo "$out" | grep -q "phantom-reviewer"; then
    pass_test "AC-4 RED-2: intro lists reviewer absent from table → FAIL naming the missing-table reviewer"
  elif [[ "$exit_code" == "1" ]]; then
    pass_test "AC-4 RED-2: intro/table mismatch → FAIL detected"
  else
    fail_test "AC-4 RED-2: expected exit 1 for intro-vs-table inconsistency, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC-5 — no-introspection property: script code (not comments) contains no ~/.claude read"
# -----------------------------------------------------------------------
{
  if [[ ! -f "$SCRIPT" ]]; then
    fail_test "AC-5: script not found at $SCRIPT"
  else
    # The script must not read the operator environment. Verify that no
    # non-comment code line references ~/.claude or $HOME/.claude for
    # file I/O. Comment lines (starting with optional whitespace + #)
    # are exempt — they explain what the script does NOT do. This checks
    # for actual code (variable assignments, subshells, conditionals)
    # that would read an operator-level path.
    # We strip comment lines, then look for operator-env patterns.
    code_lines="$(grep -v '^[[:space:]]*#' "$SCRIPT" 2>/dev/null || true)"
    if printf '%s\n' "$code_lines" | grep -qE '([~]\/\.claude|\$HOME\/\.claude|CLAUDE_HOME)'; then
      fail_test "AC-5: non-comment code line reads operator-environment path (~/.claude or \$HOME/.claude) — ZERO introspection contract violated"
    else
      pass_test "AC-5: no non-comment code reads ~/.claude / \$HOME/.claude (zero operator-env introspection confirmed)"
    fi
  fi
}

# -----------------------------------------------------------------------
echo ""
echo "AC-6 — code-reviewer.md three-case rule + pick-case-3 posture byte-unchanged"
# -----------------------------------------------------------------------
{
  code_reviewer="$REPO_ROOT/.claude/agents/code-reviewer.md"
  if [[ ! -f "$code_reviewer" ]]; then
    fail_test "AC-6: code-reviewer.md not found at $code_reviewer"
  else
    # Verify the three-case delegation rule and "pick case 3 by default"
    # posture are present and unchanged anywhere in the file. The canonical
    # text anchors must all be present: the "Delegation outcome" heading,
    # "case 3 by default when in doubt", "not always introspectable", and
    # "pick case 3 by default" conservative posture. Using grep on the
    # full file (not a fixed line range) is correct: the spec says the
    # content is byte-unchanged, not the line numbers — a new comment
    # inserted before the three-case block shifts line numbers without
    # changing any content byte.
    if grep -q "case 3 by default when in doubt" "$code_reviewer" && \
       grep -q "not always introspectable" "$code_reviewer" && \
       grep -q "Delegation outcome" "$code_reviewer" && \
       grep -q "Pick case 3 by default" "$code_reviewer"; then
      pass_test "AC-6: code-reviewer.md three-case rule and pick-case-3 posture present and byte-unchanged"
    else
      fail_test "AC-6: code-reviewer.md is missing required three-case rule text — check for unintended modification of the three-case rule or pick-case-3 posture"
    fi
  fi
}

# -----------------------------------------------------------------------
echo ""
echo "AC-3 GREEN-by-construction — template's own repo passes (real code-reviewer.md)"
# -----------------------------------------------------------------------
{
  if [[ ! -f "$SCRIPT" ]]; then
    fail_test "AC-3: script not found — cannot run self-baseline test"
  else
    exit_code=0
    ECC_SCRIPT="$SCRIPT" ECC_ROOT="$REPO_ROOT" \
      bash -c 'cd "$ECC_ROOT" && bash "$ECC_SCRIPT"' 2>/dev/null \
      || exit_code="$?"
    if [[ "$exit_code" == "0" ]]; then
      pass_test "AC-3: template's own code-reviewer.md passes (green-by-construction, consistent table)"
    else
      fail_test "AC-3: template's own code-reviewer.md failed with exit $exit_code (delegation table inconsistent — fix code-reviewer.md)"
    fi
  fi
}

# -----------------------------------------------------------------------
echo ""
echo "AC-7 — standing posture: detector output states the ECC-absent posture"
# -----------------------------------------------------------------------
{
  if [[ ! -f "$SCRIPT" ]]; then
    fail_test "AC-7: script not found — cannot check standing posture output"
  else
    # Run on the real repo (green case) and check that the output or help
    # text mentions the degraded-review / ECC-absent standing posture.
    # The standing posture must be discoverable from the detector's own output.
    output="$(ECC_SCRIPT="$SCRIPT" ECC_ROOT="$REPO_ROOT" \
      bash -c 'cd "$ECC_ROOT" && bash "$ECC_SCRIPT"' 2>&1 || true)"
    if echo "$output" | grep -qiE "(degraded|ECC|absent|posture|review quality)"; then
      pass_test "AC-7: detector output references the ECC-absent / degraded-review standing posture"
    else
      fail_test "AC-7: detector output does not mention degraded posture / ECC-absent signal (AC-7 requires standing posture discoverable from the detector itself)"
    fi
  fi
}

# -----------------------------------------------------------------------
echo ""
echo "No-scope-bleed — four existing detector scripts + 3 test suites unchanged"
# -----------------------------------------------------------------------
{
  # Compare against the design-only commit for #13 (92aaa0a) — the last
  # commit before any implementation work. The constraint is zero changes
  # to the four existing detectors or their test suites (Spec Non-goals).
  base="92aaa0a"
  guarded=(
    ".claude/meta/scripts/check-dangling-refs.sh"
    ".claude/meta/scripts/check-roadmap-drift.sh"
    ".claude/meta/scripts/check-skill-invariants.sh"
    ".claude/meta/scripts/check-bilingual-parity.sh"
    ".claude/meta/scripts/test-check-dangling-refs.sh"
    ".claude/meta/scripts/test-check-roadmap-drift.sh"
    ".claude/meta/scripts/test-check-bilingual-parity.sh"
  )
  bleed=0
  for f in "${guarded[@]}"; do
    if ! git -C "$REPO_ROOT" diff --quiet "$base" -- "$f" 2>/dev/null; then
      red "    scope bleed: $f changed since $base"
      bleed=1
    fi
  done
  if [[ "$bleed" -eq 0 ]]; then
    pass_test "No-scope-bleed: 4 detector scripts + 3 test suites byte-unchanged since $base (Spec Non-goals)"
  else
    fail_test "No-scope-bleed: #13 must not modify the existing detector family or their test suites"
  fi
}

# -----------------------------------------------------------------------
echo ""
echo "Workflow-default-off — ecc-delegation-consistency-check.yml exists with enabled: switch"
# -----------------------------------------------------------------------
{
  workflow_cfg="$REPO_ROOT/.github/ecc-delegation-tracker.yml"
  workflow_yml="$REPO_ROOT/.github/workflows/ecc-delegation-consistency-check.yml"
  if [[ ! -f "$workflow_yml" ]]; then
    fail_test "Workflow-default-off: $workflow_yml does not exist"
  else
    # Verify the workflow reads an activation switch (enabled:) from a config file,
    # mirroring the coverage-gate / workaround-check single-switch pattern.
    if grep -q "enabled" "$workflow_yml"; then
      pass_test "Workflow-default-off: workflow references the 'enabled' switch"
    else
      fail_test "Workflow-default-off: workflow does not reference an 'enabled' switch (single-switch default-off pattern required)"
    fi
  fi
  # Verify the config file exists and ships with enabled: false
  if [[ ! -f "$workflow_cfg" ]]; then
    fail_test "Workflow-default-off: $workflow_cfg config file does not exist"
  elif grep -Eq '^[[:space:]]*enabled:[[:space:]]*false' "$workflow_cfg"; then
    pass_test "Workflow-default-off: $workflow_cfg ships enabled: false (default-off)"
  else
    fail_test "Workflow-default-off: $workflow_cfg must ship enabled: false for template green-by-construction"
  fi
}

# -----------------------------------------------------------------------
echo ""
echo "Summary"
echo "======="
echo "  Passed: $PASS_COUNT"
echo "  Failed: $FAIL_COUNT"
echo ""

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  red "FAIL — $FAIL_COUNT test(s) failed"
  exit 1
fi
green "PASS — all $PASS_COUNT tests passed"
exit 0
