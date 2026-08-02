import { forwardRef } from "react";
import type { AnchorHTMLAttributes, ReactNode } from "react";
import { cn } from "@/lib/cn";
import { buttonSize, buttonVariant, type ButtonSize, type ButtonVariant } from "@/lib/variants";

export interface LinkButtonProps extends AnchorHTMLAttributes<HTMLAnchorElement> {
  variant?: ButtonVariant;
  size?: ButtonSize;
  iconStart?: ReactNode;
  iconEnd?: ReactNode;
  fullWidth?: boolean;
}

/**
 * LinkButton — same visual scale/variants as `Button`, for cases that must
 * be a real `<a>` (external links, downloads, open-in-new-tab) rather than
 * a `<button onClick>`. Keeps every such link visually identical to the
 * buttons around it instead of each call site hand-rolling its own
 * padding/size (the exact mismatch reported on the vault recording/
 * transcript links).
 */
export const LinkButton = forwardRef<HTMLAnchorElement, LinkButtonProps>(
  function LinkButton(
    {
      variant = "secondary",
      size = "md",
      fullWidth = false,
      iconStart,
      iconEnd,
      className,
      children,
      ...props
    },
    ref,
  ) {
    return (
      <a
        ref={ref}
        className={cn(
          "inline-flex items-center justify-center whitespace-nowrap font-heebo transition outline-none",
          "focus-visible:ring-2 focus-visible:ring-focus/60 focus-visible:ring-offset-2 focus-visible:ring-offset-surface-canvas",
          fullWidth && "w-full",
          buttonSize[size],
          buttonVariant[variant],
          className,
        )}
        {...props}
      >
        {iconStart}
        {children}
        {iconEnd}
      </a>
    );
  },
);
