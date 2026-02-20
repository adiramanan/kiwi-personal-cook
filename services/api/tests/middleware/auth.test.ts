import { describe, it, expect, vi, beforeEach } from "vitest";
import { Hono } from "hono";
import { authMiddleware } from "../../src/middleware/auth.js";

vi.mock("../../src/models/user.js", () => ({
  findSession: vi.fn(),
}));

vi.mock("../../src/utils/logger.js", () => ({
  logger: { warn: vi.fn(), info: vi.fn(), error: vi.fn() },
}));

describe("auth middleware", () => {
  let app: Hono;

  beforeEach(async () => {
    app = new Hono();
    app.use("/*", authMiddleware);
    app.get("/test", (c) => c.json({ userId: c.get("userId") }));
    vi.clearAllMocks();
  });

  it("returns 401 without Authorization header", async () => {
    const res = await app.request("/test");
    expect(res.status).toBe(401);
    const body = await res.json();
    expect(body.error).toBe("unauthorized");
  });

  it("returns 401 with invalid token format", async () => {
    const res = await app.request("/test", {
      headers: { Authorization: "InvalidFormat" },
    });
    expect(res.status).toBe(401);
  });

  it("returns 401 when session not found", async () => {
    const { findSession } = await import("../../src/models/user.js");
    (findSession as ReturnType<typeof vi.fn>).mockResolvedValueOnce(null);

    const res = await app.request("/test", {
      headers: { Authorization: "Bearer invalid-token" },
    });
    expect(res.status).toBe(401);
  });

  it("returns 401 when session is expired", async () => {
    const { findSession } = await import("../../src/models/user.js");
    (findSession as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      userId: "user-123",
      expiresAt: new Date(Date.now() - 1000),
    });

    const res = await app.request("/test", {
      headers: { Authorization: "Bearer expired-token" },
    });
    expect(res.status).toBe(401);
  });

  it("passes with valid token and sets userId", async () => {
    const { findSession } = await import("../../src/models/user.js");
    (findSession as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      userId: "user-123",
      expiresAt: new Date(Date.now() + 86400000),
    });

    const res = await app.request("/test", {
      headers: { Authorization: "Bearer valid-token" },
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.userId).toBe("user-123");
  });
});
