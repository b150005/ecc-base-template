#!/usr/bin/env bash
# coaching-context.sh
#
# UserPromptSubmit hook that injects the active coaching style's preamble as
# additionalContext on every user prompt — but only when Developer Learning
# Mode is enabled and a non-default coaching style is active.
#
# Behaviour:
#   - Learning Mode disabled OR config missing      → exit 0 silently (fail-open).
#   - Coaching style is "default" or unset          → exit 0 silently.
#   - Style name fails the strict allow-list        → exit 0 silently.
#   - Resolved style file escapes coach-styles dir  → exit 0 silently.
#   - Style file not found / unreadable             → exit 0 silently.
#   - jq missing                                    → exit 0 silently.
#   - Otherwise → emit a JSON object with hookSpecificOutput.additionalContext
#     containing the coach style preamble.
#
# Why fail-open: this hook runs on every user prompt. A misbehaving hook must
# never block the user. set -e is intentionally NOT used: every error path
# exits 0 explicitly so a maintainer cannot regress this contract by accident.
#
# Why the allow-list and realpath containment check below: the style name is
# read from a writable on-disk file (.claude/learn/config.json). Without
# validation, a tampered config could resolve STYLE_FILE to any .md path on
# the filesystem (path traversal), letting unrelated file contents flow into
# the prompt's additionalContext.
#
# Documented contract:
#   https://code.claude.com/docs/en/hooks (UserPromptSubmit, hookSpecificOutput.additionalContext)

set -u

# Resolve paths relative to the project root. Per the official hooks docs,
# settings.json hook commands receive $CLAUDE_PROJECT_DIR. We also fall back
# to the current working directory so the script is testable in isolation.
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
CONFIG="${PROJECT_ROOT}/.claude/learn/config.json"
STYLE_DIR="${PROJECT_ROOT}/.claude/skills/learn/coach-styles"

# Fast exits — anything missing means "do nothing".
[ -f "${CONFIG}" ] || exit 0
[ -d "${STYLE_DIR}" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

ENABLED=$(jq -r '.enabled // false' "${CONFIG}" 2>/dev/null) || exit 0
[ "${ENABLED}" = "true" ] || exit 0

STYLE=$(jq -r '.coach.style // "default"' "${CONFIG}" 2>/dev/null) || exit 0
[ -n "${STYLE}" ] && [ "${STYLE}" != "default" ] || exit 0

# Strict allow-list for the style name. Coach style files are owned by the
# template; their basenames are short kebab-case identifiers. Reject anything
# that could traverse out of STYLE_DIR or smuggle shell metacharacters.
case "${STYLE}" in
  *[!a-zA-Z0-9_-]* | -* | "" ) exit 0 ;;
esac

STYLE_FILE="${STYLE_DIR}/${STYLE}.md"
[ -f "${STYLE_FILE}" ] || exit 0

# Defense in depth: even after the allow-list rejects traversal sequences,
# canonicalize STYLE_FILE itself (following symlinks on the file, not just
# its parent directory) and verify it still lives under STYLE_DIR. This
# rejects the case where coach-styles/<name>.md is a symlink whose target
# is outside the styles dir. We avoid `realpath`/`readlink -f` because
# they are not portable to default macOS bash; instead we use a small
# manual loop that resolves the file via `cd "$(dirname …)" && pwd -P`
# combined with `readlink` until the path no longer points to a symlink.
CANONICAL_STYLE_DIR=$(cd "${STYLE_DIR}" 2>/dev/null && pwd -P) || exit 0
RESOLVE_TARGET="${STYLE_FILE}"
RESOLVE_HOPS=0
while [ -L "${RESOLVE_TARGET}" ]; do
  RESOLVE_HOPS=$((RESOLVE_HOPS + 1))
  [ "${RESOLVE_HOPS}" -gt 8 ] && exit 0          # symlink loop guard
  LINK_TARGET=$(readlink "${RESOLVE_TARGET}" 2>/dev/null) || exit 0
  case "${LINK_TARGET}" in
    /*) RESOLVE_TARGET="${LINK_TARGET}" ;;
    *) RESOLVE_TARGET="$(dirname "${RESOLVE_TARGET}")/${LINK_TARGET}" ;;
  esac
done
RESOLVED_DIR=$(cd "$(dirname "${RESOLVE_TARGET}")" 2>/dev/null && pwd -P) || exit 0
[ "${RESOLVED_DIR}" = "${CANONICAL_STYLE_DIR}" ] || exit 0

# Bound the injected context to keep prompts efficient. We use line count
# rather than byte count to avoid splitting a UTF-8 multibyte sequence
# mid-character — `jq --arg` would still accept the bytes, but the resulting
# additionalContext could end with a malformed character.
PREAMBLE=$(head -n 200 "${STYLE_FILE}" 2>/dev/null) || exit 0
[ -n "${PREAMBLE}" ] || exit 0

# Emit the documented JSON shape. jq handles string escaping correctly.
jq -n \
  --arg style "${STYLE}" \
  --arg body "${PREAMBLE}" \
  '{
     hookSpecificOutput: {
       hookEventName: "UserPromptSubmit",
       additionalContext: ("Active coaching style: \($style)\n\n\($body)")
     }
   }' 2>/dev/null || exit 0
