import { beforeEach, describe, expect, it, vi } from "vitest";
import { Hono } from "hono";
import { requestLoggerMiddleware } from "../../src/middleware/requestLogger.js";

const {
  requestLoggerSpy,
  infoSpy,
  errorSpy,
} = vi.hoisted(() => {
  return {
    requestLoggerSpy: vi.fn(),
    infoSpy: vi.fn(),
    errorSpy: vi.fn(),
  };
});

vi.mock("../../src/utils/logger.js", () => ({
  logger: { warn: vi.fn(), info: vi.fn(), error: vi.fn() },
  requestLogger: requestLoggerSpy,
}));

describe("requestLogger middleware", () => {
  beforeEach(() => {
    requestLoggerSpy.mockReturnValue({
      info: infoSpy,
      error: errorSpy,
    });
    requestLoggerSpy.mockClear();
    infoSpy.mockClear();
    errorSpy.mockClear();
  });

  it("logs request metadata for successful requests", async () => {
    const app = new Hono();
    app.use("/*", requestLoggerMiddleware);
    app.get("/ok", (c) => c.json({ ok: true }));

    const res = await app.request("/ok");
    expect(res.status).toBe(200);
    expect(res.headers.get("x-request-id")).toBeTruthy();
    expect(requestLoggerSpy).toHaveBeenCalledTimes(1);
    expect(infoSpy).toHaveBeenCalledWith(
      expect.objectContaining({
        method: "GET",
        path: "/ok",
        statusCode: 200,
      }),
      "Request completed"
    );
  });

  it("logs request metadata for failed requests", async () => {
    const app = new Hono();
    app.use("/*", requestLoggerMiddleware);
    app.get("/fail", () => {
      throw new Error("boom");
    });
    app.onError((_err, c) => c.json({ error: "internal_server_error" }, 500));

    const res = await app.request("/fail");
    expect(res.status).toBe(500);
    expect(requestLoggerSpy).toHaveBeenCalledTimes(1);
    expect(errorSpy).toHaveBeenCalledWith(
      expect.objectContaining({
        method: "GET",
        path: "/fail",
        statusCode: 500,
      }),
      "Request failed"
    );
  });
});
