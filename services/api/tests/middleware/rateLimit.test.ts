import { beforeEach, describe, expect, it, vi } from "vitest";
import { Hono } from "hono";
import type { AppEnv } from "../../src/types";

const { dbMock } = vi.hoisted(() => ({
  dbMock: vi.fn(),
}));

vi.mock("../../src/db/client", () => ({
  db: dbMock,
}));

import { rateLimitMiddleware } from "../../src/middleware/rateLimit";

function makeApp() {
  const app = new Hono<AppEnv>();
  app.use("*", async (c, next) => {
    c.set("userId", "user-1");
    await next();
  });
  app.use("*", rateLimitMiddleware);
  app.post("/v1/scan", (c) => c.json({ ok: true }));
  return app;
}

describe("rateLimitMiddleware", () => {
  beforeEach(() => {
    dbMock.mockReset();
  });

  it("allows user with 0 scans today", async () => {
    dbMock.mockResolvedValueOnce([]);

    const app = makeApp();
    const res = await app.fetch(new Request("http://localhost/v1/scan", { method: "POST" }));

    expect(res.status).toBe(200);
  });

  it("allows user with 3 scans today", async () => {
    dbMock.mockResolvedValueOnce([{ scan_count: 3 }]);

    const app = makeApp();
    const res = await app.fetch(new Request("http://localhost/v1/scan", { method: "POST" }));

    expect(res.status).toBe(200);
  });

  it("rejects user with 4 scans today", async () => {
    dbMock.mockResolvedValueOnce([{ scan_count: 4 }]);

    const app = makeApp();
    const res = await app.fetch(new Request("http://localhost/v1/scan", { method: "POST" }));

    expect(res.status).toBe(429);
    expect(res.headers.get("Retry-After")).toBeTruthy();

    const body = await res.json();
    expect(body.error).toBe("rate_limit_exceeded");
    expect(body.message).toBe("You've reached your daily scan limit.");
    expect(typeof body.resetsAt).toBe("string");
  });
});
