const REQUIRED_VARS = [
  "DATABASE_URL",
  "OPENAI_API_KEY",
  "APPLE_TEAM_ID",
  "APPLE_CLIENT_ID",
  "APPLE_KEY_ID",
] as const;

function required(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

function optional(name: string, defaultValue: string): string {
  return process.env[name] ?? defaultValue;
}

// Getters keep this module side-effect free on import; call validateConfig()
// at startup to fail fast on missing variables.
export const config = {
  get port(): number {
    return parseInt(optional("PORT", "3000"), 10);
  },
  get databaseUrl(): string {
    return required("DATABASE_URL");
  },
  get openaiApiKey(): string {
    return required("OPENAI_API_KEY");
  },
  get appleTeamId(): string {
    return required("APPLE_TEAM_ID");
  },
  get appleClientId(): string {
    return required("APPLE_CLIENT_ID");
  },
  get appleKeyId(): string {
    return required("APPLE_KEY_ID");
  },
  get logLevel(): string {
    return optional("LOG_LEVEL", "info");
  },
  get dailyScanLimit(): number {
    return parseInt(optional("DAILY_SCAN_LIMIT", "40"), 10);
  },
} as const;

export function validateConfig(): void {
  for (const name of REQUIRED_VARS) {
    required(name);
  }
}
