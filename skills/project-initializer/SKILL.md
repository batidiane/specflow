---
name: project-initializer
description: Generates or updates .specflow/config.md by analyzing the project's CLAUDE.md, repo structure, and GitHub metadata. Use when the user runs /specflow:init or when config is missing.
---

# Project Initializer

You generate the `.specflow/config.md` configuration file for a project by analyzing
existing project files and asking the user targeted questions for anything you can't infer.

## Prime Directive

Infer as much as possible from the project. Only ask questions when information is genuinely
missing or ambiguous. Never invent project constraints — derive them from CLAUDE.md, existing
config files, or explicit user input.

---

## Step 1: Gather Project Context

Read these files in order (skip any that don't exist):

1. **CLAUDE.md** / **AGENTS.md** — project constitution, stack, rules, architecture
2. **Project manifests** — project name, language stack, build system (see § Language Detection Table below)
3. **README.md** — project description
4. **.github/** / **.ai/** — workflows, issue templates (hints at labels and conventions)
5. **docs/** — specification documents (scan for `*.md` files)
6. **$ARGUMENTS** — user-provided project description (if any)

Also run:
```bash
# Get GitHub remote info
git remote get-url origin 2>/dev/null
# Get repo owner and name
gh repo view --json owner,name,projectsV2 2>/dev/null
```

### Language Detection Table

Detect **every** manifest present — presence is signal even when contents can't be parsed. Multiple manifests at the repo root = polyglot / monorepo (record both stacks; pick a primary via the heuristic below).

| Manifest file(s) | Language / stack | Project name extraction |
|---|---|---|
| `package.json` | JavaScript / Node.js (TypeScript if `tsconfig.json` also present) | `"name"` field |
| `tsconfig.json` | TypeScript (companion — usually with package.json) | use `package.json` name |
| `deno.json` / `deno.jsonc` | TypeScript / JavaScript (Deno) | `"name"` field |
| `pyproject.toml` | Python (Poetry / PEP 621) | `[project] name` or `[tool.poetry] name` |
| `setup.py` / `setup.cfg` | Python (legacy) | `setup(name=...)` or `[metadata] name =` |
| `requirements.txt` / `Pipfile` | Python (no name in file) | directory name |
| `go.mod` | Go | `module <path>` — last path segment |
| `Cargo.toml` | Rust | `[package] name =` |
| `pom.xml` | Java (Maven) | `<artifactId>` (or `<name>` if present) |
| `build.gradle` / `build.gradle.kts` | Java or Kotlin (Gradle) | `rootProject.name` (from `settings.gradle*`), else directory |
| `settings.gradle` / `settings.gradle.kts` | Java / Kotlin (multi-module Gradle) | `rootProject.name =` |
| `CMakeLists.txt` | C / C++ (CMake) | `project(<name> ...)` argument |
| `Makefile` (no CMake) | C / C++ (Make — last-resort signal) | directory name |
| `meson.build` | C / C++ (Meson) | `project('<name>', ...)` |
| `conanfile.txt` / `conanfile.py` | C / C++ (Conan deps) | `name = ` in conanfile.py |
| `vcpkg.json` | C / C++ (vcpkg deps) | `"name"` field |
| `*.csproj` / `*.sln` | C# / .NET | filename minus extension |
| `global.json` | .NET SDK pin | use `.csproj` name |
| `Gemfile` / `*.gemspec` | Ruby | `.gemspec` `name` field, else directory |
| `composer.json` | PHP | `"name"` field |
| `Package.swift` | Swift / SwiftPM | `name:` arg to `Package(...)` |
| `*.xcodeproj/` / `*.xcworkspace/` | Swift / Objective-C (Xcode) | directory name minus `.xcodeproj` |
| `mix.exs` | Elixir | `app: :<name>` in `project/0` |
| `build.sbt` | Scala (sbt) | `name :=` or directory |
| `pubspec.yaml` | Dart / Flutter | `name:` |
| `stack.yaml` / `*.cabal` | Haskell | `.cabal` `name:` |
| `Project.toml` | Julia | `name =` |
| `dune-project` | OCaml | `(name <x>)` |
| `build.zig` | Zig | `addExecutable(.{ .name = ... })` |
| `flake.nix` / `default.nix` | Nix (build descriptor — usually wraps an inner stack) | use inner stack's name |
| `DESCRIPTION` (R-style fields) / `renv.lock` | R | `Package:` field in `DESCRIPTION` |
| `*.tf` at root | Terraform / HCL (infra) | directory name |
| `Dockerfile` | containerization layer (signal, not primary stack) | — |

**Polyglot / monorepo heuristic (which stack is "primary"):**

1. Root manifest beats subdirectory manifest. (`./package.json` > `./services/api/package.json`.)
2. If multiple manifests at the same level (e.g. `package.json` + `go.mod` at root), the one whose top-level source directory holds the most files wins (`src/`, `lib/`, `cmd/`, etc.).
3. If still ambiguous, record both stacks and ask the user which is primary for SDD purposes.
4. Build descriptors (`Dockerfile`, `flake.nix`, `Makefile` alone) are NEVER primary — they wrap or build another stack.

**Output:** record `stack: <primary-language>` in the config; if polyglot, add a `secondary-stack:` line.

---

## Step 2: Extract What You Can

From the gathered context, attempt to fill every config section:

### Project Identity
- **name**: from the project's primary manifest (see § Language Detection Table for the per-language extraction rule), else CLAUDE.md project name, else repo name from `gh repo view`.
- **stack**: the primary language/stack detected. Use the form `<language> (<build tool / runtime>)` when relevant (e.g. `Python (Poetry)`, `Java (Maven)`, `C++ (CMake)`, `TypeScript (Node.js)`). For polyglot repos, additionally record `secondary-stack:` lines.
- **owner**: from git remote URL or `gh repo view`
- **repo**: from git remote URL or `gh repo view`
- **github-project-id**: from `gh project list --owner {owner} --format json`
- **github-project-number**: same source

### Spec Documents
- Scan `docs/` for specification documents (*.md files that look like specs)
- Look for common patterns: "Product Spec", "API Design", "Architecture", "PRD"
- Each gets a label and path entry

### Epic Definitions
- If CLAUDE.md defines phases, milestones, or sprints → use those
- If a roadmap or project board exists → derive from there
- Otherwise → ask the user

### Domain Labels
- If CLAUDE.md defines domain areas (API, UI, CORE, etc.) → use those
- If directory structure implies domains (api/, mobile/, infra/) → derive labels
- Common defaults: [API], [UI], [CORE], [INFRA], [DATA], [TEST]

### Kanban Columns
- Always use the specflow standard: Icebox / To Do (Ready) / In Progress (Triad Active) / HITL Review / Done

### Project Constraints
- Extract from CLAUDE.md: testing rules, architecture rules, style rules, security rules
- These are the NON-NEGOTIABLE rules injected into every Prompt Contract
- Focus on rules that affect implementation: coverage thresholds, forbidden patterns, required libraries

### Scope Discipline Constraints
- **Always emit the standard block** (SCOPE-001..006). These do not come from CLAUDE.md —
  they are specflow's built-in pipeline discipline rules and apply to every project.
- Do not ask the user about them. Do not omit them. Write them verbatim (see Step 4).

### Out of Scope
- If CLAUDE.md or specs define "out of scope" or "Phase 2" items → use those
- If nothing found → leave empty, ask the user

---

## Step 3: Identify Gaps and Ask Questions

For each section you couldn't fully populate, ask a targeted question. Group all questions
into a single prompt — don't ask one at a time.

**Question format:**
```
I've analyzed your project and can generate most of the specflow config.
I need a few clarifications:

1. **GitHub Project:** I found project "{name}" (#{number}). Is this the one
   to use for specflow task tracking? [yes / other project name]

2. **Epic Definitions:** I didn't find phase/milestone definitions. How do you
   want to organize your work? Examples:
   - By feature area: "Auth", "Dashboard", "API"
   - By phase: "MVP", "Beta", "Launch"
   - By sprint: "Sprint 1", "Sprint 2"
   Please list your Epics with a one-line scope each.

3. **Out of Scope:** Are there features or areas that should be explicitly
   excluded from specflow planning?
```

**Rules for questions:**
- Never ask about something you already found in CLAUDE.md or project files
- Never ask about Kanban Columns (always use the standard set)
- If you have a strong inference, present it as a confirmation: "I'll use X — correct?"
- Maximum 5 questions per init. If more unknowns exist, use sensible defaults and note them.

---

## Step 4: Generate Config File

Write to `.specflow/config.md`:

```markdown
# specflow config

## Project Identity
- name: {project-name}
- stack: {primary-language-stack, e.g. "TypeScript (Node.js)", "Python (Poetry)", "Java (Maven)"}
- secondary-stack: {optional — for polyglot repos, additional stacks detected}
- owner: {github-owner}
- repo: {github-repo}
- github-project-id: {PVT_...}
- github-project-number: {integer}

## Spec Documents
- {label}: {path}
- {label}: {path}

## Epic Definitions
- {epic-name}: {one-line scope}
- {epic-name}: {one-line scope}

## Domain Labels
- [{LABEL}]: {scope description}
- [{LABEL}]: {scope description}

## Kanban Columns
- Icebox
- To Do (Ready)
- In Progress (Triad Active)
- HITL Review
- Done

## Project Constraints
- {constraint from CLAUDE.md or user input}
- {constraint from CLAUDE.md or user input}

## Scope Discipline Constraints
SCOPE-001: Fix findings inline if < 30 min and files are in the PR diff.
SCOPE-002: Target zero new issues per PR. Justify any exception in the PR description.
SCOPE-003: Before creating any issue, search existing issues first
           (`gh issue list --search "<keywords>" --state open`). Duplicate issues are a defect.
SCOPE-004: Style preferences (switch vs map, naming nits in untouched files) are SKIP,
           not DEFER. Do not track them as follow-ups.
SCOPE-005: Spec gaps route through the specflow pipeline
           (`/specflow:specify` → `/specflow:contract` → `/specflow:plan` → `/specflow:publish`),
           not standalone GitHub issues.
SCOPE-006: When vendor docs conflict with contract FORMAT, follow vendor docs.
           Flag the deviation in the PR description.

## Out of Scope
- {item}
- {item}
```

---

## Step 5: Create Artifact Directories

Create the specflow artifact directories if they don't exist:

```
docs/specflow/ears/.gitkeep
docs/specflow/contracts/.gitkeep
docs/specflow/plans/.gitkeep
docs/specflow/published/.gitkeep
```

Only create directories that don't already exist. Don't overwrite existing .gitkeep files
or any existing artifacts.

---

## Step 6: Update Mode (Config Already Exists)

If `.specflow/config.md` already exists:

1. Read the existing config
2. Read current project state (CLAUDE.md, repo structure, GitHub metadata)
3. Compare: identify sections that are outdated or missing new information
4. **Check for Scope Discipline block**: if `## Scope Discipline Constraints` section is
   missing from the existing config, flag it as a REQUIRED update (not optional). The full
   SCOPE-001..006 block from Step 4 must be added — these are specflow pipeline rules,
   not project-specific preferences.
5. Present a diff-style summary:
   ```
   ## specflow config update

   ### No changes needed
   - Project Identity ✓
   - Kanban Columns ✓

   ### Updates found
   - Spec Documents: found new file docs/CocoMind Migration Strategy.md — add?
   - Project Constraints: CLAUDE.md added "All HTTP requests must have timeouts" — add?
   - Epic Definitions: no changes

   ### Required updates (specflow pipeline rules)
   - Scope Discipline Constraints: SECTION MISSING — will add SCOPE-001..006 block

   ### Missing (still need input)
   - github-project-id: still not set — discover now? [yes/no]

   Apply these updates? [yes / selective / no]
   ```
5. On `yes`: apply all updates
6. On `selective`: ask which updates to apply
7. On `no`: abort

---

## Step 7: Report to User

```
specflow config {created / updated}.
Output: .specflow/config.md

Sections populated:
✓ Project Identity: {owner}/{repo} — stack: {detected-stack}
✓ Spec Documents: {N} documents linked
✓ Epic Definitions: {M} epics defined
✓ Domain Labels: {P} labels
✓ Kanban Columns: standard (5 columns)
✓ Project Constraints: {Q} constraints
✓ Scope Discipline Constraints: SCOPE-001..006 (specflow pipeline rules)
✓ Out of Scope: {R} items

[If artifact directories were created]:
✓ Created docs/specflow/ artifact directories

Recommended (manual — CLAUDE.md is yours to own):
Mirror the Scope Discipline rules into CLAUDE.md §Development Rules so every
agent reads them on every task. Suggested block:

  ### Scope Discipline
  - Fix inline, don't defer: < 30 min + files in PR diff → fix now, no follow-up issue.
  - Zero new issues per PR is the target. Justify any exception.
  - Search before creating: `gh issue list --search "<keywords>" --state open` first.
  - Style preferences are SKIP, not DEFER. Do not track them.
  - Don't touch what you didn't break — findings outside the PR diff are out of scope.
  - Spec gaps use the specflow pipeline, not standalone GitHub issues.
  - Vendor best practices override contract FORMAT when they conflict; flag in PR.

Next: /specflow:specify [feature description]
```
