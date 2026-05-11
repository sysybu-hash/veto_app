import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";
import { Skeleton, SkeletonText } from "@/components/ui/Skeleton";
import { authGlassPanel } from "@/lib/vetoGlass";

export default function LoginLoading() {
  return (
    <div
      className="flex min-h-screen w-full items-center justify-center bg-veto-ink px-4 py-12"
      aria-busy="true"
      aria-label="טוען מסך התחברות"
    >
      <div className="w-full max-w-md space-y-6 text-center">
        <div className="flex justify-center">
          <VetoBrandLogo className="h-9 w-auto sm:h-10" priority />
        </div>
        <div className={`space-y-4 p-6 ${authGlassPanel}`}>
          <Skeleton className="mx-auto h-10 w-full max-w-xs" rounded="lg" />
          <SkeletonText lines={2} className="text-start" />
          <Skeleton className="h-12 w-full" rounded="xl" />
          <Skeleton className="h-12 w-full" rounded="xl" />
        </div>
      </div>
    </div>
  );
}
