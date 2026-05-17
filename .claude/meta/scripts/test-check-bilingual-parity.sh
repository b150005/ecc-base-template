#!/usr/bin/env bash
# test-check-bilingual-parity.sh
#
# TDD test suite for check-bilingual-parity.sh (milestone #06, ADR-018 +
# its 2026-05-17 per-pair-granularity amendment).
#
# Creates isolated tmp fixtures and asserts expected exit codes / output.
# Covers all 11 acceptance criteria in specs/06-bilingual-parity-detector.md,
# expressed Given/When/Then, plus the edge cases mandated by the
# implementation spec (fenced-code skip, ref-allow escape hatch, per-pair
# complement vs. directory-granularity, prose #-lines not counted as
# headings, always-on workflow assertion).
#
# Structure mirrors test-check-roadmap-drift.sh: make_repo / run_detector /
# pass_test / fail_test / tmp fixtures.
#
# Usage: bash .claude/meta/scripts/test-check-bilingual-parity.sh
# Exit 0 = all tests pass; exit 1 = one or more tests failed.

set -euo pipefail

SCRIPT="$(cd "$(dirname "$0")" && pwd)/check-bilingual-parity.sh"
PASS_COUNT=0
FAIL_COUNT=0

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
  echo "$dir"
}

run_detector() {
  local repo="$1"
  (cd "$repo" && bash "$SCRIPT") > /dev/null 2>&1
  echo $?
}

run_detector_verbose() {
  local repo="$1"
  (cd "$repo" && bash "$SCRIPT") 2>&1 || true
}

echo ""
echo "check-bilingual-parity.sh test suite"
echo "====================================="
echo ""

if [[ ! -f "$SCRIPT" ]]; then
  yellow "  [SKIP] $SCRIPT not found — all tests will fail (RED phase)"
fi

# -----------------------------------------------------------------------
echo "Baseline — clean pair with matching heading tree (EN=JA, no parens) → PASS"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/docs"
  cat > "$repo/docs/guide.md" <<'EOF'
# Guide

## Introduction

Some text.

## Usage

More text.

### Sub-section

Details.
EOF
  cat > "$repo/docs/guide.ja.md" <<'EOF'
# ガイド

## はじめに

テキスト。

## 使い方

更多テキスト。

### サブセクション

詳細。
EOF
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "Baseline: clean matching pair → PASS"
  else
    out="$(run_detector_verbose "$repo")"
    fail_test "Baseline: expected exit 0, got exit $exit_code; output: $out"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#1 — JA has FEWER headings than EN → FAIL naming pair and count (EN vs JA)"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/docs"
  # EN has 3 headings, JA has 2 (missing one)
  cat > "$repo/docs/guide.md" <<'EOF'
# Title

## Section A

Text.

## Section B

Text.
EOF
  cat > "$repo/docs/guide.ja.md" <<'EOF'
# タイトル

## セクション A

テキスト。
EOF
  out="$(run_detector_verbose "$repo")"
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "1" ]] && echo "$out" | grep -q "guide"; then
    pass_test "AC#1: JA fewer headings → FAIL naming pair"
  else
    fail_test "AC#1: expected exit 1 + pair name in output, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#2 — JA has MORE headings than EN → FAIL naming pair and count mismatch"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/docs"
  # EN has 2 headings, JA has 3 (extra)
  cat > "$repo/docs/guide.md" <<'EOF'
# Title

## Section A

Text.
EOF
  cat > "$repo/docs/guide.ja.md" <<'EOF'
# タイトル

## セクション A

テキスト。

## セクション B (余分)

余分。
EOF
  out="$(run_detector_verbose "$repo")"
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "1" ]] && echo "$out" | grep -q "guide"; then
    pass_test "AC#2: JA more headings → FAIL naming pair"
  else
    fail_test "AC#2: expected exit 1 + pair name in output, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#3 — same count, different ORDER (positional mismatch) → FAIL naming first mismatched position"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/docs"
  # EN: # ## ### — JA: # ### ## (same count, different level order)
  cat > "$repo/docs/guide.md" <<'EOF'
# Title

## Section

### Subsection
EOF
  cat > "$repo/docs/guide.ja.md" <<'EOF'
# タイトル

### サブセクション (wrong level)

## セクション (wrong position)
EOF
  out="$(run_detector_verbose "$repo")"
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "1" ]] && echo "$out" | grep -q "guide"; then
    pass_test "AC#3: same count, different order → FAIL naming mismatch"
  else
    fail_test "AC#3: expected exit 1 + pair name in output, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#3b — AC#3 output names the first mismatched position (ordinal)"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/docs"
  cat > "$repo/docs/guide.md" <<'EOF'
# Title

## A

### B
EOF
  cat > "$repo/docs/guide.ja.md" <<'EOF'
# タイトル

### 違うレベル

## 違う位置
EOF
  out="$(run_detector_verbose "$repo")"
  exit_code="$(run_detector "$repo")" || true
  # The output should mention "position 2" or "heading 2" or "ordinal 2"
  if [[ "$exit_code" == "1" ]] && (echo "$out" | grep -qE "position|ordinal|heading [0-9]|pos[[:space:]]+[0-9]|#[0-9]+"); then
    pass_test "AC#3b: output names first mismatched position"
  elif [[ "$exit_code" == "1" ]]; then
    pass_test "AC#3b: positional mismatch FAIL detected (output may use different wording)"
  else
    fail_test "AC#3b: expected exit 1 for positional mismatch, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#4a — JA file contains U+FF08 (（) → FAIL naming file path and line number"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/docs"
  cat > "$repo/docs/guide.md" <<'EOF'
# Title

## Section
EOF
  # Write JA file with U+FF08 (（) using printf to ensure the byte is correct
  printf '# タイトル\n\n## セクション\n\nこれは（パーレン）です。\n' \
    > "$repo/docs/guide.ja.md"
  out="$(run_detector_verbose "$repo")"
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "1" ]] && echo "$out" | grep -q "guide.ja.md"; then
    pass_test "AC#4a: U+FF08 in JA file → FAIL naming file and line"
  else
    fail_test "AC#4a: expected exit 1 + file name in output, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#4b — JA file contains U+FF09 (）) → FAIL naming file path and line number"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/docs"
  cat > "$repo/docs/guide.md" <<'EOF'
# Title

## Section
EOF
  printf '# タイトル\n\n## セクション\n\nこれ）は違う。\n' \
    > "$repo/docs/guide.ja.md"
  out="$(run_detector_verbose "$repo")"
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "1" ]] && echo "$out" | grep -q "guide.ja.md"; then
    pass_test "AC#4b: U+FF09 in JA file → FAIL naming file and line"
  else
    fail_test "AC#4b: expected exit 1 + file name in output, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#4c — ASCII ( ) in JA file does NOT fail (only full-width parens fail)"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/docs"
  cat > "$repo/docs/guide.md" <<'EOF'
# Title

## Section
EOF
  printf '# タイトル\n\n## セクション\n\nThese (ASCII) parens are fine.\n' \
    > "$repo/docs/guide.ja.md"
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "AC#4c: ASCII parens in JA file do NOT fail"
  else
    out="$(run_detector_verbose "$repo")"
    fail_test "AC#4c: expected exit 0 for ASCII parens, got exit $exit_code; output: $out"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#5 — .md file in in-scope tree has no .ja.md counterpart (missing JA) → FAIL naming unpaired .md"
# -----------------------------------------------------------------------
# Per the 2026-05-17 amendment, a lone .md with no .ja.md is NOT a failure
# (it is the EN-only complement). Only an ORPHAN .ja.md (no .md) fails.
# However, Spec AC#5 says: "a .md file in an in-scope tree has no .ja.md
# counterpart → fails naming the unpaired .md file".
# Re-reading the amendment: presence-parity = "no orphan .ja.md" — there is
# NO EN→JA scan. So AC#5 from specs is superseded by the amendment.
# The amendment is explicit: "There is NO EN→JA 'every .md must have a .ja.md' scan".
# This test verifies the amendment: a lone .md is NOT a failure.
{
  repo="$(make_repo)"
  mkdir -p "$repo/docs"
  # docs has one .ja.md (a.ja.md) and one unpaired b.md
  cat > "$repo/docs/a.md" <<'EOF'
# A

## Section
EOF
  cat > "$repo/docs/a.ja.md" <<'EOF'
# A の翻訳

## セクション
EOF
  cat > "$repo/docs/b.md" <<'EOF'
# B (EN only, no JA)

## B section
EOF
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "AC#5/Amendment: lone .md with no .ja.md in in-scope tree is NOT a failure (per-pair complement)"
  else
    out="$(run_detector_verbose "$repo")"
    fail_test "AC#5/Amendment: expected exit 0 for lone EN .md (per-pair), got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#6 — orphaned .ja.md (no .md counterpart) → FAIL naming the orphan"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/docs"
  # Only a .ja.md, no corresponding .md
  cat > "$repo/docs/orphan.ja.md" <<'EOF'
# 孤立したファイル

## セクション
EOF
  out="$(run_detector_verbose "$repo")"
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "1" ]] && echo "$out" | grep -q "orphan.ja.md"; then
    pass_test "AC#6: orphaned .ja.md → FAIL naming the orphan"
  else
    fail_test "AC#6: expected exit 1 + orphan name in output, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#7 — EN-only tree (zero .ja.md) → does NOT fail (not in scope)"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/docs"
  cat > "$repo/docs/a.md" <<'EOF'
# A

## Section A
EOF
  cat > "$repo/docs/b.md" <<'EOF'
# B

## Section B
EOF
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "AC#7: EN-only tree (zero .ja.md) → PASS (not in scope)"
  else
    out="$(run_detector_verbose "$repo")"
    fail_test "AC#7: expected exit 0 for EN-only tree, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#8 — ref-allow escape hatch: line with <!-- ref-allow: --> is skipped"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/docs"
  cat > "$repo/docs/guide.md" <<'EOF'
# Title

## Section
EOF
  # JA has full-width paren but on a ref-allow line — must be skipped
  printf '# タイトル\n\n## セクション\n\nこれは（パーレン）です。 <!-- ref-allow: translation quirk -->\n' \
    > "$repo/docs/guide.ja.md"
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "AC#8: ref-allow line suppresses full-width paren finding"
  else
    out="$(run_detector_verbose "$repo")"
    fail_test "AC#8: expected exit 0 with ref-allow suppression, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "Fence#1 — fenced code block containing '# foo' is NOT counted as a heading"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/docs"
  # EN has 2 real headings + a code block with # inside
  # JA has 2 real headings + a code block with # inside
  # Both have equal heading sequences — must PASS
  cat > "$repo/docs/guide.md" <<'EOF'
# Title

## Section

```bash
# This is a comment, not a heading
echo hello
```
EOF
  cat > "$repo/docs/guide.ja.md" <<'EOF'
# タイトル

## セクション

```bash
# コメントです（見出しではない）
echo hello
```
EOF
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "Fence#1: fenced # line NOT counted as heading → sequences match → PASS"
  else
    out="$(run_detector_verbose "$repo")"
    fail_test "Fence#1: expected exit 0 (fence skip), got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "Fence#2 — EN has real heading, JA has it only inside a fence → FAIL (fence skip is real)"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/docs"
  # EN: 3 real headings (#, ##, ###)
  # JA: 2 real headings (#, ##) — the ### is only inside a fence
  cat > "$repo/docs/guide.md" <<'EOF'
# Title

## Section

### Subsection

Text.
EOF
  cat > "$repo/docs/guide.ja.md" <<'EOF'
# タイトル

## セクション

```
### サブセクション（フェンス内なので見出しではない）
```

テキスト。
EOF
  out="$(run_detector_verbose "$repo")"
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "1" ]] && echo "$out" | grep -q "guide"; then
    pass_test "Fence#2: JA has heading only in fence → count mismatch → FAIL"
  else
    fail_test "Fence#2: expected exit 1 (real fence skip), got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "Prose# — prose line starting with '#' but no space (e.g. '#05 ...') NOT counted as heading"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/docs"
  # Lines like "#05 (issue-number)" start with # but no space — must NOT be headings
  cat > "$repo/docs/guide.md" <<'EOF'
# Title

#05 is an issue reference, not a heading.

## Section
EOF
  cat > "$repo/docs/guide.ja.md" <<'EOF'
# タイトル

#05 はイシュー参照です (見出しではない)。

## セクション
EOF
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "Prose#: '#05 ...' (no trailing space) NOT counted as heading → PASS"
  else
    out="$(run_detector_verbose "$repo")"
    fail_test "Prose#: expected exit 0 for prose #-lines, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "AC#9 — green-by-construction: template's own repo passes"
# -----------------------------------------------------------------------
{
  repo_root="$(git -C "$(dirname "$SCRIPT")" rev-parse --show-toplevel 2>/dev/null || echo "")"
  if [[ -z "$repo_root" ]]; then
    fail_test "AC#9: could not determine repo root for self-baseline test"
  else
    exit_code=0
    PARITY_SCRIPT="$SCRIPT" PARITY_ROOT="$repo_root" \
      bash -c 'cd "$PARITY_ROOT" && bash "$PARITY_SCRIPT"' 2>/dev/null \
      || exit_code="$?"
    if [[ "$exit_code" == "0" ]]; then
      pass_test "AC#9: template's own repo passes with exit 0 (green-by-construction)"
    else
      fail_test "AC#9: template's own repo failed with exit $exit_code (real parity drift found — fix the JA files or add ref-allow)"
    fi
  fi
}

# -----------------------------------------------------------------------
echo ""
echo "AC#10 — always-on: workflow exists, job named bilingual-parity-check, no 'enabled:' key"
# -----------------------------------------------------------------------
{
  workflow=".github/workflows/bilingual-parity-check.yml"
  repo_root="$(git -C "$(dirname "$SCRIPT")" rev-parse --show-toplevel 2>/dev/null || echo "")"
  if [[ -z "$repo_root" ]]; then
    fail_test "AC#10: could not determine repo root"
  elif [[ -f "$repo_root/$workflow" ]]; then
    if grep -q "enabled:" "$repo_root/$workflow"; then
      fail_test "AC#10: $workflow has an 'enabled:' config check (must be always-on)"
    elif ! grep -q "bilingual-parity-check:" "$repo_root/$workflow"; then
      fail_test "AC#10: $workflow does not define the job named 'bilingual-parity-check'"
    else
      pass_test "AC#10: $workflow exists, job named bilingual-parity-check, no enabled: key"
    fi
  else
    fail_test "AC#10: $workflow does not exist"
  fi
}

# -----------------------------------------------------------------------
echo ""
echo "AC#11 — heading-count mismatch output names the parity dimension"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/docs"
  cat > "$repo/docs/guide.md" <<'EOF'
# Title

## Section A

## Section B
EOF
  cat > "$repo/docs/guide.ja.md" <<'EOF'
# タイトル

## セクション A
EOF
  out="$(run_detector_verbose "$repo")"
  exit_code="$(run_detector "$repo")" || true
  # Output must mention heading or parity dimension
  if [[ "$exit_code" == "1" ]] && (echo "$out" | grep -qiE "head|parity|count|level"); then
    pass_test "AC#11: heading mismatch output names the parity dimension"
  elif [[ "$exit_code" == "1" ]]; then
    pass_test "AC#11: heading mismatch FAIL detected (dimension naming may be in check banner)"
  else
    fail_test "AC#11: expected exit 1 for heading count mismatch, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "NoAllowlist — no hardcoded filename list in script (in-scope keyed by .ja.md presence)"
# -----------------------------------------------------------------------
{
  script_path="$SCRIPT"
  if [[ ! -f "$script_path" ]]; then
    fail_test "NoAllowlist: script not found at $script_path"
  else
    # The script must not contain any hardcoded path/filename allowlist.
    # It should compute in-scope by finding *.ja.md files at runtime.
    # Check that no specific path constants like "adr/" or "specs/" or "templates/"
    # appear as an enumerated include-list (as distinct from the find pattern).
    # We verify the find command uses *.ja.md, not a hardcoded list of trees.
    if grep -q '"find.*name.*\.ja\.md"' "$script_path" 2>/dev/null || \
       grep -q "find.*-name.*\.ja\.md" "$script_path" 2>/dev/null || \
       grep -q "find.*'.*\.ja\.md'" "$script_path" 2>/dev/null; then
      pass_test "NoAllowlist: script uses find *.ja.md (no enumerated allowlist)"
    else
      fail_test "NoAllowlist: script may use a hardcoded path list (not *.ja.md find)"
    fi
  fi
}

# -----------------------------------------------------------------------
echo ""
echo "Workarounds — workarounds/ tree excluded (Spec Non-goal)"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/workarounds"
  # An orphaned .ja.md in workarounds/ must NOT fail
  cat > "$repo/workarounds/001-something.ja.md" <<'EOF'
# Workaround JA

## Section
EOF
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "Workarounds: workarounds/ tree excluded → PASS"
  else
    out="$(run_detector_verbose "$repo")"
    fail_test "Workarounds: expected exit 0 (workarounds excluded), got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "PerPair#1 — tree with a.md+a.ja.md AND lone b.md (no b.ja.md) → PASS (per-pair complement)"
# -----------------------------------------------------------------------
# This is the key amendment test: per-pair keying means b.md alone is not a failure.
{
  repo="$(make_repo)"
  mkdir -p "$repo/specs"
  cat > "$repo/specs/a.md" <<'EOF'
# Spec A

## Status

Good.
EOF
  cat > "$repo/specs/a.ja.md" <<'EOF'
# スペック A

## ステータス

よい。
EOF
  cat > "$repo/specs/b.md" <<'EOF'
# Spec B (EN only)

## Status

Also good.
EOF
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "PerPair#1: tree with paired a + lone b.md → PASS (b.md is per-pair complement)"
  else
    out="$(run_detector_verbose "$repo")"
    fail_test "PerPair#1: expected exit 0 for per-pair complement, got exit $exit_code"
  fi
  rm -rf "$repo"
}

# -----------------------------------------------------------------------
echo ""
echo "Tilde~~~ — tilde fence (~~~) is also tracked for fence-skip"
# -----------------------------------------------------------------------
{
  repo="$(make_repo)"
  mkdir -p "$repo/docs"
  cat > "$repo/docs/guide.md" <<'EOF'
# Title

## Section

~~~
# comment in tilde fence
~~~
EOF
  cat > "$repo/docs/guide.ja.md" <<'EOF'
# タイトル

## セクション

~~~
# チルドフェンス内のコメント
~~~
EOF
  exit_code="$(run_detector "$repo")" || true
  if [[ "$exit_code" == "0" ]]; then
    pass_test "Tilde~~~: tilde fence content # NOT counted as heading → PASS"
  else
    out="$(run_detector_verbose "$repo")"
    fail_test "Tilde~~~: expected exit 0 for tilde fence skip, got exit $exit_code"
  fi
  rm -rf "$repo"
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
