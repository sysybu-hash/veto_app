"use client";

import {
  CalendarDays,
  FolderLock,
  Home,
  MessageCircle,
  Settings,
  type LucideIcon,
} from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";
import { useTranslation } from "@/lib/i18n/LocaleProvider";

type LinkDef = {
  href: string;
  icon: LucideIcon;
  labelKey: string;
  match: (pathname: string) => boolean;
};

const LINKS: LinkDef[] = [
  { href: "/hub", icon: Home, labelKey: "navCitizen.home", match: (p) => p === "/hub" },
  {
    href: "/chat",
    icon: MessageCircle,
    labelKey: "navCitizen.chat",
    match: (p) => p === "/chat",
  },
  {
    href: "/vault",
    icon: FolderLock,
    labelKey: "navCitizen.vault",
    match: (p) => p.startsWith("/vault"),
  },
  {
    href: "/calendar",
    icon: CalendarDays,
    labelKey: "navCitizen.calendar",
    match: (p) => p === "/calendar",
  },
  {
    href: "/settings",
    icon: Settings,
    labelKey: "navCitizen.settings",
    match: (p) => p.startsWith("/settings"),
  },
];

export function CitizenSidebar() {
  const pathname = usePathname();
  const { t } = useTranslation();

  if (pathname.startsWith("/onboarding")) {
    return null;
  }

  return (
    <aside
      data-print="hide"
      className="hidden w-60 shrink-0 flex-col gap-6 border-e border-subtle bg-surface-raised/95 p-5 backdrop-blur-xl md:flex"
      aria-label={t("nav.mainAria")}
    >
      <div className="space-y-1">
        <Link href="/hub" className="inline-flex" aria-label="VETO">
          <VetoBrandLogo className="h-9 w-auto" />
        </Link>
        <p className="text-sm font-bold tracking-tight text-muted">
          {t("citizenLayout.subtitle")}
        </p>
      </div>
      <nav className="flex flex-1 flex-col gap-1.5">
        {LINKS.map(({ href, icon: Icon, labelKey, match }) => {
          const active = match(pathname);
          return (
            <Link
              key={href}
              href={href}
              className={`flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-bold transition ${
                active
                  ? "bg-veto-gold/15 text-brand-700 dark:text-veto-gold"
                  : "text-primary hover:bg-hover-overlay"
              }`}
            >
              <Icon size={18} aria-hidden />
              {t(labelKey)}
            </Link>
          );
        })}
      </nav>
    </aside>
  );
}
