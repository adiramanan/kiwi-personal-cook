import { Hono } from "hono";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { AppEnv } from "../../src/types.js";
vi.mock("../../src/models/kitchen.js", () => ({ listMembers: vi.fn(), saveMember: vi.fn(), removeMember: vi.fn(),
  listInventory: vi.fn(), updateInventory: vi.fn(), reserveUsage: vi.fn(), releaseUsage: vi.fn(), generationQuota: vi.fn() }));
vi.mock("../../src/services/cooking.js", () => ({ recognizeIngredients: vi.fn(), generateRecipes: vi.fn() }));
import * as store from "../../src/models/kitchen.js";
import * as cooking from "../../src/services/cooking.js";
import kitchen from "../../src/routes/kitchen.js";
const userID = "account-a";
const id = "550e8400-e29b-41d4-a716-446655440000";
function app() {
  const app = new Hono<AppEnv>();
  app.use("*", async (c, next) => { c.set("userId", userID); await next(); });
  app.route("/v1/kitchen", kitchen); return app;
}
function image(size = 100) {
  const bytes = new Uint8Array(size); bytes.set([0xff, 0xd8, 0xff].slice(0, size));
  return new Blob([bytes], { type: "image/jpeg" });
}
describe("kitchen routes", () => {
  beforeEach(() => {
    vi.resetAllMocks();
    vi.mocked(store.listMembers).mockResolvedValue([]);
    vi.mocked(store.listInventory).mockResolvedValue([{ id, name: "egg" }]);
    vi.mocked(store.reserveUsage).mockResolvedValue(true);
    vi.mocked(cooking.recognizeIngredients).mockResolvedValue([{ id, name: "egg" }]);
  });
  it("scopes inventory updates and removals to the authenticated account", async () => {
    vi.mocked(store.updateInventory).mockResolvedValue([]);
    const res = await app().request("/v1/kitchen/inventory", { method: "PATCH", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ upserts: [{ id, name: "egg" }], removedIDs: [id] }) });
    expect(res.status).toBe(200);
    expect(store.updateInventory).toHaveBeenCalledWith(userID, [{ id, name: "egg" }], [id]);
  });
  it("cannot update another account's member", async () => {
    const res = await app().request(`/v1/kitchen/family/${id}`, { method: "PUT", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ name: "Ada" }) });
    expect(res.status).toBe(404); expect(store.saveMember).not.toHaveBeenCalled();
  });
  it("validates targets and rejects malformed JSON", async () => {
    const invalid = await app().request("/v1/kitchen/family", { method: "POST", body: JSON.stringify({ name: "Ada", calorieTarget: -500 }) });
    expect(invalid.status).toBe(400);
    const malformed = await app().request("/v1/kitchen/family", { method: "POST", body: "{" });
    expect(malformed.status).toBe(400);
  });
  it("recognizes three photos as one batch without generating or persisting ingredients", async () => {
    const data = new FormData(); for (let i = 0; i < 3; i++) data.append("images", image());
    const res = await app().request("/v1/kitchen/recognize", { method: "POST", body: data });
    expect(res.status).toBe(200); expect(cooking.recognizeIngredients).toHaveBeenCalledOnce();
    expect(store.reserveUsage).toHaveBeenCalledExactlyOnceWith(userID, "recognition");
    expect(store.updateInventory).not.toHaveBeenCalled(); expect(cooking.generateRecipes).not.toHaveBeenCalled();
  });
  it("rejects empty, oversized, excessive or truncated image batches before charging quota", async () => {
    for (const files of [[], [image(), image(), image(), image()], [image(2)], [image(2 * 1024 * 1024 + 1)]]) {
      const data = new FormData(); for (const file of files) data.append("images", file);
      const res = await app().request("/v1/kitchen/recognize", { method: "POST", body: data });
      expect(res.status).toBe(400);
    }
    expect(store.reserveUsage).not.toHaveBeenCalled();
  });
  it("generates from saved ingredients rather than client-supplied preferences", async () => {
    vi.mocked(cooking.generateRecipes).mockResolvedValue({ cookNow: [], shopping: [], profileSnapshot: [], inventorySnapshot: [], generatedAt: "now" });
    const res = await app().request("/v1/kitchen/recipes", { method: "POST", body: JSON.stringify({ inventory: [], members: [{ name: "intruder" }] }) });
    expect(res.status).toBe(200);
    expect(cooking.generateRecipes).toHaveBeenCalledWith([{ id, name: "egg" }], []);
  });
  it("returns a quota error before invoking the model", async () => {
    vi.mocked(store.reserveUsage).mockResolvedValue(false);
    const res = await app().request("/v1/kitchen/recipes", { method: "POST" });
    expect(res.status).toBe(429); expect(res.headers.get("Retry-After")).toBeTruthy();
    expect(cooking.generateRecipes).not.toHaveBeenCalled();
  });
  it("releases reservations on provider failure without exposing private error text", async () => {
    vi.mocked(cooking.generateRecipes).mockRejectedValue(new Error("private prompt"));
    const res = await app().request("/v1/kitchen/recipes", { method: "POST" });
    expect(res.status).toBe(503); expect(await res.text()).not.toContain("private prompt");
    expect(store.releaseUsage).toHaveBeenCalledWith(userID, "generation");
  });
  it("requires inventory before spending a generation request", async () => {
    vi.mocked(store.listInventory).mockResolvedValue([]);
    const res = await app().request("/v1/kitchen/recipes", { method: "POST" });
    expect(res.status).toBe(400); expect(store.reserveUsage).not.toHaveBeenCalled();
  });
});
