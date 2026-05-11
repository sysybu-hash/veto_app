import { CallShellNoSsr } from "./_v2/CallShellNoSsr";

/**
 * Phase 3 — the v2 call surface (`agora-rtc-sdk-ng` + AI Denoiser + Virtual
 * Background + E2EE + Real-Time Transcription) is now the default. The
 * legacy `agora-rtc-react` surface has been removed in favour of the
 * direct SDK integration in `_v2/`.
 *
 * To temporarily disable the v2 room (e.g. during incident response),
 * set `NEXT_PUBLIC_CALL_V2=0`. There is no longer a fallback room — the
 * page renders a minimal "video calls disabled" notice instead.
 */
export default async function CallPage({
  params,
}: {
  params: Promise<{ channel: string }>;
}) {
  const { channel: raw } = await params;
  const channel = decodeURIComponent(raw);

  const v2Flag = process.env.NEXT_PUBLIC_CALL_V2;
  const disabled = v2Flag === "0" || v2Flag === "false";

  if (disabled) {
    return (
      <div className="veto-call-keep-dark fixed inset-0 z-[70] flex h-[100dvh] w-screen flex-col items-center justify-center gap-3 bg-black px-6 text-center text-slate-200">
        <p className="text-base font-bold">Video calls are temporarily disabled.</p>
        <p className="max-w-md text-xs text-slate-400">
          Operators have set NEXT_PUBLIC_CALL_V2=0. Re-enable the call surface
          by clearing the flag and redeploying.
        </p>
      </div>
    );
  }

  return <CallShellNoSsr channel={channel} />;
}
