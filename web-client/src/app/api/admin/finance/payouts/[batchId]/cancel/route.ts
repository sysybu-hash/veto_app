import { NextRequest } from "next/server";
import { proxyAdminFinance } from "../../../_proxy";

export const dynamic = "force-dynamic";

export async function PATCH(
  req: NextRequest,
  ctx: { params: Promise<{ batchId: string }> },
) {
  const { batchId } = await ctx.params;
  return proxyAdminFinance(
    req,
    `/api/admin/finance/payouts/${encodeURIComponent(batchId)}/cancel`,
    { method: "PATCH", body: "{}" },
  );
}
