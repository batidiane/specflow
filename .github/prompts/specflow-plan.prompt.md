---
agent: agent
description: "Organize Prompt Contracts into a Vision→Epic→Feature→Task hierarchy with dependencies. Writes output to docs/specflow/plans/"
tools: ['search/codebase', 'edit/editFiles']
---

# /specflow-plan

Organize Prompt Contracts into a Vision → Epic → Feature → Task plan with dependency graph and verification.

**Input:** `${input:contractInput:Contract document path, directory, or glob (e.g. 'docs/specflow/contracts/who-5*.md' or 'docs/specflow/contracts/')}`

## Preconditions

1. Check `.specflow/config.md`. If missing, STOP — *"⚠ Cannot plan without `.specflow/config.md`. The planner needs Epic Definitions and Domain Labels. Run `/specflow-init` first."*
2. If the input is empty, list `.md` files under `docs/specflow/contracts/` (skip `.gitkeep`) and ask which to include, or offer to include all.
3. If the input is a directory, read every `.md` file in it (skip `.gitkeep`). If it is a glob, resolve and read all matches.

## Procedure

**Canonical procedure: `#file:skills/roadmap-planner/SKILL.md`.** Read it and follow it exactly. The skill defines the Vision → Epic → Feature → Task hierarchy, dependency graph construction, sequencing rules, and the plan document template under `docs/specflow/plans/`.

Translate Claude tool references per `#file:AGENTS.md` (§ Tool surface translation).

## Reference

- Canonical procedure: `skills/roadmap-planner/SKILL.md`.
- Repo-wide rules: `AGENTS.md`.
