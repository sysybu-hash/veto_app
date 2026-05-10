import { apiUrl, authFetch, tunnelBypassHeaders } from "@/api/apiClient";
import { getJwt } from "@/lib/authToken";

async function parseJsonError(res: Response): Promise<string> {
  try {
    const j = (await res.json()) as {
      error?: string;
      message?: string;
      success?: boolean;
    };
    if (j.success === false && typeof j.message === "string") {
      return j.message;
    }
    return j.error || j.message || res.statusText;
  } catch {
    return res.statusText;
  }
}

export type CreateOrderResult = {
  orderId: string;
  approveUrl: string;
};

export type PlanId = "demo" | "standard" | "family";

export type PlanOrderResult =
  | { kind: "redirect"; orderId: string; approveUrl: string; planId: PlanId }
  | { kind: "activated"; planId: "demo"; expiry: string };

/** Subscribe to a plan. Demo activates server-side; paid plans return a PayPal approveUrl. */
export async function createPlanOrder(planId: PlanId): Promise<PlanOrderResult> {
  const res = await authFetch(apiUrl("/api/payments/plan"), {
    method: "POST",
    body: JSON.stringify({ planId }),
  });
  if (!res.ok) throw new Error(await parseJsonError(res));
  const data = (await res.json()) as {
    orderId?: string;
    subscriptionId?: string;
    approveUrl?: string;
    planId?: PlanId;
    success?: boolean;
    expiry?: string;
  };
  if (data.success && data.planId === "demo") {
    return { kind: "activated", planId: "demo", expiry: data.expiry ?? "" };
  }
  const id = data.subscriptionId ?? data.orderId;
  if (!id || !data.approveUrl || !data.planId) {
    throw new Error("Invalid payment response");
  }
  return {
    kind: "redirect",
    orderId: id,
    approveUrl: data.approveUrl,
    planId: data.planId,
  };
}

/** Pay for overtime minutes after a call. */
export async function createOvertimeOrder(
  minutes: number,
): Promise<CreateOrderResult & { amountIls: number; overtimeMinutes: number }> {
  const res = await authFetch(apiUrl("/api/payments/overtime"), {
    method: "POST",
    body: JSON.stringify({ minutes }),
  });
  if (!res.ok) throw new Error(await parseJsonError(res));
  const data = (await res.json()) as {
    orderId?: string;
    approveUrl?: string;
    amountIls?: number;
    overtimeMinutes?: number;
  };
  if (!data.orderId || !data.approveUrl) throw new Error("Invalid payment response");
  return {
    orderId: data.orderId,
    approveUrl: data.approveUrl,
    amountIls: data.amountIls ?? 0,
    overtimeMinutes: data.overtimeMinutes ?? 0,
  };
}

/** Pay for a single consultation (₪79.90). Returns PayPal approveUrl. */
export async function createConsultationOrder(): Promise<CreateOrderResult> {
  const res = await authFetch(apiUrl("/api/payments/consultation"), {
    method: "POST",
    body: JSON.stringify({}),
  });
  if (!res.ok) throw new Error(await parseJsonError(res));
  const data = (await res.json()) as { orderId?: string; approveUrl?: string };
  if (!data.orderId || !data.approveUrl) throw new Error("Invalid payment response");
  return { orderId: data.orderId, approveUrl: data.approveUrl };
}

/** Backwards-compat shim — older code path expects this. Maps to standard plan. */
export async function createSubscriptionOrder(): Promise<CreateOrderResult> {
  const r = await createPlanOrder("standard");
  if (r.kind === "redirect") return { orderId: r.orderId, approveUrl: r.approveUrl };
  throw new Error("Unexpected demo activation");
}

export type CaptureResult = {
  success: boolean;
  captureId?: string | null;
  status?: string | null;
  consultationToken?: string;
};

/** Capture after PayPal approval — requires JWT (user bound server-side). */
export async function captureSubscriptionPayment(
  orderId: string,
  type: "plan" | "subscription" | "consultation" | "overtime" = "subscription",
  planId?: PlanId,
): Promise<CaptureResult> {
  const res = await authFetch(apiUrl("/api/payments/capture"), {
    method: "POST",
    body: JSON.stringify(
      type === "plan" || type === "subscription"
        ? { subscriptionId: orderId, type, planId }
        : { orderId, type, planId },
    ),
  });
  if (!res.ok) throw new Error(await parseJsonError(res));
  return (await res.json()) as CaptureResult;
}

export type MyPlan = {
  planId: PlanId | null;
  expiry: string | null;
  consultationsIncluded: number;
  consultationsUsed: number;
  consultationsRemaining: number;
  isFamilyOwner: boolean;
  paymentExempt: boolean;
};

export async function fetchMyPlan(): Promise<MyPlan> {
  const res = await authFetch(apiUrl("/api/payments/me/plan"), { method: "GET" });
  if (!res.ok) throw new Error(await parseJsonError(res));
  return (await res.json()) as MyPlan;
}

/** True when JWT is present in memory (client). */
export function canCapturePayment(): boolean {
  return !!getJwt();
}

/** Static pricing constants — mirrors backend/src/config/pricing.js. */
export const PRICING = {
  demoMonthlyIls: 0,
  standardMonthlyIls: 19.9,
  familyMonthlyIls: 199.99,
  consultationIls: 79.9,
  overtimeIlsPerMin: 0.5,
  freeCallMinutes: 15,
  familySeats: 4,
  familyConsultationsIncluded: 2,
  demoDurationDays: 30,
} as const;

// kept to avoid breaking any incidental import
export { tunnelBypassHeaders };
