# specflow — Agent Instructions

`specflow` is a Specification-Driven Development toolkit. The pipeline turns natural language → EARS requirements → Prompt Contracts → GitHub Vision/Epic/Feature/Task issues → TDD with HITL gates → curated engineering wiki. Every step writes a markdown artifact before the next reads it — files are the source of truth, not conversation memory.

Skills (canonical procedures) live under `skills/<name>/SKILL.md`. Slash-commands are thin wrappers: `commands/specflow-*.md` for Claude Code, `.github/prompts/specflow-*.prompt.md` for Copilot Chat. The Copilot wrappers reference skills via `#file:`. Wiki curator agent: `agents/wiki-curator.md` (canonical) + `.github/agents/wiki-curator.agent.md` (Copilot wrapper).

## Hard rules

Non-negotiable across every specflow command and ad-hoc agent work in this repo.

### Scope Discipline (SCOPE-001..006)

Cascaded from `.specflow/config.md` into every Prompt Contract. Enforced at the REFACTOR gate of `/specflow:implement`.

- **SCOPE-001** — Fix findings inline if < 30 min and the files are already in the PR diff. No follow-up issue.
- **SCOPE-002** — Target zero new issues per PR. Every new issue is scope creep until justified.
- **SCOPE-003** — Before creating any issue, search existing first (`gh issue list --search "<keywords>" --state open`).
- **SCOPE-004** — Style preferences are SKIP, not DEFER. Do not track them.
- **SCOPE-005** — Spec gaps route through the specflow pipeline (`/specflow:specify` → `/specflow:contract` → `/specflow:plan` → `/specflow:publish`), not standalone GitHub issues.
- **SCOPE-006** — When vendor docs conflict with contract FORMAT, follow vendor docs and flag the deviation in the PR description.

REFACTOR audit MUST end with `New issues recommended: [count]` — target 0. Every count > 0 needs a one-line justification.

### Two-pass HITL on every wiki write

`/specflow:wiki`, `/specflow:wiki-init`, and the wiki-curator agent enforce: (1) read + propose diff, (2) HITL gate, (3) apply only the approved diff. Never combine. The only carve-out is flipping `[PENDING] → [COMPILED]` markers on existing lines of `docs/wiki/sources/_pending.md`.

### Never invent facts

If you cannot point to a source — cycle report under `docs/wiki/sources/`, EARS REQ-###, CONTRACT-### in published receipt, file in the codebase, or documented spec — do not write it. Flag the gap. The `/specflow:specify` → `/specflow:contract` route exists so gaps re-enter the pipeline as requirements, not invented behaviour.

### Format consistency outranks novelty

Imitate templates exactly: wiki per-category `_template.md`, Prompt Contracts (4 sections, exact order), EARS (6 patterns, no others), plan hierarchy (Vision → Epic → Feature → Task, no new tiers). New format ideas → raise as OWNER DECISION, never silent change.

## Tool surface translation

Skills are written in Claude Code vocabulary. Non-Claude agents translate at the tool level — never rewrite the skill body:

| Claude Code | Copilot Chat | Codex / Gemini |
|---|---|---|
| `Read` | `#search/codebase` | native file read |
| `Write` / `Edit` | `#edit/editFiles` | native edit |
| `Bash` | terminal tool | shell tool |
| `Skill` (load by name) | `#file:skills/<name>/SKILL.md` | inline-read same path |
| `Grep` / `Glob` | `#search/codebase` | native search |

One procedure, many runtimes.

## Reference

- Full pipeline and workflows: `README.md`.
- Per-step procedures: `skills/<name>/SKILL.md`.
- Project-specific config: `.specflow/config.md`.
