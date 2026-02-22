import "dotenv/config";
import postgres from "postgres";

const url = process.env.DATABASE_URL;
if (!url) throw new Error("DATABASE_URL not set");

const sql = postgres(url);
const result = await sql`DELETE FROM scan_quota WHERE scan_date = CURRENT_DATE`;
console.log(`Quota reset — ${result.count} row(s) deleted.`);
await sql.end();
