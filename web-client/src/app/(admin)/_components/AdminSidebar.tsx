"use client";

import {
  Database,
  FileText,
  LayoutDashboard,
  Scale,
  Settings,
  type LucideIcon,
} from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";

const LINKS: Array<{ href: string; icon: LucideIcon; label: string }> = [
  { href: "/admin/dashboard", icon: LayoutDashboard, label: "מרכז שליטה" },
  { href: "/admin/lawyers", icon: Scale, label: "ניהול עורכי דין" },
  { href: "/admin/vault", icon: Database, label: "ניהול כספת" },
  { href: "/vault/generator", icon: FileText, label: "מחולל מסמכים AI" },
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
          const active = pathname === href;
          return (
            <Link
              key={href}
              href={href}
              className={`flex items-center gap-3 rounded-lg p-3 text-sm font-medium transition ${
                active
                  ? "bg-veto-gold/10 text-veto-gold"
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
