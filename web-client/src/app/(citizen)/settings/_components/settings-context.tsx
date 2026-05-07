"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { useRouter } from "next/navigation";
import {
  fetchProfile,
  updateProfile,
  type UserProfile,
} from "@/api/userApi";
import { getJwt } from "@/lib/authToken";
import { useTranslation } from "@/lib/i18n/LocaleProvider";

export type SettingsContextValue = {
  profile: UserProfile | null;
  fullName: string;
  setFullName: (v: string) => void;
  email: string;
  setEmail: (v: string) => void;
  phone: string;
  setPhone: (v: string) => void;
  notifySms: boolean;
  setNotifySms: (v: boolean | ((p: boolean) => boolean)) => void;
  notifyPush: boolean;
  setNotifyPush: (v: boolean | ((p: boolean) => boolean)) => void;
  loading: boolean;
  saving: boolean;
  message: string | null;
  error: string | null;
  save: () => Promise<void>;
  refresh: () => Promise<void>;
};

const SettingsContext = createContext<SettingsContextValue | null>(null);

export function useSettings(): SettingsContextValue {
  const ctx = useContext(SettingsContext);
  if (!ctx) throw new Error("useSettings must be used within SettingsProvider");
  return ctx;
}

export function SettingsProvider({ children }: { children: ReactNode }) {
  const router = useRouter();
  const { t } = useTranslation();
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

  const refresh = useCallback(async () => {
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
    queueMicrotask(() => {
      void refresh();
    });
  }, [router, refresh]);

  const save = useCallback(async () => {
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
      setMessage(t("settings.saved"));
    } catch (e) {
      setError(e instanceof Error ? e.message : "Save failed");
    } finally {
      setSaving(false);
    }
  }, [
    fullName,
    email,
    phone,
    notifySms,
    notifyPush,
    profile,
    t,
  ]);

  const value = useMemo<SettingsContextValue>(
    () => ({
      profile,
      fullName,
      setFullName,
      email,
      setEmail,
      phone,
      setPhone,
      notifySms,
      setNotifySms,
      notifyPush,
      setNotifyPush,
      loading,
      saving,
      message,
      error,
      save,
      refresh,
    }),
    [
      profile,
      fullName,
      email,
      phone,
      notifySms,
      notifyPush,
      loading,
      saving,
      message,
      error,
      save,
      refresh,
    ],
  );

  return (
    <SettingsContext.Provider value={value}>{children}</SettingsContext.Provider>
  );
}
