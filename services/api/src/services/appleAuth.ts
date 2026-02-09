import { createRemoteJWKSet, jwtVerify } from "jose";
import { config } from "../utils/config";
import { db } from "../db/client";
import { randomUUID } from "crypto";

const jwks = createRemoteJWKSet(new URL("https://appleid.apple.com/auth/keys"));

export interface SessionRecord {
  token: string;
  expiresAt: string;
}

export async function verifyAppleToken(identityToken: string): Promise<{ appleUserId: string; email: string | null }> {
  const { payload } = await jwtVerify(identityToken, jwks, {
    issuer: "https://appleid.apple.com",
    audience: config.APPLE_CLIENT_ID,
  });

  const appleUserId = payload.sub;
  if (!appleUserId) {
    throw new Error("missing_sub");
  }

  return { appleUserId, email: (payload.email as string) ?? null };
}

export async function createSession(appleUserId: string, email: string | null): Promise<SessionRecord> {
  const user = await db.begin(async (trx) => {
    const existing = await trx`
      SELECT id FROM users WHERE apple_user_id = ${appleUserId}
    `;
    if (existing.length === 0) {
      const inserted = await trx`
        INSERT INTO users (apple_user_id, email)
        VALUES (${appleUserId}, ${email})
        RETURNING id
      `;
      return inserted[0];
    }
    return existing[0];
  });

  const token = `${randomUUID()}-${randomUUID()}`;
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();

  await db`
    INSERT INTO sessions (user_id, token, expires_at)
    VALUES (${user.id}, ${token}, ${expiresAt})
  `;

  return { token, expiresAt };
}
