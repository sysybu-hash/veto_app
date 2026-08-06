"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { AiConsultShell } from "@/components/ai-consult/AiConsultShell";
import { getJwt } from "@/lib/authToken";

/** Shared AI consult — outside (citizen) layout so lawyers keep lawyer chrome. */
export default function AiConsultPage() {
  const router = useRouter();

  useEffect(() => {
    if (!getJwt()) router.replace("/login");
  }, [router]);

  return <AiConsultShell />;
}
