import { describe, it, expect, vi, beforeEach } from "vitest";
import { Hono } from "hono";
import { rateLimitMiddleware } from "../../src/middleware/rateLimit.js";

vi.mock("../../src/models/quota.js", () => ({
  getScanCount: vi.fn(),
}));

vi.mock("../../src/utils/logger.js", () => ({
  logger: { warn: vi.fn(), info: vi.fn(), error: vi.fn() },
}));

describe("rate limit middleware", () => {
  let app: Hono;

  beforeEach(() => {
    app = new Hono();
    app.use("/*", async (c, next) => {
      c.set("userId", "user-123");
      await next();
    });
    app.use("/*", rateLimitMiddleware);
    app.post("/scan", (c) => c.json({ ok: true }));
    vi.clearAllMocks();
  });

  it("allows user with 0 scans today", async () => {
    const { getScanCount } = await import("../../src/models/quota.js");
    (getScanCount as ReturnType<typeof vi.fn>).mockResolvedValueOnce(0);

    const res = await app.request("/scan", { method: "POST" });
    expect(res.status).toBe(200);
  });

  it("allows user with 3 scans today", async () => {
    const { getScanCount } = await import("../../src/models/quota.js");
    (getScanCount as ReturnType<typeof vi.fn>).mockResolvedValueOnce(3);

    const res = await app.request("/scan", { method: "POST" });
    expect(res.status).toBe(200);
  });

  it("rejects user with 4 scans today with 429", async () => {
    const { getScanCount } = await import("../../src/models/quota.js");
    (getScanCount as ReturnType<typeof vi.fn>).mockResolvedValueOnce(4);

    const res = await app.request("/scan", { method: "POST" });
    expect(res.status).toBe(429);

    const body = await res.json();
    expect(body.error).toBe("rate_limit_exceeded");
    expect(body.resetsAt).toBeDefined();
    expect(res.headers.get("Retry-After")).toBeDefined();
  });
});
