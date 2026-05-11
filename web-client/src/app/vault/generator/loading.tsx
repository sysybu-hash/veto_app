import { Skeleton, SkeletonText } from "@/components/ui/Skeleton";
import { glassCard, glassPanelNested } from "@/lib/vetoGlass";

export default function VaultGeneratorLoading() {
  return (
    <div
      className="mx-auto w-full max-w-7xl space-y-5 px-4 pb-[calc(10rem+env(safe-area-inset-bottom))] pt-5"
      aria-busy="true"
      aria-label="טוען מחולל מסמכים"
      dir="rtl"
    >
      <div className="grid gap-5 lg:grid-cols-[360px_minmax(0,1fr)]">
        <div className={`space-y-4 p-4 ${glassPanelNested}`}>
          <Skeleton className="h-8 w-3/4" rounded="md" />
          <SkeletonText lines={4} />
          <Skeleton className="h-11 w-full" rounded="xl" />
          <Skeleton className="h-11 w-full" rounded="xl" />
        </div>
        <div className={`min-h-[320px] p-4 ${glassCard}`}>
          <Skeleton className="mb-4 h-6 w-2/3" rounded="md" />
          <SkeletonText lines={8} />
        </div>
      </div>
    </div>
  );
}
