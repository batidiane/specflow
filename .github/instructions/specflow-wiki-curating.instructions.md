---
applyTo: "docs/wiki/**"
description: "Procedures the wiki-curator follows to maintain the engineering wiki under docs/wiki/. Covers ADR drafting, glossary maintenance, domain primer distillation, pattern promotion under the Name 3 rule, confidence calibration, stale detection, cross-link integrity, the end-of-sprint compilation-pass checklist, and the four control files."
---

# Wiki Curating — Procedures for the Engineering Wiki

The engineering wiki lives under `docs/wiki/` and is the LLM-curated second brain. This file codifies the procedures the `wiki-curator` chat mode (and any human contributor) follows when maintaining it. **Format consistency outranks stylistic novelty:** imitate the per-category templates (and any seed exemplars the project has shipped) rather than inventing new shapes.

The per-category templates seeded by `/specflow-wiki-init` are the canonical format reference:

- `docs/wiki/wiki/decisions/_template.md`
- `docs/wiki/wiki/domains/_template.md`
- `docs/wiki/wiki/patterns/_template.md`
- `docs/wiki/wiki/interfaces/_template.md`
- `docs/wiki/wiki/flows/_template.md`
- `docs/wiki/wiki/runbooks/_template.md`
- `docs/wiki/wiki/dependencies/_template.md`
- `docs/wiki/wiki/policies/_template.md`

When the project ships hand-written seed exemplars in any category (e.g., a polished ADR-001 capturing the project's voice), prefer those exemplars over the bare template — but never replace the template's section list or frontmatter contract.

---

## 1. ADR creation procedure

**When to draft an ADR.** Decisions with > 3-month consequences. Strong signals: an OWNER DECISION item resolved during a Triad cycle's HITL gate; a vendor / pricing / regulatory change that forces a structural choice; a security or privacy posture change; the supersession of a prior ADR.

**Where to source rationale.**

1. The cycle report under `docs/wiki/sources/cycles/` — for the immediate context and the alternatives discussed at the gate.
2. The owner decision artefact under `docs/wiki/sources/decisions/` — for the precise wording the owner used.
3. The project's high-level design / architecture / strategy documents — for cost / FinOps / cross-cloud rationale and structural framing.
4. The project's product specification — for behaviour-driven decisions.
5. EARS files under `docs/specflow/ears/` — for decisions that emerged from a spec-gap pass.

**Five required sections (in order).**

1. **Context** — what forced the decision. Reference the source artefact.
2. **Decision** — what was chosen, in **one sentence**.
3. **Alternatives rejected** — at least two, each with a one-sentence rationale.
4. **Consequences** — both positive AND negative. Negatives are mandatory; every decision pays a cost.
5. **Status** — `proposed` | `accepted` | `superseded by ADR-NNN`.

**Length target.** 300–500 body words (excluding frontmatter and section headings).

**Frontmatter.**

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

**Never cold-write a primer.** A primer distils *experience*; cold-writing produces fiction. Minimum source pool:

- **At least 2 cycle reports** under `docs/wiki/sources/cycles/` that touched the domain.
- The relevant project SKILL or instructions file if one exists.
- The relevant section of the project's product specification.

**Six required sections.**

1. Overview (3–5 sentences).
2. Key entities (types, structs, tables, store slices — link each to its source-of-truth file).
3. Data flow (where data enters, where it lives, where it leaves).
4. Boundaries — what this domain is NOT. Explicitly list adjacent domains.
5. Related patterns (links to `wiki/patterns/`).
6. Related ADRs (links to `wiki/decisions/`).

**Frontmatter.** `confidence: medium` is the default for a freshly distilled primer. Promote to `high` only after owner approval.

**Anti-pattern.** A primer that re-states the SKILL or instructions verbatim. The primer is for *future readers consulting the wiki*; the SKILL is for *agents executing a task*. Different audiences, different jargon density.

---

## 3. Pattern promotion procedure (the "Name 3" gate)

A pattern earns a page in `wiki/patterns/` **only when 3 known consumers exist in the codebase**. This rule is canonical (`docs/wiki/wiki/lessons.md` → "Name 3, build once").

**Promotion checklist.**

- [ ] List the file paths of all **three** consumers. Not types — paths.
- [ ] Verify each consumer actually uses the same mechanism (mechanism similarity check).
- [ ] State why a shared abstraction is better than three local copies — concrete cost.
- [ ] Confirm the abstraction's contract is stable (not still mutating across consumers).

**If only 2 consumers exist:** open a *watchlist* comment in the curator's diff proposal. Never publish a 2-consumer pattern page:

```markdown
- **Watchlist:** `<pattern slug>` — 2 of 3 consumers present (`<path A>`, `<path B>`). Promote when a third lands.
```

**Five required sections.**

1. When to use (with observable signals).
2. Mechanics (language- / framework-agnostic where possible).
3. Example in this codebase (real file path + 5–15 line snippet).
4. Anti-pattern (the shape that looks similar but breaks the contract).
5. Three known consumers (file paths).

---

## 3b. Interface page procedure

**Purpose.** The `interfaces/` category surfaces every public contract consumers depend on (HTTP endpoints, exported types/functions, GraphQL fields, RPC methods, CLI commands, event payloads). Treat it as engineering's pre-doc layer for product documentation generation downstream.

**When to draft / update.**

- A cycle adds, modifies, deprecates, or changes the audience/stability of any **public** contract.
- A Mode B scan finds an exported public surface that has no `interfaces/` page yet.
- The canonical definition (OpenAPI YAML, TS types, proto, schema) drifts from the page.

**Source-of-truth discipline.** The interface page **summarises**; it never replaces the canonical source. Always link to the file that defines the contract. When the source diverges, demote `confidence` and propose an update — never silently rewrite.

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

`kind`, `stability`, `audience` are mandatory. They drive downstream documentation generation (partner-facing docs filter `audience: external | both` and `stability: stable`).

**Six required sections.** Overview, Contract, Inputs, Outputs, Example, Stability & versioning.

**Detection heuristics by stack.**

- **HTTP backend** — routes mounted to the framework (Fastify / Express / Hono / Echo / FastAPI / Axum / etc.).
- **Library** — public exports in a barrel/index file.
- **GraphQL** — schema definitions (`type Query`, `type Mutation`, `type Subscription`).
- **RPC** — `.proto` files, gRPC service definitions, JSON-RPC method registries.
- **CLI** — public subcommands; flags that affect external behaviour.
- **Event** — emitter topics, queue / channel / topic constants, message-bus subscribers.

**Anti-pattern.** A page that re-states the schema verbatim. The page is for future readers consulting the wiki AND for product docs generators; the schema file is for runtime validation. Different audiences, different shape.

**Demotion path.** When the canonical source diverges, demote `confidence` immediately and propose an update — never silently rewrite. When `stability: stable` is broken by a non-additive change, propose a `kind`-appropriate versioning ADR.

---

## 3c. Flow page procedure

**Purpose.** End-to-end user journey from trigger to completion, including meaningful branches. Feeds onboarding docs, help-center articles, QA test plans, and support runbooks.

**When to draft / update.**

- A cycle implements or modifies a primary user journey.
- An EARS spec exists for the journey but no `flows/` page does.
- A UI / integration test plan covers the journey end-to-end.

**Source-of-truth discipline.** Distil from EARS + UI/integration test plan + actual implementation. Never cold-write.

**Frontmatter extras.** `actor` (end-user / admin / system / partner) and `trigger` (one phrase).

**Five required sections.** Overview, Preconditions, Steps (numbered happy path), Branches, Postconditions & related.

**Anti-pattern.** A page that re-states the EARS spec verbatim. The flow page is the *consequence* (what users observe step by step); the EARS spec is the *requirement* (what the system shall do).

---

## 3d. Runbook procedure

**Purpose.** Operational procedures with verification and rollback. Feeds the on-call playbook, incident response docs, and admin guides.

**When to draft / update.**

- A cycle introduces or modifies an admin / migration / recovery procedure.
- An incident retrospective produces reusable steps.
- A scheduled operation (key rotation, certificate renewal) is automated or documented.

**`last_drilled` discipline.** Tracks the last time the procedure was actually executed. A runbook with `last_drilled: never` is documentation, not a runbook — surface in `_hot.md` health. A runbook not drilled in 90+ days surfaces as well.

**Frontmatter extras.** `severity` (routine / urgent / emergency), `audience` (on-call / sre / admin / developer), `last_drilled` (date or `never`).

**Six required sections.** When to use, Preconditions, Procedure (numbered idempotent steps with expected output), Verification, Rollback, Related.

**Cold-writing forbidden.** A runbook must come from real procedure — a cycle that fixed an incident, an owner-decision capturing recovery steps, or a pre-flight checklist that has been exercised.

---

## 3e. Dependency page procedure

**Purpose.** Documents external services we **consume**. Distinct from `interfaces/` (what we expose). Feeds architecture diagrams, partner-facing docs, deps pages, and incident-blast-radius analysis.

**When to draft / update.**

- A cycle adds, removes, or changes the integration shape of an external service.
- Lock-file deltas signal a candidate (new package touching the network boundary).
- Vendor SLA / pricing / region changes that affect criticality or fallback.

**Frontmatter extras.** `kind` (saas / infrastructure / library / api / data-source / other), `criticality` (critical / high / medium / low), `fallback` (available / degraded / none).

**Six required sections.** Overview, Integration shape, Usage shape, Failure modes & fallback, SLA / SLO, Related.

**Criticality discipline.** A `critical` dependency without a documented `fallback` is itself a finding — surface as an OWNER DECISION.

---

## 3f. Policy page procedure

**Purpose.** Non-functional cross-cutting constraints (data retention, rate limits, encryption posture, GDPR/CCPA stance, SLO commitments, access control). Distinct from ADRs (point-in-time decisions); policies are ongoing rules. Feeds compliance pages, trust pages, security overviews, and partner SLA negotiations.

**When to draft / update.**

- A regulatory requirement, contractual commitment, or owner decision establishes a new ongoing rule.
- A cycle adds runtime enforcement code (rate-limiter, retention sweeper, audit logger) for an existing policy.
- A compliance audit surfaces a gap.

**Frontmatter extras.** `scope` (data / security / reliability / compliance / financial / other), `authority` (regulatory / contractual / internal), `enforcement` (runtime / review / manual / hybrid).

**Six required sections.** Statement, Scope, Rationale (link to authority artefact), Enforcement (link to enforcement file(s)), Exceptions (with approval path), Related.

**Cold-writing forbidden.** Policies must trace to a regulatory document, contractual clause, owner-decision artefact, or shipped enforcement code. A policy without enforcement is a wish — surface as an OWNER DECISION.

---

## 3g. Risk page procedure

**Purpose.** Threat-model entries / known-risk register. Tracks security, privacy, operational, business, compliance, and supply-chain risks with severity, likelihood, mitigation, and lifecycle status.

**When to draft / update.**

- A security-audit finding in a cycle names a risk not yet in the register.
- An ADR has a residual-risk callout not tracked.
- A policy admits an exception path that constitutes ongoing risk.
- An incident retrospective surfaces a class of failure that should be tracked.
- An explicit owner risk-acceptance during a HITL gate.

**Frontmatter extras.** `kind` (security / privacy / operational / business / compliance / supply-chain / other), `severity` (critical / high / medium / low), `likelihood` (high / medium / low), `status` (open / mitigated / accepted / transferred / closed).

**Six required sections.** Statement, Scope/Assets, Threat/Cause/Conditions, Impact (CIA / user-facing / business / blast-radius), Mitigation (current / planned / residual), Related.

**Mitigation discipline.** All three mitigation layers (current, planned, residual) are required. A risk with `status: open` and an empty Mitigation section is a finding — surface as an OWNER DECISION. A risk with `status: accepted` MUST name the owner and the acceptance date.

**Cold-writing forbidden.** Risks must trace to a security finding, an ADR's residual-risk callout, a policy that admits exceptions, an incident retrospective, or an explicit owner risk-acceptance. Speculative risks belong in a threat-modelling exercise, not the wiki.

**Lifecycle.** `status` transitions are owner-driven. The curator may propose `open → mitigated` when a planned control ships and the cycle that shipped it is referenced. The curator may NEVER propose `open → accepted` or `open → closed` unilaterally.

---

## 4. Glossary procedure

**One H2 per term. One-sentence definition. Optional `→ See:` cross-reference.** Imitate the existing entries' brevity; the glossary is scanned, not read.

**No jargon-loop.** A definition cannot reference another term that is itself undefined or defined only via this term. Walk the cross-references; if you arrive back at the starting term without a concrete definition, fix the loop.

**When to add a term.** Used 3+ times across CLAUDE.md, the Product Spec, the Pre-HLD, or cycle reports without a glossary entry. Used 5+ times across the wiki without an entry → also propose a primer page (the curator's Mode B "missing pages" check).

**When to delete or merge.** Two entries cover the same concept → merge into one canonical entry; surface in Mode B's deduplication step.

---

## 5. Confidence calibration procedure

The `confidence` field is the trust dial. Three values:

- `high` — owner-confirmed and stable; safe to cite externally.
- `medium` — derived from documented sources but not yet battle-tested.
- `low` — inferred from a single cycle or external article; treat as hypothesis until validated.

**Promotion criteria (owner-only).** A file moves to `high` only by owner approval, with rationale citing at least:

- The number of subsequent cycles that did not regress the file's claims.
- Specific ADRs / cycle paths that validated it.
- Any contradicting signals considered and dismissed.

The curator MAY *propose* promotion in a Mode B diff. The curator may NEVER apply promotion unilaterally. Phrasing: *"Propose: confidence medium → high. Rationale: validated by ADR-014, ADR-016, and 2 cycles without regression."*.

**Demotion criteria (curator-allowed).** A file moves down a step when a more recent cycle contradicts its claims. Demotion is a safety move; the curator applies it during Mode B with rationale in the diff.

**All confidence changes appear in the diff proposal — never silent.**

---

## 6. Stale detection procedure

**Default threshold: 90 days since `last_updated`.** A file older than that with cycle activity in its domain is a stale candidate.

**Signals beyond the threshold.**

- A referenced cycle has shipped to `main` since the file was last touched.
- An ADR was superseded by another ADR.
- A source skill / instructions file under the relevant domain has been rewritten — primer should likely be re-distilled.
- Frontmatter `source_issues: []` is non-empty and any of those issues has been closed by a cycle touching files outside the primer's surface.

**Detection commands (read-only).**

- `git log --since=<last_updated> -- <file or domain path>`.
- `git log --follow <wiki file>`.
- `grep -r "<term>" docs/wiki/wiki/ | wc -l` — usage frequency for missing-page detection.

**Outcome.** Surface stale candidates in the Mode B diff proposal with one of *Refresh recommended*, *Demote confidence*, *Mark superseded*. Apply only on owner approval.

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

**Resolution.** Propose either a fix (add the link) or a removal (delete the page) — never silent.

---

## 8. Compilation-pass checklist (Mode B, end-of-sprint)

Run literally; do not skip steps.

- [ ] **1. Load the full wiki tree.**
- [ ] **2. Process the pending queue.** Read `docs/wiki/sources/_pending.md`. For every `[PENDING]` entry, run Mode A candidate-detection on the named source artefact and add its diffs to this Mode B proposal. Each processed line gets flipped to `[COMPILED — YYYY-MM-DD by mode-B]`.
- [ ] **3. Cross-link integrity.** (§7)
- [ ] **4. Stale detection.** (§6)
- [ ] **5. Confidence drift — promotions.** Any `low`-confidence file validated by 2+ subsequent cycles → propose `low → medium`. Any `medium` file with multiple supporting cycles → propose `medium → high` (owner-only).
- [ ] **6. Confidence drift — demotions.** Any file contradicted by a more recent cycle → apply demotion in the proposed diff.
- [ ] **7. Pattern promotion candidates.** (§3) Promote when "Name 3" is satisfied; watchlist when only 2.
- [ ] **8. Deduplication.** Two glossary entries for the same concept; two ADRs covering overlapping decisions; the same lesson under two H2s in `lessons.md`.
- [ ] **9. Missing pages.** Any glossary term referenced 5+ times in `wiki/` without its own primer → propose a primer (§2 still applies — never cold-write).
- [ ] **10. Interface surface scan.** (§3b) Walk the codebase for public contracts. Propose new pages or demotions where canonical source has drifted.
- [ ] **11. Flow / runbook / dependency / policy / risk scan.** (§3c–§3g) Specifically:
  - Flows: primary EARS specs without a journey page; UI test plans for cross-screen flows.
  - Runbooks: admin / migration / recovery scripts referenced in incidents but not yet written up; `last_drilled: never` or > 90 days surface in `_hot.md` health.
  - Dependencies: lock-file deltas, packages crossing the network boundary without a page, vendor SLA changes.
  - Policies: non-functional constraints in `.specflow/config.md` or referenced in EARS specs without a page; runtime enforcement code without a corresponding policy page.
  - Risks: security findings in cycle reports without a risk page; high-severity TODOs/FIXMEs flagging accepted risk; threat-model gaps surfaced by ADRs/policies; risks with `status: open` surface in `_hot.md`.
- [ ] **12. Refresh `_hot.md`.** (§9.3)
- [ ] **13. Update `index.md`.** (§9.4)
- [ ] **14. Append `_log.md` entry.** (§9.2)

After step 14, produce the diff proposal in the curator agent's format. **STOP. Wait for owner approval before applying.**

---

## 9. Control files (Karpathy second-brain plumbing)

Seeded by `/specflow-wiki-init`. This section defines how the curator reads and updates them at runtime.

### 9.1 `docs/wiki/sources/_pending.md` — compilation queue

**Purpose.** Bridges per-cycle distillation (Mode A) with end-of-sprint compilation (Mode B). Without this file, a Mode A skip silently loses a cycle's contribution to the curated wiki.

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

**Purpose.** The only persistent record of what the curator has done. Used for drift detection (no Mode B in 60 days = stale risk), debuggability, and confidence-trend analysis.

**Format.**

```markdown
## [YYYY-MM-DD HH:MM] mode-{A|B} — <subject> — wrote <K> / proposed <P>
- Wrote: <path> — <one-line>
- Proposed (deferred): <path> — <reason>
- Confidence changes: <file> <from>→<to> (<promotion|demotion>)
- Watchlist: <slug> — <consumer count>
```

Subject: Mode A → cycle issue ID (`issue #142`); Mode B → sprint identifier or date range.

**When to log.**

- Every successful Pass 2 run appends an entry. The entry appears in the diff proposal alongside the rest; the owner approves it as part of the diff.
- A no-op Mode B run still logs (`- No changes; checklist clean.`) so freshness can be measured.
- A no-op Mode A run does not log unless explicitly skipped by owner decision.

**Append-only.** Never edit historical entries. Corrections go in a new entry that references the original by timestamp.

### 9.3 `docs/wiki/wiki/_hot.md` — hot cache (< 500 tokens)

**Purpose.** The first file any agent reads when consulting the wiki. Daily-briefing style — what's load-bearing right now.

**Refreshed only by Mode B.** Mode A does not touch this file.

**Sections (rebuilt on each Mode B run).**

- **Active decisions (last 30 days)** — ADRs whose `last_updated` falls in the window. `Title — confidence — status`.
- **Open OWNER DECISIONS** — pattern-promotion borderlines, confidence-promotion candidates, primer-refresh proposals deferred by the owner.
- **Recent confidence changes** — last 30 days; `file — from→to — date — rationale`.
- **Watchlist patterns (2 of 3 consumers)** — `slug — known consumers (paths)`.
- **Health** — pending queue depth, days since last Mode B, days since last Mode A, stale primer count.

**Token discipline.** Target < 500 tokens. If a section grows beyond its share, summarise and link out. The whole point of `_hot.md` is cheap orientation.

**No silent updates.** The full new content of `_hot.md` appears in the Mode B diff proposal.

### 9.4 `docs/wiki/wiki/index.md` — catalog

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

Mode A explicitly reads `_hot.md` before any candidate detection.

---

## Format imitation reminders

- New ADRs follow `docs/wiki/wiki/decisions/_template.md` exactly. 300–500 body words; five sections.
- Frontmatter required on every curated page: `title`, `tags`, `last_updated`, `source_issues`, `confidence`. Per-category extras documented in §3b–§3g.
- When the project ships seed exemplars (e.g., a hand-written ADR-001), imitate those exemplars over the bare template — the seeds carry the project's voice.
- The curator is a stylistic conservative. A "better" idea about format goes in the diff as an OWNER DECISION — never a silent change.
