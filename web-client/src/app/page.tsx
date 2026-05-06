import Link from "next/link";

export default function Home() {
  return (
    <div className="container relative z-10 mx-auto flex min-h-screen flex-col px-6">
      <nav className="flex items-center justify-between py-10">
        <div className="font-frank text-4xl font-black tracking-tighter text-white">
          VETO<span className="text-[#C5A059]">.</span>
        </div>

        <div className="hidden items-center gap-10 text-lg font-bold text-white/90 md:flex">
          <a href="#" className="transition-colors hover:text-[#C5A059]">
            צוות משפטי
          </a>
          <a href="#" className="transition-colors hover:text-[#C5A059]">
            אבטחה
          </a>
          <a href="#" className="transition-colors hover:text-[#C5A059]">
            המערכת
          </a>
        </div>
        <div className="flex items-center gap-4">
          <Link
            href="/login"
            className="rounded-full border border-white/20 bg-white/10 px-6 py-2 font-bold text-white backdrop-blur-md transition-all hover:bg-white/20"
          >
            אזור עורכי דין
          </Link>
          <Link
            href="/login"
            className="rounded-full bg-[#C5A059] px-6 py-2 font-black text-black shadow-lg transition-all hover:scale-105"
          >
            כניסת משתמשים
          </Link>
        </div>
      </nav>

      <main className="flex grow flex-col items-center justify-center py-20 text-center">
        <h1 className="mb-8 font-frank text-7xl leading-none font-black drop-shadow-2xl md:text-9xl">
          עורך דין
          <br />
          בלחיצת כפתור
        </h1>
        <p className="mb-12 max-w-3xl text-xl font-medium leading-relaxed text-white/80 md:text-3xl">
          מערכת ההפעלה המשפטית הראשונה בישראל המשלבת הגנה מיידית, ניהול ראיות חכם
          וחיבור ישיר למומחים ברגע האמת.
        </p>

        <Link
          href="/login"
          className="rounded-xl bg-white px-16 py-6 text-2xl font-black text-black shadow-2xl transition-all hover:-translate-y-1 hover:bg-[#C5A059] hover:text-white"
        >
          התחל הגנה עכשיו
        </Link>

        <div
          className="mt-12 inline-block rounded-full border border-[#C5A059]/30 bg-black/40 px-8 py-3 font-black text-[#C5A059] backdrop-blur-xl"
          role="status"
        >
          השירות ניתן מלבד שבתות וחגים
        </div>
      </main>

      <div className="grid grid-cols-1 gap-6 pb-20 md:grid-cols-3">
        <div className="rounded-3xl border border-white/10 bg-white/5 p-10 backdrop-blur-2xl transition-all hover:border-[#C5A059]/50">
          <div className="mb-4 text-sm font-black tracking-tighter text-[#C5A059]">
            EMERGENCY RESPONSE
          </div>
          <h3 className="mb-4 font-frank text-3xl font-bold">התערבות SOS</h3>
          <p className="text-lg leading-relaxed text-white/60">
            חיבור וידאו מיידי לעורך דין תורן שמקבל גישה למקום האירוע ולסטטוס שלך.
          </p>
        </div>
        <div className="rounded-3xl border border-white/10 bg-white/5 p-10 backdrop-blur-2xl transition-all hover:border-[#C5A059]/50">
          <div className="mb-4 text-sm font-black tracking-tighter text-[#C5A059]">
            ENCRYPTION
          </div>
          <h3 className="mb-4 font-frank text-3xl font-bold">כספת ראיות</h3>
          <p className="text-lg leading-relaxed text-white/60">
            אחסון מוצפן בסטנדרט צבאי לכל המסמכים והראיות שלך עם שרשרת חזקה של
            בלוקצ&apos;יין.
          </p>
        </div>
        <div className="rounded-3xl border border-white/10 bg-white/5 p-10 backdrop-blur-2xl transition-all hover:border-[#C5A059]/50">
          <div className="mb-4 text-sm font-black tracking-tighter text-[#C5A059]">
            INTELLIGENCE
          </div>
          <h3 className="mb-4 font-frank text-3xl font-bold">ניהול חכם</h3>
          <p className="text-lg leading-relaxed text-white/60">
            סנכרון מלא ליומן גוגל ומערכת משימות משפטיות מתקדמת שדואגת שלא תפספס דבר.
          </p>
        </div>
      </div>
    </div>
  );
}
