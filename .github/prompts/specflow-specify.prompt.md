---
agent: agent
description: "Transform a feature description or spec section into EARS requirements. Writes output to docs/specflow/ears/"
tools: ['search/codebase', 'edit/editFiles']
---

# /specflow-specify

Transform a free-form feature description or spec section into unambiguous EARS requirements.

**Input:** `${input:feature:Feature description or spec file path (e.g. 'WHO-5 wellbeing check-in' or 'docs/spec.md §3.4')}`

## Preconditions

1. Check `.specflow/config.md` via `#search/codebase`. If present, read it and announce *"Loaded [project name] config"*. If missing, warn: *"⚠ No `.specflow/config.md` found. Output will lack project-specific constraints. Run `/specflow-init` first."* Continue anyway.
2. If the input is empty, ask: *"What feature or spec section should I formalize into EARS requirements? Provide a description or a file path."*

## Procedure

**Canonical procedure: `#file:skills/ears-engineer/SKILL.md`.** Read it and follow it exactly. Use the input as the feature source; write the output to `docs/specflow/ears/<feature-slug>.md`.

Translate Claude tool references in the skill body to Copilot equivalents per the table in `#file:AGENTS.md` (§ Tool surface translation).

## Prime directive

You NEVER invent requirements. You only formalize what is explicitly stated in the input. If something is implied but not stated, flag it as ambiguous rather than assume. When in doubt: flag, don't guess.

## Reference

- Canonical procedure: `skills/ears-engineer/SKILL.md`.
- Repo-wide rules: `AGENTS.md`.
