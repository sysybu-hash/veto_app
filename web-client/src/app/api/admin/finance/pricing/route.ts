import { NextRequest } from "next/server";
import { proxyAdminFinance } from "../_proxy";

export const dynamic = "force-dynamic";

/**
 * No local fallback here on purpose. The other finance endpoints can show
 * figures computed from existing admin APIs when the backend is behind, but
 * pricing is the source of truth for what people are charged — showing a
 * guess, or worse accepting an edit that goes nowhere, would be worse than an
 * error. If the backend cannot answer, the screen says so.
 */
export async function GET(req: NextRequest) {
  return proxyAdminFinance(req, "/api/admin/finance/pricing");
}

export async function PUT(req: NextRequest) {
  const body = await req.text();
  return proxyAdminFinance(req, "/api/admin/finance/pricing", {
    method: "PUT",
    body,
  });
}
