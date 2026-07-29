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
import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";
import { LanguageSwitcher } from "@/components/i18n/LanguageSwitcher";
import { ThemeToggle } from "@/components/ui/ThemeToggle";
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
  /** אזרחים: קישורים כבר במגירה וב־CitizenBottomNav — בלי כפילות בשורה העליונה */
  const showDesktopLinkRow =
    !hasToken || role === "lawyer" || role === "admin";

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

  if (pathname.startsWith("/call/")) {
    return null;
  }

  const logout = () => {
    disconnectSocket();
    clearJwt();
    setSession({ hasToken: false, role: null });
    setOpen(false);
    window.location.assign("/login");
  };

  const navBarClass =
    "sticky top-0 z-40 border-b border-subtle bg-surface-overlay px-3 py-2.5 shadow-sm backdrop-blur-xl";

  const desktopLinkClass = (active: boolean) =>
    `transition-colors ${active ? "text-veto-gold-dark dark:text-veto-gold" : "text-primary hover:text-veto-gold-dark"}`;

  return (
    <>
      <nav data-print="hide" className={navBarClass} aria-label="ניווט ראשי">
        <div className="mx-auto flex min-h-12 max-w-7xl items-center justify-between gap-2 px-2 sm:min-h-0 sm:gap-4 sm:px-3">
          <Link href={homeHref(role, hasToken)} className="flex min-w-0 shrink-0 items-center" aria-label="VETO">
            <VetoBrandLogo priority className="h-11 w-auto" />
          </Link>

          {showDesktopLinkRow ? (
            <div
              className="hidden min-w-0 flex-1 items-center justify-center gap-8 text-sm font-bold text-primary md:flex"
            >
              {items.slice(0, hasToken ? items.length : 3).map((item) => {
                const active = item.match?.(pathname) ?? pathname === item.href;
                return (
                  <Link key={item.href} href={item.href} className={desktopLinkClass(active)}>
                    {item.label}
                  </Link>
                );
              })}
            </div>
          ) : null}

          <div className="flex min-w-0 shrink-0 items-center justify-end gap-1.5 sm:gap-2">
            <ThemeToggle className="hidden sm:inline-flex" />
            {!hasToken ? (
              <>
                <LanguageSwitcher className="hidden sm:block" />
                <Link
                  href="/register/lawyer"
                  className="hidden rounded-xl px-3 py-2 text-sm font-bold text-primary transition-colors hover:text-veto-gold-dark sm:inline-flex"
                >
                  הצטרפות עורכי דין
                </Link>
                <Link
                  href="/login"
                  className="whitespace-nowrap rounded-xl border border-veto-gold/50 bg-veto-gold px-3 py-2 text-xs font-black text-primary shadow-[0_0_24px_-8px_rgba(197,160,89,0.8)] transition hover:bg-veto-gold-light sm:px-4 sm:py-2.5 sm:text-sm"
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
              className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl border border-default bg-surface-raised-2 text-primary shadow-sm transition hover:bg-white hover:text-veto-gold-dark dark:bg-white/10 dark:hover:bg-white/15"
            >
              <Menu className="h-5 w-5" aria-hidden />
            </button>
          </div>
        </div>
      </nav>

      {open ? (
        <>
          <div
            className="fixed inset-0 z-50 bg-surface-scrim backdrop-blur-sm"
            onClick={() => setOpen(false)}
            aria-hidden
          />
          <aside
            id="universal-nav-drawer"
            role="dialog"
            aria-modal="true"
            aria-label="תפריט ראשי"
            className="fixed inset-y-0 start-0 z-50 flex w-80 max-w-[88vw] flex-col border-e border-subtle bg-surface-raised-2 text-primary shadow-2xl backdrop-blur-xl"
          >
            <div
              className="flex items-center justify-between border-b border-subtle px-4 py-3"
            >
              <Link href={homeHref(role, hasToken)} className="flex items-center" onClick={() => setOpen(false)} aria-label="VETO">
                <VetoBrandLogo className="h-11 w-auto" />
              </Link>
              <button
                type="button"
                onClick={() => setOpen(false)}
                aria-label="סגירת תפריט"
                className="flex h-9 w-9 items-center justify-center rounded-xl border border-default bg-surface-overlay text-primary transition hover:bg-hover-overlay"
              >
                <X className="h-5 w-5" aria-hidden />
              </button>
            </div>

            <div
              className="border-b border-subtle px-4 py-3 text-xs font-bold text-secondary"
            >
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
                        active
                          ? "bg-veto-gold/15 text-brand-700" : "text-primary hover:bg-hover-overlay"}`}
                    >
                      <Icon className="h-5 w-5" aria-hidden />
                      {item.label}
                    </Link>
                  </li>
                );
              })}
            </ul>

            <div className="border-t border-subtle p-3">
              {hasToken ? (
                <button
                  type="button"
                  onClick={logout}
                  className="flex w-full items-center gap-3 rounded-2xl px-3 py-3 text-sm font-bold text-red-700 transition hover:bg-red-50 dark:text-red-400 dark:hover:bg-red-950/40"
                >
                  <LogOut className="h-5 w-5" aria-hidden />
                  יציאה
                </button>
              ) : (
                <Link
                  href="/register"
                  onClick={() => setOpen(false)}
                  className="flex items-center gap-3 rounded-2xl px-3 py-3 text-sm font-bold text-primary transition hover:bg-hover-overlay"
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
