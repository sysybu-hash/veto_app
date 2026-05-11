"use client";

import { useRef, type ClipboardEvent, type KeyboardEvent } from "react";
import { authGlassInput } from "@/lib/vetoGlass";

const OTP_LEN = 6;

export type OtpInputProps = {
  value: string;
  onChange: (next: string) => void;
  disabled?: boolean;
  onResend?: () => void | Promise<void>;
  /** Seconds until resend is allowed; 0 means the user can resend */
  resendCooldown: number;
  resendBusy?: boolean;
};

export function OtpInput({
  value,
  onChange,
  disabled,
  onResend,
  resendCooldown,
  resendBusy,
}: OtpInputProps) {
  const refs = useRef<Array<HTMLInputElement | null>>([]);
  const raw = value.replace(/\D/g, "").slice(0, OTP_LEN);
  const digits = Array.from({ length: OTP_LEN }, (_, i) => raw[i] ?? "");

  const commit = (next: string) => {
    onChange(next.replace(/\D/g, "").slice(0, OTP_LEN));
  };

  const focusAt = (i: number) => {
    refs.current[Math.max(0, Math.min(OTP_LEN - 1, i))]?.focus();
  };

  const onKeyDown = (index: number, e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Backspace") {
      if (!digits[index] && index > 0) {
        e.preventDefault();
        const prev = raw.slice(0, index - 1) + raw.slice(index);
        commit(prev);
        focusAt(index - 1);
      }
    } else if (e.key === "ArrowLeft") {
      e.preventDefault();
      focusAt(index - 1);
    } else if (e.key === "ArrowRight") {
      e.preventDefault();
      focusAt(index + 1);
    }
  };

  const onPaste = (e: ClipboardEvent<HTMLInputElement>) => {
    e.preventDefault();
    const t = e.clipboardData.getData("text").replace(/\D/g, "").slice(0, OTP_LEN);
    commit(t);
    focusAt(Math.min(t.length, OTP_LEN - 1));
  };

  return (
    <div className="flex flex-col gap-3">
      <div className="flex justify-center gap-2" dir="ltr">
        {digits.map((d, i) => (
          <input
            key={i}
            ref={(el) => {
              refs.current[i] = el;
            }}
            type="text"
            inputMode="numeric"
            pattern="[0-9]*"
            autoComplete={i === 0 ? "one-time-code" : "off"}
            autoFocus={i === 0}
            maxLength={1}
            value={d}
            disabled={disabled}
            onChange={(e) => {
              const v = e.target.value.replace(/\D/g, "");
              if (v.length > 1) {
                commit(v.slice(0, OTP_LEN));
                focusAt(Math.min(v.length, OTP_LEN - 1));
                return;
              }
              const next =
                raw.slice(0, i) + (v.slice(-1) || "") + raw.slice(i + 1);
              commit(next);
              if (v && i < OTP_LEN - 1) focusAt(i + 1);
            }}
            onKeyDown={(e) => onKeyDown(i, e)}
            onPaste={i === 0 ? onPaste : undefined}
            className={`h-12 min-h-[48px] w-11 min-w-[44px] text-center text-lg font-bold ${authGlassInput}`}
            aria-label={`ספרת קוד ${i + 1} מתוך ${OTP_LEN}`}
          />
        ))}
      </div>
      {onResend && (
        <div className="flex justify-center">
          <button
            type="button"
            disabled={resendCooldown > 0 || resendBusy || disabled}
            onClick={() => void onResend()}
            className="min-h-[44px] rounded-lg px-2 text-sm font-semibold text-veto-gold underline-offset-2 outline-none hover:underline focus-visible:ring-2 focus-visible:ring-veto-gold/50 disabled:cursor-not-allowed disabled:opacity-40 disabled:no-underline"
          >
            {resendCooldown > 0
              ? `שלח שוב בעוד ${resendCooldown} ש׳`
              : "שלח שוב קוד"}
          </button>
        </div>
      )}
    </div>
  );
}
