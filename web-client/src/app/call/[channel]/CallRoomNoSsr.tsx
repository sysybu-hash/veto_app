"use client";

import dynamic from "next/dynamic";

const CallRoom = dynamic(() => import("./CallRoom"), {
  ssr: false,
  loading: () => (
    <div className="flex min-h-full items-center justify-center bg-black px-6 text-center text-sm font-bold text-slate-200">
      מכין את חדר השיחה...
    </div>
  ),
});

export function CallRoomNoSsr({ channel }: { channel: string }) {
  return <CallRoom channel={channel} />;
}
