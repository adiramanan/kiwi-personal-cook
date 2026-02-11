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

function makeApp() {
  const app = new Hono<AppEnv>();
  app.use("*", authMiddleware);
  app.get("/secure", (c) => c.json({ userId: c.get("userId") }));
  return app;
}

describe("authMiddleware", () => {
  beforeEach(() => {
    dbMock.mockReset();
  });

  it("returns 401 without Authorization header", async () => {
    const app = makeApp();
    const res = await app.fetch(new Request("http://localhost/secure"));
    expect(res.status).toBe(401);
  });

  it("returns 401 with invalid token", async () => {
    dbMock.mockResolvedValueOnce([]);

    const app = makeApp();
    const res = await app.fetch(
      new Request("http://localhost/secure", {
        headers: {
          Authorization: "Bearer invalid",
        },
      }),
    );

    expect(res.status).toBe(401);
  });

  it("returns 401 with expired session", async () => {
    dbMock.mockResolvedValueOnce([
      {
        user_id: "user-123",
        expires_at: new Date(Date.now() - 1_000).toISOString(),
      },
    ]);

    const app = makeApp();
    const res = await app.fetch(
      new Request("http://localhost/secure", {
        headers: {
          Authorization: "Bearer expired",
        },
      }),
    );

    expect(res.status).toBe(401);
  });

  it("passes through and sets userId with valid token", async () => {
    dbMock.mockResolvedValueOnce([
      {
        user_id: "user-abc",
        expires_at: new Date(Date.now() + 60_000).toISOString(),
      },
    ]);

    const app = makeApp();
    const res = await app.fetch(
      new Request("http://localhost/secure", {
        headers: {
          Authorization: "Bearer valid",
        },
      }),
    );

    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.userId).toBe("user-abc");
  });
});
