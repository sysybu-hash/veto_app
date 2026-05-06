"use client";

import { useRouter } from "next/navigation";
import Script from "next/script";
import { useCallback, useEffect, useRef, useState } from "react";
import { getRoleFromJwt, setJwt } from "@/lib/authToken";
import { setSocketAuthToken } from "@/lib/socketClient";
import {
  apiUrl,
  isApiOriginConfigured,
  tunnelBypassHeaders,
} from "@/lib/env";
import {
  btnPrimaryDark,
  btnSecondaryGlass,
  glassInput,
  glassPanelNested,
} from "@/lib/vetoGlass";

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

function pickOtpFromResponse(data: Record<string, unknown>): string | null {
  const o = data.otp;
  const s = o == null ? "" : String(o).trim();
  return /^\d{4,8}$/.test(s) ? s : null;
}

function formatLoginError(e: unknown): string {
  const raw = e instanceof Error ? e.message : String(e);
  if (/Google OAuth not configured/i.test(raw)) {
    return "כניסה עם Google לא מוגדרת בשרת. הגדירו GOOGLE_CLIENT_ID ב-API (Render וכו׳).";
  }
  if (raw.includes("NEXT_PUBLIC_API_ORIGIN")) {
    return "חסרה הגדרת שרת: ב-Vercel → Environment Variables הגדירו NEXT_PUBLIC_API_ORIGIN לכתובת ה-API (HTTPS, בלי סיומת /api), ואז Redeploy.";
  }
  if (
    /failed to fetch|networkerror|load failed|connection refused|err_connection_refused/i.test(
      raw,
    )
  ) {
    return "לא ניתן להתחבר לשרת. ודאו ש-NEXT_PUBLIC_API_ORIGIN מצביע לשרת ה-API הפעיל (למשל Render), ש-CORS בשרת מאשר את דומיין האתר, והשרת רץ.";
  }
  if (raw === "No token in response") {
    return "אין אסימון בתשובת השרת. נסו שוב או בדקו לוגים.";
  }
  return raw;
}

type GoogleOAuthTokenResponse = {
  access_token?: string;
  error?: string;
  error_description?: string;
};

declare global {
  interface Window {
    google?: {
      accounts?: {
        oauth2?: {
          initTokenClient: (config: {
            client_id: string;
            scope: string;
            callback: (resp: GoogleOAuthTokenResponse) => void;
          }) => { requestAccessToken: (opts?: { prompt?: string }) => void };
        };
      };
    };
  }
}

export default function LoginPage() {
  const router = useRouter();
  const [phone, setPhone] = useState("");
  const [otp, setOtp] = useState("");
  const [devToken, setDevToken] = useState("");
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [devOtp, setDevOtp] = useState<string | null>(null);
  const [otpCopied, setOtpCopied] = useState(false);
  const [gsiLoaded, setGsiLoaded] = useState(false);

  const googleClientId =
    process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID?.trim() ?? "";
  const legacyGoogleLoginUrl =
    process.env.NEXT_PUBLIC_GOOGLE_LOGIN_URL?.trim() ?? "";

  const tokenClientRef = useRef<{
    requestAccessToken: (opts?: { prompt?: string }) => void;
  } | null>(null);

  const completeGoogleLogin = useCallback(
    async (accessToken: string) => {
      setBusy(true);
      setMessage(null);
      try {
        const data = await postJson("/api/auth/google", {
          access_token: accessToken,
        });
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
        setMessage(formatLoginError(e));
      } finally {
        setBusy(false);
      }
    },
    [router],
  );

  useEffect(() => {
    if (!gsiLoaded || !googleClientId) return;
    const oauth2 = window.google?.accounts?.oauth2;
    if (!oauth2) return;
    tokenClientRef.current = oauth2.initTokenClient({
      client_id: googleClientId,
      scope: "openid email profile",
      callback: (resp) => {
        if (resp.error) {
          const ephemeral =
            /popup_closed|access_denied|user_cancel/i.test(
              String(resp.error) + (resp.error_description ?? ""),
            );
          if (!ephemeral) {
            const detail = resp.error_description?.trim()
              ? `${resp.error}: ${resp.error_description}`
              : resp.error;
            setMessage(
              String(detail).includes("403") ||
                /blocked|disallowed_useragent/i.test(String(detail))
                ? "הדפדפן חסם את Google או שחסרה הרשאה. נסו שוב, התירו חלונות קופצים, או נסו דפדפן אחר."
                : `Google: ${detail}`,
            );
          }
          setBusy(false);
          return;
        }
        if (!resp.access_token) {
          setBusy(false);
          return;
        }
        void completeGoogleLogin(resp.access_token);
      },
    });
  }, [gsiLoaded, googleClientId, completeGoogleLogin]);

  const handleGoogle = () => {
    setMessage(null);
    if (legacyGoogleLoginUrl) {
      window.location.href = legacyGoogleLoginUrl;
      return;
    }
    if (!googleClientId) {
      setMessage(
        "חסר NEXT_PUBLIC_GOOGLE_CLIENT_ID — הוסיפו את מזהה לקוח ה-OAuth מהקונסול של Google (אותו GOOGLE_CLIENT_ID כמו בשרת), ואז npm run dev מחדש.",
      );
      return;
    }
    if (!tokenClientRef.current) {
      setMessage("טוען את Google… נסו שוב בעוד רגע.");
      return;
    }
    setBusy(true);
    tokenClientRef.current.requestAccessToken();
  };

  const handleOtpLogin = async () => {
    setBusy(true);
    setMessage(null);
    setDevOtp(null);
    setOtpCopied(false);
    try {
      const data = await postJson("/api/auth/request-otp", { phone });
      const returned = pickOtpFromResponse(data);
      if (returned) {
        setDevOtp(returned);
        setOtp(returned);
        setMessage(
          "הקוד הוחזר מהשרת (פיתוח או SMS לא מוגדר). אפשר להעתיק או לאמת למטה.",
        );
      } else {
        setMessage("נשלח קוד. בדקו את הטלפון או לוג שרת בפיתוח.");
      }
    } catch (e) {
      setMessage(formatLoginError(e));
    } finally {
      setBusy(false);
    }
  };

  const copyDevOtp = async () => {
    if (!devOtp) return;
    try {
      await navigator.clipboard.writeText(devOtp);
      setOtpCopied(true);
      window.setTimeout(() => setOtpCopied(false), 2000);
    } catch {
      setMessage("העתקה נכשלה — סמנו את הקוד ידנית.");
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
      setMessage(formatLoginError(e));
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
    <>
      <Script
        src="https://accounts.google.com/gsi/client"
        strategy="afterInteractive"
        onLoad={() => setGsiLoaded(true)}
      />
      <div className="flex min-h-screen w-full items-center justify-center px-4 py-12 md:px-6 md:py-16">
      <main
        className={`w-full max-w-md p-6 shadow-[0_24px_64px_rgba(15,23,42,0.15)] backdrop-blur-2xl md:p-8 ${glassPanelNested}`}
        dir="rtl"
      >
        <div className="text-center">
          {!isApiOriginConfigured() && (
            <div
              className="mb-4 rounded-xl border border-amber-600/80 bg-amber-100/95 px-3 py-2.5 text-xs font-semibold leading-snug text-amber-950 shadow-sm"
              role="alert"
            >
              חסר NEXT_PUBLIC_API_ORIGIN — ב-Vercel יש להגדיר את כתובת ה-API (למשל
              https://…onrender.com) ולבצע Redeploy.
            </div>
          )}
          <h1 className="font-display text-2xl font-semibold text-slate-900 md:text-3xl">
            כניסה ל-VETO
          </h1>
        </div>

        <div className="mt-8 flex flex-col gap-4">
          <button
            type="button"
            onClick={handleGoogle}
            disabled={busy}
            className={`flex w-full items-center justify-center gap-3 px-4 py-3 text-sm font-semibold shadow-sm transition focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-slate-900 disabled:opacity-50 ${btnSecondaryGlass}`}
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
              <span className="rounded-full border border-white/40 bg-white/45 px-3 py-0.5 text-slate-600 backdrop-blur-sm">
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
              onChange={(e) => {
                setPhone(e.target.value);
                setDevOtp(null);
                setOtpCopied(false);
              }}
              className={glassInput}
              placeholder="+972..."
              autoComplete="tel"
            />
          </div>

          <div className="flex flex-wrap gap-2">
            <button
              type="button"
              disabled={busy || !phone.trim()}
              onClick={() => void handleOtpLogin()}
              className={`px-4 py-2.5 text-sm font-semibold shadow-md ${btnPrimaryDark} disabled:opacity-50`}
            >
              שלח קוד OTP
            </button>
          </div>

          {devOtp && (
            <div
              className="rounded-2xl border border-amber-500/60 bg-amber-50/95 px-4 py-4 shadow-sm"
              role="region"
              aria-label="קוד OTP להדגמה"
            >
              <p className="text-center text-xs font-semibold text-amber-950">
                קוד OTP (הוצג מהשרת)
              </p>
              <div className="mt-3 flex flex-wrap items-center justify-center gap-3">
                <code
                  className={`min-w-[8.5rem] px-4 py-2 text-center text-2xl font-bold tracking-[0.35em] text-slate-900 shadow-inner ${glassPanelNested}`}
                  dir="ltr"
                >
                  {devOtp}
                </code>
                <button
                  type="button"
                  onClick={() => void copyDevOtp()}
                  className="rounded-xl bg-amber-600 px-4 py-2.5 text-sm font-bold text-white shadow transition hover:bg-amber-700"
                >
                  {otpCopied ? "הועתק" : "העתק"}
                </button>
              </div>
            </div>
          )}

          <div className="flex flex-col gap-2">
            <label className="text-xs font-medium text-slate-700">קוד OTP</label>
            <input
              value={otp}
              onChange={(e) => setOtp(e.target.value)}
              className={glassInput}
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
              className={`mt-2 resize-y ${glassInput} text-xs`}
              placeholder="eyJ..."
            />
            <button
              type="button"
              onClick={handleDevToken}
              className={`mt-2 w-full px-4 py-2.5 text-sm font-medium ${btnSecondaryGlass}`}
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
    </>
  );
}
