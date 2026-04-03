---
description: "Organize Prompt Contracts into a Vision→Epic→Feature→Task hierarchy with dependencies. Writes output to docs/specflow/plans/"
argument-hint: "Contract document path or glob (e.g. 'docs/specflow/contracts/who-5*.md' or 'docs/specflow/contracts/')"
allowed-tools: ["Read", "Write", "Glob", "Grep", "Skill"]
---

Load the `specflow:roadmap-planner` skill and run it on the provided input.

The input is: $ARGUMENTS

Before running the skill:
1. Check if `.specflow/config.md` exists in the working directory.
   - If it exists: read it and tell the user "Loaded [project name] config" (use the project name from config).
   - If it does not exist: warn — "⚠ No .specflow/config.md found. Cannot plan without Epic Definitions.
     Run `/specflow:init` to generate config from your project."
     STOP — do not proceed without config.

2. If $ARGUMENTS is empty, look for contract documents in `docs/specflow/contracts/`:
   - If files exist (besides .gitkeep): list them and ask the user which to include,
     or offer to include all.
   - If no files exist: tell the user to run `/specflow:contract` first.

3. If $ARGUMENTS is a directory path, read all `.md` files in it (excluding .gitkeep).

4. If $ARGUMENTS is a glob pattern, resolve it and read all matching files.

Then load and follow the `specflow:roadmap-planner` skill.
