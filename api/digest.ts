import type { VercelRequest, VercelResponse } from "@vercel/node";
import { authenticateRequest } from "./_lib/auth";
import { getSupabaseAdmin } from "./_lib/supabase-admin";
import { ok, handleError } from "./_lib/response";

/**
 * POST /api/digest
 * Generates a daily AI digest for the authenticated user.
 * Collects recent activity across all modules and sends to an LLM.
 *
 * Expects optional body: { date?: string }  (ISO date, defaults to today)
 */
export default async function handler(
  req: VercelRequest,
  res: VercelResponse
) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  try {
    const { userId } = await authenticateRequest(req);
    const supabase = getSupabaseAdmin();

    const targetDate =
      (req.body as { date?: string })?.date ??
      new Date().toISOString().slice(0, 10);

    // Gather data from the last 24h
    const since = new Date(targetDate);
    since.setDate(since.getDate() - 1);
    const sinceISO = since.toISOString();

    const [tasks, habits, expenses, standups, streaks] = await Promise.all([
      supabase
        .from("tasks")
        .select("title, is_done, priority, project_id")
        .eq("user_id", userId)
        .gte("updated_at", sinceISO),
      supabase
        .from("habit_completions")
        .select("habit_id, completed_date")
        .eq("user_id", userId)
        .gte("completed_date", targetDate),
      supabase
        .from("expenses")
        .select("title, amount, category")
        .eq("user_id", userId)
        .gte("created_at", sinceISO),
      supabase
        .from("standup_logs")
        .select("wins, challenges, priorities")
        .eq("user_id", userId)
        .gte("created_at", sinceISO)
        .limit(1),
      supabase
        .from("streaks")
        .select("category, current_streak, is_broken")
        .eq("user_id", userId),
    ]);

    const snapshot = {
      date: targetDate,
      tasks_updated: tasks.data?.length ?? 0,
      tasks_completed: tasks.data?.filter((t) => t.is_done).length ?? 0,
      habits_completed_today: habits.data?.length ?? 0,
      expenses_logged: expenses.data?.length ?? 0,
      total_spent: expenses.data?.reduce((s, e) => s + (e.amount ?? 0), 0) ?? 0,
      latest_standup: standups.data?.[0] ?? null,
      streaks: streaks.data ?? [],
    };

    // ── AI generation ────────────────────────────────────────────────────
    // If you have an OPENAI_API_KEY or ANTHROPIC_API_KEY set, replace the
    // placeholder below with an actual LLM call. For now, we return the
    // raw snapshot so the Flutter client can render it.
    const aiApiKey = process.env.OPENAI_API_KEY ?? process.env.ANTHROPIC_API_KEY;
    let digest: string;

    if (aiApiKey) {
      digest = await generateDigestWithAI(snapshot, aiApiKey);
    } else {
      digest = buildFallbackDigest(snapshot);
    }

    // Persist the digest to the user's profile
    await supabase
      .from("profiles")
      .update({
        last_ai_digest: digest,
        last_digest_date: targetDate,
      })
      .eq("id", userId);

    return ok(res, { date: targetDate, digest, snapshot });
  } catch (err) {
    return handleError(res, err);
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

interface Snapshot {
  date: string;
  tasks_updated: number;
  tasks_completed: number;
  habits_completed_today: number;
  expenses_logged: number;
  total_spent: number;
  latest_standup: { wins?: string; challenges?: string; priorities?: string } | null;
  streaks: { category: string; current_streak: number; is_broken: boolean }[];
}

function buildFallbackDigest(s: Snapshot): string {
  const lines = [`📋 Daily Digest — ${s.date}`];
  lines.push(`• Tasks updated: ${s.tasks_updated} (${s.tasks_completed} completed)`);
  lines.push(`• Habits completed today: ${s.habits_completed_today}`);
  if (s.expenses_logged > 0) {
    lines.push(`• Expenses: ${s.expenses_logged} totalling $${s.total_spent.toFixed(2)}`);
  }
  if (s.streaks.length > 0) {
    const active = s.streaks.filter((st) => !st.is_broken);
    lines.push(`• Active streaks: ${active.length}`);
  }
  return lines.join("\n");
}

async function generateDigestWithAI(
  snapshot: Snapshot,
  apiKey: string
): Promise<string> {
  // TODO: Replace with your preferred AI provider call.
  // Example using OpenAI-compatible endpoint:
  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      max_tokens: 300,
      messages: [
        {
          role: "system",
          content:
            "You are a friendly productivity coach. Given the user's daily data snapshot, write a short motivational daily digest (3-5 sentences). Highlight wins, flag risks (broken streaks, overspending), and suggest one focus area.",
        },
        { role: "user", content: JSON.stringify(snapshot) },
      ],
    }),
  });

  if (!response.ok) {
    console.error("AI API error:", await response.text());
    return buildFallbackDigest(snapshot);
  }

  const json = (await response.json()) as {
    choices: { message: { content: string } }[];
  };
  return json.choices[0]?.message?.content ?? buildFallbackDigest(snapshot);
}
