import type { Metadata } from "next";
import { ContactPageClient } from "@/components/contact/ContactPageClient";
import { getSupportEmail, getSupportWhatsapp } from "@/lib/env";
import { isLegalCommerciallyApproved } from "@/lib/legalMode";

export const metadata: Metadata = {
  title: "צור קשר | Contact | Контакты | VETO Legal",
  description:
    "Support, privacy, subscriptions, and lawyer onboarding — contact channels for VETO Legal.",
};

export default function ContactPage() {
  const email = getSupportEmail();
  const waDigits = getSupportWhatsapp();
  const waHref = waDigits ? `https://wa.me/${waDigits}` : "";
  const approved = isLegalCommerciallyApproved();

  return (
    <ContactPageClient email={email} waHref={waHref} approved={approved} />
  );
}
