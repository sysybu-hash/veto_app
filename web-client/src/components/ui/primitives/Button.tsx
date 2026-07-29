"use client";

import { forwardRef } from "react";
import type { ButtonHTMLAttributes, ReactNode } from "react";
import { Loader2 } from "lucide-react";
import { cn } from "@/lib/cn";
import { buttonSize, buttonVariant, type ButtonSize, type ButtonVariant } from "@/lib/variants";

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant;
  size?: ButtonSize;
  loading?: boolean;
  iconStart?: ReactNode;
  iconEnd?: ReactNode;
  fullWidth?: boolean;
}

/**
 * Button — primary interactive control. Visually equivalent to the
 * legacy `btnPrimaryGold`/`btnSecondaryGlass` vetoGlass strings, so it
 * can be mixed with raw `<button className={btnPrimaryGold}>` call
 * sites during the route-by-route migration (Phase 3).
 */
export const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  {
    variant = "primary",
    size = "md",
    loading = false,
    fullWidth = false,
    iconStart,
    iconEnd,
    disabled,
    className,
    children,
    ...props
  },
  ref,
) {
  const isDisabled = disabled || loading;
  return (
    <button
      ref={ref}
      type={props.type ?? "button"}
      disabled={isDisabled}
      aria-busy={loading || undefined}
      className={cn(
        "inline-flex items-center justify-center whitespace-nowrap font-heebo transition outline-none",
        "focus-visible:ring-2 focus-visible:ring-focus/60 focus-visible:ring-offset-2 focus-visible:ring-offset-surface-canvas",
        "disabled:cursor-not-allowed disabled:opacity-50 disabled:hover:translate-y-0",
        fullWidth && "w-full",
        buttonSize[size],
        buttonVariant[variant],
        className,
      )}
      {...props}
    >
      {loading ? (
        <Loader2 className="h-4 w-4 animate-spin" aria-hidden />
      ) : (
        iconStart
      )}
      {children}
      {!loading && iconEnd}
    </button>
  );
});
