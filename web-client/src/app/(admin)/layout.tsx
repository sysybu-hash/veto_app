import { AdminSidebar } from "./_components/AdminSidebar";

export default function AdminLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <div
      className="flex min-h-full flex-col bg-surface-canvas text-primary antialiased md:flex-row"
      dir="rtl"
    >
      <AdminSidebar />
      {/* `main` landmark for the whole admin group — no admin page renders its
          own, so every route here gets exactly one. Without it axe's `region`
          rule flags all page content as sitting outside a landmark, which is
          what screen-reader users navigate by. */}
      <main className="flex-1">{children}</main>
    </div>
  );
}
