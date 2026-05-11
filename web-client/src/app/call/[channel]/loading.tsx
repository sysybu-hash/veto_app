import { Skeleton } from "@/components/ui/Skeleton";

/** Call UI is always dark (`veto-call-keep-dark`); match shell so transition is not a flash of light. */
export default function CallChannelLoading() {
  return (
    <div
      className="veto-call-keep-dark flex min-h-[100dvh] w-full flex-col bg-gradient-to-b from-zinc-950 via-black to-zinc-950 px-4 py-8"
      aria-busy="true"
      aria-label="טוען שיחה"
    >
      <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-4">
        <div className="flex items-center justify-between gap-3">
          <Skeleton className="h-9 w-28 rounded-lg bg-white/10" />
          <Skeleton className="h-9 flex-1 max-w-md rounded-lg bg-white/10" />
        </div>
        <div className="flex flex-1 flex-col items-center justify-center gap-4 py-12">
          <Skeleton className="aspect-video w-full max-w-3xl rounded-2xl bg-white/10" />
          <div className="flex gap-3">
            <Skeleton className="h-12 w-12 rounded-full bg-white/10" />
            <Skeleton className="h-12 w-12 rounded-full bg-white/10" />
            <Skeleton className="h-12 w-12 rounded-full bg-white/10" />
          </div>
        </div>
      </div>
    </div>
  );
}
