# Prompt Contract Template

Every contract follows this exact structure. Do not add, remove, or reorder sections.

---

## CONTRACT-NNN: [Imperative Task Title]

Title format: verb + object (e.g., "Implement WHO-5 score calculator", "Create wellbeing Zustand store")

### GOAL

One sentence. Must be:
- Binary: either pass or fail, no partial credit
- Testable: an automated test can verify it in under 1 minute
- Observable: describes what the system DOES, not how it's built

**Good examples:**
- "The WHO-5 score calculator accepts a 5-item integer array (0-5 each), multiplies the raw sum by 4, and returns a score in range 0-100."
- "The SOS overlay renders within 100ms of FAB tap, plays pre-cached audio, and saves zero data to any database."
- "The `/api/v1/wellbeing/scores` endpoint returns the authenticated user's score history as a paginated JSON array sorted by date descending."

**Bad examples:**
- "Implement the score calculator" (not testable — what does "implement" mean?)
- "The component works correctly" (not specific — what is "correct"?)
- "Use Zustand for state management" (implementation prescription, not observable behavior)

### CONSTRAINTS

Ordered list of hard boundaries. Three categories:

1. **Project constraints** — from `.specflow/config.md` `## Project Constraints` section
   Only include constraints relevant to this specific task.
   ```
   - NativeWind className for all static styling (project config)
   - 90% minimum test coverage on all touched files (project config)
   ```

2. **Task-specific constraints** — architecture layer, library, pattern
   ```
   - Domain layer: domain/wellbeing.go (Hexagonal Architecture)
   - Use testify for assertions, httptest for handler tests
   - Handler must validate JWT before processing
   ```

3. **Forbidden approaches** — what NOT to do
   ```
   - No ORM — raw SQL via pgx only
   - No direct Supabase client calls from mobile
   ```

4. **Scope Discipline** — verbatim from `.specflow/config.md` `## Scope Discipline Constraints`
   section. Always included. Never abbreviated. Enforced at the REFACTOR gate.
   ```
   **Scope Discipline** (from .specflow/config.md — applies to every contract):
   - SCOPE-001: Fix findings inline if < 30 min and files are in the PR diff.
   - SCOPE-002: Target zero new issues per PR. Justify any exception.
   - SCOPE-003: Before creating any issue, search existing issues first.
   - SCOPE-004: Style preferences are SKIP, not DEFER.
   - SCOPE-005: Spec gaps route through the specflow pipeline, not issues.
   - SCOPE-006: Vendor docs override contract FORMAT when they conflict; flag in PR.
   ```

5. **Coverage line** — always last
   ```
   - Covers: REQ-001, REQ-002, REQ-003
   ```

### FORMAT

Exact output specification. The implementer knows precisely what files to create.

```
- File: api/internal/domain/wellbeing.go
- Exported: CalculateWHO5Score(answers [5]int) (int, error)
- File: api/internal/handlers/wellbeing_handler.go
- Exported: HandleSubmitScore(w http.ResponseWriter, r *http.Request)
- Test file: api/internal/domain/wellbeing_test.go
- Test file: api/internal/handlers/wellbeing_handler_test.go
```

#### Routing & Navigation (required when FORMAT names a new mobile screen component)

If this contract introduces a new screen component (e.g. a file ending in `Screen.tsx`),
add this subsection — the screen component file alone does not make a route reachable:

```
### Routing & Navigation
- Route file: <router-entry-path>     # file that registers the screen in the router
                                       # e.g. mobile/app/auth/login.tsx for Expo Router
- Nav entry: <ScreenName> → navigates via <element> on <ParentScreen>
- Layout: <which layout file this screen joins, or 'create <group>/_layout'>
- Deep-link: <scheme://path> or N/A
```

**Rules:**
- Every new router directory must have a layout file — include it in FORMAT if it does
  not already exist at that path in the repo.
- Project-specific routing conventions (URL prefixes, group naming) belong in the project's
  TDD orchestrator config, not here.
- Omitting this subsection from a screen-introducing contract blocks the pre-RED gate.

### FAILURE CONDITIONS

Checkbox list. Each maps to a specific REQ-### and becomes a RED phase test.

```
- [ ] Score calculator accepts values outside 0-5 range without error (REQ-001)
- [ ] Calculated score falls outside 0-100 range (REQ-002)
- [ ] Score is not persisted to user's wellbeing history after submission (REQ-003)
- [ ] SOS overlay is not triggered when score < 52 (REQ-004)
- [ ] Test coverage below 90% (project config)
```

Minimum 2 failure conditions per contract (excluding coverage).

### Effort: [XS / S / M / L]

Single value. See effort scale reference.

### Dependencies

```
- Blocked by: CONTRACT-001 (if this contract needs CONTRACT-001's output)
- Blocks: CONTRACT-003, CONTRACT-004
```

Use "none" if no dependencies exist.
