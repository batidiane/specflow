---
description: "Run @wiki-curator in full compilation mode against docs/wiki/wiki/ — performs cross-link integrity check, stale detection, confidence drift review, pattern promotion candidates, deduplication, and missing-page detection. Output is a diff proposal that requires owner approval before any wiki files are modified. Typically run end-of-sprint."
argument-hint: "(empty) or --scope <decisions|domains|patterns|interfaces|flows|runbooks|dependencies|policies|risks|glossary|lessons>"
allowed-tools: ["Read", "Bash", "Skill", "Agent"]
---

Run the **full compilation pass** of the engineering wiki under `docs/wiki/wiki/` via the `@wiki-curator` agent in Mode B.

The input is: $ARGUMENTS

## 1. Purpose

Run this command end-of-sprint, after a batch of related Triad cycles, or whenever the wiki feels drifted. In plain language, it asks the curator: *"What's missing? What's stale? What's contradicted? What deserves a confidence promotion or demotion?"* — the Karpathy LLM-Wiki "linting" pass.

Per-cycle distillation (Mode A) is wired through the project's TDD orchestrator (e.g. a `triad.md` Phase 8.5 step in projects that use a Triad workflow) and is **not** the job of this command. `/specflow:wiki` is purely the Mode B / compilation entry point.

## 2. User Input

`$ARGUMENTS` may be:

- **empty** → full compilation pass over the entire `docs/wiki/wiki/` tree (all categories + glossary + lessons + index + control-file refresh).
- `--scope decisions` → limit to ADRs only. Stale ADRs, broken cross-links, confidence drift, supersession, deduplication.
- `--scope domains` → limit to domain primers only. Stale primers, missing pages, primer-to-cycle drift.
- `--scope patterns` → limit to patterns only. "Name 3" gate compliance, watchlist re-evaluation, repeated-mechanic scan.
- `--scope interfaces` → limit to public-contract pages. Surface scan against codebase for HTTP / TS / GraphQL / RPC / CLI / event surfaces; canonical-source drift demotions; stability and audience flags.
- `--scope flows` → limit to user journeys. EARS-spec-to-flow alignment, UI test plan coverage, branch completeness.
- `--scope runbooks` → limit to operational procedures. `last_drilled` health, missing rollback sections, missing verification.
- `--scope dependencies` → limit to external services. Lock-file deltas, criticality calibration, fallback presence, vendor-SLA changes.
- `--scope policies` → limit to non-functional rules. Enforcement-code traceability, regulatory authority links, exception approval paths.
- `--scope risks` → limit to threat-model / known-risk register. Mitigation completeness (current/planned/residual all present), `status: open` entries, lifecycle transitions, severity × likelihood calibration.
- `--scope glossary` → limit to glossary. Jargon-loops, duplicate definitions, over-referenced terms without a primer.
- `--scope lessons` → limit to lessons. Duplicate H2s, contradicted lessons, missing rationale.

Any other `$ARGUMENTS` value → echo the help block (the bullet list above) and exit cleanly without invoking the curator.

## 3. Precondition check

Before invoking the curator:

1. Verify `docs/wiki/wiki/` exists (relative to the working directory).
2. If it does not exist, output the message:

   *"Wiki not initialized; run `/specflow:wiki-init` first to bootstrap the layout (creates `docs/wiki/sources/` + `docs/wiki/wiki/`, seeds the four control files `_pending.md` / `_log.md` / `_hot.md` / `index.md`, and amends the project root CLAUDE.md with wiki policies)."*

   Then exit cleanly. **Do NOT attempt to run the curator on an absent wiki.**

3. Verify the four control files exist: `docs/wiki/sources/_pending.md`, `docs/wiki/wiki/_log.md`, `docs/wiki/wiki/_hot.md`, `docs/wiki/wiki/index.md`. If any are missing, output:

   *"Wiki is partially bootstrapped; re-run `/specflow:wiki-init` (idempotent — fills only what is missing) to seed the missing control files."*

   Then exit cleanly.

4. If everything exists, continue to Execution.

## 4. Execution

Load the `wiki-curating` skill (the curator's own procedure manual), then invoke the `@wiki-curator` agent in **Mode B** with any scope filter from `$ARGUMENTS`.

The curator's two-pass discipline applies:

- **Pass 1: Read + Propose.** No writes. The curator walks the twelve-step compilation checklist (load tree → process pending queue → cross-link integrity → stale detection → confidence drift promotions → confidence drift demotions → pattern promotion candidates → deduplication → missing pages → refresh `_hot.md` → update `index.md` → append `_log.md` entry) and produces a single Markdown diff proposal. The diff includes both the curated-side changes AND the control-file updates (queue status flips, `_hot.md` rebuild, `index.md` rebuild, `_log.md` append).
- **STOP. Surface the diff to the owner. Do not write yet.**

Pass the scope filter (if present) to the agent in its invocation: e.g., *"Mode B, scope: decisions"*. The curator then loads only the relevant sub-tree (still respecting Mode B's full-tree budget for cross-link integrity).

## 5. HITL gate

The owner reviews the diff. Three outcomes are accepted — match the structure and language used by the project's REFACTOR HITL gate (e.g. a `triad.md` Phase 5 in projects that use a Triad workflow) so behavior is consistent across commands:

- ⛔ **Approve** — curator applies the diff verbatim.
- ⛔ **Modify** — owner edits the diff inline (in the response). Curator applies the modified version.
- ⛔ **Reject** — curator writes nothing and exits cleanly.

The owner may also approve subsets ("apply ADR-007, defer the glossary edits"). Treat that as Modify.

## 6. Apply phase

On approval (or modified approval):

1. The curator performs Pass 2 writes — inside `docs/wiki/wiki/`, plus status-marker flips on existing lines of `docs/wiki/sources/_pending.md` (the only `sources/` carve-out). Order: process pending entries first → curated-side writes → `_hot.md` refresh → `index.md` update → `_log.md` append.
2. After writes complete, output a summary:
   - **Pending queue.** Lines flipped from `[PENDING]` to `[COMPILED — ... by mode-B]`.
   - **Files written.** List paths with a one-line description per file.
   - **Lines added / removed.** Aggregate counts for the diff.
   - **Confidence-level changes applied.** Tabular: file → from → to → direction (promotion / demotion).
   - **Watchlist additions.** Patterns that did not yet meet the "Name 3" gate.
   - **Deferred items.** Anything the owner explicitly modified to defer.
   - **Hot cache.** Confirm `_hot.md` rebuilt (token count after refresh).
   - **Log entry.** Confirm one entry appended to `_log.md`.

3. Remind the owner: *"These changes are unstaged. Stage and commit separately when ready — `/specflow:wiki` does not commit."*

## 7. Failure modes

Handle each explicitly:

- **Curator finds nothing.** Output: *"No updates proposed; wiki is current."* Exit cleanly. Do not enter the HITL gate.
- **Diff rejected.** Output: *"Diff rejected; no changes written."* Exit cleanly.
- **Cross-link integrity check finds broken links.** Surface those in the diff as **MUST-FIX** items, separated from style-and-stale items. The owner may still reject the whole diff, but broken links are flagged as a different severity than "we should refresh this primer."
- **Boundary violation attempt.** If the curator at any point attempts to write outside `docs/wiki/wiki/` (other than the permitted status-marker flips on existing lines of `docs/wiki/sources/_pending.md`), abort the command and surface the violation: *"BOUNDARY VIOLATION: curator attempted to write to <path>; aborted, no changes written."* This is a defensive check — the curator's own prompt body forbids it, but the command guards against the failure mode in case the agent's reasoning lapses.
- **Token budget overrun (Mode B).** If the curator reports that even Mode B's full-tree budget is insufficient (very large wikis), suggest re-running with a `--scope` filter and exit cleanly without applying.

## 8. Notes

- `/specflow:wiki` is read-and-propose first, write-only-on-approval. Same shape as the REFACTOR gate.
- The curator never commits. Commits are the owner's call after the diff is applied.
- For per-cycle distillation (Mode A), see your project's TDD orchestrator integration; this command is the compilation-pass entry point only.
