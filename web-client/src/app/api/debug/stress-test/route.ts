import { randomUUID } from "node:crypto";
import { NextResponse } from "next/server";

import {
  SOS_ALERTS_CHANNEL,
  SOS_EVENT_NAME,
  getAblyRest,
  isAblyConfigured,
} from "@/lib/ably";
import { prisma } from "@/lib/prisma";

export const dynamic = "force-dynamic";

/**
 * POST — simulates 10 parallel SOS publishes for Ably/Vercel QA.
 * Protected by `STRESS_TEST_SECRET` header: `x-veto-stress-secret`.
 */
export async function POST(request: Request) {
  if (process.env.NODE_ENV === "production") {
    return NextResponse.json({ success: false, error: "Not found" }, {
      status: 404,
    });
  }

  const secret = process.env.STRESS_TEST_SECRET?.trim();
  const sent = request.headers.get("x-veto-stress-secret");
  if (!secret || sent !== secret) {
    return NextResponse.json({ success: false, error: "Unauthorized" }, {
      status: 401,
    });
  }

  if (!isAblyConfigured()) {
    return NextResponse.json(
      { success: false, error: "ABLY_API_KEY not configured" },
      { status: 503 },
    );
  }

  const rest = getAblyRest();
  const channel = rest.channels.get(SOS_ALERTS_CHANNEL);
  const t = Date.now();

  try {
    await Promise.all(
      Array.from({ length: 10 }, async (_, i) => {
        const eventId = randomUUID();
        const citizenId = `stress-${t}-${i}`;
        await prisma.sosEvent.create({
          data: {
            eventId,
            citizenId,
            urgency: "SOS",
            stressTest: true,
            status: "OPEN",
          },
        });
        return channel.publish(SOS_EVENT_NAME, {
          eventId,
          userId: citizenId,
          role: "citizen",
          timestamp: new Date().toISOString(),
          stress_test: true,
          urgency: "SOS",
          location: null,
        });
      }),
    );
    return NextResponse.json({ success: true, published: 10 });
  } catch (e) {
    console.error("[stress-test]", e);
    return NextResponse.json(
      { success: false, error: "Stress batch failed" },
      { status: 500 },
    );
  }
}
