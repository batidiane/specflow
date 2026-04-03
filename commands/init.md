---
description: "Generate or update .specflow/config.md by analyzing the project's CLAUDE.md, repo structure, and GitHub metadata. Creates artifact directories if needed."
argument-hint: "Optional project description (e.g. 'A meditation app for the Spanish market')"
allowed-tools: ["Read", "Write", "Glob", "Bash", "Skill"]
---

Load the `specflow:project-initializer` skill and run it.

The input is: $ARGUMENTS

Determine the mode:

**Create mode** — if `.specflow/config.md` does NOT exist:
1. Tell the user: "No specflow config found. Analyzing your project to generate one..."
2. Load and follow the `specflow:project-initializer` skill in create mode.

**Update mode** — if `.specflow/config.md` ALREADY exists:
1. Read the existing config.
2. Tell the user: "Found existing specflow config. Checking for updates..."
3. Load and follow the `specflow:project-initializer` skill in update mode.

If $ARGUMENTS contains a project description, pass it to the skill as additional context
for populating the config. The skill will still analyze CLAUDE.md and project structure,
but will use the description to fill gaps (especially for Epic Definitions and Out of Scope).
