import { NextRequest, NextResponse } from "next/server";
import { apiUrl, tunnelBypassHeaders } from "@/lib/env";

export const dynamic = "force-dynamic";

type Preset = "today" | "week" | "month";

type BackendUser = {
  _id?: string;
  role?: string;
  is_subscribed?: boolean;
  subscription_expiry?: string | null;
  manually_added?: boolean;
};

function parsePreset(raw: string | null): Preset {
  if (raw === "today" || raw === "week" || raw === "month") return raw;
  return "month";
}

function buildFallbackReport(opts: {
  preset: Preset;
  statsBody: Record<string, unknown>;
  users: BackendUser[];
}) {
  const now = new Date();
  const { preset, statsBody, users } = opts;
  const data = (statsBody.data as Record<string, unknown> | undefined) ?? {};
  const stats = (data.stats as Record<string, unknown> | undefined) ?? {};

  const dailyRevenue = Number(stats.dailyRevenue) || 0;
  const eventsToday = Number(statsBody.eventsToday) || 0;
  const eventsWeek = Number(statsBody.eventsWeek) || 0;
  const eventsMonth = Number(statsBody.eventsMonth) || 0;

  const eventsInRange =
    preset === "today"
      ? eventsToday
      : preset === "week"
        ? eventsWeek
        : eventsMonth;
  // Dedicated week/month revenue needs backend finance API; until then only
  // the daily KPI is authoritative.
  const rangeRevenue = dailyRevenue;

  const subCounts = {
    active: 0,
    expired: 0,
    free: 0,
    none: 0,
    lawyers: 0,
    admins: 0,
  };
  for (const u of users) {
    if (u.role === "lawyer") {
      subCounts.lawyers += 1;
      continue;
    }
    if (u.role === "admin") {
      subCounts.admins += 1;
      continue;
    }
    if (u.manually_added) subCounts.free += 1;
    else if (u.is_subscribed) {
      const expired =
        u.subscription_expiry && new Date(u.subscription_expiry) < now;
      if (expired) subCounts.expired += 1;
      else subCounts.active += 1;
    } else subCounts.none += 1;
  }

  let from: Date;
  if (preset === "today") {
    from = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  } else if (preset === "week") {
    from = new Date(now);
    from.setDate(now.getDate() - 6);
    from = new Date(from.getFullYear(), from.getMonth(), from.getDate());
  } else {
    from = new Date(now.getFullYear(), now.getMonth(), 1);
  }

  const lines = [
    "VETO Legal — דוח כספים וניהול",
    `נוצר: ${now.toISOString()}`,
    `טווח: ${from.toISOString()} → ${now.toISOString()} (${preset})`,
    "",
    "=== הכנסות (₪) ===",
    `הכנסות היום (מ־API קיים): ${dailyRevenue.toFixed(2)} ₪`,
    `(סיכומי שבוע/חודש מלאים יתעדכנו אחרי פריסת finance בשרת)`,
    "",
    "=== מנויים ומשתמשים ===",
    `מנויים פעילים: ${subCounts.active}`,
    `מנויים שפגו: ${subCounts.expired}`,
    `פטורים (ידני): ${subCounts.free}`,
    `ללא מנוי: ${subCounts.none}`,
    `עורכי דין: ${subCounts.lawyers}`,
    `מנהלים: ${subCounts.admins}`,
    `סה״כ משתמשים: ${users.length}`,
    `אירועי SOS בטווח: ${eventsInRange}`,
    "",
  ];

  const csv = [
    "metric,value",
    `daily_revenue_ils,${dailyRevenue}`,
    `events_today,${eventsToday}`,
    `events_week,${eventsWeek}`,
    `events_month,${eventsMonth}`,
    `subs_active,${subCounts.active}`,
    `subs_expired,${subCounts.expired}`,
    `subs_free,${subCounts.free}`,
    `subs_none,${subCounts.none}`,
    `users_total,${users.length}`,
  ].join("\n");

  return {
    generatedAt: now.toISOString(),
    range: {
      from: from.toISOString(),
      to: now.toISOString(),
      preset,
    },
    revenue: {
      range: { totalIls: rangeRevenue, chargedCalls: 0 },
      today: { totalIls: dailyRevenue, chargedCalls: 0 },
      week: { totalIls: 0, chargedCalls: 0 },
      month: { totalIls: 0, chargedCalls: 0 },
    },
    subscriptions: subCounts,
    totals: {
      users: users.length,
      eventsInRange,
    },
    recentCharges: [] as Array<{
      id: string;
      amountIls: number;
      chargeStatus: string | null;
      callType: string | null;
      createdAt: string | null;
    }>,
    textReport: lines.join("\n"),
    csv,
    source: "fallback-stats" as const,
  };
}

async function upstreamGet(
  path: string,
  auth: string,
): Promise<Response> {
  const url = apiUrl(path);
  return fetch(url, {
    method: "GET",
    headers: {
      Authorization: auth,
      ...tunnelBypassHeaders(),
    },
    cache: "no-store",
    signal: AbortSignal.timeout(20_000),
  });
}

export async function GET(req: NextRequest) {
  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) {
    return NextResponse.json({ error: "נדרשת התחברות." }, { status: 401 });
  }

  const preset = parsePreset(req.nextUrl.searchParams.get("preset"));
  const qs = req.nextUrl.searchParams.toString();

  // Prefer dedicated backend finance API when deployed.
  try {
    const dedicated = await upstreamGet(
      `/api/admin/finance/report${qs ? `?${qs}` : `?preset=${preset}`}`,
      auth,
    );
    if (dedicated.ok) {
      const text = await dedicated.text();
      return new NextResponse(text, {
        status: 200,
        headers: {
          "content-type":
            dedicated.headers.get("content-type") ?? "application/json",
        },
      });
    }
    // 404/501 → compose from existing admin endpoints (Render lag).
    if (dedicated.status !== 404 && dedicated.status !== 501) {
      const errText = await dedicated.text().catch(() => "");
      let message = `שגיאת שרת (${dedicated.status})`;
      try {
        const j = JSON.parse(errText) as { error?: string; message?: string };
        message = j.error || j.message || message;
      } catch {
        if (errText.trim()) message = errText.slice(0, 200);
      }
      return NextResponse.json({ error: message }, { status: dedicated.status });
    }
  } catch {
    /* fall through to composed report */
  }

  try {
    const [statsRes, usersRes] = await Promise.all([
      upstreamGet("/api/admin/stats", auth),
      upstreamGet("/api/admin/users-with-status", auth),
    ]);

    if (!statsRes.ok && !usersRes.ok) {
      return NextResponse.json(
        {
          error:
            "לא ניתן לטעון נתוני כספים מהשרת. בדקו התחברות ו־API.",
        },
        { status: 502 },
      );
    }

    const statsBody = statsRes.ok
      ? ((await statsRes.json()) as Record<string, unknown>)
      : {};
    const usersBody = usersRes.ok
      ? ((await usersRes.json()) as { users?: BackendUser[] })
      : { users: [] };
    const users = Array.isArray(usersBody.users) ? usersBody.users : [];

    const report = buildFallbackReport({ preset, statsBody, users });
    return NextResponse.json({ status: "success", data: report });
  } catch {
    return NextResponse.json(
      { error: "טעינת דוח הכספים נכשלה. נסו שוב." },
      { status: 502 },
    );
  }
}
