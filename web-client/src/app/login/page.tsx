"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { getRoleFromJwt, setJwt } from "@/lib/authToken";
import { setSocketAuthToken } from "@/lib/socketClient";
import { apiUrl, tunnelBypassHeaders } from "@/lib/env";

async function postJson(path: string, body: object) {
  const headers: HeadersInit = {
    "Content-Type": "application/json",
    ...tunnelBypassHeaders(),
  };
  const res = await fetch(apiUrl(path), {
    method: "POST",
    headers,
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

export default function LoginPage() {
  const router = useRouter();
  const [phone, setPhone] = useState("");
  const [otp, setOtp] = useState("");
  const [devToken, setDevToken] = useState("");
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  const googleLoginUrl = process.env.NEXT_PUBLIC_GOOGLE_LOGIN_URL;

  const handleGoogle = () => {
    setMessage(null);
    if (googleLoginUrl) {
      window.location.href = googleLoginUrl;
      return;
    }
    setMessage(
      "כניסה עם Google תופעל לאחר חיבור OAuth. ניתן להמשיך בטלפון והקוד בינתיים.",
    );
  };

  const handleOtpLogin = async () => {
    setBusy(true);
    setMessage(null);
    try {
      await postJson("/api/auth/request-otp", { phone });
      setMessage("נשלח קוד. בדקו את הטלפון או לוג שרת בפיתוח.");
    } catch (e) {
      setMessage(e instanceof Error ? e.message : "Request failed");
    } finally {
      setBusy(false);
    }
  };

  const handleVerify = async () => {
    setBusy(true);
    setMessage(null);
    try {
      const data = await postJson("/api/auth/verify-otp", { phone, otp });
      const token = typeof data.token === "string" ? data.token : null;
      if (!token) throw new Error("No token in response");
      setJwt(token);
      setSocketAuthToken(token);
      const role = getRoleFromJwt();
      if (role === "admin") {
        router.replace("/admin/dashboard");
      } else if (role === "lawyer") {
        router.replace("/dashboard");
      } else {
        router.replace("/hub");
      }
    } catch (e) {
      setMessage(e instanceof Error ? e.message : "Verification failed");
    } finally {
      setBusy(false);
    }
  };

  const handleDevToken = () => {
    const t = devToken.trim();
    if (!t) {
      setMessage("הדביקו JWT לפני השימוש.");
      return;
    }
    setJwt(t);
    setSocketAuthToken(t);
    const role = getRoleFromJwt();
    if (role === "admin") {
      router.replace("/admin/dashboard");
    } else if (role === "lawyer") {
      router.replace("/dashboard");
    } else {
      router.replace("/hub");
    }
  };

  return (
    <div className="flex min-h-screen w-full items-center justify-center px-4 py-12 md:px-6 md:py-16">
      <main
        className="w-full max-w-md rounded-3xl border border-white/60 bg-white/30 p-6 shadow-[0_24px_64px_rgba(15,23,42,0.15)] backdrop-blur-2xl md:p-8"
        dir="rtl"
      >
        <div className="text-center">
          <h1 className="font-display text-2xl font-semibold text-slate-900 md:text-3xl">
            כניסה ל-VETO
          </h1>
          <p className="mt-2 text-sm leading-relaxed text-slate-700">
            חשבון אזרח: אימות OTP מול שרת VETO. בפיתוח ניתן להדביק JWT
            (<code className="rounded bg-white/50 px-1 text-xs">veto_jwt</code>
            ).
          </p>
        </div>

        <div className="mt-8 flex flex-col gap-4">
          <button
            type="button"
            onClick={handleGoogle}
            disabled={busy}
            className="flex w-full items-center justify-center gap-3 rounded-2xl border border-white/70 bg-white/90 px-4 py-3 text-sm font-semibold text-slate-800 shadow-sm transition hover:bg-white focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-slate-900 disabled:opacity-50"
          >
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
            המשך עם Google
          </button>

          <div className="relative py-2">
            <div
              className="absolute inset-0 flex items-center"
              aria-hidden
            >
              <div className="w-full border-t border-white/50" />
            </div>
            <div className="relative flex justify-center text-xs font-medium">
              <span className="bg-white/40 px-3 text-slate-600 backdrop-blur-sm rounded-full border border-white/40">
                או עם טלפון
              </span>
            </div>
          </div>
        </div>

        <div className="mt-2 flex flex-col gap-6">
          <div className="flex flex-col gap-2">
            <label className="text-xs font-medium text-slate-700">
              טלפון
            </label>
            <input
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              className="rounded-xl border border-white/60 bg-white/40 px-3 py-2.5 text-sm text-slate-900 outline-none ring-slate-900/10 placeholder:text-slate-500 focus:border-white focus:ring-2 focus:ring-slate-800/20"
              placeholder="+972..."
              autoComplete="tel"
            />
          </div>

          <div className="flex flex-wrap gap-2">
            <button
              type="button"
              disabled={busy || !phone.trim()}
              onClick={() => void handleOtpLogin()}
              className="rounded-xl border border-slate-800/15 bg-slate-900/90 px-4 py-2.5 text-sm font-semibold text-white shadow-md transition hover:bg-slate-900 disabled:opacity-50"
            >
              שלח קוד OTP
            </button>
          </div>

          <div className="flex flex-col gap-2">
            <label className="text-xs font-medium text-slate-700">קוד OTP</label>
            <input
              value={otp}
              onChange={(e) => setOtp(e.target.value)}
              className="rounded-xl border border-white/60 bg-white/40 px-3 py-2.5 text-sm text-slate-900 outline-none ring-slate-900/10 placeholder:text-slate-500 focus:border-white focus:ring-2 focus:ring-slate-800/20"
              placeholder="6 ספרות"
              autoComplete="one-time-code"
            />
            <button
              type="button"
              disabled={busy || !phone.trim() || !otp.trim()}
              onClick={() => void handleVerify()}
              className="mt-1 rounded-xl bg-emerald-700 px-4 py-2.5 text-sm font-semibold text-white shadow-md transition hover:bg-emerald-600 disabled:opacity-50"
            >
              אמת והמשך
            </button>
          </div>

          <div className="border-t border-white/40 pt-6">
            <label className="text-xs font-medium text-slate-700">
              פיתוח: הדבקת JWT
            </label>
            <textarea
              value={devToken}
              onChange={(e) => setDevToken(e.target.value)}
              rows={3}
              className="mt-2 w-full rounded-xl border border-white/60 bg-white/40 px-3 py-2 text-xs text-slate-900 outline-none focus:ring-2 focus:ring-slate-800/20"
              placeholder="eyJ..."
            />
            <button
              type="button"
              onClick={handleDevToken}
              className="mt-2 w-full rounded-xl border border-slate-800/20 bg-white/30 px-4 py-2.5 text-sm font-medium text-slate-800 transition hover:bg-white/50"
            >
              השתמש ב-JWT שהודבק
            </button>
          </div>

          {message && (
            <p className="text-center text-sm text-amber-900" role="status">
              {message}
            </p>
          )}
        </div>
      </main>
    </div>
  );
}
