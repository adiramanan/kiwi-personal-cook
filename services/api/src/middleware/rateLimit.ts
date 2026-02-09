import type { Context, Next } from "hono";
import { db } from "../db/client";

const DAILY_LIMIT = 4;

function nextReset(): string {
  const now = new Date();
  const next = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1, 0, 0, 0));
  return next.toISOString();
}

export async function rateLimitMiddleware(c: Context, next: Next) {
  const userId = c.get("userId") as string;
  const rows = await db`
    SELECT scan_count FROM scan_quota WHERE user_id = ${userId} AND scan_date = CURRENT_DATE
  `;
  const count = rows.length ? rows[0].scan_count : 0;
  if (count >= DAILY_LIMIT) {
    const resetsAt = nextReset();
    c.header("Retry-After", "86400");
    return c.json({ error: "rate_limit_exceeded", message: "You've reached your daily scan limit.", resetsAt }, 429);
  }
  await next();
}

export function incrementQuota(userId: string) {
  return db`
    INSERT INTO scan_quota (user_id, scan_count)
    VALUES (${userId}, 1)
    ON CONFLICT (user_id, scan_date)
    DO UPDATE SET scan_count = scan_quota.scan_count + 1
  `;
}
