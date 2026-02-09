import { Hono } from "hono";
import { verifyAppleToken, createSession } from "../services/appleAuth";

export const authRoutes = new Hono();

authRoutes.post("/v1/auth/apple", async (c) => {
  const body = await c.req.json<{ identityToken?: string }>();
  if (!body.identityToken) {
    return c.json({ error: "invalid_token" }, 401);
  }
  try {
    const { appleUserId, email } = await verifyAppleToken(body.identityToken);
    const session = await createSession(appleUserId, email);
    return c.json({ sessionToken: session.token, expiresAt: session.expiresAt });
  } catch {
    return c.json({ error: "invalid_token" }, 401);
  }
});
