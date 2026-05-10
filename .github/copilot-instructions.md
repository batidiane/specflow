# specflow — Specification-Driven Development for GitHub Copilot

This repository ships **specflow**, a Specification-Driven Development (SDD) toolkit. The pipeline turns natural language into testable EARS requirements, wraps them in executable Prompt Contracts, organizes them into a GitHub Vision → Epic → Feature → Task hierarchy, drives implementation through a Kanban workflow with mandatory human gates, and distils the resulting cycles into an LLM-curated engineering wiki under `docs/wiki/`. Every step writes a markdown artifact before the next step reads it — the files are the source of truth, not conversation memory.

## Pipeline (one paragraph)

`spec / feature idea → /specflow-specify → EARS requirements → /specflow-contract → Prompt Contracts → /specflow-plan → roadmap plan → /specflow-publish → GitHub milestones+issues+sub-issues → /specflow-implement → TDD (RED → GREEN → REFACTOR) with HITL gate → /specflow-status → live Kanban → /specflow-wiki → curated wiki updates`.

## Slash prompts (`.github/prompts/`)

| Prompt | Purpose | Output |
|---|---|---|
| `/specflow-init` | Generate or update `.specflow/config.md` from CLAUDE.md, repo structure, GitHub metadata | `.specflow/config.md` |
| `/specflow-specify` | Feature description → EARS requirements; flags ambiguities instead of guessing | `docs/specflow/ears/<slug>.md` |
| `/specflow-contract` | EARS → atomic Prompt Contracts (GOAL / CONSTRAINTS / FORMAT / FAILURE CONDITIONS) | `docs/specflow/contracts/<slug>.md` |
| `/specflow-plan` | Contracts → Vision → Epic → Feature → Task plan with dependency graph | `docs/specflow/plans/<slug>.md` |
| `/specflow-publish` | Plan → GitHub milestones, issues, sub-issues (preview + explicit confirmation) | `docs/specflow/published/<slug>-receipt.md` |
| `/specflow-implement` | Issue → TDD execution; moves task across Kanban; pauses at REFACTOR | TDD artifacts |
| `/specflow-status` | Live Kanban status report; epic progress, HITL queue, ready / blocked tasks; can move cards | console |
| `/specflow-wiki-init` | Bootstrap or repair the engineering wiki under `docs/wiki/`; idempotent | `docs/wiki/` layout + root `CLAUDE.md` block |
| `/specflow-wiki` | End-of-sprint compilation pass over `docs/wiki/wiki/`; cross-link integrity, stale detection, confidence drift, pattern promotion candidates | diff proposal → `docs/wiki/wiki/` updates |

Each prompt inlines its procedure. The deeper procedure manuals live alongside as `.github/instructions/specflow-<skill>.instructions.md` — open those when you need the full rulebook.

## Hard rules

These rules apply to every prompt and to ad-hoc Copilot Chat work in this repo. They are non-negotiable.

### Scope Discipline (SCOPE-001..006)

Cascaded from `.specflow/config.md` into every Prompt Contract's CONSTRAINTS section. Enforced at the REFACTOR gate of `/specflow-implement`.

- **SCOPE-001** — Fix findings inline if < 30 min and the files are already in the PR diff. No follow-up issue.
- **SCOPE-002** — Target zero new issues per PR. Every new issue is scope creep until justified.
- **SCOPE-003** — Before creating any issue, search existing issues first (`gh issue list --search "<keywords>" --state open`). Duplicate issues are a defect. The publisher runs this automatically for every planned issue.
- **SCOPE-004** — Style preferences are SKIP, not DEFER. Do not track them.
- **SCOPE-005** — Spec gaps route through the specflow pipeline (`/specflow-specify` → `/specflow-contract` → `/specflow-plan` → `/specflow-publish`), not standalone GitHub issues.
- **SCOPE-006** — When vendor docs conflict with contract FORMAT, follow vendor docs and flag the deviation in the PR description.

A REFACTOR audit report MUST end with `New issues recommended: [count]` — target 0. Every count > 0 item needs a one-line justification for why it cannot be fixed inline.

### Two-pass HITL on every wiki write

`/specflow-wiki`, `/specflow-wiki-init`, and the `wiki-curator` chat mode all enforce the same shape:

1. **Pass 1 — Read + Propose.** No writes. Output is a single Markdown diff proposal listing new files, modified files, confidence changes, watchlist additions, format-imitation references, and questions for the owner.
2. **HITL gate.** The owner replies approve / modify / reject. Subset approvals ("apply ADR-007, defer the glossary edits") are treated as modify.
3. **Pass 2 — Apply.** Writes only the approved diff. On rejection, nothing is written.

Never combine the two passes. The cost of one approval round is small; the cost of a silent overwrite is large.

### `sources/` is append-only

`docs/wiki/sources/` is populated by the project's TDD orchestrator (cycle archiving) and owner-decision capture. The only mutation any agent may make under `sources/` is flipping existing `[PENDING] → [COMPILED — YYYY-MM-DD by mode-A|mode-B]` markers on individual lines of `docs/wiki/sources/_pending.md`. No adds, no deletes, no reorders. All other writes under `sources/` are boundary violations.

### Never invent facts

If you cannot point to a source line — a cycle report under `docs/wiki/sources/`, an EARS REQ-###, a CONTRACT-### in the published receipt, a file in the codebase, or a documented spec — do not write it. Flag the gap. The `/specflow-specify` → `/specflow-contract` route exists precisely so that gaps re-enter the pipeline as requirements, not as invented behaviour.

### Format consistency outranks novelty

For wiki work, imitate the per-category templates (`docs/wiki/wiki/<category>/_template.md`) and any project-shipped seed exemplars exactly. If you have a "better" idea about format, raise it as an OWNER DECISION in the diff proposal — never a silent change. Same posture applies to Prompt Contracts (four sections, exact order), EARS (six patterns, no others), and the plan hierarchy (Vision → Epic → Feature → Task, no new tiers).

## Wiki curation — use the `wiki-curator` chat mode

When the task is anything under `docs/wiki/` — drafting an ADR, distilling a domain primer, evaluating a pattern for promotion, processing the `_pending.md` queue, running an end-of-sprint compilation pass — select the **wiki-curator** chat mode from the picker. It enforces the read-only-on-production-code boundary, the writes-only-inside-`docs/wiki/wiki/` boundary, and the two-pass HITL discipline. The single carve-out is `[PENDING] → [COMPILED]` status flips on existing lines of `_pending.md`.

The mandatory read order when consulting the wiki at runtime is `_hot.md` first → `index.md` second → specific files only after.

## Reference

- The 9 prompt files in `.github/prompts/` are the entry points.
- The 7 instruction files in `.github/instructions/` are the deep procedure manuals (EARS engineer, contract writer, roadmap planner, kanban manager, project initializer, wiki curating, wiki init).
- The 1 chat mode in `.github/chatmodes/` is the wiki curator agent.
- The Claude Code equivalents live alongside: `commands/*.md`, `skills/*/SKILL.md`, `agents/*.md`. Both layouts ship side-by-side in this repo.
