import type { VercelResponse } from "@vercel/node";
import { AuthError } from "./auth";

/** Send a JSON success response. */
export function ok(res: VercelResponse, data: unknown, status = 200) {
  return res.status(status).json(data);
}

/** Handle errors uniformly across all API routes. */
export function handleError(res: VercelResponse, err: unknown) {
  if (err instanceof AuthError) {
    return res.status(err.status).json({ error: err.message });
  }

  console.error("[API Error]", err);
  return res.status(500).json({ error: "Internal server error" });
}
