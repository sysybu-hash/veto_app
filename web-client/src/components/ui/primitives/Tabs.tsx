"use client";

import { useRef } from "react";
import type { ReactNode } from "react";
import { cn } from "@/lib/cn";

export interface TabItem {
  value: string;
  label: string;
  content: ReactNode;
}

export interface TabsProps {
  items: TabItem[];
  value: string;
  onChange: (value: string) => void;
  className?: string;
}

/**
 * Tabs — roving tabindex, arrow-key navigation that respects the
 * ambient `dir` (RTL flips Left/Right automatically via `matches`).
 */
export function Tabs({ items, value, onChange, className }: TabsProps) {
  const listRef = useRef<HTMLDivElement>(null);

  function onKeyDown(e: React.KeyboardEvent) {
    const idx = items.findIndex((i) => i.value === value);
    const dir = getComputedStyle(e.currentTarget).direction;
    const next = dir === "rtl" ? "ArrowLeft" : "ArrowRight";
    const prev = dir === "rtl" ? "ArrowRight" : "ArrowLeft";
    if (e.key === next) {
      e.preventDefault();
      onChange(items[(idx + 1) % items.length].value);
    } else if (e.key === prev) {
      e.preventDefault();
      onChange(items[(idx - 1 + items.length) % items.length].value);
    }
  }

  const active = items.find((i) => i.value === value);

  return (
    <div className={className}>
      <div
        ref={listRef}
        role="tablist"
        onKeyDown={onKeyDown}
        className="flex gap-1 border-b border-subtle"
      >
        {items.map((item) => {
          const selected = item.value === value;
          return (
            <button
              key={item.value}
              type="button"
              role="tab"
              aria-selected={selected}
              tabIndex={selected ? 0 : -1}
              onClick={() => onChange(item.value)}
              className={cn(
                "border-b-2 px-4 py-2.5 text-sm font-semibold outline-none transition",
                "focus-visible:ring-2 focus-visible:ring-focus/60 focus-visible:ring-offset-2 focus-visible:ring-offset-surface-canvas",
                selected
                  ? "border-veto-gold text-primary"
                  : "border-transparent text-muted hover:text-secondary",
              )}
            >
              {item.label}
            </button>
          );
        })}
      </div>
      <div role="tabpanel" className="pt-4">
        {active?.content}
      </div>
    </div>
  );
}
