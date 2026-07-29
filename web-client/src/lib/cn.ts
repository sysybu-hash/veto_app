/**
 * Tiny class-name joiner — filters falsy values, no dependency on
 * clsx/tailwind-merge (matches the repo's zero-dep styling posture).
 */
export function cn(...classes: Array<string | false | null | undefined>): string {
  return classes.filter(Boolean).join(" ");
}
