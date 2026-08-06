"use client";

import { useMemo, useState } from "react";
import { useTranslation } from "@/lib/i18n/LocaleProvider";

type Props = {
  supportEmail: string;
};

type SubjectId = "support" | "billing" | "privacy" | "lawyer" | "other";

export function ContactForm({ supportEmail }: Props) {
  const { t } = useTranslation();
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [subjectId, setSubjectId] = useState<SubjectId>("support");
  const [message, setMessage] = useState("");
  const [status, setStatus] = useState<string | null>(null);

  const subjects = useMemo(
    () =>
      [
        { id: "support" as const, label: t("contactPage.subjectSupport") },
        { id: "billing" as const, label: t("contactPage.subjectBilling") },
        { id: "privacy" as const, label: t("contactPage.subjectPrivacy") },
        { id: "lawyer" as const, label: t("contactPage.subjectLawyer") },
        { id: "other" as const, label: t("contactPage.subjectOther") },
      ] as const,
    [t],
  );

  const subjectLabel = useMemo(
    () => subjects.find((s) => s.id === subjectId)?.label ?? t("contactPage.subjectFallback"),
    [subjectId, subjects, t],
  );

  const onSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setStatus(null);
    if (!name.trim() || !email.trim() || !message.trim()) {
      setStatus(t("contactPage.errRequired"));
      return;
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) {
      setStatus(t("contactPage.errEmail"));
      return;
    }

    const body = [
      `${t("contactPage.bodyName")}: ${name.trim()}`,
      `${t("contactPage.bodyReplyEmail")}: ${email.trim()}`,
      `${t("contactPage.bodySubject")}: ${subjectLabel}`,
      "",
      message.trim(),
      "",
      t("contactPage.bodyFooter"),
    ].join("\n");

    if (!supportEmail) {
      void navigator.clipboard?.writeText(body).then(
        () => setStatus(t("contactPage.copiedNoEmail")),
        () => setStatus(t("contactPage.noEmailManual")),
      );
      return;
    }

    const mailto = `mailto:${encodeURIComponent(supportEmail)}?subject=${encodeURIComponent(`[VETO] ${subjectLabel}`)}&body=${encodeURIComponent(body)}`;
    window.location.href = mailto;
    setStatus(t("contactPage.mailtoOpened") + supportEmail);
  };

  return (
    <form
      onSubmit={onSubmit}
      className="space-y-4 rounded-2xl border border-subtle bg-surface-raised-2 p-6 shadow-sm md:p-8"
    >
      <h2 className="text-lg font-bold text-primary">{t("contactPage.formTitle")}</h2>
      <p className="text-sm text-secondary">{t("contactPage.formHint")}</p>

      <div className="grid gap-4 md:grid-cols-2">
        <label className="block text-sm">
          <span className="mb-1 block font-semibold text-secondary">{t("contactPage.name")}</span>
          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="w-full rounded-xl border border-subtle bg-surface-sunken px-3 py-2.5 text-primary outline-none focus:ring-2 focus:ring-veto-gold"
            autoComplete="name"
            required
          />
        </label>
        <label className="block text-sm">
          <span className="mb-1 block font-semibold text-secondary">{t("contactPage.email")}</span>
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="w-full rounded-xl border border-subtle bg-surface-sunken px-3 py-2.5 text-primary outline-none focus:ring-2 focus:ring-veto-gold"
            autoComplete="email"
            required
            dir="ltr"
          />
        </label>
      </div>

      <label className="block text-sm">
        <span className="mb-1 block font-semibold text-secondary">{t("contactPage.subject")}</span>
        <select
          value={subjectId}
          onChange={(e) => setSubjectId(e.target.value as SubjectId)}
          className="w-full rounded-xl border border-subtle bg-surface-sunken px-3 py-2.5 text-primary outline-none focus:ring-2 focus:ring-veto-gold"
        >
          {subjects.map((s) => (
            <option key={s.id} value={s.id}>
              {s.label}
            </option>
          ))}
        </select>
      </label>

      <label className="block text-sm">
        <span className="mb-1 block font-semibold text-secondary">{t("contactPage.message")}</span>
        <textarea
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          rows={5}
          className="w-full rounded-xl border border-subtle bg-surface-sunken px-3 py-2.5 text-primary outline-none focus:ring-2 focus:ring-veto-gold"
          required
        />
      </label>

      <button
        type="submit"
        className="w-full rounded-xl bg-veto-gold px-4 py-3 text-sm font-bold text-brand-fg transition hover:opacity-90 md:w-auto md:min-w-[12rem]"
      >
        {t("contactPage.formSubmit")}
      </button>

      {status && (
        <p
          className="rounded-xl border border-amber-500/30 bg-amber-500/10 px-4 py-3 text-sm text-amber-950 dark:text-amber-100"
          role="status"
        >
          {status}
        </p>
      )}
    </form>
  );
}
