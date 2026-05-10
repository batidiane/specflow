---
mode: agent
description: "Implement a specflow task using TDD. Reads the Prompt Contract, moves the task to In Progress, and delegates to the TDD workflow."
tools: ['codebase', 'editFiles', 'findTestFiles', 'changes', 'problems', 'githubRepo']
---

# /specflow-implement

Implement a specflow task using TDD. Read the Prompt Contract, move the task to **In Progress (Triad Active)**, drive RED → GREEN → REFACTOR, pause at the REFACTOR gate for human review, then leave the task in **HITL Review**.

**Input:** `${input:task:GitHub issue number or CONTRACT-### ID (e.g. '49' or 'CONTRACT-001')}`

## Preconditions

1. Check `.specflow/config.md`. If present, read it. If missing, warn but continue — implementation can work without config, just without project-specific defaults.
2. If the input is empty, ask: *"Which task should I implement? Provide a GitHub issue number or CONTRACT-### ID. Run `/specflow-status` to see what's ready."*

## Resolve the task

**If the input is a number (issue number):**

```bash
gh issue view <number> --repo <owner>/<repo> --json body,title,labels,milestone,projectItems
```

Extract the Prompt Contract from the issue body.

**If the input is a CONTRACT-### ID:**

1. Read the latest receipt file under `docs/specflow/published/` to find the matching issue number.
2. If no receipt exists, read the contracts doc directly under `docs/specflow/contracts/`.
3. Extract the Prompt Contract.

## Validate state

Check the task's current Kanban column and reject implementations that are out of order:

- **Done** — STOP. *"This task is already complete."*
- **In Progress (Triad Active)** — ask: *"This task is already In Progress. Resume?"*. Continue on yes.
- **HITL Review** — STOP. *"This task is awaiting HITL review, not implementation."*
- **Icebox** — warn: *"This task hasn't been moved to To Do yet. Implement anyway?"*. Continue on yes.
- **To Do (Ready)** — proceed.

## Auto-move to In Progress

Move the task to "In Progress (Triad Active)" using the same procedure as `/specflow-status move`. Auto-move — no confirmation needed; the user already confirmed by invoking implement.

## Handoff to TDD

Extract the Prompt Contract sections and treat them as the task specification:

- **FAILURE CONDITIONS** become the RED phase test specifications.
- **CONSTRAINTS** become the architectural boundaries.
- **FORMAT** defines the exact file outputs.
- **GOAL** is the acceptance criterion.

### Scope Discipline (REFACTOR phase — pass verbatim to the TDD workflow)

The contract's CONSTRAINTS block already carries SCOPE-001..006 from `.specflow/config.md`. The TDD orchestrator MUST apply these rules at the REFACTOR gate:

- A finding fixable in **< 30 min** touching files **already in the PR diff** → **fix inline**. Present to HITL as "applied", not as a follow-up.
- A finding in a file **outside the PR diff** → **SKIP**. Note as *"out of scope (untouched file)"* in the audit report. Do not recommend a follow-up issue.
- A **style preference** with no correctness impact → **SKIP permanently**. Do not surface at the HITL gate.
- A **genuine spec gap** → **pause and surface to the owner** for `/specflow-specify` routing. Do not file a standalone issue.
- The REFACTOR audit report MUST end with `New issues recommended: [count]` — target **0**. Each count > 0 item must include a justification for why it cannot be fixed inline.

### TDD workflow selection (check in this order)

a. If the project has a `/triad` command available (the multi-agent TDD orchestrator — DESIGN → RED → GREEN → REFACTOR → QUALITY) — invoke `/triad` with the full Prompt Contract (including SCOPE-001..006) as the task specification. This is the preferred workflow.

b. Only if `/triad` does NOT exist — fall back to the equivalent `superpowers:test-driven-development` flow.

c. If neither is available — drive RED → GREEN → REFACTOR yourself using `#findTestFiles` to locate or create test files, `#changes` and `#problems` to review the diff and lint output, and `#editFiles` to apply changes. Keep the same rigour: write failing tests first, make them pass with the smallest change, then refactor with SCOPE-001..006 applied.

## REFACTOR HITL gate

When the TDD workflow reaches the REFACTOR gate:

1. Move the task to **HITL Review**.
2. Present the REFACTOR plan, including the `New issues recommended: [count]` tally. If count > 0, require a one-line justification per item before approval.
3. Before presenting any recommended new issue, confirm the orchestrator ran `gh issue list --search "<keywords>" --state open` (SCOPE-003). If not, run it now and dedupe.
4. STOP and wait for owner approval.

## After REFACTOR approval

- The task stays in **HITL Review** until the user explicitly marks it Done after merge.
- Print: *"Task #{number} is in HITL Review. After merging, run: `/specflow-status move {number} Done`"*.

## Reference

- Kanban transitions and move semantics: `.github/instructions/specflow-kanban.instructions.md`.
- Contract structure (GOAL / CONSTRAINTS / FORMAT / FAILURE CONDITIONS): `.github/instructions/specflow-contract-writer.instructions.md`.
