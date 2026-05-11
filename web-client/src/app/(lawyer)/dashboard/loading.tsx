import { Skeleton, SkeletonCard } from "@/components/ui/Skeleton";
import { glassPanel } from "@/lib/vetoGlass";

/**
 * Lawyer dashboard skeleton — stripe of KPI tiles, nav, then a
 * grid of cards that mirrors the real layout so the page does not
 * jump when data resolves.
 */
export default function LawyerDashboardLoading() {
  return (
    <div
      className="mx-auto w-full max-w-7xl px-4 py-6"
      aria-busy="true"
      aria-label="טעינת דשבורד עורך דין"
    >
      <div className="mb-4 flex items-center justify-between">
        <Skeleton width={220} height={28} rounded="md" />
        <Skeleton width={120} height={36} rounded="lg" />
      </div>

      <nav className={`${glassPanel} grid grid-cols-2 gap-2 p-2 md:grid-cols-6`}>
        {Array.from({ length: 6 }).map((_, i) => (
          <Skeleton key={i} height={36} rounded="lg" />
        ))}
      </nav>

      <section className={`${glassPanel} mt-5 grid gap-3 p-4 md:grid-cols-4`}>
        {Array.from({ length: 4 }).map((_, i) => (
          <div key={i} className="rounded-xl border border-slate-200/80 bg-white/85 p-3">
            <Skeleton width={80} height={12} className="mb-2" />
            <Skeleton width={120} height={28} />
          </div>
        ))}
      </section>

      <div className="mt-5 grid gap-3 md:grid-cols-3">
        {Array.from({ length: 3 }).map((_, i) => (
          <SkeletonCard key={i} />
        ))}
      </div>
    </div>
  );
}
