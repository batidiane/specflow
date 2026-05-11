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
# Requires: bash 3.2+, git, mktemp, cp, perl, grep.
#
# Install layouts by platform
# ---------------------------
#
#   --platform=copilot (DEFAULT — minimal, clean root):
#     AGENTS.md                            (specflow block merged; user content preserved)
#     .github/prompts/specflow-*.prompt.md (per-file install; other files untouched)
#     .github/agents/wiki-curator.agent.md (per-file install)
#     .specflow/skills/                    (vendored — referenced via #file:)
#     .specflow/agents/                    (vendored — referenced via #file:)
#     .specflow.lock
#
#     The installer rewrites `#file:skills/` → `#file:.specflow/skills/` (and same for
#     agents/) inside the specflow block of AGENTS.md and inside copied prompt + agent
#     wrapper files, so #file: references resolve at runtime.
#
#   --platform=claude (canonical Claude Code plugin layout):
#     AGENTS.md, skills/, agents/, commands/, .claude-plugin/ at root.
#     No path rewriting — layout matches the source repo.
#
#   --platform=both (everything at root):
#     Union of claude + .github/ files. Root layout, no rewriting.
#
# Conflict handling
# -----------------
#
#   AGENTS.md uses marker-region merge — your content is preserved unless you edit
#   between the BEGIN/END markers (clearly labelled). Backup written to AGENTS.md.bak
#   the first time we append a block.
#
#   .github/ files are installed per-file. Existing files (yours or specflow's from a
#   previous install) are SKIPPED unless --force. .github/workflows/, codeowners, etc.
#   are NEVER touched.
#
#   Other dirs (skills/, agents/, etc.) are skipped at directory level — pass --force
#   to overwrite.

set -euo pipefail

REPO="batidiane/specflow"
REF="main"
PLATFORM="copilot"
TARGET="$(pwd)"
FORCE=0
DRY_RUN=0

SPECFLOW_BEGIN="<!-- BEGIN specflow (managed by install.sh — edits between markers will be overwritten) -->"
SPECFLOW_END="<!-- END specflow -->"

# Specflow-owned files under .github/ — installed per-file, never as a directory.
GITHUB_FILES=(
  ".github/prompts/specflow-init.prompt.md"
  ".github/prompts/specflow-specify.prompt.md"
  ".github/prompts/specflow-contract.prompt.md"
  ".github/prompts/specflow-plan.prompt.md"
  ".github/prompts/specflow-publish.prompt.md"
  ".github/prompts/specflow-implement.prompt.md"
  ".github/prompts/specflow-status.prompt.md"
  ".github/prompts/specflow-wiki-init.prompt.md"
  ".github/prompts/specflow-wiki.prompt.md"
  ".github/agents/wiki-curator.agent.md"
)

usage() {
  cat <<'EOF'
specflow installer — bootstrap specflow into a project.

Usage:
  curl -fsSL https://raw.githubusercontent.com/batidiane/specflow/main/install.sh | bash
  bash install.sh [OPTIONS]

Options:
  --platform=<copilot|claude|both>  Which layer to install (default: copilot).
  --ref=<branch|tag|sha>            Git ref to install from (default: main).
  --target=<path>                   Install into a different directory (default: cwd).
  --force                           Overwrite existing specflow-owned files.
                                    Never affects unrelated files in .github/.
  --dry-run                         Show what would be installed without writing.
  -h, --help                        Show this help.

Conflict handling:
  • AGENTS.md  — specflow content merged inside BEGIN/END markers. Your existing
                 content is preserved. Backup to AGENTS.md.bak on first append.
  • .github/   — per-file install. .github/workflows/, codeowners, etc. untouched.
  • Other dirs — directory-level skip unless --force.

Examples:
  bash install.sh                                  # copilot, clean layout, safe defaults
  bash install.sh --platform=both --ref=v1.1.0
  bash install.sh --dry-run
  curl -fsSL .../install.sh | bash -s -- --force   # update an existing install

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

# regular_pairs() prints "src:dst" lines for directory-level installs.
# AGENTS.md (Fix A) and .github/ (Fix B) are handled separately by name.
regular_pairs() {
  case "$1" in
    copilot)
      echo "skills:.specflow/skills"
      echo "agents:.specflow/agents"
      ;;
    claude)
      echo "skills:skills"
      echo "agents:agents"
      echo "commands:commands"
      echo ".claude-plugin:.claude-plugin"
      ;;
    both)
      echo "skills:skills"
      echo "agents:agents"
      echo "commands:commands"
      echo ".claude-plugin:.claude-plugin"
      ;;
  esac
}

needs_rewrite() { [[ "$PLATFORM" == "copilot" ]]; }

# Rewrite #file: references inside a file from canonical (skills/, agents/) to
# the installed copilot layout (.specflow/skills/, .specflow/agents/).
rewrite_file() {
  local f="$1"
  perl -i -pe '
    s|#file:skills/|#file:.specflow/skills/|g;
    s|#file:agents/|#file:.specflow/agents/|g;
    s|`skills/|`.specflow/skills/|g;
    s|`agents/wiki-curator|`.specflow/agents/wiki-curator|g;
  ' "$f"
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

# For copilot platform, rewrite #file: references in the staged copies BEFORE
# they reach the target. This way the merge / per-file logic operates on
# already-correct content.
if needs_rewrite && [[ $DRY_RUN -eq 0 ]]; then
  echo "▶ Staging rewrites (#file:skills/ → #file:.specflow/skills/)..."
  rewrite_file "$TMPDIR/specflow/AGENTS.md"
  for relpath in "${GITHUB_FILES[@]}"; do
    [[ -f "$TMPDIR/specflow/$relpath" ]] && rewrite_file "$TMPDIR/specflow/$relpath"
  done
fi

# ----------------------------------------------------------------------
# Phase 1: regular directory installs (skills/, agents/, commands/, ...).
# ----------------------------------------------------------------------

SKIPPED=0
INSTALLED=0

echo "▶ Installing directories..."
while IFS= read -r pair; do
  [[ -z "$pair" ]] && continue
  src_rel="${pair%%:*}"
  dst_rel="${pair#*:}"
  src="$TMPDIR/specflow/$src_rel"
  dst="$TARGET/$dst_rel"

  if [[ ! -e "$src" ]]; then
    echo "  ⚠ source missing in repo: $src_rel (skipping)"
    continue
  fi

  if [[ -e "$dst" && $FORCE -eq 0 ]]; then
    echo "  ⊙ $dst_rel/ (already exists — pass --force to overwrite directory)"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    if [[ "$src_rel" == "$dst_rel" ]]; then
      echo "  + $dst_rel/ (would install)"
    else
      echo "  + $dst_rel/ (would install — remapped from $src_rel/)"
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
    echo "  ✓ $dst_rel/"
  else
    echo "  ✓ $dst_rel/  (← $src_rel/)"
  fi
  INSTALLED=$((INSTALLED + 1))
done < <(regular_pairs "$PLATFORM")

# ----------------------------------------------------------------------
# Phase 2: AGENTS.md — marker-region merge (Fix A).
# ----------------------------------------------------------------------

install_agents_md() {
  local src="$TMPDIR/specflow/AGENTS.md"
  local dst="$TARGET/AGENTS.md"

  if [[ ! -f "$src" ]]; then
    echo "  ⚠ source missing: AGENTS.md"
    return
  fi

  local body
  body="$(cat "$src")"

  # Compose the marked block. Note: heredoc-style assembly, no leading whitespace.
  local block
  block=$(printf '%s\n%s\n%s\n' "$SPECFLOW_BEGIN" "$body" "$SPECFLOW_END")

  if [[ ! -f "$dst" ]]; then
    if [[ $DRY_RUN -eq 1 ]]; then
      echo "  + AGENTS.md (would create with specflow block)"
    else
      printf '%s\n' "$block" > "$dst"
      echo "  ✓ AGENTS.md (created with specflow block)"
    fi
    INSTALLED=$((INSTALLED + 1))
    return
  fi

  if grep -qF "$SPECFLOW_BEGIN" "$dst"; then
    # Markers present → idempotent in-place update of the marked region.
    if [[ $DRY_RUN -eq 1 ]]; then
      echo "  ↻ AGENTS.md (would refresh specflow block in place)"
    else
      # Use perl with slurp mode to do multi-line non-greedy replace.
      # Pass the new block content via env var to avoid shell-quoting hell.
      BLOCK_REPLACEMENT="$block" \
      BEGIN_MARKER="$SPECFLOW_BEGIN" \
      END_MARKER="$SPECFLOW_END" \
      perl -i -0pe '
        my $b = quotemeta($ENV{BEGIN_MARKER});
        my $e = quotemeta($ENV{END_MARKER});
        my $repl = $ENV{BLOCK_REPLACEMENT};
        s/$b.*?$e/$repl/se;
      ' "$dst"
      echo "  ✓ AGENTS.md (specflow block refreshed)"
    fi
    INSTALLED=$((INSTALLED + 1))
    return
  fi

  # No markers → append the block. Save backup first (one-time).
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "  + AGENTS.md (would append specflow block; backup to AGENTS.md.bak)"
  else
    cp "$dst" "${dst}.bak"
    {
      echo ""
      printf '%s\n' "$block"
    } >> "$dst"
    echo "  ✓ AGENTS.md (specflow block appended; original saved as AGENTS.md.bak)"
  fi
  INSTALLED=$((INSTALLED + 1))
}

echo "▶ Installing AGENTS.md (marker-region merge)..."
install_agents_md

# ----------------------------------------------------------------------
# Phase 3: .github/ files (Fix B) — per-file, only specflow-owned paths.
# Only runs for copilot + both platforms.
# ----------------------------------------------------------------------

if [[ "$PLATFORM" == "copilot" || "$PLATFORM" == "both" ]]; then
  echo "▶ Installing .github/ files (per-file)..."
  for relpath in "${GITHUB_FILES[@]}"; do
    src="$TMPDIR/specflow/$relpath"
    dst="$TARGET/$relpath"

    if [[ ! -f "$src" ]]; then
      echo "  ⚠ source missing: $relpath"
      continue
    fi

    if [[ -f "$dst" && $FORCE -eq 0 ]]; then
      echo "  ⊙ $relpath (exists — pass --force)"
      SKIPPED=$((SKIPPED + 1))
      continue
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
      echo "  + $relpath (would install)"
      INSTALLED=$((INSTALLED + 1))
      continue
    fi

    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "  ✓ $relpath"
    INSTALLED=$((INSTALLED + 1))
  done
fi

# ----------------------------------------------------------------------
# Lockfile.
# ----------------------------------------------------------------------

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
echo "▶ Summary: $INSTALLED installed/updated, $SKIPPED skipped."
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
