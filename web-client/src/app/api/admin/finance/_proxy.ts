import { NextRequest, NextResponse } from "next/server";
import { apiUrl, tunnelBypassHeaders } from "@/lib/env";

/**
 * Marks the one case where a local fallback is legitimate: the backend simply
 * does not expose the finance routes yet. Set on the response so callers can
 * tell "not deployed" apart from "the API is broken" — a genuine 500 must
 * surface as an error, never as plausible-looking money computed here.
 */
export const NOT_DEPLOYED_HEADER = "x-veto-finance-not-deployed";

export function isNotDeployed(res: NextResponse): boolean {
  return res.headers.get(NOT_DEPLOYED_HEADER) === "1";
}

export async function proxyAdminFinance(
  req: NextRequest,
  backendPath: string,
  init?: { method?: string; body?: string | null },
): Promise<NextResponse> {
  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) {
    return NextResponse.json({ error: "נדרשת התחברות." }, { status: 401 });
  }

  let backendUrl: string;
  try {
    backendUrl = apiUrl(backendPath);
  } catch {
    return NextResponse.json(
      { error: "NEXT_PUBLIC_API_ORIGIN לא מוגדר." },
      { status: 503 },
    );
  }

  const method = init?.method || req.method || "GET";
  try {
    const upstream = await fetch(backendUrl, {
      method,
      headers: {
        Authorization: auth,
        ...(method !== "GET" && method !== "HEAD"
          ? { "Content-Type": "application/json" }
          : {}),
        ...tunnelBypassHeaders(),
      },
      body:
        method !== "GET" && method !== "HEAD"
          ? (init?.body ?? (await req.text()))
          : undefined,
      cache: "no-store",
      signal: AbortSignal.timeout(30_000),
    });

    if (upstream.status === 404 || upstream.status === 501) {
      return NextResponse.json(
        {
          error:
            "נתיב תשלומי עו״ד עדיין לא זמין בשרת. יש לפרוס את ה-backend המעודכן.",
          code: "FINANCE_PAYOUT_NOT_DEPLOYED",
        },
        { status: 503, headers: { [NOT_DEPLOYED_HEADER]: "1" } },
      );
    }

    const text = await upstream.text();
    const ct = upstream.headers.get("content-type") ?? "application/json";
    return new NextResponse(text, {
      status: upstream.status,
      headers: { "content-type": ct },
    });
  } catch {
    return NextResponse.json(
      { error: "לא ניתן להתחבר לשרת הכספים." },
      { status: 502 },
    );
  }
}
