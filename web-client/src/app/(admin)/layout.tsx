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
    <div className="min-h-full flex flex-col bg-slate-50 text-slate-900 antialiased">
      <header className="sticky top-0 z-30 border-b border-slate-200/90 bg-white shadow-sm shadow-slate-900/5">
        <div className="mx-auto flex h-14 max-w-7xl items-center justify-between gap-4 px-4 sm:h-16 sm:px-6 lg:px-8">
          <div className="flex items-center gap-3">
            <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-slate-900 text-sm font-bold text-white sm:h-10 sm:w-10">
              V
            </div>
            <div>
              <p className="text-sm font-semibold leading-tight text-slate-900 sm:text-base">
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
            className="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow-sm transition hover:border-slate-300 hover:bg-slate-50 active:scale-[0.98]"
          >
            Log out
          </button>
        </div>
      </header>
      <div className="flex flex-1 flex-col">{children}</div>
    </div>
  );
}
