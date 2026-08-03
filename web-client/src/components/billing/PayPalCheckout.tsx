"use client";

import { LogIn } from "lucide-react";
import { apiUrl } from "@/api/apiClient";
import { LinkButton } from "@/components/ui/primitives/LinkButton";

type PayPalCheckoutProps = {
  amount?: string;
  isLoggedIn: boolean;
};

const CONTAINER_ID = "veto-paypal-button-container";
const ERROR_ID = "veto-paypal-button-error";
const SUCCESS_ID = "veto-paypal-button-success";

/**
 * Renders the PayPal buttons via a plain inline `<script>` instead of
 * `@paypal/react-paypal-js` (or even `next/script`). Extensive A/B testing
 * against real production and local production builds found that on a hard
 * page load (F5, direct link, first visit — as opposed to an already-
 * hydrated SPA transition) the client-side effect responsible for loading
 * the PayPal SDK intermittently never runs at all — no console error,
 * roughly 50% of loads, reproduced with three different implementations
 * (the library's own script loader, a manual "mounted" useEffect flag, and
 * next/script's own onReady effect). The common failure mode across all
 * three: whatever mechanism depends on a React effect firing for this leaf
 * sometimes just doesn't, in this Next.js version.
 *
 * An inline `<script>` written directly into the server-rendered HTML has
 * no such dependency — the browser executes it while parsing the HTML
 * document itself, before hydration even starts, exactly like any other
 * static `<script>` tag on a plain page. It self-polls for `window.paypal`
 * via `setInterval` (a native timer, not tied to React's effect scheduler
 * at all) rather than relying on the SDK script's load event. On payment
 * success it updates the DOM directly and navigates via
 * `window.location.href` — the whole flow ends in a full navigation away
 * from this page anyway, so there's no need to round-trip back into React.
 *
 * Checkout also requires an existing session (create-order needs a Bearer
 * JWT to know which account to bill). Since /pricing is a public marketing
 * page, most visitors clicking "Standard" won't be logged in yet.
 * `isLoggedIn` comes from the server (PricingPage reads the `veto_jwt`
 * cookie during SSR — see `getVetoJwtFromCookies`), so the choice between
 * the login-gate and the real checkout is baked into the very first render
 * and hydrates identically — no client-side toggle, no chance of React's
 * hydration reverting a className it manages back to the SSR value (which
 * is exactly what broke an earlier version of this gate that tried to
 * flip a `classList` from inline JS). The gate's "continue" link carries
 * `?next=/pricing` through login so the visitor lands back here, already
 * authenticated, ready to pay.
 */
export default function PayPalCheckout({
  amount = "99.00",
  isLoggedIn,
}: PayPalCheckoutProps) {
  const clientId = process.env.NEXT_PUBLIC_PAYPAL_CLIENT_ID?.trim() || "";

  if (!clientId) {
    return (
      <div
        className="mx-auto w-full max-w-sm rounded-2xl border border-amber-500/40 bg-amber-500/10 px-4 py-4 text-center text-sm text-amber-950 dark:border-amber-500/30 dark:bg-amber-500/10 dark:text-amber-100"
        dir="rtl"
      >
        <p className="font-semibold leading-snug">
          תשלום PayPal אינו זמין בסביבה זו — חסר מזהה לקוח בפריסה.
        </p>
        <p className="mt-2 text-xs leading-relaxed text-amber-900/80 dark:text-amber-200/85">
          הוסיפו את משתנה הסביבה{" "}
          <code className="rounded bg-black/10 px-1 py-0.5 font-mono text-[11px] dark:bg-black/25">
            NEXT_PUBLIC_PAYPAL_CLIENT_ID
          </code>{" "}
          ב־Vercel / Render (או בקובץ env מקומי) והפעילו מחדש את הבנייה.
        </p>
      </div>
    );
  }

  if (!isLoggedIn) {
    return (
      <div
        className="mx-auto w-full max-w-sm rounded-2xl border border-subtle bg-surface-raised-2 p-4 text-center shadow-[0_12px_40px_-20px_rgba(0,0,0,0.5)] backdrop-blur-xl"
        dir="rtl"
      >
        <LogIn className="mx-auto h-6 w-6 text-veto-gold-light" aria-hidden />
        <p className="mt-2 text-sm font-semibold text-primary">
          כדי להשלים את התשלום צריך להתחבר או להירשם קודם
        </p>
        <p className="mt-1 text-xs text-muted">
          זה לוקח פחות מדקה — אחרי ההתחברות תחזרו לכאן ותוכלו להמשיך בתשלום.
        </p>
        <LinkButton
          href="/login?next=/pricing"
          variant="primary"
          size="sm"
          fullWidth
          className="mt-3"
        >
          התחברות / הרשמה
        </LinkButton>
      </div>
    );
  }

  const createOrderUrl = apiUrl("/api/billing/create-order");
  const captureOrderUrl = apiUrl("/api/billing/capture-order");
  const successText =
    "המנוי הופעל בהצלחה! מעביר אותך למחולל המסמכים של VETO...";

  return (
    <div
      className="relative z-0 mx-auto w-full max-w-sm rounded-2xl border border-subtle bg-surface-raised-2 p-4 shadow-[0_12px_40px_-20px_rgba(0,0,0,0.5)] backdrop-blur-xl"
      dir="rtl"
    >
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
            if (!data.id) throw new Error("לא התקבל מזהה הזמנה מ-PayPal");
            return data.id;
          });
        }).catch(function (e) {
          showError(e.message || "שגיאה ביצירת התשלום");
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
            if (!res.ok) throw new Error(cap.error || cap.message || "שגיאה באימות התשלום");
            if (cap.status !== "COMPLETED") throw new Error("התשלום לא הושלם במלואו");
            showSuccess();
          });
        }).catch(function (e) {
          showError(e.message || "שגיאה באימות התשלום");
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
        showError("שגיאה בטעינת PayPal — נסו לרענן את הדף");
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
