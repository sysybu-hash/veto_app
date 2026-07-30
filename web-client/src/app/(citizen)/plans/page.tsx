"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import {
  createPlanOrder,
  fetchMyPlan,
  PRICING,
  type MyPlan,
  type PlanId,
} from "@/api/paymentApi";
import { CitizenBottomNav } from "@/components/citizen/CitizenBottomNav";
import { citizenBottomSafe } from "@/lib/vetoGlass";
import { getJwt } from "@/lib/authToken";
import { Button } from "@/components/ui/primitives/Button";

const PLAN_CARDS: Array<{
  id: PlanId;
  title: string;
  priceLine: string;
  bullets: string[];
  cta: string;
  highlight?: boolean;
}> = [
  {
    id: "demo",
    title: "מנוי דמו",
    priceLine: "ללא עלות · 30 יום",
    bullets: [
      "גישה מלאה למחולל המסמכים, כספת מוצפנת ויומן.",
      "ללא אפשרות שיחה עם עורך דין — לחיצה על SOS תוביל לדף תשלום ושדרוג.",
      "מופעל פעם אחת לכל חשבון.",
    ],
    cta: "הפעלה",
  },
  {
    id: "standard",
    title: "מנוי רגיל",
    priceLine: `₪${PRICING.standardMonthlyIls.toFixed(2)} לחודש`,
    bullets: [
      "גישה מלאה למערכת.",
      `כל שיחה עם עורך דין מחויבת ב-₪${PRICING.consultationIls.toFixed(2)}.`,
      `${PRICING.freeCallMinutes} דקות ראשונות כלולות; אחר כך ₪${PRICING.overtimeIlsPerMin.toFixed(2)} לדקה.`,
      "התשלום מאושר לפני חיבור לעורך הדין.",
    ],
    cta: "הצטרפות",
    highlight: true,
  },
  {
    id: "family",
    title: "מנוי משפחתי",
    priceLine: `₪${PRICING.familyMonthlyIls.toFixed(2)} לחודש`,
    bullets: [
      `עד ${PRICING.familySeats} משתמשים על אותו מנוי.`,
      `${PRICING.familyConsultationsIncluded} שיחות לעורך דין כלולות בכל חודש.`,
      `שיחה נוספת — ₪${PRICING.consultationIls.toFixed(2)}.`,
      `${PRICING.freeCallMinutes} דקות ראשונות כלולות; אחר כך ₪${PRICING.overtimeIlsPerMin.toFixed(2)} לדקה.`,
    ],
    cta: "הצטרפות",
  },
];

export default function PlansPage() {
  const router = useRouter();
  const [me, setMe] = useState<MyPlan | null>(null);
  const [busyPlan, setBusyPlan] = useState<PlanId | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  useEffect(() => {
    if (!getJwt()) {
      router.replace("/login");
      return;
    }
    void fetchMyPlan().then(setMe).catch(() => setMe(null));
  }, [router]);

  const subscribe = async (planId: PlanId) => {
    setError(null);
    setNotice(null);
    setBusyPlan(planId);
    try {
      const r = await createPlanOrder(planId);
      if (r.kind === "redirect") {
        window.location.assign(r.approveUrl);
        return;
      }
      setNotice("המנוי הופעל. תוקף עד " + new Date(r.expiry).toLocaleDateString("he-IL"));
      const fresh = await fetchMyPlan().catch(() => null);
      if (fresh) setMe(fresh);
    } catch (e) {
      setError(e instanceof Error ? e.message : "שגיאה ברכישת המנוי");
    } finally {
      setBusyPlan(null);
    }
  };

  const expiryStr = me?.expiry
    ? new Date(me.expiry).toLocaleDateString("he-IL")
    : null;

  return (
    <div
      dir="rtl"
      className={`mx-auto flex w-full max-w-3xl flex-col gap-6 px-4 py-8 ${citizenBottomSafe}`}
    >
      <header className="text-end">
        <h1 className="font-frank text-2xl font-bold text-primary">מנויים</h1>
        <p className="mt-2 text-sm text-muted">
          בחרו את המסלול המתאים לכם. המעבר לתשלום מתבצע באמצעות PayPal.
        </p>
      </header>

      {me && me.planId === "family" && (
        <a
          href="/family"
          className="rounded-2xl border border-emerald-500/30 bg-emerald-500/10 p-4 text-end text-sm text-emerald-200 transition hover:border-emerald-400/60"
        >
          ניהול בני המשפחה במנוי שלך → /family
        </a>
      )}

      {me && (
        <div className="rounded-2xl border border-veto-gold/35 bg-veto-gold/10 p-4 text-end text-sm">
          <p className="font-bold text-primary">המצב שלך</p>
          <p className="mt-1 text-secondary">
            {me.paymentExempt
              ? "חשבון פטור מתשלום (שיוך ע״י מנהל)."
              : me.planId
                ? `מסלול פעיל: ${me.planId === "demo" ? "דמו" : me.planId === "standard" ? "רגיל" : "משפחתי"}${expiryStr ? ` · עד ${expiryStr}` : ""}`
                : "אין מסלול פעיל."}
          </p>
          {(me.consultationsIncluded > 0 || me.consultationsUsed > 0) && (
            <p className="mt-1 text-xs text-muted">
              שיחות כלולות בחודש: {me.consultationsUsed}/{me.consultationsIncluded} (נותרו {me.consultationsRemaining}).
            </p>
          )}
        </div>
      )}

      {error && (
        <div role="alert" className="rounded-xl border border-red-500/30 bg-red-500/10 p-3 text-sm text-red-200">
          {error}
        </div>
      )}
      {notice && (
        <div role="status" className="rounded-xl border border-emerald-500/30 bg-emerald-500/10 p-3 text-sm text-emerald-200">
          {notice}
        </div>
      )}

      <div className="grid gap-4 md:grid-cols-3">
        {PLAN_CARDS.map((p) => {
          const isCurrent = me?.planId === p.id;
          const demoUsed = p.id === "demo" && (me?.planId === "demo" || (me && me.planId !== null));
          return (
            <article
              key={p.id}
              className={`flex flex-col rounded-2xl border p-5 backdrop-blur-xl ${
                p.highlight
                  ? "border-veto-gold/60 bg-veto-gold/10" : "border-subtle bg-white/[0.03]"}`}
            >
              <h2 className="font-frank text-lg font-bold text-primary">{p.title}</h2>
              <p className="mt-1 text-sm font-semibold text-amber-200">{p.priceLine}</p>
              <ul className="mt-3 flex-1 space-y-2 text-sm text-secondary">
                {p.bullets.map((b, i) => (
                  <li key={i} className="flex items-start gap-2">
                    <span aria-hidden className="mt-1.5 inline-block h-1.5 w-1.5 shrink-0 rounded-full bg-amber-300" />
                    <span>{b}</span>
                  </li>
                ))}
              </ul>
              <Button
                variant={p.highlight ? "primary" : "secondary"}
                size="md"
                fullWidth
                className="mt-5"
                disabled={busyPlan !== null || isCurrent || (p.id === "demo" && !!demoUsed)}
                loading={busyPlan === p.id}
                onClick={() => void subscribe(p.id)}
              >
                {isCurrent
                  ? "מסלול פעיל"
                  : p.id === "demo" && demoUsed
                    ? "כבר נוצל"
                    : busyPlan === p.id
                      ? "מעבר לתשלום…"
                      : p.cta}
              </Button>
            </article>
          );
        })}
      </div>

      <p className="text-center text-xs text-muted">
        כל שיחה ארוכה מ-{PRICING.freeCallMinutes} דקות מחויבת ב-₪{PRICING.overtimeIlsPerMin.toFixed(2)} לכל דקה נוספת.
        בסיום השיחה יוצג סיכום עלויות מלא.
      </p>

      <CitizenBottomNav active="hub" />
    </div>
  );
}
