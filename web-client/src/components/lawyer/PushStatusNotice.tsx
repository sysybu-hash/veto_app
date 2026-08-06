"use client";

import { BellOff, Share, PlusSquare } from "lucide-react";
import type { SubscribeToPushResult } from "@/lib/pushClient";

/**
 * Push failures used to be console-only. For a lawyer that meant switching to
 * available, seeing no error, and silently never receiving an SOS alert — the
 * one failure mode this product cannot afford.
 *
 * Only shown when a subscription attempt actually failed; success renders
 * nothing.
 */
export function PushStatusNotice({
  result,
}: {
  result: SubscribeToPushResult | null;
}) {
  if (!result || result.ok) return null;

  if (result.reason === "ios_needs_install") {
    return (
      <section
        role="alert"
        className="rounded-2xl border border-warning-border bg-warning-soft p-4 text-sm text-warning-on-soft"
      >
        <h3 className="flex items-center gap-2 font-black">
          <BellOff className="h-4 w-4" aria-hidden />
          לא תקבלו התראות SOS במכשיר הזה
        </h3>
        <p className="mt-2 leading-6">
          באייפון, התראות עובדות רק כשהאתר מותקן במסך הבית. זה לוקח חמש שניות:
        </p>
        <ol className="mt-2 space-y-1 ps-1">
          <li className="flex items-center gap-2">
            <Share className="h-4 w-4 shrink-0" aria-hidden />
            <span>1. הקישו על כפתור השיתוף בסרגל של ספארי</span>
          </li>
          <li className="flex items-center gap-2">
            <PlusSquare className="h-4 w-4 shrink-0" aria-hidden />
            <span>2. בחרו &quot;הוסף למסך הבית&quot;</span>
          </li>
          <li className="flex items-center gap-2">
            <span aria-hidden className="w-4" />
            <span>3. פתחו את VETO מהאייקון החדש וסמנו &quot;זמין&quot; שוב</span>
          </li>
        </ol>
      </section>
    );
  }

  if (result.reason === "denied") {
    return (
      <section
        role="alert"
        className="rounded-2xl border border-warning-border bg-warning-soft p-4 text-sm text-warning-on-soft"
      >
        <h3 className="flex items-center gap-2 font-black">
          <BellOff className="h-4 w-4" aria-hidden />
          התראות חסומות בדפדפן
        </h3>
        <p className="mt-2 leading-6">
          סימנתם שאתם זמינים, אך התראות SOS לא יגיעו. אפשרו התראות עבור האתר
          בהגדרות הדפדפן, וסמנו &quot;זמין&quot; שוב.
        </p>
      </section>
    );
  }

  if (result.reason === "unsupported") {
    return (
      <section
        role="alert"
        className="rounded-2xl border border-warning-border bg-warning-soft p-4 text-sm text-warning-on-soft"
      >
        <h3 className="flex items-center gap-2 font-black">
          <BellOff className="h-4 w-4" aria-hidden />
          הדפדפן הזה אינו תומך בהתראות
        </h3>
        <p className="mt-2 leading-6">
          השאירו את הדף פתוח כדי לראות קריאות, או השתמשו ב-Chrome, Edge או ספארי
          מעודכן. ההתראות בתוך הדף ימשיכו לעבוד.
        </p>
      </section>
    );
  }

  // no_vapid / no_subscription / network — a server-side or transient problem
  // the lawyer cannot fix, but must still know about.
  return (
    <section
      role="alert"
      className="rounded-2xl border border-danger-border bg-danger-soft p-4 text-sm text-danger-on-soft"
    >
      <h3 className="flex items-center gap-2 font-black">
        <BellOff className="h-4 w-4" aria-hidden />
        רישום להתראות נכשל
      </h3>
      <p className="mt-2 leading-6">
        סימנתם שאתם זמינים, אך לא הצלחנו לרשום את המכשיר להתראות. השאירו את הדף
        פתוח ופנו לתמיכה אם זה חוזר.
      </p>
    </section>
  );
}
