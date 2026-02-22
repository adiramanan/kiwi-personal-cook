import "dotenv/config";
import { Hono } from "hono";
import { serve } from "@hono/node-server";
import { authMiddleware } from "./middleware/auth.js";
import { rateLimitMiddleware } from "./middleware/rateLimit.js";
import { requestLoggerMiddleware } from "./middleware/requestLogger.js";
import authRoutes from "./routes/auth.js";
import scanRoutes from "./routes/scan.js";
import quotaRoutes from "./routes/quota.js";
import accountRoutes from "./routes/account.js";
import { logger } from "./utils/logger.js";

const app = new Hono();

app.use("*", requestLoggerMiddleware);

app.get("/health", (c) => c.json({ status: "ok" }));

app.route("/v1/auth", authRoutes);

app.use("/v1/*", authMiddleware);

app.use("/v1/scan/*", rateLimitMiddleware);

app.route("/v1/scan", scanRoutes);
app.route("/v1/quota", quotaRoutes);
app.route("/v1/account", accountRoutes);

app.onError((err, c) => {
  logger.error({ error: err.message }, "Unhandled error");
  return c.json({ error: "internal_server_error" }, 500);
});

const port = parseInt(process.env.PORT ?? "3000", 10);

serve({ fetch: app.fetch, port }, () => {
  logger.info({ port }, "Kiwi API server started");
});

export default app;
