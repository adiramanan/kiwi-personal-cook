import { z } from "zod";

const ConfigSchema = z.object({
  PORT: z.string().default("3000"),
  DATABASE_URL: z.string().min(1),
  OPENAI_API_KEY: z.string().min(1),
  APPLE_TEAM_ID: z.string().min(1),
  APPLE_CLIENT_ID: z.string().min(1),
  APPLE_KEY_ID: z.string().min(1),
  LOG_LEVEL: z.string().default("info"),
});

export type Config = z.infer<typeof ConfigSchema>;

export const config: Config = ConfigSchema.parse({
  PORT: process.env.PORT ?? "3000",
  DATABASE_URL: process.env.DATABASE_URL,
  OPENAI_API_KEY: process.env.OPENAI_API_KEY,
  APPLE_TEAM_ID: process.env.APPLE_TEAM_ID,
  APPLE_CLIENT_ID: process.env.APPLE_CLIENT_ID,
  APPLE_KEY_ID: process.env.APPLE_KEY_ID,
  LOG_LEVEL: process.env.LOG_LEVEL ?? "info",
});
