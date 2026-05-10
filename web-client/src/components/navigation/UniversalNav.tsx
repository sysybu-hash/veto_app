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
  Scale,
  Settings,
  UserPlus,
  X,
} from "lucide-react";
import { LanguageSwitcher } from "@/components/i18n/LanguageSwitcher";
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
  { href: "/chat", label: "צ'אט", icon: MessageCircle, match: (p) => p === "/chat" },
  { href: "/vault", label: "כספת", icon: FolderLock, match: (p) => p.startsWith("/vault") },
  { href: "/plans", label: "מנוי", icon: Scale, match: (p) => p.startsWith("/plans") || p.startsWith("/family") },
  { href: "/calendar", label: "יומן", icon: CalendarDays, match: (p) => p === "/calendar" },
  { href: "/settings", label: "הגדרות", icon: Settings, match: (p) => p.startsWith("/settings") },
];

const lawyerItems: NavItem[] = [
  { href: "/dashboard", label: "דשבורד", icon: LayoutDashboard, match: (p) => p === "/dashboard" },
  { href: "/chat", label: "צ'אט", icon: MessageCircle, match: (p) => p === "/chat" },
  { href: "/vault", label: "כספת", icon: FolderLock, match: (p) => p.startsWith("/vault") },
];

const adminItems: NavItem[] = [
  { href: "/admin/dashboard", label: "דשבורד", icon: LayoutDashboard, match: (p) => p.startsWith("/admin/dashboard") },
  { href: "/admin/lawyers", label: "עורכי דין", icon: Scale, match: (p) => p.startsWith("/admin/lawyers") },
  { href: "/admin/vault", label: "כספת", icon: FolderLock, match: (p) => p.startsWith("/admin/vault") },
  { href: "/admin/settings", label: "הגדרות", icon: Settings, match: (p) => p.startsWith("/admin/settings") },
];

const guestItems: NavItem[] = [
  { href: "/", label: "בית", icon: Home, match: (p) => p === "/" },
  { href: "/pricing", label: "מחירים", icon: Scale, match: (p) => p === "/pricing" },
  { href: "/register/lawyer", label: "לעורכי דין", icon: UserPlus, match: (p) => p === "/register/lawyer" },
  { href: "/login", label: "כניסה", icon: LogIn, match: (p) => p === "/login" },
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

function roleLabel(role: string | null, hasToken: boolean): string {
  if (!hasToken) return "אורח";
  if (role === "lawyer") return "עורך דין";
  if (role === "admin") return "מנהל";
  return "אזרח";
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
      setSession({ hasToken: !!getJwt(), role: getRoleFromJwt() });
      setOpen(false);
    });
  }, [pathname]);

  useEffect(() => {
    if (typeof document === "undefined") return;
    const prev = document.body.style.overflow;
    if (open) document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = prev;
    };
  }, [open]);

  const logout = () => {
    disconnectSocket();
    clearJwt();
    setSession({ hasToken: false, role: null });
    setOpen(false);
    window.location.assign("/login");
  };

  return (
    <>
      <nav className="sticky top-0 z-40 border-b border-white/[0.06] bg-slate-950/78 px-3 py-2.5 backdrop-blur-xl supports-[backdrop-filter]:bg-slate-950/68" aria-label="ניווט ראשי">
        <div className="mx-auto flex max-w-7xl items-center justify-between gap-4 px-1">
          <Link href={homeHref(role, hasToken)} className="flex shrink-0 items-center" aria-label="VETO">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src="/veto-logo.svg" alt="VETO Legal" className="h-11 w-auto select-none" draggable={false} />
          </Link>

          <div className="hidden min-w-0 flex-1 items-center justify-center gap-8 text-sm font-semibold text-slate-300 md:flex">
            {items.slice(0, hasToken ? items.length : 3).map((item) => {
              const active = item.match?.(pathname) ?? pathname === item.href;
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`transition-colors ${active ? "text-[#D8B867]" : "hover:text-[#D8B867]"}`}
                >
                  {item.label}
                </Link>
              );
            })}
          </div>

          <div className="flex shrink-0 items-center gap-2">
            {!hasToken ? (
              <>
                <LanguageSwitcher className="hidden sm:block" />
                <Link
                  href="/register/lawyer"
                  className="hidden rounded-xl px-3 py-2 text-sm font-semibold text-slate-300 transition-colors hover:text-white sm:inline-flex"
                >
                  הצטרפות עורכי דין
                </Link>
                <Link
                  href="/login"
                  className="rounded-xl border border-[#C5A059]/50 bg-[#C5A059] px-4 py-2.5 text-sm font-black text-slate-950 shadow-[0_0_24px_-8px_rgba(197,160,89,0.8)] transition hover:bg-[#d8b867]"
                >
                  אזור אישי
                </Link>
              </>
            ) : null}
            <button
              type="button"
              onClick={() => setOpen(true)}
              aria-label="פתיחת תפריט"
              aria-expanded={open}
              aria-controls="universal-nav-drawer"
              className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl border border-white/[0.08] bg-white/[0.03] text-slate-200 transition hover:bg-white/[0.08] hover:text-white"
            >
              <Menu className="h-5 w-5" aria-hidden />
            </button>
          </div>
        </div>
      </nav>

      {open ? (
        <>
          <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-sm" onClick={() => setOpen(false)} aria-hidden />
          <aside
            id="universal-nav-drawer"
            role="dialog"
            aria-modal="true"
            aria-label="תפריט ראשי"
            className="fixed inset-y-0 start-0 z-50 flex w-80 max-w-[88vw] flex-col border-e border-white/10 bg-slate-950/96 shadow-2xl backdrop-blur-xl"
          >
            <div className="flex items-center justify-between border-b border-white/10 px-4 py-3">
              <Link href={homeHref(role, hasToken)} className="flex items-center" onClick={() => setOpen(false)} aria-label="VETO">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src="/veto-logo.svg" alt="VETO Legal" className="h-11 w-auto select-none" draggable={false} />
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

            <div className="border-b border-white/10 px-4 py-3 text-xs font-bold text-slate-400">
              {roleLabel(role, hasToken)}
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
                      className={`flex items-center gap-3 rounded-2xl px-3 py-3 text-sm font-bold transition ${
                        active ? "bg-[#C5A059]/15 text-[#D8B867]" : "text-slate-200 hover:bg-white/[0.06]"
                      }`}
                    >
                      <Icon className="h-5 w-5" aria-hidden />
                      {item.label}
                    </Link>
                  </li>
                );
              })}
            </ul>

            <div className="border-t border-white/10 p-3">
              {hasToken ? (
                <button
                  type="button"
                  onClick={logout}
                  className="flex w-full items-center gap-3 rounded-2xl px-3 py-3 text-sm font-bold text-red-200 transition hover:bg-red-500/10"
                >
                  <LogOut className="h-5 w-5" aria-hidden />
                  יציאה
                </button>
              ) : (
                <Link
                  href="/register"
                  onClick={() => setOpen(false)}
                  className="flex items-center gap-3 rounded-2xl px-3 py-3 text-sm font-bold text-slate-200 transition hover:bg-white/[0.06]"
                >
                  <UserPlus className="h-5 w-5" aria-hidden />
                  הרשמת אזרח
                </Link>
              )}
            </div>
          </aside>
        </>
      ) : null}
    </>
  );
}
