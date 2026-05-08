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

/** Start PayPal subscription checkout (no JWT required). */
export async function createSubscriptionOrder(): Promise<CreateOrderResult> {
  const res = await fetch(apiUrl("/api/payments/subscription"), {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...tunnelBypassHeaders(),
    },
    body: JSON.stringify({}),
  });
  if (!res.ok) {
    throw new Error(await parseJsonError(res));
  }
  const data = (await res.json()) as { orderId?: string; approveUrl?: string };
  if (!data.orderId || !data.approveUrl) {
    throw new Error("Invalid payment response");
  }
  return { orderId: data.orderId, approveUrl: data.approveUrl };
}

export type CaptureResult = {
  success: boolean;
  captureId?: string | null;
  status?: string | null;
};

/** Capture after PayPal approval — requires JWT (user bound server-side). */
export async function captureSubscriptionPayment(
  orderId: string,
): Promise<CaptureResult> {
  const res = await authFetch(apiUrl("/api/payments/capture"), {
    method: "POST",
    body: JSON.stringify({ orderId, type: "subscription" }),
  });
  if (!res.ok) {
    throw new Error(await parseJsonError(res));
  }
  return (await res.json()) as CaptureResult;
}

/** True when JWT is present in memory (client). */
export function canCapturePayment(): boolean {
  return !!getJwt();
}
