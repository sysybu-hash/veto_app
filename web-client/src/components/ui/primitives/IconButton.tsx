"use client";

import { forwardRef } from "react";
import type { ButtonHTMLAttributes, ReactNode } from "react";
import { Loader2 } from "lucide-react";
import { cn } from "@/lib/cn";
import { buttonVariant, iconButtonSize, type ButtonSize, type ButtonVariant } from "@/lib/variants";

export interface IconButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  /** Required — becomes `aria-label` + `title`. Structurally prevents unlabeled icon buttons. */
  label: string;
  icon: ReactNode;
  variant?: ButtonVariant;
  size?: ButtonSize;
  loading?: boolean;
}

export const IconButton = forwardRef<HTMLButtonElement, IconButtonProps>(function IconButton(
  { label, icon, variant = "ghost", size = "md", loading = false, disabled, className, ...props },
  ref,
) {
  const isDisabled = disabled || loading;
  return (
    <button
      ref={ref}
      type={props.type ?? "button"}
      disabled={isDisabled}
      aria-label={label}
      title={label}
      aria-busy={loading || undefined}
      className={cn(
        "inline-flex shrink-0 items-center justify-center transition outline-none",
        "focus-visible:ring-2 focus-visible:ring-focus/60 focus-visible:ring-offset-2 focus-visible:ring-offset-surface-canvas",
        "disabled:cursor-not-allowed disabled:opacity-50",
        iconButtonSize[size],
        buttonVariant[variant],
        className,
      )}
      {...props}
    >
      {loading ? <Loader2 className="h-4 w-4 animate-spin" aria-hidden /> : icon}
    </button>
  );
});
