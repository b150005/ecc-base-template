#!/usr/bin/env bash
# init.sh — post-fork initializer for ecc-base-template-derived projects.
#
# Run this once after forking from ecc-base-template. It localizes the
# template's generic scaffolding to your project:
#   - Replace the `## About This Project` placeholder in .claude/CLAUDE.md
#   - Copy .env.example to .env (if .env does not exist)
#   - Print a next-steps checklist
#
# Flags:
#   --project-name <name>     Skip the interactive prompt for the project name
#   --description <desc>      Skip the interactive prompt for the one-line description
#   --stack <stack>           Skip the interactive prompt for the tech stack
#   --non-interactive         Fail instead of prompting if any field is missing
#   --dry-run                 Print planned changes without writing files
#   -h, --help                Show this help and exit
#
# This script is safe to re-run. It does not touch .claude/CLAUDE.md after
# the placeholder has already been replaced, and it will not overwrite an
# existing .env.

set -euo pipefail

project_name=""
description=""
stack=""
non_interactive=0
dry_run=0

usage() {
  sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-name)
      project_name="$2"; shift 2 ;;
    --description)
      description="$2"; shift 2 ;;
    --stack)
      stack="$2"; shift 2 ;;
    --non-interactive)
      non_interactive=1; shift ;;
    --dry-run)
      dry_run=1; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      printf "Unknown flag: %s\n" "$1" >&2
      usage >&2
      exit 2 ;;
  esac
done

# Resolve repo root (git preferred, relative fallback).
if repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  :
else
  repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
fi
cd "$repo_root"

say() { printf "%s\n" "$*"; }
warn() { printf "  [WARN] %s\n" "$*" >&2; }
ok() { printf "  [OK]   %s\n" "$*"; }

# prompt <label> <default> <var-name>
# Bash 3.1+ compatible (macOS bash 3.2 included). Uses `printf -v` for safe
# indirect assignment — never `eval` — so user input cannot be re-interpreted
# as shell syntax. The value is treated as a literal string throughout.
prompt() {
  local label="$1"
  local default="${2:-}"
  local var_name="$3"
  local current="${!var_name:-}"
  if [[ -n "$current" ]]; then
    return 0
  fi
  if [[ $non_interactive -eq 1 ]]; then
    printf "Missing required field: %s. Re-run with a flag or drop --non-interactive.\n" \
      "$label" >&2
    exit 2
  fi
  local answer
  if [[ -n "$default" ]]; then
    read -r -p "${label} [${default}]: " answer
    answer="${answer:-$default}"
  else
    read -r -p "${label}: " answer
    while [[ -z "$answer" ]]; do
      read -r -p "${label} (required): " answer
    done
  fi
  printf -v "$var_name" '%s' "$answer"
}

# ---------------------------------------------------------------------------
# 0. Preflight checks
# ---------------------------------------------------------------------------
if [[ ! -f ".claude/CLAUDE.md" ]]; then
  say "Expected .claude/CLAUDE.md at $repo_root — is this an ecc-base-template fork?"
  exit 1
fi

claude_md=".claude/CLAUDE.md"
has_placeholder=0
if grep -q '\[YOUR PROJECT NAME\]' "$claude_md"; then
  has_placeholder=1
fi

changelog="CHANGELOG.md"
changelog_is_pristine=0
if [[ -f "$changelog" ]]; then
  # Pristine means the file matches the v3 template exactly (small file, only
  # a header and [Unreleased] stub). We compare by content fingerprint.
  if grep -q '^## \[Unreleased\]' "$changelog" && [[ "$(wc -l < "$changelog")" -le 12 ]]; then
    changelog_is_pristine=1
  fi
fi

# ---------------------------------------------------------------------------
# 1. Collect project metadata
# ---------------------------------------------------------------------------
say "ecc-base-template post-fork initializer"
say "========================================"
say

if [[ $has_placeholder -eq 1 ]]; then
  prompt "Project name"           ""                   project_name
  prompt "One-line description"   ""                   description
  prompt "Primary tech stack"     "(e.g. Go / Gin / PostgreSQL)" stack
else
  ok "$claude_md: 'About This Project' already customized — skipping"
fi

say

# ---------------------------------------------------------------------------
# 2. Replace the About This Project placeholder in .claude/CLAUDE.md
# ---------------------------------------------------------------------------
if [[ $has_placeholder -eq 1 ]]; then
  # Build the replacement block in a temp file. The heredoc is single-quoted
  # ('TEMPLATE_EOF') so user-supplied values cannot be re-interpreted as shell
  # syntax. Field markers are placeholders that we substitute literally
  # afterwards.
  tmp_block="$(mktemp)"
  tmp_out="$(mktemp)"
  trap 'rm -f "$tmp_block" "$tmp_out"' EXIT
  # Build the block via printf with %s, which prints the value as a literal
  # string with no shell-syntax re-interpretation. This keeps user input safe
  # even with $, `, ", \, or newlines.
  {
    printf '%s — %s.\n' "$project_name" "$description"
    printf '\n'
    printf '**Stack:** %s\n' "$stack"
    printf '**Target users:** [who uses this]\n'
    printf '**Key constraints:** [performance, compliance, platform, etc.]\n'
  } > "$tmp_block"

  if [[ $dry_run -eq 1 ]]; then
    say "[dry-run] would replace the placeholder block in $claude_md with:"
    sed 's/^/    /' "$tmp_block"
  else
    # Use awk to replace the placeholder body between the '## About This
    # Project' heading and the next '## ' heading.
    awk -v block_file="$tmp_block" '
      BEGIN { state = "before" }
      state == "before" && /^## About This Project$/ { print; state = "in_section"; next }
      state == "in_section" && /^## / { state = "done" }
      state == "in_section" {
        if (!printed) {
          print ""
          while ((getline line < block_file) > 0) print line
          close(block_file)
          print ""
          printed = 1
        }
        next
      }
      { print }
    ' "$claude_md" > "$tmp_out"
    mv "$tmp_out" "$claude_md"
    ok "Updated $claude_md"
  fi
fi

# ---------------------------------------------------------------------------
# 3. Copy .env.example -> .env (only if .env does not yet exist)
# ---------------------------------------------------------------------------
if [[ -f ".env.example" && ! -f ".env" ]]; then
  if [[ $dry_run -eq 1 ]]; then
    say "[dry-run] would copy .env.example -> .env (mode 0600)"
  else
    cp .env.example .env
    chmod 600 .env
    ok "Created .env from .env.example (mode 0600 — edit to fill in real values)"
    warn ".env is gitignored. Never commit it. Verify with: git check-ignore -v .env"
  fi
elif [[ -f ".env" ]]; then
  ok ".env already exists — skipping"
fi

# ---------------------------------------------------------------------------
# 4. Reset the root CHANGELOG.md if it is still the pristine template copy
# ---------------------------------------------------------------------------
if [[ $changelog_is_pristine -eq 1 ]]; then
  ok "$changelog is already the pristine Unreleased-only template"
else
  warn "$changelog has entries — leaving it alone (run manually if you want to reset)"
fi

# ---------------------------------------------------------------------------
# 5. Print the next-steps checklist
# ---------------------------------------------------------------------------
say
say "Next steps"
say "----------"
say "  1. Replace README.md and README.ja.md with your project's own."
say "     The shipped README describes the template, not your project."
say "  2. Skim $claude_md and tune the 'Architecture Principles' and"
say "     'Code Quality Standards' sections to your project."
say "  3. Edit .env with real secrets. Never commit it."
say "  4. Customize .devcontainer/devcontainer.json for your stack."
say "  5. Extend .gitignore with stack-specific patterns (see the commented"
say "     references near the end of the file)."
say "  6. If you do not plan to use Developer Learning Mode, delete"
say "     .claude/meta/ and .github/workflows/learn-invariants.yml."
say "  7. Commit: 'chore: initialize from ecc-base-template'."
say
say "Ready. Open Claude Code at the repo root and give the orchestrator a real task."
