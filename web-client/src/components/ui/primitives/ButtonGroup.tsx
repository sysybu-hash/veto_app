import type { HTMLAttributes, ReactNode } from "react";
import { cn } from "@/lib/cn";

export interface ButtonGroupProps extends HTMLAttributes<HTMLDivElement> {
  children: ReactNode;
}

/** Segmented row of actions (e.g. the document generator's export row). */
export function ButtonGroup({ className, children, ...props }: ButtonGroupProps) {
  return (
    <div
      role="group"
      className={cn(
        "inline-flex overflow-hidden rounded-sm border border-default",
        "[&>button]:rounded-none [&>button]:border-0 [&>button:not(:last-child)]:border-e [&>button:not(:last-child)]:border-default",
        className,
      )}
      {...props}
    >
      {children}
    </div>
  );
}
