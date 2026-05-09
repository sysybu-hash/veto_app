"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";
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

export default function RegisterPage() {
  const router = useRouter();
  const { t, locale } = useTranslation();
  const [fullName, setFullName] = useState("");
  const [phone, setPhone] = useState("");
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

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
    void (async () => {
      setBusy(true);
      setMessage(null);
      try {
        await postJson("/api/auth/register", {
          full_name: fullName.trim(),
          phone: normalizedPhone,
          role: "user",
          preferred_language: locale === "ru" ? "ru" : locale === "en" ? "en" : "he",
        });
        router.push(
          `/login?registered=1&phone=${encodeURIComponent(normalizedPhone)}`,
        );
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
        className={`w-full max-w-md p-6 shadow-[0_24px_64px_rgba(15,23,42,0.15)] backdrop-blur-2xl md:p-8 ${glassPanelNested}`}
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
        <h1 className="font-display text-2xl font-semibold text-slate-100">
          {t("register.title")}
        </h1>
        <p className="mt-2 text-sm text-slate-400">{t("register.subtitle")}</p>

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
          <button
            type="button"
            disabled={busy}
            onClick={() => onSubmit()}
            className={`w-full px-4 py-3 text-sm font-semibold ${btnPrimaryDark} disabled:opacity-50`}
          >
            {busy ? t("register.busy") : t("register.submit")}
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
