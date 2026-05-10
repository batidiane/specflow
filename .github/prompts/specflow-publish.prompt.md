---
mode: agent
description: "Create GitHub milestones, issues, and sub-issues from a specflow plan. Requires explicit confirmation before any GitHub operations."
tools: ['codebase', 'editFiles', 'githubRepo']
---

# /specflow-publish

Publish a specflow plan to GitHub: create milestones, issues, sub-issues, and project items in dependency order, with a mandatory confirmation gate.

**Input:** `${input:planDoc:Plan document path (e.g. 'docs/specflow/plans/who-5-wellbeing.md')}`

## Preconditions

1. Check `.specflow/config.md`.
   - **Exists** — read it; announce *"Loaded [project name] config"*.
   - **Missing** — STOP. *"⚠ Cannot publish without `.specflow/config.md`. The publisher needs owner, repo, and project-number. Run `/specflow-init` to generate config from your project."*
2. Verify `gh` CLI is authenticated. Run `gh auth status` in the terminal. If not authenticated, STOP and tell the user to run `gh auth login`.
3. If the input is empty, look at `docs/specflow/plans/`:
   - Exactly one file (besides `.gitkeep`) → use it automatically.
   - Multiple → list and ask which.
   - None → tell the user to run `/specflow-plan` first.
4. If the input is provided but the file does not exist, tell the user.

## CRITICAL safety rule

This command creates **real GitHub issues, milestones, and project items**. You MUST show a full preview of every `gh` command and obtain **explicit user confirmation** before executing any of them. Never skip the confirmation gate.

## Procedure

1. **Read the plan.** Parse the Vision → Epic → Feature → Task hierarchy. Extract every CONTRACT-### with its full Prompt Contract body, dependencies, effort estimate, and Feature / Epic placement.
2. **Read the config** for `owner`, `repo`, `github-project-id`, `github-project-number`, Domain Labels, Epic Definitions, and Kanban Columns.
3. **Reverse-search existing issues (SCOPE-003).** For each planned issue, run `gh issue list --search "<keywords>" --state open --repo <owner>/<repo>` to detect duplicates. Surface any matches in the preview so the owner can decide to dedupe.
4. **Build the preview.** Render every operation as the `gh` command that will execute it, in dependency order:
   - Milestones (one per Epic from config) — `gh api repos/<owner>/<repo>/milestones`.
   - Pinned Vision issue (optional, if the plan calls for one).
   - Feature issues — `gh issue create ... --milestone <epic> --label <domain-label>`.
   - Task sub-issues — created and linked via the GraphQL `addSubIssue` mutation against the parent Feature issue.
   - Project item additions — `gh project item-add <project-number> --owner <owner> --url <issue-url>`.
   - Initial Kanban column for every item: **Icebox**.
5. **HITL gate.** Present the preview as a single block of `gh` commands plus a counts summary (`N milestones, M features, P tasks, Q duplicates flagged`). Ask: *"Proceed? [yes / no / preview only]"*.
   - **yes** → execute in order.
   - **preview only** → write the preview to a temp file under `docs/specflow/published/<slug>-preview.md` and exit without executing.
   - **no** → exit cleanly.
6. **Execute** — only after explicit `yes`. For each operation:
   - Log the command being run.
   - Capture the resulting issue number / item ID.
   - On failure, STOP and surface the partial state; do not retry blindly. Re-runs are the owner's call (the receipt file makes resuming safe).
7. **Write the receipt.** Path: `docs/specflow/published/<plan-slug>-receipt.md`. The receipt is the canonical CONTRACT-### → GitHub issue number mapping consumed downstream by `/specflow-implement` and `/specflow-status`. Include:
   - Date of publish.
   - Plan source path.
   - Milestone-id table (Epic → milestone number).
   - Issue table (CONTRACT-### → issue number → URL → milestone → labels).
   - Sub-issue links recorded (parent Feature → child Tasks).
   - Project items (issue → project-item-id).
   - Any duplicates that were intentionally skipped.
8. **Report.** Print counts created, the receipt path, and the next-step command: *"Run `/specflow-status all` to see the new Icebox."*.

## Boundary rules

- Never mutate GitHub state outside the previewed command list.
- Never create new Epics not present in the config — if the plan lists Unassigned Contracts, surface them as part of the preview and ask the owner whether to file a config update or skip them.
- SCOPE-003 — duplicate detection is non-optional. If a search would return obviously stale results (e.g., the search keywords are too generic), pause and ask the owner to tighten them rather than producing duplicates silently.

## Reference

Deep procedure (publish-receipt template, label-and-milestone resolution): the procedure is enforced inline in this prompt — there is no separate `github-publisher.instructions.md` because the steps map directly to `gh` invocations and the receipt format. Cross-references: `.github/instructions/specflow-roadmap-planner.instructions.md` for the source plan shape.
