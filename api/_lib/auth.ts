import type { VercelRequest } from "@vercel/node";
import { getSupabaseAdmin } from "./supabase-admin";

export interface AuthResult {
  userId: string;
  email?: string;
}

/**
 * Validates the Bearer token from the request and returns the authenticated user.
 * Pass the Supabase access_token from the Flutter client as:
 *   Authorization: Bearer <access_token>
 */
export async function authenticateRequest(
  req: VercelRequest
): Promise<AuthResult> {
  const header = req.headers.authorization;

  if (!header?.startsWith("Bearer ")) {
    throw new AuthError("Missing or invalid Authorization header", 401);
  }

  const token = header.slice(7);
  const supabase = getSupabaseAdmin();

  const {
    data: { user },
    error,
  } = await supabase.auth.getUser(token);

  if (error || !user) {
    throw new AuthError("Invalid or expired token", 401);
  }

  return { userId: user.id, email: user.email };
}

export class AuthError extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.name = "AuthError";
    this.status = status;
  }
}
