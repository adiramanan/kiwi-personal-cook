import pino from "pino";

export const logger = pino({
  level: process.env.LOG_LEVEL ?? "info",
  redact: {
    paths: ["req.headers.authorization", "email"],
    censor: "[REDACTED]",
  },
  serializers: {
    userId: (id: string) => (id ? id.substring(0, 8) + "..." : undefined),
  },
});

export function requestLogger(requestId: string) {
  return logger.child({ requestId });
}
