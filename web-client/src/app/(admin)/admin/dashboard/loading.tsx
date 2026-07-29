import { Skeleton, SkeletonCard } from "@/components/ui/Skeleton";
import { glassPanel } from "@/lib/vetoGlass";

export default function AdminDashboardLoading() {
  return (
    <div
      className="mx-auto w-full max-w-7xl px-4 py-6"
      aria-busy="true"
      aria-label="טעינת לוח אדמין"
    >
      <Skeleton width={240} height={28} className="mb-4" />
      <section className={`${glassPanel} grid gap-3 p-4 md:grid-cols-4`}>
        {Array.from({ length: 4 }).map((_, i) => (
          <div key={i} className="rounded-xl border border-subtle bg-surface-raised p-3">
            <Skeleton width={80} height={12} className="mb-2" />
            <Skeleton width={120} height={28} />
          </div>
        ))}
      </section>
      <div className="mt-5 grid gap-4 lg:grid-cols-2">
        <SkeletonCard />
        <SkeletonCard />
      </div>
    </div>
  );
}
