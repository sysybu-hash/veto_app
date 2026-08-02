"use client";

import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useState } from "react";
import { Database, Lock, ShieldCheck } from "lucide-react";
import {
  apiUrl,
  isApiOriginConfigured,
  tunnelBypassHeaders,
} from "@/lib/env";
import { normalizePhoneForVeto } from "@/lib/phone";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { authBtnSecondary, authGlassInput, authGlassPanel } from "@/lib/vetoGlass";
import { Button } from "@/components/ui/primitives/Button";

type Mode = "user" | "lawyer";

const SPECIALIZATION_OPTIONS = [
  { id: "criminal", label: "פלילי" },
  { id: "family", label: "משפחה" },
  { id: "real estate", label: "נדל״ן" },
  { id: "labor", label: "עבודה" },
  { id: "commercial", label: "מסחרי" },
  { id: "traffic", label: "תעבורה" },
] as const;

async function postJson(path: string, body: object) {
  const res = await fetch(apiUrl(path), {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...tunnelBypassHeaders(),
    },
    body: JSON.stringify(body),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    const err =
      typeof data?.error === "string"
        ? data.error
        : `Request failed (${res.status})`;
    throw new Error(err);
  }
  return data as Record<string, unknown>;
}

function RegisterInner() {
  const router = useRouter();
  const search = useSearchParams();
  const { t, locale } = useTranslation();

  const initialMode: Mode = search.get("role") === "lawyer" ? "lawyer" : "user";
  const [mode, setMode] = useState<Mode>(initialMode);

  const [fullName, setFullName] = useState("");
  const [phone, setPhone] = useState("");
  const [email, setEmail] = useState("");
  const [licenseNumber, setLicenseNumber] = useState("");
  const [years, setYears] = useState<number>(0);
  const [specs, setSpecs] = useState<string[]>([]);

  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [acceptedTerms, setAcceptedTerms] = useState(false);

  const toggleSpec = (id: string) =>
    setSpecs((prev) => (prev.includes(id) ? prev.filter((s) => s !== id) : [...prev, id]));

  const onSubmit = () => {
    const normalizedPhone = normalizePhoneForVeto(phone);
    if (!fullName.trim()) {
      setMessage(t("register.errFullName"));
      return;
    }
    if (!normalizedPhone) {
      setMessage(t("login.errInvalidPhone"));
      return;
    }
    if (mode === "lawyer" && !licenseNumber.trim()) {
      setMessage("נדרש מספר רישיון לשכת עוה״ד.");
      return;
    }
    if (!acceptedTerms) {
      setMessage("יש לאשר את תנאי השימוש ומדיניות הפרטיות כדי להמשיך.");
      return;
    }
    void (async () => {
      setBusy(true);
      setMessage(null);
      try {
        await postJson("/api/auth/register", {
          full_name: fullName.trim(),
          phone: normalizedPhone,
          role: mode,
          preferred_language: locale === "ru" ? "ru" : locale === "en" ? "en" : "he",
          ...(email.trim() ? { email: email.trim() } : {}),
          ...(mode === "lawyer"
            ? {
                license_number: licenseNumber.trim(),
                years_of_experience: Number.isFinite(years) ? years : 0,
                specializations: specs,
              }
            : {}),
        });

        if (mode === "lawyer") {
          router.push(
            `/login?registeredLawyer=1&phone=${encodeURIComponent(normalizedPhone)}`,
          );
        } else {
          router.push(
            `/login?registered=1&phone=${encodeURIComponent(normalizedPhone)}`,
          );
        }
      } catch (e) {
        setMessage(e instanceof Error ? e.message : "Error");
      } finally {
        setBusy(false);
      }
    })();
  };

  return (
    <div className="flex min-h-screen w-full items-center justify-center bg-surface-canvas px-4 py-12">
      <main
        className={`w-full max-w-lg p-6 md:p-8 ${authGlassPanel}`}
        dir={locale === "he" ? "rtl" : "ltr"}
      >
        {!isApiOriginConfigured() && (
          <div
            className="mb-4 rounded-xl border border-amber-600/80 bg-amber-500/15 px-3 py-2.5 text-xs font-semibold text-amber-200"
            role="alert"
          >
            {t("login.alertMissingApiOrigin")}
          </div>
        )}

        <div className="mb-5 flex gap-2 rounded-xl border border-subtle bg-white/[0.03] p-1 text-sm">
          <button
            type="button"
            onClick={() => setMode("user")}
            className={`flex-1 rounded-lg px-3 py-2 font-semibold transition ${
              mode === "user"
                ? "bg-veto-gold text-primary" : "text-secondary hover:bg-white/[0.05]"}`}
          >
            הרשמה כאזרח
          </button>
          <button
            type="button"
            onClick={() => setMode("lawyer")}
            className={`flex-1 rounded-lg px-3 py-2 font-semibold transition ${
              mode === "lawyer"
                ? "bg-veto-gold text-primary" : "text-secondary hover:bg-white/[0.05]"}`}
          >
            הרשמה כעורך דין
          </button>
        </div>

        <h1 className="font-display text-2xl font-semibold text-primary">
          {mode === "lawyer" ? "הצטרפות עורכי דין למערכת VETO" : t("register.title")}
        </h1>
        <p className="mt-2 text-sm text-muted">
          {mode === "lawyer"
            ? "יש למלא את הפרטים. הבקשה תועבר לאישור מנהל המערכת לפני הפעלת החשבון."
            : t("register.subtitle")}
        </p>

        <div className="mt-6 flex flex-col gap-4">
          <div>
            <label htmlFor="register-full-name" className="text-xs font-medium text-secondary">
              {t("register.fullName")}
            </label>
            <input
              id="register-full-name"
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              className={`mt-1 ${authGlassInput}`}
              autoComplete="name"
            />
          </div>
          <div>
            <label htmlFor="register-phone" className="text-xs font-medium text-secondary">
              {t("register.phone")}
            </label>
            <input
              id="register-phone"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              className={`mt-1 ${authGlassInput}`}
              placeholder={t("login.phonePlaceholder")}
              autoComplete="tel"
            />
          </div>

          {mode === "lawyer" && (
            <>
              <div>
                <label htmlFor="register-email" className="text-xs font-medium text-secondary">
                  אימייל מקצועי
                </label>
                <input
                  id="register-email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className={`mt-1 ${authGlassInput}`}
                  autoComplete="email"
                />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label htmlFor="register-license" className="text-xs font-medium text-secondary">
                    מספר רישיון לשכת עוה״ד
                  </label>
                  <input
                    id="register-license"
                    value={licenseNumber}
                    onChange={(e) => setLicenseNumber(e.target.value)}
                    className={`mt-1 ${authGlassInput}`}
                  />
                </div>
                <div>
                  <label htmlFor="register-years" className="text-xs font-medium text-secondary">
                    שנות ותק
                  </label>
                  <input
                    id="register-years"
                    type="number"
                    min={0}
                    max={70}
                    value={years}
                    onChange={(e) =>
                      setYears(Math.max(0, Number(e.target.value) || 0))
                    }
                    className={`mt-1 ${authGlassInput}`}
                  />
                </div>
              </div>
              <div>
                <p className="mb-2 text-xs font-medium text-secondary">
                  תחומי התמחות (בחר אחד או יותר)
                </p>
                <div className="flex flex-wrap gap-2">
                  {SPECIALIZATION_OPTIONS.map((s) => {
                    const on = specs.includes(s.id);
                    return (
                      <button
                        type="button"
                        key={s.id}
                        onClick={() => toggleSpec(s.id)}
                        className={`rounded-full px-3 py-1 text-xs font-semibold transition ${
                          on
                            ? "border border-veto-gold bg-veto-gold/15 text-veto-gold" : "border border-subtle bg-white/[0.03] text-muted hover:bg-white/[0.06]"}`}
                      >
                        {s.label}
                      </button>
                    );
                  })}
                </div>
              </div>
            </>
          )}

          <label className="flex cursor-pointer items-start gap-3 rounded-xl border border-subtle bg-white/[0.04] p-4 text-sm text-primary">
            <input
              type="checkbox"
              checked={acceptedTerms}
              onChange={(e) => setAcceptedTerms(e.target.checked)}
              className="mt-0.5 h-4 w-4 shrink-0 accent-veto-gold"
              required
            />
            <span>
              אני מסכים ל
              <Link
                href="/terms"
                className="mx-1 font-bold text-veto-gold underline-offset-2 hover:underline"
              >
                תנאי השימוש
              </Link>
              ול
              <Link
                href="/privacy"
                className="mx-1 font-bold text-veto-gold underline-offset-2 hover:underline"
              >
                מדיניות הפרטיות
              </Link>
              של VETO.
            </span>
          </label>

          <p className="rounded-xl border border-veto-gold/20 bg-veto-gold/5 p-3 text-xs leading-relaxed text-secondary">
            חיסיון עו״ד–לקוח חל על שיחות הווידאו המבוצעות במערכת, בכפוף לדין החל
            ולנסיבות העניין.
          </p>

          <Button
            variant="primary"
            size="lg"
            fullWidth
            disabled={busy || !acceptedTerms}
            loading={busy}
            onClick={() => onSubmit()}
          >
            {busy
              ? t("register.busy")
              : mode === "lawyer"
                ? "שליחת בקשה לאישור"
                : t("register.submit")}
          </Button>

          <div
            className="flex flex-wrap items-center justify-center gap-3 border-t border-subtle pt-4 text-xs text-muted"
            aria-label="אבטחה ותאימות"
          >
            <span className="inline-flex items-center gap-1.5 rounded-full border border-subtle bg-white/[0.04] px-3 py-1.5">
              <ShieldCheck className="h-3.5 w-3.5 text-emerald-400" aria-hidden />
              GDPR Compliant
            </span>
            <span className="inline-flex items-center gap-1.5 rounded-full border border-subtle bg-white/[0.04] px-3 py-1.5">
              <Lock className="h-3.5 w-3.5 text-veto-gold" aria-hidden />
              AES-256 Encrypted
            </span>
            <span className="inline-flex items-center gap-1.5 rounded-full border border-subtle bg-white/[0.04] px-3 py-1.5">
              <Database className="h-3.5 w-3.5 text-sky-400" aria-hidden />
              Secure Vault
            </span>
          </div>
        </div>

        {message && (
          <p className="mt-4 text-center text-sm text-amber-200" role="status">
            {message}
          </p>
        )}

        <p className="mt-6 text-center text-sm">
          <Link href="/login" className={`${authBtnSecondary} inline-block px-4 py-2`}>
            {t("register.backLogin")}
          </Link>
        </p>
      </main>
    </div>
  );
}

export default function RegisterPage() {
  return (
    <Suspense fallback={<div className="min-h-screen bg-surface-canvas" />}>
      <RegisterInner />
    </Suspense>
  );
}
