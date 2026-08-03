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
  beginGoogleImplicitLogin,
  GOOGLE_OAUTH_STATE_KEY,
} from "@/lib/googleOAuth";
import { loginWithPasskey, passkeysSupported } from "@/api/passkeyApi";
import { OtpInput } from "@/components/auth/OtpInput";
import { authGlassInput, authGlassPanel } from "@/lib/vetoGlass";
import { Fingerprint } from "lucide-react";
import { Button } from "@/components/ui/primitives/Button";

/**
 * Only a same-origin relative path is a safe redirect target — reject
 * anything else (protocol-relative "//evil.com", absolute URLs) to avoid an
 * open-redirect via the `next` query param.
 */
function safeNextPath(next: string | null): string | null {
  if (!next || !next.startsWith("/") || next.startsWith("//")) return null;
  return next;
}

function routeByRole(
  router: ReturnType<typeof useRouter>,
  role: string | null,
  next?: string | null,
) {
  if (role === "admin") {
    router.replace("/admin/dashboard");
  } else if (role === "lawyer") {
    router.replace("/dashboard");
  } else {
    router.replace(next || "/hub");
  }
}

function routeAfterAuth(
  router: ReturnType<typeof useRouter>,
  data: Record<string, unknown>,
  next?: string | null,
) {
  const role = getRoleFromJwt();
  const u = data.user as { onboarding_completed?: boolean } | undefined;
  if (role === "user" && u?.onboarding_completed !== true) {
    router.replace("/onboarding");
    return;
  }
  routeByRole(router, role, next);
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
    const code = typeof data?.code === "string" ? data.code : "";
    throw new Error(code ? `${code}: ${err}` : err);
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
  if (
    /no account found|please register first/i.test(raw)
  ) {
    return t("login.errNoAccount");
  }
  if (
    /DUPLICATE_EMAIL|google email already exists|with this email already exists/i.test(
      raw,
    )
  ) {
    return t("login.errEmailExists");
  }
  if (
    /DUPLICATE_PHONE|with this phone already exists|account with this phone/i.test(
      raw,
    )
  ) {
    return t("login.errPhoneExists");
  }
  if (/already exists/i.test(raw)) {
    return t("login.errAccountExists");
  }
  return raw;
}

export default function LoginPage() {
  return (
    <Suspense
      fallback={
        <div className="flex min-h-screen items-center justify-center text-muted">
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
  // "next" is set by explicit login links (e.g. the /pricing login gate);
  // "redirect" is set automatically by proxy.ts for any protected route
  // an anonymous visitor lands on directly. Honor whichever is present so a
  // visitor's original destination survives login either way.
  const nextParam = safeNextPath(
    searchParams.get("next") ?? searchParams.get("redirect"),
  );
  const { t, locale } = useTranslation();
  const [phone, setPhone] = useState("");
  const [otp, setOtp] = useState("");
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [devOtp, setDevOtp] = useState<string | null>(null);
  const [otpCopied, setOtpCopied] = useState(false);
  const [autoOtpPhone, setAutoOtpPhone] = useState<string | null>(null);
  const autoOtpConsumedRef = useRef<string | null>(null);
  const [resendCooldown, setResendCooldown] = useState(0);
  const [allowOtpResend, setAllowOtpResend] = useState(false);

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
      if (searchParams.get("registeredLawyer") === "1") {
        setMessage(
          "הבקשה נשלחה. החשבון יופעל לאחר אישור המנהל — תקבלו עדכון בטלפון.",
        );
      }
    });
  }, [searchParams, t]);

  useEffect(() => {
    if (resendCooldown <= 0) return;
    const tmr = window.setInterval(() => {
      setResendCooldown((s) => Math.max(0, s - 1));
    }, 1000);
    return () => window.clearInterval(tmr);
  }, [resendCooldown]);

  const completeGoogleLogin = useCallback(
    async (accessToken: string, oauthNext?: string | null) => {
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
        routeAfterAuth(router, data, oauthNext ?? nextParam);
      } catch (e) {
        setMessage(formatLoginError(e, t));
      } finally {
        setBusy(false);
      }
    },
    [router, t, nextParam],
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
    let storedNext: string | null = null;
    try {
      const raw = sessionStorage.getItem(GOOGLE_OAUTH_STATE_KEY);
      sessionStorage.removeItem(GOOGLE_OAUTH_STATE_KEY);
      if (raw) {
        try {
          const parsed = JSON.parse(raw) as { state?: string; next?: string | null };
          expectedState = parsed.state ?? null;
          storedNext = safeNextPath(parsed.next ?? null);
        } catch {
          // Pre-existing sessionStorage entry from before `next` support was
          // added — it's a bare state string, not JSON.
          expectedState = raw;
        }
      }
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
      void completeGoogleLogin(accessToken, storedNext);
    });
  }, [completeGoogleLogin, t]);

  const handleGoogle = () => {
    setMessage(null);
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

  const handlePasskeyLogin = useCallback(async () => {
    const normalizedPhone = normalizePhoneForVeto(phone);
    if (!normalizedPhone) {
      setMessage(t("login.errInvalidPhone"));
      return;
    }
    setBusy(true);
    setMessage(null);
    try {
      const data = await loginWithPasskey(normalizedPhone);
      await prepareLoginSession(data.token);
      setSocketAuthToken(data.token);
      routeAfterAuth(router, data as Record<string, unknown>, nextParam);
    } catch (e) {
      setMessage(e instanceof Error ? e.message : "לא ניתן להיכנס עם Passkey כרגע.");
    } finally {
      setBusy(false);
    }
  }, [phone, router, t, nextParam]);

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
      setAllowOtpResend(true);
      setResendCooldown(60);
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
      const code = otp.replace(/\D/g, "").slice(0, 6);
      const data = await postJson("/api/auth/verify-otp", {
        phone: normalizedPhone,
        otp: code,
      });
      const token = typeof data.token === "string" ? data.token : null;
      if (!token) throw new Error("No token in response");
      await prepareLoginSession(token);
      setSocketAuthToken(token);
      routeAfterAuth(router, data, nextParam);
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
        routeAfterAuth(router, verifyData, nextParam);
      } catch (e) {
        if (!cancelled) setMessage(formatLoginError(e, t));
      } finally {
        if (!cancelled) setBusy(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [autoOtpPhone, router, t, nextParam]);

  const canRequestOtp = !busy;
  const otpDigits = otp.replace(/\D/g, "");
  const canVerifyOtp = otpDigits.length === 6 && !busy;

  return (
    <>
      <div className="flex min-h-screen w-full items-center justify-center bg-surface-canvas px-4 py-12 md:px-6 md:py-16">
      <main
        className={`w-full max-w-md p-6 md:p-8 ${authGlassPanel}`}
        dir={locale === "he" ? "rtl" : "ltr"}
      >
        <div className="text-center">
          {!isApiOriginConfigured() && (
            <div
              className="mb-4 rounded-xl border border-amber-600/80 bg-amber-500/15 px-3 py-2.5 text-xs font-semibold leading-snug text-amber-200 shadow-sm"
              role="alert"
            >
              {t("login.alertMissingApiOrigin")}
            </div>
          )}
          <h1 className="font-display text-2xl font-semibold text-primary md:text-3xl">
            {t("login.title")}
          </h1>
        </div>

        <div className="mt-8 flex flex-col gap-4">
          <Button variant="secondary" size="lg" fullWidth onClick={handleGoogle} disabled={busy}>
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
          </Button>

          <div className="relative py-2">
            <div
              className="absolute inset-0 flex items-center"
              aria-hidden
            >
              <div className="w-full border-t border-subtle" />
            </div>
            <div className="relative flex justify-center text-xs font-medium">
              <span className="rounded-full border border-subtle bg-white/[0.06] px-3 py-0.5 text-muted backdrop-blur-sm">
                {t("login.orPhone")}
              </span>
            </div>
          </div>
        </div>

        <div className="mt-4">
          <Button
            variant="secondary"
            size="lg"
            fullWidth
            disabled={busy || !phone.trim() || !passkeysSupported()}
            onClick={() => void handlePasskeyLogin()}
            iconStart={<Fingerprint className="h-6 w-6 shrink-0" aria-hidden />}
          >
            כניסה מהירה עם Passkey (טביעת אצבע / פנים)
          </Button>
          {!passkeysSupported() && (
            <p className="mt-2 text-center text-xs text-muted">
              הדפדפן אינו תומך ב-Passkeys. השתמשו בקוד SMS.
            </p>
          )}
        </div>

        <div className="relative py-3">
          <div className="absolute inset-0 flex items-center" aria-hidden>
            <div className="w-full border-t border-subtle" />
          </div>
          <div className="relative flex justify-center text-xs font-medium">
            <span className="rounded-full border border-subtle bg-white/[0.06] px-3 py-0.5 text-muted backdrop-blur-sm">
              או קוד ב-SMS
            </span>
          </div>
        </div>

        <div className="mt-2 flex flex-col gap-6">
          <div className="flex flex-col gap-2">
            <label className="text-xs font-medium text-secondary">
              {t("login.phone")}
            </label>
            <input
              value={phone}
              onChange={(e) => {
                setPhone(e.target.value);
                setDevOtp(null);
                setOtpCopied(false);
                setAllowOtpResend(false);
                setResendCooldown(0);
              }}
              className={authGlassInput}
              placeholder={t("login.phonePlaceholder")}
              autoComplete="tel"
            />
            <p className="text-center text-sm text-secondary">
              {t("login.needRegister")}{" "}
              <Link
                href="/register"
                className="font-semibold text-veto-gold underline underline-offset-2 hover:text-veto-gold/90"
              >
                {t("login.registerLink")}
              </Link>
            </p>
          </div>

          <Button variant="primary" size="lg" fullWidth disabled={!canRequestOtp} onClick={() => void handleOtpLogin()}>
            {t("login.sendOtp")}
          </Button>

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
                  className="min-w-[8.5rem] rounded-xl border border-subtle bg-white/[0.06] px-4 py-2 text-center text-2xl font-bold tracking-[0.35em] text-primary shadow-inner backdrop-blur-md"
                  dir="ltr"
                >
                  {devOtp}
                </code>
                <Button
                  variant="primary"
                  onClick={() => void copyDevOtp()}
                  className="bg-amber-600 hover:bg-amber-700"
                >
                  {otpCopied ? t("common.copied") : t("common.copy")}
                </Button>
              </div>
            </div>
          )}

          <div className="flex flex-col gap-2">
            <label className="text-xs font-medium text-secondary">
              {t("login.otpLabel")}
            </label>
            <OtpInput
              value={otp}
              onChange={setOtp}
              disabled={busy}
              resendCooldown={allowOtpResend ? resendCooldown : 0}
              resendBusy={busy}
              onResend={
                allowOtpResend ? () => void handleOtpLogin() : undefined
              }
            />
            <Button
              variant="primary"
              fullWidth
              className="mt-1 bg-emerald-700 text-inverse hover:bg-emerald-600"
              disabled={!canVerifyOtp}
              onClick={() => void handleVerify()}
            >
              {t("login.verify")}
            </Button>
          </div>

          {message && (
            <p className="text-center text-sm text-amber-200" role="status">
              {message}
            </p>
          )}
        </div>
      </main>
    </div>
    </>
  );
}
