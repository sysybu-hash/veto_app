import { Skeleton } from "@/components/ui/Skeleton";
import { glassPanel } from "@/lib/vetoGlass";

export default function ChatLoading() {
  return (
    <div
      className="mx-auto flex h-full w-full max-w-4xl flex-col px-4 py-4"
      aria-busy="true"
      aria-label="טעינת צ'אט"
    >
      <Skeleton width={200} height={24} className="mb-3" />
      <div className={`${glassPanel} flex flex-1 flex-col gap-3 p-4`}>
        <div className="flex flex-col gap-3">
          {Array.from({ length: 4 }).map((_, i) => (
            <div
              key={i}
              className={`flex ${i % 2 === 0 ? "justify-start" : "justify-end"}`}
            >
              <Skeleton
                width={`${50 + (i % 3) * 12}%`}
                height={48}
                rounded="2xl"
              />
            </div>
          ))}
        </div>
        <div className="mt-auto flex gap-2 pt-3">
          <Skeleton height={44} className="flex-1" rounded="xl" />
          <Skeleton width={44} height={44} rounded="full" />
        </div>
      </div>
    </div>
  );
}
