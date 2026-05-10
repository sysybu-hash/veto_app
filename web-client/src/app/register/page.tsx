"use client";

import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useState } from "react";
import {
  apiUrl,
  isApiOriginConfigured,
  tunnelBypassHeaders,
} from "@/lib/env";
import { normalizePhoneForVeto } from "@/lib/phone";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import {
  btnPrimaryDark,
  btnSecondaryGlass,
  glassInput,
  glassPanelNested,
} from "@/lib/vetoGlass";

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
    <div className="flex min-h-screen w-full items-center justify-center px-4 py-12">
      <main
        className={`w-full max-w-lg p-6 shadow-[0_24px_64px_rgba(15,23,42,0.15)] backdrop-blur-2xl md:p-8 ${glassPanelNested}`}
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

        <div className="mb-5 flex gap-2 rounded-xl border border-white/10 bg-white/[0.03] p-1 text-sm">
          <button
            type="button"
            onClick={() => setMode("user")}
            className={`flex-1 rounded-lg px-3 py-2 font-semibold transition ${
              mode === "user"
                ? "bg-[#C5A059] text-slate-950"
                : "text-slate-300 hover:bg-white/[0.05]"
            }`}
          >
            הרשמה כאזרח
          </button>
          <button
            type="button"
            onClick={() => setMode("lawyer")}
            className={`flex-1 rounded-lg px-3 py-2 font-semibold transition ${
              mode === "lawyer"
                ? "bg-[#C5A059] text-slate-950"
                : "text-slate-300 hover:bg-white/[0.05]"
            }`}
          >
            הרשמה כעורך דין
          </button>
        </div>

        <h1 className="font-display text-2xl font-semibold text-slate-100">
          {mode === "lawyer" ? "הצטרפות עורכי דין למערכת VETO" : t("register.title")}
        </h1>
        <p className="mt-2 text-sm text-slate-400">
          {mode === "lawyer"
            ? "יש למלא את הפרטים. הבקשה תועבר לאישור מנהל המערכת לפני הפעלת החשבון."
            : t("register.subtitle")}
        </p>

        <div className="mt-6 flex flex-col gap-4">
          <div>
            <label className="text-xs font-medium text-slate-300">
              {t("register.fullName")}
            </label>
            <input
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              className={`mt-1 ${glassInput}`}
              autoComplete="name"
            />
          </div>
          <div>
            <label className="text-xs font-medium text-slate-300">
              {t("register.phone")}
            </label>
            <input
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              className={`mt-1 ${glassInput}`}
              placeholder={t("login.phonePlaceholder")}
              autoComplete="tel"
            />
          </div>

          {mode === "lawyer" && (
            <>
              <div>
                <label className="text-xs font-medium text-slate-300">
                  אימייל מקצועי
                </label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className={`mt-1 ${glassInput}`}
                  autoComplete="email"
                />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs font-medium text-slate-300">
                    מספר רישיון לשכת עוה״ד
                  </label>
                  <input
                    value={licenseNumber}
                    onChange={(e) => setLicenseNumber(e.target.value)}
                    className={`mt-1 ${glassInput}`}
                  />
                </div>
                <div>
                  <label className="text-xs font-medium text-slate-300">
                    שנות ותק
                  </label>
                  <input
                    type="number"
                    min={0}
                    max={70}
                    value={years}
                    onChange={(e) =>
                      setYears(Math.max(0, Number(e.target.value) || 0))
                    }
                    className={`mt-1 ${glassInput}`}
                  />
                </div>
              </div>
              <div>
                <p className="mb-2 text-xs font-medium text-slate-300">
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
                            ? "border border-[#C5A059] bg-[#C5A059]/15 text-[#C5A059]"
                            : "border border-white/10 bg-white/[0.03] text-slate-400 hover:bg-white/[0.06]"
                        }`}
                      >
                        {s.label}
                      </button>
                    );
                  })}
                </div>
              </div>
            </>
          )}

          <button
            type="button"
            disabled={busy}
            onClick={() => onSubmit()}
            className={`w-full px-4 py-3 text-sm font-semibold ${btnPrimaryDark} disabled:opacity-50`}
          >
            {busy
              ? t("register.busy")
              : mode === "lawyer"
                ? "שליחת בקשה לאישור"
                : t("register.submit")}
          </button>
        </div>

        {message && (
          <p className="mt-4 text-center text-sm text-amber-200" role="status">
            {message}
          </p>
        )}

        <p className="mt-6 text-center text-sm">
          <Link href="/login" className={`${btnSecondaryGlass} inline-block px-4 py-2`}>
            {t("register.backLogin")}
          </Link>
        </p>
      </main>
    </div>
  );
}

export default function RegisterPage() {
  return (
    <Suspense fallback={<div className="min-h-screen" />}>
      <RegisterInner />
    </Suspense>
  );
}
