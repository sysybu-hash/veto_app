"use client";

/**
 * View Transitions API integration for VETO (Phase 5).
 *
 * Browsers that support `document.startViewTransition` (Chromium-based,
 * Safari TP, soon Firefox) get smooth crossfade / shared-element
 * transitions when we navigate via the App Router. Other browsers fall
 * back to a normal client-side navigation — no behaviour change.
 *
 * Use:
 *   const router = useViewTransitionRouter();
 *   router.push("/dashboard");
 *
 * Or wrap an anchor:
 *   <ViewTransitionLink href="/hub">…</ViewTransitionLink>
 *
 * Animations are defined in `globals.css` under the
 * `::view-transition-old(root)` / `::view-transition-new(root)`
 * selectors so we don't ship any extra JS for the visual layer.
 */

import { useRouter } from "next/navigation";
import type { MouseEvent } from "react";

type StartViewTransition = (
  cb: () => void | Promise<void>,
) => { finished: Promise<void> };

/** Narrow without `extends Document` — DOM lib types `startViewTransition` as always present. */
type DocumentWithOptionalVT = Document & {
  startViewTransition?: StartViewTransition;
};

function asDocumentWithVt(doc: Document): DocumentWithOptionalVT {
  return doc as unknown as DocumentWithOptionalVT;
}

function supportsViewTransitions(): boolean {
  if (typeof document === "undefined") return false;
  return typeof asDocumentWithVt(document).startViewTransition === "function";
}

export function startViewTransition(cb: () => void | Promise<void>) {
  const doc = asDocumentWithVt(document);
  if (typeof doc.startViewTransition === "function") {
    return doc.startViewTransition(cb);
  }
  // Fallback: just run immediately so navigation is never blocked.
  void cb();
  return null;
}

export function useViewTransitionRouter() {
  const router = useRouter();

  return {
    push(url: string) {
      if (!supportsViewTransitions()) {
        router.push(url);
        return;
      }
      startViewTransition(() => {
        router.push(url);
      });
    },
    replace(url: string) {
      if (!supportsViewTransitions()) {
        router.replace(url);
        return;
      }
      startViewTransition(() => {
        router.replace(url);
      });
    },
    back() {
      if (!supportsViewTransitions()) {
        router.back();
        return;
      }
      startViewTransition(() => {
        router.back();
      });
    },
    refresh() {
      router.refresh();
    },
  };
}

/**
 * Returns an `onClick` handler that wraps the navigation to `href` in a
 * view transition. Use on plain anchors when you need the SEO benefits
 * of `<a>` (e.g. footer / nav links) but want the smooth animation.
 */
export function viewTransitionAnchorHandler(
  href: string,
  onAfter?: () => void,
) {
  return (e: MouseEvent<HTMLAnchorElement>) => {
    // Modifier-clicks should keep their native open-in-new-tab behavior.
    if (
      e.defaultPrevented ||
      e.button !== 0 ||
      e.metaKey ||
      e.ctrlKey ||
      e.shiftKey ||
      e.altKey
    ) {
      return;
    }
    e.preventDefault();
    if (!supportsViewTransitions()) {
      window.location.assign(href);
      return;
    }
    startViewTransition(() => {
      window.location.assign(href);
      onAfter?.();
    });
  };
}
