import { NextRequest, NextResponse } from "next/server";
import { apiUrl, tunnelBypassHeaders } from "@/lib/env";

export const dynamic = "force-dynamic";

const fallbackEntitlement = {
  allowed: false,
  status: "payment_required",
  reason: "לא הצלחנו לאמת זכאות כרגע. אפשר להמשיך לדף המנויים או לנסות שוב.",
  nextAction: "pricing",
  planId: null,
  subscriptionExpiry: null,
  pendingOvertime: 0,
  paymentExempt: false,
};

export async function GET(req: NextRequest) {
  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) {
    return NextResponse.json({ error: "Unauthorized." }, { status: 401 });
  }

  try {
    const upstream = await fetch(apiUrl("/api/users/entitlement"), {
      method: "GET",
      headers: {
        Authorization: auth,
        ...tunnelBypassHeaders(),
      },
      cache: "no-store",
      signal: AbortSignal.timeout(10_000),
    });

    if (upstream.status === 404) {
      return NextResponse.json(fallbackEntitlement);
    }

    const text = await upstream.text();
    return new NextResponse(text, {
      status: upstream.status,
      headers: { "content-type": upstream.headers.get("content-type") ?? "application/json" },
    });
  } catch {
    return NextResponse.json(fallbackEntitlement);
  }
}
