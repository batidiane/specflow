---
title: <domain name>
tags: [domain, <slug>]
last_updated: <YYYY-MM-DD>
source_issues: [<gh-issue-numbers>]
confidence: medium
---

# <domain name>

<!--
Six required sections in order.
Never cold-write a primer — distil from at least 2 cycle reports + the relevant SKILL.md (if one exists) + the product spec.
A primer that re-states a SKILL verbatim is an anti-pattern. The primer is for *future-Claude reading the wiki*; the SKILL is for *Claude executing a task*. Different audiences, different jargon density.
-->

## Overview

3–5 sentences. What this domain does, who owns it, where it sits in the system.

## Key entities

Types, structs, tables, store slices. Link each to its source-of-truth file.

- `<entity>` — `path/to/source.ts:NN` — <one-line>

## Data flow

Where data enters, where it lives, where it leaves. Mention the boundary tools (HTTP handlers, database adapters, message queues).

## Boundaries

What this domain is NOT. List adjacent domains explicitly.

- Does not handle: <thing> — see [<adjacent domain>](<slug>.md).

## Related patterns

- [<pattern>](../patterns/<slug>.md)

## Related ADRs

- [ADR-NNN — <title>](../decisions/ADR-NNN-<slug>.md)
