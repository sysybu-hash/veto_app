/**
 * Variant class maps for the primitive components in
 * `src/components/ui/primitives/`. New variant work belongs here —
 * `vetoGlass.ts` receives no new exports (see its file header).
 */

export const buttonSize = {
  sm: "h-8 gap-1.5 rounded-sm px-3 text-xs",
  md: "h-10 gap-2 rounded-sm px-4 text-sm",
  lg: "h-12 gap-2.5 rounded-md px-6 text-base",
} as const;

export const buttonVariant = {
  primary:
    "bg-veto-gold font-bold text-on-brand shadow-brand-glow hover:-translate-y-0.5 hover:bg-veto-gold-light disabled:hover:translate-y-0",
  secondary:
    "border border-default bg-surface-raised-2 font-semibold text-primary shadow-sm hover:border-strong hover:bg-surface-overlay",
  ghost:
    "font-semibold text-primary hover:bg-hover-overlay active:bg-active-overlay",
  danger:
    "bg-danger font-bold text-danger-fg shadow-sm hover:brightness-110",
  brandSoft:
    "bg-brand-soft font-semibold text-brand-fg hover:bg-brand-soft-hover",
  link: "font-semibold text-link underline-offset-4 hover:underline",
} as const;

export type ButtonSize = keyof typeof buttonSize;
export type ButtonVariant = keyof typeof buttonVariant;

export const iconButtonSize = {
  sm: "h-8 w-8 rounded-sm",
  md: "h-10 w-10 rounded-sm",
  lg: "h-12 w-12 rounded-md",
} as const;

export const badgeVariant = {
  neutral: "bg-surface-sunken text-secondary border border-subtle",
  brand: "bg-brand-soft text-brand-fg border border-brand",
  success: "bg-success-soft text-success border border-success-border",
  warning: "bg-warning-soft text-warning border border-warning-border",
  danger: "bg-danger-soft text-danger border border-danger-border",
  info: "bg-info-soft text-info border border-info-border",
} as const;

export type BadgeVariant = keyof typeof badgeVariant;

export const cardVariant = {
  panel: "rounded-panel border border-subtle bg-surface-raised shadow-panel backdrop-blur-xl",
  nested: "rounded-lg border border-subtle bg-surface-raised-2 shadow-card backdrop-blur-xl",
  flat: "rounded-lg border border-subtle bg-surface-raised",
  interactive:
    "rounded-lg border border-subtle bg-surface-raised shadow-sm transition hover:border-default hover:shadow-card cursor-pointer",
} as const;

export type CardVariant = keyof typeof cardVariant;
