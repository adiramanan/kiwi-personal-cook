import pino from "pino";

const logLevel = process.env["LOG_LEVEL"] || "info";

export const logger = pino({
  level: logLevel,
  formatters: {
    level(label: string) {
      return { level: label };
    },
  },
  timestamp: pino.stdTimeFunctions.isoTime,
  redact: {
    paths: ["req.headers.authorization", "email"],
    censor: "[REDACTED]",
  },
});

/**
 * Truncate a user ID to the first 8 characters for privacy-preserving logging.
 */
export function anonymizeUserId(userId: string): string {
  return userId.substring(0, 8);
}

export type Logger = typeof logger;
