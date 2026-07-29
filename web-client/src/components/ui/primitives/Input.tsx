"use client";

import { forwardRef } from "react";
import type { InputHTMLAttributes, TextareaHTMLAttributes, SelectHTMLAttributes, ReactNode } from "react";
import { cn } from "@/lib/cn";

const fieldBase =
  "w-full rounded-md border border-default bg-surface-overlay px-3 py-2.5 text-sm font-semibold text-primary outline-none transition placeholder:text-muted focus:border-veto-gold/70 focus:ring-2 focus:ring-veto-gold/25 focus-visible:ring-2 focus-visible:ring-veto-gold/40 disabled:cursor-not-allowed disabled:opacity-50 aria-[invalid=true]:border-danger aria-[invalid=true]:focus:ring-danger/25";

const fieldSize = {
  sm: "h-8 px-2.5 py-1.5 text-xs",
  md: "h-10 px-3 py-2.5 text-sm",
  lg: "h-12 px-4 py-3 text-base",
} as const;

export interface InputProps extends Omit<InputHTMLAttributes<HTMLInputElement>, "size"> {
  size?: keyof typeof fieldSize;
  invalid?: boolean;
}

export const Input = forwardRef<HTMLInputElement, InputProps>(function Input(
  { size = "md", invalid, className, ...props },
  ref,
) {
  return (
    <input
      ref={ref}
      aria-invalid={invalid || props["aria-invalid"]}
      className={cn(fieldBase, fieldSize[size], className)}
      {...props}
    />
  );
});

export interface TextareaProps extends TextareaHTMLAttributes<HTMLTextAreaElement> {
  invalid?: boolean;
}

export const Textarea = forwardRef<HTMLTextAreaElement, TextareaProps>(function Textarea(
  { invalid, className, rows = 4, ...props },
  ref,
) {
  return (
    <textarea
      ref={ref}
      rows={rows}
      aria-invalid={invalid || props["aria-invalid"]}
      className={cn(fieldBase, "h-auto resize-y py-2.5", className)}
      {...props}
    />
  );
});

export interface SelectProps extends Omit<SelectHTMLAttributes<HTMLSelectElement>, "size"> {
  size?: keyof typeof fieldSize;
  invalid?: boolean;
  children: ReactNode;
}

export const Select = forwardRef<HTMLSelectElement, SelectProps>(function Select(
  { size = "md", invalid, className, children, ...props },
  ref,
) {
  return (
    <select
      ref={ref}
      aria-invalid={invalid || props["aria-invalid"]}
      className={cn(fieldBase, fieldSize[size], "appearance-none bg-[position:left_0.75rem_center] rtl:bg-[position:right_0.75rem_center]", className)}
      {...props}
    >
      {children}
    </select>
  );
});
