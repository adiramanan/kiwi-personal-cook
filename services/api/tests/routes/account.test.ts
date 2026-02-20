import { describe, it, expect, vi, beforeEach } from "vitest";
import { Hono } from "hono";

vi.mock("../../src/models/user.js", () => ({
  deleteUser: vi.fn(),
  findSession: vi.fn(),
}));

vi.mock("../../src/utils/logger.js", () => ({
  logger: { warn: vi.fn(), info: vi.fn(), error: vi.fn() },
}));

describe("DELETE /v1/account", () => {
  let app: Hono;

  beforeEach(async () => {
    vi.clearAllMocks();

    app = new Hono();
    app.use("/*", async (c, next) => {
      c.set("userId", "user-123");
      await next();
    });

    const accountRoutes = (await import("../../src/routes/account.js")).default;
    app.route("/v1/account", accountRoutes);
  });

  it("returns deleted true on success", async () => {
    const { deleteUser } = await import("../../src/models/user.js");
    (deleteUser as ReturnType<typeof vi.fn>).mockResolvedValueOnce(undefined);

    const res = await app.request("/v1/account", { method: "DELETE" });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.deleted).toBe(true);
  });
});
