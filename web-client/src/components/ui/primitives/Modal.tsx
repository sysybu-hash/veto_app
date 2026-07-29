"use client";

import { useEffect, useRef } from "react";
import type { ReactNode } from "react";
import { X } from "lucide-react";
import { cn } from "@/lib/cn";
import { IconButton } from "./IconButton";

export interface ModalProps {
  open: boolean;
  onClose: () => void;
  title: string;
  children: ReactNode;
  footer?: ReactNode;
  className?: string;
}

/**
 * Modal — built on the native `<dialog>` element: focus trap, Esc
 * handling, and inert background come from the browser for free.
 */
export function Modal({ open, onClose, title, children, footer, className }: ModalProps) {
  const ref = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    if (open && !el.open) el.showModal();
    if (!open && el.open) el.close();
  }, [open]);

  return (
    <dialog
      ref={ref}
      onClose={onClose}
      onCancel={onClose}
      onClick={(e) => {
        if (e.target === ref.current) onClose();
      }}
      aria-labelledby="modal-title"
      className={cn(
        "m-auto w-full max-w-lg rounded-panel border border-subtle bg-surface-raised p-0 text-primary shadow-modal backdrop:bg-surface-scrim backdrop:backdrop-blur-sm",
        className,
      )}
    >
      <div className="flex items-center justify-between border-b border-subtle px-5 py-4">
        <h2 id="modal-title" className="font-frank text-base font-bold">
          {title}
        </h2>
        <IconButton label="סגור" icon={<X className="h-4 w-4" />} size="sm" onClick={onClose} />
      </div>
      <div className="px-5 py-4">{children}</div>
      {footer && <div className="flex justify-end gap-2 border-t border-subtle px-5 py-4">{footer}</div>}
    </dialog>
  );
}
