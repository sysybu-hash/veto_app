import { listEvidenceForSession } from "@/app/actions/vault";
import { VaultPageClient } from "./VaultPageClient";

export const dynamic = "force-dynamic";

export default async function CitizenVaultPage() {
  const evidence = await listEvidenceForSession();
  return <VaultPageClient initialEvidence={evidence} />;
}
