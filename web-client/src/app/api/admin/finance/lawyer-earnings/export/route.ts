import { NextRequest } from "next/server";
import { proxyAdminFinance } from "../../_proxy";

export const dynamic = "force-dynamic";

export async function GET(req: NextRequest) {
  const qs = req.nextUrl.searchParams.toString();
  return proxyAdminFinance(
    req,
    `/api/admin/finance/lawyer-earnings/export${qs ? `?${qs}` : ""}`,
  );
}
