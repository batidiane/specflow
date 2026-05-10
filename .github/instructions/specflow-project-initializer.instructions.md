---
applyTo: "**"
description: "Generates or updates .specflow/config.md by analyzing the project's CLAUDE.md, repo structure, and GitHub metadata. Use when the user runs /specflow-init or when config is missing."
---

# Project Initializer — Procedure Manual

Deep procedure for `/specflow-init`. Generates the `.specflow/config.md` configuration file for a project by analysing existing project files and asking the user targeted questions for anything you can't infer.

## Prime Directive

Infer as much as possible from the project. Only ask questions when information is genuinely missing or ambiguous. Never invent project constraints — derive them from CLAUDE.md, existing config files, or explicit user input.

---

## Step 1 — Gather project context

Read these files in order (skip any that don't exist):

1. **CLAUDE.md** (or AGENTS.md) — project constitution, stack, rules, architecture.
2. **package.json** / **go.mod** / **Cargo.toml** / **pyproject.toml** — project name, language stack.
3. **README.md** — project description.
4. **.github/** — workflows, issue templates (hints at labels and conventions).
5. **docs/** — specification documents (scan for `*.md` files).
6. User-provided project description (if any).

Also run in the terminal:

```bash
# Get GitHub remote info
git remote get-url origin 2>/dev/null
# Get repo owner and name
gh repo view --json owner,name,projectsV2 2>/dev/null
```

---

## Step 2 — Extract what you can

From the gathered context, attempt to fill every config section:

### Project Identity

- **name** — from `package.json` `name`, `go.mod` module, or CLAUDE.md project name.
- **owner** — from git remote URL or `gh repo view`.
- **repo** — same.
- **github-project-id** — from `gh project list --owner <owner> --format json`.
- **github-project-number** — same source.

### Spec Documents

- Scan `docs/` for specification documents (`*.md` files that look like specs).
- Look for common patterns: "Product Spec", "API Design", "Architecture", "PRD".
- Each gets a label and path entry.

### Epic Definitions

- If CLAUDE.md defines phases, milestones, or sprints → use those.
- If a roadmap or project board exists → derive from there.
- Otherwise → ask the user.

### Domain Labels

- If CLAUDE.md defines domain areas (API, UI, CORE, etc.) → use those.
- If directory structure implies domains (`api/`, `mobile/`, `infra/`) → derive labels.
- Common defaults: `[API]`, `[UI]`, `[CORE]`, `[INFRA]`, `[DATA]`, `[TEST]`.

### Kanban Columns

Always use the specflow standard: `Icebox` / `To Do (Ready)` / `In Progress (Triad Active)` / `HITL Review` / `Done`.

### Project Constraints

- Extract from CLAUDE.md: testing rules, architecture rules, style rules, security rules.
- These are the NON-NEGOTIABLE rules injected into every Prompt Contract.
- Focus on rules that affect implementation: coverage thresholds, forbidden patterns, required libraries.

### Scope Discipline Constraints

- **Always emit the standard block** (SCOPE-001..006). These do not come from CLAUDE.md — they are specflow's built-in pipeline discipline rules and apply to every project.
- Do not ask the user about them. Do not omit them. Write them verbatim (see Step 4).

### Out of Scope

- If CLAUDE.md or specs define "out of scope" or "Phase 2" items → use those.
- If nothing found → leave empty, ask the user.

---

## Step 3 — Identify gaps and ask questions

For each section you couldn't fully populate, ask a targeted question. Group all questions into a single prompt — don't ask one at a time.

**Question format:**

```
I've analyzed your project and can generate most of the specflow config.
I need a few clarifications:

1. **GitHub Project:** I found project "{name}" (#{number}). Is this the one
   to use for specflow task tracking? [yes / other project name]

2. **Epic Definitions:** I didn't find phase/milestone definitions. How do you
   want to organize your work? Examples:
   - By feature area: "Auth", "Dashboard", "API"
   - By phase: "MVP", "Beta", "Launch"
   - By sprint: "Sprint 1", "Sprint 2"
   Please list your Epics with a one-line scope each.

3. **Out of Scope:** Are there features or areas that should be explicitly
   excluded from specflow planning?
```

**Rules for questions:**

- Never ask about something you already found in CLAUDE.md or project files.
- Never ask about Kanban Columns (always the standard set).
- If you have a strong inference, present it as a confirmation: *"I'll use X — correct?"*.
- Maximum 5 questions per init. If more unknowns exist, use sensible defaults and note them.

---

## Step 4 — Generate the config file

Write to `.specflow/config.md`:

```markdown
# specflow config

## Project Identity
- name: {project-name}
- owner: {github-owner}
- repo: {github-repo}
- github-project-id: {PVT_...}
- github-project-number: {integer}

## Spec Documents
- {label}: {path}
- {label}: {path}

## Epic Definitions
- {epic-name}: {one-line scope}
- {epic-name}: {one-line scope}

## Domain Labels
- [{LABEL}]: {scope description}
- [{LABEL}]: {scope description}

## Kanban Columns
- Icebox
- To Do (Ready)
- In Progress (Triad Active)
- HITL Review
- Done

## Project Constraints
- {constraint from CLAUDE.md or user input}
- {constraint from CLAUDE.md or user input}

## Scope Discipline Constraints
SCOPE-001: Fix findings inline if < 30 min and files are in the PR diff.
SCOPE-002: Target zero new issues per PR. Justify any exception in the PR description.
SCOPE-003: Before creating any issue, search existing issues first
           (`gh issue list --search "<keywords>" --state open`). Duplicate issues are a defect.
SCOPE-004: Style preferences (switch vs map, naming nits in untouched files) are SKIP,
           not DEFER. Do not track them as follow-ups.
SCOPE-005: Spec gaps route through the specflow pipeline
           (`/specflow-specify` → `/specflow-contract` → `/specflow-plan` → `/specflow-publish`),
           not standalone GitHub issues.
SCOPE-006: When vendor docs conflict with contract FORMAT, follow vendor docs.
           Flag the deviation in the PR description.

## Out of Scope
- {item}
- {item}
```

---

## Step 5 — Create artifact directories

Create the specflow artifact directories if they don't exist:

```
docs/specflow/ears/.gitkeep
docs/specflow/contracts/.gitkeep
docs/specflow/plans/.gitkeep
docs/specflow/published/.gitkeep
```

Only create directories that don't already exist. Don't overwrite existing `.gitkeep` files or any existing artifacts.

---

## Step 6 — Update mode (config already exists)

If `.specflow/config.md` already exists:

1. Read the existing config.
2. Read current project state (CLAUDE.md, repo structure, GitHub metadata).
3. Compare: identify sections that are outdated or missing new information.
4. **Check for Scope Discipline block** — if `## Scope Discipline Constraints` is missing from the existing config, flag it as a REQUIRED update (not optional). The full SCOPE-001..006 block must be added — these are specflow pipeline rules, not project-specific preferences.
5. Present a diff-style summary:

   ```
   ## specflow config update

   ### No changes needed
   - Project Identity ✓
   - Kanban Columns ✓

   ### Updates found
   - Spec Documents: found new file docs/CocoMind Migration Strategy.md — add?
   - Project Constraints: CLAUDE.md added "All HTTP requests must have timeouts" — add?
   - Epic Definitions: no changes

   ### Required updates (specflow pipeline rules)
   - Scope Discipline Constraints: SECTION MISSING — will add SCOPE-001..006 block

   ### Missing (still need input)
   - github-project-id: still not set — discover now? [yes/no]

   Apply these updates? [yes / selective / no]
   ```

6. On `yes`: apply all updates.
7. On `selective`: ask which updates to apply.
8. On `no`: abort.

---

## Step 7 — Report to user

```
specflow config {created / updated}.
Output: .specflow/config.md

Sections populated:
✓ Project Identity: {owner}/{repo}
✓ Spec Documents: {N} documents linked
✓ Epic Definitions: {M} epics defined
✓ Domain Labels: {P} labels
✓ Kanban Columns: standard (5 columns)
✓ Project Constraints: {Q} constraints
✓ Scope Discipline Constraints: SCOPE-001..006 (specflow pipeline rules)
✓ Out of Scope: {R} items

[If artifact directories were created]:
✓ Created docs/specflow/ artifact directories

Recommended (manual — CLAUDE.md is yours to own):
Mirror the Scope Discipline rules into CLAUDE.md §Development Rules so every
agent reads them on every task. Suggested block:

  ### Scope Discipline
  - Fix inline, don't defer: < 30 min + files in PR diff → fix now, no follow-up issue.
  - Zero new issues per PR is the target. Justify any exception.
  - Search before creating: `gh issue list --search "<keywords>" --state open` first.
  - Style preferences are SKIP, not DEFER. Do not track them.
  - Don't touch what you didn't break — findings outside the PR diff are out of scope.
  - Spec gaps use the specflow pipeline, not standalone GitHub issues.
  - Vendor best practices override contract FORMAT when they conflict; flag in PR.

Next: /specflow-specify [feature description]
```
