import { describe, it, expect, vi, beforeEach } from "vitest";
import { Hono } from "hono";
import { authMiddleware } from "../../src/middleware/auth.js";

// Mock database
function createMockSql(sessions: Array<{ user_id: string; expires_at: string }> = []) {
  const mockSql = vi.fn().mockResolvedValue(sessions) as any;
  mockSql.end = vi.fn();
  return mockSql;
}

function createTestApp(sql: any) {
  const app = new Hono();
  app.use("/*", authMiddleware(sql));
  app.get("/test", (c) => c.json({ userId: c.get("userId") }));
  return app;
}

describe("Auth Middleware", () => {
  it("should return 401 when Authorization header is missing", async () => {
    const sql = createMockSql();
    const app = createTestApp(sql);

    const res = await app.request("/test");

    expect(res.status).toBe(401);
    const body = await res.json();
    expect(body.error).toBe("unauthorized");
  });

  it("should return 401 when Authorization header has no Bearer prefix", async () => {
    const sql = createMockSql();
    const app = createTestApp(sql);

    const res = await app.request("/test", {
      headers: { Authorization: "Basic abc123" },
    });

    expect(res.status).toBe(401);
  });

  it("should return 401 when token is invalid (not found in sessions)", async () => {
    const sql = createMockSql([]); // No sessions found
    const app = createTestApp(sql);

    const res = await app.request("/test", {
      headers: { Authorization: "Bearer invalid-token" },
    });

    expect(res.status).toBe(401);
    const body = await res.json();
    expect(body.error).toBe("unauthorized");
    expect(body.message).toBe("Invalid token");
  });

  it("should return 401 when session is expired", async () => {
    const expiredDate = new Date(Date.now() - 1000).toISOString();
    const sql = createMockSql([
      { user_id: "user-123", expires_at: expiredDate },
    ]);
    const app = createTestApp(sql);

    const res = await app.request("/test", {
      headers: { Authorization: "Bearer expired-token" },
    });

    expect(res.status).toBe(401);
    const body = await res.json();
    expect(body.message).toBe("Session expired");
  });

  it("should pass and set userId when token is valid", async () => {
    const futureDate = new Date(Date.now() + 86400000).toISOString();
    const sql = createMockSql([
      { user_id: "user-abc-123", expires_at: futureDate },
    ]);
    const app = createTestApp(sql);

    const res = await app.request("/test", {
      headers: { Authorization: "Bearer valid-token" },
    });

    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.userId).toBe("user-abc-123");
  });
});
