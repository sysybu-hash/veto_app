"use client";

import {
  FolderLock,
  LayoutDashboard,
  MessageCircle,
  type LucideIcon,
} from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";
import { useTranslation } from "@/lib/i18n/LocaleProvider";

type LinkDef = {
  href: string;
  icon: LucideIcon;
  label: string;
  match: (pathname: string) => boolean;
};

export function LawyerSidebar() {
  const pathname = usePathname();
  const { t } = useTranslation();

  const links: LinkDef[] = [
    {
      href: "/dashboard",
      icon: LayoutDashboard,
      label: t("nav.dashboard"),
      match: (p) => p === "/dashboard" || p.startsWith("/dashboard"),
    },
    {
      href: "/chat",
      icon: MessageCircle,
      label: t("nav.chat"),
      match: (p) => p === "/chat",
    },
    {
      href: "/vault",
      icon: FolderLock,
      label: t("nav.vault"),
      match: (p) => p.startsWith("/vault"),
    },
  ];

  return (
    <aside
      data-print="hide"
      className="hidden w-60 shrink-0 flex-col gap-6 border-e border-subtle bg-surface-raised/95 p-5 backdrop-blur-xl md:flex"
      aria-label={t("nav.mainAria")}
    >
      <div className="space-y-1">
        <Link href="/dashboard" className="inline-flex" aria-label="VETO">
          <VetoBrandLogo className="h-9 w-auto" />
        </Link>
        <p className="text-sm font-bold tracking-tight text-muted">
          {t("nav.roleLawyer")}
        </p>
      </div>
      <nav className="flex flex-1 flex-col gap-1.5">
        {links.map(({ href, icon: Icon, label, match }) => {
          const active = match(pathname);
          return (
            <Link
              key={href}
              href={href}
              className={`flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-bold transition ${
                active
                  ? "bg-veto-gold/15 text-brand-700 dark:text-brand-text"
                  : "text-primary hover:bg-hover-overlay"
              }`}
            >
              <Icon size={18} aria-hidden />
              {label}
            </Link>
          );
        })}
      </nav>
    </aside>
  );
}
