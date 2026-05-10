export default function LawyerLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <div className="flex min-h-full flex-col text-slate-950">
      <div className="flex flex-1 flex-col">{children}</div>
    </div>
  );
}
