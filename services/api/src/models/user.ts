import { getDb } from "../db/client.js";
import { v4 as uuid } from "uuid";

export interface User {
  id: string;
  apple_user_id: string;
  email: string | null;
  created_at: Date;
  updated_at: Date;
}

export async function upsertUser(
  appleUserId: string,
  email: string | null
): Promise<User> {
  const db = getDb();
  const [user] = await db<User[]>`
    INSERT INTO users (apple_user_id, email)
    VALUES (${appleUserId}, ${email})
    ON CONFLICT (apple_user_id)
    DO UPDATE SET email = COALESCE(EXCLUDED.email, users.email), updated_at = NOW()
    RETURNING *
  `;
  return user;
}

export async function deleteUser(userId: string): Promise<void> {
  const db = getDb();
  await db`DELETE FROM users WHERE id = ${userId}`;
}

export async function createSession(
  userId: string
): Promise<{ token: string; expiresAt: Date }> {
  const db = getDb();
  const token = uuid() + "-" + uuid();
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days

  await db`
    INSERT INTO sessions (user_id, token, expires_at)
    VALUES (${userId}, ${token}, ${expiresAt})
  `;

  return { token, expiresAt };
}

export async function findSession(
  token: string
): Promise<{ userId: string; expiresAt: Date } | null> {
  const db = getDb();
  const [session] = await db<{ user_id: string; expires_at: Date }[]>`
    SELECT user_id, expires_at FROM sessions WHERE token = ${token}
  `;
  if (!session) return null;
  return { userId: session.user_id, expiresAt: session.expires_at };
}

export async function deleteUserSessions(userId: string): Promise<void> {
  const db = getDb();
  await db`DELETE FROM sessions WHERE user_id = ${userId}`;
}
