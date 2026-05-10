---
mode: agent
description: "Transform EARS requirements into atomic Prompt Contracts. Writes output to docs/specflow/contracts/"
tools: ['codebase', 'editFiles']
---

# /specflow-contract

Transform an EARS requirements document into atomic Prompt Contracts.

**Input:** `${input:earsDoc:EARS document path (e.g. 'docs/specflow/ears/who-5-wellbeing-check-in.md')}`

## Preconditions

1. Check via `#codebase` whether `.specflow/config.md` exists.
   - **Exists** — read it; announce *"Loaded [project name] config"*.
   - **Missing** — warn: *"⚠ No `.specflow/config.md` found. Running without project context. Contracts will lack project-specific constraints. Run `/specflow-init` to generate config from your project."* Continue.
2. If the config exists but is missing the `## Scope Discipline Constraints` section, STOP and tell the user to run `/specflow-init` in update mode to add the SCOPE-001..006 block. A contract without scope rules is incomplete.
3. If the input is empty, look at `docs/specflow/ears/`:
   - Exactly one file (besides `.gitkeep`) → use it automatically and announce.
   - Multiple files → list them and ask which to use.
   - No files → tell the user to run `/specflow-specify` first.
4. If the input is provided but the file does not exist, tell the user.
5. Read the EARS document. If it contains any `⚠ AMBIGUOUS` entries, warn the user that ambiguous requirements will be skipped.

## Prime directive

Every contract traces to specific REQ-### IDs. Never invent requirements, goals, or failure conditions. Group and structure what EARS already defined. Ambiguous requirements are skipped entirely and listed in the **Skipped** section — never contracted.

## Procedure (summarised — full manual in the instructions file)

1. **Read inputs.** The EARS doc. The `.specflow/config.md` (Project Constraints, Scope Discipline Constraints, Domain Labels, Out of Scope, Project Identity).
2. **Validate the EARS doc.** Has a `## Requirements` section. Has REQ-### entries. Has `⚠ AMBIGUOUS` items flagged for skipping. If ALL requirements are ambiguous, STOP and tell the user to resolve them first.
3. **Group requirements into atomic tasks.** Each contract is one atomic task — completable in a single AI coding session. Grouping rules:
   - Requirements that modify the same file or module go together.
   - Requirements that share a data dependency go together.
   - A single API endpoint + its error handling = one contract.
   - A single UI component + its states = one contract.
   - A store/state module + its actions = one contract.
   - Never group more than 5 REQ-### items in one contract.
   - If a group would exceed L effort, split it.
4. **Write each Prompt Contract** with all four sections:
   - **GOAL** — one sentence, binary pass/fail, testable in under 1 minute, observable behaviour (not implementation).
   - **CONSTRAINTS** — project constraints, task-specific technology constraints, forbidden approaches; followed by the verbatim **Scope Discipline** subsection (SCOPE-001..006 from config); ends with `Covers: REQ-###, REQ-###`. When an artifact requires a separate registration or binding site to become reachable (route mounted on a mux, screen registered on a router, scheduled job added to a scheduler, event subscription, migration list entry, CLI command registration), the FORMAT section MUST name **both** the artifact file and its binding site.
   - **FORMAT** — exact file paths to create/modify, exported symbol names and signatures, test file path, naming conventions.
   - **FAILURE CONDITIONS** — checkbox list. Every item references a specific REQ-###. Minimum 2 per contract. Include a coverage failure condition (`Test coverage below [threshold]% (project config)`). Each becomes a RED phase test specification.
5. **Assign effort and dependencies.** Effort: XS / S / M / L. Dependencies reference CONTRACT-### IDs in this document. No circular dependencies.
6. **Write the file.** Path: `docs/specflow/contracts/<feature-slug>.md` (same slug as the EARS doc). See the instructions file for the exact document template.
7. **Skipped section.** List every `⚠ AMBIGUOUS` REQ-### that was not contracted, with the original ambiguous text and the resolve hint.
8. **Report.** Print counts, effort distribution, and the next-step command.

## Quality checklist

- Every CONTRACT-### has all 4 sections.
- Every GOAL is one sentence, binary pass/fail.
- Every FAILURE CONDITION references a REQ-###.
- Every contract has at least 2 failure conditions and a coverage condition.
- Every contract has a `Covers: REQ-...` line in CONSTRAINTS.
- Every contract's CONSTRAINTS includes the verbatim Scope Discipline subsection.
- No ambiguous requirements were contracted.
- No contract exceeds L effort.
- Dependencies reference valid CONTRACT-### IDs; no circular dependencies.
- No spec-gap found during contracting was filed as a standalone GitHub issue (SCOPE-005 — route it back through `/specflow-specify`).

## Reference

Deep procedure (full document template, contract template reference, failure condition guide): `.github/instructions/specflow-contract-writer.instructions.md`.
