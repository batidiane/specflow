# specflow — Agent Instructions

This repository ships **specflow**, a Specification-Driven Development (SDD) toolkit. The pipeline turns natural language into testable EARS requirements, wraps them in executable Prompt Contracts, organizes them into a GitHub Vision → Epic → Feature → Task hierarchy, drives implementation through a Kanban workflow with mandatory human gates, and distils the resulting cycles into an LLM-curated engineering wiki under `docs/wiki/`. Every step writes a markdown artifact before the next step reads it — the files are the source of truth, not conversation memory.

This file is the **agent-neutral** canonical instruction set. Read by Claude Code, Copilot Chat, Codex, Gemini, Cursor, opencode, and any other agent that follows the [`AGENTS.md`](https://agents.md/) convention.

## Pipeline (one paragraph)

`spec / feature idea → /specflow:specify → EARS requirements → /specflow:contract → Prompt Contracts → /specflow:plan → roadmap plan → /specflow:publish → GitHub milestones+issues+sub-issues → /specflow:implement → TDD (RED → GREEN → REFACTOR) with HITL gate → /specflow:status → live Kanban → /specflow:wiki → curated wiki updates`.

The Claude Code form is `/specflow:<step>`; the Copilot form is `/specflow-<step>`. Same pipeline, same artifacts.

## Where the procedure lives

**`skills/` is the payload.** Every pipeline step has a backing skill under `skills/<name>/SKILL.md` that holds the canonical procedure, format, and boundaries. The slash-command surface (`commands/*.md` for Claude Code, `.github/prompts/*.prompt.md` for Copilot) is a thin wrapper that:

1. Resolves inputs and preconditions.
2. References the relevant `skills/<name>/SKILL.md` body.
3. Applies any platform-specific overrides (tool surface, fallback behaviour).

Drift is structurally impossible: one source of procedure, two slash surfaces.

| Pipeline step | Skill (canonical) | Claude Code | Copilot |
|---|---|---|---|
| Initialize project | `skills/project-initializer/SKILL.md` | `/specflow:init` | `/specflow-init` |
| Specify (EARS) | `skills/ears-engineer/SKILL.md` | `/specflow:specify` | `/specflow-specify` |
| Contract | `skills/contract-writer/SKILL.md` | `/specflow:contract` | `/specflow-contract` |
| Plan (Vision→Epic→Feature→Task) | `skills/roadmap-planner/SKILL.md` | `/specflow:plan` | `/specflow-plan` |
| Publish (GitHub) | `skills/github-publisher/SKILL.md` | `/specflow:publish` | `/specflow-publish` |
| Implement (TDD) | `skills/kanban/SKILL.md` (state) + delegated TDD workflow | `/specflow:implement` | `/specflow-implement` |
| Status report / move card | `skills/kanban/SKILL.md` | `/specflow:status` | `/specflow-status` |
| Wiki bootstrap | `skills/wiki-init/SKILL.md` | `/specflow:wiki-init` | `/specflow-wiki-init` |
| Wiki compilation pass | `skills/wiki-curating/SKILL.md` | `/specflow:wiki` | `/specflow-wiki` |

The wiki curator agent lives at `agents/wiki-curator.md` (canonical) with a Copilot wrapper at `.github/agents/wiki-curator.agent.md`.

## Hard rules

These rules apply to every command and to ad-hoc agent work in this repo. Non-negotiable.

### Scope Discipline (SCOPE-001..006)

Cascaded from `.specflow/config.md` into every Prompt Contract's CONSTRAINTS section. Enforced at the REFACTOR gate of `/specflow:implement`.

- **SCOPE-001** — Fix findings inline if < 30 min and the files are already in the PR diff. No follow-up issue.
- **SCOPE-002** — Target zero new issues per PR. Every new issue is scope creep until justified.
- **SCOPE-003** — Before creating any issue, search existing issues first (`gh issue list --search "<keywords>" --state open`). Duplicate issues are a defect. The publisher runs this automatically for every planned issue.
- **SCOPE-004** — Style preferences are SKIP, not DEFER. Do not track them.
- **SCOPE-005** — Spec gaps route through the specflow pipeline (`/specflow:specify` → `/specflow:contract` → `/specflow:plan` → `/specflow:publish`), not standalone GitHub issues.
- **SCOPE-006** — When vendor docs conflict with contract FORMAT, follow vendor docs and flag the deviation in the PR description.

A REFACTOR audit report MUST end with `New issues recommended: [count]` — target 0. Every count > 0 item needs a one-line justification for why it cannot be fixed inline.

### Two-pass HITL on every wiki write

`/specflow:wiki`, `/specflow:wiki-init`, and the `wiki-curator` agent all enforce the same shape:

1. **Pass 1 — Read + Propose.** No writes. Output is a single Markdown diff proposal listing new files, modified files, confidence changes, watchlist additions, format-imitation references, and questions for the owner.
2. **HITL gate.** The owner replies approve / modify / reject. Subset approvals ("apply ADR-007, defer the glossary edits") are treated as modify.
3. **Pass 2 — Apply.** Writes only the approved diff. On rejection, nothing is written.

Never combine the two passes. The cost of one approval round is small; the cost of a silent overwrite is large.

### `sources/` is append-only

`docs/wiki/sources/` is populated by the project's TDD orchestrator (cycle archiving) and owner-decision capture. The only mutation any agent may make under `sources/` is flipping existing `[PENDING] → [COMPILED — YYYY-MM-DD by mode-A|mode-B]` markers on individual lines of `docs/wiki/sources/_pending.md`. No adds, no deletes, no reorders. All other writes under `sources/` are boundary violations.

### Never invent facts

If you cannot point to a source line — a cycle report under `docs/wiki/sources/`, an EARS REQ-###, a CONTRACT-### in the published receipt, a file in the codebase, or a documented spec — do not write it. Flag the gap. The `/specflow:specify` → `/specflow:contract` route exists precisely so that gaps re-enter the pipeline as requirements, not as invented behaviour.

### Format consistency outranks novelty

For wiki work, imitate the per-category templates (`docs/wiki/wiki/<category>/_template.md`) and any project-shipped seed exemplars exactly. If you have a "better" idea about format, raise it as an OWNER DECISION in the diff proposal — never a silent change. Same posture applies to Prompt Contracts (four sections, exact order), EARS (six patterns, no others), and the plan hierarchy (Vision → Epic → Feature → Task, no new tiers).

## Wiki curation — use the `wiki-curator` agent

When the task is anything under `docs/wiki/` — drafting an ADR, distilling a domain primer, evaluating a pattern for promotion, processing the `_pending.md` queue, running an end-of-sprint compilation pass — select or invoke the **wiki-curator** agent. It enforces the read-only-on-production-code boundary, the writes-only-inside-`docs/wiki/wiki/` boundary, and the two-pass HITL discipline. The single carve-out is `[PENDING] → [COMPILED]` status flips on existing lines of `_pending.md`.

The mandatory read order when consulting the wiki at runtime is `_hot.md` first → `index.md` second → specific files only after.

## Tool surface translation

Skills are written in Claude Code tool vocabulary (`Read`, `Write`, `Edit`, `Bash`, `Skill`, `Glob`, `Grep`). When invoked from a non-Claude agent, translate at the tool level — never rewrite the skill body:

| Claude Code | Copilot Chat | Codex / Gemini |
|---|---|---|
| `Read` | `#search/codebase` (read file via path reference) | native file read |
| `Write` / `Edit` | `#edit/editFiles` | native edit |
| `Bash` | terminal tool | shell tool |
| `Skill` (load by name) | `#file:skills/<name>/SKILL.md` (reference body) | inline-read same path |
| `Grep` / `Glob` | `#search/codebase` / file picker | native search |

This is a translation table, not a divergence. The skill procedure is identical across runtimes.

## Reference

- `skills/*/SKILL.md` — canonical procedures (one per pipeline step).
- `agents/wiki-curator.md` — canonical wiki-curator agent definition.
- `commands/*.md` — Claude Code slash-command wrappers.
- `.github/prompts/*.prompt.md` — Copilot slash-prompt wrappers.
- `.github/agents/wiki-curator.agent.md` — Copilot wiki-curator wrapper.
- `CLAUDE.md` — Claude Code repo-level notes (loaded automatically).
- `.specflow/config.md` — project-specific Epic Definitions, Domain Labels, Kanban Columns, GitHub Project IDs.
