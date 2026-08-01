"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

export default function SettingsBillingPage() {
  const router = useRouter();
  useEffect(() => {
    router.replace("/settings?tab=billing");
  }, [router]);
  return null;
}
