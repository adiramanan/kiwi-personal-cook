import type { Context, Next } from "hono";
import type postgres from "postgres";
import { DAILY_SCAN_LIMIT } from "../models/quota.js";
import { logger, anonymizeUserId } from "../utils/logger.js";

function getNextMidnightUTC(): string {
  const now = new Date();
  const tomorrow = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1)
  );
  return tomorrow.toISOString();
}

export function rateLimitMiddleware(sql: postgres.Sql) {
  return async (c: Context, next: Next) => {
    const userId = c.get("userId") as string;

    if (!userId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    try {
      const rows = await sql`
        SELECT scan_count
        FROM scan_quota
        WHERE user_id = ${userId}
          AND scan_date = CURRENT_DATE
        LIMIT 1
      `;

      const currentCount = rows.length > 0 ? (rows[0].scan_count as number) : 0;

      if (currentCount >= DAILY_SCAN_LIMIT) {
        const resetsAt = getNextMidnightUTC();

        logger.info(
          { userId: anonymizeUserId(userId), currentCount },
          "Rate limit exceeded"
        );

        return c.json(
          {
            error: "rate_limit_exceeded",
            message: "You've reached your daily scan limit.",
            resetsAt,
          },
          429,
          {
            "Retry-After": resetsAt,
          }
        );
      }

      await next();
    } catch (error) {
      logger.error({ error }, "Rate limit middleware error");
      return c.json({ error: "internal_error" }, 500);
    }
  };
}
