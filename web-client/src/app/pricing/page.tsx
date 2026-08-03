import type { Metadata } from "next";
import { getVetoJwtFromCookies } from "@/lib/jwtCookie";
import { PricingPlansClient } from "./PricingPlansClient";

export const metadata: Metadata = {
  title: "Pricing | מחירים | Цены | VETO Legal",
  description: "VETO Legal plans for citizens and families, including PayPal subscription.",
  alternates: { canonical: "/pricing" },
  openGraph: {
    title: "VETO Pricing",
    description: "VETO Legal plans for citizens and families.",
    url: "/pricing",
  },
};

const offersJsonLd = {
  "@context": "https://schema.org",
  "@type": "OfferCatalog",
  name: "VETO Legal Plans",
  itemListElement: [
    {
      "@type": "Offer",
      name: "Demo",
      priceCurrency: "ILS",
      price: "0",
      availability: "https://schema.org/InStock",
      url: "/plans",
    },
    {
      "@type": "Offer",
      name: "Standard",
      priceCurrency: "ILS",
      price: "99.00",
      availability: "https://schema.org/InStock",
      url: "/plans",
    },
    {
      "@type": "Offer",
      name: "Family",
      priceCurrency: "ILS",
      price: "199.99",
      availability: "https://schema.org/InStock",
      url: "/plans",
    },
  ],
};

export default async function PricingPage() {
  const isLoggedIn = (await getVetoJwtFromCookies()) !== null;

  return (
    <>
      <script
        type="application/ld+json"
        suppressHydrationWarning
        dangerouslySetInnerHTML={{ __html: JSON.stringify(offersJsonLd) }}
      />
      <PricingPlansClient isLoggedIn={isLoggedIn} />
    </>
  );
}
