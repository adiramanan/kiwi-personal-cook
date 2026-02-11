import { beforeEach, describe, expect, it, vi } from "vitest";
import { Hono } from "hono";
import type { AppEnv } from "../../src/types";

const { dbMock } = vi.hoisted(() => ({
  dbMock: vi.fn(),
}));

vi.mock("../../src/db/client", () => ({
  db: dbMock,
}));

import { quotaRoutes } from "../../src/routes/quota";

function makeApp() {
  const app = new Hono<AppEnv>();
  app.use("*", async (c, next) => {
    c.set("userId", "user-42");
    await next();
  });
  app.route("/", quotaRoutes);
  return app;
}

describe("GET /v1/quota", () => {
  beforeEach(() => {
    dbMock.mockReset();
  });

  it("returns remaining=4 when user has no scans", async () => {
    dbMock.mockResolvedValueOnce([]);

    const app = makeApp();
    const res = await app.fetch(new Request("http://localhost/v1/quota"));

    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toMatchObject({ remaining: 4, limit: 4 });
  });

  it("returns remaining=2 when user has 2 scans", async () => {
    dbMock.mockResolvedValueOnce([{ scan_count: 2 }]);

    const app = makeApp();
    const res = await app.fetch(new Request("http://localhost/v1/quota"));

    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toMatchObject({ remaining: 2, limit: 4 });
  });
});
