import postgres from "postgres";
import { config } from "../utils/config";

export const db = postgres(config.DATABASE_URL, {
  max: 10,
});
