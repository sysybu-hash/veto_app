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
  ShieldCheck,
  UserPlus,
  X,
} from "lucide-react";
import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";
import { LanguageSwitcher } from "@/components/i18n/LanguageSwitcher";
import { ThemeToggle } from "@/components/ui/ThemeToggle";
import {
  clearJwt,
  getJwt,
  getRoleFromJwt,
  isOwnerFromJwt,
  isViewingAsFromJwt,
  returnToOwnerView,
  viewAs,
} from "@/lib/authToken";
import { disconnectSocket } from "@/lib/socketClient";
import { Button } from "@/components/ui/primitives/Button";
import { IconButton } from "@/components/ui/primitives/IconButton";
import { useTranslation } from "@/lib/i18n/LocaleProvider";

type NavItem = {
  href: string;
  label: string;
  icon: typeof Home;
  match?: (pathname: string) => boolean;
};

function homeHref(role: string | null, hasToken: boolean): string {
  if (!hasToken) return "/";
  if (role === "lawyer") return "/dashboard";
  if (role === "admin") return "/admin/dashboard";
  return "/hub";
}

export function UniversalNav() {
  const pathname = usePathname();
  const { t } = useTranslation();
  const [session, setSession] = useState<{
    hasToken: boolean;
    role: string | null;
    isOwner: boolean;
    viewingAs: boolean;
  }>({
    hasToken: false,
    role: null,
    isOwner: false,
    viewingAs: false,
  });
  const [open, setOpen] = useState(false);
  const [switchingRole, setSwitchingRole] = useState<string | null>(null);
  const [switchError, setSwitchError] = useState<string | null>(null);
  const [returning, setReturning] = useState(false);
  const { hasToken, role, isOwner, viewingAs } = session;

  const viewAsOptions = useMemo(
    () =>
      [
        { role: "citizen" as const, label: t("nav.roleCitizen"), home: "/hub" },
        { role: "lawyer" as const, label: t("nav.roleLawyer"), home: "/dashboard" },
        { role: "admin" as const, label: t("nav.roleAdmin"), home: "/admin/dashboard" },
      ] as const,
    [t],
  );

  const items = useMemo((): NavItem[] => {
    if (!hasToken) {
      return [
        { href: "/", label: t("nav.home"), icon: Home, match: (p) => p === "/" },
        { href: "/pricing", label: t("nav.pricing"), icon: Scale, match: (p) => p === "/pricing" },
        { href: "/contact", label: t("nav.contact"), icon: MessageCircle, match: (p) => p === "/contact" },
        {
          href: "/playbooks",
          label: t("nav.playbooks"),
          icon: ShieldCheck,
          match: (p) => p.startsWith("/playbooks"),
        },
        {
          href: "/register/lawyer",
          label: t("nav.forLawyers"),
          icon: UserPlus,
          match: (p) => p === "/register/lawyer",
        },
        { href: "/login", label: t("nav.login"), icon: LogIn, match: (p) => p === "/login" },
      ];
    }
    if (role === "admin") {
      return [
        {
          href: "/admin/dashboard",
          label: t("nav.dashboard"),
          icon: LayoutDashboard,
          match: (p) => p.startsWith("/admin/dashboard"),
        },
        {
          href: "/admin/lawyers",
          label: t("nav.lawyers"),
          icon: Scale,
          match: (p) => p.startsWith("/admin/lawyers"),
        },
        {
          href: "/admin/vault",
          label: t("nav.vault"),
          icon: FolderLock,
          match: (p) => p.startsWith("/admin/vault"),
        },
        {
          href: "/admin/settings",
          label: t("nav.settings"),
          icon: Settings,
          match: (p) => p.startsWith("/admin/settings"),
        },
      ];
    }
    if (role === "lawyer") {
      return [
        {
          href: "/dashboard",
          label: t("nav.dashboard"),
          icon: LayoutDashboard,
          match: (p) => p === "/dashboard",
        },
        { href: "/chat", label: t("nav.chat"), icon: MessageCircle, match: (p) => p === "/chat" },
        {
          href: "/vault",
          label: t("nav.vault"),
          icon: FolderLock,
          match: (p) => p.startsWith("/vault"),
        },
      ];
    }
    return [
      { href: "/hub", label: t("nav.home"), icon: Home, match: (p) => p === "/hub" },
      { href: "/chat", label: t("nav.chat"), icon: MessageCircle, match: (p) => p === "/chat" },
      {
        href: "/vault",
        label: t("nav.vault"),
        icon: FolderLock,
        match: (p) => p.startsWith("/vault"),
      },
      {
        href: "/plans",
        label: t("nav.plans"),
        icon: Scale,
        match: (p) => p.startsWith("/plans") || p.startsWith("/family"),
      },
      {
        href: "/calendar",
        label: t("nav.calendar"),
        icon: CalendarDays,
        match: (p) => p === "/calendar",
      },
      {
        href: "/settings",
        label: t("nav.settings"),
        icon: Settings,
        match: (p) => p.startsWith("/settings"),
      },
    ];
  }, [hasToken, role, t]);

  /** Citizens: links already in drawer + CitizenBottomNav — avoid duplicating top row */
  const showDesktopLinkRow =
    !hasToken || role === "lawyer" || role === "admin";

  const roleLabel = (r: string | null, token: boolean): string => {
    if (!token) return t("nav.roleGuest");
    if (r === "lawyer") return t("nav.roleLawyer");
    if (r === "admin") return t("nav.roleAdmin");
    return t("nav.roleCitizen");
  };

  useEffect(() => {
    queueMicrotask(() => {
      setSession({
        hasToken: !!getJwt(),
        role: getRoleFromJwt(),
        isOwner: isOwnerFromJwt(),
        viewingAs: isViewingAsFromJwt(),
      });
      setOpen(false);
    });
  }, [pathname]);

  const handleViewAs = async (targetRole: "citizen" | "lawyer" | "admin", home: string) => {
    setSwitchError(null);
    setSwitchingRole(targetRole);
    try {
      await viewAs(targetRole);
      window.location.assign(home);
    } catch (err) {
      setSwitchError(err instanceof Error ? err.message : t("nav.switchError"));
      setSwitchingRole(null);
    }
  };

  const handleReturnToOwnerView = async () => {
    setReturning(true);
    try {
      await returnToOwnerView();
      window.location.assign(homeHref(getRoleFromJwt(), true));
    } catch (err) {
      setSwitchError(err instanceof Error ? err.message : t("nav.returnError"));
      setReturning(false);
    }
  };

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
    setSession({ hasToken: false, role: null, isOwner: false, viewingAs: false });
    setOpen(false);
    window.location.assign("/login");
  };

  const navBarClass =
    "sticky top-0 z-40 border-b border-subtle bg-surface-overlay px-3 py-2.5 shadow-sm backdrop-blur-xl";

  const desktopLinkClass = (active: boolean) =>
    `transition-colors ${active ? "text-veto-gold-dark dark:text-veto-gold" : "text-primary hover:text-veto-gold-dark"}`;

  return (
    <>
      <nav data-print="hide" className={navBarClass} aria-label={t("nav.mainAria")}>
        <div className="mx-auto flex min-h-12 max-w-7xl items-center justify-between gap-2 px-2 sm:min-h-0 sm:gap-4 sm:px-3">
          <Link href={homeHref(role, hasToken)} className="flex min-w-0 shrink-0 items-center" aria-label="VETO">
            <VetoBrandLogo priority className="h-11 w-auto" />
          </Link>

          {showDesktopLinkRow ? (
            <div className="hidden min-w-0 flex-1 items-center justify-center gap-8 text-sm font-bold text-primary md:flex">
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
            <LanguageSwitcher className="hidden sm:block" />
            {!hasToken ? (
              <>
                <Link
                  href="/register/lawyer"
                  className="hidden rounded-xl px-3 py-2 text-sm font-bold text-primary transition-colors hover:text-veto-gold-dark sm:inline-flex"
                >
                  {t("nav.joinLawyers")}
                </Link>
                <Link
                  href="/login"
                  className="whitespace-nowrap rounded-xl border border-veto-gold/50 bg-veto-gold px-3 py-2 text-xs font-black text-primary shadow-[0_0_24px_-8px_rgba(197,160,89,0.8)] transition hover:bg-veto-gold-light sm:px-4 sm:py-2.5 sm:text-sm"
                >
                  {t("nav.personalArea")}
                </Link>
              </>
            ) : null}
            <IconButton
              variant="secondary"
              size="lg"
              onClick={() => setOpen(true)}
              label={t("nav.openMenu")}
              aria-expanded={open}
              aria-controls="universal-nav-drawer"
              icon={<Menu className="h-5 w-5" aria-hidden />}
            />
          </div>
        </div>

        {viewingAs ? (
          <div className="mx-auto flex max-w-7xl items-center justify-between gap-2 px-2 pb-1.5 pt-1 text-xs font-bold sm:px-3">
            <span className="rounded-full bg-veto-gold/15 px-3 py-1 text-brand-700 dark:text-veto-gold">
              {t("nav.viewingAs").replace("{role}", roleLabel(role, hasToken))}
            </span>
            <Button
              variant="link"
              size="sm"
              className="h-auto p-0"
              disabled={returning}
              loading={returning}
              onClick={() => void handleReturnToOwnerView()}
            >
              {t("nav.returnToMyView")}
            </Button>
          </div>
        ) : null}
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
            aria-label={t("nav.menuAria")}
            className="fixed inset-y-0 start-0 z-50 flex w-80 max-w-[88vw] flex-col border-e border-subtle bg-surface-raised-2 text-primary shadow-2xl backdrop-blur-xl"
          >
            <div className="flex items-center justify-between border-b border-subtle px-4 py-3">
              <Link
                href={homeHref(role, hasToken)}
                className="flex items-center"
                onClick={() => setOpen(false)}
                aria-label="VETO"
              >
                <VetoBrandLogo className="h-11 w-auto" />
              </Link>
              <IconButton
                variant="secondary"
                size="md"
                onClick={() => setOpen(false)}
                label={t("nav.closeMenu")}
                icon={<X className="h-5 w-5" aria-hidden />}
              />
            </div>

            <div className="flex items-center justify-between gap-2 border-b border-subtle px-4 py-3">
              <span className="text-xs font-bold text-secondary">{roleLabel(role, hasToken)}</span>
              <LanguageSwitcher />
            </div>

            {isOwner ? (
              <div className="border-b border-subtle px-4 py-3">
                <div className="mb-2 text-xs font-bold text-secondary">{t("nav.viewAs")}</div>
                <div className="flex gap-1.5" role="group" aria-label={t("nav.viewAsGroup")}>
                  {viewAsOptions.map((opt) => (
                    <button
                      key={opt.role}
                      type="button"
                      disabled={switchingRole !== null}
                      onClick={() => handleViewAs(opt.role, opt.home)}
                      aria-pressed={role === opt.role || (role === "user" && opt.role === "citizen")}
                      className={`flex-1 rounded-xl border px-2 py-2 text-xs font-bold transition disabled:cursor-not-allowed disabled:opacity-60 ${
                        role === opt.role || (role === "user" && opt.role === "citizen")
                          ? "border-veto-gold/50 bg-veto-gold/15 text-brand-700 dark:text-veto-gold"
                          : "border-default text-primary hover:bg-hover-overlay"
                      }`}
                    >
                      {switchingRole === opt.role ? "..." : opt.label}
                    </button>
                  ))}
                </div>
                {switchError ? (
                  <p className="mt-2 text-xs font-semibold text-red-700 dark:text-red-400">{switchError}</p>
                ) : null}
              </div>
            ) : null}

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
                          ? "bg-veto-gold/15 text-brand-700"
                          : "text-primary hover:bg-hover-overlay"
                      }`}
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
                <Button
                  variant="ghost"
                  fullWidth
                  className="justify-start text-red-700 hover:bg-red-50 dark:text-red-400 dark:hover:bg-red-950/40"
                  onClick={logout}
                  iconStart={<LogOut className="h-5 w-5" aria-hidden />}
                >
                  {t("nav.logout")}
                </Button>
              ) : (
                <Link
                  href="/register"
                  onClick={() => setOpen(false)}
                  className="flex items-center gap-3 rounded-2xl px-3 py-3 text-sm font-bold text-primary transition hover:bg-hover-overlay"
                >
                  <UserPlus className="h-5 w-5" aria-hidden />
                  {t("nav.registerCitizen")}
                </Link>
              )}
            </div>
          </aside>
        </>
      ) : null}
    </>
  );
}
