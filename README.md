# specflow

A **Specification-Driven Development (SDD)** toolkit for AI-assisted teams. specflow turns natural language into EARS requirements, wraps them in four-section Prompt Contracts, publishes them into a Vision → Epic → Feature → Task hierarchy on GitHub, drives TDD with explicit human-in-the-loop gates, and distils every cycle into an LLM-curated engineering wiki.

It ships two ways:

- **[Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin** — install with `/plugin install`, get nine `/specflow:*` slash-commands. See [Install (Claude Code)](#install-claude-code).
- **GitHub Copilot customization layer** — install with a `curl ... install.sh | bash` one-liner, get matching `/specflow-*` Copilot prompts and a `wiki-curator` custom agent. See [Install (GitHub Copilot)](#install-github-copilot).

The same canonical skills (`skills/<name>/SKILL.md`) drive both runtimes — no duplicated logic.

## Status & Scope

specflow is a personal experiment: an attempt to find a **lighter middle ground between [spec-kit](https://github.com/github/spec-kit) and [superpowers](https://github.com/obra/superpowers)**. spec-kit is a comprehensive SDD toolkit with a large surface area; superpowers is a broad, general-purpose skills framework. specflow picks a narrow slice — EARS → Prompt Contracts → GitHub Projects, plus a curated wiki on top — and wires it together in the way that fits *my* workflow.

That means:

- **Opinionated by design.** The pipeline, artifact layout, Kanban columns, wiki schema, and config shape reflect my own projects and preferences, not a general standard.
- **Not a product.** It ships as-is, without roadmap guarantees or support commitments.
- **Use it freely, adapt it freely.** MIT-licensed. Fork it, carve out the pieces you want, rewire the skills — everything is plain markdown.
- **Composable, not exclusive.** specflow is designed to work *alongside* [superpowers](https://github.com/obra/superpowers) rather than replace it. `/specflow:implement` can hand off to [`superpowers:test-driven-development`](https://github.com/obra/superpowers), and the brainstorming / planning / verification skills from superpowers complement specflow's artifact pipeline cleanly.
- **Pairs with [triad](https://github.com/batidiane/triad).** triad is a companion plugin — a multi-agent TDD orchestrator (DESIGN → RED → GREEN → REFACTOR → QUALITY) that specflow prefers for the implementation phase when it's installed. The wiki's per-cycle distillation hook (Mode A) is designed to fit a Phase 8.5 in that orchestrator.

If you want a more complete or vendor-backed SDD experience, use spec-kit. If you want a broader skills toolkit, use superpowers. If you want a small, hackable, GitHub-native pipeline tuned to one person's taste, this is it.

## Why

AI-assisted development produces inconsistent results when requirements are informal and project memory is scattered across chat history. Vague specs lead to hallucinated features and missed edge cases; lost context across cycles leads to re-discovery, re-litigation of decisions, and gradual architectural drift. specflow tackles both halves of the problem:

```
Spec document / feature idea
    ↓  formalize
Unambiguous EARS requirements (testable, traceable)
    ↓  contract
Prompt Contracts (deterministic AI agent instructions)
    ↓  plan
GitHub hierarchy (Vision → Epic → Feature → Task)
    ↓  publish
Real GitHub milestones, issues, sub-issues
    ↓  implement
TDD execution with human gates
    ↓  track
Kanban status from live GitHub data
    ↓  distil
Curated engineering wiki (LLM-maintained second brain)
```

Every step produces a persistent markdown artifact. The files are the source of truth — not conversation memory.

## Core Principles

### Spec-as-Source
Every GitHub issue traces to a Prompt Contract, which traces to an EARS requirement, which traces to a spec document section. Nothing is invented by AI.

### EARS Requirements
[Easy Approach to Requirements Syntax](https://alistairmavin.com/ears/) eliminates ambiguity by constraining natural language into six patterns:

| Pattern | Template | Use When |
|---------|----------|----------|
| **Ubiquitous** | The system shall [action]. | Always active, no trigger |
| **Event-driven** | When [event], the system shall [action]. | Discrete trigger |
| **State-driven** | While [state], the system shall [action]. | Sustained condition |
| **Conditional** | If [condition], then the system shall [action]. | Error/edge cases |
| **Negative** | The system shall not [action]. | Genuine prohibitions |
| **Complex** | While [state], when [event], the system shall [action]. | State + trigger |

If something can't be written as EARS, it's flagged as ambiguous — never guessed.

### Prompt Contracts
Each atomic task gets a four-section contract that drives deterministic AI agent behavior:

- **GOAL** — One sentence. Binary pass/fail. Testable in under 1 minute.
- **CONSTRAINTS** — Hard boundaries: architecture rules, required libraries, forbidden patterns.
- **FORMAT** — Exact file paths, exported symbols, test file locations. **When an artifact requires a separate registration or binding site to become reachable** (route mounted on a mux, screen registered on a router, scheduled job added to a scheduler, event subscription, migration list entry, CLI command registration), FORMAT must name **both** the artifact file and its binding site. An artifact without its binding ships unreachable.
- **FAILURE CONDITIONS** — What makes the output unacceptable. Each maps to a REQ-### and becomes a TDD test spec.

### Artifacts Over Memory
Every pipeline step writes a markdown file before the next step reads it. Restartable, manually editable, version-controlled. No reliance on conversation context.

### Explicit Gates
GitHub mutations are never automatic. The publisher previews every `gh` command and waits for human confirmation. The Kanban workflow has a mandatory human gate (HITL Review) between AI implementation and merge. The wiki curator follows the same shape — every wiki write is preceded by a diff proposal and an approval round.

### Scope Discipline
Every `.specflow/config.md` carries a standard `## Scope Discipline Constraints` block (SCOPE-001..006) that cascades into every Prompt Contract's CONSTRAINTS section and travels with every TDD handoff. These rules are enforced at the REFACTOR gate:

- **Fix inline, don't defer** — if a finding is < 30 min and touches files in the PR diff, fix it now; no follow-up issue.
- **Zero new issues per PR** is the target; every new issue is scope creep until justified.
- **Search before creating** — `gh issue list --search "<keywords>" --state open` first; the publisher runs this automatically for every planned issue.
- **Style preferences are SKIP**, not DEFER — do not track them.
- **Don't touch what you didn't break** — findings in files outside the PR diff are out of scope.
- **Spec gaps use the specflow pipeline**, not standalone GitHub issues.
- **Vendor docs override contract FORMAT** when they conflict; flag in PR.

`/specflow:init` writes these into your config automatically. If you run it against an existing config that predates them, update mode will flag the missing block as a required update. The suggested CLAUDE.md §Development Rules mirror is printed after init — apply it manually.

## Install (Claude Code)

From inside Claude Code:

```
/plugin marketplace add batidiane/specflow
/plugin install specflow@specflow
```

The first command registers the marketplace; the second installs the plugin. After install, the nine `/specflow:*` commands appear in the slash menu.

To share specflow with your team via project settings, add it to `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "specflow": {
      "source": {
        "source": "github",
        "repo": "batidiane/specflow"
      }
    }
  },
  "enabledPlugins": {
    "specflow@specflow": true
  }
}
```

Current plugin version: `1.1.0` (see `.claude-plugin/plugin.json`).

## Install (GitHub Copilot)

specflow follows the **superpowers single-source-of-truth pattern**: skills are the payload, every agent gets a thin platform wrapper. There is no duplication of skill bodies into Copilot-specific instruction files.

**Source repo structure (canonical sources at the top, platform wrappers underneath):**

```
AGENTS.md                              # agent-neutral canonical instructions (also installs at target root)
skills/<name>/SKILL.md                 # canonical procedure for each pipeline step
agents/wiki-curator.md                 # canonical wiki-curator agent

commands/*.md                          # Claude Code slash-command wrappers
.github/prompts/*.prompt.md            # Copilot slash-prompt wrappers (~30 LOC each)
.github/agents/wiki-curator.agent.md   # Copilot wiki-curator wrapper
```

In the source repo, prompts reference `#file:skills/<name>/SKILL.md`. The Copilot installer (below) rewrites those references to `#file:.specflow/skills/<name>/SKILL.md` when it moves the skill payload into the hidden `.specflow/` namespace at the target — same content, different path. Drift between prompt and skill is structurally impossible at either layout.

**Quick install (one-liner).** From the target project's repo root:

```bash
curl -fsSL https://raw.githubusercontent.com/batidiane/specflow/main/install.sh | bash
```

Requires `git`, `bash` 3.2+, and `perl` (standard on dev machines).

Default install (`--platform=copilot`) drops a **clean hidden layout**:

```
your-project/
├── AGENTS.md                        # required at root (Copilot/Codex/Gemini auto-discover here)
├── .github/                         # Copilot prompts + custom agents
│   ├── prompts/specflow-*.prompt.md
│   └── agents/wiki-curator.agent.md
├── .specflow/                       # vendored skills + agents (hidden — out of your way)
│   ├── skills/
│   └── agents/
└── .specflow.lock                   # install manifest (ref + commit + platform + timestamp)
```

`#file:` references inside the prompts are rewritten during install — `#file:skills/...` becomes `#file:.specflow/skills/...` — so paths resolve at runtime. Existing files are NOT overwritten; re-run with `--force` to update.

**Common flags:**

```bash
# Install both Claude + Copilot layers (root layout — skills/, agents/, commands/ visible)
curl -fsSL https://raw.githubusercontent.com/batidiane/specflow/main/install.sh | bash -s -- --platform=both

# Claude-only canonical layout (rarely needed — Claude users normally use /plugin install)
curl -fsSL https://raw.githubusercontent.com/batidiane/specflow/main/install.sh | bash -s -- --platform=claude

# Pin to a tag (or branch/commit SHA)
curl -fsSL https://raw.githubusercontent.com/batidiane/specflow/main/install.sh | bash -s -- --ref=v1.1.0

# Preview before writing
curl -fsSL https://raw.githubusercontent.com/batidiane/specflow/main/install.sh | bash -s -- --dry-run

# Update an existing install
curl -fsSL https://raw.githubusercontent.com/batidiane/specflow/main/install.sh | bash -s -- --force
```

Full options: `bash install.sh --help`.

**Conflict handling.** The installer is designed to be safe to drop into a repo that already has Copilot customizations:

- `AGENTS.md` — specflow content is merged inside `<!-- BEGIN specflow ... -->` / `<!-- END specflow -->` marker comments. Your existing content outside the markers is preserved verbatim. The first time the block is appended, a `AGENTS.md.bak` backup is written. Re-runs refresh only the marked region in place.
- `.github/prompts/` and `.github/agents/` — installed **per file**, never as a directory wipe. Only the nine `specflow-*.prompt.md` files and `wiki-curator.agent.md` are touched. Your `.github/workflows/`, `CODEOWNERS`, issue templates, and unrelated prompts/agents are never read or modified.
- Other directories (`.specflow/`, `skills/`, `agents/`, etc.) — directory-level skip if they already exist. Pass `--force` to overwrite.

**Layout choice by platform:**

| Platform | Layout | When to pick |
|---|---|---|
| `copilot` (default) | hidden under `.specflow/`, `#file:` paths rewritten | specflow is added to an existing app; clean root preferred |
| `claude` | canonical root (`skills/`, `agents/`, `commands/`, `.claude-plugin/`) | vendor-into-repo for Claude (most users skip and `/plugin install` instead) |
| `both` | root union (everything visible at root) | specflow IS the project, or you want symmetric paths across platforms |

**Why not `/plugin install` like Claude Code?** VS Code Copilot has no plugin marketplace for customization layers (prompts, agents, instructions). Files must live in the target project's repo. `install.sh` is the moral equivalent of `/plugin install` — one command, fetches the canonical sources, drops them at the right paths. An `npx specflow init` package is on the roadmap for tighter ergonomics (update semantics, conflict resolution per file, per-platform subcommands à la spec-kit).

**What auto-discovers what.** Copilot picks up `AGENTS.md` at the repo root, `.github/prompts/`, and `.github/agents/` with no manifest required. The skills under `.specflow/skills/` are read on demand via the `#file:` references in each prompt.

**Mapping (Claude Code → Copilot).**

| Claude Code | Copilot equivalent |
|---|---|
| `/specflow:init` | `/specflow-init` prompt |
| `/specflow:specify` | `/specflow-specify` prompt |
| `/specflow:contract` | `/specflow-contract` prompt |
| `/specflow:plan` | `/specflow-plan` prompt |
| `/specflow:publish` | `/specflow-publish` prompt |
| `/specflow:implement` | `/specflow-implement` prompt |
| `/specflow:status` | `/specflow-status` prompt |
| `/specflow:wiki-init` | `/specflow-wiki-init` prompt |
| `/specflow:wiki` | `/specflow-wiki` prompt |
| `skills/*/SKILL.md` | **same file** — Copilot prompts reference it via `#file:` (path rewritten to `.specflow/skills/` on copilot-platform install) |
| `agents/wiki-curator.md` | `.github/agents/wiki-curator.agent.md` (thin wrapper; references rewritten to `.specflow/agents/` on copilot-platform install) |
| `CLAUDE.md` (Claude-specific) | `AGENTS.md` at repo root (agent-neutral; read by Copilot Chat) |

**Usage.** In Copilot Chat, type `/specflow-specify` (etc.) to invoke a prompt; pass arguments inline. The `wiki-curator` custom agent is selectable from the agent picker — switch to it for any work under `docs/wiki/`.

**Why this works.** Skills are written in Claude Code tool vocabulary (`Read`, `Write`, `Bash`, `Skill`, `Grep`). When Copilot loads a skill via `#file:`, the prompt wrapper instructs it to translate at the tool level — `Bash` → terminal tool, `Read` → `#search/codebase`, `Write` → `#edit/editFiles`, and so on. The translation table lives in `AGENTS.md` (§ Tool surface translation). One procedure, many runtimes.

## Quick Start

### 1. Initialize your project

```
/specflow:init
```

Analyzes your project's CLAUDE.md, repo structure, and GitHub metadata to generate `.specflow/config.md`. Detects 25+ language stacks (with a polyglot heuristic for mixed-language repos) and asks targeted questions for anything it can't infer.

### 2. Formalize requirements

```
/specflow:specify WHO-5 wellbeing check-in assessment flow
```

Transforms the feature description into EARS requirements. Flags ambiguities instead of guessing.

**Output:** `docs/specflow/ears/who-5-wellbeing-check-in.md`

### 3. Write Prompt Contracts

```
/specflow:contract docs/specflow/ears/who-5-wellbeing-check-in.md
```

Groups requirements into atomic tasks, writes a Prompt Contract for each with GOAL, CONSTRAINTS, FORMAT, and FAILURE CONDITIONS.

**Output:** `docs/specflow/contracts/who-5-wellbeing-check-in.md`

### 4. Plan the roadmap

```
/specflow:plan docs/specflow/contracts/who-5-wellbeing-check-in.md
```

Organizes contracts into Vision → Epic → Feature → Task hierarchy. Resolves dependencies, identifies critical path, runs verification checks.

**Output:** `docs/specflow/plans/who-5-wellbeing.md`

### 5. Publish to GitHub

```
/specflow:publish docs/specflow/plans/who-5-wellbeing.md
```

Shows a full preview of all milestones, issues, and sub-issues to create. Waits for your confirmation. Creates everything in dependency order. Writes a receipt mapping CONTRACT-### to issue numbers.

**Output:** `docs/specflow/published/who-5-wellbeing-receipt.md`

### 6. Implement with TDD

```
/specflow:implement 49
```

Reads the Prompt Contract from the issue, moves the task to In Progress, delegates to your TDD workflow. Pauses at REFACTOR for human review.

### 7. Track progress

```
/specflow:status all
/specflow:status S2
/specflow:status move 47 Done
/specflow:status unblock
```

Queries live GitHub Projects data. Shows epic progress bars, HITL items awaiting review, blocked tasks, and what's ready to start.

### 8. Bootstrap the engineering wiki (one-time)

```
/specflow:wiki-init
```

Detects the current state of `docs/wiki/`, proposes a diff of every directory to create, file to seed, and amendment to your root `CLAUDE.md`, then applies on approval. Idempotent — re-run for repair or schema bumps.

### 9. Compile the wiki end-of-sprint

```
/specflow:wiki
/specflow:wiki --scope interfaces
```

Runs `@wiki-curator` Mode B against the full curated tree: processes the pending queue, checks cross-link integrity, detects stale and contradicted pages, proposes confidence promotions and demotions, surfaces pattern-promotion candidates, refreshes `_hot.md`, updates `index.md`, and appends to `_log.md`. Output is a diff proposal; nothing is written without owner approval.

## Commands

| Command | Purpose | Output |
|---------|---------|--------|
| `/specflow:init` | Generate or update project config | `.specflow/config.md` |
| `/specflow:specify` | Feature → EARS requirements | `docs/specflow/ears/<slug>.md` |
| `/specflow:contract` | EARS → Prompt Contracts | `docs/specflow/contracts/<slug>.md` |
| `/specflow:plan` | Contracts → GitHub hierarchy | `docs/specflow/plans/<slug>.md` |
| `/specflow:publish` | Plan → GitHub issues (with confirmation) | `docs/specflow/published/<slug>-receipt.md` |
| `/specflow:implement` | Issue → TDD execution | TDD artifacts |
| `/specflow:status` | Live Kanban status report | Console output |
| `/specflow:wiki-init` | Bootstrap or repair the engineering wiki | `docs/wiki/` layout + root `CLAUDE.md` amendment |
| `/specflow:wiki` | End-of-sprint compilation pass over the curated wiki | Diff proposal → `docs/wiki/wiki/` updates |

## Project Configuration

Each project gets a `.specflow/config.md` (generated by `/specflow:init`):

```markdown
# specflow config

## Project Identity
- name: MyProject
- owner: github-owner
- repo: repo-name
- github-project-id: PVT_...
- github-project-number: 3

## Spec Documents
- product-spec: docs/product-spec.md
- api-spec: docs/api-design.md

## Epic Definitions
- S0: Foundation & Setup
- S1: Core Features
- S2: Polish & Release

## Domain Labels
- [API]: Backend endpoints and services
- [UI]: Frontend screens and components
- [CORE]: Shared state, auth, utilities

## Kanban Columns
- Icebox
- To Do (Ready)
- In Progress (Triad Active)
- HITL Review
- Done

## Project Constraints
- 90% minimum test coverage
- All features behind feature flags

## Out of Scope
- Admin dashboard
- Monetization
```

## Artifact Pipeline

```
docs/specflow/
  ears/              ← EARS requirement documents
  contracts/         ← Prompt Contract documents
  plans/             ← Roadmap plan documents
  published/         ← GitHub publish receipts
```

Every file is markdown, version-controlled, and human-editable. If you need to fix a requirement, edit the EARS doc and re-run downstream commands.

## Kanban Workflow

Tasks flow through five columns in GitHub Projects:

```
Icebox → To Do (Ready) → In Progress (Triad Active) → HITL Review → Done
```

| Column | Who Acts | Entry Condition |
|--------|----------|-----------------|
| Icebox | — | Published by specflow |
| To Do (Ready) | Human | Human confirms task is ready |
| In Progress | AI | `/specflow:implement` invoked |
| HITL Review | Human | TDD reaches REFACTOR gate |
| Done | Human | Approved, merged, quality gates passed |

Forbidden transitions are enforced: you can't skip from Icebox to In Progress, or from In Progress to Done.

## Engineering Wiki

The wiki is specflow's third pillar, alongside the EARS → Contract pipeline and the GitHub Kanban workflow. It is an **LLM-curated, project-specific second brain** that captures decisions, domain knowledge, public contracts, user journeys, runbooks, dependencies, and policies as they emerge during the development loop — and feeds the downstream documentation surfaces that product, ops, and compliance care about.

The shape draws directly from two ideas:

- Andrej Karpathy's [LLM wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) — the "second brain" pattern where an LLM librarian distils append-only sources into a curated layer and re-lints the result periodically.
- The [*Towards Data Science* article on giving AI unlimited, updated context](https://towardsdatascience.com/give-your-ai-unlimited-updated-context/) — which adds the control-file plumbing (pending queue, hot cache, audit log) that makes the loop reliable across cycles.

Everything the curator writes is preceded by a diff proposal. Nothing is applied without owner approval — same HITL discipline as the REFACTOR gate.

### Layout

```
docs/wiki/
├── sources/                     # Append-only; populated by the TDD orchestrator
│   ├── cycles/                  # One archived cycle report per Triad cycle
│   ├── decisions/               # Owner-decision artefacts from HITL gates
│   └── _pending.md              # Compilation queue (control file)
└── wiki/                        # Curated; only @wiki-curator writes here
    ├── CLAUDE.md                # Wiki schema (auto-loaded inside docs/wiki/)
    ├── _hot.md                  # < 500 token briefing — read first
    ├── _log.md                  # Append-only audit trail of every curator run
    ├── index.md                 # Catalog — read second
    ├── glossary.md              # One-line term definitions
    ├── lessons.md               # Cross-cycle anti-patterns and rules
    ├── decisions/               # ADRs
    ├── domains/                 # Domain primers
    ├── patterns/                # Code patterns (gated by "Name 3")
    ├── interfaces/              # APIs we expose
    ├── flows/                   # End-to-end user journeys
    ├── runbooks/                # Operational procedures
    ├── dependencies/            # External services we consume
    ├── policies/                # Non-functional cross-cutting rules
    └── risks/                   # Threat-model entries / known-risk register
```

The split is the central invariant: `sources/` is the immutable raw record, `wiki/` is the curated derivative. If the curated layer drifts, the recovery path is rebuild-from-sources.

### Categories that feed product documentation

Each curated category maps to a downstream documentation surface, so the wiki is upstream of help docs, ops docs, compliance docs, and architecture diagrams — not parallel to them.

| Category | What it captures | Feeds (downstream) |
|---|---|---|
| `decisions/` | ADRs (300–500 words, five sections) | Architecture decision register |
| `domains/` | Internal mental models (six sections) | Engineering onboarding |
| `patterns/` | Reusable mechanics gated by "Name 3" | Internal best-practice catalog |
| `interfaces/` | What we **expose** — HTTP / TS / GraphQL / RPC / CLI / events | Partner docs, SDK reference, public API docs |
| `flows/` | End-to-end user journeys (happy path + branches) | Help center, onboarding, QA scenarios, support |
| `runbooks/` | Operational procedures with verification + rollback | On-call playbook, incident response, admin guides |
| `dependencies/` | External services we **consume**, with criticality + fallback | Architecture diagrams, deps page, blast-radius analysis |
| `policies/` | Non-functional rules (retention, GDPR, SLOs, access) | Compliance, trust page, security overview |
| `risks/` | Threat-model entries with severity / likelihood / status / mitigation | Security overview, audit prep, blast-radius analysis |

### Control files (the Karpathy / TDS plumbing)

Four files coordinate cadence and provide audit / orientation. Without them, per-cycle distillation can silently lose work and the end-of-sprint pass has no way to know what is fresh.

- **`sources/_pending.md`** — the compilation queue. Bridges per-cycle distillation (Mode A) and end-of-sprint compilation (Mode B). When a Mode A run is skipped (token budget, time pressure, agent crash), its line stays `[PENDING]` so Mode B picks it up. The curator may only flip `[PENDING] → [COMPILED]` on existing lines — never add, delete, or reorder. This is the single carve-out for writes under `sources/`.
- **`wiki/_log.md`** — append-only audit trail. Every successful curator run appends one entry (mode, subject, files written, confidence changes, watchlist additions). No-op Mode B runs still log so freshness can be measured. Historical entries are never edited; corrections reference the original by timestamp.
- **`wiki/_hot.md`** — the hot cache. A < 500 token briefing of what is load-bearing right now: active decisions, open OWNER DECISIONS, recent confidence changes, watchlist patterns, health metrics (pending depth, days since last Mode A/B, stale primer count). Refreshed only by Mode B, so Mode A stays cheap.
- **`wiki/index.md`** — the catalog. Re-listed in full on every Mode B run; carries the confidence level inline for each page.

When any agent consults the wiki at runtime, the mandatory read order is `_hot.md` → `index.md` → specific files. The wiki schema file (`docs/wiki/wiki/CLAUDE.md`) is auto-loaded by Claude Code whenever an agent works in the wiki tree, so the order is enforced at the schema layer.

### Confidence dial and the "Name 3" rule

Every curated file carries a `confidence` field: `high` (owner-confirmed, safe to cite externally), `medium` (derived from documented sources, not yet battle-tested), `low` (inferred from a single cycle, treat as hypothesis).

- **Promotion** (`medium → high`) is **owner-only**. The curator may *propose* a promotion in a diff with rationale; it never applies one unilaterally.
- **Demotion** is **curator-allowed** as a safety move when a more recent cycle contradicts the file. Demotions always appear in the diff proposal — never silent.

Patterns are gated by **"Name 3"**: a pattern earns a `patterns/` page only when three known consumers exist in the codebase, each listed by file path. Two consumers go on a watchlist comment in the Mode B proposal; one is just a coincidence.

### Two modes, two cadences

- **Mode A — per-cycle distillation.** Invoked by the project's TDD orchestrator (e.g. `triad.md` Phase 8.5) immediately after a cycle archives its report under `sources/cycles/`. Token budget: < 5K. The curator reads the cycle report, `_hot.md`, `index.md`, `glossary.md`, and any wiki files the cycle names by path — never the full tree. It produces a small diff proposal: candidate ADRs, glossary updates, lesson updates, primer touches, pattern-promotion borderlines, interface/flow/runbook/dependency/policy candidates.
- **Mode B — end-of-sprint compilation.** Invoked by `/specflow:wiki`. Token budget: the full wiki tree. The curator walks a twelve-step checklist: load tree → process the pending queue → cross-link integrity → stale detection → confidence drift (promotions and demotions) → pattern promotion candidates → deduplication → missing pages → interface surface scan → flow / runbook / dependency / policy scan → refresh `_hot.md` → update `index.md` → append `_log.md`.

Mode B supports a `--scope` filter to narrow the pass to one category (`decisions`, `domains`, `patterns`, `interfaces`, `flows`, `runbooks`, `dependencies`, `policies`, `risks`, `glossary`, or `lessons`) while still respecting the full-tree budget for cross-link integrity.

### The two-pass HITL discipline

Every curator run is two passes, and the two passes must not be combined.

1. **Pass 1 — Read + Propose.** No writes. Output is a single Markdown diff proposal listing new files, modified files, confidence changes, watchlist additions, format-imitation references, and questions for the owner. The diff also carries the queue flips, `_hot.md` rebuild, `index.md` update, and `_log.md` append.
2. **HITL gate.** The owner replies approve / modify / reject. Subset approvals ("apply ADR-007, defer the glossary edits") are treated as modify.
3. **Pass 2 — Apply.** Writes only the approved diff. On rejection, nothing is written.

The curator is read-only on production code and writes only inside `docs/wiki/wiki/` — with the single carve-out for `[PENDING] → [COMPILED]` flips on existing lines of `_pending.md`. The command guards against boundary violations defensively even though the agent's prompt body already forbids them.

### `/specflow:wiki-init`

The single entry point for adopting the wiki in a new project, repairing partial state, or bumping the schema version when this plugin ships a newer layout. Idempotent — safe to re-run.

What it does:

- Creates the `docs/wiki/sources/` (append-only) and `docs/wiki/wiki/` (curated) tree.
- Seeds the four control files (`_pending.md`, `_log.md`, `_hot.md`, `index.md`) plus `glossary.md` and `lessons.md`.
- Seeds nine category templates (one per `decisions/`, `domains/`, `patterns/`, `interfaces/`, `flows/`, `runbooks/`, `dependencies/`, `policies/`, `risks/`).
- Writes the wiki schema file at `docs/wiki/wiki/CLAUDE.md`, which is auto-loaded by Claude Code whenever an agent works in the wiki tree.
- Amends the project root `CLAUDE.md` with a `## Engineering Wiki` block between idempotent marker comments (`<!-- specflow:wiki-policies:start -->` / `<!-- specflow:wiki-policies:end -->`). Pass `--no-root-amend` to skip this.
- Pins the schema version (`schema_version: 1` today) in the wiki `CLAUDE.md` frontmatter, so future schema bumps are detected and proposed as migration diffs.

The command follows the same two-pass HITL discipline: it detects the current state, computes a delta against the target schema version, surfaces a diff proposal, and writes only on approval. Existing files are never overwritten — owner-edited content always wins, even during schema bumps.

## Integration

specflow is designed to compose with existing tools:

- **[triad](https://github.com/batidiane/triad)** — companion plugin, a multi-agent TDD orchestrator (DESIGN → RED → GREEN → REFACTOR → QUALITY). `/specflow:implement` invokes `/triad` automatically if it's installed, passing the Prompt Contract as the task spec. The wiki's per-cycle distillation (Mode A) is designed to fit in as a Phase 8.5 step that archives the cycle report under `docs/wiki/sources/cycles/` and queues it for the curator.
- **[superpowers](https://github.com/obra/superpowers)** — specflow is fully compatible. If `/triad` isn't available, `/specflow:implement` falls back to `superpowers:test-driven-development`. The `superpowers:brainstorming`, `writing-plans`, and `verification-before-completion` skills all pair naturally with the specflow pipeline.
- **Brainstorming** — upstream idea exploration (e.g. `superpowers:brainstorming`) feeds into `/specflow:specify`.
- **Code review** — the human gate at HITL Review integrates with your existing PR workflow.
- **Existing agents** — any tester, implementer, or architect agent you already use can consume Prompt Contracts as their exact spec, and any cycle they archive into `docs/wiki/sources/cycles/` becomes raw material for the curator.

## Inspiration & Related Work

- [EARS](https://alistairmavin.com/ears/) — Alistair Mavin's Easy Approach to Requirements Syntax ([2009 IEEE paper](https://ieeexplore.ieee.org/document/5328509/))
- [Prompt Contracts](https://medium.com/@enkidu.risk/prompt-contracts-my-ai-went-from-guessing-to-shipping-professional-80d92edeace2) — enkidurisk's four-section contract (GOAL / CONSTRAINTS / FORMAT / FAILURE CONDITIONS) for deterministic AI agent instructions
- [Karpathy's LLM wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) — the LLM-as-librarian second-brain pattern the engineering wiki implements
- [Give your AI unlimited, updated context](https://towardsdatascience.com/give-your-ai-unlimited-updated-context/) — Towards Data Science article on the control-file plumbing that makes the wiki loop reliable
- [spec-kit](https://github.com/github/spec-kit) — GitHub's comprehensive specification-driven development toolkit; specflow aims for a lighter alternative
- [superpowers](https://github.com/obra/superpowers) — Claude Code skills framework; specflow is fully compatible and can delegate to it
- [triad](https://github.com/batidiane/triad) — companion multi-agent TDD orchestrator; `/specflow:implement` prefers it when available

## Contributing

Issues and pull requests are welcome. Because specflow is a personal experiment first (see [Status & Scope](#status--scope)), expect opinionated review and a bias toward keeping the surface area small. If you want to add a new skill, a new wiki category, or a new command, open an issue first so we can discuss whether it belongs in core or in your own fork.

Every change to the canonical sources (`skills/`, `agents/`, `commands/`, `.github/prompts/`, `AGENTS.md`) propagates to both the Claude Code plugin and the Copilot installer — there is no separate per-platform branch to maintain.

## License

[MIT](./LICENSE)
