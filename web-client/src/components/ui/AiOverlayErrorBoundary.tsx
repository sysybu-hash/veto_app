"use client";

import { Component, type ErrorInfo, type ReactNode } from "react";

type Props = { children: ReactNode };
type State = { hasError: boolean };

/**
 * Isolates GlobalAiOverlay so a render/runtime error there never tears down the shell.
 */
export class AiOverlayErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(): State {
    return { hasError: true };
  }

  override componentDidCatch(error: Error, info: ErrorInfo): void {
    console.error("[VETO AI] overlay error:", error, info.componentStack);
  }

  override render(): ReactNode {
    if (this.state.hasError) {
      if (process.env.NODE_ENV === "development") {
        return (
          <p
            className="pointer-events-auto fixed bottom-4 end-4 z-[60] max-w-sm rounded-lg border border-amber-500/50 bg-amber-950/90 px-3 py-2 text-xs text-amber-100 shadow-lg"
            role="status"
          >
            AI overlay crashed (dev only). Check the console. Reload the page to retry.
          </p>
        );
      }
      return null;
    }
    return this.props.children;
  }
}
