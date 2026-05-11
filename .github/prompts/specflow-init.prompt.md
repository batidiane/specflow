---
mode: agent
description: "Generate or update .specflow/config.md by analyzing the project's CLAUDE.md, repo structure, and GitHub metadata. Creates artifact directories if needed."
tools: ['codebase', 'editFiles', 'fetch', 'githubRepo']
---

# /specflow-init

Generate or update `.specflow/config.md` by introspecting the workspace.

**Input:** `${input:mode:Leave empty to auto-detect, or pass 'force' to overwrite existing config}`

## Preconditions

1. Verify `gh` CLI is authenticated (`gh auth status`). If not, STOP and tell the user to run `gh auth login`.
2. If `.specflow/config.md` already exists and the input is not `force`, ask before overwriting: *"`.specflow/config.md` already exists. Update it (preserve owner sections), regenerate from scratch, or cancel?"*

## Procedure

**Canonical procedure: `#file:skills/project-initializer/SKILL.md`.** Read it and follow it exactly. The skill walks through repo introspection, CLAUDE.md parsing, GitHub Project discovery (`gh project list`, `gh api`), Epic Definitions, Domain Labels, Kanban Columns, and SCOPE-001..006 generation.

Translate Claude tool references per `#file:AGENTS.md` (§ Tool surface translation). `Bash` calls become terminal tool calls; `Read`/`Write` become `#codebase` / `#editFiles`.

## Post-conditions

- `.specflow/config.md` written or updated.
- Empty artifact directories created if missing: `docs/specflow/ears/`, `docs/specflow/contracts/`, `docs/specflow/plans/`, `docs/specflow/published/`. Each gets a `.gitkeep`.
- Report what was created vs. updated; print the next-step command.

## Reference

- Canonical procedure: `skills/project-initializer/SKILL.md`.
- Repo-wide rules: `AGENTS.md`.
