---
description: "Run @wiki-curator in full compilation mode against docs/wiki/wiki/ — performs cross-link integrity check, stale detection, confidence drift review, pattern promotion candidates, deduplication, and missing-page detection. Output is a diff proposal that requires owner approval before any wiki files are modified. Typically run end-of-sprint."
argument-hint: "(empty) or --scope <decisions|domains|patterns|glossary|lessons>"
allowed-tools: ["Read", "Bash", "Skill", "Agent"]
---

Run the **full compilation pass** of the engineering wiki under `docs/wiki/wiki/` via the `@wiki-curator` agent in Mode B.

The input is: $ARGUMENTS

## 1. Purpose

Run this command end-of-sprint, after a batch of related Triad cycles, or whenever the wiki feels drifted. In plain language, it asks the curator: *"What's missing? What's stale? What's contradicted? What deserves a confidence promotion or demotion?"* — the Karpathy LLM-Wiki "linting" pass.

Per-cycle distillation (Mode A) is wired through the project's TDD orchestrator (e.g. `triad.md` Phase 8.5 in CocoMind) and is **not** the job of this command. `/specflow:wiki` is purely the Mode B / compilation entry point.

## 2. User Input

`$ARGUMENTS` may be:

- **empty** → full compilation pass over the entire `docs/wiki/wiki/` tree (all ADRs, primers, patterns, glossary, lessons, index).
- `--scope decisions` → limit to ADRs only. The curator inspects `docs/wiki/wiki/decisions/` for stale ADRs, broken cross-links, confidence drift, supersession opportunities, and deduplication.
- `--scope domains` → limit to domain primers only. Inspects `docs/wiki/wiki/domains/` for stale primers, missing pages signalled by glossary frequency, and primer-to-cycle-report drift.
- `--scope patterns` → limit to patterns only. Inspects `docs/wiki/wiki/patterns/` for "Name 3" gate compliance, re-evaluates watchlist entries, scans the codebase for repeated mechanics that may now have a third consumer.
- `--scope glossary` → limit to glossary. Inspects `docs/wiki/wiki/glossary.md` for jargon-loops, duplicate definitions, and terms over-referenced elsewhere without a primer.
- `--scope lessons` → limit to lessons. Inspects `docs/wiki/wiki/lessons.md` for duplicate H2 entries, lessons contradicted by recent cycles, and missing rationale subsections.

Any other `$ARGUMENTS` value → echo the help block (the bullet list above) and exit cleanly without invoking the curator.

## 3. Precondition check

Before invoking the curator:

1. Verify `docs/wiki/wiki/` exists (relative to the working directory).
2. If it does not exist, output the message:

   *"Wiki not initialized; run the wiki bootstrap step (see your project's wiki-curator setup docs, e.g. `setup-wiki-step-1-prompt.md`) first."*

   Then exit cleanly. **Do NOT attempt to run the curator on an absent wiki.**

3. If it does exist, continue to Execution.

## 4. Execution

Load the `wiki-curating` skill (the curator's own procedure manual), then invoke the `@wiki-curator` agent in **Mode B** with any scope filter from `$ARGUMENTS`.

The curator's two-pass discipline applies:

- **Pass 1: Read + Propose.** No writes. The curator walks the eight-step compilation checklist (cross-link integrity, stale detection, confidence drift — promotions, confidence drift — demotions, pattern promotion candidates, deduplication, missing pages) and produces a single Markdown diff proposal.
- **STOP. Surface the diff to the owner. Do not write yet.**

Pass the scope filter (if present) to the agent in its invocation: e.g., *"Mode B, scope: decisions"*. The curator then loads only the relevant sub-tree (still respecting Mode B's full-tree budget for cross-link integrity).

## 5. HITL gate

The owner reviews the diff. Three outcomes are accepted — match the structure and language used by the project's REFACTOR HITL gate (e.g. CocoMind's `triad.md` Phase 5) so behavior is consistent across commands:

- ⛔ **Approve** — curator applies the diff verbatim.
- ⛔ **Modify** — owner edits the diff inline (in the response). Curator applies the modified version.
- ⛔ **Reject** — curator writes nothing and exits cleanly.

The owner may also approve subsets ("apply ADR-007, defer the glossary edits"). Treat that as Modify.

## 6. Apply phase

On approval (or modified approval):

1. The curator performs Pass 2 writes — only inside `docs/wiki/wiki/`.
2. After writes complete, output a summary:
   - **Files written.** List paths with a one-line description per file.
   - **Lines added / removed.** Aggregate counts for the diff.
   - **Confidence-level changes applied.** Tabular: file → from → to → direction (promotion / demotion).
   - **Watchlist additions.** Patterns that did not yet meet the "Name 3" gate.
   - **Deferred items.** Anything the owner explicitly modified to defer.

3. Remind the owner: *"These changes are unstaged. Stage and commit separately when ready — `/specflow:wiki` does not commit."*

## 7. Failure modes

Handle each explicitly:

- **Curator finds nothing.** Output: *"No updates proposed; wiki is current."* Exit cleanly. Do not enter the HITL gate.
- **Diff rejected.** Output: *"Diff rejected; no changes written."* Exit cleanly.
- **Cross-link integrity check finds broken links.** Surface those in the diff as **MUST-FIX** items, separated from style-and-stale items. The owner may still reject the whole diff, but broken links are flagged as a different severity than "we should refresh this primer."
- **Boundary violation attempt.** If the curator at any point attempts to write outside `docs/wiki/wiki/`, abort the command and surface the violation: *"BOUNDARY VIOLATION: curator attempted to write to <path>; aborted, no changes written."* This is a defensive check — the curator's own prompt body forbids it, but the command guards against the failure mode in case the agent's reasoning lapses.
- **Token budget overrun (Mode B).** If the curator reports that even Mode B's full-tree budget is insufficient (very large wikis), suggest re-running with a `--scope` filter and exit cleanly without applying.

## 8. Notes

- `/specflow:wiki` is read-and-propose first, write-only-on-approval. Same shape as the REFACTOR gate.
- The curator never commits. Commits are the owner's call after the diff is applied.
- For per-cycle distillation (Mode A), see your project's TDD orchestrator integration; this command is the compilation-pass entry point only.
