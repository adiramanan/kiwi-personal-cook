import { Hono } from "hono";
import type { AppEnv } from "../types.js";
import { getQuota } from "../models/quota.js";

const quota = new Hono<AppEnv>();

quota.get("/", async (c) => {
  const userId = c.get("userId");
  const quotaInfo = await getQuota(userId);
  return c.json(quotaInfo);
});

export default quota;
