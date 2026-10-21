import type postgres from "postgres";
import { getDb } from "../db/client.js";
import { config } from "../utils/config.js";
import { normalizeName, type Member, type InventoryItem } from "../schema/kitchen.js";

export async function listMembers(userId: string): Promise<Member[]> {
  const rows = await getDb()<{ id: string; profile: Omit<Member, "id"> }[]>`
    SELECT id, profile FROM family_members WHERE user_id = ${userId} ORDER BY created_at, id`;
  return rows.map(row => ({ ...row.profile, id: row.id }));
}
export async function saveMember(userId: string, id: string, profile: Omit<Member, "id">): Promise<Member | null> {
  const db = getDb();
  const rows = await db<{ id: string }[]>`
    INSERT INTO family_members (id, user_id, profile) VALUES (${id}, ${userId}, ${db.json(profile)})
    ON CONFLICT (id) DO UPDATE SET profile = EXCLUDED.profile
    WHERE family_members.user_id = ${userId} RETURNING id`;
  return rows.length ? { ...profile, id } : null;
}
export async function removeMember(userId: string, id: string): Promise<boolean> {
  const rows = await getDb()`DELETE FROM family_members WHERE id = ${id} AND user_id = ${userId} RETURNING id`;
  return rows.length > 0;
}
export async function listInventory(userId: string): Promise<InventoryItem[]> {
  return await getDb()<InventoryItem[]>`SELECT id, name FROM fridge_items WHERE user_id = ${userId} ORDER BY name`;
}
export async function updateInventory(userId: string, upserts: InventoryItem[], removedIDs: string[]): Promise<InventoryItem[]> {
  const db = getDb();
  await db.begin(async transaction => {
    const tx = transaction as unknown as postgres.Sql;
    // Serialize account edits, including simultaneous scans from two devices.
    await tx`SELECT id FROM users WHERE id = ${userId} FOR UPDATE`;
    if (removedIDs.length) await tx`DELETE FROM fridge_items WHERE user_id = ${userId} AND id IN ${tx(removedIDs)}`;
    for (const item of upserts) {
      const normalized = normalizeName(item.name);
      // Update owned IDs first; a duplicate normalized name is merged below.
      await tx`DELETE FROM fridge_items WHERE user_id = ${userId} AND id = ${item.id} AND normalized_name <> ${normalized}`;
      await tx`INSERT INTO fridge_items (id, user_id, name, normalized_name)
        VALUES (${crypto.randomUUID()}, ${userId}, ${item.name.trim()}, ${normalized})
        ON CONFLICT (user_id, normalized_name) DO UPDATE SET name = EXCLUDED.name`;
    }
  });
  return listInventory(userId);
}

export type UsageKind = "recognition" | "generation";
export async function reserveUsage(userId: string, kind: UsageKind): Promise<boolean> {
  const db = getDb();
  const rows = kind === "recognition"
    ? await db`INSERT INTO scan_quota (user_id, scan_date, scan_count) VALUES (${userId}, CURRENT_DATE, 1)
        ON CONFLICT (user_id, scan_date) DO UPDATE SET scan_count = scan_quota.scan_count + 1
        WHERE scan_quota.scan_count < ${config.dailyScanLimit} RETURNING id`
    : await db`INSERT INTO recipe_quota (user_id, usage_date, generation_count) VALUES (${userId}, CURRENT_DATE, 1)
        ON CONFLICT (user_id, usage_date) DO UPDATE SET generation_count = recipe_quota.generation_count + 1
        WHERE recipe_quota.generation_count < ${config.dailyScanLimit} RETURNING user_id`;
  return rows.length > 0;
}
export async function releaseUsage(userId: string, kind: UsageKind): Promise<void> {
  if (kind === "recognition") {
    await getDb()`UPDATE scan_quota SET scan_count = GREATEST(0, scan_count - 1) WHERE user_id = ${userId} AND scan_date = CURRENT_DATE`;
  } else {
    await getDb()`UPDATE recipe_quota SET generation_count = GREATEST(0, generation_count - 1) WHERE user_id = ${userId} AND usage_date = CURRENT_DATE`;
  }
}
export async function generationQuota(userId: string): Promise<{ generationRemaining: number; generationLimit: number }> {
  const [row] = await getDb()<{ generation_count: number }[]>`
    SELECT generation_count FROM recipe_quota WHERE user_id = ${userId} AND usage_date = CURRENT_DATE`;
  return { generationRemaining: Math.max(0, config.dailyScanLimit - (row?.generation_count ?? 0)), generationLimit: config.dailyScanLimit };
}
