---
mode: agent
description: "Query GitHub Projects for task status. Shows epic progress, HITL items, blocked tasks, and ready-to-start items."
tools: ['codebase', 'githubRepo']
---

# /specflow-status

Query live GitHub Projects data and surface an actionable Kanban status report, move tasks between columns, or detect newly unblocked tasks.

**Input:** `${input:mode:Epic name, 'all', 'unblock', or 'move [issue] [column]' (e.g. 'S2', 'all', 'move 47 Done')}`

## Preconditions

1. Check `.specflow/config.md`.
   - **Exists** — read it; announce *"Loaded [project name] config"*.
   - **Missing** — STOP. *"⚠ Cannot query status without `.specflow/config.md`. The kanban manager needs owner, repo, and project-number. Run `/specflow-init` to generate config from your project."*
2. Verify `gh` CLI is authenticated (`gh auth status`). If not, STOP and tell the user to run `gh auth login`.

## Mode dispatch

Parse the input to choose one of three modes:

- **empty or `all`** → **Status Report** (full).
- **Epic name** (e.g. `S2`, `S2: Core Screens`) → **Status Report** filtered to that Epic.
- **`move <issue-number> <target-column>`** → **Move Task**.
- **`unblock`** → **Unblock Report**.

## Prime directive

Always fetch live data — never cache or assume state from a prior query. Column transitions respect strict rules; confirm before moving any card (except auto-moves from `/specflow-implement`).

## Mode 1: Status Report

1. Fetch all project items:
   ```bash
   gh project item-list <project-number> --owner <owner> --format json --limit 500
   ```
2. For each item, fetch issue details when needed:
   ```bash
   gh issue view <issue-number> --repo <owner>/<repo> --json title,labels,milestone,state
   ```
3. Group items by Epic (milestone) and status (column).
4. Render the report. Show actionable items first — HITL Review at the top, then In Progress, then Ready, then Blocked, then Icebox:

   ```
   ## specflow Status Report — <date>

   ### Epic: S1 Foundation        ████████░░  80%  (8/10 Done)
   ### Epic: S2 Core Screens      ██░░░░░░░░  20%  (3/14 Done)

   ---

   ### ⏸ HITL Review (awaiting you)
     #47  [API] WHO-5 score calculator — REFACTOR plan ready

   ### 🔄 In Progress (Triad Active)
     #44  [UI] Wellbeing gauge component — Triad active

   ### ✅ Ready to Start (all blockers Done)
     #48  [UI] WHO-5 assessment flow

   ### 🚫 Blocked
     #51  [ANIM] Score gauge animation  ← blocked by #47

   ### 📦 Icebox (not yet prioritized)
     #60  [TEST] E2E: full assessment flow
   ```

   If filtering by Epic, show only that Epic's items.

## Mode 2: Move Task

1. Parse: `move <issue-number> <target-column>` (e.g. `move 47 Done` or `move 47 "HITL Review"`).
2. Validate the transition against the allowed transitions:
   - Icebox → To Do (Ready).
   - To Do (Ready) → In Progress (Triad Active).
   - In Progress (Triad Active) → HITL Review.
   - HITL Review → Done (after merge).
   - HITL Review → In Progress (Triad Active) (rework).
   - Any column → Icebox (defer).

   Forbidden: Icebox → In Progress (must pass through To Do). In Progress → Done (must pass HITL Review). If forbidden, STOP and explain why.
3. Show a move preview:
   ```
   Move #47 "[API] WHO-5 score calculator"
   From: In Progress (Triad Active)
   To:   HITL Review

   Proceed? [yes / no]
   ```
4. On `yes`, execute:
   ```bash
   gh project item-list <project-number> --owner <owner> --format json \
     --jq '.items[] | select(.content.number == <issue>) | .id'
   gh project field-list <project-number> --owner <owner> --format json
   gh project item-edit \
     --project-id <project-id> \
     --id <item-id> \
     --field-id <status-field-id> \
     --single-select-option-id <target-column-option-id>
   ```
5. Confirm: `✓ Moved #47 to HITL Review`.

**Auto-move exception.** When called by `/specflow-implement`, the move to "In Progress (Triad Active)" does NOT require confirmation — the user already confirmed by invoking implement.

## Mode 3: Unblock Report

1. Find all tasks in **Done**.
2. For each Done task, check whether it was listed as a blocker for other tasks (read receipt files and the plan's dependency graph).
3. Surface tasks whose ALL blockers are now Done — they can move from Icebox / Blocked to "To Do (Ready)".

   ```
   ## Unblock Report — <date>

   Tasks recently completed:
     #47  [API] WHO-5 score calculator → Done

   Tasks now unblocked:
     #51  [ANIM] Score gauge animation — was blocked by #47 ✓

   Suggested moves:
     /specflow-status move 51 "To Do (Ready)"
   ```

## Reading dependencies

To determine blockers, read in order:

1. The latest receipt file under `docs/specflow/published/` → CONTRACT-### → issue mapping.
2. The plan file under `docs/specflow/plans/` → CONTRACT dependencies.
3. Cross-reference to build the issue-level dependency graph.

If no receipt file exists, dependency tracking is unavailable. The status report will still show items by column but cannot detect blocked / unblocked transitions.

## Quality rules

- Always fetch live data; never assume state from a prior query.
- Reject forbidden moves with explanation.
- Confirm manual moves; only `/specflow-implement` auto-moves to In Progress.
- Show actionable items first.
- Progress bars use filled / empty blocks for at-a-glance Epic status.

## Reference

Deep procedure (column transitions, dependency parsing): `.github/instructions/specflow-kanban.instructions.md`.
