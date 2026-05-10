"use client";

import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { useCallback, useEffect, useRef, useState, Suspense } from "react";
import { getRoleFromJwt, prepareLoginSession } from "@/lib/authToken";
import { setSocketAuthToken } from "@/lib/socketClient";
import {
  apiUrl,
  isApiOriginConfigured,
  tunnelBypassHeaders,
} from "@/lib/env";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { normalizePhoneForVeto } from "@/lib/phone";
import {
  btnPrimaryDark,
  btnSecondaryGlass,
  glassInput,
  glassPanelNested,
} from "@/lib/vetoGlass";

type LoginRole = "admin" | "citizen" | "lawyer";

function routeByRole(router: ReturnType<typeof useRouter>, role: string | null) {
  if (role === "admin") {
    router.replace("/admin/dashboard");
  } else if (role === "lawyer") {
    router.replace("/dashboard");
  } else {
    router.replace("/hub");
  }
}

function routeAfterAuth(
  router: ReturnType<typeof useRouter>,
  data: Record<string, unknown>,
) {
  const role = getRoleFromJwt();
  const u = data.user as { onboarding_completed?: boolean } | undefined;
  if (role === "user" && u?.onboarding_completed !== true) {
    router.replace("/onboarding");
    return;
  }
  routeByRole(router, role);
}

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

function formatLoginError(
  e: unknown,
  t: (key: string) => string,
): string {
  const raw = e instanceof Error ? e.message : String(e);
  if (/Google OAuth not configured/i.test(raw)) {
    return t("login.errGoogleNotConfigured");
  }
  if (raw.includes("NEXT_PUBLIC_API_ORIGIN")) {
    return t("login.errMissingApiOriginConfig");
  }
  if (
    /failed to fetch|networkerror|load failed|connection refused|err_connection_refused/i.test(
      raw,
    )
  ) {
    return t("login.errNetwork");
  }
  if (raw === "No token in response") {
    return t("login.errNoToken");
  }
  if (/invalid or expired token/i.test(raw)) {
    return t("login.errNoToken");
  }
  if (/invalid phone number/i.test(raw)) {
    return t("login.errInvalidPhone");
  }
  return raw;
}

const GOOGLE_OAUTH_STATE_KEY = "veto_google_oauth_state";

/**
 * Must match exactly an entry under Google Cloud → OAuth → Authorized redirect URIs.
 * Always use the **current** browser origin + `/login` so Vercel previews / prod hosts match
 * (a stale `NEXT_PUBLIC_GOOGLE_OAUTH_REDIRECT_URI` for another domain causes redirect_uri_mismatch).
 */
function googleOAuthRedirectUri(): string {
  if (typeof window !== "undefined") {
    return new URL("/login", window.location.origin).href;
  }
  const fromEnv = process.env.NEXT_PUBLIC_GOOGLE_OAUTH_REDIRECT_URI?.trim();
  if (fromEnv) {
    try {
      return new URL("/login", new URL(fromEnv).origin).href;
    } catch {
      return fromEnv;
    }
  }
  return "http://localhost:3000/login";
}

function buildGoogleImplicitAuthUrl(
  clientId: string,
  redirectUri: string,
  state: string,
): string {
  const params = new URLSearchParams({
    client_id: clientId,
    redirect_uri: redirectUri,
    response_type: "token",
    scope: "openid email profile",
    include_granted_scopes: "true",
    prompt: "select_account",
    state,
  });
  return `https://accounts.google.com/o/oauth2/v2/auth?${params.toString()}`;
}

export default function LoginPage() {
  return (
    <Suspense
      fallback={
        <div className="flex min-h-screen items-center justify-center text-slate-400">
          …
        </div>
      }
    >
      <LoginPageInner />
    </Suspense>
  );
}

function LoginPageInner() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { t, locale } = useTranslation();
  const [phone, setPhone] = useState("");
  const [otp, setOtp] = useState("");
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [devOtp, setDevOtp] = useState<string | null>(null);
  const [otpCopied, setOtpCopied] = useState(false);
  const [devUsername, setDevUsername] = useState("");
  const [devPassword, setDevPassword] = useState("");
  const [devRole, setDevRole] = useState<LoginRole>("admin");
  const [adminLoginOpen, setAdminLoginOpen] = useState(false);
  const [autoOtpPhone, setAutoOtpPhone] = useState<string | null>(null);
  const autoOtpConsumedRef = useRef<string | null>(null);

  const googleClientId =
    process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID?.trim() ?? "";
  const legacyGoogleLoginUrl =
    process.env.NEXT_PUBLIC_GOOGLE_LOGIN_URL?.trim() ?? "";

  useEffect(() => {
    queueMicrotask(() => {
      const ph = searchParams.get("phone");
      if (ph) {
        try {
          setPhone(decodeURIComponent(ph));
        } catch {
          setPhone(ph);
        }
      }
      if (searchParams.get("registeredLawyer") === "1") {
        setMessage("הבקשה נשלחה. לאחר אימות טלפון ואישור מנהל ניתן יהיה להיכנס כעורך דין.");
        if (ph) {
          try {
            setAutoOtpPhone(decodeURIComponent(ph));
          } catch {
            setAutoOtpPhone(ph);
          }
        }
      } else if (searchParams.get("registered") === "1") {
        setMessage(t("register.success"));
        if (ph) {
          try {
            setAutoOtpPhone(decodeURIComponent(ph));
          } catch {
            setAutoOtpPhone(ph);
          }
        }
      }
    });
  }, [searchParams, t]);

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
        await prepareLoginSession(token);
        setSocketAuthToken(token);
        routeAfterAuth(router, data);
      } catch (e) {
        setMessage(formatLoginError(e, t));
      } finally {
        setBusy(false);
      }
    },
    [router, t],
  );

  useEffect(() => {
    if (typeof window === "undefined") return;
    const rawHash = window.location.hash.replace(/^#/, "");
    if (!rawHash) return;

    const params = new URLSearchParams(rawHash);
    const oauthError = params.get("error");
    const oauthDesc = params.get("error_description") ?? "";

    const clearHash = () => {
      window.history.replaceState(
        null,
        "",
        `${window.location.pathname}${window.location.search}`,
      );
    };

    if (oauthError) {
      clearHash();
      try {
        sessionStorage.removeItem(GOOGLE_OAUTH_STATE_KEY);
      } catch {
        /* ignore */
      }
      queueMicrotask(() => {
        if (/redirect_uri_mismatch/i.test(oauthError + oauthDesc)) {
          setMessage(t("login.errGoogleRedirectMismatch"));
          return;
        }
        setMessage(
          `${t("login.errGooglePrefix")} ${oauthDesc.trim() || oauthError}`,
        );
      });
      return;
    }

    const accessToken = params.get("access_token");
    const returnedState = params.get("state");
    if (!accessToken) return;

    let expectedState: string | null = null;
    try {
      expectedState = sessionStorage.getItem(GOOGLE_OAUTH_STATE_KEY);
      sessionStorage.removeItem(GOOGLE_OAUTH_STATE_KEY);
    } catch {
      expectedState = null;
    }

    clearHash();

    if (!returnedState || !expectedState || returnedState !== expectedState) {
      queueMicrotask(() => {
        setMessage(t("login.errGoogleOAuthState"));
      });
      return;
    }

    queueMicrotask(() => {
      void completeGoogleLogin(accessToken);
    });
  }, [completeGoogleLogin, t]);

  const handleGoogle = () => {
    setMessage(null);
    if (legacyGoogleLoginUrl) {
      window.location.href = legacyGoogleLoginUrl;
      return;
    }
    if (!googleClientId) {
      setMessage(t("login.errMissingGoogleClientId"));
      return;
    }
    const redirectUri = googleOAuthRedirectUri();
    const state =
      typeof crypto !== "undefined" && "randomUUID" in crypto
        ? crypto.randomUUID()
        : `${Date.now()}-${Math.random().toString(36).slice(2)}`;
    try {
      sessionStorage.setItem(GOOGLE_OAUTH_STATE_KEY, state);
    } catch {
      setMessage(t("login.errGoogleOAuthStorage"));
      return;
    }
    setBusy(true);
    window.location.assign(
      buildGoogleImplicitAuthUrl(googleClientId, redirectUri, state),
    );
  };

  const handleOtpLogin = async () => {
    const normalizedPhone = normalizePhoneForVeto(phone);
    if (!normalizedPhone) {
      setMessage(t("login.errInvalidPhone"));
      return;
    }
    setBusy(true);
    setMessage(null);
    setDevOtp(null);
    setOtpCopied(false);
    try {
      const data = await postJson("/api/auth/request-otp", {
        phone: normalizedPhone,
      });
      const returned = pickOtpFromResponse(data);
      if (returned) {
        setDevOtp(returned);
        setOtp(returned);
        setMessage(t("login.otpReturnedDev"));
      } else {
        setMessage(t("login.otpSent"));
      }
    } catch (e) {
      setMessage(formatLoginError(e, t));
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
      setMessage(t("login.copyFailed"));
    }
  };

  const handleVerify = async () => {
    const normalizedPhone = normalizePhoneForVeto(phone);
    if (!normalizedPhone) {
      setMessage(t("login.errInvalidPhone"));
      return;
    }
    setBusy(true);
    setMessage(null);
    try {
      const data = await postJson("/api/auth/verify-otp", {
        phone: normalizedPhone,
        otp,
      });
      const token = typeof data.token === "string" ? data.token : null;
      if (!token) throw new Error("No token in response");
      await prepareLoginSession(token);
      setSocketAuthToken(token);
      routeAfterAuth(router, data);
    } catch (e) {
      setMessage(formatLoginError(e, t));
    } finally {
      setBusy(false);
    }
  };

  useEffect(() => {
    if (!autoOtpPhone) return;
    if (autoOtpConsumedRef.current === autoOtpPhone) return;
    autoOtpConsumedRef.current = autoOtpPhone;
    const normalizedPhone = normalizePhoneForVeto(autoOtpPhone);
    if (!normalizedPhone) return;
    let cancelled = false;
    void (async () => {
      setBusy(true);
      try {
        const otpData = await postJson("/api/auth/request-otp", {
          phone: normalizedPhone,
        });
        if (cancelled) return;
        const returned = pickOtpFromResponse(otpData);
        if (!returned) {
          setOtp("");
          setMessage(t("login.otpSent"));
          return;
        }
        setDevOtp(returned);
        setOtp(returned);
        const verifyData = await postJson("/api/auth/verify-otp", {
          phone: normalizedPhone,
          otp: returned,
        });
        if (cancelled) return;
        const token =
          typeof verifyData.token === "string" ? verifyData.token : null;
        if (!token) throw new Error("No token in response");
        await prepareLoginSession(token);
        setSocketAuthToken(token);
        routeAfterAuth(router, verifyData);
      } catch (e) {
        if (!cancelled) setMessage(formatLoginError(e, t));
      } finally {
        if (!cancelled) setBusy(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [autoOtpPhone, router, t]);

  const handleTestCredentialsLogin = () => {
    void (async () => {
      setBusy(true);
      setMessage(null);
      try {
        const data = await postJson("/api/auth/dev-login", {
          username: devUsername.trim(),
          password: devPassword.trim(),
          role: devRole,
        });
        const token = typeof data.token === "string" ? data.token : null;
        if (!token) throw new Error("No token in response");
        await prepareLoginSession(token);
        setSocketAuthToken(token);
        routeAfterAuth(router, data);
      } catch (e) {
        setMessage(formatLoginError(e, t));
      } finally {
        setBusy(false);
      }
    })();
  };

  const openAdminLogin = () => {
    setAdminLoginOpen(true);
    setMessage(null);
  };

  const canRequestOtp = !busy;
  const canVerifyOtp = !!otp.trim() && !busy;

  return (
    <>
      <div className="flex min-h-screen w-full items-center justify-center px-4 py-12 md:px-6 md:py-16">
      <main
        className={`w-full max-w-md p-6 shadow-[0_24px_64px_rgba(15,23,42,0.15)] backdrop-blur-2xl md:p-8 ${glassPanelNested}`}
        dir={locale === "he" ? "rtl" : "ltr"}
      >
        <div className="text-center">
          <div className="mb-4">
            <button
              type="button"
              onClick={openAdminLogin}
              className={`px-4 py-2 text-sm font-bold ${btnPrimaryDark}`}
            >
              כניסת מנהל
            </button>
          </div>
          {!isApiOriginConfigured() && (
            <div
              className="mb-4 rounded-xl border border-amber-600/80 bg-amber-500/15 px-3 py-2.5 text-xs font-semibold leading-snug text-amber-200 shadow-sm"
              role="alert"
            >
              {t("login.alertMissingApiOrigin")}
            </div>
          )}
          <h1 className="font-display text-2xl font-semibold text-slate-100 md:text-3xl">
            {t("login.title")}
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
            {t("login.google")}
          </button>

          <div className="relative py-2">
            <div
              className="absolute inset-0 flex items-center"
              aria-hidden
            >
              <div className="w-full border-t border-white/10" />
            </div>
            <div className="relative flex justify-center text-xs font-medium">
              <span className="rounded-full border border-white/10 bg-white/[0.04] px-3 py-0.5 text-slate-400 backdrop-blur-sm">
                {t("login.orPhone")}
              </span>
            </div>
          </div>
        </div>

        <div className="mt-2 flex flex-col gap-6">
          <div className="flex flex-col gap-2">
            <label className="text-xs font-medium text-slate-300">
              {t("login.phone")}
            </label>
            <input
              value={phone}
              onChange={(e) => {
                setPhone(e.target.value);
                setDevOtp(null);
                setOtpCopied(false);
              }}
              className={glassInput}
              placeholder={t("login.phonePlaceholder")}
              autoComplete="tel"
            />
            <p className="text-center text-xs text-slate-400">
              {t("login.needRegister")}{" "}
              <Link
                href="/register"
                className="font-bold text-[#8a6d3d] underline underline-offset-2"
              >
                {t("login.registerLink")}
              </Link>
            </p>
          </div>

          <div className="flex flex-wrap gap-2">
            <button
              type="button"
              disabled={!canRequestOtp}
              onClick={() => void handleOtpLogin()}
              className={`px-4 py-2.5 text-sm font-semibold shadow-md ${btnPrimaryDark} disabled:opacity-50`}
            >
              {t("login.sendOtp")}
            </button>
          </div>

          {devOtp && (
            <div
              className="rounded-2xl border border-amber-500/30 bg-amber-500/10 px-4 py-4 shadow-sm"
              role="region"
              aria-label={t("login.otpDevAria")}
            >
              <p className="text-center text-xs font-semibold text-amber-200">
                {t("login.otpDevTitle")}
              </p>
              <div className="mt-3 flex flex-wrap items-center justify-center gap-3">
                <code
                  className={`min-w-[8.5rem] px-4 py-2 text-center text-2xl font-bold tracking-[0.35em] text-slate-100 shadow-inner ${glassPanelNested}`}
                  dir="ltr"
                >
                  {devOtp}
                </code>
                <button
                  type="button"
                  onClick={() => void copyDevOtp()}
                  className="rounded-xl bg-amber-600 px-4 py-2.5 text-sm font-bold text-white shadow transition hover:bg-amber-700"
                >
                  {otpCopied ? t("common.copied") : t("common.copy")}
                </button>
              </div>
            </div>
          )}

          <div className="flex flex-col gap-2">
            <label className="text-xs font-medium text-slate-300">
              {t("login.otpLabel")}
            </label>
            <input
              value={otp}
              onChange={(e) => setOtp(e.target.value)}
              className={glassInput}
              placeholder={t("login.otpPlaceholder")}
              autoComplete="one-time-code"
            />
            <button
              type="button"
              disabled={!canVerifyOtp}
              onClick={() => void handleVerify()}
              className="mt-1 rounded-xl bg-emerald-700 px-4 py-2.5 text-sm font-semibold text-white shadow-md transition hover:bg-emerald-600 disabled:opacity-50"
            >
              {t("login.verify")}
            </button>
          </div>

          {message && (
            <p className="text-center text-sm text-amber-200" role="status">
              {message}
            </p>
          )}
        </div>
      </main>

      {adminLoginOpen && (
        <div
          className="fixed inset-0 z-[120] flex items-center justify-center bg-slate-900/45 p-4"
          role="presentation"
          onMouseDown={(e) => {
            if (e.target === e.currentTarget) setAdminLoginOpen(false);
          }}
        >
          <div
            className={`w-full max-w-sm p-5 md:p-6 ${glassPanelNested}`}
            dir={locale === "he" ? "rtl" : "ltr"}
            role="dialog"
            aria-modal="true"
            aria-label="כניסת מנהל"
            onMouseDown={(e) => e.stopPropagation()}
          >
            <h3 className="text-lg font-bold text-slate-100">כניסת מנהל</h3>
            <p className="mt-1 text-xs text-slate-400">
              התחברות בדיקות עם שם משתמש וסיסמה ובחירת תפקיד.
            </p>

            <div className="mt-4 flex flex-col gap-2">
              <label className="text-xs font-medium text-slate-300">שם משתמש</label>
              <input
                value={devUsername}
                onChange={(e) => setDevUsername(e.target.value)}
                className={glassInput}
                autoComplete="username"
              />
            </div>

            <div className="mt-3 flex flex-col gap-2">
              <label className="text-xs font-medium text-slate-300">סיסמה</label>
              <input
                type="password"
                value={devPassword}
                onChange={(e) => setDevPassword(e.target.value)}
                className={glassInput}
                autoComplete="current-password"
              />
            </div>

            <div className="mt-3 flex flex-col gap-2">
              <label className="text-xs font-medium text-slate-300">כניסה כ</label>
              <select
                value={devRole}
                onChange={(e) => setDevRole(e.target.value as LoginRole)}
                className={glassInput}
              >
                <option value="admin">אדמין</option>
                <option value="citizen">אזרח</option>
                <option value="lawyer">עורך דין</option>
              </select>
            </div>

            <div className="mt-4 flex gap-2">
              <button
                type="button"
                onClick={() => setAdminLoginOpen(false)}
                className={`flex-1 px-4 py-2.5 text-sm ${btnSecondaryGlass}`}
              >
                ביטול
              </button>
              <button
                type="button"
                onClick={handleTestCredentialsLogin}
                className={`flex-1 px-4 py-2.5 text-sm font-bold ${btnPrimaryDark}`}
              >
                התחבר
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
    </>
  );
}
