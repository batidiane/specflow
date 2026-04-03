---
description: "Transform a feature description or spec section into EARS requirements. Writes output to docs/specflow/ears/"
argument-hint: "Feature description or spec file path (e.g. 'WHO-5 wellbeing check-in' or 'docs/spec.md §3.4')"
allowed-tools: ["Read", "Write", "Glob", "Skill"]
---

Load the `specflow:ears-engineer` skill and run it on the provided input.

The input is: $ARGUMENTS

Before running the skill:
1. Check if `.specflow/config.md` exists in the working directory.
   - If it exists: read it and tell the user "Loaded CocoMind config" (or whatever the project name is).
   - If it does not exist: warn the user — "⚠ No .specflow/config.md found.
     Running without project context. Output will lack project-specific constraints.
     Run `/specflow:init` to generate config from your project."

2. If $ARGUMENTS is empty, ask:
   "What feature or spec section should I formalize into EARS requirements?
   Provide a description or a file path (e.g. 'docs/CocoMind Product Specification.md §3.4')."

Then load and follow the `specflow:ears-engineer` skill.
