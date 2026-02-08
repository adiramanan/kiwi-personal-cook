export interface ScanQuota {
  id: string;
  userId: string;
  scanDate: string;
  scanCount: number;
}

export interface QuotaInfo {
  remaining: number;
  limit: number;
  resetsAt: string;
}

export const DAILY_SCAN_LIMIT = 4;
