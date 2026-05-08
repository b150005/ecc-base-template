#!/usr/bin/env bash
# check-citation-discipline.sh
#
# CI check that enforces the verification-layer citation rule across
# load-bearing documents: knowledge entries, ADRs, and PRDs. Any link
# whose hostname matches the secondary-source blocklist is flagged as
# a failure unless an inline escape comment is present on (or
# immediately above) the same line.
#
# The blocklist lives here in this script (single source of truth for
# the CI side); the verification-layer Skill references the same set
# of hostnames in its allowlist file. Keep them in sync — diverging
# them silently weakens the mechanism.
#
# Configuration: paths to scan come from .claude/verification.yml
# (or default to a hard-coded set when the file is missing). When the
# file exists with citation_discipline.enabled: false, the script
# exits 0 with a single informational line — derived projects can opt
# out without hard-failing CI.
#
# Exit codes:
#   0 — clean (or opted out)
#   1 — blocked links found
#
# Documented contract:
#   ADR-008, ADR-010
#   .claude/skills/verification-layer/research/checklist.md (allowlist)
#   .claude/verification.yml.example (citation_discipline section)

set -u

PROJECT_ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
CONFIG="${PROJECT_ROOT}/.claude/verification.yml"

DEFAULT_PATHS=(
  ".claude/learn/knowledge"
  ".claude/meta/adr"
  ".claude/meta/prd"
)

ENABLED="true"
PATHS=("${DEFAULT_PATHS[@]}")

if [ -f "${CONFIG}" ]; then
  in_section=0
  in_paths=0
  parsed_paths=()
  while IFS= read -r line; do
    case "${line}" in
      citation_discipline:* )
        in_section=1; in_paths=0
        ;;
      [a-zA-Z]*:* )
        in_section=0; in_paths=0
        ;;
      "  enabled:"* )
        if [ "${in_section}" = "1" ]; then
          val=$(echo "${line}" | sed 's/.*enabled:[[:space:]]*//' | tr -d '"' | tr -d "'")
          ENABLED="${val}"
        fi
        ;;
      "  paths:"* )
        if [ "${in_section}" = "1" ]; then
          in_paths=1
        fi
        ;;
      "    - "* )
        if [ "${in_section}" = "1" ] && [ "${in_paths}" = "1" ]; then
          p=$(echo "${line}" | sed 's/^    - [[:space:]]*//' | tr -d '"' | tr -d "'")
          parsed_paths+=("${p}")
        fi
        ;;
      "  "* )
        if [ "${in_paths}" = "1" ]; then in_paths=0; fi
        ;;
    esac
  done < "${CONFIG}"

  if [ ${#parsed_paths[@]} -gt 0 ]; then
    # Reject paths that try to escape the project root or use absolute
    # paths. The check is intentionally strict: scanned paths come from
    # an on-disk config file that a PR can modify, so untrusted values
    # must not be allowed to direct find(1) at arbitrary filesystem
    # locations.
    for candidate in "${parsed_paths[@]}"; do
      case "${candidate}" in
        /* | *..* | "" )
          echo "[citation-discipline] rejecting unsafe path in verification.yml: '${candidate}'"
          exit 1
          ;;
      esac
    done
    PATHS=("${parsed_paths[@]}")
  fi
fi

if [ "${ENABLED}" != "true" ]; then
  echo "[citation-discipline] disabled via .claude/verification.yml — skipping."
  exit 0
fi

BLOCKLIST=(
  "stackoverflow.com"
  "stackexchange.com"
  "qiita.com"
  "zenn.dev"
  "medium.com"
  "dev.to"
  "reddit.com"
  "blog."
  ".blog/"
  "hashnode.dev"
  "perplexity.ai"
  "phind.com"
  "you.com"
)

fail_count=0
for p in "${PATHS[@]}"; do
  full="${PROJECT_ROOT}/${p}"
  [ -e "${full}" ] || continue
  while IFS= read -r -d '' file; do
    line_no=0
    prev_line=""
    in_code_fence=0
    fence_char=""
    while IFS= read -r line; do
      line_no=$((line_no + 1))

      # Track fenced code blocks. A `~~~` opener can only be closed by
      # `~~~`; a ``` opener can only be closed by ```. Mixing them up
      # would silently merge two unrelated fences and let URLs in a
      # subsequent block escape the skip — that is a false-negative
      # path the citation-discipline check cannot afford.
      case "${line}" in
        '```'* )
          if [ "${in_code_fence}" = "1" ] && [ "${fence_char}" = '```' ]; then
            in_code_fence=0; fence_char=""
          elif [ "${in_code_fence}" = "0" ]; then
            in_code_fence=1; fence_char='```'
          fi
          prev_line="${line}"
          continue
          ;;
        '~~~'* )
          if [ "${in_code_fence}" = "1" ] && [ "${fence_char}" = '~~~' ]; then
            in_code_fence=0; fence_char=""
          elif [ "${in_code_fence}" = "0" ]; then
            in_code_fence=1; fence_char='~~~'
          fi
          prev_line="${line}"
          continue
          ;;
      esac
      [ "${in_code_fence}" = "1" ] && { prev_line="${line}"; continue; }

      # Strip inline code spans before any URL extraction. A URL inside
      # `backticks` is a citation example or a documentation reference,
      # not an actual reference; flagging it would be a false positive.
      # The sed expression removes the shortest non-greedy `...` spans
      # on the line, leaving the rest of the prose intact.
      stripped_line=$(echo "${line}" | sed 's/`[^`]*`//g')

      # Only look for hosts that appear inside an actual URL — either a
      # bare http(s):// scheme or a markdown link `](...)` target. This
      # skips meta-mentions of the hostname inside prose or comma-
      # separated lists in documentation.
      case "${stripped_line}" in
        *http://*|*https://*|*"]("* ) ;;
        * ) prev_line="${line}"; continue ;;
      esac

      # Extract URL-shaped tokens from the cleaned line. We only flag
      # the host if it appears inside a real URL token (http/https
      # scheme or a markdown link target). grep -oE is portable to
      # ubuntu-latest and macOS (BSD grep) alike.
      url_tokens=$(echo "${stripped_line}" | grep -oE 'https?://[^[:space:]<>"`)]+' || true)
      mdlink_tokens=$(echo "${stripped_line}" | grep -oE '\]\([^)]+\)' || true)
      candidates="${url_tokens}
${mdlink_tokens}"

      hit=""
      for host in "${BLOCKLIST[@]}"; do
        case "${candidates}" in
          *"${host}"* )
            hit="${host}"
            break
            ;;
        esac
      done
      [ -z "${hit}" ] && { prev_line="${line}"; continue; }

      case "${line}" in
        *"<!-- cite-allow:"* ) prev_line="${line}"; continue ;;
      esac
      case "${prev_line}" in
        *"<!-- cite-allow:"* ) prev_line="${line}"; continue ;;
      esac

      echo "${file}:${line_no}: blocked-source: ${hit}"
      echo "    line: ${line}"
      fail_count=$((fail_count + 1))
      prev_line="${line}"
    done < "${file}"
  done < <(find "${full}" -type f \( -name '*.md' -o -name '*.mdx' \) -print0 2>/dev/null)
done

if [ "${fail_count}" -gt 0 ]; then
  echo ""
  echo "[citation-discipline] FAIL — ${fail_count} blocked-source link(s) found."
  echo ""
  echo "Each load-bearing document (knowledge entries, ADRs, PRDs) must"
  echo "cite primary sources only. Replace each blocked link with a"
  echo "primary source from the allowlist, or add an inline escape:"
  echo ""
  echo "    <!-- cite-allow: <one-line reason> -->"
  echo ""
  echo "See .claude/skills/verification-layer/research/checklist.md for"
  echo "the full allowlist and rationale."
  exit 1
fi

echo "[citation-discipline] PASS — no blocked-source links in scanned paths."
exit 0
