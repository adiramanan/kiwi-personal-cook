import type { Context, Next } from "hono";
import type { AppEnv } from "../types.js";
import { findSession } from "../models/user.js";
import { logger } from "../utils/logger.js";

export async function authMiddleware(c: Context<AppEnv>, next: Next) {
  const authHeader = c.req.header("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    logger.warn("Missing or invalid authorization header");
    return c.json({ error: "unauthorized" }, 401);
  }

  const token = authHeader.slice(7);
  const session = await findSession(token);

  if (!session) {
    logger.warn("Session not found");
    return c.json({ error: "unauthorized" }, 401);
  }

  if (new Date(session.expiresAt) < new Date()) {
    logger.warn("Session expired");
    return c.json({ error: "unauthorized" }, 401);
  }

  c.set("userId", session.userId);
  await next();
}
