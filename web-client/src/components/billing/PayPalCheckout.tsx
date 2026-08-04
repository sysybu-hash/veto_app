"use client";

import { useEffect, useId, useRef, useState, useSyncExternalStore } from "react";
import Link from "next/link";
import { LogIn } from "lucide-react";
import { apiUrl } from "@/api/apiClient";
import { getJwt, syncJwtCookieFromStorage } from "@/lib/authToken";
import { useTranslation } from "@/lib/i18n/LocaleProvider";

type PayPalCheckoutProps = {
  amount?: string;
  isLoggedIn: boolean;
};

type PaypalNamespace = {
  Buttons: (config: Record<string, unknown>) => { render: (el: HTMLElement) => Promise<void> };
};

declare global {
  interface Window {
    paypal?: PaypalNamespace;
  }
}

function subscribeJwt(): () => void {
  // JWT changes via login navigation / full reload; no live subscription needed.
  return () => undefined;
}

function readClientHasJwt(): boolean {
  return !!getJwt();
}

function loadPaypalSdk(clientId: string): Promise<PaypalNamespace> {
  if (typeof window === "undefined") {
    return Promise.reject(new Error("no window"));
  }
  if (window.paypal) return Promise.resolve(window.paypal);

  const existing = document.querySelector<HTMLScriptElement>(
    'script[data-veto-paypal-sdk="1"]',
  );
  if (existing) {
    return new Promise((resolve, reject) => {
      const started = Date.now();
      const poll = window.setInterval(() => {
        if (window.paypal) {
          window.clearInterval(poll);
          resolve(window.paypal);
        } else if (Date.now() - started > 20000) {
          window.clearInterval(poll);
          reject(new Error("sdk timeout"));
        }
      }, 100);
    });
  }

  return new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.src = `https://www.paypal.com/sdk/js?client-id=${encodeURIComponent(clientId)}&currency=ILS&intent=capture`;
    script.async = true;
    script.dataset.vetoPaypalSdk = "1";
    script.onload = () => {
      if (window.paypal) resolve(window.paypal);
      else reject(new Error("sdk missing"));
    };
    script.onerror = () => reject(new Error("sdk load failed"));
    document.body.appendChild(script);
  });
}

/**
 * PayPal Standard checkout for the featured ₪99 plan.
 * Loads the SDK via useEffect (inline <script> in client components is unreliable in Next).
 */
export default function PayPalCheckout({
  amount = "99.00",
  isLoggedIn: isLoggedInProp,
}: PayPalCheckoutProps) {
  const { t } = useTranslation();
  const clientId = process.env.NEXT_PUBLIC_PAYPAL_CLIENT_ID?.trim() || "";
  const reactId = useId().replace(/:/g, "");
  const containerId = `veto-paypal-btn-${reactId}`;
  const containerRef = useRef<HTMLDivElement | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [ready, setReady] = useState(false);
  const clientHasJwt = useSyncExternalStore(
    subscribeJwt,
    readClientHasJwt,
    () => false,
  );
  const isLoggedIn = isLoggedInProp || clientHasJwt;

  useEffect(() => {
    syncJwtCookieFromStorage();
  }, []);

  useEffect(() => {
    if (!isLoggedIn || !clientId) return;
    let cancelled = false;
    let rendered = false;

    const run = async () => {
      setError(null);
      try {
        const paypal = await loadPaypalSdk(clientId);
        if (cancelled || rendered) return;
        const container = containerRef.current;
        if (!container) return;
        rendered = true;
        await paypal
          .Buttons({
            style: { layout: "vertical", shape: "pill", color: "gold", label: "pay" },
            createOrder: () => {
              setError(null);
              const token = getJwt() || "";
              return fetch(apiUrl("/api/billing/create-order"), {
                method: "POST",
                headers: {
                  "Content-Type": "application/json",
                  Authorization: `Bearer ${token}`,
                },
                body: JSON.stringify({ amount }),
              }).then(async (res) => {
                const data = (await res.json().catch(() => ({}))) as {
                  id?: string;
                  error?: string;
                  message?: string;
                };
                if (!res.ok) {
                  throw new Error(data.error || data.message || `HTTP ${res.status}`);
                }
                if (!data.id) throw new Error(t("paypalUi.errNoOrderId"));
                return data.id;
              });
            },
            onApprove: (data: { orderID: string }) => {
              const token = getJwt() || "";
              return fetch(apiUrl("/api/billing/capture-order"), {
                method: "POST",
                headers: {
                  "Content-Type": "application/json",
                  Authorization: `Bearer ${token}`,
                },
                body: JSON.stringify({ orderID: data.orderID }),
              }).then(async (res) => {
                const cap = (await res.json().catch(() => ({}))) as {
                  status?: string;
                  error?: string;
                  message?: string;
                };
                if (!res.ok) {
                  throw new Error(cap.error || cap.message || t("paypalUi.errCapture"));
                }
                if (cap.status !== "COMPLETED") {
                  throw new Error(t("paypalUi.errIncomplete"));
                }
                setSuccess(t("paypalUi.success"));
                window.setTimeout(() => {
                  window.location.href = "/vault/generator";
                }, 2500);
              });
            },
            onError: () => {
              setError(t("paypalUi.errCreate"));
            },
          })
          .render(container);
        if (!cancelled) setReady(true);
      } catch (e) {
        if (!cancelled) {
          setError(e instanceof Error && e.message ? e.message : t("paypalUi.errSdk"));
        }
      }
    };

    void run();
    return () => {
      cancelled = true;
    };
  }, [amount, clientId, isLoggedIn, t]);

  if (!clientId) {
    return (
      <div className="rounded-xl border border-amber-500/40 bg-amber-500/10 px-4 py-4 text-center text-sm text-amber-950 dark:text-amber-100">
        <p className="font-semibold leading-snug">{t("paypalUi.missingClientTitle")}</p>
        <p className="mt-2 text-xs leading-relaxed opacity-90">{t("paypalUi.missingClientBody")}</p>
      </div>
    );
  }

  if (!isLoggedIn) {
    return (
      <div className="space-y-2">
        <Link
          href="/login?next=/pricing"
          className="inline-flex w-full items-center justify-center gap-2 rounded-xl border border-subtle bg-surface-raised px-5 py-3 text-sm font-black text-primary transition hover:bg-surface-overlay"
        >
          <LogIn className="h-4 w-4" aria-hidden />
          {t("paypalUi.loginCta")}
        </Link>
        <p className="text-center text-xs leading-5 text-muted">{t("paypalUi.needLoginBody")}</p>
      </div>
    );
  }

  return (
    <div className="space-y-3">
      {success ? (
        <p
          className="rounded-xl border border-emerald-500/40 bg-emerald-500/10 px-4 py-3 text-center text-sm font-medium text-emerald-900 dark:text-emerald-100"
          role="status"
        >
          {success}
        </p>
      ) : null}
      <div
        id={containerId}
        ref={containerRef}
        className="min-h-[48px] w-full"
        aria-busy={!ready && !error}
      />
      {!ready && !error && !success ? (
        <p className="text-center text-xs text-muted">{t("paypalUi.loading")}</p>
      ) : null}
      {error ? (
        <p className="text-center text-sm text-red-600 dark:text-red-300" role="alert">
          {error}
        </p>
      ) : null}
    </div>
  );
}
