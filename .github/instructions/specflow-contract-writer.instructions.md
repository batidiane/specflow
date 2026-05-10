---
applyTo: "docs/specflow/contracts/**"
description: "Groups EARS requirements into atomic tasks and writes Prompt Contracts for each. Use when the user runs /specflow-contract or asks to create Prompt Contracts from EARS requirements."
---

# Contract Writer — Procedure Manual

Deep procedure for `/specflow-contract`. Auto-applied over the contracts tree so the rules travel with the artifacts.

You transform EARS requirements documents into atomic, executable Prompt Contracts that drive deterministic AI agent behaviour. Output feeds directly into `/specflow-plan`.

## Prime Directive

Every contract traces to specific REQ-### IDs. You never invent requirements, goals, or failure conditions. You group and structure what EARS already defined. If a requirement is marked `⚠ AMBIGUOUS`, you skip it entirely and list it in the **Skipped** section.

---

## Step 1 — Read your inputs

Before writing any contract:

1. Read the EARS requirements document.
2. Read `.specflow/config.md` if it exists — extract:
   - **Project Constraints** → injected into every contract's CONSTRAINTS section where applicable.
   - **Scope Discipline Constraints** (SCOPE-001..006) → injected into every contract's CONSTRAINTS section verbatim, as a dedicated subsection. These are pipeline rules and apply to every contract with no exceptions.
   - **Domain Labels** → used to tag contracts.
   - **Out of Scope** → reject any requirement targeting these.
3. Refresh the contract template (Step 6) and the failure-condition writing rules (Step 4).

If `.specflow/config.md` is missing the `## Scope Discipline Constraints` section, **STOP** and tell the user to run `/specflow-init` in update mode to add it. Do not proceed without it — a contract without scope rules is incomplete.

---

## Step 2 — Validate the EARS document

Before grouping, verify the input:

1. Confirm the document has a `## Requirements` section with REQ-### entries.
2. Check for any `⚠ AMBIGUOUS` entries — these CANNOT be contracted.
3. Count total requirements vs ambiguities.
4. If ALL requirements are ambiguous, STOP: *"Cannot write contracts — all requirements are ambiguous. Resolve ambiguities first."*

---

## Step 3 — Group requirements into atomic tasks

Each contract represents ONE atomic task — completable in a single AI coding session.

**Grouping rules:**

- Requirements that modify the same file or module go together.
- Requirements that share a data dependency go together.
- A single API endpoint + its error handling = one contract.
- A single UI component + its states = one contract.
- A store / state module + its actions = one contract.
- Never group more than 5 REQ-### items in one contract.
- If a group would exceed L effort, split it.

**Each group becomes one CONTRACT-###.**

---

## Step 4 — Write Prompt Contracts

For each group, write the four mandatory sections:

### GOAL

- One sentence. Binary pass / fail. Testable in under 1 minute.
- Must reference observable behaviour, not implementation.
- Bad: *"Implement the wellbeing score calculator."*
- Good: *"The WHO-5 score calculator accepts a 5-item array of integers (0–5), returns raw sum × 4 (range 0–100), and persists the result to the user's wellbeing history."*

### CONSTRAINTS

- Start with project constraints from `.specflow/config.md` (if applicable).
- Add task-specific technology constraints (library, pattern, architecture layer).
- Add forbidden approaches.
- Inject the **Scope Discipline** subsection verbatim (SCOPE-001..006 from config) — applies to every contract without exception, enforced at REFACTOR.
- End with: `Covers: REQ-001, REQ-002` (list all covered requirement IDs).

### FORMAT

- Exact file paths to create or modify.
- Exported symbol names and signatures (for Go: function signatures; for TS: type exports).
- Test file path.
- Any naming conventions specific to this task.
- **Binding sites.** When an artifact requires a separate registration or binding site to become reachable (route mounted on a mux, screen registered on a router, scheduled job added to a scheduler, event subscription, migration list entry, CLI command registration), FORMAT must name **both** the artifact file and its binding site. An artifact without its binding ships unreachable.

### FAILURE CONDITIONS

- Each is a checkbox: `- [ ] [description — maps to REQ-###]`.
- Every failure condition MUST reference a specific REQ-### ID.
- Minimum 2 failure conditions per contract.
- Include a coverage failure condition: `- [ ] Test coverage below [threshold]% (project config)`.
- Each failure condition becomes a RED phase test specification.

---

## Step 5 — Assign effort and dependencies

For each contract:

**Effort**

| Size | Duration | Criteria |
|------|----------|----------|
| XS | < 30 min | Config, locale, dependency add |
| S | 30 min – 2h | Simple component, single endpoint, utility |
| M | 2 – 4h | Complex screen, multi-step flow, state machine |
| L | 4 – 8h | Full player, animation system, integration layer |

If effort exceeds L, split the contract into smaller ones.

**Dependencies**

- If CONTRACT-B reads data that CONTRACT-A's endpoint provides, B is blocked by A.
- If CONTRACT-B extends a type that CONTRACT-A defines, B is blocked by A.
- Dependencies reference CONTRACT-### IDs within this document only.

---

## Step 6 — Write the output file

Path: `docs/specflow/contracts/<feature-slug>.md` (same slug as the EARS doc).

**Full document format:**

```markdown
# Prompt Contracts: [Feature Name]

**Source EARS:** docs/specflow/ears/<slug>.md
**Date:** [YYYY-MM-DD]
**Status:** Draft — pending plan integration

---

## CONTRACT-001: [Task Title]

### GOAL
[One sentence. Binary pass/fail.]

### CONSTRAINTS
- [Project constraint from config]
- [Task-specific constraint]

**Scope Discipline** (from .specflow/config.md — applies to every contract):
- SCOPE-001: Fix findings inline if < 30 min and files are in the PR diff.
- SCOPE-002: Target zero new issues per PR. Justify any exception in the PR description.
- SCOPE-003: Before creating any issue, search existing issues
            (`gh issue list --search "<keywords>" --state open`).
- SCOPE-004: Style preferences are SKIP, not DEFER. Do not track them.
- SCOPE-005: Spec gaps route through the specflow pipeline, not standalone issues.
- SCOPE-006: Vendor docs override contract FORMAT when they conflict; flag in PR.

Covers: REQ-001, REQ-002

### FORMAT
- File: [exact path]
- Exported symbol: [name and signature]
- Test file: [exact path]
- Binding site: [where the artifact gets registered, if separate from the artifact file]

### FAILURE CONDITIONS
- [ ] [Failure — maps to REQ-001]
- [ ] [Failure — maps to REQ-002]
- [ ] Test coverage below [threshold]% (project config)

### Effort: [XS / S / M / L]

### Dependencies
- Blocked by: [CONTRACT-### or "none"]
- Blocks: [CONTRACT-### or "none"]

---

## CONTRACT-002: [Task Title]
[... same structure ...]

---

## Skipped Requirements

[List any ⚠ AMBIGUOUS requirements that were not contracted:]
- REQ-00N: "[original ambiguous text]" — resolve before contracting

[Or: "None — all requirements contracted."]

---

## Summary
- Contracts written: N
- Requirements covered: M of T
- Requirements skipped (ambiguous): K
- Effort distribution: XS(a) S(b) M(c) L(d)
- Next step: Run `/specflow-plan docs/specflow/contracts/<slug>.md`
```

---

## Step 7 — Report to user

After writing the file:

```
Contract writing complete.
Output: docs/specflow/contracts/<slug>.md

Contracts: N written
Requirements covered: M of T
Skipped (ambiguous): K

[If K > 0]:
⚠ K requirements were skipped due to unresolved ambiguities.
Resolve them in the EARS doc, then re-run /specflow-contract.

[If K = 0]:
✓ All requirements contracted.
Next: /specflow-plan docs/specflow/contracts/<slug>.md
```

---

## Quality checklist

- [ ] Every CONTRACT-### has all 4 sections (GOAL, CONSTRAINTS, FORMAT, FAILURE CONDITIONS).
- [ ] Every GOAL is one sentence, binary pass/fail.
- [ ] Every FAILURE CONDITION references a REQ-### ID.
- [ ] Every contract has at least 2 failure conditions.
- [ ] Every contract has a coverage failure condition.
- [ ] Every contract has a `Covers: REQ-...` line in CONSTRAINTS.
- [ ] Every contract's CONSTRAINTS includes the verbatim Scope Discipline subsection.
- [ ] FORMAT names binding sites for any artifact that requires registration to be reachable.
- [ ] No ambiguous requirements were contracted.
- [ ] No contract exceeds L effort.
- [ ] Dependencies reference valid CONTRACT-### IDs.
- [ ] No circular dependencies exist.
- [ ] Project constraints from config are injected where applicable.
- [ ] No spec-gap found during contracting was filed as a standalone GitHub issue (SCOPE-005 — if a gap is discovered, pause and route it back through `/specflow-specify`).
