---
description: "Create GitHub milestones, issues, and sub-issues from a specflow plan. Requires explicit confirmation before any GitHub operations."
argument-hint: "Plan document path (e.g. 'docs/specflow/plans/who-5-wellbeing.md')"
allowed-tools: ["Read", "Write", "Bash", "Skill"]
---

Load the `specflow:github-publisher` skill and run it on the provided input.

The input is: $ARGUMENTS

Before running the skill:
1. Check if `.specflow/config.md` exists in the working directory.
   - If it exists: read it and tell the user "Loaded [project name] config" (use the project name from config).
   - If it does not exist: STOP — "⚠ Cannot publish without .specflow/config.md.
     The publisher needs owner, repo, and project-number.
     Run `/specflow:init` to generate config from your project."

2. Verify gh CLI is authenticated:
   - Run `gh auth status`
   - If not authenticated, STOP and tell the user to run `gh auth login`.

3. If $ARGUMENTS is empty, look for plan documents in `docs/specflow/plans/`:
   - If exactly one file exists (besides .gitkeep): use it automatically.
   - If multiple files exist: list them and ask the user to choose.
   - If no files exist: tell the user to run `/specflow:plan` first.

4. If $ARGUMENTS is provided but the file doesn't exist, tell the user the file was not found.

⚠ CRITICAL SAFETY RULE:
This command creates real GitHub issues, milestones, and project items.
The skill MUST show a full preview and get explicit user confirmation before executing
any `gh` command. Never skip the confirmation gate.

Then load and follow the `specflow:github-publisher` skill.
