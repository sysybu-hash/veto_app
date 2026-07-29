"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { apiUrl, isApiOriginConfigured, tunnelBypassHeaders } from "@/lib/env";
import { normalizePhoneForVeto } from "@/lib/phone";
import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";
import { glassInput, glassPanelNested } from "@/lib/vetoGlass";

const SPECIALIZATIONS = [
  { id: "criminal", label: "פלילי" },
  { id: "family", label: "משפחה" },
  { id: "real estate", label: "נדל\"ן" },
  { id: "labor", label: "עבודה" },
  { id: "commercial", label: "מסחרי" },
  { id: "traffic", label: "תעבורה" },
];

async function registerLawyer(body: object) {
  const res = await fetch(apiUrl("/api/auth/register"), {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...tunnelBypassHeaders(),
    },
    body: JSON.stringify(body),
  });
  const data = (await res.json().catch(() => ({}))) as { error?: string };
  if (!res.ok) throw new Error(data.error || `Request failed (${res.status})`);
}

export default function LawyerRegisterPage() {
  const router = useRouter();
  const [fullName, setFullName] = useState("");
  const [phone, setPhone] = useState("");
  const [email, setEmail] = useState("");
  const [licenseNumber, setLicenseNumber] = useState("");
  const [years, setYears] = useState("0");
  const [selected, setSelected] = useState<string[]>([]);
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  function toggleSpec(id: string) {
    setSelected((prev) =>
      prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id],
    );
  }

  async function onSubmit() {
    const normalizedPhone = normalizePhoneForVeto(phone);
    if (!fullName.trim()) return setMessage("שם מלא הוא שדה חובה.");
    if (!normalizedPhone) return setMessage("מספר הטלפון אינו תקין.");
    if (!licenseNumber.trim()) return setMessage("מספר רישיון הוא שדה חובה.");
    if (selected.length === 0) return setMessage("בחר לפחות תחום התמחות אחד.");

    setBusy(true);
    setMessage(null);
    try {
      await registerLawyer({
        full_name: fullName.trim(),
        phone: normalizedPhone,
        email: email.trim() || undefined,
        license_number: licenseNumber.trim(),
        years_of_experience: Number(years) || 0,
        specializations: selected,
        role: "lawyer",
        preferred_language: "he",
      });
      router.push(
        `/login?registeredLawyer=1&phone=${encodeURIComponent(normalizedPhone)}`,
      );
    } catch (e) {
      setMessage(e instanceof Error ? e.message : "ההרשמה נכשלה.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="flex min-h-screen w-full items-center justify-center px-4 py-12" dir="rtl">
      <main className={`w-full max-w-2xl p-6 md:p-8 ${glassPanelNested}`}>
        {!isApiOriginConfigured() ? (
          <div className="mb-4 rounded-xl border border-amber-600/70 bg-amber-500/15 px-3 py-2 text-xs font-semibold text-amber-200">
            שרת ה-API עדיין לא מוגדר בסביבת ה-Frontend.
          </div>
        ) : null}

        <div className="mb-3 flex justify-start">
          <VetoBrandLogo className="h-9 w-auto sm:h-10" />
        </div>
        <h1 className="font-frank text-3xl font-black text-primary">
          הצטרפות עורכי דין
        </h1>
        <p className="mt-2 text-sm leading-6 text-muted">
          מלאו פרטים מקצועיים. לאחר ההרשמה הבקשה תועבר לאישור מנהל לפני קבלת קריאות.
        </p>

        <div className="mt-6 grid gap-4 md:grid-cols-2">
          <Field label="שם מלא" value={fullName} onChange={setFullName} autoComplete="name" />
          <Field label="טלפון" value={phone} onChange={setPhone} autoComplete="tel" />
          <Field label="אימייל" value={email} onChange={setEmail} autoComplete="email" />
          <Field label="מספר רישיון" value={licenseNumber} onChange={setLicenseNumber} />
          <Field label="שנות ותק" value={years} onChange={setYears} type="number" />
        </div>

        <div className="mt-5">
          <p className="text-xs font-medium text-secondary">תחומי התמחות</p>
          <div className="mt-2 flex flex-wrap gap-2">
            {SPECIALIZATIONS.map((spec) => {
              const active = selected.includes(spec.id);
              return (
                <button
                  key={spec.id}
                  type="button"
                  onClick={() => toggleSpec(spec.id)}
                  className={`rounded-full border px-4 py-2 text-sm font-bold transition ${
                    active
                      ? "border-veto-gold bg-veto-gold text-primary" : "border-subtle bg-white/[0.03] text-secondary hover:border-veto-gold/60"}`}
                >
                  {spec.label}
                </button>
              );
            })}
          </div>
        </div>

        {message ? (
          <p className="mt-4 rounded-xl border border-amber-500/30 bg-amber-500/10 px-3 py-2 text-sm text-amber-100">
            {message}
          </p>
        ) : null}

        <div className="mt-6 flex flex-col gap-3 sm:flex-row">
          <button
            type="button"
            disabled={busy}
            onClick={() => void onSubmit()}
            className="rounded-xl bg-veto-gold px-5 py-3 text-sm font-black text-primary transition hover:bg-veto-gold-light disabled:opacity-50"
          >
            {busy ? "שולח..." : "שליחת בקשת הצטרפות"}
          </button>
          <Link
            href="/login"
            className="rounded-xl border border-subtle px-5 py-3 text-center text-sm font-bold text-secondary transition hover:bg-white/[0.06]"
          >
            כבר רשום? כניסה
          </Link>
        </div>
      </main>
    </div>
  );
}

function Field({
  label,
  value,
  onChange,
  type = "text",
  autoComplete,
}: {
  label: string;
  value: string;
  onChange: (value: string) => void;
  type?: string;
  autoComplete?: string;
}) {
  return (
    <label className="block">
      <span className="text-xs font-medium text-secondary">{label}</span>
      <input
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        autoComplete={autoComplete}
        className={`mt-1 ${glassInput}`}
      />
    </label>
  );
}
