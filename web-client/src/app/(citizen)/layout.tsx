import type { ReactNode } from "react";

export default function CitizenLayout({
  children,
}: Readonly<{
  children: ReactNode;
}>) {
  return (
    <div className="flex min-h-full flex-col text-primary">
      <div className="flex flex-1 flex-col">{children}</div>
    </div>
  );
}
