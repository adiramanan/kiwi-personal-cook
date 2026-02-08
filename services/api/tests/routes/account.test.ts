import { describe, it, expect, vi } from "vitest";
import { Hono } from "hono";
import { accountRoutes } from "../../src/routes/account.js";

function createMockSql() {
  const mockSql = vi.fn().mockResolvedValue([]) as any;
  mockSql.end = vi.fn();
  return mockSql;
}

function createTestApp(sql: any, authenticated = true) {
  const app = new Hono();
  if (authenticated) {
    app.use("/*", async (c, next) => {
      c.set("userId" as any, "test-user-id");
      await next();
    });
  }
  app.route("/", accountRoutes(sql));
  return app;
}

describe("Account Route", () => {
  it("should return 200 with deleted: true on valid delete", async () => {
    const sql = createMockSql();
    const app = createTestApp(sql);

    const res = await app.request("/", { method: "DELETE" });

    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.deleted).toBe(true);
  });

  it("should call SQL to delete user", async () => {
    const sql = createMockSql();
    const app = createTestApp(sql);

    await app.request("/", { method: "DELETE" });

    // Verify the SQL was called (tagged template function)
    expect(sql).toHaveBeenCalled();
  });
});
