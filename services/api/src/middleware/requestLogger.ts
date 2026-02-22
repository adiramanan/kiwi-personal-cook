import { randomUUID } from "node:crypto";
import type { Context, Next } from "hono";
import { requestLogger } from "../utils/logger.js";

export async function requestLoggerMiddleware(c: Context, next: Next) {
  const requestId = c.req.header("x-request-id") ?? randomUUID();
  const logger = requestLogger(requestId);
  const startTime = Date.now();
  let thrownError: unknown;

  c.header("x-request-id", requestId);

  try {
    await next();
  } catch (error) {
    thrownError = error;
    throw error;
  } finally {
    const latencyMs = Date.now() - startTime;
    const statusCode = thrownError ? 500 : c.res.status;

    if (thrownError || statusCode >= 500) {
      logger.error(
        {
          method: c.req.method,
          path: c.req.path,
          statusCode,
          latencyMs,
          error:
            thrownError instanceof Error
              ? thrownError.message
              : thrownError
              ? "unknown_error"
              : undefined,
        },
        "Request failed"
      );
      return;
    }

    logger.info(
      {
        method: c.req.method,
        path: c.req.path,
        statusCode,
        latencyMs,
      },
      "Request completed"
    );
  }
}
