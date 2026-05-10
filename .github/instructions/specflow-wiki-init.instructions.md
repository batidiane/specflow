---
applyTo: "docs/wiki/**"
description: "Bootstraps or repairs the Karpathy-style engineering wiki under docs/wiki/. Detects current state, plans deltas against the target schema version, proposes a diff, and on owner approval seeds directories, control files, templates, the wiki schema file, and amends the project root CLAUDE.md. Idempotent — safe to re-run."
---

# Wiki Init — Bootstrap & Repair Procedure

Deep procedure for `/specflow-wiki-init`. Enforces idempotency, two-pass HITL, and schema-version pinning so a single command serves three use cases:

1. **Bootstrap** — wiki does not exist yet; create the full structure.
2. **Repair** — wiki partially exists; fill gaps, never overwrite owner-edited content.
3. **Schema bump** — wiki is at an older schema version; propose migration.

The procedure writes only into the **target project's** working tree:

- `docs/wiki/` and its subtree.
- The project's root `CLAUDE.md` (unless `--no-root-amend`).

It never writes to the specflow plugin itself.

## Current schema version

`schema_version: 1` (this plugin's shipped layout).

The schema version is recorded in the YAML frontmatter of `docs/wiki/wiki/CLAUDE.md`. Any future change to the wiki layout, control-file formats, or root CLAUDE.md block bumps this number and triggers a migration proposal on the next `/specflow-wiki-init` run.

---

## 1. Boundaries (enforcement layer)

The command does not enforce these — this body is the enforcement layer.

1. **Write scope.** Writes are restricted to:
   - `docs/wiki/**` in the target project (any new file or seeded template).
   - The target project's root `CLAUDE.md` (only between the marker comments — see §6).
2. **Never overwrite owner content.** Existing files in `docs/wiki/wiki/` are never overwritten unless they exactly match a previously-shipped seed and a schema bump explicitly migrates them. Owner-edited content always wins.
3. **Source files are off-limits.** `docs/wiki/sources/cycles/*.md` and `docs/wiki/sources/decisions/*.md` are populated by Triad archiving, not by this skill. Only `docs/wiki/sources/_pending.md` is seeded here.
4. **Read-only terminal commands.** Allowed: `mkdir -p`, `tree`, `ls`, `find`, `git status`, `git log`, `grep`, `wc`. Forbidden: `git commit`, `git push`, `git add`, `rm`, `mv`, anything that mutates beyond the explicit writes in §6.

If a write outside scope is attempted, STOP and surface: `BOUNDARY VIOLATION: requested write to <path>; refused.`

---

## 2. HITL discipline

Two passes. The two passes MUST NOT be combined.

- **Pass 1 — Detect + Propose.** No writes. Output is a Markdown diff proposal (see §5).
- **HITL gate.** The owner reviews and replies approve / modify / reject.
- **Pass 2 — Apply.** Writes only the approved deltas. On rejection, write nothing and exit cleanly.

---

## 3. Detection procedure (Pass 1)

Walk the target project and answer:

1. **Project root.** Is there a `CLAUDE.md` or `.specflow/config.md` in the cwd? If neither, abort with the failure message in §9.
2. **Wiki state.** Does `docs/wiki/` exist? Inventory:
   - Directories: `sources/`, `sources/cycles/`, `sources/decisions/`, `wiki/`, `wiki/decisions/`, `wiki/domains/`, `wiki/patterns/`, `wiki/interfaces/`, `wiki/flows/`, `wiki/runbooks/`, `wiki/dependencies/`, `wiki/policies/`, `wiki/risks/`.
   - Control files: `sources/_pending.md`, `wiki/_log.md`, `wiki/_hot.md`, `wiki/index.md`, `wiki/glossary.md`, `wiki/lessons.md`, `wiki/CLAUDE.md`.
   - Templates: nine `_template.md` files under their respective category dirs.
3. **Schema version.** If `wiki/CLAUDE.md` exists, read its frontmatter `schema_version`. Compare to target.
4. **Root CLAUDE.md state.** Does the project root `CLAUDE.md` exist? Does it contain markers `<!-- specflow:wiki-policies:start -->` / `<!-- specflow:wiki-policies:end -->`? If yes, is the content between them the current shipped block?
5. **User-edited content.** For each present seed file, read it and compare to the shipped seed content. If it diverges (more than whitespace), mark as **owner-edited — preserve**.

---

## 4. Delta computation

Build three buckets:

- **Create.** Directories or files that do not exist.
- **Update.** Files whose shipped content has changed across schema versions AND that are NOT owner-edited.
- **Skip.** Files that exist and either match the shipped seed exactly or are owner-edited.

If all three buckets are empty AND the schema version matches the target, output: *"Wiki is already at schema version N; nothing to do."* and exit cleanly without HITL.

---

## 5. Diff proposal format (Pass 1 output)

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

End with: **STOP. Awaiting owner approval before applying.**

---

## 6. Apply phase (Pass 2)

On approval (or modified approval), perform writes in this order. Each write is logged for the post-run summary.

1. **Create directories** with `mkdir -p`. Idempotent — never errors on existing dirs.
2. **Seed control files** from the plugin templates:
   - `_pending.md.template` → `docs/wiki/sources/_pending.md`
   - `_log.md.template` → `docs/wiki/wiki/_log.md`
   - `_hot.md.template` → `docs/wiki/wiki/_hot.md`
   - `index.md.template` → `docs/wiki/wiki/index.md`
   - `glossary.md.template` → `docs/wiki/wiki/glossary.md`
   - `lessons.md.template` → `docs/wiki/wiki/lessons.md`
3. **Seed per-type templates** (nine `_template.md` files under their respective category dirs).
4. **Seed or update wiki schema** (`CLAUDE.md.template` → `docs/wiki/wiki/CLAUDE.md`). If the file exists and is owner-edited, surface a Modify request rather than overwriting. The schema version is written into the frontmatter.
5. **Amend root `CLAUDE.md`** (skip entirely if `--no-root-amend`):
   - Read the file. Locate the markers `<!-- specflow:wiki-policies:start -->` and `<!-- specflow:wiki-policies:end -->`.
   - If markers are present: replace everything between them (inclusive) with the rendered block from `root-claude-block.template`.
   - If markers are absent: append a single newline followed by the rendered block to end of file.
   - Never touch content outside the markers.
6. **Append a bootstrap entry to `docs/wiki/wiki/_log.md`**:
   ```markdown
   ## [YYYY-MM-DD HH:MM] wiki-init — schema vN — wrote K / skipped J
   - Created: <count> directories
   - Wrote: <list paths>
   - Skipped: <list paths> (owner-edited or already current)
   - Root CLAUDE.md: <amended | skipped>
   ```

The timestamp uses local date / time in `YYYY-MM-DD HH:MM`. The log is the only file always written, even on a "nothing to do" repair (with the exception that if literally nothing changed, no log entry is written).

---

## 7. Output summary

After Pass 2:

```markdown
## /specflow-wiki-init — applied

Mode: [bootstrap | repair | schema-bump v<M>→v<N>]
Schema version: <N>

### Files written
- ...

### Files skipped (preserved)
- ...

### Root CLAUDE.md
[amended (block updated) | amended (block appended) | skipped (--no-root-amend)]

### Next steps
- Per-cycle distillation runs through the project's TDD orchestrator (e.g. triad.md Phase 8.5).
- Run `/specflow-wiki` end-of-sprint to compile the first batch of cycles.
- Stage and commit the new files when ready — `/specflow-wiki-init` does not commit.
```

---

## 8. Schema migration notes

When this plugin ships a schema version higher than what is in the project:

- The mode is `schema-bump v<M>→v<N>`.
- The diff proposal lists every file whose shipped content has changed across versions.
- For files that are owner-edited, the proposal surfaces a side-by-side note: *"Owner-edited; review the new shipped version manually if you want to migrate."* — the skill never overwrites owner content during a bump.
- The root CLAUDE.md block is updated in place between markers (this is exactly why the markers exist).

---

## 9. Failure modes

- **Cannot detect project root** → abort with: *"Cannot detect project root. Run from the project's root directory."* Do not enter the HITL gate.
- **Plugin templates missing** → abort with: *"wiki-init templates missing from plugin; reinstall specflow."*
- **Pass 2 write fails partway** → surface the partial state in the summary so the owner can re-run; the operation is idempotent so re-runs are safe.

---

## 10. Process summary

1. Parse the input flag — empty | `--no-root-amend` | `--schema-version N` | other (help).
2. Detect (project root, wiki state, schema version, root CLAUDE.md state).
3. Compute the delta.
4. Output the diff proposal.
5. **STOP.** Output *"STOP. Awaiting owner approval before applying."* and wait.
6. On approval, perform Pass 2 writes in §6 order.
7. Output the summary in §7.
