import { NextRequest, NextResponse } from "next/server";
import { apiUrl, tunnelBypassHeaders } from "@/lib/env";

export const dynamic = "force-dynamic";

export async function PUT(req: NextRequest) {
  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) {
    return NextResponse.json({ error: "Unauthorized." }, { status: 401 });
  }
  let backendUrl: string;
  try {
    backendUrl = apiUrl("/api/admin/settings/eu-compliance");
  } catch {
    return NextResponse.json({ error: "NEXT_PUBLIC_API_ORIGIN is not configured." }, { status: 503 });
  }
  const upstream = await fetch(backendUrl, {
    method: "PUT",
    headers: {
      Authorization: auth,
      "Content-Type": "application/json",
      ...tunnelBypassHeaders(),
    },
    body: await req.text(),
    cache: "no-store",
  });
  return new NextResponse(await upstream.text(), {
    status: upstream.status,
    headers: { "content-type": upstream.headers.get("content-type") ?? "application/json" },
  });
}
