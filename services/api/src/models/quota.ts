import { getDb } from "../db/client.js";
import { config } from "../utils/config.js";

export interface QuotaInfo {
  remaining: number;
  limit: number;
  resetsAt: string;
}

export async function getQuota(userId: string): Promise<QuotaInfo> {
  const db = getDb();
  const [row] = await db<{ scan_count: number }[]>`
    SELECT scan_count FROM scan_quota
    WHERE user_id = ${userId} AND scan_date = CURRENT_DATE
  `;

  const scanCount = row?.scan_count ?? 0;
  const tomorrow = new Date();
  tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);
  tomorrow.setUTCHours(0, 0, 0, 0);

  return {
    remaining: Math.max(0, config.dailyScanLimit - scanCount),
    limit: config.dailyScanLimit,
    resetsAt: tomorrow.toISOString(),
  };
}

export async function getScanCount(userId: string): Promise<number> {
  const db = getDb();
  const [row] = await db<{ scan_count: number }[]>`
    SELECT scan_count FROM scan_quota
    WHERE user_id = ${userId} AND scan_date = CURRENT_DATE
  `;
  return row?.scan_count ?? 0;
}

export async function incrementScanCount(userId: string): Promise<void> {
  const db = getDb();
  await db`
    INSERT INTO scan_quota (user_id, scan_date, scan_count)
    VALUES (${userId}, CURRENT_DATE, 1)
    ON CONFLICT (user_id, scan_date)
    DO UPDATE SET scan_count = scan_quota.scan_count + 1
  `;
}
