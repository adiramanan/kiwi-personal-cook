# Kiwi Architecture

## System Overview
Kiwi is a SwiftUI iOS client backed by a small Hono API. The client captures a fridge image, strips metadata, uploads the image to the API, and renders detected ingredients plus recipe recommendations. The API validates and rate-limits requests, then calls OpenAI to generate structured recipe data before returning a validated response.

```
[iOS App] -> [Kiwi API] -> [OpenAI]
```

## Scan Data Flow
1. User captures or selects a fridge image.
2. The app strips EXIF/GPS metadata and compresses the image to <= 1 MB.
3. The app uploads the JPEG to `POST /v1/scan` with auth.
4. The API validates the image size/type and rate limit.
5. The API sends the image to OpenAI with a strict system prompt.
6. The API validates the JSON response against a schema.
7. The app renders ingredients and recipe cards.

## Auth Flow
1. User signs in with Apple and receives an identity token.
2. The app exchanges the token with `POST /v1/auth/apple`.
3. The API verifies the token with Apple and returns a session token.
4. The app stores the session token in Keychain and attaches it to all API calls.

## Rate Limiting
- Server enforces 4 scans/day per user.
- Client mirrors limits locally for quick UX feedback.

## Privacy Guarantees
- No image storage on Kiwi servers.
- Images are stripped of metadata before upload.
- Logs are anonymized and redact raw images and prompts.

## Component Diagram
```
+---------------------+     +-----------------+     +------------------+
| SwiftUI iOS Client  | --> | Kiwi API (Hono) | --> | OpenAI (gpt-4o)  |
| - Image processing  |     | - Auth/Rate     |     | - Vision/Recipes |
| - UI/UX + MVVM      |     | - Validation    |     | - JSON output    |
+---------------------+     +-----------------+     +------------------+
```
