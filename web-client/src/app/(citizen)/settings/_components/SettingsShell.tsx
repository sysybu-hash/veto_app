"use client";

import Link from "next/link";
import { usePathname, useSearchParams } from "next/navigation";
import { CitizenBottomNav } from "@/components/citizen/CitizenBottomNav";
import { clearJwt } from "@/lib/authToken";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { disconnectSocket } from "@/lib/socketClient";
import { btnSecondaryGlass } from "@/lib/vetoGlass";
import { Button } from "@/components/ui";
import { SettingsProvider, useSettings } from "./settings-context";

const TABS = [
  { tab: "profile", legacy: "/settings/profile", labelKey: "settings.profile" },
  {
    tab: "notifications",
    legacy: "/settings/notifications",
    labelKey: "settings.notifications",
  },
  { tab: "security", legacy: "/settings/security", labelKey: "settings.security" },
  { tab: "billing", legacy: "/settings/billing", labelKey: "settings.billing" },
] as const;

type TabId = (typeof TABS)[number]["tab"];

function resolveActiveTabId(pathname: string, searchTab: string | null): TabId {
  const legacy = TABS.find((x) => pathname === x.legacy);
  if (legacy) return legacy.tab;

  const raw = searchTab ?? "profile";
  const hit = TABS.find((x) => x.tab === raw);
  if (hit) return hit.tab;
  return "profile";
}

function SettingsChrome({
  children,
  variant,
}: {
  children: React.ReactNode;
  variant: "citizen" | "admin";
}) {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const { t: tr } = useTranslation();
  const { loading, saving, message, error, save } = useSettings();

  const currentTab = searchParams.get("tab");
  const activeTabId = resolveActiveTabId(pathname, currentTab);

  const showSave =
    activeTabId === "profile" || activeTabId === "notifications";

  const settingsBase = variant === "admin" ? "/admin/settings" : "/settings";

  const handleLogout = () => {
    disconnectSocket();
    clearJwt();
    if (typeof window !== "undefined") {
      window.location.assign("/login");
    }
  };

  return (
    <>
      <main
        className={`mx-auto flex w-full max-w-lg flex-1 flex-col gap-6 px-4 py-8 ${variant === "citizen" ? "pb-[calc(10rem+env(safe-area-inset-bottom))]" : "pb-12"}`}
      >
        {variant === "admin" && (
          <Link
            href="/admin/dashboard"
            className="text-sm font-semibold text-veto-gold hover:underline"
          >
            ← מרכז שליטה
          </Link>
        )}

        <div>
          <h1 className="font-frank text-2xl font-bold tracking-tight text-primary">
            {tr("settings.title")}
          </h1>
          <p className="font-heebo mt-1 text-sm text-secondary">
            {tr("settings.shellSubtitle")}
          </p>
        </div>

        <nav
          className="flex flex-wrap gap-2 rounded-2xl border border-subtle bg-surface-sunken p-2 backdrop-blur-md"
          aria-label="Settings sections"
        >
          {TABS.map((tab) => {
            const active = activeTabId === tab.tab;
            return (
              <Link
                key={tab.tab}
                href={`${settingsBase}?tab=${tab.tab}`}
                className={`rounded-xl px-3 py-2 text-center text-xs font-semibold sm:flex-1 sm:px-4 sm:text-sm ${
                  active
                    ? "border border-veto-gold/50 bg-veto-gold/25 text-primary shadow-[0_0_14px_rgba(197,160,89,0.3)]"
                    : `${btnSecondaryGlass} border-transparent bg-transparent dark:bg-white/[0.03]`
                }`}
              >
                {tr(tab.labelKey)}
              </Link>
            );
          })}
        </nav>

        {loading ? (
          <div className="h-64 animate-pulse rounded-2xl border border-subtle bg-surface-sunken backdrop-blur-md" />
        ) : (
          children
        )}

        {!loading && (
          <div className="mt-2 flex flex-col gap-3 border-t border-subtle pt-6">
            {error && (
              <p
                className="font-heebo rounded-xl border border-red-500/30 bg-red-500/15 px-3 py-2 text-sm text-red-800 backdrop-blur-md dark:text-red-200"
                role="alert"
              >
                {error}
              </p>
            )}

            {message && (
              <p className="font-heebo rounded-xl border border-emerald-500/30 bg-emerald-500/15 px-3 py-2 text-sm text-emerald-900 backdrop-blur-md dark:text-emerald-200">
                {message}
              </p>
            )}

            {showSave ? (
              <Button
                variant="primary"
                size="lg"
                fullWidth
                onClick={() => void save()}
                loading={saving}
                className="font-heebo"
              >
                {saving ? tr("settings.saving") : tr("settings.saveChanges")}
              </Button>
            ) : null}

            <Button
              variant="ghost"
              size="lg"
              fullWidth
              onClick={handleLogout}
              className="font-heebo min-h-[44px] text-red-700 hover:bg-transparent hover:text-red-800 dark:text-red-300 dark:hover:text-red-200"
            >
              {tr("settings.logout")}
            </Button>
          </div>
        )}
      </main>

      {variant === "citizen" ? (
        <CitizenBottomNav active="settings" />
      ) : null}
    </>
  );
}

export function SettingsShell({
  children,
  variant = "citizen",
}: {
  children: React.ReactNode;
  variant?: "citizen" | "admin";
}) {
  return (
    <SettingsProvider>
      <SettingsChrome variant={variant}>{children}</SettingsChrome>
    </SettingsProvider>
  );
}
