# Kiwi Personal Cook

Kiwi helps families cook toward their dietary goals using what is already in their fridge. Scan up to three photos into a saved ingredient inventory, add each person’s restrictions, tastes and optional meal targets, then find shared meals with tailored portions and estimated nutrition. See the [feature scope and API contract](docs/KITCHEN_FEATURES.md).

## Repo Layout

- `apps/ios` - SwiftUI iOS client (feature-first MVVM)
- `services/api` - Hono + TypeScript backend API
- `docs` - architecture, build notes, and [project status / roadmap](docs/PROJECT_STATUS.md)

## iOS

The iOS source lives under `apps/ios/Kiwi` with feature, domain, data, and shared layers plus unit/UI test directories.

### Run on your iPhone (development)

1. Start the API on your Mac (see below). The Debug build points at `http://MacBook-Air.local:3000` via the `API_BASE_URL` build setting — iPhone and Mac must be on the same Wi-Fi network.
2. Open `apps/ios/Kiwi.xcodeproj` in Xcode, plug in your iPhone (or use Wi-Fi debugging), select it as the run destination, and press Run.
3. First run only: on the iPhone, trust the developer profile via Settings > General > VPN & Device Management, and accept the Local Network permission prompt so the app can reach your Mac.

Release builds point at the production API URL configured in the `API_BASE_URL` build setting (Release configuration).

## API

Ingredient recognition and recipe generation use the hosted OpenAI `gpt-6-luna` model with low reasoning effort. Set `OPENAI_API_KEY` to a key whose project has access to that model; no local model installation is needed. Restart the API after updating the code or environment.

```sh
cd services/api
npm install
cp .env.example .env   # fill in DATABASE_URL, OPENAI_API_KEY, APPLE_* values
npx tsx src/index.ts
```

Run tests:

```sh
cd services/api
npx vitest run
npx tsc --noEmit
```
