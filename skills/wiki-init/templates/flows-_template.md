---
title: <flow name>
tags: [flow, <area>]
last_updated: <YYYY-MM-DD>
source_issues: [<gh-issue-numbers>]
confidence: medium
actor: <end-user | admin | system | partner>
trigger: <what starts this flow>
---

# <flow name>

<!--
End-to-end user journey. Captures the happy path AND the meaningful branches. This page feeds onboarding docs, help-center articles, QA test plans, and support runbooks.

Five required sections in order. Never cold-write — distil from cycle reports + EARS specs + the actual implementation.
-->

## Overview

3–5 sentences. Who runs this flow, when it triggers, what they get out of it.

## Preconditions

What must be true before the flow starts. Auth state, feature flags, prior data, device permissions.

## Steps (happy path)

Numbered. Each step is one user-observable action and the system response.

1. User <action> → system <response>.
2. ...

## Branches

Meaningful divergences from the happy path. Each with the trigger condition and the resulting user experience.

- **<branch name>** — when <condition> → <user experience>.

## Postconditions & related

- **End state** — what is true after the flow completes (data persisted, state changed, notification sent).
- **Related interfaces** — [<interface>](../interfaces/<slug>.md)
- **Related ADRs** — [ADR-NNN](../decisions/ADR-NNN-<slug>.md)
- **Related runbooks** — [<runbook>](../runbooks/<slug>.md) when this flow has an operator-facing recovery path.
