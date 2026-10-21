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

export const config = {
  port: parseInt(optional("PORT", "3000"), 10),
  databaseUrl: required("DATABASE_URL"),
  openaiApiKey: required("OPENAI_API_KEY"),
  appleTeamId: required("APPLE_TEAM_ID"),
  appleClientId: required("APPLE_CLIENT_ID"),
  appleKeyId: required("APPLE_KEY_ID"),
  logLevel: optional("LOG_LEVEL", "info"),
  dailyScanLimit: parseInt(optional("DAILY_SCAN_LIMIT", "40"), 10),
} as const;
