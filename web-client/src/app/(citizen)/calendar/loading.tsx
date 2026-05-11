import { Skeleton } from "@/components/ui/Skeleton";
import { glassPanel } from "@/lib/vetoGlass";

export default function CalendarLoading() {
  return (
    <div
      className="mx-auto w-full max-w-5xl px-4 py-6"
      aria-busy="true"
      aria-label="טעינת יומן"
    >
      <div className="mb-4 flex items-center justify-between">
        <Skeleton width={180} height={26} />
        <Skeleton width={140} height={32} rounded="lg" />
      </div>
      <div className={`${glassPanel} p-4`}>
        <div className="mb-3 grid grid-cols-7 gap-1">
          {Array.from({ length: 7 }).map((_, i) => (
            <Skeleton key={i} height={20} />
          ))}
        </div>
        <div className="grid grid-cols-7 gap-1">
          {Array.from({ length: 35 }).map((_, i) => (
            <Skeleton key={i} height={64} rounded="md" />
          ))}
        </div>
      </div>
    </div>
  );
}
