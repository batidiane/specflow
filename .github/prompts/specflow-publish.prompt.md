---
agent: agent
description: "Create GitHub milestones, issues, and sub-issues from a specflow plan. Requires explicit confirmation before any GitHub operations."
tools: ['search/codebase', 'edit/editFiles', 'web/githubRepo']
---

# /specflow-publish

Publish a specflow plan to GitHub: create milestones, issues, sub-issues, and project items in dependency order, with a mandatory confirmation gate.

**Input:** `${input:planDoc:Plan document path (e.g. 'docs/specflow/plans/who-5-wellbeing.md')}`

## Preconditions

1. Check `.specflow/config.md`. If missing, STOP — *"⚠ Cannot publish without `.specflow/config.md`. The publisher needs owner, repo, and project-number. Run `/specflow-init` first."*
2. Verify `gh` CLI is authenticated (`gh auth status`). If not, STOP and tell the user to run `gh auth login`.
3. If the input is empty, look under `docs/specflow/plans/`: one file (besides `.gitkeep`) → use it; multiple → list and ask; none → tell the user to run `/specflow-plan` first.

## CRITICAL safety rules (non-negotiable)

1. **NEVER execute without preview confirmation.** Show every `gh` command first; wait for explicit `yes`.
2. **NEVER force-create.** If an item already exists, SKIP it. Re-running must be safe (idempotent).
3. **ALWAYS write the receipt** — even on abort, failure, or partial publish.
4. **NEVER delete or modify existing issues.** Only `addSubIssue` against existing parents.
5. **All created issues get the `specflow` label** (for filter and idempotency). Task issues additionally get an effort label (XS/S/M/L).

## Procedure

**Canonical procedure: `#file:skills/github-publisher/SKILL.md`.** Read it and follow it exactly. The skill defines: input parsing, Check A (exact-title + label) + Check B (SCOPE-003 keyword search) duplicate detection, the decision matrix, preview format, `addSubIssue` GraphQL mutation (do NOT use `gh issue edit --add-sub-issue` — unreliable), execute-only-on-explicit-yes gate, partial-failure receipt protocol, and receipt format.

Translate Claude tool references per `#file:AGENTS.md` (§ Tool surface translation). `Bash` invocations are real `gh` commands; the rest become `#search/codebase` / `#edit/editFiles`.

## HITL gate (mandatory)

Preview ends with: *"Proceed? [yes / milestones-only / preview-only / no]"*.
- **yes** → execute every command in order.
- **milestones-only** → create only milestones; skip features, tasks, and project items.
- **preview-only** → write preview to `docs/specflow/published/<slug>-preview.md` and exit.
- **no** → abort cleanly; write no receipt.

**STOP HERE and wait** until the user answers one of the four. Never proceed on an ambiguous response.

## Reference

- Canonical procedure: `skills/github-publisher/SKILL.md`.
- gh patterns and column field IDs: `skills/github-publisher/references/`.
- Repo-wide rules: `AGENTS.md`.
