import { NextRequest, NextResponse } from "next/server";
import { isNotDeployed, proxyAdminFinance } from "../../../_proxy";
import { buildFallbackLawyerFinance } from "../../../_fallback";

export const dynamic = "force-dynamic";

export async function GET(
  req: NextRequest,
  ctx: { params: Promise<{ lawyerId: string }> },
) {
  const { lawyerId } = await ctx.params;
  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) {
    return NextResponse.json({ error: "נדרשת התחברות." }, { status: 401 });
  }

  const qs = req.nextUrl.searchParams.toString();
  const proxied = await proxyAdminFinance(
    req,
    `/api/admin/finance/lawyers/${encodeURIComponent(lawyerId)}/earnings${qs ? `?${qs}` : ""}`,
  );
  // Fallback only for "backend not deployed yet", never for a real API failure.
  if (!isNotDeployed(proxied)) {
    return proxied;
  }

  try {
    const data = await buildFallbackLawyerFinance(auth);
    const earnings = data.earningsByLawyer[lawyerId] || [];
    return NextResponse.json({
      status: "success",
      data: { earnings, source: data.source },
    });
  } catch (e) {
    return NextResponse.json(
      {
        error:
          e instanceof Error ? e.message : "לא ניתן לטעון זכאויות עו״ד.",
      },
      { status: 502 },
    );
  }
}
