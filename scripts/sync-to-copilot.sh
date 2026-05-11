#!/usr/bin/env bash
#
# sync-to-copilot.sh
#
# Verify structural parity between the canonical Claude Code sources
# (commands/, skills/, agents/, AGENTS.md) and the Copilot Customization
# layer under .github/.
#
# specflow follows the superpowers SSoT pattern: skills/ is the payload,
# AGENTS.md is the agent-neutral README. The Copilot layer is intentionally
# thin — it does NOT duplicate skill bodies. Each .github/prompts/specflow-
# <cmd>.prompt.md is a ~30-line wrapper that references
# #file:skills/<name>/SKILL.md for the canonical procedure.
#
# This script verifies:
#   - AGENTS.md exists at the repo root (agent-neutral canonical instructions).
#   - one .github/prompts/specflow-<cmd>.prompt.md per commands/<cmd>.md.
#   - one .github/agents/<agent>.agent.md per agents/<agent>.md.
#   - no orphan files (prompts/agents that point at deleted sources).
#
# It does NOT compare bodies for drift, because the wrappers reference
# skills via #file: — drift is structurally impossible.
#
# Output is human-readable. Exit codes:
#   0 — in sync.
#   1 — drift detected (see stdout for details).
#   2 — script invocation error.
#
# Usage:
#   ./scripts/sync-to-copilot.sh                 # check; non-zero on drift.
#   ./scripts/sync-to-copilot.sh --list          # list expected files only.
#   ./scripts/sync-to-copilot.sh -h              # this help.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

usage() {
  sed -n '/^# Usage:/,/^$/s/^# \{0,1\}//p' "$0"
  exit "${1:-0}"
}

LIST_ONLY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --list)    LIST_ONLY=1; shift ;;
    -h|--help) usage 0 ;;
    *)         echo "Unknown arg: $1" >&2; usage 2 ;;
  esac
done

# ----------------------------------------------------------------------
# Compute expected Copilot files from the canonical sources.
# ----------------------------------------------------------------------

declare -a EXPECTED_PROMPTS=()
declare -a EXPECTED_AGENTS=()

# Commands -> prompts
for src in "$REPO_ROOT"/commands/*.md; do
  [[ -f "$src" ]] || continue
  base="$(basename "$src" .md)"
  EXPECTED_PROMPTS+=( ".github/prompts/specflow-${base}.prompt.md" )
done

# Agents -> .github/agents (Copilot custom agents)
for src in "$REPO_ROOT"/agents/*.md; do
  [[ -f "$src" ]] || continue
  base="$(basename "$src" .md)"
  EXPECTED_AGENTS+=( ".github/agents/${base}.agent.md" )
done

EXPECTED_AGENTS_MD="AGENTS.md"

# ----------------------------------------------------------------------
# --list: print expected files and exit.
# ----------------------------------------------------------------------

if [[ $LIST_ONLY -eq 1 ]]; then
  echo "$EXPECTED_AGENTS_MD"
  printf '%s\n' "${EXPECTED_PROMPTS[@]}"
  printf '%s\n' "${EXPECTED_AGENTS[@]}"
  exit 0
fi

# ----------------------------------------------------------------------
# Drift detection (presence only — no body comparison).
# ----------------------------------------------------------------------

MISSING=()
ORPHAN=()

# Helper: source path for a Copilot file. Reverse the naming rules.
source_for() {
  local copilot="$1"
  case "$copilot" in
    AGENTS.md)
      # No upstream source — AGENTS.md IS the canonical instruction file.
      echo ""
      ;;
    .github/prompts/specflow-*.prompt.md)
      local cmd="${copilot##*/specflow-}"
      cmd="${cmd%.prompt.md}"
      echo "$REPO_ROOT/commands/${cmd}.md"
      ;;
    .github/agents/*.agent.md)
      local agent="${copilot##*/}"
      agent="${agent%.agent.md}"
      echo "$REPO_ROOT/agents/${agent}.md"
      ;;
    *)
      echo ""
      ;;
  esac
}

check_one() {
  local copilot="$1"
  local copilot_abs="$REPO_ROOT/$copilot"

  if [[ ! -f "$copilot_abs" ]]; then
    local source_abs
    source_abs="$(source_for "$copilot")"
    if [[ -n "$source_abs" ]]; then
      MISSING+=( "$copilot (source: ${source_abs#$REPO_ROOT/})" )
    else
      MISSING+=( "$copilot" )
    fi
  fi
}

check_one "$EXPECTED_AGENTS_MD"
for f in "${EXPECTED_PROMPTS[@]}"; do check_one "$f"; done
for f in "${EXPECTED_AGENTS[@]}"; do check_one "$f"; done

# Orphan check: Copilot files whose source no longer exists.
if [[ -d "$REPO_ROOT/.github/prompts" ]]; then
  while IFS= read -r -d '' f; do
    rel=".github/prompts/$(basename "$f")"
    src="$(source_for "$rel")"
    [[ -f "$src" ]] || ORPHAN+=( "$rel (no matching source)" )
  done < <(find "$REPO_ROOT/.github/prompts" -name 'specflow-*.prompt.md' -print0 2>/dev/null)
fi

if [[ -d "$REPO_ROOT/.github/agents" ]]; then
  while IFS= read -r -d '' f; do
    rel=".github/agents/$(basename "$f")"
    src="$(source_for "$rel")"
    [[ -f "$src" ]] || ORPHAN+=( "$rel (no matching source)" )
  done < <(find "$REPO_ROOT/.github/agents" -name '*.agent.md' -print0 2>/dev/null)
fi

# Reject leftover .github/instructions/ — Option C deleted that layer.
if [[ -d "$REPO_ROOT/.github/instructions" ]]; then
  ORPHAN+=( ".github/instructions/ (directory removed in Option C — delete entirely)" )
fi

# Reject leftover copilot-instructions.md — AGENTS.md replaced it.
if [[ -f "$REPO_ROOT/.github/copilot-instructions.md" ]]; then
  ORPHAN+=( ".github/copilot-instructions.md (replaced by AGENTS.md at repo root)" )
fi

# ----------------------------------------------------------------------
# Report.
# ----------------------------------------------------------------------

DRIFT=0
if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "Missing files (need to be created):"
  printf '  %s\n' "${MISSING[@]}"
  echo
  DRIFT=1
fi

if [[ ${#ORPHAN[@]} -gt 0 ]]; then
  echo "Orphan files (no matching canonical source — delete or restore source):"
  printf '  %s\n' "${ORPHAN[@]}"
  echo
  DRIFT=1
fi

if [[ $DRIFT -eq 0 ]]; then
  echo "Copilot layer in sync with canonical sources (presence check)."
  echo "Body drift impossible — prompts reference skills/ via #file: in place of inlining."
  exit 0
fi

exit 1
