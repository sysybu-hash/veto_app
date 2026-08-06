"use client";

import { Save, RotateCcw, Info } from "lucide-react";
import { useCallback, useEffect, useState } from "react";
import { authFetch } from "@/api/apiClient";
import { Button } from "@/components/ui/primitives/Button";

type FieldSpec = {
  min: number;
  max: number;
  integer?: boolean;
  label: string;
};

type Pricing = {
  consultationIls: number;
  overtimeIlsPerMin: number;
  freeCallMinutes: number;
  lawyerCallFeeIls: number;
  lawyerOvertimeShare: number;
};

type SubscriptionPlan = {
  id: string;
  label: string;
  monthlyIls: number;
  familySeats: number;
  consultationsIncluded: number;
  paypalPlanIdEnv: string | null;
  paypalPlanIdSet: boolean;
};

type PricingPayload = {
  pricing: Pricing;
  defaults: Pricing;
  fields: Record<keyof Pricing, FieldSpec>;
  subscriptionPlans: SubscriptionPlan[];
};

const ORDER: Array<keyof Pricing> = [
  "consultationIls",
  "overtimeIlsPerMin",
  "freeCallMinutes",
  "lawyerCallFeeIls",
  "lawyerOvertimeShare",
];

const HINTS: Record<keyof Pricing, string> = {
  consultationIls: "מה שהאזרח משלם על שיחת SOS.",
  overtimeIlsPerMin: "מחיר לכל דקה מעבר לחלון החינם.",
  freeCallMinutes: "כמה דקות ראשונות אינן מחויבות כלל.",
  lawyerCallFeeIls: "מה שעורך הדין מקבל על כל שיחה שהושלמה.",
  lawyerOvertimeShare: "החלק מתוך חיוב החריגה שעובר לעורך הדין. 0.7 = 70%.",
};

function ils(n: number): string {
  return `${n.toLocaleString("he-IL", { minimumFractionDigits: 2, maximumFractionDigits: 2 })} ₪`;
}

/**
 * Shows what a call of a given length would cost and earn under the values
 * currently in the form — so the effect of an edit is visible before saving,
 * not after the next real call.
 */
function previewCall(p: Pricing, minutes: number) {
  const overtimeMinutes = Math.max(0, minutes - p.freeCallMinutes);
  const overtimeIls = Math.round(overtimeMinutes * p.overtimeIlsPerMin * 100) / 100;
  const citizenPays = Math.round((p.consultationIls + overtimeIls) * 100) / 100;
  const lawyerGets =
    Math.round((p.lawyerCallFeeIls + overtimeIls * p.lawyerOvertimeShare) * 100) / 100;
  return {
    overtimeMinutes,
    overtimeIls,
    citizenPays,
    lawyerGets,
    platform: Math.round((citizenPays - lawyerGets) * 100) / 100,
  };
}

export function PricingPanel() {
  const [data, setData] = useState<PricingPayload | null>(null);
  const [draft, setDraft] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [msg, setMsg] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await authFetch("/api/admin/finance/pricing");
      const body = (await res.json().catch(() => ({}))) as {
        data?: PricingPayload;
        error?: string;
      };
      if (!res.ok || !body.data) {
        throw new Error(body.error || `טעינת המחירים נכשלה (${res.status})`);
      }
      setData(body.data);
      setDraft(
        Object.fromEntries(
          ORDER.map((k) => [k, String(body.data!.pricing[k])]),
        ),
      );
    } catch (e) {
      setError(e instanceof Error ? e.message : "טעינת המחירים נכשלה");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    queueMicrotask(() => void load());
  }, [load]);

  const draftAsPricing = (): Pricing | null => {
    if (!data) return null;
    const out = { ...data.pricing };
    for (const k of ORDER) {
      const n = Number(draft[k]);
      if (!Number.isFinite(n)) return null;
      out[k] = n;
    }
    return out;
  };

  const preview = draftAsPricing();
  const dirty =
    !!data && ORDER.some((k) => String(data.pricing[k]) !== String(draft[k] ?? ""));

  const save = async () => {
    if (!data) return;
    setBusy(true);
    setError(null);
    setMsg(null);
    try {
      const payload: Record<string, number> = {};
      for (const k of ORDER) payload[k] = Number(draft[k]);
      const res = await authFetch("/api/admin/finance/pricing", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      const body = (await res.json().catch(() => ({}))) as {
        error?: string;
        fields?: string[];
        data?: { changed?: string[] };
      };
      if (!res.ok) {
        throw new Error(body.fields?.join(" ") || body.error || "שמירה נכשלה");
      }
      const changed = body.data?.changed ?? [];
      setMsg(
        changed.length
          ? `נשמר. ${changed.length} מחירים עודכנו ונכנסו לתוקף מיד.`
          : "לא היו שינויים לשמור.",
      );
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : "שמירה נכשלה");
    } finally {
      setBusy(false);
    }
  };

  const resetToDefaults = () => {
    if (!data) return;
    if (
      !window.confirm(
        "להחזיר את כל המחירים לערכי ברירת המחדל שבקוד? השינוי עדיין לא יישמר עד שתלחצו על שמירה.",
      )
    ) {
      return;
    }
    setDraft(Object.fromEntries(ORDER.map((k) => [k, String(data.defaults[k])])));
  };

  if (loading) {
    return <p className="text-sm text-muted">טוען מחירים…</p>;
  }

  return (
    <div className="space-y-6">
      {error ? (
        <p
          role="alert"
          className="rounded-2xl border border-danger-border bg-danger-soft px-4 py-3 text-sm font-semibold text-danger-on-soft"
        >
          {error}
        </p>
      ) : null}
      {msg ? (
        <p
          role="status"
          className="rounded-2xl border border-success-border bg-success-soft px-4 py-3 text-sm font-semibold text-success-on-soft"
        >
          {msg}
        </p>
      ) : null}

      <section className="rounded-2xl border border-subtle bg-surface-raised/80 p-4 md:p-5">
        <h2 className="text-sm font-black text-primary">מחירי שיחה ותגמול עו״ד</h2>
        <p className="mt-1 text-xs text-muted">
          שינוי נכנס לתוקף בשיחה הבאה, בלי פריסה מחדש. שיחות שכבר הסתיימו וזכאויות
          שכבר נרשמו נשארות בתעריף שבו נוצרו.
        </p>

        <div className="mt-4 grid gap-4 sm:grid-cols-2">
          {ORDER.map((key) => {
            const spec = data?.fields[key];
            return (
              <label key={key} className="block">
                <span className="text-xs font-bold text-secondary">
                  {spec?.label ?? key}
                </span>
                <input
                  type="number"
                  step={spec?.integer ? 1 : 0.01}
                  min={spec?.min}
                  max={spec?.max}
                  value={draft[key] ?? ""}
                  onChange={(e) =>
                    setDraft((d) => ({ ...d, [key]: e.target.value }))
                  }
                  className="mt-1 w-full rounded-xl border border-subtle bg-surface-raised-2 px-3 py-2 text-sm text-primary"
                />
                <span className="mt-1 block text-[11px] text-muted">
                  {HINTS[key]}
                  {data ? ` ברירת מחדל: ${data.defaults[key]}.` : ""}
                </span>
              </label>
            );
          })}
        </div>

        <div className="mt-5 flex flex-wrap items-center gap-3">
          <Button type="button" onClick={() => void save()} disabled={busy || !dirty}>
            <Save className="h-4 w-4" aria-hidden />
            שמירת מחירים
          </Button>
          <Button
            type="button"
            variant="secondary"
            onClick={resetToDefaults}
            disabled={busy}
          >
            <RotateCcw className="h-4 w-4" aria-hidden />
            ערכי ברירת מחדל
          </Button>
          {dirty ? (
            <span className="text-xs font-bold text-warning-on-soft">
              יש שינויים שלא נשמרו
            </span>
          ) : null}
        </div>
      </section>

      {preview ? (
        <section className="rounded-2xl border border-subtle bg-surface-raised/80 p-4 md:p-5">
          <h2 className="text-sm font-black text-primary">
            תצוגה מקדימה — לפי הערכים שבטופס
          </h2>
          <div className="mt-3 overflow-x-auto" tabIndex={0} role="region" aria-label="תצוגה מקדימה של מחירים">
            <table className="w-full min-w-[520px] text-sm">
              <thead>
                <tr className="border-b border-subtle text-xs text-muted">
                  <th className="px-2 py-2 text-start">אורך שיחה</th>
                  <th className="px-2 py-2 text-start">דקות חריגה</th>
                  <th className="px-2 py-2 text-start">האזרח משלם</th>
                  <th className="px-2 py-2 text-start">עו״ד מקבל</th>
                  <th className="px-2 py-2 text-start">נשאר לפלטפורמה</th>
                </tr>
              </thead>
              <tbody>
                {[5, 15, 20, 30, 60].map((m) => {
                  const p = previewCall(preview, m);
                  return (
                    <tr key={m} className="border-b border-subtle/50">
                      <td className="px-2 py-2 font-bold text-primary">{m} דק׳</td>
                      <td className="px-2 py-2">{p.overtimeMinutes}</td>
                      <td className="px-2 py-2">{ils(p.citizenPays)}</td>
                      <td className="px-2 py-2">{ils(p.lawyerGets)}</td>
                      <td
                        className={`px-2 py-2 font-bold ${
                          p.platform < 0 ? "text-danger-on-soft" : "text-success-on-soft"
                        }`}
                      >
                        {ils(p.platform)}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
          <p className="mt-2 text-[11px] text-muted">
            &quot;נשאר לפלטפורמה&quot; מניח אזרח מחויב. עבור אזרח פטור (מנהל או חשבון
            שנוסף ידנית) ההכנסה היא 0 והשורה תהיה שלילית בגובה שכר עורך הדין.
          </p>
        </section>
      ) : null}

      <section className="rounded-2xl border border-brand bg-brand-soft p-4 md:p-5">
        <h2 className="flex items-center gap-2 text-sm font-black text-primary">
          <Info className="h-4 w-4" aria-hidden />
          מחירי מנוי — מנוהלים ב-PayPal
        </h2>
        <p className="mt-1 text-xs text-secondary">
          חיובים חוזרים נגבים מול תוכנית שמוגדרת בצד של PayPal. שינוי המספר כאן היה
          משנה רק את התצוגה באתר — PayPal היה ממשיך לגבות את הסכום הישן. לכן שינוי
          מחיר מנוי מחייב יצירת תוכנית חדשה והחלטה מה קורה למנויים קיימים.
        </p>
      </section>

      {/* The table sits on a normal surface, NOT inside the brand-tinted
          callout above: the `-on-soft` status colours are calibrated against
          their own tint (success text on success-soft), and putting them on a
          gold background drops them below 4.5:1 in dark mode. */}
      <section className="rounded-2xl border border-subtle bg-surface-raised/80 p-4 md:p-5">
        <h2 className="text-sm font-black text-primary">מסלולי מנוי</h2>
        <div className="mt-3 overflow-x-auto" tabIndex={0} role="region" aria-label="מסלולי מנוי">
          <table className="w-full min-w-[420px] text-sm">
            <thead>
              <tr className="border-b border-subtle text-xs text-muted">
                <th className="px-2 py-2 text-start">מסלול</th>
                <th className="px-2 py-2 text-start">מחיר חודשי</th>
                <th className="px-2 py-2 text-start">מושבים</th>
                <th className="px-2 py-2 text-start">תוכנית PayPal</th>
              </tr>
            </thead>
            <tbody>
              {(data?.subscriptionPlans ?? []).map((p) => (
                <tr key={p.id} className="border-b border-subtle/50">
                  <td className="px-2 py-2 font-bold text-primary">{p.label}</td>
                  <td className="px-2 py-2">{ils(p.monthlyIls)}</td>
                  <td className="px-2 py-2">{p.familySeats}</td>
                  <td className="px-2 py-2">
                    {p.paypalPlanIdEnv === null ? (
                      <span className="text-muted">—</span>
                    ) : p.paypalPlanIdSet ? (
                      <span className="rounded-full bg-success px-2 py-0.5 text-xs font-bold text-success-fg">
                        מוגדרת
                      </span>
                    ) : (
                      <span className="rounded-full bg-warning px-2 py-0.5 text-xs font-bold text-warning-fg">
                        חסרה
                      </span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}
