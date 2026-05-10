---
title: <runbook name>
tags: [runbook, <area>]
last_updated: <YYYY-MM-DD>
source_issues: [<gh-issue-numbers>]
confidence: medium
severity: <routine | urgent | emergency>
audience: <on-call | sre | admin | developer>
last_drilled: <YYYY-MM-DD or never>
---

# <runbook name>

<!--
Operational procedure — what to do when X. Feeds the on-call playbook, incident response docs, and admin guides.

Six required sections in order. Cold-writing is forbidden; runbooks must come from real procedures (a cycle that fixed an incident, an owner-decision capturing recovery steps, or a pre-flight checklist that has been exercised).

`last_drilled` tracks the last time the procedure was actually executed (drill or production). A runbook with `last_drilled: never` is documentation, not a runbook — surface in `_hot.md` health.
-->

## When to use this runbook

The signals that say "execute this now". Specific. Avoid vague triggers like "things look bad".

## Preconditions

Access required (production / staging / read-only), credentials, tools, prior approvals, communication channels to notify.

## Procedure

Numbered, idempotent steps. Each step is exactly one action. Include the expected output / signal of success.

1. <command or action> → expect <output>.
2. ...

## Verification

How to confirm the runbook worked. Specific signals: metric returned to baseline, page resolved, queue drained, key rotated and old key revoked.

## Rollback

What to do if a step fails or makes things worse. If rollback is impossible, say so explicitly — that is itself a finding.

## Related

- **Triggers from** — alerts, dashboards, support tickets that point here.
- **Related ADRs** — [ADR-NNN](../decisions/ADR-NNN-<slug>.md)
- **Related dependencies** — [<service>](../dependencies/<slug>.md) when the runbook involves an external service.
- **Related interfaces** — [<interface>](../interfaces/<slug>.md) when the runbook touches a public contract.
