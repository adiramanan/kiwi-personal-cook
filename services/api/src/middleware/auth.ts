import type { Context, Next } from "hono";
import type postgres from "postgres";
import { logger, anonymizeUserId } from "../utils/logger.js";

declare module "hono" {
  interface ContextVariableMap {
    userId: string;
    db: postgres.Sql;
  }
}

export function authMiddleware(sql: postgres.Sql) {
  return async (c: Context, next: Next) => {
    const authHeader = c.req.header("Authorization");

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return c.json({ error: "unauthorized", message: "Missing or invalid authorization header" }, 401);
    }

    const token = authHeader.slice(7);

    if (!token) {
      return c.json({ error: "unauthorized", message: "Missing token" }, 401);
    }

    try {
      const sessions = await sql`
        SELECT s.user_id, s.expires_at
        FROM sessions s
        WHERE s.token = ${token}
        LIMIT 1
      `;

      if (sessions.length === 0) {
        return c.json({ error: "unauthorized", message: "Invalid token" }, 401);
      }

      const session = sessions[0];
      const expiresAt = new Date(session.expires_at as string);

      if (expiresAt < new Date()) {
        // Clean up expired session
        await sql`DELETE FROM sessions WHERE token = ${token}`;
        return c.json({ error: "unauthorized", message: "Session expired" }, 401);
      }

      const userId = session.user_id as string;
      c.set("userId", userId);
      c.set("db", sql);

      logger.debug(
        { userId: anonymizeUserId(userId) },
        "Authenticated request"
      );

      await next();
    } catch (error) {
      logger.error({ error }, "Auth middleware error");
      return c.json({ error: "internal_error", message: "Authentication failed" }, 500);
    }
  };
}
