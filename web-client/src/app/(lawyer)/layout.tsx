export default function LawyerLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <div className="min-h-full flex flex-col bg-slate-50 text-slate-900">
      <div className="flex flex-1 flex-col">{children}</div>
    </div>
  );
}
