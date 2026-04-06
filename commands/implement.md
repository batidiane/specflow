---
description: "Implement a specflow task using TDD. Reads the Prompt Contract, moves the task to In Progress, and delegates to the TDD workflow."
argument-hint: "GitHub issue number or CONTRACT-### ID (e.g. '49' or 'CONTRACT-001')"
allowed-tools: ["Read", "Bash", "Skill", "Agent"]
---

Load the `specflow:kanban` skill for task transitions, then delegate to the TDD workflow.

The input is: $ARGUMENTS

Before running:
1. Check if `.specflow/config.md` exists in the working directory.
   - If it exists: read it.
   - If it does not exist: warn but continue — implementation can work without config.

2. If $ARGUMENTS is empty, ask: "Which task should I implement? Provide a GitHub issue number
   or CONTRACT-### ID. Run `/specflow:status` to see what's ready."

3. Resolve the task:
   **If $ARGUMENTS is a number (issue number):**
   - Fetch the issue body: `gh issue view {number} --repo {owner}/{repo} --json body,title,labels`
   - Extract the Prompt Contract from the issue body

   **If $ARGUMENTS is a CONTRACT-### ID:**
   - Read the latest receipt file from `docs/specflow/published/` to find the issue number
   - If no receipt exists, read the contracts doc directly from `docs/specflow/contracts/`
   - Extract the Prompt Contract

4. Verify the task is in a valid state for implementation:
   - If it's in "Done": STOP — "This task is already complete."
   - If it's in "In Progress": Ask — "This task is already In Progress. Resume?"
   - If it's in "HITL Review": STOP — "This task is awaiting HITL review, not implementation."
   - If it's in "Icebox": Warn — "This task hasn't been moved to To Do yet. Implement anyway?"

5. Move the task to "In Progress (Triad Active)" using `specflow:kanban` (auto-move, no confirmation needed).

6. Extract the Prompt Contract sections and delegate to the TDD workflow:

   **Handoff to TDD:**
   The Prompt Contract's FAILURE CONDITIONS become the RED phase test specifications.
   The CONSTRAINTS become the architectural boundaries.
   The FORMAT defines the exact file outputs.
   The GOAL is the acceptance criterion.

   **Skill resolution (check in this order):**
   a. If the project has a `/triad` command available — invoke `/triad` with the full Prompt
      Contract as the task specification. This is the preferred implementation workflow.
   b. Only if `/triad` does NOT exist — fall back to `superpowers:test-driven-development`
      with the full Prompt Contract as the task specification.

7. When TDD reaches the REFACTOR gate (human approval needed):
   - Move the task to "HITL Review" using `specflow:kanban`
   - Present the REFACTOR plan to the user
   - STOP and wait for approval

8. After REFACTOR approval and completion:
   - The task stays in "HITL Review" until the user explicitly marks it Done
   - Print: "Task #{number} is in HITL Review. After merging, run:
     `/specflow:status move {number} Done`"
