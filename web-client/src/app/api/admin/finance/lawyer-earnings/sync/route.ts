import { NextRequest, NextResponse } from "next/server";
import { isNotDeployed, proxyAdminFinance } from "../../_proxy";
import { buildFallbackLawyerFinance } from "../../_fallback";

export const dynamic = "force-dynamic";

export async function POST(req: NextRequest) {
  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) {
    return NextResponse.json({ error: "נדרשת התחברות." }, { status: 401 });
  }

  const body = await req.text();
  const proxied = await proxyAdminFinance(
    req,
    "/api/admin/finance/lawyer-earnings/sync",
    { method: "POST", body: body || "{}" },
  );
  if (!isNotDeployed(proxied)) {
    return proxied;
  }

  // Soft sync: recompute from emergency logs (no persistence until backend deploy).
  try {
    const data = await buildFallbackLawyerFinance(auth);
    const scanned = Object.values(data.earningsByLawyer).reduce(
      (n, rows) => n + rows.length,
      0,
    );
    return NextResponse.json({
      status: "success",
      data: {
        scanned,
        upserted: scanned,
        source: "fallback-activity",
        note: "חושב מיומני חירום קיימים. שמירה קבועה תתאפשר אחרי פריסת backend.",
      },
    });
  } catch (e) {
    return NextResponse.json(
      {
        error: e instanceof Error ? e.message : "סנכרון חלופי נכשל",
      },
      { status: 502 },
    );
  }
}
