import { Skeleton, SkeletonCard } from "@/components/ui/Skeleton";

export default function FamilyLoading() {
  return (
    <div
      className="mx-auto w-full max-w-3xl px-4 py-6"
      aria-busy="true"
      aria-label="טעינת מנוי משפחתי"
    >
      <Skeleton width={240} height={28} className="mb-4" />
      <SkeletonCard className="mb-4 h-40" />
      <div className="grid gap-3 md:grid-cols-2">
        <SkeletonCard className="h-32" />
        <SkeletonCard className="h-32" />
      </div>
    </div>
  );
}
