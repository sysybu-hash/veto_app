import Link from "next/link";

const bento = [
  {
    title: "התערבות SOS",
    desc: "חיבור וידאו מיידי לעורך דין תורן שמקבל גישה למקום האירוע.",
    tag: "EMERGENCY",
  },
  {
    title: "כספת ראיות",
    desc: "אחסון מוצפן בסטנדרט צבאי לכל המסמכים והראיות שלך.",
    tag: "SECURITY",
  },
  {
    title: "סנכרון חכם",
    desc: "חיבור מלא ליומן גוגל ומעקב אחר משימות משפטיות.",
    tag: "INTELLIGENCE",
  },
] as const;

export default function Home() {
  return (
    <div className="flex min-h-screen flex-col">
      <nav className="container mx-auto flex items-center justify-between px-6 py-8">
        <div className="font-frank text-3xl font-black text-white drop-shadow-md">
          VETO<span className="text-[#C5A059]">.</span>
        </div>

        <div className="hidden items-center gap-8 font-bold text-white/90 md:flex">
          <a href="#" className="transition-all hover:text-[#C5A059]">
            המערכת
          </a>
          <a href="#" className="transition-all hover:text-[#C5A059]">
            אבטחה ופרטיות
          </a>
          <a href="#" className="transition-all hover:text-[#C5A059]">
            צוות משפטי
          </a>
        </div>
        <div className="flex items-center gap-4">
          <Link
            href="/login"
            className="rounded-lg px-4 py-2 font-bold text-white transition-all hover:bg-white/10"
          >
            כניסת עורכי דין
          </Link>
          <Link
            href="/login"
            className="rounded-full bg-[#C5A059] px-6 py-2 font-black text-black shadow-lg transition-all hover:scale-105"
          >
            אזור אישי
          </Link>
        </div>
      </nav>

      <main className="container mx-auto flex grow flex-col items-center justify-center px-6 py-20 text-center">
        <div className="mb-6 rounded-full border border-white/20 bg-white/10 px-4 py-1 text-xs font-black tracking-wide text-white backdrop-blur-md">
          VETO OS 2.0 ✦ עכשיו באוויר
        </div>
        <h1 className="mb-8 font-frank text-7xl font-black leading-[0.9] tracking-tighter text-slate-900 drop-shadow-sm md:text-[120px]">
          עורך דין
          <br />
          בלחיצת כפתור
        </h1>
        <p className="mb-10 max-w-3xl text-xl font-medium leading-relaxed text-slate-700 md:text-2xl">
          מערכת ההפעלה המשפטית הראשונה בישראל. הגנה מיידית, ניהול ראיות חכם
          וסנכרון מלא לחיים הדיגיטליים שלך.
        </p>

        <Link
          href="/login"
          className="rounded-2xl bg-slate-900 px-12 py-5 text-xl font-black text-white shadow-2xl transition-all hover:-translate-y-1 hover:bg-[#C5A059]"
        >
          התחל הגנה עכשיו
        </Link>
        <div
          className="mt-12 rounded-full border border-slate-900/10 bg-slate-900/5 px-6 py-2 text-sm font-black text-slate-900 backdrop-blur-sm"
          role="status"
        >
          השירות ניתן מלבד שבתות וחגים
        </div>
      </main>

      <section className="container mx-auto grid grid-cols-1 gap-6 px-6 pb-20 md:grid-cols-3">
        {bento.map((item) => (
          <div
            key={item.tag}
            className="cursor-default rounded-[40px] border border-white/60 bg-white/40 p-10 shadow-sm backdrop-blur-xl transition-all hover:bg-white/60 hover:shadow-xl"
          >
            <span className="mb-4 block text-[10px] font-black tracking-widest text-[#C5A059] uppercase">
              {item.tag}
            </span>
            <h3 className="mb-4 font-frank text-3xl font-bold text-slate-900">
              {item.title}
            </h3>
            <p className="font-medium leading-relaxed text-slate-600">
              {item.desc}
            </p>
          </div>
        ))}
      </section>
    </div>
  );
}
