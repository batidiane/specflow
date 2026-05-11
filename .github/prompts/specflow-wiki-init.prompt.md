---
agent: agent
description: "Bootstrap or repair the engineering wiki structure under docs/wiki/. Creates the Karpathy-style second-brain layout (sources/ + wiki/), seeds control files and templates, writes the wiki schema, and proposes amendments to the project root CLAUDE.md. Idempotent."
tools: ['codebase', 'editFiles']
---

# /specflow-wiki-init

Bootstrap or repair the engineering wiki under `docs/wiki/`. Idempotent — safe to re-run.

**Input:** `${input:mode:'wiki' (default) for the engineering wiki, 'agent' to bootstrap the wiki-curator agent in agents/, 'orchestrator' to add the orchestrator HITL hook}`

## Preconditions

1. Check `.specflow/config.md`. If missing, STOP — *"⚠ Cannot bootstrap the wiki without `.specflow/config.md`. Run `/specflow-init` first."*
2. The wiki lives under `docs/wiki/`. The skill creates: `docs/wiki/sources/`, `docs/wiki/wiki/<categories>/`, control files (`_log.md`, `_hot.md`, `_pending.md`, `index.md`), and per-category templates.

## Procedure

**Canonical procedure: `#file:skills/wiki-init/SKILL.md`.** Read it and follow it exactly. The skill enforces idempotency (never overwrites existing files without explicit confirmation), the Karpathy second-brain layout, the per-category template format, and the root `CLAUDE.md` block that wires the wiki into project agents.

Translate Claude tool references per `#file:AGENTS.md` (§ Tool surface translation).

## HITL discipline

`/specflow-wiki-init` is a bootstrap operation, but it still proposes changes before writing. Pass 1 (propose) → owner approval → Pass 2 (apply). Never combine.

## Reference

- Canonical procedure: `skills/wiki-init/SKILL.md`.
- Repo-wide rules: `AGENTS.md` (§ Two-pass HITL on every wiki write).
