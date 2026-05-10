---
title: <dependency name>
tags: [dependency, <area>]
last_updated: <YYYY-MM-DD>
source_issues: [<gh-issue-numbers>]
confidence: medium
kind: <saas | infrastructure | library | api | data-source | other>
criticality: <critical | high | medium | low>
fallback: <available | degraded | none>
---

# <dependency name>

<!--
External service we depend on. Distinct from `interfaces/` (which is what we expose). Feeds architecture diagrams, partner-facing docs, deps pages, and incident-blast-radius analysis.

Six required sections in order. Cold-writing forbidden — the dependency must already be wired into the codebase (or have an ADR proposing the wire-up).

`criticality` drives blast-radius reasoning when the dep has an outage. `fallback` documents whether we degrade gracefully.
-->

## Overview

3–5 sentences. What this dependency provides, why we picked it, where it integrates.

## Integration shape

What we call, how we authenticate, where in the code the integration lives.

- **Auth** — <how credentials are managed>; reference the secret-store path or env-var name pattern.
- **Endpoints / SDKs used** — list each, link to canonical source where available.
- **Wiring location** — `path/to/integration.ts:NN` (or whichever file owns the boundary).

## Usage shape

The runtime characteristics that matter for capacity planning, cost forecasting, and outage reasoning.

- **Frequency** — calls/sec or calls/day order of magnitude.
- **Data volume** — payload sizes, monthly egress, etc.
- **Cost model** — per-request, per-GB, flat tier; link to the ADR if one exists.

## Failure modes & fallback

How this dep can fail and what happens to us when it does.

- **Outage behaviour** — <how the system behaves when the dep is down>.
- **Rate-limit behaviour** — <retry / backoff / shed-load policy>.
- **Fallback** — <available | degraded mode | none>; describe the degraded mode when applicable.

## SLA / SLO

What the vendor promises (link to their public SLA) and what we observe in practice. Note any gap.

## Related

- **ADRs** — [ADR-NNN](../decisions/ADR-NNN-<slug>.md) (the decision that picked this dependency over alternatives).
- **Runbooks** — [<runbook>](../runbooks/<slug>.md) (recovery procedures that involve this dep).
- **Interfaces** — [<interface>](../interfaces/<slug>.md) (public contracts that hide or expose this dep).
- **Policies** — [<policy>](../policies/<slug>.md) (data residency / retention / compliance constraints this dep is bound by).
