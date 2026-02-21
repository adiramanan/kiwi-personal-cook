import * as jose from "jose";
import { logger } from "../utils/logger.js";

const APPLE_JWKS_URL = "https://appleid.apple.com/auth/keys";
const APPLE_ISSUER = "https://appleid.apple.com";

let jwks: ReturnType<typeof jose.createRemoteJWKSet> | null = null;

function getJWKS() {
  if (!jwks) {
    jwks = jose.createRemoteJWKSet(new URL(APPLE_JWKS_URL));
  }
  return jwks;
}

export interface AppleTokenPayload {
  sub: string;
  email?: string;
}

export async function verifyAppleToken(
  identityToken: string,
  clientId: string
): Promise<AppleTokenPayload> {
  const { payload } = await jose.jwtVerify(identityToken, getJWKS(), {
    issuer: APPLE_ISSUER,
    audience: clientId,
  });

  if (!payload.sub) {
    throw new Error("Missing sub in Apple token");
  }

  logger.info({ sub: payload.sub.substring(0, 8) }, "Apple token verified");

  return {
    sub: payload.sub,
    email: payload.email as string | undefined,
  };
}
