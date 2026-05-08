import { NextResponse } from "next/server";
import { getPublicApiOrigin } from "@/lib/env";
import { prisma } from "@/lib/prisma";

export const dynamic = "force-dynamic";

function tunnelBypassForFetch(): Record<string, string> {
  const base = getPublicApiOrigin();
  if (!base) return {};
  try {
    if (new URL(base).hostname.endsWith("loca.lt")) {
      return { "bypass-tunnel-reminder": "true" };
    }
  } catch {
    /* ignore */
  }
  return {};
}

export type AdminHealthResponse = {
  frontend: string;
  database_postgres: string;
  database_mongo: string;
  backend_render: string;
};

export async function GET() {
  const healthStatus: AdminHealthResponse = {
    frontend: "OK",
    database_postgres: "DOWN",
    database_mongo: "UNKNOWN",
    backend_render: "DOWN",
  };

  try {
    await prisma.$queryRaw`SELECT 1`;
    healthStatus.database_postgres = "OK";
  } catch {
    healthStatus.database_postgres = "DOWN";
  }

  const base = getPublicApiOrigin().replace(/\/$/, "");
  if (!base) {
    healthStatus.backend_render = "UNKNOWN";
    healthStatus.database_mongo = "UNKNOWN";
    return NextResponse.json(healthStatus);
  }

  try {
    const backendRes = await fetch(`${base}/health`, {
      cache: "no-store",
      headers: tunnelBypassForFetch(),
      signal: AbortSignal.timeout(12_000),
    });

    if (backendRes.ok) {
      healthStatus.backend_render = "OK";
      try {
        const body = (await backendRes.json()) as {
          mongo?: string;
          db?: string;
        };
        const m = body.mongo ?? body.db;
        if (m === "connected") healthStatus.database_mongo = "OK";
        else if (m === "error") healthStatus.database_mongo = "DOWN";
        else healthStatus.database_mongo = "UNKNOWN";
      } catch {
        healthStatus.database_mongo = "UNKNOWN";
      }
    } else {
      healthStatus.backend_render = "DOWN";
    }
  } catch {
    healthStatus.backend_render = "DOWN";
  }

  const degraded =
    healthStatus.database_postgres !== "OK" ||
    healthStatus.backend_render !== "OK";

  return NextResponse.json(healthStatus, { status: degraded ? 503 : 200 });
}
