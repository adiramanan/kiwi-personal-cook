import type { Context, Next } from "hono";
import { db } from "../db/client";

export async function authMiddleware(c: Context, next: Next) {
  const header = c.req.header("Authorization");
  if (!header || !header.startsWith("Bearer ")) {
    return c.json({ error: "unauthorized" }, 401);
  }
  const token = header.replace("Bearer ", "");
  const sessions = await db`
    SELECT user_id, expires_at FROM sessions WHERE token = ${token}
  `;
  if (sessions.length === 0) {
    return c.json({ error: "unauthorized" }, 401);
  }
  const session = sessions[0];
  if (new Date(session.expires_at) < new Date()) {
    return c.json({ error: "unauthorized" }, 401);
  }
  c.set("userId", session.user_id);
  await next();
}
