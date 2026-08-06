import { NextRequest, NextResponse } from "next/server";
import { isNotDeployed, proxyAdminFinance } from "../_proxy";

export const dynamic = "force-dynamic";

export async function GET(req: NextRequest) {
  const qs = req.nextUrl.searchParams.toString();
  const proxied = await proxyAdminFinance(
    req,
    `/api/admin/finance/payouts${qs ? `?${qs}` : ""}`,
  );
  // Empty list instead of hard error when backend not deployed yet.
  if (isNotDeployed(proxied)) {
    return NextResponse.json({
      status: "success",
      data: { batches: [], source: "fallback-empty" },
    });
  }
  return proxied;
}

export async function POST(req: NextRequest) {
  const body = await req.text();
  const proxied = await proxyAdminFinance(req, "/api/admin/finance/payouts", {
    method: "POST",
    body,
  });
  if (isNotDeployed(proxied)) {
    return NextResponse.json(
      {
        error:
          "יצירת תשלום דורשת פריסת ה-backend. בינתיים אפשר לראות יתרות לפי פעילות בלבד.",
      },
      { status: 503 },
    );
  }
  return proxied;
}
