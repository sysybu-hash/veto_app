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
  MessageCircle,
  Settings,
  UserPlus,
} from "lucide-react";
import { clearJwt, getJwt, getRoleFromJwt } from "@/lib/authToken";
import { disconnectSocket } from "@/lib/socketClient";
import { btnSecondaryGlass } from "@/lib/vetoGlass";

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

export function UniversalNav() {
  const pathname = usePathname();
  const router = useRouter();
  const [session, setSession] = useState<{ hasToken: boolean; role: string | null }>({
    hasToken: false,
    role: null,
  });
  const { hasToken, role } = session;
  const items = useMemo(() => resolveItems(role, hasToken), [hasToken, role]);

  useEffect(() => {
    queueMicrotask(() => {
      setSession({
        hasToken: !!getJwt(),
        role: getRoleFromJwt(),
      });
    });
  }, [pathname]);

  const logout = () => {
    disconnectSocket();
    clearJwt();
    setSession({ hasToken: false, role: null });
    router.replace("/login");
  };

  return (
    <nav className="sticky top-0 z-40 border-b border-white/40 bg-white/70 px-3 py-2 backdrop-blur-xl" aria-label="ניווט ראשי">
      <div className="mx-auto flex max-w-6xl items-center gap-2">
        <Link href={hasToken ? (role === "lawyer" ? "/dashboard" : role === "admin" ? "/admin/dashboard" : "/hub") : "/"} className="me-1 shrink-0 font-frank text-base font-black text-slate-950">
          VETO
        </Link>
        <div className="flex min-w-0 flex-1 gap-1 overflow-x-auto pb-0.5">
          {items.map((item) => {
            const Icon = item.icon;
            const active = item.match?.(pathname) ?? pathname === item.href;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`flex shrink-0 items-center gap-1.5 rounded-xl px-3 py-2 text-xs font-black transition ${
                  active
                    ? "bg-slate-900 text-white shadow-md"
                    : `${btnSecondaryGlass} border-transparent text-slate-700`
                }`}
              >
                <Icon className="h-4 w-4" aria-hidden />
                {item.label}
              </Link>
            );
          })}
        </div>
        {hasToken ? (
          <button
            type="button"
            onClick={logout}
            className="flex shrink-0 items-center gap-1.5 rounded-xl border border-red-200 bg-red-50/80 px-3 py-2 text-xs font-black text-red-800 transition hover:bg-red-100"
          >
            <LogOut className="h-4 w-4" aria-hidden />
            התנתקות
          </button>
        ) : null}
      </div>
    </nav>
  );
}
