---
agent: agent
description: "Query GitHub Projects for task status. Shows epic progress, HITL items, blocked tasks, and ready-to-start items."
tools: ['search/codebase', 'githubRepo']
---

# /specflow-status

Query live GitHub Projects data and surface an actionable Kanban status report, move tasks between columns, or detect newly unblocked tasks.

**Input:** `${input:mode:Epic name, 'all', 'unblock', or 'move [issue] [column]' (e.g. 'S2', 'all', 'move 47 Done')}`

## Preconditions

1. Check `.specflow/config.md`. If present, read it and announce *"Loaded [project name] config"*. If missing, STOP — *"⚠ Cannot query status without `.specflow/config.md`. The kanban manager needs owner, repo, and project-number. Run `/specflow-init` first."*
2. Verify `gh` CLI is authenticated (`gh auth status`). If not, STOP and tell the user to run `gh auth login`.

## Mode dispatch

Parse the input:
- **empty or `all`** → full Status Report.
- **Epic name** (e.g. `S2`, `S2: Core Screens`) → Status Report filtered to that Epic.
- **`move <issue-number> <target-column>`** → Move Task (confirmation required unless invoked by `/specflow-implement`).
- **`unblock`** → Unblock Report (tasks whose dependencies just closed).

## Procedure

**Canonical procedure: `#file:skills/kanban/SKILL.md`.** Read it and follow it exactly. The skill defines the live-data prime directive (never cache), column transition rules, the move-confirmation gate, the unblock-detection logic, and the report format.

Translate Claude tool references per `#file:AGENTS.md` (§ Tool surface translation). `Bash` calls execute `gh` directly.

## Reference

- Canonical procedure: `skills/kanban/SKILL.md`.
- Repo-wide rules: `AGENTS.md`.
