import { Hono } from "hono";
import { db } from "../db/client";

export const quotaRoutes = new Hono();

function nextReset(): string {
  const now = new Date();
  const next = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1, 0, 0, 0));
  return next.toISOString();
}

quotaRoutes.get("/v1/quota", async (c) => {
  const userId = c.get("userId") as string;
  const rows = await db`
    SELECT scan_count FROM scan_quota WHERE user_id = ${userId} AND scan_date = CURRENT_DATE
  `;
  const count = rows.length ? rows[0].scan_count : 0;
  const remaining = Math.max(0, 4 - count);
  return c.json({ remaining, limit: 4, resetsAt: nextReset() });
});
