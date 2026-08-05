"use client";

import { MotionConfig } from "framer-motion";
import type { ReactNode } from "react";

/**
 * Makes every Framer Motion animation in the app honour the OS "reduce motion"
 * setting. `reducedMotion="user"` skips transform/layout animations (the ones
 * that trigger vestibular symptoms) while still allowing opacity fades, so
 * content that reveals on scroll never gets stranded invisible.
 *
 * The CSS-side counterpart lives in globals.css under
 * `@media (prefers-reduced-motion: reduce)`.
 */
export function MotionPreferences({ children }: { children: ReactNode }) {
  return <MotionConfig reducedMotion="user">{children}</MotionConfig>;
}
