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

  const handleOtpLogin = async () => {
    setBusy(true);
    setMessage(null);
    try {
      await postJson("/api/auth/request-otp", { phone });
      setMessage("OTP sent. Check your phone or server logs in dev.");
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
      setMessage("Paste a JWT first.");
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
    <main className="mx-auto flex min-h-full max-w-md flex-col gap-6 px-6 py-16 text-slate-100">
      <div>
        <h1 className="text-2xl font-semibold text-white">Sign in</h1>
        <p className="mt-2 text-sm text-slate-400">
          Citizen accounts use phone OTP against your VETO API. You can also
          paste a JWT for local development (stored as{" "}
          <code className="rounded bg-white/10 px-1">veto_jwt</code>).
        </p>
      </div>

      <div className="flex flex-col gap-2">
        <label className="text-xs font-medium text-slate-400">Phone</label>
        <input
          value={phone}
          onChange={(e) => setPhone(e.target.value)}
          className="rounded-xl border border-white/15 bg-white/5 px-3 py-2 text-sm outline-none focus:border-white/30"
          placeholder="+972..."
          autoComplete="tel"
        />
      </div>

      <div className="flex flex-wrap gap-2">
        <button
          type="button"
          disabled={busy || !phone.trim()}
          onClick={() => void handleOtpLogin()}
          className="rounded-xl bg-white/15 px-4 py-2 text-sm font-medium text-white hover:bg-white/20 disabled:opacity-50"
        >
          Request OTP
        </button>
      </div>

      <div className="flex flex-col gap-2">
        <label className="text-xs font-medium text-slate-400">OTP</label>
        <input
          value={otp}
          onChange={(e) => setOtp(e.target.value)}
          className="rounded-xl border border-white/15 bg-white/5 px-3 py-2 text-sm outline-none focus:border-white/30"
          placeholder="6-digit code"
          autoComplete="one-time-code"
        />
        <button
          type="button"
          disabled={busy || !phone.trim() || !otp.trim()}
          onClick={() => void handleVerify()}
          className="mt-1 rounded-xl bg-emerald-600 px-4 py-2 text-sm font-semibold text-white hover:bg-emerald-500 disabled:opacity-50"
        >
          Verify &amp; continue
        </button>
      </div>

      <div className="border-t border-white/10 pt-6">
        <label className="text-xs font-medium text-slate-400">
          Dev: paste JWT
        </label>
        <textarea
          value={devToken}
          onChange={(e) => setDevToken(e.target.value)}
          rows={3}
          className="mt-2 w-full rounded-xl border border-white/15 bg-white/5 px-3 py-2 text-xs outline-none focus:border-white/30"
          placeholder="eyJ..."
        />
        <button
          type="button"
          onClick={handleDevToken}
          className="mt-2 rounded-xl border border-white/20 bg-transparent px-4 py-2 text-sm text-white hover:bg-white/5"
        >
          Use pasted JWT
        </button>
      </div>

      {message && (
        <p className="text-sm text-amber-200" role="status">
          {message}
        </p>
      )}
    </main>
  );
}
