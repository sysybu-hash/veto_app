"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
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
  const [session, setSession] = useState<{ hasToken: boolean; role: string | null }>({
    hasToken: false,
    role: null,
  });
  const [open, setOpen] = useState(false);
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

  // Close drawer on route change
  useEffect(() => {
    setOpen(false);
  }, [pathname]);

  // Lock body scroll while drawer is open
  useEffect(() => {
    if (typeof document === "undefined") return;
    const prev = document.body.style.overflow;
    if (open) document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = prev;
    };
  }, [open]);

  // Close on Escape
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setOpen(false);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open]);

  const logout = () => {
    disconnectSocket();
    clearJwt();
    setSession({ hasToken: false, role: null });
    setOpen(false);
    if (typeof window !== "undefined") {
      window.location.assign("/login");
    }
  };

  return (
    <>
      <nav
        className="sticky top-0 z-40 border-b border-white/[0.06] bg-slate-950/70 px-3 py-2 backdrop-blur-xl supports-[backdrop-filter]:bg-slate-950/60"
        aria-label="ניווט ראשי"
      >
        <div className="mx-auto flex max-w-6xl items-center justify-between gap-2">
          <Link
            href={homeHref(role, hasToken)}
            className="flex shrink-0 items-center"
            aria-label="VETO"
          >
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src="/veto-logo.svg"
              alt="VETO"
              className="h-7 w-auto select-none"
              draggable={false}
            />
          </Link>

          <button
            type="button"
            onClick={() => setOpen(true)}
            aria-label="פתיחת תפריט"
            aria-expanded={open}
            aria-controls="universal-nav-drawer"
            className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl border border-white/[0.08] bg-white/[0.03] text-slate-200 transition hover:bg-white/[0.08] hover:text-white"
          >
            <Menu className="h-5 w-5" aria-hidden />
          </button>
        </div>
      </nav>

      {/* Backdrop */}
      <div
        className={`fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-sm transition-opacity duration-200 ${
          open ? "opacity-100" : "pointer-events-none opacity-0"
        }`}
        onClick={() => setOpen(false)}
        aria-hidden
      />

      {/* Drawer (slides in from the start side — RTL app: from the right) */}
      <aside
        id="universal-nav-drawer"
        role="dialog"
        aria-modal="true"
        aria-label="תפריט ראשי"
        aria-hidden={!open}
        className="fixed inset-y-0 start-0 z-50 flex w-72 max-w-[85vw] flex-col border-e border-white/10 bg-slate-950/95 shadow-2xl backdrop-blur-xl transition-transform duration-200 ease-out"
        style={{
          transform: open ? "translateX(0)" : "translateX(100%)",
        }}
      >
        <div className="flex items-center justify-between border-b border-white/10 px-4 py-3">
          <Link
            href={homeHref(role, hasToken)}
            className="flex items-center"
            onClick={() => setOpen(false)}
            aria-label="VETO"
          >
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src="/veto-logo.svg"
              alt="VETO"
              className="h-7 w-auto select-none"
              draggable={false}
            />
          </Link>
          <button
            type="button"
            onClick={() => setOpen(false)}
            aria-label="סגירת תפריט"
            className="flex h-9 w-9 items-center justify-center rounded-xl border border-white/[0.08] bg-white/[0.03] text-slate-200 transition hover:bg-white/[0.08] hover:text-white"
          >
            <X className="h-5 w-5" aria-hidden />
          </button>
        </div>

        <ul className="flex flex-1 flex-col gap-1 overflow-y-auto px-3 py-4">
          {items.map((item) => {
            const Icon = item.icon;
            const active = item.match?.(pathname) ?? pathname === item.href;
            return (
              <li key={item.href}>
                <Link
                  href={item.href}
                  onClick={() => setOpen(false)}
                  className={`flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-bold transition ${
                    active
                      ? "border border-[#C5A059]/40 bg-[#C5A059] text-slate-950 shadow-[0_0_20px_-4px_rgba(197,160,89,0.5)]"
                      : "border border-white/[0.06] bg-white/[0.02] text-slate-200 hover:bg-white/[0.06] hover:text-white"
                  }`}
                >
                  <Icon className="h-5 w-5 shrink-0" aria-hidden />
                  <span className="truncate">{item.label}</span>
                </Link>
              </li>
            );
          })}
        </ul>

        {hasToken ? (
          <div className="border-t border-white/10 px-3 py-3">
            <button
              type="button"
              onClick={logout}
              className="flex w-full items-center justify-center gap-2 rounded-xl border border-red-500/30 bg-red-500/10 px-3 py-2.5 text-sm font-black text-red-300 transition hover:bg-red-500/20 hover:text-red-200"
            >
              <LogOut className="h-5 w-5" aria-hidden />
              התנתקות
            </button>
          </div>
        ) : null}
      </aside>
    </>
  );
}
