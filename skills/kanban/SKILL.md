---
name: kanban
description: Manages Kanban state in GitHub Projects — status reports, task transitions, unblock detection. Use when the user runs /specflow:status or /specflow:implement needs to move a task.
---

# Kanban Manager

You manage task state in GitHub Projects and surface actionable status. You query live
GitHub data to show what needs attention, what's blocked, and what's ready to start.

## Prime Directive

You report truth from GitHub. You never cache or assume state — every status query
fetches live data. Column transitions respect strict rules (see `references/kanban-columns.md`).
You confirm before moving any card.

---

## Capabilities

This skill supports three modes: **status**, **move**, and **unblock**.

---

## Mode 1: Status Report

**Triggered by:** `/specflow:status [epic-name or "all"]`

### Process

1. Read `.specflow/config.md` for project identity (owner, repo, project-number)
2. Read the latest receipt file from `docs/specflow/published/` to get CONTRACT → issue mapping
3. Fetch all project items:

```bash
gh project item-list {project-number} \
  --owner {owner} \
  --format json \
  --limit 500
```

4. For each item, fetch issue details if needed:
```bash
gh issue view {issue-number} --repo {owner}/{repo} --json title,labels,milestone,state
```

5. Group items by Epic (milestone) and status (column)

### Output Format

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

**Triggered by:** `/specflow:status move [issue-number] [target-column]`
**Also used internally by:** `/specflow:implement` (auto-move to In Progress)

### Process

1. Validate the transition is allowed (see `references/kanban-columns.md`)
2. If transition is forbidden, STOP and explain why
3. Show the move preview:
   ```
   Move #47 "[API] WHO-5 score calculator"
   From: In Progress (Triad Active)
   To:   HITL Review

   Proceed? [yes / no]
   ```
4. On confirmation, execute:

```bash
# Get project item ID
gh project item-list {project-number} --owner {owner} --format json \
  --jq '.items[] | select(.content.number == {issue-number}) | .id'

# Get status field ID and option IDs (or read from config)
gh project field-list {project-number} --owner {owner} --format json

# Move the card
gh project item-edit \
  --project-id {project-id} \
  --id {item-id} \
  --field-id {status-field-id} \
  --single-select-option-id {target-column-option-id}
```

5. Confirm the move:
   ```
   ✓ Moved #47 to HITL Review
   ```

### Auto-Move (no confirmation needed)

When called by `/specflow:implement`, the move to "In Progress" does NOT require
confirmation — it's an expected part of the implement workflow. The user already
confirmed by invoking implement.

---

## Mode 3: Unblock Report

**Triggered by:** `/specflow:status unblock`

### Process

1. Find all tasks in "Done" column
2. For each Done task, check if it was listed as a blocker for other tasks
3. Find tasks whose ALL blockers are now Done
4. These tasks can move from Icebox/Blocked to "To Do (Ready)"

### Output

```
## Unblock Report — [date]

Tasks recently completed:
  #47  [API] WHO-5 score calculator → Done

Tasks now unblocked:
  #51  [ANIM] Score gauge animation — was blocked by #47 ✓
  #58  [UI] Score display component — was blocked by #47 ✓

Suggested moves:
  /specflow:status move 51 "To Do (Ready)"
  /specflow:status move 58 "To Do (Ready)"
```

---

## Reading Dependencies

To determine blockers, the kanban manager reads:
1. The receipt file → CONTRACT → issue mapping
2. The plan file → CONTRACT dependencies
3. Cross-references to build the issue-level dependency graph

If no receipt file exists, dependency tracking is unavailable. The status report
will show items by column but cannot detect blocked/unblocked transitions.

---

## Quality Rules

1. **Always fetch live data** — never assume state from prior queries
2. **Respect transition rules** — reject forbidden moves with explanation
3. **Confirm manual moves** — auto-moves from implement are the only exception
4. **Show actionable items first** — HITL Review at top (needs human), then In Progress, then Ready
5. **Progress bars use filled/empty blocks** — visual at-a-glance Epic status
