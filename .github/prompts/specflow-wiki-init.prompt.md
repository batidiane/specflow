---
mode: agent
description: "Bootstrap or repair the engineering wiki structure under docs/wiki/. Creates the Karpathy-style second-brain layout (sources/ + wiki/), seeds control files and templates, writes the wiki schema, and proposes amendments to the project root CLAUDE.md. Idempotent."
tools: ['codebase', 'editFiles']
---

# /specflow-wiki-init

Bootstrap or repair the engineering wiki under `docs/wiki/`. Sets up the directory layout, seeds control files and templates, writes the wiki schema, and amends the project root `CLAUDE.md` with wiki policies. Idempotent — safe to re-run for repair or schema-version bumps.

**Input:** `${input:flags:(empty) or --no-root-amend or --schema-version <N>}`

## Purpose

Single entry point for three use cases:

- **Bootstrap** — wiki does not exist yet; create the full structure.
- **Repair** — wiki partially exists; fill gaps, never overwrite owner-edited content.
- **Schema bump** — wiki is at an older schema version; propose a migration.

It is idempotent. Existing files are never overwritten without explicit owner approval. Missing files are seeded. The root `CLAUDE.md` block is updated in place between marker comments.

## Argument parsing

- **empty** → full bootstrap or repair. Detect current state, plan deltas, propose diff.
- `--no-root-amend` → skip amending the project root `CLAUDE.md`. All wiki-internal files still seeded.
- `--schema-version <N>` → force-target a specific wiki schema version. Default: latest shipped (currently `1`).
- Anything else → echo the help block (the bullet list above) and exit cleanly without writing anything.

## Two-pass HITL discipline

This command follows the same shape as the `wiki-curator` chat mode.

- **Pass 1 — Detect + Propose.** No writes. Output is a Markdown diff proposal listing every directory to create, every file to seed, every existing file to leave untouched, and the proposed amendment to the root `CLAUDE.md`.
- **STOP.** Surface the diff. Wait for owner approval.
- **Pass 2 — Apply.** On approval (or modified approval), perform writes. On rejection, write nothing and exit cleanly.

### HITL outcomes

- ⛔ **Approve** — apply the diff verbatim.
- ⛔ **Modify** — owner edits the diff inline (e.g., "seed templates but skip the root CLAUDE.md amendment"). Apply the modified version.
- ⛔ **Reject** — write nothing and exit cleanly.

## Pass 1 — Detect

Walk the target project and answer:

1. **Project root.** Is there a `CLAUDE.md` or `.specflow/config.md` in the cwd? If neither, abort with: *"Cannot detect project root. Run from the project's root directory."*.
2. **Wiki state.** Does `docs/wiki/` exist? Inventory:
   - Directories present: `sources/`, `sources/cycles/`, `sources/decisions/`, `wiki/`, `wiki/decisions/`, `wiki/domains/`, `wiki/patterns/`, `wiki/interfaces/`, `wiki/flows/`, `wiki/runbooks/`, `wiki/dependencies/`, `wiki/policies/`, `wiki/risks/`.
   - Control files: `sources/_pending.md`, `wiki/_log.md`, `wiki/_hot.md`, `wiki/index.md`, `wiki/glossary.md`, `wiki/lessons.md`, `wiki/CLAUDE.md`.
   - Templates: `wiki/decisions/_template.md`, `wiki/domains/_template.md`, `wiki/patterns/_template.md`, `wiki/interfaces/_template.md`, `wiki/flows/_template.md`, `wiki/runbooks/_template.md`, `wiki/dependencies/_template.md`, `wiki/policies/_template.md`, `wiki/risks/_template.md`.
3. **Schema version.** If `wiki/CLAUDE.md` exists, read its frontmatter `schema_version`. Compare to target.
4. **Root CLAUDE.md state.** Does the project root `CLAUDE.md` exist? Does it contain markers `<!-- specflow:wiki-policies:start -->` / `<!-- specflow:wiki-policies:end -->`? If yes, is the content between them the current shipped block?
5. **User-edited content.** For each present seed file, read it and compare to the shipped seed. If it diverges (more than whitespace), mark as **owner-edited — preserve**.

## Delta computation

Build three buckets:

- **Create.** Directories or files that do not exist.
- **Update.** Files whose shipped content has changed across schema versions AND that are NOT owner-edited (e.g., the root CLAUDE.md block itself, the wiki CLAUDE.md schema file).
- **Skip.** Files that exist and either match the shipped seed exactly or are owner-edited (must not overwrite).

If all three buckets are empty AND the schema version matches the target → output *"Wiki is already at schema version N; nothing to do."* and exit cleanly without entering the HITL gate.

## Diff proposal format

```markdown
## Wiki-Init — Diff Proposal

### Mode
[bootstrap | repair | schema-bump from vN to vM]

### Target schema version
N

### Directories to create
- `docs/wiki/sources/cycles/`
- ...

### Files to create
| Path | Purpose | Source |
| --- | --- | --- |
| `docs/wiki/sources/_pending.md` | Compilation queue | template |
| ... | ... | ... |

### Files to update
| Path | Reason | Diff summary |
| --- | --- | --- |

### Files to skip (already present)
| Path | Reason |
| --- | --- |
| `docs/wiki/wiki/glossary.md` | owner-edited — preserve |
| `docs/wiki/wiki/decisions/_template.md` | matches shipped seed |

### Root CLAUDE.md amendment
[one of: append block | update block in place | skip (--no-root-amend) | skip (no root CLAUDE.md present)]

### Boundaries respected
- All proposed paths begin with `docs/wiki/` or are the project root `CLAUDE.md`. ✓
- No writes proposed to `docs/wiki/sources/cycles/` or `docs/wiki/sources/decisions/` (Triad-owned). ✓

### Questions for owner (OWNER DECISIONS)
- [Anything ambiguous, e.g., a divergence in an existing seed file]
```

End the proposal with: **STOP. Awaiting owner approval before applying.**

## Pass 2 — Apply (on approval)

Perform writes in this exact order:

1. **Create directories** (idempotent — never errors on existing dirs):
   `docs/wiki/sources/{cycles,decisions}/`, `docs/wiki/wiki/{decisions,domains,patterns,interfaces,flows,runbooks,dependencies,policies,risks}/`.
2. **Seed missing control files** (`_pending.md`, `_log.md`, `_hot.md`, `index.md`, `glossary.md`, `lessons.md`).
3. **Seed missing per-type templates** (the nine `_template.md` files under their respective category dirs).
4. **Seed or update the wiki schema file** at `docs/wiki/wiki/CLAUDE.md`, with `schema_version: N` in frontmatter. If the file exists and is owner-edited, surface a Modify request rather than overwriting.
5. **Amend the project root `CLAUDE.md`** (skip entirely if `--no-root-amend`):
   - Locate markers `<!-- specflow:wiki-policies:start -->` / `<!-- specflow:wiki-policies:end -->`.
   - If markers are present: replace everything between them (inclusive) with the rendered block.
   - If markers are absent: append a newline followed by the rendered block to end of file.
   - Never touch content outside the markers.
6. **Append a bootstrap entry to `docs/wiki/wiki/_log.md`**:
   ```markdown
   ## [YYYY-MM-DD HH:MM] wiki-init — schema vN — wrote K / skipped J
   - Created: <count> directories
   - Wrote: <list paths>
   - Skipped: <list paths> (owner-edited or already current)
   - Root CLAUDE.md: <amended | skipped>
   ```

## Output summary

After Pass 2:

- **Files written.** Paths with one-line descriptions.
- **Files skipped (already present).** Paths.
- **Root CLAUDE.md.** *"amended (block updated)"*, *"amended (block appended)"*, or *"skipped (--no-root-amend)"*.
- **Schema version.** Set to N.
- **Next steps.** *"Run `/specflow-wiki` end-of-sprint to compile the first batch of cycles. Per-cycle distillation runs through the project's TDD orchestrator. Stage and commit the new files when ready — `/specflow-wiki-init` does not commit."*

## Failure modes

- **Project root not detected.** Exit with: *"Cannot detect project root. Run from the project's root directory."*.
- **Wiki already at target schema version with no missing files.** Output *"Wiki is already at schema version N; nothing to do."* and exit cleanly without entering the HITL gate.
- **User-edited content in a seed file.** Never overwrite. Surface as *"Skipped: <path> has user content."* in the diff.
- **Boundary violation.** If anything attempts to write outside `docs/wiki/` or the root `CLAUDE.md`, abort with *"BOUNDARY VIOLATION: wiki-init attempted to write to <path>; aborted, no changes written."*.

## Notes

- Read-and-propose first, write-only-on-approval. Same shape as `/specflow-wiki` and the project's REFACTOR gate.
- This command never commits.
- Re-running on an already-bootstrapped wiki is the canonical way to pick up a newer schema version when this plugin updates.

## Reference

Deep procedure (boundary enforcement, schema migration notes): `.github/instructions/specflow-wiki-init.instructions.md`.
