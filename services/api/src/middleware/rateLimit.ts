import type { Context, Next } from "hono";
import type { AppEnv } from "../types.js";
import { getScanCount } from "../models/quota.js";
import { logger } from "../utils/logger.js";

const DAILY_LIMIT = 4;

export async function rateLimitMiddleware(c: Context<AppEnv>, next: Next) {
  const userId = c.get("userId");
  const scanCount = await getScanCount(userId);

  if (scanCount >= DAILY_LIMIT) {
    const tomorrow = new Date();
    tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);
    tomorrow.setUTCHours(0, 0, 0, 0);

    const retryAfterSeconds = Math.ceil(
      (tomorrow.getTime() - Date.now()) / 1000
    );

    logger.warn({ userId: userId.substring(0, 8) }, "Rate limit exceeded");

    c.header("Retry-After", String(retryAfterSeconds));
    return c.json(
      {
        error: "rate_limit_exceeded",
        message: "You've reached your daily scan limit.",
        resetsAt: tomorrow.toISOString(),
      },
      429
    );
  }

  await next();
}
