"use client";

import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useMemo, useState } from "react";
import { Database, Lock, ShieldCheck } from "lucide-react";
import {
  apiUrl,
  isApiOriginConfigured,
  tunnelBypassHeaders,
} from "@/lib/env";
import { beginGoogleImplicitLogin } from "@/lib/googleOAuth";
import { normalizePhoneForVeto } from "@/lib/phone";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { authBtnSecondary, authGlassInput, authGlassPanel } from "@/lib/vetoGlass";
import { Button } from "@/components/ui/primitives/Button";

type Mode = "user" | "lawyer";

function safeNextPath(next: string | null): string | null {
  if (!next || !next.startsWith("/") || next.startsWith("//")) return null;
  return next;
}

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

function GoogleIcon() {
  return (
    <svg className="h-5 w-5 shrink-0" viewBox="0 0 24 24" aria-hidden>
      <path
        fill="#4285F4"
        d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
      />
      <path
        fill="#34A853"
        d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
      />
      <path
        fill="#FBBC05"
        d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
      />
      <path
        fill="#EA4335"
        d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
      />
    </svg>
  );
}

function RegisterInner() {
  const router = useRouter();
  const search = useSearchParams();
  const { t, locale } = useTranslation();

  const initialMode: Mode = search.get("role") === "lawyer" ? "lawyer" : "user";
  const [mode, setMode] = useState<Mode>(initialMode);
  const nextParam = safeNextPath(
    search.get("next") ?? search.get("redirect"),
  );

  const [fullName, setFullName] = useState("");
  const [phone, setPhone] = useState("");
  const [email, setEmail] = useState("");
  const [licenseNumber, setLicenseNumber] = useState("");
  const [years, setYears] = useState<number>(0);
  const [specs, setSpecs] = useState<string[]>([]);

  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [showLoginHint, setShowLoginHint] = useState(false);
  const [acceptedTerms, setAcceptedTerms] = useState(false);

  const specializationOptions = useMemo(
    () =>
      [
        { id: "criminal", label: t("specialization.criminal") },
        { id: "family", label: t("specialization.family") },
        { id: "real estate", label: t("registerUi.specRealEstate") },
        { id: "labor", label: t("specialization.labor") },
        { id: "commercial", label: t("registerUi.specCommercial") },
        { id: "traffic", label: t("specialization.traffic") },
      ] as const,
    [t],
  );

  const toggleSpec = (id: string) =>
    setSpecs((prev) => (prev.includes(id) ? prev.filter((s) => s !== id) : [...prev, id]));

  const handleGoogle = () => {
    setMessage(null);
    setShowLoginHint(false);
    if (!acceptedTerms) {
      setMessage(t("registerUi.errAcceptTerms"));
      return;
    }
    const result = beginGoogleImplicitLogin({ next: nextParam });
    if (result.ok || result.reason === "legacy_redirect") {
      setBusy(true);
      return;
    }
    if (result.reason === "missing_client_id") {
      setMessage(t("login.errMissingGoogleClientId"));
      return;
    }
    setMessage(t("login.errGoogleOAuthStorage"));
  };

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
      setMessage(t("registerUi.errLicense"));
      return;
    }
    if (!acceptedTerms) {
      setMessage(t("registerUi.errAcceptTerms"));
      return;
    }
    void (async () => {
      setBusy(true);
      setMessage(null);
      setShowLoginHint(false);
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
        const raw = e instanceof Error ? e.message : String(e);
        if (/already exists|a record with this phone/i.test(raw)) {
          setMessage(t("register.errPhoneExists"));
          setShowLoginHint(true);
        } else if (/invalid phone number/i.test(raw)) {
          setMessage(t("login.errInvalidPhone"));
        } else {
          setMessage(raw || "Error");
        }
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
            {t("registerUi.asCitizen")}
          </button>
          <button
            type="button"
            onClick={() => setMode("lawyer")}
            className={`flex-1 rounded-lg px-3 py-2 font-semibold transition ${
              mode === "lawyer"
                ? "bg-veto-gold text-primary" : "text-secondary hover:bg-white/[0.05]"}`}
          >
            {t("registerUi.asLawyer")}
          </button>
        </div>

        <h1 className="font-display text-2xl font-semibold text-primary">
          {mode === "lawyer" ? t("registerUi.lawyerTitle") : t("register.title")}
        </h1>
        <p className="mt-2 text-sm text-muted">
          {mode === "lawyer" ? t("registerUi.lawyerSubtitle") : t("register.subtitle")}
        </p>

        <label className="mt-6 flex cursor-pointer items-start gap-3 rounded-xl border border-subtle bg-white/[0.04] p-4 text-sm text-primary">
          <input
            type="checkbox"
            checked={acceptedTerms}
            onChange={(e) => setAcceptedTerms(e.target.checked)}
            className="mt-0.5 h-4 w-4 shrink-0 accent-veto-gold"
            required
          />
          <span>
            {t("registerUi.agreePrefix")}{" "}
            <Link
              href="/terms"
              className="mx-1 font-bold text-veto-gold underline-offset-2 hover:underline"
            >
              {t("registerUi.terms")}
            </Link>{" "}
            {t("registerUi.agreeAnd")}{" "}
            <Link
              href="/privacy"
              className="mx-1 font-bold text-veto-gold underline-offset-2 hover:underline"
            >
              {t("registerUi.privacy")}
            </Link>
            .
          </span>
        </label>

        {mode === "user" && (
          <div className="mt-4 flex flex-col gap-4">
            <Button
              variant="secondary"
              size="lg"
              fullWidth
              onClick={handleGoogle}
              disabled={busy || !acceptedTerms}
            >
              <GoogleIcon />
              {t("login.google")}
            </Button>
            <div className="relative py-1">
              <div className="absolute inset-0 flex items-center" aria-hidden>
                <div className="w-full border-t border-subtle" />
              </div>
              <div className="relative flex justify-center text-xs font-medium">
                <span className="rounded-full border border-subtle bg-white/[0.06] px-3 py-0.5 text-muted backdrop-blur-sm">
                  {t("login.orPhone")}
                </span>
              </div>
            </div>
          </div>
        )}

        <div className={`flex flex-col gap-4 ${mode === "user" ? "mt-2" : "mt-6"}`}>
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
                  {t("registerUi.proEmail")}
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
                    {t("registerUi.licenseNumber")}
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
                    {t("registerUi.years")}
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
                  {t("registerUi.specs")}
                </p>
                <div className="flex flex-wrap gap-2">
                  {specializationOptions.map((s) => {
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

          <p className="rounded-xl border border-veto-gold/20 bg-veto-gold/5 p-3 text-xs leading-relaxed text-secondary">
            {t("registerUi.privilegeNote")}
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
                ? t("registerUi.submitLawyer")
                : t("register.submit")}
          </Button>

          <div
            className="flex flex-wrap items-center justify-center gap-3 border-t border-subtle pt-4 text-xs text-muted"
            aria-label={t("registerUi.securityAria")}
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
            {showLoginHint && (
              <>
                {" "}
                <Link
                  href={`/login${phone.trim() ? `?phone=${encodeURIComponent(phone.trim())}` : ""}`}
                  className="font-semibold text-veto-gold underline underline-offset-2"
                >
                  {t("register.backLogin")}
                </Link>
              </>
            )}
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
