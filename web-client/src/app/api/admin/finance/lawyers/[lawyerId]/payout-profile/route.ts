import { NextRequest, NextResponse } from "next/server";
import { apiUrl, tunnelBypassHeaders } from "@/lib/env";
import { isNotDeployed, proxyAdminFinance } from "../../../_proxy";

export const dynamic = "force-dynamic";

/** When finance payout-profile isn't deployed yet, save via admin lawyer update. */
async function fallbackSavePayoutProfile(
  auth: string,
  lawyerId: string,
  bodyText: string,
): Promise<NextResponse> {
  let payout: Record<string, unknown>;
  try {
    payout = JSON.parse(bodyText) as Record<string, unknown>;
  } catch {
    return NextResponse.json({ error: "JSON לא תקין." }, { status: 400 });
  }

  let backendUrl: string;
  try {
    backendUrl = apiUrl(`/api/admin/lawyers/${encodeURIComponent(lawyerId)}`);
  } catch {
    return NextResponse.json(
      { error: "NEXT_PUBLIC_API_ORIGIN לא מוגדר." },
      { status: 503 },
    );
  }

  try {
    const upstream = await fetch(backendUrl, {
      method: "PUT",
      headers: {
        Authorization: auth,
        "Content-Type": "application/json",
        ...tunnelBypassHeaders(),
      },
      body: JSON.stringify({ payout }),
      cache: "no-store",
      signal: AbortSignal.timeout(30_000),
    });
    const text = await upstream.text();
    if (!upstream.ok) {
      return new NextResponse(text, {
        status: upstream.status,
        headers: {
          "content-type":
            upstream.headers.get("content-type") ?? "application/json",
        },
      });
    }
    return NextResponse.json({
      status: "success",
      data: { savedVia: "admin-lawyer-update" },
    });
  } catch {
    return NextResponse.json(
      { error: "לא ניתן לשמור פרטי תשלום." },
      { status: 502 },
    );
  }
}

export async function PATCH(
  req: NextRequest,
  ctx: { params: Promise<{ lawyerId: string }> },
) {
  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) {
    return NextResponse.json({ error: "נדרשת התחברות." }, { status: 401 });
  }
  const { lawyerId } = await ctx.params;
  const body = await req.text();
  const proxied = await proxyAdminFinance(
    req,
    `/api/admin/finance/lawyers/${encodeURIComponent(lawyerId)}/payout-profile`,
    { method: "PATCH", body },
  );
  if (!isNotDeployed(proxied)) return proxied;
  return fallbackSavePayoutProfile(auth, lawyerId, body);
}
