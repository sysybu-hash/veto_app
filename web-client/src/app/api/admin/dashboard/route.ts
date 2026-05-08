import { Role } from "@prisma/client";
import { type NextRequest, NextResponse } from "next/server";
import { cookies } from "next/headers";
import { decodeJwtPayload } from "@/lib/jwtCookie";
import { prisma } from "@/lib/prisma";

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

/**
 * Aggregated admin dashboard: Prisma stats + recent users.
 * Subscription flags are not stored on User yet; `isPro` is reserved for future billing sync.
 */
export async function GET(req: NextRequest) {
  try {
    const token = await getBearerOrCookieToken(req);
    const payload = token ? decodeJwtPayload(token) : null;
    if (payload?.role !== "admin") {
      return NextResponse.json({ error: "Forbidden." }, { status: 403 });
    }

    const dayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

    const [userCount, lawyerCount, sosCount, recentUsers, pgOk] =
      await Promise.all([
        prisma.user.count(),
        prisma.user.count({ where: { role: Role.LAWYER } }),
        prisma.sosEvent.count({
          where: { createdAt: { gte: dayAgo } },
        }),
        prisma.user.findMany({
          orderBy: { createdAt: "desc" },
          take: 50,
          select: {
            id: true,
            externalId: true,
            email: true,
            name: true,
            role: true,
            createdAt: true,
          },
        }),
        prisma.$queryRaw`SELECT 1`.then(() => true).catch(() => false),
      ]);

    const users = recentUsers.map((u) => ({
      id: u.id,
      externalId: u.externalId,
      email: u.email,
      name: u.name ?? "",
      role: u.role,
      createdAt: u.createdAt.toISOString(),
      /** Billing not on Postgres User yet; default false until synced from Mongo/payments. */
      isPro: false,
    }));

    const health = {
      database: pgOk ? "OK" : "DOWN",
      api: "OK",
      timestamp: new Date().toISOString(),
    };

    return NextResponse.json({
      stats: {
        users: userCount,
        lawyers: lawyerCount,
        sos: sosCount,
      },
      users,
      health,
    });
  } catch (error) {
    console.error("Admin API Error:", error);
    return NextResponse.json(
      { error: "Failed to fetch admin data" },
      { status: 500 },
    );
  }
}
