import type { ReactNode } from "react";
import { CitizenSidebar } from "@/components/citizen/CitizenSidebar";

export default function CitizenLayout({
  children,
}: Readonly<{
  children: ReactNode;
}>) {
  return (
    <div className="flex min-h-full flex-col text-primary md:flex-row">
      <CitizenSidebar />
      <div className="flex min-w-0 flex-1 flex-col">{children}</div>
    </div>
  );
}
