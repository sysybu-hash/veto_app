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
      {/* Single `main` landmark for the whole citizen group. Pages must NOT
          render their own <main> — nesting landmarks is invalid, and without
          one here axe's `region` rule flags every page's content as living
          outside a landmark. */}
      <main className="flex min-w-0 flex-1 flex-col">{children}</main>
    </div>
  );
}
