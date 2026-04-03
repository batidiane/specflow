# Kanban Column Reference

The Kanban workflow uses GitHub Projects' "Status" single-select field.
Column definitions and transition rules for specflow.

---

## Columns

| Column | Meaning | Entry Condition | Who Acts |
|--------|---------|----------------|----------|
| **Icebox** | Specified but not yet prioritized | Published by specflow | — |
| **To Do (Ready)** | All blockers Done, Prompt Contract complete | Human moves after review | Human |
| **In Progress (Triad Active)** | AI agents executing RED → GREEN → REFACTOR | `/specflow:implement` moves here | AI |
| **HITL Review** | REFACTOR plan ready, awaiting human approval | Triad pauses at REFACTOR gate | Human |
| **Done** | Merged to main, all quality gates passed | Human approves and merges | Human |

---

## Transition Rules

```
Icebox → To Do (Ready)
  Condition: Human reviews and confirms task is ready
  Action: Human moves card manually or via /specflow:status move

To Do (Ready) → In Progress (Triad Active)
  Condition: /specflow:implement invoked for this task
  Action: specflow:kanban moves card automatically

In Progress (Triad Active) → HITL Review
  Condition: Triad loop reaches REFACTOR gate
  Action: specflow:kanban moves card automatically

HITL Review → In Progress (Triad Active)
  Condition: Human requests changes to REFACTOR plan
  Action: specflow:kanban moves card back

HITL Review → Done
  Condition: Human approves, PR merged, all quality gates pass
  Action: Human moves card manually or via /specflow:status move

Done → (terminal)
  No transitions out of Done
```

---

## Forbidden Transitions

- Icebox → In Progress (must go through To Do first)
- In Progress → Done (must go through HITL Review)
- Done → anything (terminal state)

---

## Project Field Discovery

To find the Status field ID and option IDs for a project:

```bash
# Get all project fields
gh project field-list {project-number} --owner {owner} --format json

# The Status field will have:
# - field ID (used in item-edit --field-id)
# - options array with id and name for each column
```

Store these IDs in `.specflow/config.md` once discovered:

```markdown
## GitHub Project Fields
- status-field-id: PVTSSF_...
- icebox-option-id: ...
- todo-option-id: ...
- in-progress-option-id: ...
- hitl-review-option-id: ...
- done-option-id: ...
```

If field IDs are not in config, the publisher will discover them at runtime
and suggest adding them to config for future runs.

---

## Column Colors (for label alignment)

| Column | Suggested Color |
|--------|----------------|
| Icebox | `#dfe1e6` (gray) |
| To Do | `#0052cc` (blue) |
| In Progress | `#ff991f` (amber) |
| HITL Review | `#6554c0` (purple) |
| Done | `#36b37e` (green) |
