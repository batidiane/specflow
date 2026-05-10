---
mode: agent
description: "Generate or update .specflow/config.md by analyzing the project's CLAUDE.md, repo structure, and GitHub metadata. Creates artifact directories if needed."
tools: ['codebase', 'editFiles', 'fetch', 'githubRepo']
---

# /specflow-init

Generate or update `.specflow/config.md` for the current workspace. Optional argument: a short project description (e.g., *"A meditation app for the Spanish market"*).

**Input:** `${input:projectDescription:Optional project description}`

## Mode detection

Decide the mode by looking at the workspace via `#codebase`:

- **Create mode** — if `.specflow/config.md` does NOT exist. Announce: *"No specflow config found. Analyzing your project to generate one..."*
- **Update mode** — if `.specflow/config.md` already exists. Read it, then announce: *"Found existing specflow config. Checking for updates..."*

If the user supplied a project description, fold it in as additional context for the config sections you cannot infer from files alone (especially **Epic Definitions** and **Out of Scope**).

## Procedure

Follow the procedure in `.github/instructions/specflow-project-initializer.instructions.md` end-to-end.

### Gather context

Read in order via `#codebase` (skip what does not exist):

1. `CLAUDE.md` (or `AGENTS.md`) — project constitution, stack, rules, architecture.
2. `package.json` / `go.mod` / `Cargo.toml` / `pyproject.toml` — name, language stack.
3. `README.md` — project description.
4. `.github/` — workflows, issue templates (hints at labels and conventions).
5. `docs/` — scan for `*.md` files that look like specification documents.

For GitHub identity, use `#githubRepo` (or terminal `git remote get-url origin` and `gh repo view --json owner,name,projectsV2`).

### Extract what you can, then ask

Attempt to fill every config section from the gathered context. Then group all remaining unknowns into a **single** prompt (never one question at a time). Maximum 5 questions per init; beyond that, use sensible defaults and note them.

Never ask about:
- Kanban Columns (always the specflow standard set).
- Anything you already found in `CLAUDE.md` or project files (confirm instead, do not re-ask).
- Scope Discipline Constraints — these are specflow's built-in pipeline rules, emitted verbatim every time.

### Emit the config

Write `.specflow/config.md` with these sections in order:

- `## Project Identity` — name, owner, repo, github-project-id, github-project-number.
- `## Spec Documents` — labelled paths to specification documents.
- `## Epic Definitions` — milestone structure with one-line scopes.
- `## Domain Labels` — `[API]`, `[UI]`, `[CORE]`, etc., with descriptions.
- `## Kanban Columns` — always: Icebox / To Do (Ready) / In Progress (Triad Active) / HITL Review / Done.
- `## Project Constraints` — non-negotiable rules extracted from CLAUDE.md.
- `## Scope Discipline Constraints` — verbatim SCOPE-001..006 block. See the instructions file for exact wording.
- `## Out of Scope` — items explicitly excluded.

### Create artifact directories

Create only the ones missing — never overwrite existing `.gitkeep` files or artifacts:

```
docs/specflow/ears/.gitkeep
docs/specflow/contracts/.gitkeep
docs/specflow/plans/.gitkeep
docs/specflow/published/.gitkeep
```

### Update mode discipline

If the config already exists, read it and present a diff-style summary before writing anything:

- **No changes needed** — list sections that are already current.
- **Updates found** — list optional updates with `add?` next to each.
- **Required updates (specflow pipeline rules)** — if `## Scope Discipline Constraints` is missing, flag it as a required update (not optional) and emit the SCOPE-001..006 block when applied.
- **Missing (still need input)** — list residual unknowns.

Ask: *"Apply these updates? [yes / selective / no]"*. On `selective`, ask which subset to apply.

### Report

After writing, print which sections were populated, whether artifact directories were created, and the suggested manual `CLAUDE.md §Scope Discipline` block to mirror (see the instructions file). End with: *"Next: /specflow-specify [feature description]"*.

## Reference

Deep procedure: `.github/instructions/specflow-project-initializer.instructions.md`.
