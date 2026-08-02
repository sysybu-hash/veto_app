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
      <div className="flex-1">{children}</div>
    </div>
  );
}
