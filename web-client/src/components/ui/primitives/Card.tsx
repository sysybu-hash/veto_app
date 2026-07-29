"use client";

import type { HTMLAttributes, ReactNode } from "react";
import { cn } from "@/lib/cn";
import { cardVariant, type CardVariant } from "@/lib/variants";

export interface CardProps extends HTMLAttributes<HTMLDivElement> {
  variant?: CardVariant;
  children: ReactNode;
}

export function Card({ variant = "panel", className, children, ...props }: CardProps) {
  return (
    <div className={cn(cardVariant[variant], "text-primary", className)} {...props}>
      {children}
    </div>
  );
}

Card.Header = function CardHeader({ className, children, ...props }: HTMLAttributes<HTMLDivElement>) {
  return (
    <div className={cn("border-b border-subtle px-5 py-4", className)} {...props}>
      {children}
    </div>
  );
};

Card.Body = function CardBody({ className, children, ...props }: HTMLAttributes<HTMLDivElement>) {
  return (
    <div className={cn("px-5 py-4", className)} {...props}>
      {children}
    </div>
  );
};

Card.Footer = function CardFooter({ className, children, ...props }: HTMLAttributes<HTMLDivElement>) {
  return (
    <div className={cn("border-t border-subtle px-5 py-4", className)} {...props}>
      {children}
    </div>
  );
};
