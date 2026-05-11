export default function AdminLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <div className="veto-admin-keep-dark flex min-h-full flex-col bg-veto-canvas text-slate-950 antialiased">
      {children}
    </div>
  );
}
