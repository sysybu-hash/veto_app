import { Skeleton, SkeletonText } from "@/components/ui/Skeleton";
import { glassCard, glassPanelNested } from "@/lib/vetoGlass";

export default function AdminSectionLoading() {
  return (
    <div
      className="veto-admin-keep-dark mx-auto w-full max-w-6xl space-y-6 px-4 py-8"
      aria-busy="true"
      aria-label="טוען קונסולת ניהול"
    >
      <div className="flex flex-wrap items-center justify-between gap-4">
        <Skeleton className="h-10 w-56 rounded-lg bg-white/10" />
        <Skeleton className="h-10 w-40 rounded-lg bg-white/10" />
      </div>
      <div className={`p-5 ${glassPanelNested}`}>
        <Skeleton className="mb-4 h-6 w-48 bg-slate-200/50 dark:bg-white/10" rounded="md" />
        <SkeletonText lines={2} />
        <div className="mt-6 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          <div className={`min-h-[120px] p-4 ${glassCard}`}>
            <Skeleton className="mb-3 h-4 w-1/2" />
            <Skeleton className="h-8 w-full" />
          </div>
          <div className={`min-h-[120px] p-4 ${glassCard}`}>
            <Skeleton className="mb-3 h-4 w-1/2" />
            <Skeleton className="h-8 w-full" />
          </div>
          <div className={`min-h-[120px] p-4 ${glassCard}`}>
            <Skeleton className="mb-3 h-4 w-1/2" />
            <Skeleton className="h-8 w-full" />
          </div>
        </div>
      </div>
    </div>
  );
}
