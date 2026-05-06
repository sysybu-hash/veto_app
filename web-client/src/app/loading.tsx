import { glassPanel } from "@/lib/vetoGlass";

export default function RootLoading() {
  return (
    <div
      className="flex min-h-[40vh] w-full flex-col items-center justify-center px-4 py-20"
      aria-busy="true"
      aria-label="טוען"
      dir="rtl"
    >
      <div className="w-full max-w-sm space-y-4 text-center">
        <p className="font-frank text-lg font-black tracking-tight text-slate-900">
          VETO
        </p>
        <div
          className={`flex flex-col gap-4 p-6 shadow-lg shadow-slate-900/10 ${glassPanel}`}
        >
          <div className="flex animate-pulse flex-col gap-3 text-start">
            <div className="h-3 w-3/4 rounded-lg bg-white/40" />
            <div className="h-24 rounded-2xl bg-white/35" />
            <div className="h-14 rounded-2xl bg-white/30" />
          </div>
        </div>
      </div>
    </div>
  );
}
