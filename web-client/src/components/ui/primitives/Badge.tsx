import type { HTMLAttributes, ReactNode } from "react";
import { cn } from "@/lib/cn";
import { badgeVariant, type BadgeVariant } from "@/lib/variants";

export interface BadgeProps extends HTMLAttributes<HTMLSpanElement> {
  variant?: BadgeVariant;
  children: ReactNode;
}

export function Badge({ variant = "neutral", className, children, ...props }: BadgeProps) {
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1 rounded-pill px-2.5 py-0.5 text-xs font-semibold",
        badgeVariant[variant],
        className,
      )}
      {...props}
    >
      {children}
    </span>
  );
}
