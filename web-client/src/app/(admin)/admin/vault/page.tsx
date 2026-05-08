import { listEvidenceForSession } from "@/app/actions/vault";
import { VaultPageClient } from "@/app/(citizen)/vault/VaultPageClient";

export const dynamic = "force-dynamic";

export default async function AdminVaultPage() {
  const evidence = await listEvidenceForSession();
  return <VaultPageClient initialEvidence={evidence} adminContext />;
}
