import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";
import { Skeleton, SkeletonText } from "@/components/ui/Skeleton";
import { authGlassPanel } from "@/lib/vetoGlass";

export default function RegisterLawyerLoading() {
  return (
    <div
      className="flex min-h-screen w-full items-center justify-center bg-veto-ink px-4 py-12"
      aria-busy="true"
      aria-label="טוען הרשמת עורך דין"
    >
      <div className="w-full max-w-lg space-y-6">
        <div className="flex justify-center">
          <VetoBrandLogo className="h-9 w-auto sm:h-10" />
        </div>
        <div className={`space-y-4 p-6 md:p-8 ${authGlassPanel}`}>
          <Skeleton className="h-9 w-4/5" rounded="md" />
          <SkeletonText lines={2} />
          <Skeleton className="h-11 w-full" rounded="xl" />
          <Skeleton className="h-11 w-full" rounded="xl" />
          <Skeleton className="h-24 w-full" rounded="xl" />
          <Skeleton className="h-12 w-full" rounded="xl" />
        </div>
      </div>
    </div>
  );
}
