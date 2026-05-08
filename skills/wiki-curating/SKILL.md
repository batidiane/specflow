---
name: wiki-curating
description: Provides the procedures the @wiki-curator agent follows to maintain the CocoMind engineering wiki under docs/wiki/. Covers ADR drafting from cycle reports and owner decisions, glossary maintenance, domain primer distillation, pattern promotion under the "Name 3" rule, confidence calibration (owner-only promotions, curator-allowed demotions), stale-detection thresholds, cross-link integrity verification, and the end-of-sprint compilation-pass checklist. Use when drafting an ADR for the wiki, adding a glossary term, distilling a domain primer from cycle reports, evaluating a pattern for promotion, auditing confidence drift, or running a wiki compilation pass. Triggers on tasks involving ADR, wiki, curator, glossary, pattern promotion, knowledge base, domain primer, second brain, compilation pass, or the docs/wiki/ tree.
---

# Wiki Curating — Procedures for CocoMind's Engineering Wiki

The CocoMind engineering wiki lives under `docs/wiki/` and is the LLM-curated second brain. This skill codifies the procedures the `@wiki-curator` agent (and any human contributor) follows when maintaining it. Format consistency outranks stylistic novelty: imitate the seed exemplars rather than inventing new shapes.

The seed exemplars are:

- `docs/wiki/wiki/decisions/ADR-001-cloudflare-r2-over-s3.md`
- `docs/wiki/wiki/decisions/ADR-002-hexagonal-architecture-for-api.md`
- `docs/wiki/wiki/decisions/ADR-003-expo-secure-store-locked-strategy.md`

Reference these by path whenever drafting new ADRs.

---

## 1. ADR creation procedure

**When to draft an ADR.** Decisions with > 3-month consequences. Strong signals: an OWNER DECISION item resolved during a Triad cycle's HITL gate; a vendor / pricing / regulatory change that forces a structural choice; a security or privacy posture change; the supersession of a prior ADR.

**Where to source rationale.**

1. The cycle report under `docs/wiki/sources/cycles/` — for the immediate context and the alternatives discussed at the gate.
2. The owner decision artefact under `docs/wiki/sources/decisions/` — for the precise wording the owner used.
3. `docs/CocoMind - Pre-High Level Design (HLD) & Architecture Strategy.md` — for cost / FinOps / cross-cloud rationale (e.g., the egress-economics framing behind `docs/wiki/wiki/decisions/ADR-001-cloudflare-r2-over-s3.md`).
4. `docs/CocoMind Product Specification.md` — for behaviour-driven decisions.
5. EARS files under `docs/specflow/ears/` — for decisions that emerged from a spec-gap pass (e.g., the encryption-key lifecycle behind `docs/wiki/wiki/decisions/ADR-003-expo-secure-store-locked-strategy.md`).

**Five required sections (in order).**

1. **Context** — what forced the decision. Reference the source artefact.
2. **Decision** — what was chosen, in **one sentence**.
3. **Alternatives rejected** — at least two, each with a one-sentence rationale.
4. **Consequences** — both positive AND negative. Negatives are mandatory; every decision pays a cost.
5. **Status** — `proposed` | `accepted` | `superseded by ADR-NNN`.

**Length target.** 300–500 body words (excluding YAML frontmatter and section headings). The three seed ADRs are 442 / 448 / 406 words and define the band.

**Frontmatter.** Always:

```yaml
---
title: ADR-NNN — <decision title>
tags: [adr, <area>, <subdomain>...]
last_updated: <YYYY-MM-DD>
source_issues: [<gh-issue-numbers>]
confidence: high
---
```

Seed ADRs default to `confidence: high` because they document shipped, stable decisions. New proposals start `medium`; a proposal becomes `high` only after owner approval (see §5).

---

## 2. Domain primer procedure

**Never cold-write a primer.** A primer distils *experience*; cold-writing produces fiction. The minimum source pool is:

- **At least 2 Triad cycle reports** under `docs/wiki/sources/cycles/` that touched the domain.
- **The relevant `/workspace/.claude/skills/<domain-slug>/SKILL.md`** if one exists (for example `sos-implementing/SKILL.md`, `wellbeing-scoring/SKILL.md`).
- The relevant section of the Product Specification.

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
- [ ] **2. Cross-link integrity.** Every relative link resolves. Report broken links and orphaned pages (§7).
- [ ] **3. Stale detection.** Any file with `last_updated` > 90 days where the domain has had cycles since (§6).
- [ ] **4. Confidence drift — promotions.** Any `low`-confidence file validated by 2+ subsequent cycles → propose `low → medium`. Any `medium` file with multiple supporting cycles → propose `medium → high` (owner-only).
- [ ] **5. Confidence drift — demotions.** Any file contradicted by a more recent cycle → apply demotion in the proposed diff.
- [ ] **6. Pattern promotion candidates.** Scan for repeated mechanics across 3+ files in the codebase that lack a `patterns/` page (§3). Promote when "Name 3" is satisfied; watchlist when only 2.
- [ ] **7. Deduplication.** Two glossary entries for the same concept; two ADRs covering overlapping decisions; the same lesson under two H2s in `lessons.md`.
- [ ] **8. Missing pages.** Any glossary term referenced 5+ times in `wiki/` without its own primer page → propose a primer (§2 still applies — never cold-write).

After step 8, produce the diff proposal in the curator agent's §5 format. **STOP. Wait for owner approval before applying.**

---

## Format imitation reminders

- New ADRs imitate `docs/wiki/wiki/decisions/ADR-001-cloudflare-r2-over-s3.md`, `docs/wiki/wiki/decisions/ADR-002-hexagonal-architecture-for-api.md`, `docs/wiki/wiki/decisions/ADR-003-expo-secure-store-locked-strategy.md`.
- 300–500 body words; five sections.
- Frontmatter: `title`, `tags`, `last_updated`, `source_issues`, `confidence`.
- The curator is a stylistic conservative. A "better" idea about format goes in the diff as an OWNER DECISION — never a silent change.
