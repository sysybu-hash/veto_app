"use client";

import { useMemo, useState } from "react";

type Props = {
  supportEmail: string;
};

const SUBJECTS = [
  { id: "support", label: "תמיכה טכנית" },
  { id: "billing", label: "מנוי ותשלומים" },
  { id: "privacy", label: "פרטיות ומידע אישי" },
  { id: "lawyer", label: "הצטרפות עורכי דין" },
  { id: "other", label: "נושא אחר" },
] as const;

export function ContactForm({ supportEmail }: Props) {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [subjectId, setSubjectId] = useState<(typeof SUBJECTS)[number]["id"]>(
    "support",
  );
  const [message, setMessage] = useState("");
  const [status, setStatus] = useState<string | null>(null);

  const subjectLabel = useMemo(
    () => SUBJECTS.find((s) => s.id === subjectId)?.label ?? "פנייה",
    [subjectId],
  );

  const onSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setStatus(null);
    if (!name.trim() || !email.trim() || !message.trim()) {
      setStatus("נא למלא שם, אימייל והודעה.");
      return;
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) {
      setStatus("כתובת האימייל אינה תקינה.");
      return;
    }

    const body = [
      `שם: ${name.trim()}`,
      `אימייל לחזרה: ${email.trim()}`,
      `נושא: ${subjectLabel}`,
      "",
      message.trim(),
      "",
      "— נשלח מטופס צור קשר באתר VETO —",
    ].join("\n");

    if (!supportEmail) {
      void navigator.clipboard?.writeText(body).then(
        () =>
          setStatus(
            "ההודעה הועתקה ללוח. שלחו אותה לכתובת התמיכה שתפורסם, או פנו דרך בקשות זכויות פרטיות אם מדובר במידע אישי.",
          ),
        () =>
          setStatus(
            "אין כתובת תמיכה מוגדרת עדיין. העתיקו את ההודעה ידנית או השתמשו בבקשות זכויות פרטיות.",
          ),
      );
      return;
    }

    const mailto = `mailto:${encodeURIComponent(supportEmail)}?subject=${encodeURIComponent(`[VETO] ${subjectLabel}`)}&body=${encodeURIComponent(body)}`;
    window.location.href = mailto;
    setStatus("נפתח חלון המייל שלכם. אם זה לא קרה — שלחו ידנית אל " + supportEmail);
  };

  return (
    <form
      onSubmit={onSubmit}
      className="space-y-4 rounded-2xl border border-subtle bg-surface-raised-2 p-6 shadow-sm md:p-8"
    >
      <h2 className="text-lg font-bold text-primary">טופס פנייה</h2>
      <p className="text-sm text-secondary">
        לפניות שאינן חירום משפטי. במצב חירום — התחברו והפעילו SOS, או חייגו 100.
      </p>

      <div className="grid gap-4 md:grid-cols-2">
        <label className="block text-sm">
          <span className="mb-1 block font-semibold text-secondary">שם מלא</span>
          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="w-full rounded-xl border border-subtle bg-surface-sunken px-3 py-2.5 text-primary outline-none focus:ring-2 focus:ring-veto-gold"
            autoComplete="name"
            required
          />
        </label>
        <label className="block text-sm">
          <span className="mb-1 block font-semibold text-secondary">אימייל</span>
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
        <span className="mb-1 block font-semibold text-secondary">נושא</span>
        <select
          value={subjectId}
          onChange={(e) =>
            setSubjectId(e.target.value as (typeof SUBJECTS)[number]["id"])
          }
          className="w-full rounded-xl border border-subtle bg-surface-sunken px-3 py-2.5 text-primary outline-none focus:ring-2 focus:ring-veto-gold"
        >
          {SUBJECTS.map((s) => (
            <option key={s.id} value={s.id}>
              {s.label}
            </option>
          ))}
        </select>
      </label>

      <label className="block text-sm">
        <span className="mb-1 block font-semibold text-secondary">הודעה</span>
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
        className="w-full rounded-xl bg-veto-gold px-4 py-3 text-sm font-bold text-primary transition hover:opacity-90 md:w-auto md:min-w-[12rem]"
      >
        שליחת פנייה
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
