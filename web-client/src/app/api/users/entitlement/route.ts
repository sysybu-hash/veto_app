import { NextRequest, NextResponse } from "next/server";
import { apiUrl, tunnelBypassHeaders } from "@/lib/env";

export const dynamic = "force-dynamic";

const fallbackEntitlement = {
  allowed: false,
  status: "payment_required",
  reason: "לא הצלחנו לאמת זכאות כרגע. אפשר להמשיך לדף המנויים או לנסות שוב.",
  nextAction: "pricing",
  planId: null,
  subscriptionExpiry: null,
  pendingOvertime: 0,
  paymentExempt: false,
  consultationExempt: false,
};

type ProfileResponse = {
  user?: {
    role?: string;
    manually_added?: boolean;
    is_payment_exempt?: boolean;
    is_subscribed?: boolean;
    subscription_plan?: string | null;
    subscription_expiry?: string | null;
  };
};

function deriveEntitlementFromProfile(profile: ProfileResponse) {
  const user = profile.user;
  if (!user) return null;

  const paymentExempt =
    user.role === "admin" || user.manually_added === true || user.is_payment_exempt === true;
  const expiry = user.subscription_expiry ? new Date(user.subscription_expiry) : null;
  const expired = expiry != null && Number.isFinite(expiry.getTime()) && expiry < new Date();
  const subscribed = user.is_subscribed === true && !expired;

  if (paymentExempt) {
    return {
      allowed: true,
      status: "exempt",
      reason: "חשבון פטור מתשלום כולל ייעוץ. אפשר להפעיל SOS.",
      nextAction: "sos",
      planId: user.subscription_plan ?? null,
      subscriptionExpiry: user.subscription_expiry ?? null,
      pendingOvertime: 0,
      paymentExempt: true,
      consultationExempt: true,
    };
  }

  if (subscribed) {
    return {
      allowed: true,
      status: user.subscription_plan === "family" ? "family_active" : "subscription_active",
      reason: "נמצא מנוי פעיל. אפשר להפעיל SOS.",
      nextAction: "sos",
      planId: user.subscription_plan ?? null,
      subscriptionExpiry: user.subscription_expiry ?? null,
      pendingOvertime: 0,
      paymentExempt: false,
      consultationExempt: false,
    };
  }

  return null;
}

async function fallbackFromProfile(auth: string) {
  try {
    const upstream = await fetch(apiUrl("/api/users/me"), {
      method: "GET",
      headers: {
        Authorization: auth,
        ...tunnelBypassHeaders(),
      },
      cache: "no-store",
      signal: AbortSignal.timeout(10_000),
    });

    if (!upstream.ok) return NextResponse.json(fallbackEntitlement);

    const profile = (await upstream.json().catch(() => ({}))) as ProfileResponse;
    return NextResponse.json(deriveEntitlementFromProfile(profile) ?? fallbackEntitlement);
  } catch {
    return NextResponse.json(fallbackEntitlement);
  }
}

export async function GET(req: NextRequest) {
  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) {
    return NextResponse.json({ error: "Unauthorized." }, { status: 401 });
  }

  try {
    const upstream = await fetch(apiUrl("/api/users/entitlement"), {
      method: "GET",
      headers: {
        Authorization: auth,
        ...tunnelBypassHeaders(),
      },
      cache: "no-store",
      signal: AbortSignal.timeout(10_000),
    });

    if (upstream.status === 404 || upstream.status >= 500) {
      return fallbackFromProfile(auth);
    }

    const text = await upstream.text();
    return new NextResponse(text, {
      status: upstream.status,
      headers: { "content-type": upstream.headers.get("content-type") ?? "application/json" },
    });
  } catch {
    return fallbackFromProfile(auth);
  }
}
