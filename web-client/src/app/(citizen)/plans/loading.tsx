import { SkeletonCard } from "@/components/ui/Skeleton";

export default function PlansLoading() {
  return (
    <div
      className="mx-auto w-full max-w-5xl px-4 py-6"
      aria-busy="true"
      aria-label="טעינת מסלולים"
    >
      <div className="grid gap-4 md:grid-cols-3">
        {Array.from({ length: 3 }).map((_, i) => (
          <SkeletonCard key={i} className="h-72" />
        ))}
      </div>
    </div>
  );
}
