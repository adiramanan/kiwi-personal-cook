import { Hono } from "hono";
import { verifyAppleToken } from "../services/appleAuth.js";
import { upsertUser, createSession } from "../models/user.js";
import { logger } from "../utils/logger.js";
import { config } from "../utils/config.js";

const auth = new Hono();

auth.post("/apple", async (c) => {
  const body = await c.req.json<{ identityToken: string }>();

  if (!body.identityToken) {
    return c.json({ error: "missing_token" }, 400);
  }

  try {
    const payload = await verifyAppleToken(body.identityToken, config.appleClientId);

    const user = await upsertUser(payload.sub, payload.email ?? null);
    const session = await createSession(user.id);

    logger.info(
      { userId: user.id.substring(0, 8) },
      "User authenticated"
    );

    return c.json({
      sessionToken: session.token,
      expiresAt: session.expiresAt.toISOString(),
    });
  } catch (error) {
    logger.error({ error }, "Apple auth failed");
    return c.json({ error: "invalid_token" }, 401);
  }
});

export default auth;
