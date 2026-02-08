import { describe, it, expect, vi } from "vitest";
import { Hono } from "hono";
import { rateLimitMiddleware } from "../../src/middleware/rateLimit.js";

function createMockSql(scanCount: number | null) {
  const rows = scanCount !== null ? [{ scan_count: scanCount }] : [];
  const mockSql = vi.fn().mockResolvedValue(rows) as any;
  mockSql.end = vi.fn();
  return mockSql;
}

function createTestApp(sql: any) {
  const app = new Hono();
  // Simulate auth middleware setting userId
  app.use("/*", async (c, next) => {
    c.set("userId" as any, "test-user-id");
    await next();
  });
  app.use("/*", rateLimitMiddleware(sql));
  app.post("/scan", (c) => c.json({ ok: true }));
  return app;
}

describe("Rate Limit Middleware", () => {
  it("should allow request when user has 0 scans today", async () => {
    const sql = createMockSql(null); // No row = 0 scans
    const app = createTestApp(sql);

    const res = await app.request("/scan", { method: "POST" });

    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
  });

  it("should allow request when user has 3 scans today", async () => {
    const sql = createMockSql(3);
    const app = createTestApp(sql);

    const res = await app.request("/scan", { method: "POST" });

    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
  });

  it("should reject with 429 when user has 4 scans today", async () => {
    const sql = createMockSql(4);
    const app = createTestApp(sql);

    const res = await app.request("/scan", { method: "POST" });

    expect(res.status).toBe(429);
    const body = await res.json();
    expect(body.error).toBe("rate_limit_exceeded");
    expect(body.message).toBe("You've reached your daily scan limit.");
    expect(body.resetsAt).toBeDefined();
    expect(res.headers.get("Retry-After")).toBeDefined();
  });

  it("should reject with 429 when user has more than 4 scans today", async () => {
    const sql = createMockSql(10);
    const app = createTestApp(sql);

    const res = await app.request("/scan", { method: "POST" });

    expect(res.status).toBe(429);
    const body = await res.json();
    expect(body.error).toBe("rate_limit_exceeded");
  });
});
