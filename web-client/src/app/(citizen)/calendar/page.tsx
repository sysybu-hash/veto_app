"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { CalendarShell } from "@/components/calendar/CalendarShell";
import { CitizenBottomNav } from "@/components/citizen/CitizenBottomNav";
import { getJwt } from "@/lib/authToken";

export default function CitizenCalendarPage() {
  const router = useRouter();

  useEffect(() => {
    if (!getJwt()) router.replace("/login");
  }, [router]);

  return (
    <>
      <main className="min-h-[100dvh] bg-gradient-to-b from-zinc-950 via-surface-canvas to-zinc-950 pb-28">
        <CalendarShell />
      </main>
      <CitizenBottomNav active="calendar" />
    </>
  );
}
