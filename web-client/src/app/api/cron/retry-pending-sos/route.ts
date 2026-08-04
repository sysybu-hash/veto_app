import { NextResponse } from "next/server";
import { retryPendingSosDeliveries } from "@/app/actions/sos";

/**
 * Cron / ops endpoint: republish SosEvents stuck in PENDING_DELIVERY.
 *
 * Auth: Authorization: Bearer $CRON_SECRET (or ?secret=) when CRON_SECRET is set.
 * Schedule via Vercel Cron or external pinger, e.g. every 5 minutes.
 */
export async function GET(req: Request) {
  const expected = process.env.CRON_SECRET?.trim();
  if (expected) {
    const auth = req.headers.get("authorization") || "";
    const bearer = auth.startsWith("Bearer ") ? auth.slice(7).trim() : "";
    const url = new URL(req.url);
    const q = url.searchParams.get("secret") || "";
    if (bearer !== expected && q !== expected) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }
  }

  const url = new URL(req.url);
  const limitRaw = Number(url.searchParams.get("limit") || "50");
  const limit = Number.isFinite(limitRaw) ? limitRaw : 50;

  const result = await retryPendingSosDeliveries(limit);
  return NextResponse.json({ ok: true, ...result });
}

export async function POST(req: Request) {
  return GET(req);
}
