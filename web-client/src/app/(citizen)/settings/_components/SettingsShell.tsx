"use client";



import Link from "next/link";

import { usePathname, useRouter, useSearchParams } from "next/navigation";

import { CitizenBottomNav } from "@/components/citizen/CitizenBottomNav";

import { clearJwt } from "@/lib/authToken";

import { useTranslation } from "@/lib/i18n/LocaleProvider";

import { disconnectSocket } from "@/lib/socketClient";

import { btnPrimaryGold, btnSecondaryGlass } from "@/lib/vetoGlass";

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



function SettingsChrome({ children }: { children: React.ReactNode }) {

  const pathname = usePathname();

  const searchParams = useSearchParams();

  const router = useRouter();

  const { t: tr } = useTranslation();

  const { loading, saving, message, error, save } = useSettings();

  const currentTab = searchParams.get("tab");

  const activeTabId = resolveActiveTabId(pathname, currentTab);

  const showSave =

    activeTabId === "profile" || activeTabId === "notifications";



  const handleLogout = () => {

    disconnectSocket();

    clearJwt();

    router.replace("/login");

  };



  return (

    <>

      <main className="mx-auto flex w-full max-w-lg flex-1 flex-col gap-6 px-4 py-8 pb-40">

        <div>

          <h1 className="font-frank text-2xl font-bold tracking-tight text-slate-900">

            {tr("settings.title")}

          </h1>

          <p className="font-heebo mt-1 text-sm text-slate-600">

            {tr("settings.shellSubtitle")}

          </p>

        </div>



        <nav

          className="flex flex-wrap gap-2 rounded-2xl border border-white/40 bg-white/35 p-2 backdrop-blur-md"

          aria-label="Settings sections"

        >

          {TABS.map((tab) => {

            const active = activeTabId === tab.tab;

            return (

              <Link

                key={tab.tab}

                href={`/settings?tab=${tab.tab}`}

                className={`rounded-xl px-3 py-2 text-center text-xs font-semibold sm:flex-1 sm:px-4 sm:text-sm ${

                  active

                    ? "border border-[#C5A059]/50 bg-[#C5A059]/25 text-slate-900 shadow-[0_0_14px_rgba(197,160,89,0.3)]"

                    : `${btnSecondaryGlass} border-transparent bg-white/30`

                }`}

              >

                {tr(tab.labelKey)}

              </Link>

            );

          })}

        </nav>



        {loading ? (

          <div className="h-64 animate-pulse rounded-2xl border border-white/35 bg-white/30 backdrop-blur-md" />

        ) : (

          children

        )}



        {!loading && (

          <div className="mt-2 flex flex-col gap-3 border-t border-white/35 pt-6">

            {error && (

              <p

                className="font-heebo rounded-xl border border-red-300/80 bg-red-100/45 px-3 py-2 text-sm text-red-900 backdrop-blur-md"

                role="alert"

              >

                {error}

              </p>

            )}

            {message && (

              <p className="font-heebo rounded-xl border border-emerald-300/80 bg-emerald-100/45 px-3 py-2 text-sm text-emerald-950 backdrop-blur-md">

                {message}

              </p>

            )}



            {showSave ? (

              <button

                type="button"

                onClick={() => void save()}

                disabled={saving}

                className={`font-heebo w-full py-3.5 text-sm ${btnPrimaryGold} disabled:opacity-60`}

              >

                {saving ? tr("settings.saving") : tr("settings.saveChanges")}

              </button>

            ) : null}



            <button

              type="button"

              onClick={handleLogout}

              className="font-heebo w-full py-3 text-center text-sm font-semibold text-red-800 transition hover:text-red-950"

            >

              {tr("settings.logout")}

            </button>

          </div>

        )}

      </main>

      <CitizenBottomNav active="settings" />

    </>

  );

}



export function SettingsShell({ children }: { children: React.ReactNode }) {

  return (

    <SettingsProvider>

      <SettingsChrome>{children}</SettingsChrome>

    </SettingsProvider>

  );

}

