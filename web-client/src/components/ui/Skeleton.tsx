"use client";

import type { CSSProperties } from "react";

/**
 * Skeleton — generic shimmer block used by `loading.tsx` files
 * across the app. Phase 5 of the rewrite.
 *
 * - Honours `prefers-reduced-motion` automatically (animation is
 *   driven by the `animate-pulse` Tailwind utility).
 * - Inherits border radius from parent if not overridden.
 * - Theme-aware: in dark mode it uses a subtle white tint; in light
 *   mode the slate-200 base shows through.
 */
export function Skeleton({
  className = "",
  width,
  height,
  rounded = "md",
  style,
}: {
  className?: string;
  width?: number | string;
  height?: number | string;
  rounded?: "none" | "sm" | "md" | "lg" | "xl" | "2xl" | "full";
  style?: CSSProperties;
}) {
  const r =
    rounded === "none"
      ? ""
      : rounded === "full"
        ? "rounded-full"
        : `rounded-${rounded}`;
  return (
    <div
      aria-hidden
      className={`animate-pulse bg-slate-200/70 ${r} ${className}`}
      style={{
        width,
        height,
        ...style,
      }}
    />
  );
}

/**
 * SkeletonText — an array of pulsing lines for paragraph / list copy.
 */
export function SkeletonText({
  lines = 3,
  className = "",
}: {
  lines?: number;
  className?: string;
}) {
  return (
    <div className={`flex flex-col gap-2 ${className}`} aria-hidden>
      {Array.from({ length: lines }).map((_, i) => (
        <div
          key={i}
          className="h-3 animate-pulse rounded-md bg-slate-200/70"
          style={{ width: `${100 - i * 10}%` }}
        />
      ))}
    </div>
  );
}

/**
 * SkeletonCard — composes a card with header line + body + 2 chips.
 */
export function SkeletonCard({ className = "" }: { className?: string }) {
  return (
    <div
      className={`rounded-2xl border border-slate-200/80 bg-white/85 p-4 backdrop-blur-xl ${className}`}
      aria-hidden
    >
      <div className="mb-3 h-4 w-1/2 animate-pulse rounded-md bg-slate-200/70" />
      <SkeletonText lines={3} />
      <div className="mt-3 flex gap-2">
        <div className="h-6 w-16 animate-pulse rounded-full bg-slate-200/70" />
        <div className="h-6 w-20 animate-pulse rounded-full bg-slate-200/70" />
      </div>
    </div>
  );
}
