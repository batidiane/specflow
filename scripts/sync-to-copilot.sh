#!/usr/bin/env bash
#
# sync-to-copilot.sh
#
# Regenerate .github/ Copilot Customization files from the canonical
# Claude Code sources (commands/, skills/, agents/) and verify they're
# in sync. Inspired by Superpowers' sync-to-codex-plugin.sh — same
# pattern (canonical sources -> platform-specific layer), narrower scope.
#
# This script does NOT translate prose. The .github/ files are hand-
# authored translations (Copilot prompts and instructions diverge from
# Claude SKILL.md bodies because tool surfaces differ). What the script
# verifies is structural parity:
#   - one .github/prompts/specflow-<cmd>.prompt.md per commands/<cmd>.md
#   - one .github/instructions/specflow-<skill>.instructions.md per skills/<skill>/SKILL.md
#   - one .github/chatmodes/<agent>.chatmode.md per agents/<agent>.md
#
# Drift modes detected:
#   - missing: a Copilot file that should exist for a given source.
#   - orphan: a Copilot file with no matching source (deleted command/skill).
#   - stale: a Copilot file older than its corresponding source by mtime.
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
declare -a EXPECTED_INSTRUCTIONS=()
declare -a EXPECTED_CHATMODES=()

# Commands -> prompts
for src in "$REPO_ROOT"/commands/*.md; do
  [[ -f "$src" ]] || continue
  base="$(basename "$src" .md)"
  EXPECTED_PROMPTS+=( ".github/prompts/specflow-${base}.prompt.md" )
done

# Skills -> instructions (skip github-publisher: it operates via the GitHub
# CLI which Copilot users typically don't run from VS Code chat).
for skill_dir in "$REPO_ROOT"/skills/*/; do
  [[ -d "$skill_dir" ]] || continue
  skill="$(basename "$skill_dir")"
  case "$skill" in
    github-publisher) continue ;;
  esac
  EXPECTED_INSTRUCTIONS+=( ".github/instructions/specflow-${skill}.instructions.md" )
done

# Agents -> chatmodes
for src in "$REPO_ROOT"/agents/*.md; do
  [[ -f "$src" ]] || continue
  base="$(basename "$src" .md)"
  EXPECTED_CHATMODES+=( ".github/chatmodes/${base}.chatmode.md" )
done

EXPECTED_REPO_INSTRUCTION=".github/copilot-instructions.md"

# ----------------------------------------------------------------------
# --list: print expected files and exit.
# ----------------------------------------------------------------------

if [[ $LIST_ONLY -eq 1 ]]; then
  echo "$EXPECTED_REPO_INSTRUCTION"
  printf '%s\n' "${EXPECTED_PROMPTS[@]}"
  printf '%s\n' "${EXPECTED_INSTRUCTIONS[@]}"
  printf '%s\n' "${EXPECTED_CHATMODES[@]}"
  exit 0
fi

# ----------------------------------------------------------------------
# Drift detection.
# ----------------------------------------------------------------------

MISSING=()
ORPHAN=()
STALE=()

# Helper: source path for a Copilot file. Reverse the naming rules.
source_for() {
  local copilot="$1"
  case "$copilot" in
    .github/copilot-instructions.md)
      echo "$REPO_ROOT/README.md"  # repo-wide doc — track against README mtime
      ;;
    .github/prompts/specflow-*.prompt.md)
      local cmd="${copilot##*/specflow-}"
      cmd="${cmd%.prompt.md}"
      echo "$REPO_ROOT/commands/${cmd}.md"
      ;;
    .github/instructions/specflow-*.instructions.md)
      local skill="${copilot##*/specflow-}"
      skill="${skill%.instructions.md}"
      echo "$REPO_ROOT/skills/${skill}/SKILL.md"
      ;;
    .github/chatmodes/*.chatmode.md)
      local agent="${copilot##*/}"
      agent="${agent%.chatmode.md}"
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
  local source_abs
  source_abs="$(source_for "$copilot")"

  if [[ ! -f "$copilot_abs" ]]; then
    MISSING+=( "$copilot (source: ${source_abs#$REPO_ROOT/})" )
    return
  fi

  if [[ -n "$source_abs" && -f "$source_abs" ]]; then
    if [[ "$source_abs" -nt "$copilot_abs" ]]; then
      STALE+=( "$copilot (source modified more recently: ${source_abs#$REPO_ROOT/})" )
    fi
  fi
}

check_one "$EXPECTED_REPO_INSTRUCTION"
for f in "${EXPECTED_PROMPTS[@]}"; do check_one "$f"; done
for f in "${EXPECTED_INSTRUCTIONS[@]}"; do check_one "$f"; done
for f in "${EXPECTED_CHATMODES[@]}"; do check_one "$f"; done

# Orphan check: Copilot files whose source no longer exists.
if [[ -d "$REPO_ROOT/.github/prompts" ]]; then
  while IFS= read -r -d '' f; do
    rel=".github/prompts/$(basename "$f")"
    src="$(source_for "$rel")"
    [[ -f "$src" ]] || ORPHAN+=( "$rel (no matching source)" )
  done < <(find "$REPO_ROOT/.github/prompts" -name 'specflow-*.prompt.md' -print0 2>/dev/null)
fi

if [[ -d "$REPO_ROOT/.github/instructions" ]]; then
  while IFS= read -r -d '' f; do
    rel=".github/instructions/$(basename "$f")"
    src="$(source_for "$rel")"
    [[ -f "$src" ]] || ORPHAN+=( "$rel (no matching source)" )
  done < <(find "$REPO_ROOT/.github/instructions" -name 'specflow-*.instructions.md' -print0 2>/dev/null)
fi

if [[ -d "$REPO_ROOT/.github/chatmodes" ]]; then
  while IFS= read -r -d '' f; do
    rel=".github/chatmodes/$(basename "$f")"
    src="$(source_for "$rel")"
    [[ -f "$src" ]] || ORPHAN+=( "$rel (no matching source)" )
  done < <(find "$REPO_ROOT/.github/chatmodes" -name '*.chatmode.md' -print0 2>/dev/null)
fi

# ----------------------------------------------------------------------
# Report.
# ----------------------------------------------------------------------

DRIFT=0
if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "Missing Copilot files (need to be created):"
  printf '  %s\n' "${MISSING[@]}"
  echo
  DRIFT=1
fi

if [[ ${#ORPHAN[@]} -gt 0 ]]; then
  echo "Orphan Copilot files (no matching canonical source — delete or restore source):"
  printf '  %s\n' "${ORPHAN[@]}"
  echo
  DRIFT=1
fi

if [[ ${#STALE[@]} -gt 0 ]]; then
  echo "Stale Copilot files (source modified more recently — review and update by hand):"
  printf '  %s\n' "${STALE[@]}"
  echo
  echo "Note: this script does NOT auto-translate prose. Each Copilot file is"
  echo "hand-authored because Copilot's tool surface (#codebase, #editFiles, etc.)"
  echo "differs from Claude Code's Skill / Agent / Bash tools. Open the source,"
  echo "open the Copilot file, reconcile by hand."
  echo
  DRIFT=1
fi

if [[ $DRIFT -eq 0 ]]; then
  echo "Copilot layer in sync with canonical sources."
  exit 0
fi

exit 1
