import { glassCard, glassPanelNested } from "@/lib/vetoGlass";

export default function HubLoading() {
  return (
    <div
      className="mx-auto w-full max-w-lg flex-1 space-y-5 px-4 py-6"
      aria-busy="true"
      aria-label="טוען מרכז אזרח"
    >
      <div className="animate-pulse space-y-4">
        <div className={`h-10 w-40 ${glassPanelNested}`} />
        <div className={`h-48 w-full ${glassCard}`} />
        <div className={`h-24 w-full ${glassCard}`} />
        <div className="grid grid-cols-2 gap-3">
          <div className={`h-20 ${glassCard}`} />
          <div className={`h-20 ${glassCard}`} />
        </div>
      </div>
    </div>
  );
}
