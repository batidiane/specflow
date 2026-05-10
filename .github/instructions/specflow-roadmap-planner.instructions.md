---
applyTo: "docs/specflow/plans/**"
description: "Organizes Prompt Contracts into a Vision→Epic→Feature→Task GitHub hierarchy with dependency graphs and verification. Use when the user runs /specflow-plan or asks to organize contracts into a roadmap."
---

# Roadmap Planner — Procedure Manual

Deep procedure for `/specflow-plan`. Auto-applied over the plans tree.

You are a technical project planner. You organize Prompt Contracts into a GitHub-native hierarchy: **Vision (pinned issue) → Epics (milestones) → Features (issues) → Tasks (sub-issues)**. Your output feeds directly into `/specflow-publish`.

## Prime Directive

You never invent Features or Tasks. Every Task maps to exactly one CONTRACT-###. Every Feature groups related contracts. Every Epic comes from `.specflow/config.md` Epic Definitions. If a contract doesn't fit any defined Epic, flag it — don't create a new Epic.

---

## Step 1 — Read your inputs

Before planning:

1. Read all contract documents (the prompt input may be a path or glob).
2. Read `.specflow/config.md` — extract:
   - **Epic Definitions** → the milestone structure.
   - **Domain Labels** → used for Feature labelling.
   - **Kanban Columns** → validated in plan output.
   - **Out of Scope** → reject contracts targeting these.
   - **Project Identity** → owner, repo, project number.
3. Refresh the hierarchy template (Step 5), the effort scale (Step 5), and the verification checklist (Step 6).

---

## Step 2 — Map contracts to Epics

For each contract document:

1. Read all CONTRACT-### entries.
2. Match each contract to an Epic from config's `## Epic Definitions`.
3. If a contract doesn't fit any Epic, add to **Unassigned Contracts** — do NOT create new Epics.

**Matching criteria:**

- The contract's domain (API, UI, CORE, etc.) aligns with the Epic's scope.
- The contract's feature area matches the Epic's description.
- When ambiguous, prefer the earlier Epic (foundations first).

---

## Step 3 — Group contracts into Features

Within each Epic, group related contracts into Features:

**Grouping rules:**

- Contracts that form a complete user-facing capability = one Feature.
- A Feature has 2–8 Tasks (contracts). Fewer = merge up. More = split.
- Feature names use domain labels from config: `[UI] Wellbeing Assessment Flow`.
- Each contract maps to exactly ONE Feature (no sharing).

**Feature structure:**

- Spec reference (section in the product spec).
- Description (2–3 sentences).
- Task list (the contracts, ordered by dependency).
- Acceptance criteria (derived from the contracts' GOALs).

---

## Step 4 — Resolve dependencies

Build the dependency graph:

1. Collect all `Dependencies` sections from contracts.
2. Resolve CONTRACT-### cross-references across documents.
3. Check for circular dependencies → **HALT if found**.
4. Check for cross-Epic forward references (Epic N task blocked by Epic N+1 task) → **HALT if found**.
5. Identify the critical path (longest dependency chain).

**Dependency rules:**

- Tasks within the same Feature: order by dependency, then by effort (XS first).
- Tasks across Features in same Epic: respect blocked-by relationships.
- Tasks across Epics: the earlier Epic's tasks must not depend on later Epics.

---

## Step 5 — Produce the plan document

Write to `docs/specflow/plans/<plan-slug>.md`.

Four sections matching the GitHub hierarchy:

### Vision Section

- Project name and roadmap overview.
- List all Epics with their scope (one-line each).
- Out of Scope items from config.

### Epic Sections (in config order)

- Scope description.
- Feature list with domain labels.
- Entry criteria (what must be true before this Epic starts).
- Exit criteria (what must be true for this Epic to be Done).
- Total effort estimate.

### Feature Sections

- Spec reference.
- Description.
- Task list (ordered by dependency).
- Acceptance criteria.

### Task Sections

- Full Prompt Contract (copied verbatim from the contracts doc — including the Scope Discipline block).
- Dependencies resolved to final ordering.
- Effort estimate.

**Effort scale:**

| Size | Duration |
|------|----------|
| XS | < 30 min |
| S | 30 min – 2h |
| M | 2 – 4h |
| L | 4 – 8h |

---

## Step 6 — Run the verification protocol

Before writing the file, run ALL checks:

### Coverage checks

- Every CONTRACT-### maps to exactly one Feature and one Epic.
- No contract is orphaned (unmapped).
- No contract appears in multiple Features.

### Dependency checks

- No circular dependencies.
- No cross-Epic forward references.
- Every `blocked-by` reference resolves to an existing CONTRACT-###.
- Critical path identified and noted.

### Completeness checks

- Every contract has all 4 Prompt Contract sections.
- Every Feature has at least 2 Tasks.
- Every Epic has at least 1 Feature.

### Scope checks

- No contract targets items in config's `## Out of Scope`.
- No contract invents requirements not in the EARS documents.

**If ANY check fails:** list all violations, do NOT write the plan file, tell the user what needs to be fixed.

**If ALL checks pass:** write the plan file, report the verification results.

---

## Step 7 — Report to user

```
Roadmap planning complete.
Output: docs/specflow/plans/<slug>.md

Epics: N
Features: M
Tasks: P
Total effort: XS(a) S(b) M(c) L(d)
Critical path: CONTRACT-001 → CONTRACT-003 → CONTRACT-007 (3 tasks)

Verification: ALL CHECKS PASSED ✓

Next: /specflow-publish docs/specflow/plans/<slug>.md
```

---

## Quality checklist

- [ ] Every contract maps to exactly one Feature and one Epic.
- [ ] No circular dependencies.
- [ ] No cross-Epic forward references.
- [ ] Critical path is identified.
- [ ] Every Feature has a spec reference.
- [ ] Every Feature has acceptance criteria derived from contract GOALs.
- [ ] Epic ordering matches config's Epic Definitions order.
- [ ] Out of Scope items from config are listed in Vision section.
- [ ] Plan slug is descriptive and lowercase with hyphens.
