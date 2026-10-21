import pino from "pino";
import { config } from "./config.js";

export const logger = pino({
  level: config.logLevel,
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
