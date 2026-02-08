import { Hono } from "hono";
import type postgres from "postgres";
import { logger, anonymizeUserId } from "../utils/logger.js";

export function accountRoutes(sql: postgres.Sql) {
  const router = new Hono();

  router.delete("/", async (c) => {
    const userId = c.get("userId") as string;

    try {
      // Delete user — cascading deletes handle sessions and scan_quota
      await sql`
        DELETE FROM users WHERE id = ${userId}
      `;

      logger.info(
        { userId: anonymizeUserId(userId) },
        "Account deleted"
      );

      return c.json({ deleted: true });
    } catch (error) {
      logger.error(
        { error, userId: anonymizeUserId(userId) },
        "Account deletion failed"
      );
      return c.json({ error: "internal_error" }, 500);
    }
  });

  return router;
}
