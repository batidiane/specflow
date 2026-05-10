---
name: wiki-curating
description: Provides the procedures the @wiki-curator agent follows to maintain the engineering wiki under docs/wiki/. Covers ADR drafting from cycle reports and owner decisions, glossary maintenance, domain primer distillation, pattern promotion under the "Name 3" rule, confidence calibration (owner-only promotions, curator-allowed demotions), stale-detection thresholds, cross-link integrity verification, the end-of-sprint compilation-pass checklist, and the four control files (_pending.md, _log.md, _hot.md, index.md) that coordinate cadence and provide audit / orientation. Use when drafting an ADR for the wiki, adding a glossary term, distilling a domain primer from cycle reports, evaluating a pattern for promotion, auditing confidence drift, running a wiki compilation pass, or processing the pending queue. Triggers on tasks involving ADR, wiki, curator, glossary, pattern promotion, knowledge base, domain primer, second brain, compilation pass, control files, pending queue, hot cache, or the docs/wiki/ tree.
---

# Wiki Curating — Procedures for the Engineering Wiki

The engineering wiki lives under `docs/wiki/` and is the LLM-curated second brain. This skill codifies the procedures the `@wiki-curator` agent (and any human contributor) follows when maintaining it. Format consistency outranks stylistic novelty: imitate the per-category templates (and any seed exemplars the project has shipped) rather than inventing new shapes.

The per-category templates seeded by `/specflow:wiki-init` are the canonical format reference:

- `docs/wiki/wiki/decisions/_template.md`
- `docs/wiki/wiki/domains/_template.md`
- `docs/wiki/wiki/patterns/_template.md`
- `docs/wiki/wiki/interfaces/_template.md`
- `docs/wiki/wiki/flows/_template.md`
- `docs/wiki/wiki/runbooks/_template.md`
- `docs/wiki/wiki/dependencies/_template.md`
- `docs/wiki/wiki/policies/_template.md`

When the project ships hand-written seed exemplars in any category (e.g., a polished ADR-001 that captures the project's voice), prefer those exemplars over the bare template — but never replace the template's section list or frontmatter contract.

---

## 1. ADR creation procedure

**When to draft an ADR.** Decisions with > 3-month consequences. Strong signals: an OWNER DECISION item resolved during a Triad cycle's HITL gate; a vendor / pricing / regulatory change that forces a structural choice; a security or privacy posture change; the supersession of a prior ADR.

**Where to source rationale.**

1. The cycle report under `docs/wiki/sources/cycles/` — for the immediate context and the alternatives discussed at the gate.
2. The owner decision artefact under `docs/wiki/sources/decisions/` — for the precise wording the owner used.
3. The project's high-level design / architecture / strategy documents (typical paths: `docs/<project>-architecture.md`, `docs/<project>-hld.md`, or whatever the project's `.specflow/config.md` references) — for cost / FinOps / cross-cloud rationale and structural framing.
4. The project's product specification — for behaviour-driven decisions.
5. EARS files under `docs/specflow/ears/` — for decisions that emerged from a spec-gap pass.

**Five required sections (in order).**

1. **Context** — what forced the decision. Reference the source artefact.
2. **Decision** — what was chosen, in **one sentence**.
3. **Alternatives rejected** — at least two, each with a one-sentence rationale.
4. **Consequences** — both positive AND negative. Negatives are mandatory; every decision pays a cost.
5. **Status** — `proposed` | `accepted` | `superseded by ADR-NNN`.

**Length target.** 300–500 body words (excluding YAML frontmatter and section headings). The template (`docs/wiki/wiki/decisions/_template.md`) defines the band.

**Frontmatter.** Always:

```yaml
---
title: ADR-NNN — <decision title>
tags: [adr, <area>, <subdomain>...]
last_updated: <YYYY-MM-DD>
source_issues: [<gh-issue-numbers>]
confidence: medium
---
```

New proposals default to `confidence: medium`; a proposal becomes `high` only after owner approval (see §5). Hand-written seed exemplars that document already-shipped, stable decisions may start at `high`, but only when the owner explicitly seeds them.

---

## 2. Domain primer procedure

**Never cold-write a primer.** A primer distils *experience*; cold-writing produces fiction. The minimum source pool is:

- **At least 2 cycle reports** under `docs/wiki/sources/cycles/` that touched the domain.
- The relevant project SKILL.md if one exists (e.g., `<plugin-or-project>/skills/<domain-slug>/SKILL.md`).
- The relevant section of the project's product specification.

**Six required sections (in order, per `docs/wiki/wiki/domains/_template.md`).**

1. Overview (3–5 sentences).
2. Key entities (types, structs, tables, store slices — link each to its source-of-truth file).
3. Data flow (where data enters, where it lives, where it leaves).
4. Boundaries — what this domain is NOT. Explicitly list adjacent domains.
5. Related patterns (links to `wiki/patterns/`).
6. Related ADRs (links to `wiki/decisions/`).

**Frontmatter.** `confidence: medium` is the default for a freshly distilled primer. Promote to `high` only after owner approval.

**Anti-pattern.** A primer that re-states the SKILL.md verbatim. The primer is for *future-Claude reading the wiki*; the SKILL is for *Claude executing a task*. Different audiences, different jargon density.

---

## 3. Pattern promotion procedure (the "Name 3" gate)

A pattern earns a page in `wiki/patterns/` **only when 3 known consumers exist in the codebase**. This rule is canonical (`docs/wiki/wiki/lessons.md` → "Name 3, build once").

**Promotion checklist.**

- [ ] List the file paths of all **three** consumers. Not types — paths.
- [ ] Verify each consumer actually uses the same mechanism, not similar-looking-but-different ones (mechanism similarity check).
- [ ] State why a shared abstraction is better than three local copies — concrete cost (test duplication, drift risk, future maintenance).
- [ ] Confirm the abstraction's contract is stable (not still mutating across consumers).

**If only 2 consumers exist:** open a *watchlist* comment in the curator's diff proposal. Never publish a 2-consumer pattern page. The watchlist line has the form:

```markdown
- **Watchlist:** `<pattern slug>` — 2 of 3 consumers present (`<path A>`, `<path B>`). Promote when a third lands.
```

**Five required sections (per `docs/wiki/wiki/patterns/_template.md`).**

1. When to use (with observable signals).
2. Mechanics (language- / framework-agnostic where possible).
3. Example in this codebase (real file path + 5–15 line snippet).
4. Anti-pattern (the shape that looks similar but breaks the contract).
5. Three known consumers (file paths).

---

## 3b. Interface page procedure

**Purpose.** The `interfaces/` category surfaces every public contract consumers depend on (HTTP endpoints, exported types/functions, GraphQL fields, RPC methods, CLI commands, event payloads). It is the bridge from "code we wrote" to "documentation we ship to product, partners, and external developers". Treat it as engineering's pre-doc layer for product documentation generation downstream.

**When to draft / update an interface page.**

- A cycle adds, modifies, deprecates, or changes the audience/stability of any **public** contract.
- A Mode B scan finds an exported public surface that has no `interfaces/` page yet.
- The canonical definition (OpenAPI YAML, TS types, proto, schema) drifts from the page.

**Source-of-truth discipline.** The interface page **summarises**; it never replaces the canonical source. Always link to the file that defines the contract (e.g., `path/to/openapi.yaml`, `path/to/types.ts`, `path/to/proto/foo.proto`). When the source diverges from the page, demote `confidence` and propose an update — never silently rewrite.

**Frontmatter.**

```yaml
---
title: <interface name>
tags: [interface, <area>, <kind>]
last_updated: <YYYY-MM-DD>
source_issues: [<gh-issue-numbers>]
confidence: medium
kind: <http | rpc | graphql | typescript | python | rust | go | sdk | cli | event | other>
stability: <stable | experimental | deprecated>
audience: <internal | external | both>
---
```

`kind`, `stability`, and `audience` are mandatory for interface pages. They drive downstream documentation generation (e.g., partner-facing docs filter `audience: external | both` and `stability: stable`).

**Six required sections** (per `docs/wiki/wiki/interfaces/_template.md`):

1. Overview (3–5 sentences, link to canonical source).
2. Contract (shape — endpoint / type / event signature; dense; link out for full schema).
3. Inputs (each with type, required/optional, semantic constraints).
4. Outputs (each with type, semantic meaning, including failure modes).
5. Example (one concrete request/response or call/return; 5–15 lines, real values).
6. Stability & versioning (status, breaking-change policy, known consumers, external integrators).

**Detection heuristics by stack.**

- **HTTP backend** — routes mounted to the framework (Fastify / Express / Hono / Echo / FastAPI / Axum / etc.).
- **Library** — public exports in a barrel/index file; everything in the library's published surface.
- **GraphQL** — schema definitions (`type Query`, `type Mutation`, `type Subscription`, plus their input/return types).
- **RPC** — `.proto` files, gRPC service definitions, JSON-RPC method registries.
- **CLI** — public subcommands; flags that affect external behaviour.
- **Event** — emitter topics, queue / channel / topic constants, message-bus subscribers.

**Anti-pattern.** A page that re-states the schema verbatim. The page is for *future-Claude reading the wiki* and for *product docs generators*; the schema file is for *runtime validation*. Different audiences, different shape.

**Demotion path.** When the canonical source diverges from the page (a field added, a status code removed, a deprecation), demote `confidence` immediately and propose an update — never silently rewrite. When `stability: stable` is broken by a non-additive change, propose a `kind`-appropriate versioning ADR.

---

## 3c. Flow page procedure

**Purpose.** End-to-end user journey from trigger to completion, including meaningful branches. Feeds onboarding docs, help-center articles, QA test plans, and support-team runbooks.

**When to draft / update.**

- A cycle implements or modifies a primary user journey (sign-up, onboarding, primary action, recovery).
- An EARS spec exists for the journey but no `flows/` page does.
- A UI/integration test plan covers the journey end-to-end.

**Source-of-truth discipline.** Distil from EARS specs + the cycle's UI/integration test plan + the actual implementation files (handlers, screens, hooks). Never cold-write a flow.

**Frontmatter extras.** `actor` (end-user / admin / system / partner) and `trigger` (one phrase describing what starts the flow).

**Five required sections** (per `flows/_template.md`): Overview, Preconditions, Steps (numbered happy path), Branches (meaningful divergences), Postconditions & related.

**Anti-pattern.** A page that re-states the EARS spec verbatim. The flow page is the *consequence* (what users observe step by step); the EARS spec is the *requirement* (what the system shall do). Different abstractions.

---

## 3d. Runbook procedure

**Purpose.** Operational procedures with verification and rollback. Feeds the on-call playbook, incident response docs, and admin guides.

**When to draft / update.**

- A cycle introduces or modifies an admin / migration / recovery procedure.
- An incident retrospective produces steps that should be reusable.
- A scheduled operation (key rotation, certificate renewal) is automated or documented.

**`last_drilled` discipline.** Tracks the last time the procedure was actually executed (drill or production). A runbook with `last_drilled: never` is documentation, not a runbook — surface in `_hot.md` health. A runbook not drilled in 90+ days surfaces as well.

**Frontmatter extras.** `severity` (routine / urgent / emergency), `audience` (on-call / sre / admin / developer), `last_drilled` (date or `never`).

**Six required sections** (per `runbooks/_template.md`): When to use, Preconditions, Procedure (numbered idempotent steps with expected output), Verification, Rollback, Related.

**Cold-writing forbidden.** A runbook must come from real procedure — a cycle that fixed an incident, an owner-decision capturing recovery steps, or a pre-flight checklist that has been exercised.

---

## 3e. Dependency page procedure

**Purpose.** Documents external services we **consume**. Distinct from `interfaces/` (what we expose). Feeds architecture diagrams, partner-facing docs, deps pages, and incident-blast-radius analysis.

**When to draft / update.**

- A cycle adds, removes, or changes the integration shape of an external service.
- Lock-file deltas across cycles signal a candidate (new package added that touches the network boundary).
- Vendor SLA / pricing / region changes that affect criticality or fallback.

**Frontmatter extras.** `kind` (saas / infrastructure / library / api / data-source / other), `criticality` (critical / high / medium / low), `fallback` (available / degraded / none).

**Six required sections** (per `dependencies/_template.md`): Overview, Integration shape, Usage shape (frequency / data volume / cost model), Failure modes & fallback, SLA / SLO, Related.

**Criticality discipline.** Drives blast-radius reasoning. A `critical` dependency without a documented `fallback` is itself a finding — surface as an OWNER DECISION in the diff proposal.

---

## 3f. Policy page procedure

**Purpose.** Non-functional cross-cutting constraints (data retention, rate limits, encryption posture, GDPR/CCPA stance, SLO commitments, access-control model). Distinct from ADRs (point-in-time decisions); policies are ongoing rules. Feeds compliance pages, trust pages, security overviews, and partner SLA negotiations.

**When to draft / update.**

- A regulatory requirement, contractual commitment, or owner-decision establishes a new ongoing rule.
- A cycle adds runtime enforcement code (rate-limiter, retention sweeper, audit logger) for an existing policy.
- A compliance audit surfaces a gap that needs documenting.

**Frontmatter extras.** `scope` (data / security / reliability / compliance / financial / other), `authority` (regulatory / contractual / internal), `enforcement` (runtime / review / manual / hybrid).

**Six required sections** (per `policies/_template.md`): Statement, Scope, Rationale (link to authority artefact), Enforcement (link to enforcement file(s)), Exceptions (with approval path), Related.

**Cold-writing forbidden.** Policies must trace to a regulatory document, contractual clause, owner-decision artefact, or shipped enforcement code. A policy without enforcement is a wish — surface as an OWNER DECISION ("Statement made; no enforcement found").

---

## 3g. Risk page procedure

**Purpose.** Threat-model entries / known-risk register. Tracks security, privacy, operational, business, compliance, and supply-chain risks with severity, likelihood, mitigation, and lifecycle status. Feeds security overviews, audit prep, threat-model docs, and incident-blast-radius analysis.

**When to draft / update.**

- A `@security-auditor` finding in a cycle report names a risk that is not yet in the register.
- An ADR has a residual-risk callout that is not tracked.
- A policy admits an exception path that itself constitutes ongoing risk.
- An incident retrospective surfaces a class of failure that should be tracked.
- An explicit owner risk-acceptance during a HITL gate.

**Frontmatter extras.** `kind` (security / privacy / operational / business / compliance / supply-chain / other), `severity` (critical / high / medium / low), `likelihood` (high / medium / low), `status` (open / mitigated / accepted / transferred / closed).

**Six required sections** (per `risks/_template.md`): Statement, Scope/Assets, Threat/Cause/Conditions, Impact (CIA / user-facing / business / blast-radius), Mitigation (current / planned / residual), Related.

**Mitigation discipline.** All three mitigation layers (current controls, planned controls, residual risk) are required. A risk with `status: open` and an empty Mitigation section is a finding — surface as an OWNER DECISION in the curator's diff. A risk with `status: accepted` MUST name the owner and the acceptance date in the residual-risk subsection.

**Cold-writing forbidden.** Risks must trace to a security-auditor finding, an ADR with a residual-risk callout, a policy that admits exceptions, an incident retrospective, or an explicit owner risk-acceptance. Speculative risks belong in a threat-modelling exercise, not the wiki.

**Lifecycle.** `status` transitions are owner-driven. The curator may propose `open → mitigated` when a planned control ships and the cycle that shipped it is referenced. The curator may NEVER propose `open → accepted` or `open → closed` unilaterally.

---

## 4. Glossary procedure

**One H2 per term. One-sentence definition. Optional `→ See:` cross-reference.** Imitate the existing entries' brevity; the glossary is scanned, not read.

**No jargon-loop.** A definition cannot reference another term that is itself undefined or defined only via this term. Walk the cross-references; if you arrive back at the starting term without a concrete definition, the chain is broken — fix the loop.

**When to add a term.** Used 3+ times across CLAUDE.md, the Product Spec, the Pre-HLD, or cycle reports without a glossary entry. Used 5+ times across the wiki without an entry → also propose a primer page (the curator's Mode B "missing pages" check).

**When to delete or merge.** Two entries cover the same concept → merge into one canonical entry; the curator surfaces this in Mode B's deduplication step.

---

## 5. Confidence calibration procedure

The `confidence` field on every wiki file is the trust dial. Three values:

- `high` — owner-confirmed and stable; safe to cite externally.
- `medium` — derived from documented sources but not yet battle-tested.
- `low` — inferred from a single cycle or external article; treat as hypothesis until validated.

**Promotion criteria (owner-only).** A file moves to `high` only by owner approval, with rationale citing at least:

- The number of subsequent cycles that did not regress the file's claims.
- Specific ADRs / cycle paths that validated it.
- Any contradicting signals considered and dismissed.

The curator MAY *propose* promotion in a Mode B diff. The curator may NEVER apply promotion unilaterally. Phrase the proposal: *"Propose: confidence medium → high. Rationale: validated by ADR-014, ADR-016, and 2 cycles without regression."*

**Demotion criteria (curator-allowed).** A file moves down a step when a more recent cycle contradicts its claims. Demotion is a safety move; the curator applies it during Mode B with rationale in the diff. Examples:

- An ADR whose alternative is reconsidered → demote `high → medium` until a successor ADR confirms or supersedes.
- A primer whose data flow no longer matches the code → demote `medium → low` and propose an update.

**All confidence changes appear in the diff proposal — never silent.**

---

## 6. Stale detection procedure

**Default threshold: 90 days since `last_updated`.** A file older than that with cycle activity in its domain is a stale candidate.

**Signals beyond the threshold.**

- A referenced cycle has shipped to `main` since the file was last touched.
- An ADR was superseded by another ADR (the predecessor's `status` should already say so; if it doesn't, demote the predecessor and update its status).
- A source skill under `/workspace/.claude/skills/<domain>/` has been rewritten — its primer should likely be re-distilled.
- Frontmatter `source_issues: []` is non-empty and any of those issues has been closed by a cycle that touched files outside the primer's surface.

**Detection commands (read-only).**

- `git log --since=<last_updated> -- <file or domain path>` — domain activity since the file was last touched.
- `git log --follow <wiki file>` — file's own touch history.
- `grep -r "<term>" docs/wiki/wiki/ | wc -l` — usage frequency for missing-page detection.

**Outcome.** Surface stale candidates in the Mode B diff proposal with one of: *"Refresh recommended"*, *"Demote confidence"*, *"Mark superseded"*. Apply only on owner approval.

---

## 7. Cross-link integrity procedure

**Every relative link in every wiki file must resolve to an existing file.**

**Detection.** For each `*.md` under `docs/wiki/wiki/`:

1. Extract every Markdown link of the form `[text](relative/path.md)` or `(relative/path.md#anchor)`.
2. Resolve relative to the link source's directory.
3. Confirm the target file exists; for anchors, confirm the H1/H2/H3 exists in the target.

**Reporting format (in the Mode B diff proposal).**

```markdown
### Cross-link integrity

| Source file | Broken link | Target | Reason |
| --- | --- | --- | --- |
| `wiki/decisions/ADR-007-...md` | `(patterns/clock-injection.md)` | does not exist | pattern not yet promoted |
```

**Orphaned-page detection.** Any wiki file not linked from `index.md` or any ADR is orphaned. Surface as:

```markdown
- **Orphan:** `wiki/<path>.md` — not referenced from `index.md` or any other wiki file.
```

**Resolution.** The curator proposes either a fix (add the link) or a removal (delete the page) — never silent.

---

## 8. Compilation-pass checklist (Mode B, end-of-sprint)

The full Mode B sequence the curator walks in order. Run this checklist literally; do not skip steps.

- [ ] **1. Load the full wiki tree.** Read every file under `docs/wiki/wiki/`.
- [ ] **2. Process the pending queue.** Read `docs/wiki/sources/_pending.md`. For every `[PENDING]` entry, run Mode A candidate-detection on the named source artefact and add its diffs to this Mode B proposal. Each processed line gets flipped to `[COMPILED — YYYY-MM-DD by mode-B]` (§9.1).
- [ ] **3. Cross-link integrity.** Every relative link resolves. Report broken links and orphaned pages (§7).
- [ ] **4. Stale detection.** Any file with `last_updated` > 90 days where the domain has had cycles since (§6).
- [ ] **5. Confidence drift — promotions.** Any `low`-confidence file validated by 2+ subsequent cycles → propose `low → medium`. Any `medium` file with multiple supporting cycles → propose `medium → high` (owner-only).
- [ ] **6. Confidence drift — demotions.** Any file contradicted by a more recent cycle → apply demotion in the proposed diff.
- [ ] **7. Pattern promotion candidates.** Scan for repeated mechanics across 3+ files in the codebase that lack a `patterns/` page (§3). Promote when "Name 3" is satisfied; watchlist when only 2.
- [ ] **8. Deduplication.** Two glossary entries for the same concept; two ADRs covering overlapping decisions; the same lesson under two H2s in `lessons.md`.
- [ ] **9. Missing pages.** Any glossary term referenced 5+ times in `wiki/` without its own primer page → propose a primer (§2 still applies — never cold-write).
- [ ] **10. Interface surface scan.** Walk the codebase for public contracts (per §3b's heuristics-by-stack). For each missing or out-of-date page, propose a new entry or an update; demote pages whose canonical source has drifted.
- [ ] **11. Flow / runbook / dependency / policy / risk scan.** Walk per §3c–§3g detection rules. Specifically:
  - Flows: primary EARS specs without a journey page; UI test plans for cross-screen flows.
  - Runbooks: admin/migration/recovery scripts referenced in incidents but not yet written up; runbooks with `last_drilled: never` or not drilled in 90+ days surface in `_hot.md` health.
  - Dependencies: lock-file deltas across cycles, packages crossing the network boundary without a page, vendor SLA changes.
  - Policies: non-functional constraints declared in `.specflow/config.md` `## Project Constraints` or referenced in EARS specs without a page; runtime enforcement code without a corresponding policy page.
  - Risks: `@security-auditor` findings in cycle reports without a risk page; high-severity TODOs/FIXMEs that flag accepted risk; threat-model gaps surfaced by ADRs/policies; risks with `status: open` surface in `_hot.md`.
- [ ] **12. Refresh `_hot.md`.** Rebuild from current state per §9.3.
- [ ] **13. Update `index.md`.** Re-list every page under `decisions/`, `domains/`, `patterns/`, `interfaces/`, `flows/`, `runbooks/`, `dependencies/`, `policies/`, `risks/` per §9.4.
- [ ] **14. Append `_log.md` entry.** Compose the audit entry per §9.2.

After step 14, produce the diff proposal in the curator agent's §5 format. **STOP. Wait for owner approval before applying.**

---

## 9. Control files (Karpathy second-brain plumbing)

The wiki has four control files that coordinate cadence and provide audit / orientation. They are seeded by `/specflow:wiki-init`; this section defines how the curator reads and updates them at runtime.

### 9.1 `docs/wiki/sources/_pending.md` — compilation queue

**Purpose.** Bridges per-cycle distillation (Mode A) with end-of-sprint compilation (Mode B). Without this file, a Mode A skip (token budget abort, time pressure, agent crash) silently loses a cycle's contribution to the curated wiki.

**Format.** One line per source artefact:

```
- YYYY-MM-DD — <relative path under docs/wiki/sources/> — [STATUS]
```

Statuses:

- `[PENDING]` — archived but not yet distilled.
- `[COMPILED — YYYY-MM-DD by mode-A]` — distilled by per-cycle Mode A.
- `[COMPILED — YYYY-MM-DD by mode-B]` — distilled by end-of-sprint Mode B.
- `[SKIPPED — YYYY-MM-DD <reason>]` — explicitly excluded by the owner.

**Curator's permitted mutation.** The curator may **only** flip status markers on existing lines. It may not add lines (the TDD orchestrator does that), delete lines, or reorder lines. This is the single carve-out for `sources/` writes.

**Mode A read.** Mode A reads its own cycle's line and confirms `[PENDING]` before proceeding. Missing line → abort and surface to the orchestrator.

**Mode B read.** Mode B reads the full file as the **first** step (after loading the wiki tree) and processes every `[PENDING]` entry before walking the lint checklist.

**Backlog warning.** If `[PENDING]` count exceeds 10, surface a warning in `_hot.md` health.

### 9.2 `docs/wiki/wiki/_log.md` — append-only audit trail

**Purpose.** The only persistent record of what the curator has done. Used for drift detection (no Mode B in 60 days = stale risk), debuggability (grep for the run that wrote a strange page), and confidence-trend analysis (files that bounce between levels).

**Format.**

```markdown
## [YYYY-MM-DD HH:MM] mode-{A|B} — <subject> — wrote <K> / proposed <P>
- Wrote: <path> — <one-line>
- Proposed (deferred): <path> — <reason>
- Confidence changes: <file> <from>→<to> (<promotion|demotion>)
- Watchlist: <slug> — <consumer count>
```

Subject:

- Mode A → cycle issue ID (`issue #142`).
- Mode B → sprint identifier or date range (`sprint-22` or `2026-05-03..2026-05-10`).

**When to log.**

- Every successful Pass 2 run appends an entry. The entry appears in the diff proposal alongside the rest; the owner approves it as part of the diff.
- A no-op Mode B run still logs (`- No changes; checklist clean.`) so freshness can be measured.
- A no-op Mode A run does not log unless explicitly skipped by owner decision.

**Append-only.** Never edit historical entries. Corrections go in a new entry that references the original by timestamp.

### 9.3 `docs/wiki/wiki/_hot.md` — hot cache (< 500 tokens)

**Purpose.** The first file any agent reads when consulting the wiki. Daily-briefing style — what's load-bearing right now.

**Refreshed only by Mode B.** Mode A does not touch this file. Single source of truth keeps Mode A cheap.

**Sections (rebuilt on each Mode B run).**

- **Active decisions (last 30 days)** — ADRs whose `last_updated` falls in the window. `Title — confidence — status`.
- **Open OWNER DECISIONS** — pattern-promotion borderlines, confidence-promotion candidates, primer-refresh proposals deferred by the owner. The owner who applies a deferred item should also strike it here.
- **Recent confidence changes** — last 30 days of promotions and demotions; `file — from→to — date — rationale`.
- **Watchlist patterns (2 of 3 consumers)** — `slug — known consumers (paths)`.
- **Health** — pending queue depth, days since last Mode B, days since last Mode A, stale primer count.

**Token discipline.** Target < 500 tokens. If a section grows beyond its share, summarise — link out to the full file. The whole point of `_hot.md` is cheap orientation.

**No silent updates.** The full new content of `_hot.md` appears in the Mode B diff proposal.

### 9.4 `docs/wiki/wiki/index.md` — catalog

**Purpose.** The catalog. Read by agents after `_hot.md` and before specific files.

**Refreshed by Mode B.** Re-listed in full each run; the diff proposal carries the full new content.

**Sections.**

- Decisions (ADRs) — `[ADR-NNN — title](decisions/ADR-NNN-slug.md) — confidence: <level>`.
- Domain primers — `[<domain>](domains/<slug>.md) — confidence: <level>`.
- Patterns — `[<pattern>](patterns/<slug>.md) — 3 consumers`.
- Interfaces — `[<name>](interfaces/<slug>.md) — kind: <kind> — stability: <s> — audience: <a> — confidence: <level>`.
- Flows — `[<name>](flows/<slug>.md) — actor: <actor> — confidence: <level>`.
- Runbooks — `[<name>](runbooks/<slug>.md) — severity: <s> — last_drilled: <date> — confidence: <level>`.
- Dependencies — `[<name>](dependencies/<slug>.md) — kind: <k> — criticality: <c> — fallback: <f> — confidence: <level>`.
- Policies — `[<name>](policies/<slug>.md) — scope: <s> — authority: <a> — enforcement: <e> — confidence: <level>`.
- Risks — `[<name>](risks/<slug>.md) — kind: <k> — severity: <s> — likelihood: <l> — status: <st> — confidence: <level>`.
- Glossary & lessons — fixed entries.
- Control files — fixed entries.

### 9.5 Read order (mandatory at runtime)

When the curator (or any other agent) consults the wiki:

1. `_hot.md` first.
2. `index.md` second.
3. Specific files only after the first two.

The curator enforces this order on itself. Mode A explicitly reads `_hot.md` before any candidate detection.

---

## Format imitation reminders

- New ADRs follow `docs/wiki/wiki/decisions/_template.md` exactly. 300–500 body words; five sections.
- Frontmatter required on every curated page: `title`, `tags`, `last_updated`, `source_issues`, `confidence`. Per-category extras documented in §3b–§3f.
- When the project ships seed exemplars (e.g., a hand-written ADR-001), imitate those exemplars over the bare template — the seeds carry the project's voice.
- The curator is a stylistic conservative. A "better" idea about format goes in the diff as an OWNER DECISION — never a silent change.
