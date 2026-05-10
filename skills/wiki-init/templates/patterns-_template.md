---
title: <pattern name>
tags: [pattern, <area>]
last_updated: <YYYY-MM-DD>
source_issues: [<gh-issue-numbers>]
confidence: medium
---

# <pattern name>

<!--
Five required sections in order.
The "Three known consumers" gate is canonical (see `lessons.md` → "Name 3, build once"). A pattern earns this page only when three consumer file paths can be listed below. Two = watchlist; one = inline.
-->

## When to use

Observable signals that this pattern fits. Two or three bullet points.

## Mechanics

Language- / framework-agnostic where possible. The shape, not the implementation.

## Example in this codebase

Real file path + 5–15 line snippet.

```<lang>
// from <path/to/file>:NN
<snippet>
```

## Anti-pattern

The shape that looks similar but breaks the contract. Concrete signal so a reviewer can spot it.

## Three known consumers

1. `path/to/consumer-a.ts:NN`
2. `path/to/consumer-b.ts:NN`
3. `path/to/consumer-c.ts:NN`
