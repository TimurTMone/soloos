import type { VercelRequest, VercelResponse } from "@vercel/node";
import { ok, handleError } from "./_lib/response";

/**
 * POST /api/claude
 * Proxies Claude API calls so mobile users don't need their own API key.
 * Requires ANTHROPIC_API_KEY set in Vercel environment variables.
 *
 * Body: { messages: [{role, content}], system?: string, max_tokens?: number }
 *
 * Rate-limited by a simple per-IP daily counter (stored in-memory for now).
 */

const DAILY_LIMIT = 50; // per IP per day
const callCounts = new Map<string, { count: number; date: string }>();

function getRateLimitKey(req: VercelRequest): string {
  const ip =
    (req.headers["x-forwarded-for"] as string)?.split(",")[0]?.trim() ??
    "unknown";
  return ip;
}

function checkRateLimit(req: VercelRequest): boolean {
  const key = getRateLimitKey(req);
  const today = new Date().toISOString().slice(0, 10);
  const entry = callCounts.get(key);

  if (!entry || entry.date !== today) {
    callCounts.set(key, { count: 1, date: today });
    return true;
  }

  if (entry.count >= DAILY_LIMIT) return false;
  entry.count++;
  return true;
}

export default async function handler(
  req: VercelRequest,
  res: VercelResponse
) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    return res.status(503).json({ error: "AI service not configured" });
  }

  if (!checkRateLimit(req)) {
    return res.status(429).json({ error: "Daily AI limit reached. Upgrade to Pro for unlimited." });
  }

  try {
    const { messages, system, max_tokens } = req.body as {
      messages: { role: string; content: string }[];
      system?: string;
      max_tokens?: number;
    };

    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      return res.status(400).json({ error: "messages array is required" });
    }

    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-20250514",
        max_tokens: Math.min(max_tokens ?? 1024, 2048),
        ...(system ? { system } : {}),
        messages,
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error("Anthropic API error:", errorText);
      return res.status(502).json({ error: "AI service error" });
    }

    const data = await response.json();
    const text = (data as any).content?.[0]?.text ?? "";

    return ok(res, { text });
  } catch (err) {
    return handleError(res, err);
  }
}
