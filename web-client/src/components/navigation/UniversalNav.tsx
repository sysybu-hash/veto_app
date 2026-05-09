"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import {
  CalendarDays,
  FolderLock,
  Home,
  LayoutDashboard,
  LogIn,
  LogOut,
  Menu,
  MessageCircle,
  Settings,
  UserPlus,
  X,
} from "lucide-react";
import { clearJwt, getJwt, getRoleFromJwt } from "@/lib/authToken";
import { disconnectSocket } from "@/lib/socketClient";

type NavItem = {
  href: string;
  label: string;
  icon: typeof Home;
  match?: (pathname: string) => boolean;
};

const citizenItems: NavItem[] = [
  { href: "/hub", label: "בית", icon: Home, match: (p) => p === "/hub" },
  { href: "/chat", label: "צ׳אט", icon: MessageCircle, match: (p) => p === "/chat" },
  { href: "/vault", label: "כספת", icon: FolderLock, match: (p) => p.startsWith("/vault") },
  { href: "/calendar", label: "יומן", icon: CalendarDays, match: (p) => p === "/calendar" },
  { href: "/settings", label: "הגדרות", icon: Settings, match: (p) => p.startsWith("/settings") },
];

const lawyerItems: NavItem[] = [
  { href: "/dashboard", label: "דשבורד", icon: LayoutDashboard, match: (p) => p === "/dashboard" },
  { href: "/chat", label: "צ׳אט", icon: MessageCircle, match: (p) => p === "/chat" },
  { href: "/vault", label: "כספת", icon: FolderLock, match: (p) => p.startsWith("/vault") },
  { href: "/calendar", label: "ניהול תורים", icon: CalendarDays, match: (p) => p === "/calendar" },
  { href: "/settings", label: "זמינות ופרופיל", icon: Settings, match: (p) => p.startsWith("/settings") },
];

const adminItems: NavItem[] = [
  { href: "/admin/dashboard", label: "דשבורד", icon: LayoutDashboard, match: (p) => p.startsWith("/admin/dashboard") },
  { href: "/admin/vault", label: "כספת", icon: FolderLock, match: (p) => p.startsWith("/admin/vault") },
  { href: "/admin/settings", label: "הגדרות", icon: Settings, match: (p) => p.startsWith("/admin/settings") },
];

const guestItems: NavItem[] = [
  { href: "/", label: "בית", icon: Home, match: (p) => p === "/" },
  { href: "/login", label: "כניסה", icon: LogIn, match: (p) => p === "/login" },
  { href: "/register", label: "הרשמה", icon: UserPlus, match: (p) => p === "/register" },
];

function resolveItems(role: string | null, hasToken: boolean): NavItem[] {
  if (!hasToken) return guestItems;
  if (role === "admin") return adminItems;
  if (role === "lawyer") return lawyerItems;
  return citizenItems;
}

function homeHref(role: string | null, hasToken: boolean): string {
  if (!hasToken) return "/";
  if (role === "lawyer") return "/dashboard";
  if (role === "admin") return "/admin/dashboard";
  return "/hub";
}

export function UniversalNav() {
  const pathname = usePathname();
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [session, setSession] = useState<{ hasToken: boolean; role: string | null }>({
    hasToken: false,
    role: null,
  });
  const { hasToken, role } = session;
  const items = useMemo(() => resolveItems(role, hasToken), [hasToken, role]);

  useEffect(() => {
    queueMicrotask(() => {
      setSession({ hasToken: !!getJwt(), role: getRoleFromJwt() });
      setOpen(false);
    });
  }, [pathname]);

  useEffect(() => {
    if (!open) return;
    const onKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") setOpen(false);
    };
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [open]);

  const logout = () => {
    disconnectSocket();
    clearJwt();
    setSession({ hasToken: false, role: null });
    setOpen(false);
    router.replace("/login");
  };

  return (
    <>
      <nav className="sticky top-0 z-40 border-b border-white/40 bg-white/75 px-3 py-2 backdrop-blur-xl" aria-label="ניווט ראשי">
        <div className="mx-auto flex max-w-6xl items-center justify-between gap-3" dir="rtl">
          <Link href={homeHref(role, hasToken)} className="font-frank text-lg font-black text-slate-950">
            VETO
          </Link>
          <button
            type="button"
            onClick={() => setOpen(true)}
            className="inline-flex h-11 w-11 items-center justify-center rounded-2xl border border-slate-200 bg-white/80 text-slate-950 shadow-sm transition hover:bg-white"
            aria-label="פתיחת תפריט"
            aria-expanded={open}
          >
            <Menu className="h-5 w-5" aria-hidden />
          </button>
        </div>
      </nav>

      {open ? (
        <div className="fixed inset-0 z-[70]" role="dialog" aria-modal="true" dir="rtl">
          <button
            type="button"
            className="absolute inset-0 bg-slate-950/45 backdrop-blur-sm"
            aria-label="סגירת תפריט"
            onClick={() => setOpen(false)}
          />
          <aside className="absolute inset-y-0 end-0 flex w-[min(86vw,360px)] flex-col border-s border-white/30 bg-white/95 p-4 shadow-2xl">
            <div className="flex items-center justify-between gap-3 border-b border-slate-200 pb-4">
              <div>
                <p className="font-frank text-2xl font-black text-slate-950">VETO</p>
                <p className="mt-1 text-xs font-bold text-slate-500">
                  {hasToken ? (role === "lawyer" ? "עורך דין" : role === "admin" ? "מנהל" : "אזרח") : "אורח"}
                </p>
              </div>
              <button
                type="button"
                onClick={() => setOpen(false)}
                className="grid h-10 w-10 place-items-center rounded-2xl border border-slate-200 bg-white text-slate-900"
                aria-label="סגירת תפריט"
              >
                <X className="h-5 w-5" aria-hidden />
              </button>
            </div>

            <div className="min-h-0 flex-1 overflow-y-auto py-4">
              <div className="grid gap-2">
                {items.map((item) => {
                  const Icon = item.icon;
                  const active = item.match?.(pathname) ?? pathname === item.href;
                  return (
                    <Link
                      key={item.href}
                      href={item.href}
                      className={`flex items-center gap-3 rounded-2xl px-4 py-3 text-sm font-black transition ${
                        active
                          ? "bg-slate-950 text-white shadow-lg shadow-slate-950/15"
                          : "border border-slate-200 bg-white/70 text-slate-800 hover:bg-white"
                      }`}
                    >
                      <Icon className="h-5 w-5" aria-hidden />
                      {item.label}
                    </Link>
                  );
                })}
              </div>
            </div>

            {hasToken ? (
              <button
                type="button"
                onClick={logout}
                className="flex items-center justify-center gap-2 rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-black text-red-800"
              >
                <LogOut className="h-5 w-5" aria-hidden />
                התנתקות
              </button>
            ) : null}
          </aside>
        </div>
      ) : null}
    </>
  );
}
