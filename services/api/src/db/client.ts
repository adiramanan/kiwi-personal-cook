import postgres from "postgres";
import { logger } from "../utils/logger.js";

let sql: postgres.Sql | null = null;

export function getDb(databaseUrl?: string): postgres.Sql {
  if (!sql) {
    const url = databaseUrl || process.env["DATABASE_URL"];
    if (!url) {
      throw new Error("DATABASE_URL is not set");
    }
    sql = postgres(url, {
      max: 10,
      idle_timeout: 20,
      connect_timeout: 10,
    });
    logger.info("Database connection pool created");
  }
  return sql;
}

export async function closeDb(): Promise<void> {
  if (sql) {
    await sql.end();
    sql = null;
    logger.info("Database connection pool closed");
  }
}
