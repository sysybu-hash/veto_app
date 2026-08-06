import type { ReactNode } from "react";
import { RoleAwareAppChrome } from "@/components/layout/RoleAwareAppChrome";

export default function VaultLayout({ children }: { children: ReactNode }) {
  return <RoleAwareAppChrome>{children}</RoleAwareAppChrome>;
}
