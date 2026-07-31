export default function AdminLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <div className="flex min-h-full flex-col bg-surface-canvas text-primary antialiased">
      {children}
    </div>
  );
}
