import { describe, it, expect, vi } from "vitest";
import { Hono } from "hono";
import { quotaRoutes } from "../../src/routes/quota.js";

function createMockSql(scanCount: number | null) {
  const rows = scanCount !== null ? [{ scan_count: scanCount }] : [];
  const mockSql = vi.fn().mockResolvedValue(rows) as any;
  mockSql.end = vi.fn();
  return mockSql;
}

function createTestApp(sql: any) {
  const app = new Hono();
  // Simulate auth middleware
  app.use("/*", async (c, next) => {
    c.set("userId" as any, "test-user-id");
    await next();
  });
  app.route("/", quotaRoutes(sql));
  return app;
}

describe("Quota Route", () => {
  it("should return remaining 4 when user has no scans today", async () => {
    const sql = createMockSql(null); // No rows = no scans
    const app = createTestApp(sql);

    const res = await app.request("/");

    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.remaining).toBe(4);
    expect(body.limit).toBe(4);
    expect(body.resetsAt).toBeDefined();
  });

  it("should return remaining 2 when user has 2 scans today", async () => {
    const sql = createMockSql(2);
    const app = createTestApp(sql);

    const res = await app.request("/");

    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.remaining).toBe(2);
    expect(body.limit).toBe(4);
  });

  it("should return remaining 0 when user has 4 scans today", async () => {
    const sql = createMockSql(4);
    const app = createTestApp(sql);

    const res = await app.request("/");

    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.remaining).toBe(0);
    expect(body.limit).toBe(4);
  });

  it("should return remaining 0 when user has more than 4 scans", async () => {
    const sql = createMockSql(10);
    const app = createTestApp(sql);

    const res = await app.request("/");

    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.remaining).toBe(0);
  });

  it("should include resetsAt as a valid ISO date string", async () => {
    const sql = createMockSql(0);
    const app = createTestApp(sql);

    const res = await app.request("/");
    const body = await res.json();

    expect(body.resetsAt).toBeDefined();
    const date = new Date(body.resetsAt);
    expect(date.getTime()).toBeGreaterThan(Date.now());
  });
});
