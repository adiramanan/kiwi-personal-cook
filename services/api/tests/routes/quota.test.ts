import { describe, it, expect, vi, beforeEach } from "vitest";
import { Hono } from "hono";

vi.mock("../../src/models/quota.js", () => ({
  getQuota: vi.fn(),
  getScanCount: vi.fn().mockResolvedValue(0),
}));

vi.mock("../../src/models/user.js", () => ({
  findSession: vi.fn(),
}));

vi.mock("../../src/utils/logger.js", () => ({
  logger: { warn: vi.fn(), info: vi.fn(), error: vi.fn() },
}));

describe("GET /v1/quota", () => {
  let app: Hono;

  beforeEach(async () => {
    vi.clearAllMocks();

    app = new Hono();
    app.use("/*", async (c, next) => {
      c.set("userId", "user-123");
      await next();
    });

    const quotaRoutes = (await import("../../src/routes/quota.js")).default;
    app.route("/v1/quota", quotaRoutes);
  });

  it("returns remaining 4 when no scans today", async () => {
    const { getQuota } = await import("../../src/models/quota.js");
    (getQuota as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      remaining: 4,
      limit: 4,
      resetsAt: "2026-02-21T00:00:00.000Z",
    });

    const res = await app.request("/v1/quota");
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.remaining).toBe(4);
    expect(body.limit).toBe(4);
  });

  it("returns remaining 2 when 2 scans used", async () => {
    const { getQuota } = await import("../../src/models/quota.js");
    (getQuota as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      remaining: 2,
      limit: 4,
      resetsAt: "2026-02-21T00:00:00.000Z",
    });

    const res = await app.request("/v1/quota");
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.remaining).toBe(2);
  });
});
