"use client";

import { useRouter } from "next/navigation";
import { clearJwt } from "@/lib/authToken";
import { disconnectSocket, setSocketAuthToken } from "@/lib/socketClient";

export default function AdminLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const router = useRouter();

  const handleLogout = () => {
    clearJwt();
    setSocketAuthToken(null);
    disconnectSocket();
    router.replace("/login");
  };

  return (
    <div className="flex min-h-full flex-col text-slate-100 antialiased">
      <header className="sticky top-0 z-30 border-b border-white/10 bg-white/[0.05] shadow-sm shadow-slate-900/5 backdrop-blur-xl">
        <div className="mx-auto flex h-14 max-w-7xl items-center justify-between gap-4 px-4 sm:h-16 sm:px-6 lg:px-8">
          <div className="flex items-center gap-3">
            <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-[#C5A059] text-sm font-bold text-slate-950 shadow-[0_0_16px_-4px_rgba(197,160,89,0.5)] sm:h-10 sm:w-10">
              V
            </div>
            <div>
              <p className="text-sm font-semibold leading-tight text-slate-100 sm:text-base">
                VETO Admin
              </p>
              <p className="hidden text-xs text-slate-500 sm:block">
                Operations console
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={handleLogout}
            className="rounded-xl border border-white/10 bg-white/[0.04] px-4 py-2 text-sm font-semibold text-slate-300 shadow-sm backdrop-blur-md transition hover:border-white/10 hover:bg-white/[0.06] active:scale-[0.98]"
          >
            Log out
          </button>
        </div>
      </header>
      <div className="flex flex-1 flex-col">{children}</div>
    </div>
  );
}
