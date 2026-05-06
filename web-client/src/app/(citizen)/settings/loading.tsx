import { glassCard, glassPanelNested } from "@/lib/vetoGlass";

export default function SettingsLoading() {
  return (
    <div
      className="mx-auto w-full max-w-lg flex-1 px-4 py-6"
      aria-busy="true"
      aria-label="טוען הגדרות"
    >
      <div className="animate-pulse space-y-4">
        <div className={`h-10 w-full ${glassPanelNested}`} />
        <div className={`h-36 w-full ${glassCard}`} />
        <div className={`h-36 w-full ${glassCard}`} />
      </div>
    </div>
  );
}
