---
description: "Transform EARS requirements into atomic Prompt Contracts. Writes output to docs/specflow/contracts/"
argument-hint: "EARS document path (e.g. 'docs/specflow/ears/who-5-wellbeing-check-in.md')"
allowed-tools: ["Read", "Write", "Glob", "Skill"]
---

Load the `specflow:contract-writer` skill and run it on the provided input.

The input is: $ARGUMENTS

Before running the skill:
1. Check if `.specflow/config.md` exists in the working directory.
   - If it exists: read it and tell the user "Loaded [project name] config" (use the project name from config).
   - If it does not exist: warn the user — "⚠ No .specflow/config.md found.
     Running without project context. Contracts will lack project-specific constraints.
     Run `/specflow:init` to generate config from your project."

2. If $ARGUMENTS is empty, look for EARS documents in `docs/specflow/ears/`:
   - If exactly one file exists (besides .gitkeep): use it automatically and tell the user.
   - If multiple files exist: list them and ask the user to choose.
   - If no files exist: tell the user to run `/specflow:specify` first.

3. If $ARGUMENTS is provided but the file doesn't exist, tell the user the file was not found.

4. Before proceeding, check if the EARS document has any `⚠ AMBIGUOUS` entries:
   - If yes: warn the user that ambiguous requirements will be skipped.

Then load and follow the `specflow:contract-writer` skill.
