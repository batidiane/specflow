---
description: "Query GitHub Projects for task status. Shows epic progress, HITL items, blocked tasks, and ready-to-start items."
argument-hint: "Epic name, 'all', 'unblock', or 'move [issue] [column]' (e.g. 'S2', 'all', 'move 47 Done')"
allowed-tools: ["Read", "Bash", "Skill"]
---

Load the `specflow:kanban` skill and run the appropriate mode based on input.

The input is: $ARGUMENTS

Before running:
1. Check if `.specflow/config.md` exists in the working directory.
   - If it exists: read it and tell the user "Loaded [project name] config".
   - If it does not exist: STOP — "⚠ Cannot query status without .specflow/config.md.
     The kanban manager needs owner, repo, and project-number.
     Run `/specflow:init` to generate config from your project."

2. Verify gh CLI is authenticated:
   - Run `gh auth status`
   - If not authenticated, STOP and tell the user to run `gh auth login`.

3. Determine the mode from $ARGUMENTS:

   **Mode: Status Report** (default)
   - If $ARGUMENTS is empty or "all": show full status report for all Epics
   - If $ARGUMENTS matches an Epic name (e.g. "S2", "S2: Core Screens"): show filtered report

   **Mode: Move Task**
   - If $ARGUMENTS starts with "move": parse as `move [issue-number] [target-column]`
   - Example: `move 47 Done` or `move 47 "HITL Review"`
   - The kanban skill handles validation and confirmation

   **Mode: Unblock Report**
   - If $ARGUMENTS is "unblock": show which tasks just became unblocked

Then load and follow the `specflow:kanban` skill with the determined mode.
