"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

export default function SettingsSecurityLegacyPage() {
  const router = useRouter();
  useEffect(() => {
    router.replace("/settings?tab=security");
  }, [router]);
  return null;
}
