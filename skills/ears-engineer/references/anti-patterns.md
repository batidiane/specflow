# EARS Anti-Patterns

These patterns appear in natural language requirements and must be resolved before writing EARS.
Never write a REQ-### from an anti-pattern — flag it as ⚠ AMBIGUOUS instead.

---

## Anti-Pattern 1: Subjective Quality Without Threshold

**Bad:** "The app should feel fast."
**Problem:** "Feel" is not measurable. Cannot write a test or SLA for it.
**Fix:** Identify the specific operation and define a measurable metric.
**Correct EARS:** "When the home screen mounts, the system shall render above-the-fold content within 300ms on a Pixel 6 class device."

---

## Anti-Pattern 2: Vague Actor

**Bad:** "Users can upload photos."
**Problem:** Which users? Authenticated? Subscribed? Under what conditions? What happens on failure?
**Fix:** Specify the subject, the trigger, and the error case as separate requirements.
**Correct EARS (event):** "When an authenticated user selects a photo from their device library, the system shall upload it to R2 and return a signed URL within 10 seconds."
**Correct EARS (conditional):** "If the photo upload fails, then the system shall display a user-facing error and retain the original selection for retry."

---

## Anti-Pattern 3: Bundled Requirements

**Bad:** "The system should handle authentication, refresh tokens, and redirect unauthenticated users."
**Problem:** Three separate behaviors in one sentence — each needs its own REQ-### for traceability.
**Fix:** Split into three separate EARS requirements, one per behavior.

---

## Anti-Pattern 4: Implementation Prescription

**Bad:** "The system shall use Redis to cache user preferences."
**Problem:** Requirements specify WHAT the system does, not HOW it is built. Technology choices belong in Prompt Contract CONSTRAINTS, not EARS requirements.
**Fix:** Write the observable behavior: "The system shall return user preferences within 50ms for 99% of authenticated requests."
The Prompt Contract CONSTRAINTS section then specifies: "Use Redis for the caching layer."

---

## Anti-Pattern 5: Negation of a Positive

**Bad:** "The system shall not fail to authenticate users."
**Problem:** Double negative — this is just "authenticate users" with extra words. The negative pattern is reserved for genuine prohibitions.
**Fix:** Write the positive: "When a user submits valid credentials, the system shall return a signed JWT within 2 seconds."
Use "shall not" only for permanent prohibitions: "The system shall not store plaintext passwords."

---

## Anti-Pattern 6: Unverifiable Requirement

**Bad:** "The system shall be secure."
**Problem:** No definition of "secure." Cannot pass or fail in any test.
**Fix:** Decompose into specific, testable requirements:
- "The system shall not expose JWT signing keys in any API response."
- "If a request lacks a valid Authorization header, then the system shall return HTTP 401."
- "The system shall not log user email addresses in any log level."

---

## Anti-Pattern 7: Wishful Future Tense

**Bad:** "The app should eventually support dark mode."
**Problem:** "Should" and "eventually" signal a wish, not a requirement.
**Fix:** Either it is in scope (write a real REQ-###) or it is out of scope (add to `.specflow/config.md` under `Out of Scope`). There is no middle ground.

---

## Anti-Pattern 8: Compound Condition

**Bad:** "If the user is offline and the session fails and the token expires, the system shall..."
**Problem:** Three simultaneous conditions make the requirement nearly untestable and impossible to trace.
**Fix:** Write separate requirements for each failure mode, or use the complex EARS pattern only for the most common combined case.
