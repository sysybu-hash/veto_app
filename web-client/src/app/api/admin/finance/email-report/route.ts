import { NextRequest, NextResponse } from "next/server";
import { apiUrl, tunnelBypassHeaders } from "@/lib/env";

export const dynamic = "force-dynamic";

export async function POST(req: NextRequest) {
  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) {
    return NextResponse.json({ error: "נדרשת התחברות." }, { status: 401 });
  }

  let backendUrl: string;
  try {
    backendUrl = apiUrl("/api/admin/finance/email-report");
  } catch {
    return NextResponse.json(
      { error: "NEXT_PUBLIC_API_ORIGIN לא מוגדר." },
      { status: 503 },
    );
  }

  let body: string;
  try {
    body = await req.text();
  } catch {
    return NextResponse.json({ error: "גוף הבקשה לא תקין." }, { status: 400 });
  }

  try {
    const upstream = await fetch(backendUrl, {
      method: "POST",
      headers: {
        Authorization: auth,
        "Content-Type": "application/json",
        ...tunnelBypassHeaders(),
      },
      body,
      cache: "no-store",
      signal: AbortSignal.timeout(30_000),
    });

    if (upstream.status === 404 || upstream.status === 501) {
      return NextResponse.json(
        {
          error:
            "שליחת מייל דורשת פריסת ה-backend המעודכן (נתיב finance/email-report) והגדרת SMTP בשרת.",
          smtpConfigured: false,
        },
        { status: 503 },
      );
    }

    const text = await upstream.text();
    const ct = upstream.headers.get("content-type") ?? "application/json";
    if (!upstream.ok) {
      try {
        const j = JSON.parse(text) as { error?: string };
        if (j.error) {
          return NextResponse.json(
            { error: j.error },
            { status: upstream.status },
          );
        }
      } catch {
        /* fall through */
      }
    }
    return new NextResponse(text, {
      status: upstream.status,
      headers: { "content-type": ct },
    });
  } catch {
    return NextResponse.json(
      { error: "לא ניתן להתחבר לשרת לשליחת המייל." },
      { status: 502 },
    );
  }
}
