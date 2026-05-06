"use client";

import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import {
  fetchProfile,
  updateProfile,
  type UserProfile,
} from "@/api/userApi";
import { CitizenBottomNav } from "@/components/citizen/CitizenBottomNav";
import { clearJwt, getJwt } from "@/lib/authToken";
import { disconnectSocket } from "@/lib/socketClient";

export default function CitizenSettingsPage() {
  const router = useRouter();
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [notifySms, setNotifySms] = useState(false);
  const [notifyPush, setNotifyPush] = useState(true);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const hydrate = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const u = await fetchProfile();
      setProfile(u);
      setFullName(u.full_name ?? "");
      setEmail(u.email ?? "");
      setPhone(u.phone ?? "");
      setNotifySms(!!u.settings?.notifySms);
      setNotifyPush(u.settings?.notifyUpdates !== false);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not load profile");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (!getJwt()) {
      router.replace("/login");
      return;
    }
    void hydrate();
  }, [router, hydrate]);

  const handleSave = async () => {
    setSaving(true);
    setMessage(null);
    setError(null);
    try {
      const updated = await updateProfile({
        full_name: fullName.trim() || undefined,
        email: email.trim() || undefined,
        phone: phone.trim() || undefined,
        settings: {
          ...profile?.settings,
          notifySms,
          notifyUpdates: notifyPush,
        },
      });
      setProfile(updated);
      setMessage("Changes saved.");
    } catch (e) {
      setError(e instanceof Error ? e.message : "Save failed");
    } finally {
      setSaving(false);
    }
  };

  const handleLogout = () => {
    disconnectSocket();
    clearJwt();
    router.replace("/login");
  };

  return (
    <>
      <main className="mx-auto flex w-full max-w-lg flex-1 flex-col gap-6 px-4 py-8 pb-28">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight text-white">
            Settings
          </h1>
          <p className="mt-1 text-sm text-slate-400">
            Profile, alerts, and billing preferences.
          </p>
        </div>

        {loading ? (
          <div className="h-64 animate-pulse rounded-2xl bg-white/5" />
        ) : (
          <div className="flex flex-col gap-5">
            <section className="rounded-2xl border border-slate-200/80 bg-white p-5 shadow-sm">
              <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-500">
                Personal details
              </h2>
              <div className="mt-4 flex flex-col gap-3">
                <div>
                  <label className="mb-1 block text-xs font-medium text-slate-600">
                    Full name
                  </label>
                  <input
                    value={fullName}
                    onChange={(e) => setFullName(e.target.value)}
                    className="w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm text-slate-900 placeholder:text-slate-400 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                    placeholder="Your name"
                  />
                </div>
                <div>
                  <label className="mb-1 block text-xs font-medium text-slate-600">
                    Email
                  </label>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm text-slate-900 placeholder:text-slate-400 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                    placeholder="you@example.com"
                  />
                </div>
                <div>
                  <label className="mb-1 block text-xs font-medium text-slate-600">
                    Phone
                  </label>
                  <input
                    type="tel"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    className="w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm text-slate-900 placeholder:text-slate-400 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                    placeholder="+972501234567"
                  />
                </div>
              </div>
            </section>

            <section className="rounded-2xl border border-slate-200/80 bg-white p-5 shadow-sm">
              <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-500">
                Notifications
              </h2>
              <div className="mt-4 space-y-4">
                <div className="flex items-center justify-between gap-4">
                  <div>
                    <p className="text-sm font-medium text-slate-900">SMS</p>
                    <p className="text-xs text-slate-500">
                      Text messages for important updates
                    </p>
                  </div>
                  <button
                    type="button"
                    role="switch"
                    aria-checked={notifySms}
                    onClick={() => setNotifySms((v) => !v)}
                    className={`relative h-7 w-12 shrink-0 rounded-full transition ${
                      notifySms ? "bg-blue-600" : "bg-slate-200"
                    }`}
                  >
                    <span
                      className={`absolute top-0.5 left-0.5 h-6 w-6 rounded-full bg-white shadow transition ${
                        notifySms ? "translate-x-5" : "translate-x-0"
                      }`}
                    />
                  </button>
                </div>
                <div className="flex items-center justify-between gap-4 border-t border-slate-100 pt-4">
                  <div>
                    <p className="text-sm font-medium text-slate-900">
                      Push notifications
                    </p>
                    <p className="text-xs text-slate-500">
                      In-app and device alerts
                    </p>
                  </div>
                  <button
                    type="button"
                    role="switch"
                    aria-checked={notifyPush}
                    onClick={() => setNotifyPush((v) => !v)}
                    className={`relative h-7 w-12 shrink-0 rounded-full transition ${
                      notifyPush ? "bg-blue-600" : "bg-slate-200"
                    }`}
                  >
                    <span
                      className={`absolute top-0.5 left-0.5 h-6 w-6 rounded-full bg-white shadow transition ${
                        notifyPush ? "translate-x-5" : "translate-x-0"
                      }`}
                    />
                  </button>
                </div>
              </div>
            </section>

            <section className="rounded-2xl border border-slate-200/80 bg-white p-5 shadow-sm">
              <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-500">
                Billing & payments
              </h2>
              <p className="mt-2 text-sm text-slate-600">
                PayPal checkout will appear here for subscriptions and one-time
                payments.
              </p>
              <div className="mt-4 flex flex-col gap-3 rounded-xl border border-dashed border-slate-200 bg-slate-50/80 px-4 py-6 text-center">
                <span
                  className="text-xs font-bold tracking-widest text-slate-400"
                  aria-hidden
                >
                  PayPal
                </span>
                <p className="text-xs font-medium text-slate-500">
                  PayPal integration — coming soon
                </p>
                <button
                  type="button"
                  disabled
                  className="mx-auto inline-flex cursor-not-allowed items-center justify-center rounded-xl bg-slate-900 px-5 py-2.5 text-xs font-semibold text-white opacity-50"
                >
                  Connect PayPal
                </button>
              </div>
            </section>

            {error && (
              <p
                className="rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800"
                role="alert"
              >
                {error}
              </p>
            )}
            {message && (
              <p className="rounded-xl border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-900">
                {message}
              </p>
            )}

            <button
              type="button"
              onClick={() => void handleSave()}
              disabled={saving}
              className="w-full rounded-2xl bg-slate-900 py-3.5 text-sm font-semibold text-white shadow-lg transition hover:bg-slate-800 disabled:opacity-60"
            >
              {saving ? "Saving…" : "Save changes"}
            </button>

            <button
              type="button"
              onClick={handleLogout}
              className="w-full py-3 text-center text-sm font-semibold text-red-400 transition hover:text-red-300"
            >
              Log out
            </button>
          </div>
        )}
      </main>
      <CitizenBottomNav active="settings" />
    </>
  );
}
