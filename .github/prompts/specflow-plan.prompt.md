---
mode: agent
description: "Organize Prompt Contracts into a Vision→Epic→Feature→Task hierarchy with dependencies. Writes output to docs/specflow/plans/"
tools: ['codebase', 'editFiles']
---

# /specflow-plan

Organize Prompt Contracts into a Vision → Epic → Feature → Task GitHub hierarchy with a verified dependency graph.

**Input:** `${input:contracts:Contract document path or glob (e.g. 'docs/specflow/contracts/who-5*.md' or 'docs/specflow/contracts/')}`

## Preconditions

1. Check `.specflow/config.md`.
   - **Exists** — read it; announce *"Loaded [project name] config"*.
   - **Missing** — STOP. *"⚠ No `.specflow/config.md` found. Cannot plan without Epic Definitions. Run `/specflow-init` to generate config from your project."*
2. If the input is empty, list contract documents in `docs/specflow/contracts/` (excluding `.gitkeep`) and ask which to include — or offer "all". If no files exist, tell the user to run `/specflow-contract` first.
3. If the input is a directory path, read every `.md` in it (excluding `.gitkeep`). If it is a glob pattern, resolve and read all matches.

## Prime directive

Never invent Features or Tasks. Every Task maps to exactly one CONTRACT-###. Every Feature groups related contracts. Every Epic comes from the config's `## Epic Definitions`. If a contract does not fit any defined Epic, list it in **Unassigned Contracts** — never create a new Epic on the fly.

## Procedure

1. **Read inputs.** All contract documents the user pointed to. `.specflow/config.md` for Epic Definitions, Domain Labels, Kanban Columns, Out of Scope, Project Identity (owner, repo, project-number).
2. **Map contracts to Epics.** For each CONTRACT-###, match it to one Epic from the config based on domain (API / UI / CORE / etc.) and feature area. When ambiguous, prefer the earlier Epic (foundations first). Anything that does not fit → Unassigned Contracts.
3. **Group contracts into Features within each Epic.** A Feature has 2–8 Tasks (contracts). Fewer than 2 → merge up. More than 8 → split. Feature names use domain labels: `[UI] Wellbeing Assessment Flow`. Each contract maps to exactly one Feature (no sharing). Each Feature has a spec reference, a 2–3-sentence description, an ordered task list, and acceptance criteria derived from the contracts' GOALs.
4. **Resolve dependencies.** Collect every `Dependencies` section. Resolve CONTRACT-### cross-references across documents. Check for circular dependencies → **HALT if found**. Check for cross-Epic forward references (Epic N task blocked by Epic N+1 task) → **HALT if found**. Identify the critical path (longest dependency chain).
5. **Produce the plan document** at `docs/specflow/plans/<plan-slug>.md` with four sections matching the GitHub hierarchy:
   - **Vision** — project name and roadmap overview; list every Epic with its one-line scope; include `Out of Scope` items from config.
   - **Epic sections** (in config order) — scope, Feature list with domain labels, entry criteria, exit criteria, total effort estimate.
   - **Feature sections** — spec reference, description, ordered task list, acceptance criteria.
   - **Task sections** — full Prompt Contract copied from the contracts doc, resolved dependencies, effort estimate.
6. **Verification protocol** — run every check before writing the file:

   **Coverage checks**
   - Every CONTRACT-### maps to exactly one Feature and one Epic.
   - No contract is orphaned (unmapped).
   - No contract appears in multiple Features.

   **Dependency checks**
   - No circular dependencies.
   - No cross-Epic forward references.
   - Every `blocked-by` reference resolves to an existing CONTRACT-###.
   - Critical path identified.

   **Completeness checks**
   - Every contract has all 4 Prompt Contract sections.
   - Every Feature has at least 2 Tasks.
   - Every Epic has at least 1 Feature.

   **Scope checks**
   - No contract targets items in config's `## Out of Scope`.
   - No contract invents requirements not present in the EARS documents.

   **If ANY check fails:** list violations, do NOT write the plan file, tell the user what to fix.

   **If ALL checks pass:** write the plan file, report verification results.

7. **Report.** Print: epics, features, tasks, total effort distribution, critical path (e.g., `CONTRACT-001 → CONTRACT-003 → CONTRACT-007 (3 tasks)`), verification result (`ALL CHECKS PASSED ✓`), next step.

## Quality checklist

- Every contract maps to exactly one Feature and one Epic.
- No circular dependencies; no cross-Epic forward references.
- Critical path identified.
- Every Feature has a spec reference and acceptance criteria derived from contract GOALs.
- Epic ordering matches config's Epic Definitions order.
- `Out of Scope` items from config are listed in the Vision section.
- Plan slug is descriptive, lowercase, hyphenated.

## Reference

Deep procedure (hierarchy template, effort scale, verification checklist): `.github/instructions/specflow-roadmap-planner.instructions.md`.
