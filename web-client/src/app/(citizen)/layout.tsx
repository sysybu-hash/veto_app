export default function CitizenLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <div className="flex min-h-full flex-col text-slate-900">
      <header className="shrink-0 border-b border-white/40 bg-white/55 px-4 py-3 backdrop-blur-xl">
        <div className="mx-auto flex max-w-lg items-center justify-between">
          <span className="font-frank text-sm font-bold tracking-tight text-slate-900">
            VETO
          </span>
          <span className="text-xs font-medium text-slate-600">Citizen</span>
        </div>
      </header>
      <div className="flex flex-1 flex-col">{children}</div>
    </div>
  );
}
