"use client";

import { PayPalButtons, PayPalScriptProvider } from "@paypal/react-paypal-js";
import { useCallback, useState } from "react";
import { apiUrl, authFetch } from "@/api/apiClient";

type PayPalCheckoutProps = {
  amount?: string;
  onSuccess?: () => void;
};

async function readError(res: Response): Promise<string> {
  try {
    const data = (await res.json()) as { error?: string; message?: string };
    return data.error || data.message || `HTTP ${res.status}`;
  } catch {
    return `HTTP ${res.status}`;
  }
}

export default function PayPalCheckout({
  amount = "99.00",
  onSuccess,
}: PayPalCheckoutProps) {
  const [error, setError] = useState("");

  const createOrder = useCallback(async () => {
    setError("");
    const res = await authFetch(apiUrl("/api/billing/create-order"), {
      method: "POST",
      body: JSON.stringify({ amount }),
    });
    if (!res.ok) {
      const msg = await readError(res);
      setError(msg || "שגיאה ביצירת התשלום");
      throw new Error(msg);
    }
    const data = (await res.json()) as { id?: string };
    if (!data?.id) {
      setError("לא התקבל מזהה הזמנה מ-PayPal");
      throw new Error("Missing PayPal order id");
    }
    return data.id;
  }, [amount]);

  const onApprove = useCallback(
    async (data: { orderID?: string }) => {
      setError("");
      const orderID = data.orderID;
      if (!orderID) {
        setError("חסר מזהה הזמנה");
        return;
      }
      try {
        const res = await authFetch(apiUrl("/api/billing/capture-order"), {
          method: "POST",
          body: JSON.stringify({ orderID }),
        });
        const cap = (await res.json().catch(() => ({}))) as {
          status?: string;
          message?: string;
          error?: string;
        };
        if (!res.ok) {
          setError(
            (typeof cap.error === "string" && cap.error) ||
              (typeof cap.message === "string" && cap.message) ||
              "שגיאה באימות התשלום",
          );
          return;
        }
        if (cap.status === "COMPLETED") {
          onSuccess?.();
        } else {
          setError("התשלום לא הושלם במלואו");
        }
      } catch (e) {
        console.error(e);
        setError("שגיאה באימות התשלום");
      }
    },
    [onSuccess],
  );

  const clientId =
    process.env.NEXT_PUBLIC_PAYPAL_CLIENT_ID?.trim() || "";

  if (!clientId) {
    return (
      <div
        className="mx-auto w-full max-w-sm rounded-2xl border border-amber-500/30 bg-amber-500/10 px-4 py-3 text-center text-sm text-amber-200"
        dir="rtl"
      >
        חסר <code className="rounded bg-black/20 px-1">NEXT_PUBLIC_PAYPAL_CLIENT_ID</code>{" "}
        ב־env של הפרונט.
      </div>
    );
  }

  return (
    <div
      className="relative z-0 mx-auto w-full max-w-sm rounded-2xl border border-white/10 bg-white/5 p-4 shadow-[0_12px_40px_-20px_rgba(0,0,0,0.5)] backdrop-blur-xl"
      dir="rtl"
    >
      <PayPalScriptProvider
        options={{
          clientId,
          currency: "ILS",
          intent: "capture",
        }}
      >
        <PayPalButtons
          createOrder={createOrder}
          onApprove={onApprove}
          style={{
            layout: "vertical",
            shape: "pill",
            color: "gold",
            label: "pay",
          }}
        />
      </PayPalScriptProvider>
      {error ? (
        <p className="mt-3 text-center text-sm text-red-300" role="alert">
          {error}
        </p>
      ) : null}
    </div>
  );
}
