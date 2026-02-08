import { Hono } from "hono";
import { serve } from "@hono/node-server";
import { loadConfig } from "./utils/config.js";
import { logger } from "./utils/logger.js";
import { getDb } from "./db/client.js";
import { authMiddleware } from "./middleware/auth.js";
import { rateLimitMiddleware } from "./middleware/rateLimit.js";
import { authRoutes } from "./routes/auth.js";
import { scanRoutes } from "./routes/scan.js";
import { quotaRoutes } from "./routes/quota.js";
import { accountRoutes } from "./routes/account.js";

export function createApp(sql: ReturnType<typeof getDb>, config: ReturnType<typeof loadConfig>) {
  const app = new Hono();

  // Health check (unauthenticated)
  app.get("/health", (c) => c.json({ status: "ok" }));

  // Auth routes (unauthenticated — this is where users get their session token)
  app.route("/v1/auth", authRoutes(sql, config));

  // All other /v1/* routes require authentication
  app.use("/v1/*", authMiddleware(sql));

  // Scan route — also has rate limiting
  const scanRouter = new Hono();
  scanRouter.use("*", rateLimitMiddleware(sql));
  scanRouter.route("/", scanRoutes(sql, config));
  app.route("/v1/scan", scanRouter);

  // Quota route
  app.route("/v1/quota", quotaRoutes(sql));

  // Account route
  app.route("/v1/account", accountRoutes(sql));

  return app;
}

// Only start the server if this is the main module
const isMainModule = process.argv[1]?.endsWith("index.ts") || process.argv[1]?.endsWith("index.js");

if (isMainModule) {
  try {
    const config = loadConfig();
    const sql = getDb(config.databaseUrl);

    const app = createApp(sql, config);

    serve({
      fetch: app.fetch,
      port: config.port,
    });

    logger.info({ port: config.port }, "Kiwi API server started");
  } catch (error) {
    logger.fatal({ error }, "Failed to start server");
    process.exit(1);
  }
}
