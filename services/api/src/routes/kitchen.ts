import { Hono, type Context } from "hono";
import { bodyLimit } from "hono/body-limit";
import { z } from "zod";
import type { AppEnv } from "../types.js";
import { MemberInput, InventoryUpdate } from "../schema/kitchen.js";
import * as store from "../models/kitchen.js";
import { recognizeIngredients, generateRecipes } from "../services/cooking.js";
import { validateImage } from "../services/imageValidator.js";
import { LLMError } from "../services/llm.js";
import { getQuota } from "../models/quota.js";

const kitchen = new Hono<AppEnv>();
kitchen.use("*", bodyLimit({ maxSize: 7 * 1024 * 1024, onError: c => c.json({ error: "payload_too_large", message: "Choose up to three photos, each under 2 MB." }, 413) }));
kitchen.onError((error, c) => {
  if (error instanceof SyntaxError) return c.json({ error: "invalid_json" }, 400);
  if (error instanceof LLMError) return c.json({ error: "invalid_model_response", message: "We couldn't create a suitable response. Please try again." }, 502);
  return c.json({ error: "kitchen_unavailable", message: "Couldn't reach your kitchen. Please try again." }, 503);
});
kitchen.get("/identity", c => c.json({ accountID: c.get("userId") }));
kitchen.get("/family", async c => c.json({ members: await store.listMembers(c.get("userId")) }));
kitchen.post("/family", async c => {
  const profile = MemberInput.safeParse(await c.req.json());
  if (!profile.success) return c.json({ error: "invalid_profile", message: "Check your profile and meal targets." }, 400);
  if ((await store.listMembers(c.get("userId"))).length >= 20) return c.json({ error: "family_limit", message: "You can add up to 20 members." }, 400);
  return c.json(await store.saveMember(c.get("userId"), crypto.randomUUID(), profile.data), 201);
});
kitchen.put("/family/:id", async c => {
  const id = z.string().uuid().safeParse(c.req.param("id"));
  const profile = MemberInput.safeParse(await c.req.json());
  if (!id.success || !profile.success) return c.json({ error: "invalid_profile" }, 400);
  if (!(await store.listMembers(c.get("userId"))).some(m => m.id === id.data)) return c.json({ error: "not_found" }, 404);
  const member = await store.saveMember(c.get("userId"), id.data, profile.data);
  return member ? c.json(member) : c.json({ error: "not_found" }, 404);
});
kitchen.delete("/family/:id", async c => {
  const id = z.string().uuid().safeParse(c.req.param("id"));
  if (!id.success) return c.json({ error: "invalid_id" }, 400);
  return await store.removeMember(c.get("userId"), id.data) ? c.json({ deleted: true }) : c.json({ error: "not_found" }, 404);
});
kitchen.get("/inventory", async c => c.json({ ingredients: await store.listInventory(c.get("userId")) }));
kitchen.patch("/inventory", async c => {
  const update = InventoryUpdate.safeParse(await c.req.json());
  if (!update.success) return c.json({ error: "invalid_inventory" }, 400);
  return c.json({ ingredients: await store.updateInventory(c.get("userId"), update.data.upserts, update.data.removedIDs) });
});
kitchen.get("/quota", async c => c.json({ ...await getQuota(c.get("userId")), ...await store.generationQuota(c.get("userId")) }));
function rateLimit(c: Context<AppEnv>) {
  const tomorrow = new Date(); tomorrow.setUTCDate(tomorrow.getUTCDate() + 1); tomorrow.setUTCHours(0, 0, 0, 0);
  c.header("Retry-After", String(Math.ceil((tomorrow.getTime() - Date.now()) / 1000)));
  return c.json({ error: "rate_limit_exceeded", message: "Daily limit reached. Try again tomorrow." }, 429);
}
kitchen.post("/recognize", async c => {
  let form: FormData;
  try { form = await c.req.formData(); } catch { return c.json({ error: "invalid_upload" }, 400); }
  const files = form.getAll("images");
  if (files.length < 1 || files.length > 3 || files.some(file => !(file instanceof File))) return c.json({ error: "invalid_images", message: "Choose one to three photos." }, 400);
  const images: Buffer[] = [];
  for (const file of files as File[]) {
    const buffer = Buffer.from(await file.arrayBuffer());
    const validation = validateImage(buffer, file.type);
    if (!validation.valid) return c.json({ error: "invalid_image", message: validation.error }, 400);
    images.push(buffer);
  }
  const userId = c.get("userId");
  if (!await store.reserveUsage(userId, "recognition")) return rateLimit(c);
  try { return c.json({ ingredients: await recognizeIngredients(images) }); }
  catch (error) { await store.releaseUsage(userId, "recognition"); throw error; }
});
kitchen.post("/recipes", async c => {
  const userId = c.get("userId");
  const [inventory, members] = await Promise.all([store.listInventory(userId), store.listMembers(userId)]);
  if (!inventory.length) return c.json({ error: "empty_inventory", message: "Add ingredients to your fridge first." }, 400);
  if (!await store.reserveUsage(userId, "generation")) return rateLimit(c);
  try { return c.json(await generateRecipes(inventory, members)); }
  catch (error) { await store.releaseUsage(userId, "generation"); throw error; }
});
export default kitchen;
