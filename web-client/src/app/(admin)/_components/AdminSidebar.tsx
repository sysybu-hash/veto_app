"use client";

import {
  LayoutDashboard,
  Scale,
  Settings,
  Wallet,
  type LucideIcon,
} from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";

const LINKS: Array<{ href: string; icon: LucideIcon; label: string }> = [
  { href: "/admin/dashboard", icon: LayoutDashboard, label: "מרכז שליטה" },
  { href: "/admin/lawyers", icon: Scale, label: "ניהול עורכי דין" },
  { href: "/admin/finance", icon: Wallet, label: "כספים ודוחות" },
  { href: "/admin/settings", icon: Settings, label: "הגדרות מערכת" },
];

export function AdminSidebar() {
  const pathname = usePathname();

  return (
    <aside className="flex w-full flex-col gap-8 border-l border-subtle bg-surface-raised/90 p-6 backdrop-blur-xl print:hidden md:w-64">
      <div className="space-y-2">
        <VetoBrandLogo className="h-9 w-auto" />
        <p className="font-serif text-sm font-bold tracking-tight text-muted">ממשק מנהל</p>
      </div>
      <nav className="flex flex-col gap-2">
        {LINKS.map(({ href, icon: Icon, label }) => {
          const active =
            pathname === href ||
            (href !== "/admin/dashboard" && pathname.startsWith(href));
          return (
            <Link
              key={href}
              href={href}
              className={`flex items-center gap-3 rounded-lg p-3 text-sm font-medium transition ${
                active
                  ? "bg-veto-gold/10 text-brand-text"
                  : "text-muted hover:bg-hover-overlay"
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
