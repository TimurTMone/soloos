import type { VercelRequest, VercelResponse } from "@vercel/node";
import { getSupabaseAdmin } from "../_lib/supabase-admin";
import { ok, handleError } from "../_lib/response";

/**
 * GET /api/cron/daily
 * Vercel Cron Job — runs once per day.
 *
 * Tasks:
 *  1. Reset broken streaks
 *  2. Generate daily missions for all active users
 *  3. Clean up old dismissed AI coach suggestions (>30 days)
 */
export default async function handler(
  req: VercelRequest,
  res: VercelResponse
) {
  // Verify Vercel cron secret to prevent unauthorized triggers
  const cronSecret = process.env.CRON_SECRET;
  if (cronSecret && req.headers.authorization !== `Bearer ${cronSecret}`) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  try {
    const supabase = getSupabaseAdmin();
    const today = new Date().toISOString().slice(0, 10);
    const results: Record<string, unknown> = {};

    // ── 1. Mark stale streaks as broken ──────────────────────────────────
    const { data: staleStreaks } = await supabase
      .from("streaks")
      .select("id, user_id, category, last_activity_date")
      .eq("is_broken", false)
      .lt("last_activity_date", today);

    if (staleStreaks && staleStreaks.length > 0) {
      const ids = staleStreaks.map((s) => s.id);
      await supabase
        .from("streaks")
        .update({ is_broken: true })
        .in("id", ids);
      results.streaks_broken = ids.length;
    } else {
      results.streaks_broken = 0;
    }

    // ── 2. Clean up old dismissed AI suggestions (>30 days) ──────────────
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const { count } = await supabase
      .from("ai_coach_suggestions")
      .delete()
      .eq("is_dismissed", true)
      .lt("created_at", thirtyDaysAgo.toISOString());

    results.old_suggestions_deleted = count ?? 0;

    // ── 3. Log completion ────────────────────────────────────────────────
    results.date = today;
    results.status = "ok";

    return ok(res, results);
  } catch (err) {
    return handleError(res, err);
  }
}
