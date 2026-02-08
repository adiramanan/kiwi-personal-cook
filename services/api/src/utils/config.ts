export interface Config {
  port: number;
  databaseUrl: string;
  openaiApiKey: string;
  appleTeamId: string;
  appleClientId: string;
  appleKeyId: string;
  logLevel: string;
}

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export function loadConfig(): Config {
  return {
    port: parseInt(process.env["PORT"] || "3000", 10),
    databaseUrl: requireEnv("DATABASE_URL"),
    openaiApiKey: requireEnv("OPENAI_API_KEY"),
    appleTeamId: requireEnv("APPLE_TEAM_ID"),
    appleClientId: requireEnv("APPLE_CLIENT_ID"),
    appleKeyId: requireEnv("APPLE_KEY_ID"),
    logLevel: process.env["LOG_LEVEL"] || "info",
  };
}
