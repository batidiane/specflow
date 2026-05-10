---
title: <risk name>
tags: [risk, <area>]
last_updated: <YYYY-MM-DD>
source_issues: [<gh-issue-numbers>]
confidence: medium
kind: <security | privacy | operational | business | compliance | supply-chain | other>
severity: <critical | high | medium | low>
likelihood: <high | medium | low>
status: <open | mitigated | accepted | transferred | closed>
---

# <risk name>

<!--
Threat-model entry / known-risk register entry. Six required sections in order. Feeds security overview, audit prep, threat-model docs, compliance docs, and incident-blast-radius analysis.

Cold-writing forbidden. Risks must trace to a security-auditor finding, an ADR with a residual-risk callout, a policy that admits exceptions, an incident retrospective, or an explicit owner risk-acceptance in a cycle report.

`severity` × `likelihood` is the rough exposure score; `status` tracks where the risk sits in the lifecycle (open → mitigated / accepted / transferred / closed).
-->

## Statement

The risk in one paragraph. Imperative voice. Name the asset, the threat, and the failure mode.

## Scope / Assets

What is at risk: data classes, services, users, environments, third-party trust relationships. Equally important — what is NOT in scope.

## Threat / Cause / Conditions

Why this risk exists. Capture both the **threat** (who or what could realise the risk) and the **conditions** (architectural choices, dependencies, gaps that enable it). Link to:

- The cycle report or `@security-auditor` finding under `docs/wiki/sources/`.
- The ADR or policy whose residual risk this entry tracks.
- Threat-model artefacts if external (link out).

## Impact

What happens if the risk is realised. Concrete consequences across:

- **Confidentiality / Integrity / Availability** (for security risks).
- **User-facing impact** (data loss, downtime, degraded experience).
- **Business / regulatory impact** (compliance breach, contractual penalty, reputational damage).
- **Blast radius** (which dependencies amplify or contain the impact — link to `dependencies/`).

## Mitigation

Three layers, all required:

- **Current controls** — what's in place today; link to enforcement code, policies, or runbooks.
- **Planned controls** — what's coming; link to ADRs, contracts, or specs that own the work.
- **Residual risk** — what remains after current and planned controls; if `status: accepted`, name the owner and the acceptance date.

A risk with `status: open` and an empty Mitigation section is a finding — surface as an OWNER DECISION in the curator's diff.

## Related

- **ADRs** — [ADR-NNN](../decisions/ADR-NNN-<slug>.md) (decisions that introduced, mitigated, or accepted this risk).
- **Policies** — [<policy>](../policies/<slug>.md) (policies whose enforcement reduces this risk).
- **Runbooks** — [<runbook>](../runbooks/<slug>.md) (recovery procedures for when the risk is realised).
- **Dependencies** — [<dependency>](../dependencies/<slug>.md) (deps that amplify or contain blast radius).
- **Interfaces** — [<interface>](../interfaces/<slug>.md) (public contracts whose shape affects this risk).
