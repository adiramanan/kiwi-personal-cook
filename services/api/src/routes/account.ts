import { Hono } from "hono";
import type { AppEnv } from "../types.js";
import { deleteUser } from "../models/user.js";
import { logger } from "../utils/logger.js";

const account = new Hono<AppEnv>();

account.delete("/", async (c) => {
  const userId = c.get("userId");

  await deleteUser(userId);

  logger.info({ userId: userId.substring(0, 8) }, "Account deleted");

  return c.json({ deleted: true });
});

export default account;
