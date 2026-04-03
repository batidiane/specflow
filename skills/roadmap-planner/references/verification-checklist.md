# Verification Checklist

Run ALL checks before writing the plan file. If any CRITICAL check fails, HALT and
report violations. WARN checks are reported but do not block.

---

## Coverage Checks [CRITICAL]

- [ ] Every CONTRACT-### from input documents appears in exactly one Feature
- [ ] No contract is orphaned (present in contracts doc but missing from plan)
- [ ] No contract appears in multiple Features
- [ ] Every Feature belongs to exactly one Epic
- [ ] Every Epic from config that has matching contracts has at least one Feature

## Dependency Checks [CRITICAL]

- [ ] No circular dependencies exist (A→B→C→A)
- [ ] No cross-Epic forward references (Epic N task blocked by Epic N+1 task)
- [ ] Every `blocked-by` reference resolves to an existing CONTRACT-###
- [ ] Every `blocks` reference resolves to an existing CONTRACT-###
- [ ] Critical path is identified (longest dependency chain with effort sum)

## Completeness Checks [CRITICAL]

- [ ] Every contract has all 4 Prompt Contract sections (GOAL, CONSTRAINTS, FORMAT, FAILURE CONDITIONS)
- [ ] Every GOAL is one sentence and binary pass/fail
- [ ] Every contract has at least 2 failure conditions
- [ ] Every failure condition references a REQ-### ID

## Scope Checks [CRITICAL]

- [ ] No contract targets items listed in config's `## Out of Scope`
- [ ] No contract invents requirements not present in the source EARS documents
- [ ] All domain labels used exist in config's `## Domain Labels`

## Structural Checks [WARN]

- [ ] Every Feature has 2-8 Tasks (fewer → consider merging, more → consider splitting)
- [ ] Every Epic has at least 1 Feature
- [ ] No Epic has more than 20 Tasks total (consider splitting the Epic)
- [ ] Effort distribution is roughly balanced across Epics (no single Epic > 60% of total)

## Ordering Checks [WARN]

- [ ] Tasks within each Feature are ordered by dependency, then effort (XS first)
- [ ] Features within each Epic are ordered by dependency (foundations first)
- [ ] Epics are ordered per config's `## Epic Definitions` (which defines the phase sequence)

---

## Reporting Format

```
## Verification Results

### CRITICAL Checks
✓ Coverage: N/N contracts mapped
✓ Dependencies: No circular deps. Critical path: CONTRACT-001 → CONTRACT-005 (5 tasks, ~M effort)
✓ Completeness: All contracts have 4 sections
✓ Scope: No out-of-scope items

### WARN Checks
✓ Structure: All Features have 2-8 tasks
⚠ Ordering: Feature "Auth Flow" could reorder CONTRACT-003 before CONTRACT-004 (no dependency)

### Summary
CRITICAL: 4/4 passed
WARN: 1 advisory note
Decision: PASS — plan is valid
```

If any CRITICAL check fails:
```
✗ CRITICAL FAILURE: [check name]
  Violations:
  - CONTRACT-007 is not mapped to any Feature
  - CONTRACT-003 → CONTRACT-001 creates a circular dependency

PLAN NOT WRITTEN. Fix violations and re-run /specflow:plan.
```
