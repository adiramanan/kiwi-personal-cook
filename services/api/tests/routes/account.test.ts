import { beforeEach, describe, expect, it, vi } from "vitest";
import { Hono } from "hono";
import type { AppEnv } from "../../src/types";

const { dbMock } = vi.hoisted(() => ({
  dbMock: vi.fn(),
}));

vi.mock("../../src/db/client", () => ({
  db: dbMock,
}));

import { authMiddleware } from "../../src/middleware/auth";
import { accountRoutes } from "../../src/routes/account";

function makeApp() {
  const app = new Hono<AppEnv>();
  app.use("/v1/account", authMiddleware);
  app.route("/", accountRoutes);
  return app;
}

describe("DELETE /v1/account", () => {
  beforeEach(() => {
    dbMock.mockReset();
  });

  it("deletes account when authenticated", async () => {
    dbMock
      .mockResolvedValueOnce([
        {
          user_id: "user-1",
          expires_at: new Date(Date.now() + 60_000).toISOString(),
        },
      ])
      .mockResolvedValueOnce([]);

    const app = makeApp();
    const res = await app.fetch(
      new Request("http://localhost/v1/account", {
        method: "DELETE",
        headers: {
          Authorization: "Bearer valid",
        },
      }),
    );

    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.deleted).toBe(true);
  });

  it("returns 401 when unauthenticated", async () => {
    const app = makeApp();
    const res = await app.fetch(
      new Request("http://localhost/v1/account", {
        method: "DELETE",
      }),
    );

    expect(res.status).toBe(401);
  });
});
