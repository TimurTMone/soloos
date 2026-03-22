import type { VercelRequest, VercelResponse } from "@vercel/node";
import { authenticateRequest } from "./_lib/auth";
import { getSupabaseAdmin } from "./_lib/supabase-admin";
import { ok, handleError } from "./_lib/response";

/**
 * GET /api/me
 * Returns the authenticated user's profile + summary stats.
 */
export default async function handler(
  req: VercelRequest,
  res: VercelResponse
) {
  if (req.method !== "GET") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  try {
    const { userId } = await authenticateRequest(req);
    const supabase = getSupabaseAdmin();

    const [profileRes, tasksRes, habitsRes, progressRes] = await Promise.all([
      supabase.from("profiles").select("*").eq("id", userId).single(),
      supabase
        .from("tasks")
        .select("id", { count: "exact", head: true })
        .eq("user_id", userId)
        .eq("is_done", false),
      supabase
        .from("habits")
        .select("id", { count: "exact", head: true })
        .eq("user_id", userId),
      supabase
        .from("user_progress")
        .select("*")
        .eq("user_id", userId)
        .single(),
    ]);

    return ok(res, {
      profile: profileRes.data,
      stats: {
        open_tasks: tasksRes.count ?? 0,
        active_habits: habitsRes.count ?? 0,
        level: progressRes.data?.level ?? 1,
        total_xp: progressRes.data?.total_xp ?? 0,
      },
    });
  } catch (err) {
    return handleError(res, err);
  }
}
