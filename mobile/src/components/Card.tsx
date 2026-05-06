import type { ReactNode } from "react";
import { View } from "react-native";

export type CardProps = {
  children: ReactNode;
  className?: string;
};

export function Card({ children, className = "" }: CardProps) {
  return (
    <View
      className={`rounded-2xl border border-slate-100 bg-white p-4 shadow-sm shadow-slate-900/10 ${className}`}
    >
      {children}
    </View>
  );
}
