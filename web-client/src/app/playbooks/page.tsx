import type { Metadata } from "next";
import { PlaybooksIndexClient } from "@/components/playbooks/PlaybooksIndexClient";
import { isLegalCommerciallyApproved } from "@/lib/legalMode";

export const metadata: Metadata = {
  title: "מדריכי חירום | Emergency guides | Экстренные гайды | VETO Legal",
  description:
    "First-orientation emergency guides for common legal situations in Israel — police, traffic, and family. General information only.",
};

export default function PlaybooksIndexPage() {
  const approved = isLegalCommerciallyApproved();
  return <PlaybooksIndexClient approved={approved} />;
}
