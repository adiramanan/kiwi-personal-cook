import { Hono } from "hono";
import { serve } from "@hono/node-server";
import { config } from "./utils/config";
import { logger } from "./utils/logger";
import { authMiddleware } from "./middleware/auth";
import { rateLimitMiddleware } from "./middleware/rateLimit";
import { authRoutes } from "./routes/auth";
import { scanRoutes } from "./routes/scan";
import { quotaRoutes } from "./routes/quota";
import { accountRoutes } from "./routes/account";

const app = new Hono();

app.route("/", authRoutes);

app.use("/v1/*", authMiddleware);
app.use("/v1/scan", rateLimitMiddleware);
app.route("/", scanRoutes);
app.route("/", quotaRoutes);
app.route("/", accountRoutes);

serve({
  fetch: app.fetch,
  port: Number(config.PORT),
});

logger.info({ message: "Kiwi API started", port: config.PORT });
