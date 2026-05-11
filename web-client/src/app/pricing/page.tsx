import type { Metadata } from "next";
import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";
import { PricingPlansClient } from "./PricingPlansClient";

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
    price: "₪99.00",
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
      price: plan.id === "demo" ? "0" : plan.id === "standard" ? "99.00" : "199.99",
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
        <div className="flex flex-wrap items-end gap-4">
          <VetoBrandLogo className="h-8 w-auto opacity-95 sm:h-9" />
          <p className="pb-1 text-xs font-black tracking-[0.24em] text-[#D8B867]">PRICING</p>
        </div>
        <h1 className="mt-4 max-w-3xl font-frank text-5xl font-black leading-tight text-white">
          מנוי משפטי ברור, עם PayPal Subscription אמיתי
        </h1>
        <p className="mt-5 max-w-2xl text-base leading-8 text-slate-400">
          בחרו מסלול, אשרו תשלום ב-PayPal, והמערכת תעדכן את סטטוס המנוי לפי subscription/webhook.
        </p>

        <PricingPlansClient plans={plans} />
      </section>
    </main>
  );
}
