import { Hono } from "hono";
import { verifyAppleToken } from "../services/appleAuth.js";
import { upsertUser, createSession } from "../models/user.js";
import { logger } from "../utils/logger.js";

const auth = new Hono();

auth.post("/apple", async (c) => {
  const body = await c.req.json<{ identityToken: string }>();

  if (!body.identityToken) {
    return c.json({ error: "missing_token" }, 400);
  }

  try {
    const clientId = process.env.APPLE_CLIENT_ID!;
    const payload = await verifyAppleToken(body.identityToken, clientId);

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
