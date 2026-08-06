"use client";

import type { ReactNode } from "react";
import { glassPanelNested } from "@/lib/vetoGlass";

/**
 * EmptyState — consistent "nothing here yet" placeholder for routes
 * that return zero items. Phase 5 of the rewrite.
 *
 * Pattern:
 *   {items.length === 0 ? (
 *     <EmptyState
 *       title={t("vault.emptyTitle")}
 *       description={t("vault.emptyBody")}
 *       icon={<FolderLock className="h-6 w-6" />}
 *       action={<Link href="/vault/new">…</Link>}
 *     />
 *   ) : <List items={items} />}
 *
 * Accessible by default: the title/description sit in a role="status" live
 * region so screen readers announce "no results" when it appears. The `action`
 * is deliberately OUTSIDE that region — a live region is for advisory text, and
 * putting a focusable control in one makes assistive tech re-announce the
 * button on every update.
 */
export function EmptyState({
  title,
  description,
  icon,
  action,
  className = "",
}: {
  title: string;
  description?: string;
  icon?: ReactNode;
  action?: ReactNode;
  className?: string;
}) {
  return (
    <div
      className={`${glassPanelNested} flex flex-col items-center justify-center gap-3 px-6 py-10 text-center ${className}`}
    >
      <div
        role="status"
        aria-live="polite"
        className="flex flex-col items-center justify-center gap-3"
      >
        {icon && (
          <div
            className="flex h-12 w-12 items-center justify-center rounded-full bg-veto-gold/15 text-veto-gold-dark"
            aria-hidden
          >
            {icon}
          </div>
        )}
        <h3 className="font-frank text-base font-bold text-primary">
          {title}
        </h3>
        {description && (
          <p className="max-w-sm text-sm text-secondary">{description}</p>
        )}
      </div>
      {action && <div className="mt-2">{action}</div>}
    </div>
  );
}
