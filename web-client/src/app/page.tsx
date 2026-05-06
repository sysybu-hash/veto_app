import Link from "next/link";

const bento = [
  {
    title: "SOS מיידי",
    body: "לחצן חירום משפטי מחובר לצוות ולמשתמשי קצה — תגובה בזמן אמת כשהזמן קריטי.",
  },
  {
    title: "כספת ראיות",
    body: "איסוף ושמירה מוצפנים של מסמכים, הקלטות וצילומים עם שרשרת שלמות דיגיטלית.",
  },
  {
    title: "סנכרון מומחים",
    body: "חיבור ישיר לעורכי דין ומומחים מתאימים לפי הקשר התיק — בלי גשרים מיותרים.",
  },
] as const;

export default function Home() {
  return (
    <div className="relative min-h-screen pb-28">
      <main className="mx-auto flex max-w-6xl flex-col gap-16 px-4 pt-12 md:px-8 md:pt-20 lg:pt-24">
        <header className="flex flex-col items-center text-center">
          <h1
            className="font-display text-4xl font-semibold leading-[1.05] tracking-tighter text-white drop-shadow-[0_4px_24px_rgba(0,0,0,0.55)] sm:text-6xl md:text-7xl lg:text-8xl xl:text-9xl"
          >
            עורך דין בלחיצת כפתור
          </h1>
          <p className="mt-8 max-w-3xl font-sans text-lg font-medium leading-relaxed text-slate-800 md:text-xl">
            מערכת ההפעלה המשפטית הראשונה בישראל המשלבת הגנה מיידית, ניהול ראיות חכם
            וחיבור ישיר למומחים ברגע האמת.
          </p>
          <Link
            href="/login"
            className="mt-10 inline-flex items-center justify-center rounded-2xl bg-slate-950 px-10 py-4 text-base font-semibold text-white shadow-[0_12px_40px_rgba(15,23,42,0.45)] ring-1 ring-white/10 transition hover:bg-slate-900 hover:shadow-[0_20px_50px_rgba(15,23,42,0.5)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-slate-950"
          >
            התחל הגנה עכשיו
          </Link>
        </header>

        <section
          aria-label="יכולות מרכזיות"
          className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 lg:gap-6"
        >
          {bento.map((item) => (
            <article
              key={item.title}
              className="flex flex-col rounded-3xl border border-white/60 bg-white/30 p-6 shadow-[0_8px_32px_rgba(15,23,42,0.08)] backdrop-blur-2xl md:p-8"
            >
              <h2 className="font-display text-xl font-semibold text-slate-900 md:text-2xl">
                {item.title}
              </h2>
              <p className="mt-3 font-sans text-sm leading-relaxed text-slate-800 md:text-base">
                {item.body}
              </p>
            </article>
          ))}
        </section>
      </main>

      <div className="pointer-events-none fixed bottom-6 left-1/2 z-20 -translate-x-1/2 px-4">
        <div
          className="pointer-events-auto rounded-full border border-amber-400/60 bg-linear-to-r from-[#0f172a] to-[#1e3a5f] px-5 py-2.5 text-center text-sm font-medium text-amber-100 shadow-[0_8px_32px_rgba(15,23,42,0.35)] backdrop-blur-md md:px-8 md:text-base"
          role="status"
        >
          השירות ניתן מלבד שבתות וחגים
        </div>
      </div>
    </div>
  );
}
