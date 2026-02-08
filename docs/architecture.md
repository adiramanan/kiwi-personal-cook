# Kiwi — Architecture Overview

## System Overview

Kiwi is a personal chef / cooking assistant that helps people cook healthier meals using what's already in their fridge. The user takes a photo of their fridge, the app identifies ingredients via an LLM with vision capability, and returns 2–4 fast, low-effort recipe recommendations with substitution suggestions.

```
┌──────────────────┐       ┌──────────────────┐       ┌──────────────────┐
│   iOS App        │       │   Kiwi API       │       │   OpenAI         │
│   (SwiftUI)      │◄─────►│   (Hono/Node.js) │◄─────►│   (gpt-4o)       │
│                  │ HTTPS │                  │ HTTPS │                  │
└──────────────────┘       └───────┬──────────┘       └──────────────────┘
                                   │
                                   │ SQL
                                   ▼
                           ┌──────────────────┐
                           │   PostgreSQL     │
                           │   Database       │
                           └──────────────────┘
```

## Component Diagram

```
iOS App
├── App Layer
│   ├── KiwiApp.swift          — @main entry, auth-based routing
│   └── AppState.swift         — Observable auth state, session management
├── Features
│   ├── Scan                   — Camera/library picker, quota display
│   ├── Results                — Ingredient list, recipe cards
│   ├── RecipeDetail           — Steps, substitutions, time-saving tips
│   └── Account                — Sign in with Apple, settings, deletion
├── Domain
│   ├── Models                 — Ingredient, Recipe, ScanResponse, QuotaInfo
│   └── UseCases               — ScanFridge, GetQuota, DeleteAccount
├── Data
│   ├── Network                — APIClient, Endpoint, APIError, AuthInterceptor
│   ├── Auth                   — AuthService, KeychainHelper
│   ├── ImageProcessing        — ImageMetadataStripper (EXIF removal)
│   └── RateLimit              — ClientRateLimiter (UX convenience)
└── Shared
    ├── Components             — LoadingView, ErrorView, PrimaryButton
    └── Theme                  — Colors, Typography

Kiwi API (Node.js / Hono)
├── Routes
│   ├── POST /v1/auth/apple    — Sign in with Apple verification
│   ├── POST /v1/scan          — Image upload + LLM analysis
│   ├── GET  /v1/quota         — Remaining scans for today
│   └── DELETE /v1/account     — Account deletion (cascade)
├── Middleware
│   ├── Auth                   — Bearer token validation
│   └── RateLimit              — 4 scans/day enforcement
├── Services
│   ├── AppleAuth              — JWT verification, session creation
│   ├── LLM                    — OpenAI gpt-4o integration
│   └── ImageValidator         — JPEG validation, size checks
├── Schema
│   └── ScanResponse           — Zod validation schema
└── Database
    └── PostgreSQL             — Users, sessions, scan_quota
```

## Data Flow: Scan Operation

1. **Image Capture**: User takes photo or selects from library
2. **Metadata Strip**: `ImageMetadataStripper` removes all EXIF, GPS, TIFF metadata
3. **Compress**: JPEG compression to ≤ 1 MB with iterative quality reduction
4. **Upload**: `POST /v1/scan` with multipart form data, Bearer auth token
5. **Server Validation**: Check JPEG content type, ≤ 2 MB, valid magic bytes
6. **Rate Limit Check**: Verify user has < 4 scans today
7. **LLM Request**: Base64-encode image, send to OpenAI gpt-4o with system prompt
8. **Response Validation**: Parse JSON, validate with Zod schema
9. **Quota Increment**: Update `scan_quota` table
10. **Render**: Display ingredients and recipe cards in the app

## Auth Flow

1. User taps "Sign in with Apple" button
2. iOS presents the Apple sign-in sheet
3. On success, the `ASAuthorizationAppleIDCredential` provides an identity token (JWT)
4. Client sends identity token to `POST /v1/auth/apple`
5. Server verifies JWT using Apple's public keys (JWKS)
6. Server validates issuer, audience, and expiry
7. Server upserts user in `users` table
8. Server creates a session with a cryptographically random token (30-day expiry)
9. Session token is returned to client and stored in Keychain
10. All subsequent API requests include `Authorization: Bearer <token>`
11. On 401 response, client triggers sign-out

## Rate Limiting Strategy

- **Server is authoritative**: The `scan_quota` table tracks scan counts per user per day
- **Limit**: 4 scans per user per day, resets at midnight UTC
- **Client mirrors**: `ClientRateLimiter` stores timestamps in UserDefaults for instant UX feedback
- **When exceeded**: Server returns 429 with `Retry-After` header; client shows friendly message

## Privacy Guarantees

1. **No image storage**: Images are processed in memory and never persisted on Kiwi servers
2. **Metadata stripped**: EXIF, GPS, TIFF, and IPTC metadata are removed client-side before upload
3. **Re-encoding**: Images are re-encoded as clean JPEGs via CGImageSource/CGImageDestination
4. **Anonymized logging**: User IDs are truncated to 8 characters in logs; no raw images logged
5. **Account deletion**: Cascade deletes remove all user data (sessions, quota records)
6. **Keychain storage**: Session tokens stored in iOS Keychain, not UserDefaults
7. **Clear disclosure**: Privacy explanation shown on sign-in screen and in account settings
