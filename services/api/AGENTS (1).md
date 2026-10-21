# AGENTS.md — Kiwi API

## Running Locally

### Prerequisites

- Node.js (LTS)
- PostgreSQL database

### Environment Variables

Create a `.env` file (never commit this):

```
PORT=3000
DATABASE_URL=postgresql://localhost:5432/kiwi_dev
OPENAI_API_KEY=sk-...
APPLE_TEAM_ID=...
APPLE_CLIENT_ID=com.kiwi.app
APPLE_KEY_ID=...
LOG_LEVEL=info
```

### Install Dependencies

```sh
cd services/api && npm install
```

### Run Database Migrations

```sh
psql $DATABASE_URL < src/db/migrations/001_init.sql
```

### Start Development Server

```sh
cd services/api && npx tsx src/index.ts
```

The server starts on `http://localhost:3000`.

### Health Check

```sh
curl http://localhost:3000/health
```

## Running Tests

```sh
cd services/api && npx vitest run
```

## Type Checking

```sh
cd services/api && npx tsc --noEmit
```

## API Endpoints

| Method | Path | Auth | Rate Limited | Description |
|--------|------|------|-------------|-------------|
| POST | `/v1/auth/apple` | No | No | Sign in with Apple |
| POST | `/v1/scan` | Yes | Yes (4/day) | Upload fridge image |
| GET | `/v1/quota` | Yes | No | Check remaining scans |
| DELETE | `/v1/account` | Yes | No | Delete account |
| GET | `/health` | No | No | Health check |

## Technology Stack

- **Runtime**: Node.js (LTS)
- **Language**: TypeScript (strict mode)
- **Framework**: Hono
- **Database**: PostgreSQL (raw SQL, parameterized queries)
- **LLM**: OpenAI gpt-4o
- **Validation**: Zod
- **Auth**: Jose (Apple JWT verification)
- **Logging**: Pino
- **Testing**: Vitest
