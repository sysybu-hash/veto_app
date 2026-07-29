"use client";

import dynamic from "next/dynamic";

const CallShell = dynamic(
  () => import("./CallShell").then((m) => m.CallShell),
  {
    ssr: false,
    loading: () => (
      <div data-surface="stage" className="fixed inset-0 z-[70] flex h-[100dvh] w-screen items-center justify-center bg-surface-canvas px-6 text-center text-sm font-bold text-secondary">
        Preparing call room…
      </div>
    ),
  },
);

export function CallShellNoSsr({ channel }: { channel: string }) {
  return <CallShell channel={channel} />;
}
