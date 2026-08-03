"use client";

import { LogIn } from "lucide-react";
import { apiUrl } from "@/api/apiClient";
import { LinkButton } from "@/components/ui/primitives/LinkButton";
import { useTranslation } from "@/lib/i18n/LocaleProvider";

type PayPalCheckoutProps = {
  amount?: string;
  isLoggedIn: boolean;
};

const CONTAINER_ID = "veto-paypal-button-container";
const ERROR_ID = "veto-paypal-button-error";
const SUCCESS_ID = "veto-paypal-button-success";

/**
 * Renders the PayPal buttons via a plain inline `<script>` instead of
 * `@paypal/react-paypal-js` (see prior comments in git history).
 */
export default function PayPalCheckout({
  amount = "99.00",
  isLoggedIn,
}: PayPalCheckoutProps) {
  const { t } = useTranslation();
  const clientId = process.env.NEXT_PUBLIC_PAYPAL_CLIENT_ID?.trim() || "";

  if (!clientId) {
    return (
      <div className="mx-auto w-full max-w-sm rounded-2xl border border-amber-500/40 bg-amber-500/10 px-4 py-4 text-center text-sm text-amber-950 dark:border-amber-500/30 dark:bg-amber-500/10 dark:text-amber-100">
        <p className="font-semibold leading-snug">{t("paypalUi.missingClientTitle")}</p>
        <p className="mt-2 text-xs leading-relaxed text-amber-900/80 dark:text-amber-200/85">
          {t("paypalUi.missingClientBody")}
        </p>
      </div>
    );
  }

  if (!isLoggedIn) {
    return (
      <div className="mx-auto w-full max-w-sm rounded-2xl border border-subtle bg-surface-raised-2 p-4 text-center shadow-[0_12px_40px_-20px_rgba(0,0,0,0.5)] backdrop-blur-xl">
        <LogIn className="mx-auto h-6 w-6 text-veto-gold-light" aria-hidden />
        <p className="mt-2 text-sm font-semibold text-primary">{t("paypalUi.needLoginTitle")}</p>
        <p className="mt-1 text-xs text-muted">{t("paypalUi.needLoginBody")}</p>
        <LinkButton
          href="/login?next=/pricing"
          variant="primary"
          size="sm"
          fullWidth
          className="mt-3"
        >
          {t("paypalUi.loginCta")}
        </LinkButton>
      </div>
    );
  }

  const createOrderUrl = apiUrl("/api/billing/create-order");
  const captureOrderUrl = apiUrl("/api/billing/capture-order");
  const successText = t("paypalUi.success");
  const errNoOrderId = t("paypalUi.errNoOrderId");
  const errCreate = t("paypalUi.errCreate");
  const errCapture = t("paypalUi.errCapture");
  const errIncomplete = t("paypalUi.errIncomplete");
  const errSdk = t("paypalUi.errSdk");

  return (
    <div className="relative z-0 mx-auto w-full max-w-sm rounded-2xl border border-subtle bg-surface-raised-2 p-4 shadow-[0_12px_40px_-20px_rgba(0,0,0,0.5)] backdrop-blur-xl">
      <p
        id={SUCCESS_ID}
        className="mb-3 hidden rounded-xl border border-emerald-500/40 bg-emerald-500/10 px-4 py-3 text-center text-sm font-medium text-emerald-900 dark:text-emerald-100"
        role="status"
      />
      <div id={CONTAINER_ID} />
      <p
        id={ERROR_ID}
        className="mt-3 hidden text-center text-sm text-red-300"
        role="alert"
      />
      <script
        async
        src={`https://www.paypal.com/sdk/js?client-id=${encodeURIComponent(clientId)}&currency=ILS&intent=capture`}
      />
      <script
        dangerouslySetInnerHTML={{
          __html: `
(function () {
  var createOrderUrl = ${JSON.stringify(createOrderUrl)};
  var captureOrderUrl = ${JSON.stringify(captureOrderUrl)};
  var amount = ${JSON.stringify(amount)};
  var successText = ${JSON.stringify(successText)};
  var errNoOrderId = ${JSON.stringify(errNoOrderId)};
  var errCreate = ${JSON.stringify(errCreate)};
  var errCapture = ${JSON.stringify(errCapture)};
  var errIncomplete = ${JSON.stringify(errIncomplete)};
  var errSdk = ${JSON.stringify(errSdk)};
  var containerId = ${JSON.stringify(CONTAINER_ID)};
  var errorId = ${JSON.stringify(ERROR_ID)};
  var successId = ${JSON.stringify(SUCCESS_ID)};

  function authHeaders() {
    var token = window.localStorage.getItem("veto_jwt") || "";
    return { "Content-Type": "application/json", Authorization: "Bearer " + token };
  }
  function showError(msg) {
    var el = document.getElementById(errorId);
    if (!el) return;
    el.textContent = msg;
    if (msg) el.classList.remove("hidden"); else el.classList.add("hidden");
  }
  function showSuccess() {
    var el = document.getElementById(successId);
    if (!el) return;
    el.textContent = successText;
    el.classList.remove("hidden");
    window.setTimeout(function () {
      window.location.href = "/vault/generator";
    }, 2500);
  }

  function render() {
    var container = document.getElementById(containerId);
    if (!container || !window.paypal || container.dataset.vetoRendered === "1") return;
    container.dataset.vetoRendered = "1";
    window.paypal.Buttons({
      style: { layout: "vertical", shape: "pill", color: "gold", label: "pay" },
      createOrder: function () {
        showError("");
        return fetch(createOrderUrl, {
          method: "POST",
          headers: authHeaders(),
          body: JSON.stringify({ amount: amount }),
        }).then(function (res) {
          return res.json().then(function (data) {
            if (!res.ok) throw new Error(data.error || data.message || ("HTTP " + res.status));
            if (!data.id) throw new Error(errNoOrderId);
            return data.id;
          });
        }).catch(function (e) {
          showError(e.message || errCreate);
          throw e;
        });
      },
      onApprove: function (data) {
        return fetch(captureOrderUrl, {
          method: "POST",
          headers: authHeaders(),
          body: JSON.stringify({ orderID: data.orderID }),
        }).then(function (res) {
          return res.json().catch(function () { return {}; }).then(function (cap) {
            if (!res.ok) throw new Error(cap.error || cap.message || errCapture);
            if (cap.status !== "COMPLETED") throw new Error(errIncomplete);
            showSuccess();
          });
        }).catch(function (e) {
          showError(e.message || errCapture);
        });
      },
    }).render(container);
  }

  if (window.paypal) {
    render();
  } else {
    var attempts = 0;
    var poll = window.setInterval(function () {
      attempts += 1;
      if (window.paypal) {
        window.clearInterval(poll);
        render();
      } else if (attempts > 200) {
        window.clearInterval(poll);
        showError(errSdk);
      }
    }, 100);
  }
})();
          `,
        }}
      />
    </div>
  );
}
