# AGENTS.md — Kiwi API

## Run locally
```sh
cd services/api
npm install
npx tsx src/index.ts
```

## Tests
```sh
cd services/api
npx vitest run
```

## Environment
Required variables:
- PORT
- DATABASE_URL
- OPENAI_API_KEY
- APPLE_TEAM_ID
- APPLE_CLIENT_ID
- APPLE_KEY_ID
- LOG_LEVEL

## Database
Apply migrations from `src/db/migrations` using your Postgres tooling before running the API.
