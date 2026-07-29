"use client";

import { useId } from "react";
import type { ReactNode } from "react";
import { cn } from "@/lib/cn";

export interface FieldProps {
  label: string;
  hint?: string;
  error?: string;
  required?: boolean;
  className?: string;
  children: (ids: { inputId: string; describedBy: string | undefined }) => ReactNode;
}

/**
 * Field — label/hint/error wrapper that owns id wiring so every form
 * control gets `aria-invalid` + `aria-describedby` for free.
 *
 * Usage:
 *   <Field label="שם מלא" error={errors.name}>
 *     {({ inputId, describedBy }) => (
 *       <Input id={inputId} aria-describedby={describedBy} aria-invalid={!!errors.name} />
 *     )}
 *   </Field>
 */
export function Field({ label, hint, error, required, className, children }: FieldProps) {
  const inputId = useId();
  const hintId = hint ? `${inputId}-hint` : undefined;
  const errorId = error ? `${inputId}-error` : undefined;
  const describedBy = [hintId, errorId].filter(Boolean).join(" ") || undefined;

  return (
    <div className={cn("flex flex-col gap-1.5", className)}>
      <label htmlFor={inputId} className="text-sm font-semibold text-secondary">
        {label}
        {required && (
          <span className="text-danger" aria-hidden>
            {" "}
            *
          </span>
        )}
      </label>
      {children({ inputId, describedBy })}
      {hint && !error && (
        <p id={hintId} className="text-xs text-muted">
          {hint}
        </p>
      )}
      {error && (
        <p id={errorId} role="alert" className="text-xs font-medium text-danger">
          {error}
        </p>
      )}
    </div>
  );
}
