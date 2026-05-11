#!/usr/bin/env bash
#
# specflow installer — bootstrap specflow into a project.
#
# Quick install (defaults: platform=copilot, ref=main):
#   curl -fsSL https://raw.githubusercontent.com/batidiane/specflow/main/install.sh | bash
#
# With options:
#   curl -fsSL https://raw.githubusercontent.com/batidiane/specflow/main/install.sh \
#     | bash -s -- --platform=both --ref=v1.1.0
#
# Local clone:
#   bash install.sh --platform=both
#
# Requires: bash 3.2+, git, mktemp, cp, perl. (Standard on macOS/Linux dev machines.)
#
# Install layouts by platform
# ---------------------------
#
#   --platform=copilot (DEFAULT — minimal, clean root):
#     AGENTS.md                            (required at root for Copilot/Codex/Gemini auto-discovery)
#     .github/                             (Copilot prompts + custom agents)
#     .specflow/skills/                    (vendored — referenced by .github/prompts/* via #file:)
#     .specflow/agents/                    (vendored — referenced by .github/agents/* via #file:)
#     .specflow.lock                       (install manifest)
#
#     The installer rewrites `#file:skills/` → `#file:.specflow/skills/` (and same for agents/)
#     inside the copied prompts and agent wrappers, so #file: references resolve at runtime.
#
#   --platform=claude (canonical Claude Code plugin layout):
#     AGENTS.md, skills/, agents/, commands/, .claude-plugin/ all at root.
#     No path rewriting — the layout matches the source repo.
#
#   --platform=both (everything at root, no rewriting):
#     Union of claude + .github/. Visual clutter at the project root, but symmetric
#     with the source repo. Pick this if specflow IS the project rather than a
#     dependency.
#
# Existing files are NOT overwritten unless --force is passed.

set -euo pipefail

REPO="batidiane/specflow"
REF="main"
PLATFORM="copilot"
TARGET="$(pwd)"
FORCE=0
DRY_RUN=0

usage() {
  cat <<'EOF'
specflow installer — bootstrap specflow into a project.

Usage:
  curl -fsSL https://raw.githubusercontent.com/batidiane/specflow/main/install.sh | bash
  bash install.sh [OPTIONS]

Options:
  --platform=<copilot|claude|both>  Which layer to install (default: copilot).
                                    copilot: hidden .specflow/ layout, clean root.
                                    claude:  canonical root layout (matches /plugin install).
                                    both:    union, root layout, no rewriting.
  --ref=<branch|tag|sha>            Git ref to install from (default: main).
  --target=<path>                   Install into a different directory (default: cwd).
  --force                           Overwrite existing files (use to update).
  --dry-run                         Show what would be installed without writing.
  -h, --help                        Show this help.

Examples:
  bash install.sh                                  # copilot, clean layout, no overwrite
  bash install.sh --platform=both --ref=v1.1.0
  bash install.sh --dry-run
  curl -fsSL .../install.sh | bash -s -- --force   # update existing install

Repo: https://github.com/batidiane/specflow
EOF
  exit "${1:-0}"
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform=*) PLATFORM="${1#--platform=}"; shift ;;
    --ref=*)      REF="${1#--ref=}"; shift ;;
    --target=*)   TARGET="${1#--target=}"; shift ;;
    --force)      FORCE=1; shift ;;
    --dry-run)    DRY_RUN=1; shift ;;
    -h|--help)    usage 0 ;;
    *)            echo "Unknown arg: $1" >&2; usage 2 ;;
  esac
done

case "$PLATFORM" in
  copilot|claude|both) ;;
  *) echo "Invalid --platform: $PLATFORM (expected: copilot, claude, or both)" >&2; exit 2 ;;
esac

# pairs() prints "src:dst" lines for the chosen platform — one entry per top-level
# file or directory to install. Bash 3-compatible (no associative arrays).
pairs() {
  case "$1" in
    copilot)
      echo "AGENTS.md:AGENTS.md"
      echo "skills:.specflow/skills"
      echo "agents:.specflow/agents"
      echo ".github:.github"
      ;;
    claude)
      echo "AGENTS.md:AGENTS.md"
      echo "skills:skills"
      echo "agents:agents"
      echo "commands:commands"
      echo ".claude-plugin:.claude-plugin"
      ;;
    both)
      echo "AGENTS.md:AGENTS.md"
      echo "skills:skills"
      echo "agents:agents"
      echo "commands:commands"
      echo ".claude-plugin:.claude-plugin"
      echo ".github:.github"
      ;;
  esac
}

# Sanity check the target dir.
mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"

# Clone the repo into a throwaway temp dir.
TMPDIR="$(mktemp -d -t specflow-install.XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "▶ specflow installer"
echo "  Repo:     $REPO"
echo "  Ref:      $REF"
echo "  Platform: $PLATFORM"
echo "  Target:   $TARGET"
[[ $DRY_RUN -eq 1 ]] && echo "  Mode:     DRY-RUN (no files will be written)"
echo

echo "▶ Fetching $REPO@$REF..."
if ! git clone --depth 1 --branch "$REF" "https://github.com/${REPO}.git" "$TMPDIR/specflow" >/dev/null 2>&1; then
  echo "✗ Clone failed. Verify:" >&2
  echo "    - network access to https://github.com/$REPO" >&2
  echo "    - ref '$REF' exists on that repo" >&2
  exit 1
fi

# Copy each pair (src in repo → dst in target).
SKIPPED=0
INSTALLED=0
while IFS= read -r pair; do
  src_rel="${pair%%:*}"
  dst_rel="${pair#*:}"
  src="$TMPDIR/specflow/$src_rel"
  dst="$TARGET/$dst_rel"

  if [[ ! -e "$src" ]]; then
    echo "  ⚠ source missing in repo: $src_rel (skipping)"
    continue
  fi

  if [[ -e "$dst" && $FORCE -eq 0 ]]; then
    echo "  ⊙ $dst_rel (already exists — pass --force to overwrite)"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    if [[ "$src_rel" == "$dst_rel" ]]; then
      echo "  + $dst_rel (would install)"
    else
      echo "  + $dst_rel (would install — remapped from $src_rel)"
    fi
    INSTALLED=$((INSTALLED + 1))
    continue
  fi

  mkdir -p "$(dirname "$dst")"
  if [[ -d "$src" ]]; then
    mkdir -p "$dst"
    cp -R "$src/." "$dst/"
  else
    cp "$src" "$dst"
  fi
  if [[ "$src_rel" == "$dst_rel" ]]; then
    echo "  ✓ $dst_rel"
  else
    echo "  ✓ $dst_rel  (← $src_rel)"
  fi
  INSTALLED=$((INSTALLED + 1))
done < <(pairs "$PLATFORM")

# For platform=copilot, the bulk content moves under .specflow/. Rewrite #file:
# references in the copied prompts, agent wrappers, and AGENTS.md so they
# resolve to the new locations.
if [[ "$PLATFORM" == "copilot" && $DRY_RUN -eq 0 && $INSTALLED -gt 0 ]]; then
  echo
  echo "▶ Rewriting #file: references for hidden layout..."
  REWRITE_TARGETS=()
  [[ -f "$TARGET/AGENTS.md" ]] && REWRITE_TARGETS+=("$TARGET/AGENTS.md")
  if [[ -d "$TARGET/.github/prompts" ]]; then
    for f in "$TARGET"/.github/prompts/*.prompt.md; do
      [[ -f "$f" ]] && REWRITE_TARGETS+=("$f")
    done
  fi
  if [[ -d "$TARGET/.github/agents" ]]; then
    for f in "$TARGET"/.github/agents/*.agent.md; do
      [[ -f "$f" ]] && REWRITE_TARGETS+=("$f")
    done
  fi

  for f in "${REWRITE_TARGETS[@]}"; do
    perl -i -pe '
      s|#file:skills/|#file:.specflow/skills/|g;
      s|#file:agents/|#file:.specflow/agents/|g;
      s|`skills/|`.specflow/skills/|g;
      s|`agents/wiki-curator|`.specflow/agents/wiki-curator|g;
    ' "$f"
    echo "  ✓ rewrote $(basename "$f")"
  done
fi

# Write the lockfile.
if [[ $DRY_RUN -eq 0 && $INSTALLED -gt 0 ]]; then
  VERSION="$(cd "$TMPDIR/specflow" && git rev-parse --short HEAD)"
  cat > "$TARGET/.specflow.lock" <<EOF
# specflow install manifest — auto-generated by install.sh
# Re-run install.sh --force to update.
ref: $REF
commit: $VERSION
platform: $PLATFORM
installed: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
  echo
  echo "  ✓ .specflow.lock (ref=$REF commit=$VERSION)"
fi

echo
echo "▶ Summary: $INSTALLED installed, $SKIPPED skipped."
[[ $SKIPPED -gt 0 ]] && echo "  Re-run with --force to overwrite skipped files."
echo

# Next-step hints per platform.
case "$PLATFORM" in
  copilot|both)
    echo "Next (Copilot Chat in VS Code):"
    echo "  1. Open this workspace in VS Code with Copilot Chat enabled."
    echo "  2. Type '/specflow-init' to bootstrap .specflow/config.md."
    ;;
esac
case "$PLATFORM" in
  claude|both)
    echo "Next (Claude Code):"
    echo "  1. Run '/specflow:init' to bootstrap .specflow/config.md."
    ;;
esac
echo
echo "Docs: https://github.com/$REPO#readme"
