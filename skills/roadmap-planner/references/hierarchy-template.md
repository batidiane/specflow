# GitHub Hierarchy Templates

These templates define the exact markdown format for each hierarchy level in the plan document.
The `specflow:github-publisher` parses these sections to create GitHub artifacts.

---

## Plan Document Structure

```markdown
# Roadmap: [Plan Name]

**Source contracts:** [list of contract doc paths]
**Date:** [YYYY-MM-DD]
**Status:** Draft — pending publish

---

## Vision: [Project Name]

[2-3 sentence project vision statement]

### Releases
- [ ] **[Epic Name]** — [one-line scope] — [N tasks, effort sum]
- [ ] **[Epic Name]** — [one-line scope] — [N tasks, effort sum]

### Out of Scope
- [Item from config]
- [Item from config]

---

## Epic: [Epic Name]

### Scope
[What this Epic delivers — 2-3 sentences]

### Features
- [ ] [LABEL] [Feature Name] — N tasks
- [ ] [LABEL] [Feature Name] — N tasks

### Entry Criteria
- [What must be true before this Epic starts]

### Exit Criteria
- [What must be true for this Epic to be Done]

### Effort
- Total: N tasks — XS(a) S(b) M(c) L(d)

---

## Feature: [LABEL] [Feature Name]

**Epic:** [Epic Name]
**Spec Reference:** [Product Spec §X.Y or API Spec §X.Y]

### Description
[2-3 sentences describing the user-facing capability]

### Tasks
1. [ ] CONTRACT-001: [Task Title] — [Effort] [— blocked by CONTRACT-NNN]
2. [ ] CONTRACT-002: [Task Title] — [Effort]
3. [ ] CONTRACT-003: [Task Title] — [Effort] [— blocked by CONTRACT-001]

### Acceptance Criteria
- [ ] [Derived from CONTRACT-001 GOAL]
- [ ] [Derived from CONTRACT-002 GOAL]
- [ ] [Derived from CONTRACT-003 GOAL]

---

## Task: CONTRACT-001 — [Task Title]

**Feature:** [LABEL] [Feature Name]
**Epic:** [Epic Name]

### GOAL
[Copied from contract]

### CONSTRAINTS
[Copied from contract]

### FORMAT
[Copied from contract]

### FAILURE CONDITIONS
[Copied from contract]

### Effort: [XS / S / M / L]

### Dependencies
- Blocked by: [CONTRACT-### or "none"]
- Blocks: [CONTRACT-### or "none"]

### Domain Labels
- [LABEL from config]

---
```

## Parser Hints for github-publisher

The publisher uses these markers to extract GitHub artifacts:

| Marker | Creates |
|--------|---------|
| `## Vision:` | Pinned issue (if not already present) |
| `## Epic:` | GitHub Milestone |
| `## Feature:` | GitHub Issue with domain label and milestone |
| `## Task: CONTRACT-###` | GitHub Sub-issue linked to parent Feature |
| `### Acceptance Criteria` | Copied into Feature issue body |
| `### Dependencies` | Used for sub-issue cross-references after creation |
| `### Domain Labels` | Applied as GitHub issue labels |
