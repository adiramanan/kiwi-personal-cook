# AGENTS.md — Kiwi

This file defines the operating contract for coding agents working in the **Kiwi** monorepo.

Kiwi is a personal chef / cooking assistant that helps people cook healthier meals using what's already in their fridge, reducing reliance on takeout and restaurants.

---

## 1) Scope

### 1.1 In scope (what Kiwi does)

- Accept a **fridge image** as the primary input.
- Identify ingredients present in the image.
- Generate **recipe recommendations** that:
  - Prefer using detected ingredients.
  - Allow **minor substitutions**.
  - Are optimized for fast, low-effort cooking.
- Support the user account lifecycle (Sign in, Settings, Delete account).

### 1.2 Out of scope (hard boundary)

Kiwi must only provide cooking-related assistance and meal recommendations.

- No unrelated assistant behavior.
- No browsing the user's personal data.
- No "general chatbot" features.

If a feature request is not directly tied to cooking guidance, ingredient detection, recipe suggestion, or app usability/privacy, treat it as out-of-scope and request explicit human direction.

---

## 2) Agent role, authority, and guardrails

This AGENTS.md governs the **coding agent**.

### 2.1 Allowed actions

- Modify code in-repo.
- Add or update tests.
- Run tests.
- Update documentation (including this file) when behavior or commands change.

### 2.2 Forbidden actions

- **No deployments** to any environment.
- **No infrastructure changes** without explicit human approval.
- **No deletions** (code/files/resources/data/logs) without explicit human approval.
- **No breaking changes** (API, data models, core UX flows) without explicit human approval.

### 2.3 When the agent must stop and ask for approval

- Any action that could be considered a breaking change.
- Any deletion.
- Any refactor affecting multiple features/modules.
- Any change to auth, data retention, logging, privacy posture, rate limits, or LLM prompts/policies.
- Any new third-party SDK or service integration.
- Any network access required by the agent's sandboxed environment.

### 2.4 How to handle ambiguity

- Ask a concise clarifying question.
- Prefer correctness over speed for anything security/privacy/auth/data related.
- If instructions conflict, ask for resolution before proceeding.

---

## 3) Repo structure and instruction precedence

Kiwi is a **monorepo**.

Recommended layout:

- `/AGENTS.md` — repo-wide rules (this file)
- `/apps/ios/AGENTS.md` — iOS-specific commands, schemes, snapshot rules
- `/services/api/AGENTS.md` — backend/API-specific rules
- `/packages/shared/AGENTS.md` — shared code rules

Rule: the agent should follow the **closest** AGENTS.md in the directory tree, with the root file providing baseline guardrails.

---

## 4) Product quality bar

Kiwi is built with a quality target high enough that, after incremental updates, it is a credible **Apple Design Awards** candidate.

Non-negotiables:

- Platform-native UX and interaction polish.
- Accessibility (Dynamic Type, VoiceOver, contrast, touch target sizing).
- Performance (no main-thread blocking for image processing / networking).
- Privacy-first UX (permission discipline, clear disclosures).

---

## 5) Technical architecture (recommended)

### 5.1 Goals for architecture

- SwiftUI-first, testable, scalable.
- Clear boundaries between UI state, business logic, and side effects (networking, storage, logging).
- Safe evolution for a fast-moving product without collapsing into "giant view model" complexity.

### 5.2 Chosen approach

**Feature-first modular MVVM with a light Clean-Architecture boundary**:

- **Feature-first modules**: organize by user-facing capability (Scan, Results, Recipe Detail, Account/Settings).
- **MVVM for SwiftUI**:
  - Views are declarative and minimal.
  - ViewModels own screen state + orchestration.
- **Domain/use-case layer**:
  - Pure logic for ranking recipes, applying substitutions, dietary preferences (if/when added).
- **Data layer**:
  - Networking, auth, rate limiting, and the LLM gateway client.
- **State management**:
  - Prefer native SwiftUI state and modern observable models (iOS 26+ target).

Why this is a good fit:

- Aligns naturally with SwiftUI's data-driven UI.
- Keeps business rules independent of UI so testing is reliable.
- Enables high UX polish with snapshot + UI tests protecting the design bar.

---

## 6) Platform + toolchain

- **Platform**: iOS (minimum deployment target: iOS 26.x).
- **UI**: SwiftUI.
- **Dependency management**: Swift Package Manager (SPM).
- **Concurrency**: prefer structured concurrency (async/await) and avoid callback pyramids.

---

## 7) Build, test, and CI expectations

### 7.1 Canonical commands

Keep these commands accurate. If they change, update this file in the same PR.

> Replace placeholders once the repo is initialized.

**Build (Debug):**
```sh
xcodebuild \
  -project apps/ios/Kiwi.xcodeproj \
  -scheme Kiwi \
  -configuration Debug \
  -destination "generic/platform=iOS Simulator" \
  build
```

**Unit + UI tests:**
```sh
xcodebuild \
  -project apps/ios/Kiwi.xcodeproj \
  -scheme Kiwi \
  -destination "generic/platform=iOS Simulator" \
  test
```

**SPM-only packages (if applicable):**
```sh
swift test
```

### 7.2 Testing requirements (mandatory)

For every new feature:

- Unit tests:
  - Domain/use-cases
  - Data/services
  - ViewModels
- UI tests:
  - Primary happy paths
  - Critical error states (network failure, rate limit exceeded)
- Snapshot tests:
  - Key SwiftUI views and states

If a test cannot be added, document why in the PR and propose an alternative.

### 7.3 CI quality gates (assume enforced)

- Build passes.
- Unit/UI/snapshot tests pass.
- No secrets committed.
- No unauthenticated endpoints.
- Lint/format checks pass (if configured).

---

## 8) Security, privacy, and AI safety

Kiwi's threat model is **high risk** due to:

- Untrusted image input (home environment content).
- Third-party AI processing.
- LLM prompt injection and insecure output handling risks.

### 8.1 Authentication and authorization

- Auth provider: **Sign in with Apple** (v1).
- **All network calls require auth** (including read-only).
- Prefer **zero trust** internally:
  - Treat every request as untrusted at the server boundary.
  - Enforce authorization and rate limits server-side.

### 8.2 Rate limiting and abuse prevention

- Rate limit target: **3–4 fridge image uploads per user per day**.
- Enforcement:
  - Server is authoritative.
  - Client mirrors the rule for better UX.
- When exceeded: hard stop (free tier), with a user-friendly explanation.

### 8.3 Image handling rules (non-negotiable)

- Images are processed and discarded.
  - No persistent storage on Kiwi servers.
  - On-device storage should be limited to OS-controlled photo picker/camera flows.
- Strip non-visual metadata before upload.
  - Remove EXIF/location/capture metadata.
  - Re-encode to a "visual-only" payload.
- The app must clearly explain:
  - Images are deleted after processing.

### 8.4 LLM integration rules

- Single LLM provider for v1.
- Later: optional abstraction layer (only with explicit approval).

**Output handling (mandatory):**

- Model output is **untrusted** until validated.
- Require structured output (e.g., strict JSON schema) and validate deterministically.
- Never allow model output to directly:
  - Trigger tool calls
  - Execute code
  - Perform network requests
  - Write files

**Prompt injection defense-in-depth:**

- Treat any text extracted from images as untrusted.
- Keep system prompts narrowly scoped to cooking assistance.
- Refuse out-of-scope requests.

### 8.5 Logging and telemetry

- Prompts and responses may be logged **only with anonymization/pseudonymization**.
- Log access must be least privilege and auditable.
- Crash logging: local only for now (no third-party crash reporting until approved).

### 8.6 Data deletion and account deletion

- Users must be able to delete their account from within the app.
- Deletion must remove the user account record and associated stored data.
- Any stored prompt/response logs associated with that user must be deleted (unless a legal retention requirement applies).

### 8.7 Secrets and configuration

- Never commit secrets.
- Use secure secret injection for CI and local dev.
- Prefer short-lived tokens.

---

## 9) UX + interaction requirements

### 9.1 Core flow requirements

- Scan flow:
  - Minimal steps from launch → image capture/pick → results.
  - Clear progress and error states.
- Results:
  - Show detected ingredients.
  - Allow quick edits (confirm/remove ingredients).
  - Provide 2–4 high-quality recipe options.
- Recipe detail:
  - Clear steps
  - Ingredients used vs missing
  - Substitution suggestions
  - "Make it faster" tip

### 9.2 Accessibility requirements

- Dynamic Type support.
- VoiceOver labels and logical navigation order.
- High-contrast, readable text.
- Large, tappable controls.

---

## 10) Deployment environments and human-only release process

Kiwi may use multiple environments:

- **Local / sandbox**: developer device and simulator testing.
- **Staging / internal**: internal builds (e.g., TestFlight internal testing) with staging backend.
- **Production**: App Store release + production backend.

Rules:

- The agent never deploys.
- Human-triggered deployments typically occur via:
  - CI pipelines (manual approvals)
  - App Store Connect / TestFlight submission steps
  - Infrastructure change management workflows

Document the exact release steps in `/docs/release.md` once the pipeline exists.

---

## 11) Change management

- Prefer small, incremental PRs.
- Large cohesive changes may be one PR, but only with explicit approval.
- The agent may suggest refactors, but must not perform large refactors without approval.
- Update documentation whenever behavior changes.
- Update this file whenever commands, structure, or non-negotiable policies change.

---

## 12) Backend/API (recommended baseline)

Kiwi can be implemented as an iOS client plus a small backend that:

- Verifies Sign in with Apple identity.
- Enforces rate limits and abuse prevention.
- Proxies calls to the LLM provider.
- Stores only what is necessary (account, quota counters, anonymized logs).

### 12.1 Minimal component diagram

- iOS App (SwiftUI)
  - Captures/selects image
  - Strips metadata + compresses
  - Calls Kiwi API with auth
  - Renders ingredient list + recipes
- Kiwi API
  - Auth verification (Apple)
  - Rate limiting (per user/day)
  - Image size/type validation
  - LLM request construction
  - Structured response validation
  - Logging (anonymized)
- LLM Provider
  - Receives image (or extracted ingredient candidates)
  - Returns structured recipes

### 12.2 API principles

- **Auth required everywhere**.
- Use explicit API versioning (e.g., `/v1/...`).
- Prefer small, explicit endpoints.
- Treat all input as untrusted; validate and normalize.

### 12.3 Recommended endpoints (v1)

- `POST /v1/scan`
  - Input: image payload (+ optional user-supplied preferences)
  - Output: detected ingredients + recipe options
- `GET /v1/quota`
  - Output: remaining image uploads for the day
- `DELETE /v1/account`
  - Output: deletion confirmation (async completion allowed)

### 12.4 Auth approach (v1)

- Client obtains Sign in with Apple identity token.
- Server verifies the token with Apple and issues a session token.
- Session token used for subsequent calls.

Notes:

- Do not rely solely on client enforcement.
- Treat user identifiers as pseudonymous; avoid collecting unnecessary PII.

---

## 13) Coding standards and repo hygiene

### 13.1 Swift standards

- Prefer readability over cleverness.
- Keep views small; extract subviews.
- Keep ViewModels focused on a single screen.
- Avoid singletons; use dependency injection.
- Use structured concurrency; avoid `Task {}` in view bodies unless carefully scoped.

### 13.2 Error handling

- All network calls must have typed error paths.
- UI must handle:
  - No network
  - Server errors
  - Rate limit exceeded
  - Invalid/partial model output
  - Cancelation

### 13.3 Dependencies

- Use SPM.
- Add third-party packages only with explicit approval.
- Pin versions and document why each dependency exists.

### 13.4 Linting/formatting (recommended)

- If adopted, keep it consistent and automatic in CI.
- Common choices:
  - SwiftFormat (formatting)
  - SwiftLint (lint)

---

## 14) Observability (privacy-preserving)

### 14.1 What to log

- Request IDs, timestamps, latency, status codes.
- Rate limit events.
- Validation failures (schema mismatches, parsing errors).

### 14.2 What not to log

- Raw images.
- EXIF/location metadata.
- Full user identifiers when pseudonyms suffice.

### 14.3 Redaction

- Redact any user-entered free text if/when it exists.
- Prefer structured logs with explicit fields.

---

## 15) Security testing and verification

Minimum expectations for changes touching auth/network/LLM:

- Unit tests for validation logic (schema, size/type checks).
- Negative tests for unauthenticated access.
- Rate limit tests (server-side).
- Snapshot/UI tests for error states.

Recommended repo tooling (add only with approval):

- Dependency vulnerability scanning.
- Secret scanning.
- Static analysis for Swift and server code.

---

## 16) PR checklist (agent must follow)

- [ ] No deletions without explicit approval.
- [ ] No breaking changes without explicit approval.
- [ ] Build passes locally (or in CI).
- [ ] Unit tests added/updated.
- [ ] UI/snapshot tests added/updated for user-visible changes.
- [ ] Privacy checks: no image storage, metadata stripped.
- [ ] Security checks: auth on all calls, input validated.
- [ ] Docs updated (including this file if behavior/commands changed).
