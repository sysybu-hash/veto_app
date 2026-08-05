"use client";

import type { HTMLAttributes, ReactNode, TdHTMLAttributes, ThHTMLAttributes } from "react";
import { cn } from "@/lib/cn";
import { Skeleton } from "@/components/ui/Skeleton";
import { EmptyState } from "@/components/ui/EmptyState";

export interface TableProps extends HTMLAttributes<HTMLTableElement> {
  caption?: string;
  dense?: boolean;
  loading?: boolean;
  loadingRows?: number;
  empty?: ReactNode;
  isEmpty?: boolean;
  children: ReactNode;
}

export function Table({
  caption,
  dense,
  loading,
  loadingRows = 4,
  empty,
  isEmpty,
  className,
  children,
  ...props
}: TableProps) {
  if (isEmpty && !loading) {
    return empty ?? <EmptyState title="אין נתונים להצגה" />;
  }

  // Focusable scroll region: a container that scrolls only by swipe or wheel is
  // unreachable by keyboard (WCAG 2.1.1 / EN 301 549 9.2.1.1). axe only flags it
  // once the content actually overflows, so this is easy to miss with small
  // fixtures — keep the tabIndex regardless of data size.
  return (
    <div
      className="overflow-x-auto rounded-lg border border-subtle"
      tabIndex={0}
      role="region"
      aria-label={caption ?? "טבלה"}
    >
      <table
        className={cn("w-full border-collapse text-sm", dense ? "leading-tight" : "leading-normal", className)}
        {...props}
      >
        {caption && <caption className="sr-only">{caption}</caption>}
        {children}
        {loading && (
          <tbody>
            {Array.from({ length: loadingRows }).map((_, i) => (
              <tr key={i}>
                <td colSpan={100} className="p-3">
                  <Skeleton height={16} />
                </td>
              </tr>
            ))}
          </tbody>
        )}
      </table>
    </div>
  );
}

Table.Head = function THead({ className, sticky, children, ...props }: HTMLAttributes<HTMLTableSectionElement> & { sticky?: boolean }) {
  return (
    <thead className={cn("bg-surface-sunken text-xs font-semibold text-secondary", sticky && "sticky top-0 z-10", className)} {...props}>
      {children}
    </thead>
  );
};

Table.Row = function TR({ className, children, ...props }: HTMLAttributes<HTMLTableRowElement>) {
  return (
    <tr className={cn("border-b border-subtle last:border-0", className)} {...props}>
      {children}
    </tr>
  );
};

Table.HeaderCell = function TH({ className, children, ...props }: ThHTMLAttributes<HTMLTableCellElement>) {
  return (
    <th scope="col" className={cn("px-3 py-2.5 text-start font-semibold", className)} {...props}>
      {children}
    </th>
  );
};

Table.Cell = function TD({ className, children, ...props }: TdHTMLAttributes<HTMLTableCellElement>) {
  return (
    <td className={cn("px-3 py-2.5 text-primary", className)} {...props}>
      {children}
    </td>
  );
};
