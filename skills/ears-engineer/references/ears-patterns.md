# EARS Pattern Reference

EARS (Easy Approach to Requirements Syntax) constrains natural language to eliminate ambiguity.
Every requirement must match exactly one pattern.

## 1. Ubiquitous
Always active. No trigger, no state dependency.

**Template:** `The system shall [action].`

**Examples:**
- The system shall encrypt all data at rest using AES-256.
- The system shall respond to all API requests within 500ms at the 95th percentile.
- The system shall support a minimum of 1,000 concurrent authenticated sessions.

**Use when:** The behavior is unconditional and permanent — it applies always.

---

## 2. Event-Driven
Activates in response to a specific trigger.

**Template:** `When [trigger event], the system shall [action].`

**Examples:**
- When the user submits a WHO-5 assessment, the system shall calculate a wellbeing score and persist it to the user's history.
- When a network request fails, the system shall retry up to 3 times with exponential backoff (1s, 2s, 4s).
- When the app enters the background, the system shall pause all audio playback immediately.

**Use when:** The behavior has a clear, discrete initiating event.

---

## 3. State-Driven
Active only while the system is in a particular state.

**Template:** `While [system state], the system shall [action].`

**Examples:**
- While the user is unauthenticated, the system shall redirect all protected route accesses to the login screen.
- While offline, the system shall queue all write operations in AsyncStorage for sync on reconnect.
- While a meditation session is active, the system shall suppress all push notifications.

**Use when:** The behavior is continuous and depends on a sustained application or user state.

---

## 4. Conditional (Unwanted Behavior)
Response to an undesired or boundary condition.

**Template:** `If [condition], then the system shall [response].`

**Examples:**
- If the wellbeing score is below 52, then the system shall surface the SOS overlay within 500ms of score display.
- If a sync attempt fails three times consecutively, then the system shall alert the user and retain all queued data locally.
- If the JWT token is expired, then the system shall return HTTP 401 with error code `token_expired`.

**Use when:** Specifying error handling, safety nets, security responses, or edge case behavior.

---

## 5. Negative
Explicit, permanent prohibition.

**Template:** `The system shall not [action].`

**Examples:**
- The system shall not log user journal content in any environment.
- The system shall not expose raw Cloudflare R2 object paths in API responses.
- The system shall not retain SOS session data after the overlay is dismissed.

**Use when:** Specifying security rules, privacy constraints, or behaviors that must never occur.
Reserve for genuine prohibitions — not for "do X but don't fail at X."

---

## 6. Complex (State + Event)
Combines a sustained state with a discrete trigger.

**Template:** `While [state], when [event], the system shall [action].`

**Examples:**
- While the user has an active premium subscription, when they complete a session, the system shall unlock the next session in the series.
- While offline, when the user attempts to start a premium session, the system shall display a cached fallback message and disable the start button.

**Use when:** The trigger only matters while a specific state is active.

---

## Requirement ID Format

- Prefix: `REQ-` followed by zero-padded 3-digit number
- Example: `REQ-001`, `REQ-042`
- Scope: IDs restart at REQ-001 in each feature document
- IDs never carry across feature documents
