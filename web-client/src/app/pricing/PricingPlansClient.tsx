"use client";

import Link from "next/link";
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
  isLoggedIn: boolean;
};

export function PricingPlansClient({ plans, isLoggedIn }: Props) {
  return (
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
              <PayPalCheckout amount="99.00" isLoggedIn={isLoggedIn} />
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
  );
}
