import { Hono } from "hono";
import type postgres from "postgres";
import { verifyAppleIdentityToken, createSession } from "../services/appleAuth.js";
import { logger } from "../utils/logger.js";
import type { Config } from "../utils/config.js";

export function authRoutes(sql: postgres.Sql, config: Config) {
  const router = new Hono();

  router.post("/apple", async (c) => {
    try {
      const body = await c.req.json();
      const { identityToken } = body as { identityToken: string };

      if (!identityToken) {
        return c.json({ error: "missing_token", message: "identityToken is required" }, 400);
      }

      // Decode from base64 if needed
      let tokenString: string;
      try {
        // The token may be sent as base64-encoded JWT
        tokenString = Buffer.from(identityToken, "base64").toString("utf-8");
        // If it doesn't look like a JWT, use as-is
        if (!tokenString.includes(".")) {
          tokenString = identityToken;
        }
      } catch {
        tokenString = identityToken;
      }

      const payload = await verifyAppleIdentityToken(
        tokenString,
        config.appleClientId
      );

      const { sessionToken, expiresAt } = await createSession(
        sql,
        payload.sub,
        payload.email
      );

      return c.json({
        sessionToken,
        expiresAt: expiresAt.toISOString(),
      });
    } catch (error) {
      logger.error({ error }, "Apple auth failed");
      return c.json({ error: "invalid_token" }, 401);
    }
  });

  return router;
}
