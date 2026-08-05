"use client";

import type { ReactNode } from "react";
import { useEffect, useState } from "react";
import { CitizenSidebar } from "@/components/citizen/CitizenSidebar";
import { LawyerSidebar } from "@/components/lawyer/LawyerSidebar";
import { getRoleFromJwt } from "@/lib/authToken";

/**
 * Desktop sidebar for shared routes (/chat, /vault) that both roles use.
 * Avoids mounting citizen chrome when a lawyer opens those pages.
 */
export function RoleAwareAppChrome({ children }: { children: ReactNode }) {
  const [role, setRole] = useState<string | null>(null);

  useEffect(() => {
    queueMicrotask(() => setRole(getRoleFromJwt()));
  }, []);

  // JWTs use role `user` for citizens; view-as may surface `citizen`.
  const isLawyer = role === "lawyer" || role === "admin";

  return (
    <div className="flex min-h-full flex-col text-primary md:flex-row">
      {role == null ? (
        <aside className="hidden w-60 shrink-0 md:block" aria-hidden />
      ) : isLawyer ? (
        <LawyerSidebar />
      ) : (
        <CitizenSidebar />
      )}
      {/* Landmark for the shared /vault and /chat routes. Pages rendered here
          must NOT add their own <main>. */}
      <main className="flex min-w-0 flex-1 flex-col">{children}</main>
    </div>
  );
}
