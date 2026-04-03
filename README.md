# specflow

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin for **Specification-Driven Development (SDD)**.

specflow turns natural language into unambiguous requirements, wraps them in executable Prompt Contracts, organizes them into a GitHub-native hierarchy, and tracks everything through a Kanban workflow — all without leaving your terminal.

## Why

AI-assisted development produces inconsistent results when requirements are informal. Vague specs lead to hallucinated features, missed edge cases, and untraceable work. specflow solves this by enforcing a formal pipeline:

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
```

Every step produces a persistent markdown artifact. The files are the source of truth — not conversation memory.

## Core Principles

### Spec-as-Source
Every GitHub issue traces to a Prompt Contract, which traces to an EARS requirement, which traces to a spec document section. Nothing is invented by AI.

### EARS Requirements
[Easy Approach to Requirements Syntax](https://ieeexplore.ieee.org/document/6146379) eliminates ambiguity by constraining natural language into six patterns:

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
- **FORMAT** — Exact file paths, exported symbols, test file locations.
- **FAILURE CONDITIONS** — What makes the output unacceptable. Each maps to a REQ-### and becomes a TDD test spec.

### Artifacts Over Memory
Every pipeline step writes a markdown file before the next step reads it. Restartable, manually editable, version-controlled. No reliance on conversation context.

### Explicit Gates
GitHub mutations are never automatic. The publisher previews every `gh` command and waits for human confirmation. The Kanban workflow has a mandatory human gate (HITL Review) between AI implementation and merge.

## Installation

```bash
# In Claude Code
/install-plugin batidiane/specflow
```

Then add the marketplace to your `~/.claude/settings.json` if prompted:

```json
{
  "extraKnownMarketplaces": {
    "specflow": {
      "source": {
        "source": "github",
        "repo": "batidiane/specflow"
      }
    }
  }
}
```

## Quick Start

### 1. Initialize your project

```
/specflow:init
```

Analyzes your project's CLAUDE.md, repo structure, and GitHub metadata to generate `.specflow/config.md`. Asks targeted questions for anything it can't infer.

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

## Integration

specflow is designed to compose with existing tools:

- **TDD workflows** — `/specflow:implement` delegates to `superpowers:test-driven-development` or your project's TDD command
- **Brainstorming** — upstream idea exploration feeds into `/specflow:specify`
- **Code review** — human gate at HITL Review integrates with your PR workflow
- **Existing agents** — tester, implementer, architect agents receive Prompt Contracts as their exact spec

## Inspiration

- [EARS](https://ieeexplore.ieee.org/document/6146379) — Alistair Mavin's Easy Approach to Requirements Syntax
- [Prompt Contracts](https://arxiv.org/abs/2311.18000) — Deterministic specification framework for LLM agents
- [speckit](https://github.com/speckit/speckit) — Specification-driven development toolkit
- [superpowers](https://github.com/obra/superpowers) — Claude Code skills library (specflow is compatible)

## License

MIT
