import "dotenv/config";
import { Hono } from "hono";
import { serve } from "@hono/node-server";
import { authMiddleware } from "./middleware/auth.js";
import { rateLimitMiddleware } from "./middleware/rateLimit.js";
import { requestLoggerMiddleware } from "./middleware/requestLogger.js";
import authRoutes from "./routes/auth.js";
import scanRoutes from "./routes/scan.js";
import kitchenRoutes from "./routes/kitchen.js";
import quotaRoutes from "./routes/quota.js";
import accountRoutes from "./routes/account.js";
import { logger } from "./utils/logger.js";
import { runMigrations } from "./utils/migrate.js";
import { config, validateConfig } from "./utils/config.js";
import { closeDb } from "./db/client.js";

const app = new Hono();

app.use("*", requestLoggerMiddleware);

app.get("/health", (c) => c.json({ status: "ok" }));

app.route("/v1/auth", authRoutes);

app.use("/v1/*", authMiddleware);

app.use("/v1/scan/*", rateLimitMiddleware);

app.route("/v1/scan", scanRoutes);
app.route("/v1/quota", quotaRoutes);
app.route("/v1/account", accountRoutes);
app.route("/v1/kitchen", kitchenRoutes);

app.onError((err, c) => {
  logger.error({ error: err.message }, "Unhandled error");
  return c.json({ error: "internal_server_error" }, 500);
});

validateConfig();

const port = config.port;

await runMigrations();

const server = serve({ fetch: app.fetch, port }, () => {
  logger.info({ port }, "Kiwi API server started");
});

async function shutdown(signal: string): Promise<void> {
  logger.info({ signal }, "Shutting down");
  server.close(async () => {
    await closeDb();
    process.exit(0);
  });
  // Force-exit if connections refuse to drain
  setTimeout(() => process.exit(1), 10_000).unref();
}

process.on("SIGTERM", () => void shutdown("SIGTERM"));
process.on("SIGINT", () => void shutdown("SIGINT"));

export default app;
