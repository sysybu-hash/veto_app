import Link from "next/link";

export default function Home() {
  return (
    <div className="flex min-h-full flex-1 flex-col items-center justify-center gap-6 bg-gradient-to-b from-slate-950 to-slate-900 px-6 py-16 text-center">
      <h1 className="text-3xl font-semibold text-white">VETO Web</h1>
      <p className="max-w-md text-sm text-slate-400">
        Citizen SOS flow over Socket.io and Agora video. Sign in, open the hub,
        and use SOS to request a lawyer.
      </p>
      <div className="flex flex-col gap-3 sm:flex-row">
        <Link
          href="/login"
          className="rounded-xl bg-white px-5 py-2.5 text-sm font-semibold text-slate-900 hover:bg-slate-100"
        >
          Sign in
        </Link>
        <Link
          href="/hub"
          className="rounded-xl border border-white/20 px-5 py-2.5 text-sm font-semibold text-white hover:bg-white/5"
        >
          Citizen hub
        </Link>
        <Link
          href="/dashboard"
          className="rounded-xl border border-white/20 px-5 py-2.5 text-sm font-semibold text-white hover:bg-white/5"
        >
          Lawyer dashboard
        </Link>
      </div>
    </div>
  );
}
