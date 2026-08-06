import { apiUrl, tunnelBypassHeaders } from "@/lib/env";

export const FALLBACK_CONSULTATION_ILS = 79.9;
/**
 * Last-resort rates, used ONLY when the backend cannot tell us its own.
 * They mirror backend/src/config/pricing.js defaults
 * (LAWYER_CALL_FEE_ILS = CONSULTATION_ILS * 0.65, LAWYER_OVERTIME_SHARE = 0.7).
 * If those env vars are set on Render, `fetchPayoutRates` below picks up the
 * real values — do not treat these constants as the source of truth.
 */
export const FALLBACK_CALL_FEE_ILS = 51.94;
export const FALLBACK_OVERTIME_SHARE = 0.7;

export type PayoutRates = {
  callFeeIls: number;
  overtimeShare: number;
  consultationIls: number;
  /** true when the rates came from the server rather than the constants above */
  authoritative: boolean;
};

function round2(n: number): number {
  return Math.round((Number(n) || 0) * 100) / 100;
}

/**
 * Ask the backend for the live payout rates. Available even when the rest of
 * the finance API is missing, so the fallback view stays in sync with whatever
 * the server would actually pay.
 */
async function fetchPayoutRates(auth: string): Promise<PayoutRates> {
  try {
    const res = await backendGet("/api/admin/finance/payout-settings", auth);
    if (res.ok) {
      const body = (await res.json()) as {
        data?: {
          callFeeIls?: number;
          overtimeShare?: number;
          consultationIls?: number;
        };
      };
      const d = body.data;
      if (d && Number.isFinite(Number(d.callFeeIls))) {
        return {
          callFeeIls: Number(d.callFeeIls),
          overtimeShare: Number.isFinite(Number(d.overtimeShare))
            ? Number(d.overtimeShare)
            : FALLBACK_OVERTIME_SHARE,
          consultationIls: Number.isFinite(Number(d.consultationIls))
            ? Number(d.consultationIls)
            : FALLBACK_CONSULTATION_ILS,
          authoritative: true,
        };
      }
    }
  } catch {
    /* fall through to constants */
  }
  return {
    callFeeIls: FALLBACK_CALL_FEE_ILS,
    overtimeShare: FALLBACK_OVERTIME_SHARE,
    consultationIls: FALLBACK_CONSULTATION_ILS,
    authoritative: false,
  };
}

export async function backendGet(
  path: string,
  auth: string,
): Promise<Response> {
  return fetch(apiUrl(path), {
    method: "GET",
    headers: { Authorization: auth, ...tunnelBypassHeaders() },
    cache: "no-store",
    signal: AbortSignal.timeout(25_000),
  });
}

type LawyerDoc = {
  _id: string;
  full_name?: string;
  phone?: string;
  email?: string;
  is_active?: boolean;
  is_approved?: boolean;
  total_cases_handled?: number;
  payout?: Record<string, unknown> | null;
};

type EventDoc = {
  _id: string;
  status?: string;
  assigned_lawyer_id?:
    | string
    | { _id?: string; full_name?: string; phone?: string }
    | null;
  charge_amount_ils?: number;
  charge_status?: string;
  call_duration_seconds?: number;
  call_type?: string;
  completed_at?: string;
  createdAt?: string;
  triggered_at?: string;
};

function lawyerIdOf(ev: EventDoc): string | null {
  const a = ev.assigned_lawyer_id;
  if (!a) return null;
  if (typeof a === "string") return a;
  if (a._id) return String(a._id);
  return null;
}

export function computeEarning(
  ev: EventDoc,
  rates: Pick<PayoutRates, "callFeeIls" | "overtimeShare">,
): {
  baseFeeIls: number;
  overtimeShareIls: number;
  lawyerAmountIls: number;
  durationSeconds: number;
} {
  const baseFeeIls = round2(rates.callFeeIls);
  const chargeIls = round2(ev.charge_amount_ils || 0);
  const chargeStatus = ev.charge_status || "none";
  const overtimeShareIls =
    chargeStatus === "paid" || chargeStatus === "pending"
      ? round2(chargeIls * rates.overtimeShare)
      : 0;
  return {
    baseFeeIls,
    overtimeShareIls,
    lawyerAmountIls: round2(baseFeeIls + overtimeShareIls),
    durationSeconds: Number(ev.call_duration_seconds) || 0,
  };
}

export async function buildFallbackLawyerFinance(auth: string) {
  const [lawyersRes, eventsRes, rates] = await Promise.all([
    backendGet("/api/admin/lawyers", auth),
    backendGet("/api/admin/emergency-logs", auth),
    fetchPayoutRates(auth),
  ]);

  if (!lawyersRes.ok) {
    throw new Error(`לא ניתן לטעון עורכי דין (${lawyersRes.status})`);
  }

  const lawyersBody = (await lawyersRes.json()) as { lawyers?: LawyerDoc[] };
  const lawyers = (lawyersBody.lawyers || []).filter(
    (l) => l.is_approved !== false,
  );

  let events: EventDoc[] = [];
  if (eventsRes.ok) {
    const eventsBody = (await eventsRes.json()) as { events?: EventDoc[] };
    events = Array.isArray(eventsBody.events) ? eventsBody.events : [];
  }

  const completed = events.filter((e) => {
    const st = String(e.status || "");
    return (
      (st === "completed" || st === "closed" || !!e.completed_at) &&
      !!lawyerIdOf(e)
    );
  });

  const byLawyer = new Map<
    string,
    {
      pendingAmount: number;
      pendingCalls: number;
      seconds: number;
      earnings: Array<{
        id: string;
        eventId: string;
        callCompletedAt: string | null;
        durationSeconds: number;
        callType: string | null;
        chargeAmountIls: number;
        chargeStatus: string | null;
        baseFeeIls: number;
        overtimeShareIls: number;
        lawyerAmountIls: number;
        status: string;
        payoutBatchId: null;
        notes: string;
      }>;
    }
  >();

  for (const ev of completed) {
    const lid = lawyerIdOf(ev);
    if (!lid) continue;
    if (!byLawyer.has(lid)) {
      byLawyer.set(lid, {
        pendingAmount: 0,
        pendingCalls: 0,
        seconds: 0,
        earnings: [],
      });
    }
    const bucket = byLawyer.get(lid)!;
    const calc = computeEarning(ev, rates);
    bucket.pendingAmount += calc.lawyerAmountIls;
    bucket.pendingCalls += 1;
    bucket.seconds += calc.durationSeconds;
    bucket.earnings.push({
      id: `fallback-${ev._id}`,
      eventId: String(ev._id),
      callCompletedAt:
        ev.completed_at || ev.triggered_at || ev.createdAt || null,
      durationSeconds: calc.durationSeconds,
      callType: ev.call_type || null,
      chargeAmountIls: round2(ev.charge_amount_ils || 0),
      chargeStatus: ev.charge_status || null,
      baseFeeIls: calc.baseFeeIls,
      overtimeShareIls: calc.overtimeShareIls,
      lawyerAmountIls: calc.lawyerAmountIls,
      status: "pending",
      payoutBatchId: null,
      notes: "תצוגה זמנית עד פריסת backend",
    });
  }

  const rows = lawyers.map((l) => {
    const id = String(l._id);
    const s = byLawyer.get(id) || {
      pendingAmount: 0,
      pendingCalls: 0,
      seconds: 0,
      earnings: [],
    };
    return {
      id,
      fullName: l.full_name || "",
      phone: l.phone || "",
      email: l.email || "",
      isActive: l.is_active !== false,
      totalCasesHandled: l.total_cases_handled || 0,
      payout: l.payout || null,
      pendingAmountIls: round2(s.pendingAmount),
      pendingCalls: s.pendingCalls,
      inPayoutAmountIls: 0,
      inPayoutCalls: 0,
      paidAmountIls: 0,
      paidCalls: 0,
      activitySeconds: s.seconds,
      rates: {
        baseFee: round2(rates.callFeeIls),
        overtimeShare: rates.overtimeShare,
      },
      _earnings: s.earnings,
    };
  });

  return {
    settings: {
      callFeeIls: round2(rates.callFeeIls),
      overtimeShare: rates.overtimeShare,
      consultationIls: rates.consultationIls,
    },
    lawyers: rows
      .map((r) => {
        const { _earnings: _unused, ...rest } = r;
        void _unused;
        return rest;
      })
      .sort((a, b) => b.pendingAmountIls - a.pendingAmountIls),
    earningsByLawyer: Object.fromEntries(
      rows.map((r) => [r.id, r._earnings]),
    ) as Record<string, (typeof rows)[0]["_earnings"]>,
    source: "fallback-activity" as const,
    /** false ⇒ the amounts shown are estimated from constants, not server rates */
    ratesAuthoritative: rates.authoritative,
  };
}
