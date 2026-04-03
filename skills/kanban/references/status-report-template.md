# Status Report Template

The kanban status report follows this exact format. Sections with zero items are omitted.

---

## Full Report (all Epics)

```markdown
## specflow Status Report — YYYY-MM-DD

### Progress by Epic

| Epic | Progress | Done | Total |
|------|----------|------|-------|
| S1: Foundation | ████████░░ 80% | 8 | 10 |
| S2: Core Screens | ██░░░░░░░░ 20% | 3 | 14 |
| S3: Explore | ░░░░░░░░░░ 0% | 0 | 9 |

---

### ⏸ HITL Review (awaiting you)

| # | Label | Title | Since |
|---|-------|-------|-------|
| 47 | [API] | WHO-5 score calculator | 2d ago |
| 52 | [UI] | Home screen layout | 1d ago |

**Action needed:** Review REFACTOR plans and approve or request changes.

---

### 🔄 In Progress (Triad Active)

| # | Label | Title | Phase |
|---|-------|-------|-------|
| 44 | [UI] | Wellbeing gauge component | GREEN |
| 53 | [CORE] | Auth context provider | RED |

---

### ✅ Ready to Start

| # | Label | Title | Effort |
|---|-------|-------|--------|
| 48 | [UI] | WHO-5 assessment flow | M |
| 49 | [CORE] | Zustand wellbeing store | S |
| 55 | [API] | Score history endpoint | S |

**Suggested next:** Pick the top item or use `/specflow:implement {number}`.

---

### 🚫 Blocked

| # | Label | Title | Blocked by |
|---|-------|-------|-----------|
| 51 | [ANIM] | Score gauge animation | #47 |
| 56 | [UI] | History chart screen | #55 |

---

### 📦 Icebox

| # | Label | Title | Effort |
|---|-------|-------|--------|
| 60 | [TEST] | E2E: full assessment | M |
| 61 | [OBS] | Wellbeing metrics | S |
```

---

## Single Epic Report

When filtering by Epic (e.g., `/specflow:status S2`):

```markdown
## specflow Status: S2 — Core Screens — YYYY-MM-DD

Progress: ██░░░░░░░░ 20%  (3/14 Done)

### ⏸ HITL Review
  [same format, filtered to this Epic]

### 🔄 In Progress
  [same format, filtered]

### ✅ Ready to Start
  [same format, filtered]

### 🚫 Blocked
  [same format, filtered]

### 📦 Icebox
  [same format, filtered]
```

---

## Progress Bar Rendering

Use filled and empty block characters (10 total = 100%):

| Percentage | Bar |
|-----------|-----|
| 0% | ░░░░░░░░░░ |
| 10% | █░░░░░░░░░ |
| 20% | ██░░░░░░░░ |
| 30% | ███░░░░░░░ |
| 40% | ████░░░░░░ |
| 50% | █████░░░░░ |
| 60% | ██████░░░░ |
| 70% | ███████░░░ |
| 80% | ████████░░ |
| 90% | █████████░ |
| 100% | ██████████ |

Round to nearest 10% for display.

---

## Move Confirmation Template

```
Move #{number} "{title}"
From: {current-column}
To:   {target-column}

Proceed? [yes / no]
```

After successful move:
```
✓ Moved #{number} to {target-column}
```

After forbidden move:
```
✗ Cannot move #{number} from {current-column} to {target-column}
Reason: {explanation of forbidden transition}
Allowed transitions from {current-column}: {list of valid targets}
```

---

## Unblock Report Template

```markdown
## Unblock Report — YYYY-MM-DD

### Recently Completed
| # | Title | Completed |
|---|-------|-----------|
| 47 | WHO-5 score calculator | today |

### Now Unblocked
| # | Title | Was blocked by |
|---|-------|---------------|
| 51 | Score gauge animation | #47 ✓ |
| 58 | Score display component | #47 ✓ |

### Suggested Moves
```bash
/specflow:status move 51 "To Do (Ready)"
/specflow:status move 58 "To Do (Ready)"
```
```
