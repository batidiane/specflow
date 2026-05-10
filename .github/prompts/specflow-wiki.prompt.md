---
mode: agent
description: "Run @wiki-curator in full compilation mode (Mode B) against docs/wiki/wiki/ — cross-link integrity, stale detection, confidence drift, pattern promotion candidates, deduplication, missing-page detection. Output is a diff proposal requiring owner approval. Typically end-of-sprint."
tools: ['codebase', 'editFiles', 'changes']
---

# /specflow-wiki

Run the **full compilation pass (Mode B)** of the engineering wiki under `docs/wiki/wiki/`. Plain-language: ask the curator *"What's missing? What's stale? What's contradicted? What deserves a confidence promotion or demotion?"* — the Karpathy LLM-Wiki "linting" pass.

**Input:** `${input:scope:(empty) or --scope <decisions|domains|patterns|interfaces|flows|runbooks|dependencies|policies|risks|glossary|lessons>}`

Per-cycle distillation (Mode A) is wired through the project's TDD orchestrator (e.g. a `triad.md` Phase 8.5) and is **not** the job of this command.

## When to run

End-of-sprint, after a batch of related cycles, or whenever the wiki feels drifted.

## Argument parsing

- **empty** → full compilation pass over the entire `docs/wiki/wiki/` tree.
- `--scope decisions` → limit to ADRs only.
- `--scope domains` → limit to domain primers.
- `--scope patterns` → limit to patterns. "Name 3" gate compliance, watchlist re-evaluation.
- `--scope interfaces` → limit to public-contract pages. Codebase surface scan; canonical-source drift demotions; stability and audience flags.
- `--scope flows` → user journeys. EARS-to-flow alignment, UI test plan coverage, branch completeness.
- `--scope runbooks` → operational procedures. `last_drilled` health, missing rollback sections, missing verification.
- `--scope dependencies` → external services. Lock-file deltas, criticality calibration, fallback presence, vendor-SLA changes.
- `--scope policies` → non-functional rules. Enforcement-code traceability, regulatory authority links, exception approval paths.
- `--scope risks` → threat-model / known-risk register. Mitigation completeness, `status: open` entries, lifecycle transitions, severity × likelihood calibration.
- `--scope glossary` → jargon-loops, duplicate definitions, over-referenced terms without a primer.
- `--scope lessons` → duplicate H2s, contradicted lessons, missing rationale.

Anything else → echo the help block above and exit cleanly without invoking the curator.

## Precondition check

Before invoking the curator:

1. Verify `docs/wiki/wiki/` exists (relative to the workspace root).
2. If absent → output: *"Wiki not initialized; run `/specflow-wiki-init` first to bootstrap the layout (creates `docs/wiki/sources/` + `docs/wiki/wiki/`, seeds the four control files `_pending.md` / `_log.md` / `_hot.md` / `index.md`, and amends the project root CLAUDE.md with wiki policies)."* Exit cleanly. Do NOT attempt to run the curator on an absent wiki.
3. Verify the four control files exist: `docs/wiki/sources/_pending.md`, `docs/wiki/wiki/_log.md`, `docs/wiki/wiki/_hot.md`, `docs/wiki/wiki/index.md`. If any are missing, output *"Wiki is partially bootstrapped; re-run `/specflow-wiki-init` (idempotent — fills only what is missing) to seed the missing control files."* and exit cleanly.
4. If everything exists, continue.

## Execution — invoke `wiki-curator` (Mode B)

Switch to the **wiki-curator** chat mode (`.github/chatmodes/wiki-curator.chatmode.md`) and pass the scope filter if any: *"Mode B, scope: <category>"*. The curator loads only the relevant sub-tree but still respects Mode B's full-tree budget for cross-link integrity.

The curator's two-pass discipline applies:

- **Pass 1 — Read + Propose.** No writes. The curator walks the 14-step compilation checklist (load tree → process pending queue → cross-link integrity → stale detection → confidence drift promotions → confidence drift demotions → pattern promotion candidates → deduplication → missing pages → interface surface scan → flow/runbook/dependency/policy/risk scan → refresh `_hot.md` → update `index.md` → append `_log.md` entry) and produces a single Markdown diff proposal. The diff includes both the curated-side changes AND the control-file updates (queue status flips, `_hot.md` rebuild, `index.md` rebuild, `_log.md` append).
- **STOP. Surface the diff to the owner. Do not write yet.**

## HITL gate

Three outcomes — matching the language of the REFACTOR HITL gate so behaviour is consistent across commands:

- ⛔ **Approve** — curator applies the diff verbatim.
- ⛔ **Modify** — owner edits the diff inline. Curator applies the modified version.
- ⛔ **Reject** — curator writes nothing and exits cleanly.

Subset approvals ("apply ADR-007, defer the glossary edits") are treated as Modify.

## Apply phase (on approval)

1. Curator performs Pass 2 writes inside `docs/wiki/wiki/`, plus status-marker flips on existing lines of `docs/wiki/sources/_pending.md` (the only `sources/` carve-out). Order: process pending entries first → curated-side writes → `_hot.md` refresh → `index.md` update → `_log.md` append.
2. Print the summary:
   - **Pending queue.** Lines flipped from `[PENDING]` to `[COMPILED — ... by mode-B]`.
   - **Files written.** Paths with one-line descriptions.
   - **Lines added / removed.** Aggregate counts.
   - **Confidence-level changes applied.** `file → from → to → direction (promotion / demotion)`.
   - **Watchlist additions.** Patterns that did not yet meet the "Name 3" gate.
   - **Deferred items.** Anything the owner modified to defer.
   - **Hot cache.** Confirm `_hot.md` rebuilt (token count after refresh).
   - **Log entry.** Confirm one entry appended to `_log.md`.
3. Remind the owner: *"These changes are unstaged. Stage and commit separately when ready — `/specflow-wiki` does not commit."*

## Failure modes

- **Curator finds nothing.** Output: *"No updates proposed; wiki is current."* Exit cleanly without entering the HITL gate.
- **Diff rejected.** Output: *"Diff rejected; no changes written."* Exit cleanly.
- **Cross-link integrity check finds broken links.** Surface as **MUST-FIX** items, separated from style-and-stale items. Owner may still reject the whole diff, but broken links are flagged as a different severity.
- **Boundary violation.** If the curator at any point attempts to write outside `docs/wiki/wiki/` (other than the permitted status-marker flips on existing lines of `docs/wiki/sources/_pending.md`), abort and surface: *"BOUNDARY VIOLATION: curator attempted to write to <path>; aborted, no changes written."*. This is a defensive check — the curator's prompt body already forbids it.
- **Token budget overrun.** If the curator reports that Mode B's full-tree budget is insufficient (very large wikis), suggest re-running with a `--scope` filter and exit cleanly without applying.

## Notes

- Read-and-propose first, write-only-on-approval. Same shape as the REFACTOR gate.
- The curator never commits.
- For per-cycle distillation (Mode A), see your project's TDD orchestrator integration; this command is the Mode B / compilation-pass entry point only.

## Reference

- Curator agent: `.github/chatmodes/wiki-curator.chatmode.md`.
- Deep procedure (14-step Mode B checklist, control files, "Name 3" gate, confidence dial): `.github/instructions/specflow-wiki-curating.instructions.md`.
