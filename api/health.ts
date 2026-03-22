import type { VercelRequest, VercelResponse } from "@vercel/node";

/**
 * GET /api/health
 * Public health-check endpoint — no auth required.
 */
export default function handler(_req: VercelRequest, res: VercelResponse) {
  return res.status(200).json({
    status: "ok",
    timestamp: new Date().toISOString(),
    version: "1.0.0",
  });
}
