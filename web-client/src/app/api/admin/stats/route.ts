import { NextRequest, NextResponse } from "next/server";
import { apiUrl, tunnelBypassHeaders } from "@/lib/env";

export const dynamic = "force-dynamic";

/**
 * Proxies authenticated GET /api/admin/stats to the Render/Mongo backend so the admin UI can call a same-origin URL.
 */
export async function GET(req: NextRequest) {
  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) {
    return NextResponse.json({ error: "Unauthorized." }, { status: 401 });
  }

  let backendUrl: string;
  try {
    backendUrl = apiUrl("/api/admin/stats");
  } catch {
    return NextResponse.json(
      { error: "NEXT_PUBLIC_API_ORIGIN is not configured." },
      { status: 503 },
    );
  }

  try {
    const upstream = await fetch(backendUrl, {
      method: "GET",
      headers: {
        Authorization: auth,
        ...tunnelBypassHeaders(),
      },
      cache: "no-store",
      signal: AbortSignal.timeout(15_000),
    });

    const text = await upstream.text();
    const ct = upstream.headers.get("content-type") ?? "application/json";
    return new NextResponse(text, {
      status: upstream.status,
      headers: { "content-type": ct },
    });
  } catch {
    return NextResponse.json(
      { error: "Upstream stats unavailable." },
      { status: 502 },
    );
  }
}
