"use client";

import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useCallback, useEffect, useState } from "react";
import {
  captureSubscriptionPayment,
  canCapturePayment,
} from "@/api/paymentApi";
import {
  btnPrimaryDark,
  btnSecondaryGlass,
  glassPanelNested,
} from "@/lib/vetoGlass";
import { useTranslation } from "@/lib/i18n/LocaleProvider";

function PaymentReturnInner() {
  const { t, locale } = useTranslation();
  const router = useRouter();
  const searchParams = useSearchParams();
  const [status, setStatus] = useState<"working" | "ok" | "cancel" | "err">(
    "working",
  );
  const [detail, setDetail] = useState<string | null>(null);

  const runCapture = useCallback(
    async (orderId: string) => {
      if (!canCapturePayment()) {
        setStatus("err");
        setDetail(t("payments.returnNeedLogin"));
        return;
      }
      try {
        const type = (searchParams.get("type") ?? "subscription") as
          | "plan"
          | "subscription"
          | "consultation"
          | "overtime";
        const planParam = searchParams.get("planId");
        const planId =
          planParam === "standard" || planParam === "family"
            ? planParam
            : undefined;
        const eventId = searchParams.get("eventId") ?? undefined;
        const res = await captureSubscriptionPayment(orderId, type, planId, eventId);
        if (res.success) {
          setStatus("ok");
          if (type === "consultation") {
            window.setTimeout(() => router.replace("/hub"), 1500);
          } else if (type === "plan" || type === "subscription") {
            window.setTimeout(() => router.replace("/plans"), 1500);
          } else if (type === "overtime") {
            window.setTimeout(() => router.replace("/hub"), 1500);
          }
        } else {
          setStatus("err");
          setDetail(t("payments.returnCaptureFailed"));
        }
      } catch (e) {
        setStatus("err");
        setDetail(e instanceof Error ? e.message : t("payments.returnError"));
      }
    },
    [router, searchParams, t],
  );

  useEffect(() => {
    queueMicrotask(() => {
      const cancel = searchParams.get("cancel");
      const type = searchParams.get("type") ?? "subscription";
      const token =
        searchParams.get("subscription_id") ??
        searchParams.get("ba_token") ??
        searchParams.get("token") ??
        searchParams.get("PayerID") ??
        "";

      if (cancel === "1") {
        setStatus("cancel");
        return;
      }

      if (
        type !== "subscription" &&
        type !== "plan" &&
        type !== "consultation" &&
        type !== "overtime"
      ) {
        setStatus("ok");
        setDetail(t("payments.returnNonSubscription"));
        return;
      }

      if (!token) {
        setStatus("err");
        setDetail(t("payments.returnMissingToken"));
        return;
      }

      void runCapture(token);
    });
  }, [runCapture, searchParams, t]);

  return (
    <div
      className="flex min-h-screen items-center justify-center px-4 py-16"
      dir={locale === "he" ? "rtl" : "ltr"}
    >
      <main className={`w-full max-w-md p-6 md:p-8 ${glassPanelNested}`}>
        <h1 className="font-frank text-xl font-bold text-primary">
          {t("payments.returnTitle")}
        </h1>

        {status === "working" && (
          <p className="mt-4 text-sm text-secondary">
            {t("payments.returnWorking")}
          </p>
        )}
        {status === "ok" && (
          <p className="mt-4 text-sm text-emerald-700 dark:text-emerald-300">
            {t("payments.returnSuccess")}
          </p>
        )}
        {status === "cancel" && (
          <p className="mt-4 text-sm text-secondary">
            {t("payments.returnCancelled")}
          </p>
        )}
        {status === "err" && detail && (
          <p className="mt-4 text-sm text-red-700 dark:text-red-300" role="alert">
            {detail}
          </p>
        )}

        <div className="mt-8 flex flex-wrap gap-3">
          <Link
            href="/settings?tab=billing"
            className={`inline-flex px-4 py-2.5 text-sm font-semibold ${btnPrimaryDark}`}
          >
            {t("payments.returnBilling")}
          </Link>
          <Link
            href="/hub"
            className={`inline-flex px-4 py-2.5 text-sm font-semibold ${btnSecondaryGlass}`}
          >
            {t("payments.returnHub")}
          </Link>
          <Link
            href="/login"
            className={`inline-flex px-4 py-2.5 text-sm ${btnSecondaryGlass}`}
          >
            {t("payments.returnLogin")}
          </Link>
        </div>
      </main>
    </div>
  );
}

export default function PaymentReturnPage() {
  const { t } = useTranslation();
  return (
    <Suspense
      fallback={
        <div className="flex min-h-screen items-center justify-center p-8 text-secondary">
          {t("payments.returnWorking")}
        </div>
      }
    >
      <PaymentReturnInner />
    </Suspense>
  );
}
