---
title: <policy name>
tags: [policy, <area>]
last_updated: <YYYY-MM-DD>
source_issues: [<gh-issue-numbers>]
confidence: medium
scope: <data | security | reliability | compliance | financial | other>
authority: <regulatory | contractual | internal>
enforcement: <runtime | review | manual | hybrid>
---

# <policy name>

<!--
Non-functional cross-cutting constraint. Examples: data retention, rate limits, encryption posture, GDPR/CCPA stance, SLO commitments, access-control model.

Feeds compliance pages, trust pages, security overviews, and partner SLA negotiations. Distinct from ADRs (which are point-in-time decisions) — policies are ongoing rules.

Six required sections in order. Cold-writing forbidden — the policy must trace to a regulatory requirement, contractual commitment, owner-decision artefact, or shipped enforcement code.
-->

## Statement

The policy in one paragraph. Imperative voice. What MUST / MUST NOT happen.

## Scope

What this policy applies to (which data, which services, which users, which environments). Equally important — what it does NOT apply to.

## Rationale

Why this policy exists. Link to the regulatory document, contractual clause, or owner-decision artefact under `docs/wiki/sources/`. If internal-only, name the cycle that produced it.

## Enforcement

How the policy is enforced — runtime checks, review-gate checks, manual audits, or hybrid. Link to the file(s) that implement enforcement.

- **Runtime checks** — `path/to/enforcement.ts:NN`.
- **Review gates** — name the PR-review checklist or specflow contract section that enforces it.
- **Audit cadence** — how often manual / external audits verify the policy.

## Exceptions

Documented exceptions to the policy and the approval path. An exception with no documented approval is a violation.

## Related

- **ADRs** — [ADR-NNN](../decisions/ADR-NNN-<slug>.md) (decisions that depend on or reinforce this policy).
- **Dependencies** — [<service>](../dependencies/<slug>.md) (external dependencies this policy constrains).
- **Runbooks** — [<runbook>](../runbooks/<slug>.md) (recovery procedures that must respect this policy).
- **Interfaces** — [<interface>](../interfaces/<slug>.md) (public contracts whose shape is dictated by this policy, e.g., a `Retention-After` header).
