---
agent: agent
description: "Implement a specflow task using TDD. Reads the Prompt Contract, moves the task to In Progress, and delegates to the TDD workflow."
tools: ['search/codebase', 'edit/editFiles', 'search/fileSearch', 'search/changes', 'read/problems', 'web/githubRepo']
---

# /specflow-implement

Implement a specflow task using TDD. Read the Prompt Contract, move the task to **In Progress (Triad Active)**, drive RED → GREEN → REFACTOR, pause at the REFACTOR gate for human review, then leave the task in **HITL Review**.

**Input:** `${input:task:GitHub issue number or CONTRACT-### ID (e.g. '49' or 'CONTRACT-001')}`

## Preconditions

1. Check `.specflow/config.md`. If present, read it. If missing, warn but continue — implementation can work without config, just without project-specific defaults.
2. If the input is empty, ask: *"Which task should I implement? Provide a GitHub issue number or CONTRACT-### ID. Run `/specflow-status` to see what's ready."*

## Resolve the task

- **If the input is a number** (issue number) — run `gh issue view <number> --repo <owner>/<repo> --json body,title,labels,milestone,projectItems` and extract the Prompt Contract from the body.
- **If the input is `CONTRACT-###`** — read the latest receipt under `docs/specflow/published/` to find the matching issue number; if no receipt exists, read the contract doc directly under `docs/specflow/contracts/`. Extract the Prompt Contract.

## Validate state (reject out-of-order implementations)

- **Done** → STOP. *"This task is already complete."*
- **In Progress (Triad Active)** → ask: *"This task is already In Progress. Resume?"*. Continue on yes.
- **HITL Review** → STOP. *"This task is awaiting HITL review, not implementation."*
- **Icebox** → warn: *"This task hasn't been moved to To Do yet. Implement anyway?"*. Continue on yes.
- **To Do (Ready)** → proceed.

## Kanban transition

Move the task to **In Progress (Triad Active)** using the procedure in `#file:skills/kanban/SKILL.md`. Auto-move — no confirmation needed; invoking `/specflow-implement` is the confirmation.

## TDD workflow

The Prompt Contract maps to TDD as: **FAILURE CONDITIONS** → RED tests, **CONSTRAINTS** → architectural boundaries, **FORMAT** → file outputs, **GOAL** → acceptance criterion. The contract's CONSTRAINTS already carry SCOPE-001..006 from `.specflow/config.md`.

Workflow selection (in order):

a. **If `/triad` is available** in the project — invoke it with the full Prompt Contract (including SCOPE-001..006) as the task specification. **Preferred.**
b. **Else if `superpowers:test-driven-development` is available** — fall back to it with the same input.
c. **Else (Copilot-only fallback)** — self-drive RED → GREEN → REFACTOR using `#search/fileSearch` to locate or create test files, `#search/changes` and `#read/problems` to inspect the diff and lint output, and `#edit/editFiles` to apply changes. Same rigour as triad: write failing tests first, make them pass with the smallest change, then refactor under SCOPE-001..006.

## REFACTOR gate (SCOPE-001..006 enforcement)

At REFACTOR, apply:

- < 30 min finding touching files already in the PR diff → **fix inline** (present to HITL as *applied*, not as follow-up).
- Finding in a file **outside the PR diff** → **SKIP** (note as *out of scope — untouched file* in the audit report; no follow-up issue).
- Style preference with no correctness impact → **SKIP permanently**.
- Genuine spec gap → **pause and surface to owner** for `/specflow-specify` routing.
- Audit report MUST end with `New issues recommended: [count]` — target 0. Every count > 0 item needs a justification.
- Before recommending any new issue, run `gh issue list --search "<keywords>" --state open` (SCOPE-003).

## HITL gate

1. Move the task to **HITL Review** using `#file:skills/kanban/SKILL.md`.
2. Present the REFACTOR plan with the `New issues recommended: [count]` tally and the SCOPE-003 dedupe check output.
3. STOP and wait for owner approval.

## After approval

- Task stays in **HITL Review** until the user marks it Done after merge.
- Print: *"Task #{number} is in HITL Review. After merging, run: `/specflow-status move {number} Done`"*.

## Wiki distillation gate (mandatory final step)

After the task is marked Done, ask: *"Cycle complete. Run `/specflow-wiki` (Mode A) now to distill decisions, patterns, and lessons into `docs/wiki/`? [yes / defer]"*

- **yes** → invoke `/specflow-wiki` with Mode A scope on this cycle's artifacts. Two-pass HITL ensures nothing is written without owner approval of the Pass 1 diff proposal.
- **defer** → print: *"Wiki distillation deferred. Run `/specflow-wiki` later (typically batched end of sprint). The cycle's artifacts remain in `docs/wiki/sources/_pending.md` until compiled."*

This gate lives in `/specflow-implement` (not in any TDD workflow) because not every cycle runs through `/triad`. The Phase 8.5 distillation hook only fires when triad was the workflow — for `superpowers:test-driven-development` or the option-c self-drive fallback, this is the only distillation trigger the cycle gets. Never silently skip the gate.

`/specflow-wiki` is safe to invoke even when `docs/wiki/sources/` has no pending entries — Mode A reports "nothing to distill" rather than failing.

## Reference

- Kanban transitions: `skills/kanban/SKILL.md`.
- Contract structure: `skills/contract-writer/SKILL.md`.
- Repo-wide rules: `AGENTS.md`.
