# Effort Scale Reference

Effort estimates determine task sizing and splitting decisions. Every contract
must have exactly one effort estimate.

---

## Scale

| Size | Duration | AI Session | Examples |
|------|----------|------------|---------|
| **XS** | < 30 min | Single prompt | Config file, locale strings, add dependency, constants, type definition |
| **S** | 30 min – 2h | 1-2 prompts | Simple component, single API endpoint, utility function, Zustand slice, single migration |
| **M** | 2 – 4h | 2-4 prompts | Complex screen, multi-step form, state machine, API handler + domain + tests, multi-table migration |
| **L** | 4 – 8h | 4-8 prompts | Full player implementation, animation system, integration layer, E2E flow with multiple screens |

---

## Splitting Rules

**If effort exceeds L, the contract MUST be split.** No exceptions.

**Split strategies:**
1. **By layer:** Separate domain logic, handler, UI component, and store into individual contracts
2. **By state:** Separate happy path from error handling into individual contracts
3. **By screen:** Separate each screen or modal into its own contract
4. **By endpoint:** Separate each API endpoint into its own contract

**After splitting:** Re-check dependencies. The new contracts may introduce new blocked-by relationships.

---

## Effort Aggregation

When computing Feature and Epic totals:

| Operation | Formula |
|-----------|---------|
| Feature effort | Sum of task efforts (report as count per size) |
| Epic effort | Sum of feature efforts |
| Critical path effort | Sum of efforts along the longest dependency chain |

**Report format:** `XS(2) S(3) M(1) L(1)` — meaning 2 XS, 3 S, 1 M, 1 L tasks.

---

## Estimation Guidance

When the contract writer assigns effort, consider:

- **File count:** 1 file = XS/S, 2-3 files = S/M, 4+ files = M/L
- **Test complexity:** Table-driven tests = S, integration tests = M, E2E = L
- **State management:** Stateless = XS/S, single store = S/M, cross-store coordination = M/L
- **External dependencies:** None = subtract one size, API + DB = add one size
- **Animation:** Static UI = no impact, Reanimated worklets = add one size, Lottie sequences = add one size
