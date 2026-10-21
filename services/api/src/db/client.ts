import postgres from "postgres";
import { config } from "../utils/config.js";

let sql: postgres.Sql;

export function getDb(): postgres.Sql {
  if (!sql) {
    sql = postgres(config.databaseUrl, {
      max: 10,
      idle_timeout: 20,
      connect_timeout: 10,
    });
  }
  return sql;
}

export async function closeDb(): Promise<void> {
  if (sql) {
    await sql.end();
  }
}
