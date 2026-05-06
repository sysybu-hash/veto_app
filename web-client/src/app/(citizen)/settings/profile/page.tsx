"use client";

import { glassInput, glassPanel, glassPanelNested } from "@/lib/vetoGlass";
import { useSettings } from "../_components/settings-context";

function initialsFromName(name: string): string {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return "?";
  if (parts.length === 1) return parts[0]!.slice(0, 2).toUpperCase();
  return (parts[0]![0]! + parts[parts.length - 1]![0]!).toUpperCase();
}

export default function SettingsProfilePage() {
  const { fullName, setFullName, email, setEmail, phone, setPhone } =
    useSettings();

  return (
    <div className="flex flex-col gap-5">
      <section className={`${glassPanel} p-5`}>
        <h2 className="font-frank text-lg font-bold text-slate-900">
          Profile
        </h2>
        <p className="font-heebo mt-1 text-sm text-slate-600">
          Your name and contact information.
        </p>

        <div className="mt-5 flex items-center gap-4">
          <div
            className={`flex h-16 w-16 shrink-0 items-center justify-center rounded-2xl border border-white/50 text-lg font-bold text-slate-900 shadow-sm ${glassPanelNested}`}
            aria-hidden
          >
            {initialsFromName(fullName)}
          </div>
          <p className="font-heebo min-w-0 text-sm text-slate-600">
            This is how you appear in VETO. Updates apply after you save.
          </p>
        </div>

        <div className="mt-6 flex flex-col gap-3">
          <div>
            <label
              htmlFor="settings-full-name"
              className="font-heebo mb-1 block text-xs font-semibold text-slate-700"
            >
              Full name
            </label>
            <input
              id="settings-full-name"
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              className={glassInput}
              placeholder="Your name"
              autoComplete="name"
            />
          </div>
          <div>
            <label
              htmlFor="settings-email"
              className="font-heebo mb-1 block text-xs font-semibold text-slate-700"
            >
              Email
            </label>
            <input
              id="settings-email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className={glassInput}
              placeholder="you@example.com"
              autoComplete="email"
            />
          </div>
          <div>
            <label
              htmlFor="settings-phone"
              className="font-heebo mb-1 block text-xs font-semibold text-slate-700"
            >
              Phone
            </label>
            <input
              id="settings-phone"
              type="tel"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              className={glassInput}
              placeholder="+972501234567"
              autoComplete="tel"
            />
          </div>
        </div>
      </section>
    </div>
  );
}
