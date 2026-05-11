---
agent: agent
description: "Run @wiki-curator in full compilation mode (Mode B) against docs/wiki/wiki/ — cross-link integrity, stale detection, confidence drift, pattern promotion candidates, deduplication, missing-page detection. Output is a diff proposal requiring owner approval. Typically end-of-sprint."
tools: ['search/codebase', 'edit/editFiles', 'search/changes']
---

# /specflow-wiki

Full compilation pass (Mode B) over `docs/wiki/wiki/` — produces a diff proposal for owner approval; never writes silently.

**Input:** `${input:scope:'all' (default — full Mode B pass), or a category name to scope (e.g. 'decisions', 'patterns', 'domains')}`

## Preconditions

1. Confirm `docs/wiki/wiki/` exists. If not, STOP — *"⚠ Wiki not initialized. Run `/specflow-wiki-init` first."*
2. Switch to the **wiki-curator** custom agent (`.github/agents/wiki-curator.agent.md`) before starting. If you cannot switch, surface the boundary rules from `#file:agents/wiki-curator.md` and `#file:skills/wiki-curating/SKILL.md` explicitly before any action.

## Procedure

**Canonical procedure: `#file:skills/wiki-curating/SKILL.md`.** Read it and follow it exactly. The skill defines Mode B (full compilation pass): cross-link integrity verification, stale-detection thresholds, confidence drift review (owner-only promotions; curator may propose), pattern promotion under the *Name 3* rule, deduplication, and missing-page detection.

Translate Claude tool references per `#file:AGENTS.md` (§ Tool surface translation).

## HITL discipline (mandatory)

1. **Pass 1 — Read + Propose.** No writes outside `docs/wiki/wiki/` and no writes at all in this pass. Output one Markdown diff proposal listing: new files, modified files, confidence changes, watchlist additions, format-imitation references, and questions for the owner.
2. **HITL gate.** Owner replies approve / modify / reject. Subset approvals (*"apply ADR-007, defer the glossary edits"*) are treated as modify.
3. **Pass 2 — Apply.** Writes only the approved diff. On rejection, nothing is written.

The single carve-out: `[PENDING] → [COMPILED — YYYY-MM-DD by mode-B]` status flips on existing lines of `docs/wiki/sources/_pending.md`. Never add, delete, or reorder lines.

## Reference

- Canonical procedure: `skills/wiki-curating/SKILL.md`.
- Agent definition: `agents/wiki-curator.md`.
- Repo-wide rules: `AGENTS.md`.
