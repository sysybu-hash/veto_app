"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useState } from "react";
import { ArrowLeft, CheckCircle2, Users } from "lucide-react";
import PayPalCheckout from "@/components/billing/PayPalCheckout";

export type PricingPlan = {
  id: string;
  name: string;
  price: string;
  href: string;
  points: string[];
  featured?: boolean;
};

type Props = {
  plans: PricingPlan[];
};

export function PricingPlansClient({ plans }: Props) {
  const router = useRouter();
  const [successMsg, setSuccessMsg] = useState("");
  // The PayPal SDK mounts a real iframe via a client-only effect. On a hard
  // page load (F5, direct link, first visit) this Next.js version leaves it
  // permanently stuck as an empty placeholder — it only ever worked when
  // navigating here via client-side SPA transition. Deferring the mount to
  // after the first client render (rather than relying on SSR/hydration for
  // this subtree at all) makes every visit behave like the working path.
  const [mounted, setMounted] = useState(false);
  useEffect(() => {
    queueMicrotask(() => setMounted(true));
  }, []);

  const handlePaymentSuccess = useCallback(() => {
    setSuccessMsg(
      "המנוי הופעל בהצלחה! מעביר אותך למחולל המסמכים של VETO...",
    );
    window.setTimeout(() => {
      router.push("/vault/generator");
    }, 2500);
  }, [router]);

  return (
    <>
      {successMsg ? (
        <div
          role="status"
          className="mb-6 rounded-xl border border-emerald-500/40 bg-emerald-500/10 px-4 py-3 text-center text-sm font-medium text-emerald-900 dark:text-emerald-100"
        >
          {successMsg}
        </div>
      ) : null}

      <div className="mt-10 grid gap-5 lg:grid-cols-3">
        {plans.map((plan) => (
          <article
            key={plan.id}
            className={`rounded-lg border p-6 ${
              plan.featured
                ? "border-veto-gold/70 bg-veto-gold/10 shadow-[0_22px_80px_-45px_rgba(216,184,103,0.9)]" : "border-subtle bg-surface-raised-2"}`}
          >
            <div className="flex items-center justify-between gap-3">
              <h2 className="font-frank text-2xl font-black text-primary">
                {plan.name}
              </h2>
              {plan.id === "family" ? (
                <Users className="h-6 w-6 text-veto-gold-light" aria-hidden />
              ) : null}
            </div>
            <p className="mt-4 text-4xl font-black text-veto-gold-light">
              {plan.price}
            </p>
            <p className="mt-1 text-sm text-muted">לחודש</p>
            <ul className="mt-6 space-y-3">
              {plan.points.map((point) => (
                <li
                  key={point}
                  className="flex items-center gap-2 text-sm text-secondary"
                >
                  <CheckCircle2
                    className="h-4 w-4 shrink-0 text-veto-gold-light"
                    aria-hidden
                  />
                  {point}
                </li>
              ))}
            </ul>

            {plan.featured ? (
              <div className="mt-7">
                {mounted ? (
                  <PayPalCheckout
                    amount="99.00"
                    onSuccess={handlePaymentSuccess}
                  />
                ) : (
                  <div className="mx-auto h-[168px] w-full max-w-sm animate-pulse rounded-2xl border border-subtle bg-surface-raised-2" />
                )}
              </div>
            ) : (
              <Link
                href={plan.href}
                className="mt-7 inline-flex w-full items-center justify-center gap-2 rounded-xl border border-subtle px-5 py-3 text-sm font-black text-primary transition hover:bg-surface-overlay"
              >
                התחלת מנוי
                <ArrowLeft className="h-4 w-4" aria-hidden />
              </Link>
            )}
          </article>
        ))}
      </div>
    </>
  );
}
