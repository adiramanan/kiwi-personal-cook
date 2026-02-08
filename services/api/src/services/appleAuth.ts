import * as jose from "jose";
import { v4 as uuidv4 } from "uuid";
import { randomBytes } from "crypto";
import { logger, anonymizeUserId } from "../utils/logger.js";
import type postgres from "postgres";

const APPLE_ISSUER = "https://appleid.apple.com";
const APPLE_KEYS_URL = "https://appleid.apple.com/auth/keys";

let cachedJWKS: jose.JWTVerifyGetKey | null = null;

function getAppleJWKS(): jose.JWTVerifyGetKey {
  if (!cachedJWKS) {
    cachedJWKS = jose.createRemoteJWKSet(new URL(APPLE_KEYS_URL));
  }
  return cachedJWKS;
}

export interface AppleTokenPayload {
  sub: string;
  email?: string;
}

export async function verifyAppleIdentityToken(
  identityToken: string,
  clientId: string
): Promise<AppleTokenPayload> {
  const jwks = getAppleJWKS();

  const { payload } = await jose.jwtVerify(identityToken, jwks, {
    issuer: APPLE_ISSUER,
    audience: clientId,
  });

  if (!payload.sub) {
    throw new Error("Missing sub claim in Apple identity token");
  }

  return {
    sub: payload.sub,
    email: payload["email"] as string | undefined,
  };
}

export async function createSession(
  sql: postgres.Sql,
  appleUserId: string,
  email: string | undefined
): Promise<{ sessionToken: string; expiresAt: Date; userId: string }> {
  // Upsert user
  const users = await sql`
    INSERT INTO users (apple_user_id, email)
    VALUES (${appleUserId}, ${email || null})
    ON CONFLICT (apple_user_id)
    DO UPDATE SET
      email = COALESCE(EXCLUDED.email, users.email),
      updated_at = NOW()
    RETURNING id
  `;

  const userId = users[0].id as string;

  // Generate cryptographically random session token
  const token = `${uuidv4()}-${randomBytes(32).toString("hex")}`;
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days

  await sql`
    INSERT INTO sessions (user_id, token, expires_at)
    VALUES (${userId}, ${token}, ${expiresAt.toISOString()})
  `;

  logger.info(
    { userId: anonymizeUserId(userId) },
    "Session created for user"
  );

  return { sessionToken: token, expiresAt, userId };
}
