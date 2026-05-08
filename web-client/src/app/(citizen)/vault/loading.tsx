import { glassCard, glassList } from "@/lib/vetoGlass";

export default function VaultLoading() {
  return (
    <div
      className="mx-auto w-full max-w-lg flex-1 space-y-6 px-4 py-6"
      aria-busy="true"
      aria-label="טוען כספת"
    >
      <div className="animate-pulse space-y-4">
        <div className={`h-9 w-48 ${glassCard}`} />
        <div className="grid gap-3 sm:grid-cols-2">
          <div className={`h-28 ${glassCard}`} />
          <div className={`h-28 ${glassCard}`} />
        </div>
        <div className={`h-40 ${glassList}`} />
      </div>
    </div>
  );
}
