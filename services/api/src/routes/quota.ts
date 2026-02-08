import { Hono } from "hono";
import type postgres from "postgres";
import { DAILY_SCAN_LIMIT } from "../models/quota.js";

function getNextMidnightUTC(): string {
  const now = new Date();
  const tomorrow = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1)
  );
  return tomorrow.toISOString();
}

export function quotaRoutes(sql: postgres.Sql) {
  const router = new Hono();

  router.get("/", async (c) => {
    const userId = c.get("userId") as string;

    try {
      const rows = await sql`
        SELECT scan_count
        FROM scan_quota
        WHERE user_id = ${userId}
          AND scan_date = CURRENT_DATE
        LIMIT 1
      `;

      const scanCount = rows.length > 0 ? (rows[0].scan_count as number) : 0;
      const remaining = Math.max(0, DAILY_SCAN_LIMIT - scanCount);

      return c.json({
        remaining,
        limit: DAILY_SCAN_LIMIT,
        resetsAt: getNextMidnightUTC(),
      });
    } catch (error) {
      return c.json({ error: "internal_error" }, 500);
    }
  });

  return router;
}
