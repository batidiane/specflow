---
name: github-publisher
description: Creates the full GitHub issue hierarchy (milestones, issues, sub-issues, project items) from a specflow plan document. NEVER automatic — always requires explicit human confirmation. Use when the user runs /specflow:publish.
---

# GitHub Publisher

You execute GitHub operations to create the issue hierarchy from a plan document.
You are the ONLY specflow skill that modifies external state (GitHub). Every operation
requires explicit human confirmation before execution.

## Prime Directive

NEVER execute GitHub operations without showing a full preview first. NEVER auto-chain
from another command. The user must explicitly invoke `/specflow:publish` and confirm
the preview before any `gh` command runs.

---

## Step 1: Read Your Inputs

1. Read the plan document (from $ARGUMENTS)
2. Read `.specflow/config.md` — extract:
   - **owner** and **repo** → for all `gh` commands
   - **github-project-number** → for project item operations
   - **github-project-id** → for project field mutations
   - **Domain Labels** → for issue labels
   - **Kanban Columns** → for project column assignments
3. Read `references/gh-cli-patterns.md` for exact command syntax
4. Read `references/kanban-columns.md` for column field IDs

---

## Step 2: Parse the Plan Document

Extract from the plan:

**Epics** (from `## Epic:` sections):
- Name, scope description, entry/exit criteria

**Features** (from `## Feature:` sections):
- Title with domain label, epic assignment, description, acceptance criteria

**Tasks** (from `## Task: CONTRACT-###` sections):
- Title, full prompt contract body, effort, dependencies, domain labels

Build the creation order:
1. Milestones (Epics) — must exist before issues reference them
2. Feature issues — must exist before sub-issues link to them
3. Task sub-issues — link to parent feature
4. Project items — add all to GitHub Project, set column to Icebox

---

## Step 3: Check for Existing Items (Idempotency)

Before creating anything, check what already exists:

```bash
# Check existing milestones
gh api repos/{owner}/{repo}/milestones --jq '.[].title'

# Check existing issues with specflow labels
gh issue list --repo {owner}/{repo} --label "specflow" --state all --limit 500 --json number,title
```

For each planned item:
- If a milestone with the same title exists → SKIP (note in preview)
- If an issue with the same title exists → SKIP (note in preview)
- Only create items that don't already exist

---

## Step 4: Generate Preview

Print the FULL preview before executing anything:

```
## specflow:publish Preview

Repository: {owner}/{repo}
Project: #{project-number}
Source: {plan-doc-path}

### Milestones to Create (Epics)
  [NEW] "S2: Home Screen & Wellbeing" — 2 features, 8 tasks
  [SKIP] "S1: Auth & Core Infrastructure" — already exists

### Issues to Create (Features)
  [NEW] "[CORE] Wellbeing Score Feature" → milestone "S2: Home & Wellbeing"
        Labels: core, specflow
  [NEW] "[UI] WHO-5 Assessment Flow" → milestone "S2: Home & Wellbeing"
        Labels: ui, specflow

### Sub-issues to Create (Tasks)
  [NEW] "CONTRACT-001: Implement WHO-5 score calculator" → parent "[CORE] Wellbeing Score Feature"
        Labels: core, specflow, XS
  [NEW] "CONTRACT-002: Create wellbeing Zustand store" → parent "[CORE] Wellbeing Score Feature"
        Labels: core, specflow, S
  ...

### Project Items
  All new issues added to Project #{project-number}, column: Icebox

### Summary
  Create: N milestones, M issues, P sub-issues
  Skip: X items (already exist)
  Total gh commands: Y

Proceed? [yes / milestones-only / no]
```

**STOP HERE. Wait for user response.**

- `yes` → execute all commands
- `milestones-only` → create only milestones, skip issues and sub-issues
- `no` → abort, write no receipt

---

## Step 5: Execute in Dependency Order

On `yes` or `milestones-only`:

### Phase 1: Create Milestones
```bash
gh api repos/{owner}/{repo}/milestones \
  --method POST \
  -f title="{epic-name}" \
  -f description="{epic-scope}"
```
Capture milestone number for each.

### Phase 2: Create Feature Issues (skip if milestones-only)
```bash
gh issue create --repo {owner}/{repo} \
  --title "{feature-title}" \
  --milestone "{epic-name}" \
  --label "{domain-label},specflow" \
  --body "{feature-body}"
```
Capture issue number for each.

### Phase 3: Create Task Sub-issues (skip if milestones-only)
```bash
gh issue create --repo {owner}/{repo} \
  --title "CONTRACT-{NNN}: {task-title}" \
  --label "{domain-label},specflow,{effort}" \
  --body "{full-prompt-contract-body}"
```
Then link to parent:
```bash
gh issue edit {parent-issue-number} --add-sub-issue {child-issue-number} --repo {owner}/{repo}
```

### Phase 4: Add to Project (skip if milestones-only)
```bash
gh project item-add {project-number} --owner {owner} --url {issue-url}
```

**Error handling:**
- If any `gh` command fails, log the error and continue with remaining items
- The receipt file records both successes and failures
- On partial failure, the receipt marks which items were created and which failed

---

## Step 6: Write Receipt File

ALWAYS write a receipt, even on partial failure or abort:

Write to `docs/specflow/published/<plan-slug>-receipt.md`:

```markdown
# Publish Receipt: [Plan Name]

**Source plan:** docs/specflow/plans/<slug>.md
**Date:** [YYYY-MM-DD]
**Status:** [Complete / Partial / Aborted]
**Mode:** [full / milestones-only / aborted]

---

## Milestones Created
| Epic | Milestone # | Status |
|------|------------|--------|
| S2: Home & Wellbeing | #3 | Created |
| S1: Auth & Core | — | Skipped (exists) |

## Issues Created
| Feature | Issue # | Milestone | Status |
|---------|---------|-----------|--------|
| [CORE] Wellbeing Score | #47 | S2 | Created |
| [UI] WHO-5 Assessment | #48 | S2 | Created |

## Sub-issues Created
| Contract | Issue # | Parent # | Status |
|----------|---------|----------|--------|
| CONTRACT-001 | #49 | #47 | Created |
| CONTRACT-002 | #50 | #47 | Created |
| CONTRACT-003 | #51 | #48 | Created |

## Contract → Issue Mapping
| Contract ID | GitHub Issue | Title |
|-------------|-------------|-------|
| CONTRACT-001 | #49 | Implement WHO-5 score calculator |
| CONTRACT-002 | #50 | Create wellbeing Zustand store |
| CONTRACT-003 | #51 | Build WHO-5 assessment screen |

## Errors
[None — or list of failed commands with error messages]
```

---

## Step 7: Report to User

```
Publishing complete.
Receipt: docs/specflow/published/<slug>-receipt.md

Created: N milestones, M issues, P sub-issues
Skipped: X items (already existed)
Failed: Y items (see receipt for details)

[If Y > 0]:
⚠ Some items failed to create. Review the receipt and re-run /specflow:publish
to retry. Existing items will be skipped (idempotent).

[If Y = 0]:
✓ All items published successfully.
Next: /specflow:status all
```

---

## Safety Rules

1. **NEVER execute without preview confirmation** — this is the cardinal rule
2. **NEVER force-create** — if an item exists, skip it
3. **ALWAYS write the receipt** — even on abort or partial failure
4. **NEVER delete existing issues** — only create new ones
5. **NEVER modify existing issues** — only add sub-issues to them
6. **All issues get the `specflow` label** — for filtering and idempotency checks
7. **Effort labels** — add effort size (XS, S, M, L) as a label to task issues
