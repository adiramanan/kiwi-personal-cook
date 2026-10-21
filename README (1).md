# Kiwi Personal Cook

Kiwi is a personal cooking assistant that turns a fridge photo into a short list of detected ingredients and 2-4 quick recipe suggestions.

## Repo Layout

- `apps/ios` - SwiftUI iOS client (feature-first MVVM)
- `services/api` - Hono + TypeScript backend API
- `docs` - architecture, build notes, and [project status / roadmap](docs/PROJECT_STATUS.md)

## iOS (Scaffold)

The iOS source code is scaffolded under `apps/ios/Kiwi/Kiwi` with feature, domain, data, and shared layers plus unit/UI test directories.

## API

```sh
cd services/api
npm install
npx tsx src/index.ts
```

Run tests:

```sh
cd services/api
npx vitest run
npx tsc --noEmit
```
