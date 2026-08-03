import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { PlaybookDetailClient } from "@/components/playbooks/PlaybookDetailClient";
import { isLegalCommerciallyApproved } from "@/lib/legalMode";
import { getPlaybook, PLAYBOOKS } from "@/lib/playbooks";

type Props = { params: Promise<{ id: string }> };

export function generateStaticParams() {
  return PLAYBOOKS.map((p) => ({ id: p.id }));
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const pb = getPlaybook(id);
  return {
    title: pb ? `${pb.title.he} | ${pb.title.en} | VETO` : "Guide | VETO",
  };
}

export default async function PlaybookDetailPage({ params }: Props) {
  const { id } = await params;
  const pb = getPlaybook(id);
  if (!pb) notFound();
  const approved = isLegalCommerciallyApproved();

  return <PlaybookDetailClient playbook={pb} approved={approved} />;
}
