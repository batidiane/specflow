---
mode: agent
description: "Transform a feature description or spec section into EARS requirements. Writes output to docs/specflow/ears/"
tools: ['codebase', 'editFiles']
---

# /specflow-specify

Transform a free-form feature description or spec section into unambiguous EARS requirements.

**Input:** `${input:feature:Feature description or spec file path (e.g. 'WHO-5 wellbeing check-in' or 'docs/spec.md §3.4')}`

## Preconditions

1. Check via `#codebase` whether `.specflow/config.md` exists in the workspace.
   - **Exists** — read it; announce *"Loaded [project name] config"* (use the project name from the config).
   - **Missing** — warn: *"⚠ No `.specflow/config.md` found. Running without project context. Output will lack project-specific constraints. Run `/specflow-init` to generate config from your project."* Continue anyway.
2. If the input is empty, ask: *"What feature or spec section should I formalize into EARS requirements? Provide a description or a file path (e.g. 'docs/Product Spec.md §3.4')."*

## Prime directive

You NEVER invent requirements. You only formalize what is explicitly stated in the input. If something is implied but not stated, flag it as ambiguous rather than assume. When in doubt: flag, don't guess.

## Procedure (summarised — full manual in the instructions file)

1. **Read inputs.** The feature description (or the referenced spec section). The `.specflow/config.md` if present. Refresh the EARS pattern catalogue and anti-pattern list from the instructions file.
2. **Extract behavioural candidates.** Every distinct statement about what the system does, responds to, prevents, or prohibits. Exclude implementation choices, UI aesthetics without measurable criteria, and items in the config's `## Out of Scope`.
3. **Classify each candidate** using the six EARS patterns:

   | Pattern | Template |
   |---|---|
   | Ubiquitous | `The system shall [action].` |
   | Event-driven | `When [event], the system shall [action].` |
   | State-driven | `While [state], the system shall [action].` |
   | Conditional | `If [condition], then the system shall [action].` |
   | Negative | `The system shall not [action].` |
   | Complex | `While [state], when [event], the system shall [action].` |

4. **Write requirements.** One requirement per `## REQ-NNN [Pattern-Name]` block. IDs sequential within this document only. Include measurable thresholds explicitly (time: "within 500ms", count: "up to 3 times", range: "0 to 100"). Never prescribe implementation technology — that belongs in CONSTRAINTS, not REQ-###.
5. **Flag ambiguities.** Anything you cannot convert to clean EARS goes in the **Ambiguities Requiring Resolution** section as a `⚠ AMBIGUOUS — "[quote]"` block with a *Problem* and a *To resolve* line. Never write a REQ-### for ambiguous items.
6. **Write the file.** Path: `docs/specflow/ears/<feature-slug>.md`. Slug is the feature name lowercased and hyphenated. See the instructions file for the exact document template.
7. **Report.** Print counts (formalised vs flagged), pattern distribution, and the next-step command. If any ambiguities remain, the next step is to resolve them, not to run `/specflow-contract`.

## Quality checklist (run mentally before writing)

- Every REQ-### ends with a period.
- Every REQ-### has a Source line.
- No REQ-### contains multiple requirements.
- No REQ-### uses subjective terms without measurable thresholds.
- No REQ-### prescribes implementation technology.
- All ambiguous statements live in the Ambiguities section, not in REQ-### items.
- Feature slug is lowercase and hyphenated.
- REQ IDs are sequential with no gaps.

## Reference

Deep procedure (EARS patterns reference, anti-patterns, full document template): `.github/instructions/specflow-ears-engineer.instructions.md`.
