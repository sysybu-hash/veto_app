import Link from "next/link";
import type { Metadata } from "next";
import { ArrowLeft, CheckCircle2, Users } from "lucide-react";

export const metadata: Metadata = {
  title: "Pricing",
  description: "מסלולי VETO Legal לאזרחים ומשפחות, כולל מנוי PayPal וייעוץ משפטי.",
  alternates: { canonical: "/pricing" },
  openGraph: {
    title: "VETO Pricing",
    description: "מסלולי VETO Legal לאזרחים ומשפחות.",
    url: "/pricing",
  },
};

const plans = [
  {
    id: "demo",
    name: "Demo",
    price: "₪0",
    href: "/plans",
    points: ["30 ימי התנסות", "היכרות עם הכספת", "ללא קריאות SOS פעילות"],
  },
  {
    id: "standard",
    name: "Standard",
    price: "₪19.90",
    href: "/plans",
    featured: true,
    points: ["משתמש יחיד", "SOS לעורך דין", "כספת ראיות", "מחולל מסמכים"],
  },
  {
    id: "family",
    name: "Family",
    price: "₪199.99",
    href: "/plans",
    points: ["עד 4 בני משפחה", "2 ייעוצים כלולים", "ניהול משפחתי", "אותה כספת עבודה"],
  },
];

export default function PricingPage() {
  const offersJsonLd = {
    "@context": "https://schema.org",
    "@type": "OfferCatalog",
    name: "VETO Legal Plans",
    itemListElement: plans.map((plan) => ({
      "@type": "Offer",
      name: plan.name,
      priceCurrency: "ILS",
      price: plan.id === "demo" ? "0" : plan.id === "standard" ? "19.90" : "199.99",
      availability: "https://schema.org/InStock",
      url: "/plans",
    })),
  };

  return (
    <main className="min-h-screen bg-slate-950 px-5 py-16 text-slate-100" dir="rtl">
      <script
        type="application/ld+json"
        suppressHydrationWarning
        dangerouslySetInnerHTML={{ __html: JSON.stringify(offersJsonLd) }}
      />
      <section className="mx-auto max-w-7xl">
        <p className="text-xs font-black tracking-[0.24em] text-[#D8B867]">VETO PRICING</p>
        <h1 className="mt-4 max-w-3xl font-frank text-5xl font-black leading-tight text-white">
          מנוי משפטי ברור, עם PayPal Subscription אמיתי
        </h1>
        <p className="mt-5 max-w-2xl text-base leading-8 text-slate-400">
          בחרו מסלול, אשרו תשלום ב-PayPal, והמערכת תעדכן את סטטוס המנוי לפי subscription/webhook.
        </p>

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
                <h2 className="font-frank text-2xl font-black text-white">{plan.name}</h2>
                {plan.id === "family" ? <Users className="h-6 w-6 text-[#D8B867]" aria-hidden /> : null}
              </div>
              <p className="mt-4 text-4xl font-black text-[#D8B867]">{plan.price}</p>
              <p className="mt-1 text-sm text-slate-500">לחודש</p>
              <ul className="mt-6 space-y-3">
                {plan.points.map((point) => (
                  <li key={point} className="flex items-center gap-2 text-sm text-slate-300">
                    <CheckCircle2 className="h-4 w-4 shrink-0 text-[#D8B867]" aria-hidden />
                    {point}
                  </li>
                ))}
              </ul>
              <Link
                href={plan.href}
                className={`mt-7 inline-flex w-full items-center justify-center gap-2 rounded-xl px-5 py-3 text-sm font-black transition ${
                  plan.featured
                    ? "bg-[#C5A059] text-slate-950 hover:bg-[#D8B867]"
                    : "border border-white/10 text-white hover:bg-white/[0.07]"
                }`}
              >
                התחלת מנוי
                <ArrowLeft className="h-4 w-4" aria-hidden />
              </Link>
            </article>
          ))}
        </div>
      </section>
    </main>
  );
}
