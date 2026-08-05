import type { ReactNode } from "react";
import { RoleAwareAppChrome } from "@/components/layout/RoleAwareAppChrome";

export default function ChatLayout({ children }: { children: ReactNode }) {
  return <RoleAwareAppChrome>{children}</RoleAwareAppChrome>;
}
