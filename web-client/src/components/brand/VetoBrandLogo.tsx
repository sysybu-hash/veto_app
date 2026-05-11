/**
 * Canonical horizontal wordmark — `public/veto-logo.svg`.
 * Use this everywhere the product brand appears (nav, headers, loading, etc.).
 */
export function VetoBrandLogo({
  className = "h-11 w-auto",
  priority,
}: {
  className?: string;
  /** Hint for above-the-fold / LCP (e.g. global nav). */
  priority?: boolean;
}) {
  return (
    // eslint-disable-next-line @next/next/no-img-element -- static SVG from /public
    <img
      src="/veto-logo.svg?v=20260210"
      alt="VETO Legal"
      width={256}
      height={72}
      draggable={false}
      className={`select-none ${className}`}
      {...(priority ? { fetchPriority: "high" as const } : {})}
    />
  );
}
