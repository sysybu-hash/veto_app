"use client";

import Link from "next/link";
import { useCallback, useEffect, useMemo, useState } from "react";
import { Download, Eraser, FilePenLine, LogIn } from "lucide-react";
import {
  createPrivacyRequest,
  fetchPrivacyRequests,
  type PrivacyRequest,
} from "@/api/advancedApi";
import { CitizenBottomNav } from "@/components/citizen/CitizenBottomNav";
import { LinkButton } from "@/components/ui/primitives/LinkButton";
import { getJwt } from "@/lib/authToken";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import {
  btnSecondaryGlass,
  citizenBottomSafe,
  glassPanel,
  glassPanelNested,
} from "@/lib/vetoGlass";

export default function PrivacyRightsPage() {
  const { t, locale } = useTranslation();
  const [authed, setAuthed] = useState<boolean | null>(null);
  const [requests, setRequests] = useState<PrivacyRequest[]>([]);
  const [note, setNote] = useState("");
  const [busy, setBusy] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  const actions = useMemo(
    () =>
      [
        {
          type: "export" as const,
          title: t("privacyRightsPage.exportTitle"),
          body: t("privacyRightsPage.exportBody"),
          icon: Download,
        },
        {
          type: "delete" as const,
          title: t("privacyRightsPage.deleteTitle"),
          body: t("privacyRightsPage.deleteBody"),
          icon: Eraser,
        },
        {
          type: "correct" as const,
          title: t("privacyRightsPage.correctTitle"),
          body: t("privacyRightsPage.correctBody"),
          icon: FilePenLine,
        },
      ] as const,
    [t],
  );

  const typeLabel = useCallback(
    (type: PrivacyRequest["type"]) => {
      if (type === "export") return t("privacyRightsPage.typeExport");
      if (type === "delete") return t("privacyRightsPage.typeDelete");
      if (type === "correct") return t("privacyRightsPage.typeCorrect");
      return type;
    },
    [t],
  );

  const statusLabel = useCallback(
    (status: string) => {
      const key = status.toLowerCase();
      const map: Record<string, string> = {
        pending: t("privacyRightsPage.statusPending"),
        open: t("privacyRightsPage.statusOpen"),
        in_progress: t("privacyRightsPage.statusInProgress"),
        completed: t("privacyRightsPage.statusCompleted"),
        rejected: t("privacyRightsPage.statusRejected"),
        closed: t("privacyRightsPage.statusClosed"),
      };
      return map[key] ?? status;
    },
    [t],
  );

  const mapPrivacyError = useCallback(
    (raw: string) => {
      if (/not authenticated/i.test(raw)) return t("privacyRightsPage.errNeedLogin");
      if (/failed to fetch|networkerror/i.test(raw)) return t("privacyRightsPage.errNetwork");
      return raw;
    },
    [t],
  );

  const refresh = useCallback(() => {
    if (!getJwt()) {
      setAuthed(false);
      setRequests([]);
      return;
    }
    setAuthed(true);
    void fetchPrivacyRequests()
      .then(setRequests)
      .catch(() => setRequests([]));
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  const submit = async (type: PrivacyRequest["type"]) => {
    if (!getJwt()) {
      setMessage(t("privacyRightsPage.errNeedLogin"));
      setAuthed(false);
      return;
    }
    setBusy(type);
    setMessage(null);
    try {
      await createPrivacyRequest(type, note);
      setNote("");
      setMessage(t("privacyRightsPage.success"));
      refresh();
    } catch (e) {
      const raw = e instanceof Error ? e.message : t("privacyRightsPage.errSubmit");
      setMessage(mapPrivacyError(raw));
    } finally {
      setBusy(null);
    }
  };

  const dateLocale = locale === "en" ? "en-IL" : locale === "ru" ? "ru-RU" : "he-IL";

  return (
    <>
      <main className={`mx-auto w-full max-w-5xl px-4 py-10 text-end ${citizenBottomSafe}`}>
        <section className={`${glassPanel} p-6 md:p-8`}>
          <p className="text-sm font-bold text-veto-gold">{t("privacyRightsPage.eyebrow")}</p>
          <h1 className="mt-2 font-display text-3xl font-bold text-primary">
            {t("privacyRightsPage.title")}
          </h1>
          <p className="mt-3 max-w-3xl text-sm leading-7 text-secondary md:text-base">
            {t("privacyRightsPage.intro")}
          </p>
          <p className="mt-2 text-xs text-muted">
            {t("privacyRightsPage.moreInfo")}{" "}
            <Link href="/privacy" className="font-semibold text-veto-gold underline">
              {t("privacyRightsPage.privacyPolicy")}
            </Link>{" "}
            {t("privacyRightsPage.and")}{" "}
            <Link href="/contact" className="font-semibold text-veto-gold underline">
              {t("privacyRightsPage.contactPage")}
            </Link>
            .
          </p>

          {authed === false && (
            <div className="mt-6 rounded-2xl border border-veto-gold/40 bg-veto-gold/10 px-4 py-4 text-sm text-primary">
              <p className="font-semibold">{t("privacyRightsPage.needLoginTitle")}</p>
              <p className="mt-1 text-secondary">{t("privacyRightsPage.needLoginBody")}</p>
              <Link
                href="/login?redirect=%2Fprivacy-rights"
                className="mt-3 inline-flex items-center gap-2 rounded-xl bg-veto-gold px-4 py-2.5 text-sm font-bold text-primary"
              >
                <LogIn className="h-4 w-4" aria-hidden />
                {t("privacyRightsPage.loginCta")}
              </Link>
            </div>
          )}

          <textarea
            value={note}
            onChange={(e) => setNote(e.target.value)}
            placeholder={t("privacyRightsPage.notePlaceholder")}
            disabled={authed === false}
            className="mt-5 min-h-28 w-full rounded-2xl border border-subtle bg-surface-raised p-4 text-sm text-primary outline-none focus:ring-2 focus:ring-veto-gold disabled:opacity-60"
          />

          <div className="mt-4 grid gap-3 md:grid-cols-3">
            {actions.map((action) => {
              const Icon = action.icon;
              return (
                <button
                  key={action.type}
                  type="button"
                  onClick={() => void submit(action.type)}
                  disabled={busy !== null || authed === false}
                  className={`${btnSecondaryGlass} p-4 text-end disabled:opacity-50`}
                >
                  <Icon className="h-5 w-5 text-veto-gold" aria-hidden />
                  <span className="mt-3 block font-bold text-primary">{action.title}</span>
                  <span className="mt-1 block text-sm leading-6 text-secondary">
                    {action.body}
                  </span>
                </button>
              );
            })}
          </div>

          {message && (
            <p
              className="mt-4 rounded-2xl border border-subtle bg-surface-sunken px-4 py-3 text-sm text-primary"
              role="status"
            >
              {message}
            </p>
          )}

          <div className={`${glassPanelNested} mt-6 p-4`}>
            <h2 className="text-lg font-bold text-primary">
              {t("privacyRightsPage.recentTitle")}
            </h2>
            <div className="mt-4 space-y-3">
              {authed === false && (
                <p className="text-sm text-secondary">
                  {t("privacyRightsPage.recentAfterLogin")}
                </p>
              )}
              {authed && requests.length === 0 && (
                <p className="text-sm text-secondary">{t("privacyRightsPage.empty")}</p>
              )}
              {requests.map((request) => (
                <div
                  key={request._id}
                  className="flex items-center justify-between gap-3 rounded-2xl border border-subtle bg-surface-raised p-4"
                >
                  <div>
                    <p className="font-bold text-primary">{typeLabel(request.type)}</p>
                    <p className="text-xs text-secondary">
                      {new Intl.DateTimeFormat(dateLocale, {
                        dateStyle: "short",
                        timeStyle: "short",
                      }).format(new Date(request.createdAt))}
                    </p>
                    {request.note ? (
                      <p className="mt-1 text-xs text-muted">{request.note}</p>
                    ) : null}
                  </div>
                  <span className="rounded-full bg-veto-gold/15 px-3 py-1 text-xs font-bold text-veto-gold">
                    {statusLabel(request.status)}
                  </span>
                </div>
              ))}
            </div>
          </div>

          <div className="mt-5 flex flex-wrap gap-3">
            <LinkButton href="/transparency" variant="primary" size="md">
              {t("privacyRightsPage.transparency")}
            </LinkButton>
            <LinkButton href="/contact" variant="secondary" size="md">
              {t("privacyRightsPage.contact")}
            </LinkButton>
          </div>
        </section>
      </main>
      <CitizenBottomNav active="settings" />
    </>
  );
}
