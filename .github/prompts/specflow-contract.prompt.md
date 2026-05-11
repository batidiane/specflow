---
mode: agent
description: "Transform EARS requirements into atomic Prompt Contracts. Writes output to docs/specflow/contracts/"
tools: ['codebase', 'editFiles']
---

# /specflow-contract

Group EARS requirements into atomic tasks and write a Prompt Contract for each (GOAL / CONSTRAINTS / FORMAT / FAILURE CONDITIONS).

**Input:** `${input:earsDoc:EARS document path or glob (e.g. 'docs/specflow/ears/who-5*.md' or 'docs/specflow/ears/')}`

## Preconditions

1. Check `.specflow/config.md`. If missing, STOP — *"⚠ Cannot write contracts without `.specflow/config.md`. The contract writer needs Domain Labels, Epic Definitions, and SCOPE-001..006. Run `/specflow-init` first."*
2. If the input is empty, list `.md` files under `docs/specflow/ears/` (skip `.gitkeep`) and ask which to use, or offer to include all.

## Procedure

**Canonical procedure: `#file:skills/contract-writer/SKILL.md`.** Read it and follow it exactly. The skill defines the four-section Prompt Contract template, the atomicity heuristics for grouping REQs into CONTRACTs, the FORMAT-must-name-binding-sites rule, and the SCOPE-001..006 cascade.

Translate Claude tool references per `#file:AGENTS.md` (§ Tool surface translation).

## Reference

- Canonical procedure: `skills/contract-writer/SKILL.md`.
- Contract template: `skills/contract-writer/references/contract-template.md`.
- Repo-wide rules: `AGENTS.md`.
