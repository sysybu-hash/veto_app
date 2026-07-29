"use client";

type Props = {
  checked: boolean;
  onChange: (next: boolean) => void;
  id?: string;
  "aria-labelledby"?: string;
};

/** VETO 2027 — gold-accented switch for notification preferences. */
export function GoldSwitch({
  checked,
  onChange,
  id,
  "aria-labelledby": ariaLabelledby,
}: Props) {
  return (
    <button
      id={id}
      type="button"
      role="switch"
      aria-checked={checked}
      aria-labelledby={ariaLabelledby}
      onClick={() => onChange(!checked)}
      className={`relative h-8 w-[3.25rem] shrink-0 rounded-full transition focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#C5A059] ${
        checked
          ? "bg-veto-gold shadow-[0_0_18px_rgba(197,160,89,0.55)] ring-2 ring-veto-gold/35" : "border border-subtle bg-white/[0.04] shadow-inner backdrop-blur-sm"}`}
    >
      <span
        className={`absolute top-1 h-6 w-6 rounded-full bg-surface-overlay shadow-md transition-all duration-200 ${
          checked ? "end-1" : "start-1"}`}
      />
    </button>
  );
}
