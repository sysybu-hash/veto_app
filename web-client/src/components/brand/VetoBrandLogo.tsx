/**
 * לוגו מותג VETO — קובץ PNG ב־`public/veto-brand.png`
 * (עותק נוסף בשורש הפרויקט: `veto-brand.png` לניהול נכסים מחוץ ל־Next.)
 */
const LOGO_SRC = "/veto-brand.png?v=20260511";

const VARIANT_CLASS: Record<"default" | "compact", string> = {
  default: "h-11 w-auto max-h-11",
  /** Narrow headers / cookie bars — caps width so the mark does not overflow. */
  compact: "h-8 w-auto max-h-8 max-w-[min(140px,42vw)] sm:h-9 sm:max-h-9",
};

export function VetoBrandLogo({
  className,
  variant = "default",
  priority,
}: {
  className?: string;
  /** Preset size when you do not want to repeat Tailwind on every call site. */
  variant?: keyof typeof VARIANT_CLASS;
  /** Hint for above-the-fold / LCP (e.g. global nav). */
  priority?: boolean;
}) {
  const sizeClass = className?.trim() ? className : VARIANT_CLASS[variant];
  return (
    // eslint-disable-next-line @next/next/no-img-element -- static asset from /public
    <img
      src={LOGO_SRC}
      alt="VETO legal."
      width={985}
      height={1024}
      draggable={false}
      className={`select-none object-contain ${sizeClass}`}
      {...(priority ? { fetchPriority: "high" as const } : {})}
    />
  );
}
