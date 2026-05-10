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

# <interface name>

<!--
Six required sections in order.
The interface page exists to surface a contract that consumers depend on. It is the bridge from "code we wrote" to "documentation we ship to product / partners / external developers".

Never cold-write. Distil from the cycle reports + the source files (the code is the source of truth) + any existing OpenAPI / JSON schema / type definitions.

If the contract is internal-only, mark `audience: internal` and keep it terse — this becomes part of the engineering reference, not a public doc. If the contract is external-facing or product-shipped, mark `audience: external | both`; this page is a candidate to feed product/partner documentation generation downstream.
-->

## Overview

3–5 sentences. What this interface does, who calls it, where its source-of-truth definition lives. Always link to the canonical definition file (e.g., `path/to/openapi.yaml`, `path/to/types.ts`, `path/to/proto/foo.proto`).

## Contract

The shape consumers depend on. Pick the format that fits the kind:

- **HTTP** — method + path + request schema + response schema + error codes.
- **TypeScript / Python / Rust / Go** — exported type/function signature + parameter semantics + return semantics.
- **GraphQL** — query / mutation / subscription names + input types + return types.
- **CLI** — command + flags + arguments + exit codes.
- **Event** — topic / channel + payload schema + delivery semantics (at-least-once / at-most-once / exactly-once).

Keep the contract dense. Link to the source file for full detail; do not duplicate the entire schema here.

## Inputs

What consumers send. For each input: name, type, required/optional, semantic constraints (range, format, invariants).

## Outputs

What consumers receive. For each output: name, type, semantic meaning. Include error responses / failure modes — they are part of the contract.

## Example

One concrete request/response (or call/return) pair. Real values, not placeholders. 5–15 lines.

```<format>
<example>
```

## Stability & versioning

- Current version / status: <e.g., v1, stable, since cycle #142>.
- Breaking-change policy: <e.g., bumps major version; notice period; deprecation path>.
- Known consumers (if `audience: internal | both`): list file paths.
- External consumers (if `audience: external | both`): list known integrators / SDK versions.

## Related

- ADRs that shaped this interface: [ADR-NNN — title](../decisions/ADR-NNN-slug.md)
- Related domain primer: [<domain>](../domains/<slug>.md)
- Related patterns: [<pattern>](../patterns/<slug>.md)
