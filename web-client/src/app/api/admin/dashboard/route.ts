import { type NextRequest, NextResponse } from "next/server";
import { cookies } from "next/headers";
import { apiUrl, tunnelBypassHeaders } from "@/lib/env";
import { decodeJwtPayload } from "@/lib/jwtCookie";

export const dynamic = "force-dynamic";

async function getBearerOrCookieToken(req: NextRequest): Promise<string | null> {
  const auth = req.headers.get("authorization");
  if (auth?.startsWith("Bearer ")) return auth.slice(7).trim();
  const jar = await cookies();
  const raw =
    jar.get("veto_jwt")?.value ??
    jar.get("veto_session")?.value ??
    jar.get("jwt")?.value;
  if (!raw?.trim()) return null;
  try {
    return decodeURIComponent(raw);
  } catch {
    return raw;
  }
}

type BackendUser = {
  _id: string;
  full_name?: string;
  phone?: string;
  email?: string;
  role?: string;
  status?: string;
  computed_status?: string;
  is_subscribed?: boolean;
  subscription_expiry?: string | null;
  manually_added?: boolean;
  is_active?: boolean;
  is_verified?: boolean;
  preferred_language?: string;
  createdAt?: string;
};

type BackendStats = {
  totalUsers?: number;
  activeLawyers?: number;
  pendingLawyers?: number;
  eventsToday?: number;
  users?: number;
  lawyers?: number;
  sos24h?: number;
  sos?: number;
};

async function callBackend(path: string, token: string) {
  const url = apiUrl(path);
  const r = await fetch(url, {
    headers: { Authorization: `Bearer ${token}`, ...tunnelBypassHeaders() },
    cache: "no-store",
    signal: AbortSignal.timeout(20_000),
  });
  return r;
}

export async function GET(req: NextRequest) {
  try {
    const token = await getBearerOrCookieToken(req);
    const payload = token ? decodeJwtPayload(token) : null;
    if (!token || payload?.role !== "admin") {
      return NextResponse.json({ error: "Forbidden." }, { status: 403 });
    }

    let usersPayload: { users?: BackendUser[] } = {};
    let statsPayload: BackendStats = {};
    let dbOk = false;
    try {
      const [u, s] = await Promise.all([
        callBackend("/api/admin/users-with-status", token),
        callBackend("/api/admin/stats", token),
      ]);
      if (u.ok) {
        usersPayload = (await u.json()) as { users?: BackendUser[] };
        dbOk = true;
      }
      if (s.ok) {
        statsPayload = (await s.json()) as BackendStats;
      }
    } catch (e) {
      console.error("[admin] backend fetch failed:", e);
    }

    const rawUsers: BackendUser[] = Array.isArray(usersPayload.users) ? usersPayload.users : [];
    const users = rawUsers.map((u) => ({
      id: u._id,
      externalId: u._id,
      email: u.email ?? "",
      phone: u.phone ?? "",
      name: u.full_name ?? "",
      role: (u.role ?? "user").toUpperCase(),
      createdAt: u.createdAt ?? new Date(0).toISOString(),
      isPro: !!u.is_subscribed,
      paymentExempt: !!u.manually_added,
      isActive: u.is_active !== false,
      isVerified: !!u.is_verified,
      subscriptionExpiry: u.subscription_expiry ?? null,
      status:
        u.computed_status ??
        u.status ??
        (u.manually_added ? "free" : u.is_subscribed ? "active" : "no_subscription"),
    }));

    return NextResponse.json({
      stats: {
        users: statsPayload.totalUsers ?? statsPayload.users ?? users.length,
        lawyers:
          statsPayload.activeLawyers ??
          statsPayload.lawyers ??
          users.filter((u) => u.role === "LAWYER").length,
        sos: statsPayload.eventsToday ?? statsPayload.sos24h ?? statsPayload.sos ?? 0,
      },
      users,
      health: {
        database: dbOk ? "OK" : "DOWN",
        api: "OK",
        timestamp: new Date().toISOString(),
      },
    });
  } catch (error) {
    console.error("Admin Dashboard Error:", error);
    return NextResponse.json(
      { error: "Failed to fetch admin data" },
      { status: 500 },
    );
  }
}
