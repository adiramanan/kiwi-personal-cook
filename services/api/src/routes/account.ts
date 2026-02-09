import { Hono } from "hono";
import { db } from "../db/client";

export const accountRoutes = new Hono();

accountRoutes.delete("/v1/account", async (c) => {
  const userId = c.get("userId") as string;
  await db`
    DELETE FROM users WHERE id = ${userId}
  `;
  return c.json({ deleted: true });
});
