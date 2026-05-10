import { NextRequest, NextResponse } from "next/server";
import { apiUrl, tunnelBypassHeaders } from "@/lib/env";

export const dynamic = "force-dynamic";

export async function PUT(
  req: NextRequest,
  ctx: { params: Promise<{ id: string }> },
) {
  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) {
    return NextResponse.json({ error: "Unauthorized." }, { status: 401 });
  }
  const { id } = await ctx.params;
  let backendUrl: string;
  try {
    backendUrl = apiUrl(`/api/admin/lawyers/${encodeURIComponent(id)}/approve`);
  } catch {
    return NextResponse.json(
      { error: "NEXT_PUBLIC_API_ORIGIN is not configured." },
      { status: 503 },
    );
  }
  try {
    const upstream = await fetch(backendUrl, {
      method: "PUT",
      headers: { Authorization: auth, ...tunnelBypassHeaders() },
      cache: "no-store",
      signal: AbortSignal.timeout(20_000),
    });
    const text = await upstream.text();
    const ct = upstream.headers.get("content-type") ?? "application/json";
    return new NextResponse(text, {
      status: upstream.status,
      headers: { "content-type": ct },
    });
  } catch {
    return NextResponse.json({ error: "Upstream unavailable." }, { status: 502 });
  }
}
