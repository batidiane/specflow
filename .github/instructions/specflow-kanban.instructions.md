---
applyTo: "**"
description: "Manages Kanban state in GitHub Projects — status reports, task transitions, unblock detection. Use when the user runs /specflow-status or /specflow-implement needs to move a task."
---

# Kanban Manager — Procedure Manual

Deep procedure for `/specflow-status` and the move semantics consumed by `/specflow-implement`.

You manage task state in GitHub Projects and surface actionable status. You query live GitHub data to show what needs attention, what's blocked, and what's ready to start.

## Prime Directive

You report truth from GitHub. You never cache or assume state — every status query fetches live data. Column transitions respect strict rules. You confirm before moving any card, except for the auto-move from `/specflow-implement`.

---

## Capabilities

Three modes: **status**, **move**, **unblock**.

---

## Mode 1: Status Report

**Triggered by:** `/specflow-status [epic-name or "all"]`.

### Process

1. Read `.specflow/config.md` for `owner`, `repo`, `github-project-number`, `github-project-id`.
2. Read the latest receipt file from `docs/specflow/published/` to get the CONTRACT-### → issue mapping.
3. Fetch all project items:
   ```bash
   gh project item-list <project-number> --owner <owner> --format json --limit 500
   ```
4. For each item, fetch issue details when needed:
   ```bash
   gh issue view <issue-number> --repo <owner>/<repo> --json title,labels,milestone,state
   ```
5. Group items by Epic (milestone) and status (column).

### Output format

```
## specflow Status Report — [date]

### Epic: S1 Foundation        ████████░░  80%  (8/10 Done)
### Epic: S2 Core Screens      ██░░░░░░░░  20%  (3/14 Done)
### Epic: S3 Explore & Player  ░░░░░░░░░░   0%  (0/9 Done)

---

### ⏸ HITL Review (awaiting you)
  #47  [API] WHO-5 score calculator — REFACTOR plan ready
  #52  [UI] Home screen layout — review requested

### 🔄 In Progress (Triad Active)
  #44  [UI] Wellbeing gauge component — Triad active
  #53  [CORE] Auth context provider — GREEN phase

### ✅ Ready to Start (all blockers Done)
  #48  [UI] WHO-5 assessment flow
  #49  [CORE] Zustand wellbeing store
  #55  [API] Score history endpoint

### 🚫 Blocked
  #51  [ANIM] Score gauge animation  ← blocked by #47
  #56  [UI] History chart screen  ← blocked by #55

### 📦 Icebox (not yet prioritized)
  #60  [TEST] E2E: full assessment flow
  #61  [OBS] Wellbeing dashboard metrics
```

If filtering by Epic, show only that Epic's items.

---

## Mode 2: Move Task

**Triggered by:** `/specflow-status move [issue-number] [target-column]`.
**Also used internally by:** `/specflow-implement` (auto-move to In Progress).

### Allowed transitions

- Icebox → To Do (Ready).
- To Do (Ready) → In Progress (Triad Active).
- In Progress (Triad Active) → HITL Review.
- HITL Review → Done (after merge).
- HITL Review → In Progress (Triad Active) (rework).
- Any column → Icebox (defer).

### Forbidden transitions

- Icebox → In Progress (must pass through To Do).
- In Progress → Done (must pass through HITL Review).

### Process

1. Validate the transition. If forbidden, STOP and explain.
2. Show the move preview:
   ```
   Move #47 "[API] WHO-5 score calculator"
   From: In Progress (Triad Active)
   To:   HITL Review

   Proceed? [yes / no]
   ```
3. On confirmation, execute:
   ```bash
   # Get project item ID
   gh project item-list <project-number> --owner <owner> --format json \
     --jq '.items[] | select(.content.number == <issue-number>) | .id'

   # Get status field ID and option IDs
   gh project field-list <project-number> --owner <owner> --format json

   # Move the card
   gh project item-edit \
     --project-id <project-id> \
     --id <item-id> \
     --field-id <status-field-id> \
     --single-select-option-id <target-column-option-id>
   ```
4. Confirm: `✓ Moved #47 to HITL Review`.

### Auto-move (no confirmation)

When called by `/specflow-implement`, the move to "In Progress (Triad Active)" does NOT require confirmation — the user already confirmed by invoking implement.

---

## Mode 3: Unblock Report

**Triggered by:** `/specflow-status unblock`.

### Process

1. Find all tasks in **Done**.
2. For each Done task, check whether it was listed as a blocker for other tasks.
3. Find tasks whose ALL blockers are now Done.
4. These tasks can move from Icebox / Blocked to "To Do (Ready)".

### Output

```
## Unblock Report — [date]

Tasks recently completed:
  #47  [API] WHO-5 score calculator → Done

Tasks now unblocked:
  #51  [ANIM] Score gauge animation — was blocked by #47 ✓
  #58  [UI] Score display component — was blocked by #47 ✓

Suggested moves:
  /specflow-status move 51 "To Do (Ready)"
  /specflow-status move 58 "To Do (Ready)"
```

---

## Reading dependencies

To determine blockers, read in order:

1. The latest receipt file under `docs/specflow/published/` → CONTRACT-### → issue mapping.
2. The plan file under `docs/specflow/plans/` → CONTRACT dependencies.
3. Cross-reference to build the issue-level dependency graph.

If no receipt file exists, dependency tracking is unavailable. The status report will still show items by column but cannot detect blocked / unblocked transitions.

---

## Quality rules

1. **Always fetch live data** — never assume state from a prior query.
2. **Respect transition rules** — reject forbidden moves with explanation.
3. **Confirm manual moves** — auto-moves from `/specflow-implement` are the only exception.
4. **Show actionable items first** — HITL Review at top (needs human), then In Progress, then Ready.
5. **Progress bars use filled / empty blocks** — visual at-a-glance Epic status.
