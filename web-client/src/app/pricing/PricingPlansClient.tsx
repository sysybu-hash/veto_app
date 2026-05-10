"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useCallback, useState } from "react";
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
          className="mb-6 rounded-xl border border-emerald-500/40 bg-emerald-500/10 px-4 py-3 text-center text-sm font-medium text-emerald-100"
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
                ? "border-[#C5A059]/70 bg-[#C5A059]/10 shadow-[0_22px_80px_-45px_rgba(216,184,103,0.9)]"
                : "border-white/10 bg-white/[0.04]"
            }`}
          >
            <div className="flex items-center justify-between gap-3">
              <h2 className="font-frank text-2xl font-black text-white">
                {plan.name}
              </h2>
              {plan.id === "family" ? (
                <Users className="h-6 w-6 text-[#D8B867]" aria-hidden />
              ) : null}
            </div>
            <p className="mt-4 text-4xl font-black text-[#D8B867]">
              {plan.price}
            </p>
            <p className="mt-1 text-sm text-slate-500">לחודש</p>
            <ul className="mt-6 space-y-3">
              {plan.points.map((point) => (
                <li
                  key={point}
                  className="flex items-center gap-2 text-sm text-slate-300"
                >
                  <CheckCircle2
                    className="h-4 w-4 shrink-0 text-[#D8B867]"
                    aria-hidden
                  />
                  {point}
                </li>
              ))}
            </ul>

            {plan.featured ? (
              <div className="mt-7">
                <PayPalCheckout
                  amount="99.00"
                  onSuccess={handlePaymentSuccess}
                />
              </div>
            ) : (
              <Link
                href={plan.href}
                className="mt-7 inline-flex w-full items-center justify-center gap-2 rounded-xl border border-white/10 px-5 py-3 text-sm font-black text-white transition hover:bg-white/[0.07]"
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
