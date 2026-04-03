# Failure Condition Writing Guide

Failure conditions are the most critical part of a Prompt Contract. They become the RED
phase test specifications in TDD. A poorly written failure condition produces a useless test.

---

## Rules

### 1. Every Failure Condition Maps to a REQ-###

Bad: `- [ ] The API returns an error`
Good: `- [ ] The API returns HTTP 200 for an expired JWT token (REQ-007)`

The REQ-### reference creates traceability: test → failure condition → requirement → spec.

### 2. Describe the Unacceptable Output, Not the Expected One

Bad: `- [ ] The score is calculated correctly`
Good: `- [ ] Calculated score falls outside the 0-100 range for valid inputs (REQ-002)`

Failure conditions define what MUST NOT happen. The test asserts the negative.

### 3. Be Specific Enough to Write a Test From

Bad: `- [ ] The component doesn't work offline`
Good: `- [ ] The SOS overlay fails to render when navigator.onLine is false (REQ-012)`

A developer reading this failure condition should be able to write the test without
any other context.

### 4. One Failure Per Checkbox

Bad: `- [ ] The endpoint returns wrong status codes and missing headers (REQ-003, REQ-004)`
Good:
```
- [ ] The endpoint returns HTTP 200 instead of HTTP 401 for missing auth (REQ-003)
- [ ] The response is missing the Content-Type: application/json header (REQ-004)
```

### 5. Include Boundary Conditions

If the requirement specifies a range (0-100), write failure conditions for:
- Below minimum: `- [ ] Score calculator returns negative values (REQ-001)`
- Above maximum: `- [ ] Score calculator returns values above 100 (REQ-001)`
- Invalid input: `- [ ] Score calculator accepts non-integer inputs without error (REQ-001)`

### 6. Always Include Coverage

Every contract must end with:
```
- [ ] Test coverage below [threshold]% (project config)
```

The threshold comes from `.specflow/config.md` → `## Project Constraints`.

---

## Failure Condition Categories

### Functional Failures
- Wrong output for valid input
- Missing output for valid input
- Accepting invalid input without error

### State Failures
- State not updated after operation
- State corrupted by concurrent operations
- State persisted when it should not be (privacy violation)

### Integration Failures
- Dependent service not called
- Wrong HTTP method or path
- Missing authentication header
- Wrong error code returned

### Performance Failures
- Operation exceeds time threshold
- Resource leak (connection, memory)
- Missing timeout on HTTP request

### Security Failures
- Sensitive data in logs
- Missing auth check
- Raw storage paths exposed
- Data persisted when privacy contract forbids it

---

## Effort Scale Reference

| Size | Duration | Examples |
|------|----------|---------|
| **XS** | < 30 min | Config file, locale strings, add dependency, constants file |
| **S** | 30 min – 2h | Simple component, single API endpoint, utility function, Zustand slice |
| **M** | 2 – 4h | Complex screen, multi-step form, state machine, API + handler + domain |
| **L** | 4 – 8h | Full player, animation system, integration layer, E2E flow |

**If a task exceeds L, it MUST be split.** No exceptions.
