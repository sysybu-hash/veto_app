import { NextRequest, NextResponse } from "next/server";
import { apiUrl, tunnelBypassHeaders } from "@/lib/env";

export const dynamic = "force-dynamic";

async function proxy(
  req: NextRequest,
  ctx: { params: Promise<{ id: string }> },
  method: "PUT" | "DELETE",
) {
  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) {
    return NextResponse.json({ error: "Unauthorized." }, { status: 401 });
  }
  const { id } = await ctx.params;
  if (!id) return NextResponse.json({ error: "Missing id" }, { status: 400 });

  let backendUrl: string;
  try {
    backendUrl = apiUrl(`/api/admin/users/${encodeURIComponent(id)}`);
  } catch {
    return NextResponse.json(
      { error: "NEXT_PUBLIC_API_ORIGIN is not configured." },
      { status: 503 },
    );
  }

  try {
    const init: RequestInit = {
      method,
      headers: {
        Authorization: auth,
        ...(method === "PUT" ? { "Content-Type": "application/json" } : {}),
        ...tunnelBypassHeaders(),
      },
      cache: "no-store",
      signal: AbortSignal.timeout(30_000),
    };
    if (method === "PUT") init.body = await req.text();

    const upstream = await fetch(backendUrl, init);
    const text = await upstream.text();
    const ct = upstream.headers.get("content-type") ?? "application/json";
    return new NextResponse(text, {
      status: upstream.status,
      headers: { "content-type": ct },
    });
  } catch {
    return NextResponse.json(
      { error: "Upstream user API unavailable." },
      { status: 502 },
    );
  }
}

export const PUT = (req: NextRequest, ctx: { params: Promise<{ id: string }> }) =>
  proxy(req, ctx, "PUT");
export const DELETE = (
  req: NextRequest,
  ctx: { params: Promise<{ id: string }> },
) => proxy(req, ctx, "DELETE");
