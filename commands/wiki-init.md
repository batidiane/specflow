---
description: "Bootstrap or repair the engineering wiki structure under docs/wiki/. Creates the Karpathy-style second-brain layout (sources/ + wiki/), seeds control files (_pending.md, _log.md, _hot.md, index.md), seeds templates, writes the wiki schema (docs/wiki/wiki/CLAUDE.md), and proposes amendments to the project root CLAUDE.md. Idempotent — safe to re-run for repair or schema-version bumps."
argument-hint: "(empty) or --no-root-amend or --schema-version <N>"
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Skill"]
---

Bootstrap or repair the engineering wiki under `docs/wiki/`. Sets up the directory layout, seeds control files and templates, writes the wiki schema, and amends the project root `CLAUDE.md` with wiki policies.

The input is: $ARGUMENTS

## 1. Purpose

This command is the single entry point for adopting the wiki in a new project, repairing partial state in an existing project, or bumping the wiki schema version when this plugin ships a newer layout.

It is **idempotent** — safe to re-run. Existing files are never overwritten without explicit owner approval; missing files are seeded; the root `CLAUDE.md` block is updated in place between marker comments.

## 2. User Input

`$ARGUMENTS` may be:

- **empty** → full bootstrap or repair mode. Detects current state, plans deltas, proposes diff.
- `--no-root-amend` → skip amending the project root `CLAUDE.md`. All wiki-internal files still seeded. Use when the project owner does not want a wiki policies block in their root CLAUDE.md (e.g., privacy, separation of concerns, multi-purpose repo).
- `--schema-version <N>` → force-target a specific wiki schema version. Default: latest shipped by this plugin (currently `1`). Use this for migration runs.

Any other `$ARGUMENTS` value → echo the help block (the bullet list above) and exit cleanly without writing anything.

## 3. Execution

Load the `wiki-init` skill (the bootstrap/repair procedure manual), then walk its procedure end-to-end.

The `wiki-init` skill enforces a two-pass HITL discipline matching `@wiki-curator`:

- **Pass 1: Detect + Propose.** Inspect the target project. Detect existing wiki state. Compute the delta against the target schema version. Output a Markdown diff proposal listing every directory to create, every file to seed, every existing file to leave untouched, and the proposed amendment to the root `CLAUDE.md`. **No writes.**
- **STOP.** Surface the diff. Wait for owner approval.
- **Pass 2: Apply.** On approval (or modified approval), perform writes. On rejection, write nothing and exit cleanly.

## 4. HITL gate

The owner reviews the diff. Three outcomes — match the language used by the project's other HITL gates so behavior is consistent:

- ⛔ **Approve** — apply the diff verbatim.
- ⛔ **Modify** — owner edits the diff inline. Apply the modified version.
- ⛔ **Reject** — write nothing and exit cleanly.

The owner may approve subsets ("seed templates but skip the root CLAUDE.md amendment"). Treat that as Modify.

## 5. Apply phase

On approval, the skill performs writes in this order:

1. Create directory tree (`docs/wiki/sources/{cycles,decisions}/`, `docs/wiki/wiki/{decisions,domains,patterns}/`).
2. Seed missing control files (`_pending.md`, `_log.md`, `_hot.md`, `index.md`, `glossary.md`, `lessons.md`).
3. Seed missing templates (`decisions/_template.md`, `domains/_template.md`, `patterns/_template.md`).
4. Seed or update the wiki schema file (`docs/wiki/wiki/CLAUDE.md`) with the target schema version.
5. Unless `--no-root-amend`, amend the project root `CLAUDE.md` between the markers `<!-- specflow:wiki-policies:start -->` / `<!-- specflow:wiki-policies:end -->`. If the markers are absent, append the block at end of file. If present, replace content between them.
6. Append a bootstrap entry to `docs/wiki/wiki/_log.md` with timestamp, schema version, files written, files skipped.

After writes, output a summary:

- **Files written.** List paths with one-line descriptions.
- **Files skipped (already present).** List paths.
- **Root CLAUDE.md.** Either *"amended (block updated)"*, *"amended (block appended)"*, or *"skipped (--no-root-amend)"*.
- **Schema version.** Set to N.
- **Next steps.** Remind the owner: *"Run `/specflow:wiki` end-of-sprint to compile the first batch of cycles."*

## 6. Failure modes

- **Project root not detected.** No `CLAUDE.md` and no `.specflow/config.md` in cwd → output *"Cannot detect project root. Run from the project's root directory."* and exit cleanly.
- **Wiki already at target schema version with no missing files.** Output *"Wiki is already at schema version N; nothing to do."* and exit cleanly without entering HITL gate.
- **User-edited content found in a seed file.** When repairing, if a seed file (e.g., `glossary.md`) has been edited beyond the empty seed, never overwrite. Surface as *"Skipped: <path> has user content."* in the diff.
- **Boundary violation attempt.** If the procedure attempts to write outside `docs/wiki/` or the root `CLAUDE.md`, abort and surface: *"BOUNDARY VIOLATION: wiki-init attempted to write to <path>; aborted, no changes written."*

## 7. Notes

- `/specflow:wiki-init` is read-and-propose first, write-only-on-approval. Same shape as `/specflow:wiki` and the project's REFACTOR gate.
- This command never commits. Commits are the owner's call after the diff is applied.
- After bootstrap, per-cycle distillation runs through the project's TDD orchestrator (e.g. a `triad.md` Phase 8.5 step in projects that use a Triad workflow) and end-of-sprint compilation runs through `/specflow:wiki`.
- Re-running on an already-bootstrapped wiki is the canonical way to pick up a newer schema version when this plugin updates.
