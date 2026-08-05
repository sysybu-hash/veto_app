import { NextRequest, NextResponse } from "next/server";
import { isNotDeployed, proxyAdminFinance } from "../_proxy";
import { buildFallbackLawyerFinance } from "../_fallback";

export const dynamic = "force-dynamic";

export async function GET(req: NextRequest) {
  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) {
    return NextResponse.json({ error: "נדרשת התחברות." }, { status: 401 });
  }

  // Prefer dedicated backend when deployed. Only substitute locally computed
  // figures when the route genuinely does not exist yet — a real 500/502 from
  // the API must stay an error rather than render as trustworthy money.
  const proxied = await proxyAdminFinance(req, "/api/admin/finance/lawyers");
  if (!isNotDeployed(proxied)) {
    return proxied;
  }

  try {
    const data = await buildFallbackLawyerFinance(auth);
    return NextResponse.json({
      status: "success",
      data: {
        settings: data.settings,
        lawyers: data.lawyers,
        source: data.source,
        ratesAuthoritative: data.ratesAuthoritative,
      },
    });
  } catch (e) {
    return NextResponse.json(
      {
        error:
          e instanceof Error
            ? e.message
            : "לא ניתן לטעון תשלומי עו״ד (גם במצב חלופי).",
      },
      { status: 502 },
    );
  }
}
