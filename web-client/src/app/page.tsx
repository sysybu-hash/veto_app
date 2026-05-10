import Link from "next/link";
import type { ReactNode } from "react";
import {
  ArrowLeft,
  BadgeCheck,
  Bot,
  Clock,
  FileSignature,
  FolderLock,
  HelpCircle,
  Lock,
  MapPin,
  MessageCircle,
  Mic,
  PhoneCall,
  Scale,
  ShieldCheck,
  Users,
  Video,
  type LucideIcon,
} from "lucide-react";

const features = [
  {
    icon: PhoneCall,
    title: "SOS משפטי בזמן אמת",
    body: "קריאת חירום לעורך דין זמין, עם מיקום, סוג מקרה ותיעוד שמוכן להמשך טיפול.",
  },
  {
    icon: FolderLock,
    title: "כספת ראיות",
    body: "מסמכים, הקלטות ותמונות נשמרים במקום אחד עם הקשר, זמן ויכולת שיתוף מבוקרת.",
  },
  {
    icon: Bot,
    title: "AI למסמכים משפטיים",
    body: "ניסוח ראשוני של מכתבים, בקשות והסכמים, עם שפה ברורה ומבנה שמוכן לבדיקה מקצועית.",
  },
  {
    icon: Users,
    title: "רשת עורכי דין מאושרת",
    body: "התאמה לפי תחום התמחות, זמינות וסטטוס אישור מנהל, בלי להפוך את המשתמש למוקד תפעול.",
  },
];

const faqs = [
  ["האם VETO מחליף עורך דין?", "לא. המערכת מארגנת, מתעדת ומחברת לעורך דין, אך אינה תחליף לייעוץ משפטי מחייב."],
  ["מה קורה למסמכים שלי?", "הם נשמרים בכספת המשתמש ונגישים לפי הרשאות, עם אפשרות לנהל מחיקה ושיתוף."],
  ["איך עורכי דין מצטרפים?", "דרך מסלול הצטרפות ייעודי. כל עורך דין ממתין לאישור מנהל לפני קבלת קריאות."],
];

export default function Home() {
  const faqJsonLd = {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: faqs.map(([question, answer]) => ({
      "@type": "Question",
      name: question,
      acceptedAnswer: {
        "@type": "Answer",
        text: answer,
      },
    })),
  };

  return (
    <main className="min-h-screen bg-[#eef1f5] text-slate-900" dir="rtl">
      <script
        type="application/ld+json"
        suppressHydrationWarning
        dangerouslySetInnerHTML={{ __html: JSON.stringify(faqJsonLd) }}
      />
      <section className="relative isolate overflow-hidden bg-[radial-gradient(circle_at_75%_12%,rgba(197,160,89,0.18),transparent_32%),linear-gradient(135deg,#f8fafc_0%,#eef1f5_45%,#d9dee7_100%)]">
        <div className="absolute inset-x-0 bottom-0 h-px bg-slate-300/80" aria-hidden />

        <div className="mx-auto grid min-h-[calc(100svh-68px)] max-w-7xl items-center gap-10 px-5 py-12 lg:grid-cols-[0.92fr_1.08fr] lg:py-16">
          <div className="max-w-3xl">
            <p className="inline-flex items-center gap-2 rounded-full border border-[#C5A059]/40 bg-white/75 px-4 py-2 text-xs font-black tracking-[0.22em] text-[#8a6d35] shadow-sm">
              <ShieldCheck className="h-4 w-4" aria-hidden />
              LEGAL OPERATING SYSTEM
            </p>
            <h1 className="mt-7 font-frank text-5xl font-black leading-[0.98] text-slate-950 md:text-7xl">
              VETO הופכת רגע משפטי מלחיץ למערכת פעולה מסודרת
            </h1>
            <p className="mt-7 max-w-2xl text-lg leading-8 text-slate-600">
              דף אזרח, שיחה פעילה עם עורך דין, כספת ראיות וניהול מנוי במקום אחד.
              הכל נבנה סביב פעולה מהירה, תיעוד ברור ואמון.
            </p>
            <div className="mt-9 flex flex-col gap-3 sm:flex-row">
              <Link
                href="/login"
                className="inline-flex items-center justify-center gap-2 rounded-xl bg-[#C5A059] px-6 py-3 text-sm font-black text-slate-950 shadow-[0_18px_50px_-24px_rgba(216,184,103,0.95)] transition hover:bg-[#D8B867]"
              >
                כניסה לאזור האישי
                <ArrowLeft className="h-4 w-4" aria-hidden />
              </Link>
              <Link
                href="/register/lawyer"
                className="inline-flex items-center justify-center rounded-xl border border-slate-300 bg-white/75 px-6 py-3 text-sm font-bold text-slate-800 shadow-sm backdrop-blur transition hover:bg-white"
              >
                הצטרפות עורכי דין
              </Link>
            </div>
          </div>

          <HeroMobileMockups />
        </div>
      </section>

      <section id="features" className="border-y border-slate-200 bg-[#eef1f5] px-5 py-16">
        <div className="mx-auto grid max-w-7xl gap-4 md:grid-cols-2 lg:grid-cols-4">
          {features.map((item) => {
            const Icon = item.icon;
            return (
              <article key={item.title} className="rounded-lg border border-slate-200 bg-white/75 p-5 shadow-sm">
                <Icon className="h-7 w-7 text-[#D8B867]" aria-hidden />
                <h2 className="mt-5 font-frank text-xl font-black text-slate-950">{item.title}</h2>
                <p className="mt-3 text-sm leading-6 text-slate-600">{item.body}</p>
              </article>
            );
          })}
        </div>
      </section>

      <section className="px-5 py-16">
        <div className="mx-auto grid max-w-7xl gap-10 lg:grid-cols-[0.9fr_1.1fr] lg:items-center">
          <div>
            <p className="text-xs font-black tracking-[0.22em] text-[#8a6d35]">VETO FLOW</p>
            <h2 className="mt-3 font-frank text-4xl font-black text-slate-950">
              מהקריאה הראשונה ועד תיק מסודר
            </h2>
            <p className="mt-4 text-base leading-8 text-slate-600">
              האתר מציג את המוצר כמרכז שליטה משפטי: תהליך מלא שמחבר בין משתמש,
              מסמכים, תשלום, משפחה ועורך דין מאושר.
            </p>
          </div>
          <div className="grid gap-3">
            {["אבחון מצב ובחירת תחום", "איתור עורך דין זמין", "שיחה מתועדת וחיוב דקות שקוף", "שמירה לכספת והמשך טיפול"].map((step, index) => (
              <div key={step} className="flex items-center gap-4 rounded-lg border border-slate-200 bg-white/75 p-4 shadow-sm">
                <span className="flex h-10 w-10 items-center justify-center rounded-full bg-[#C5A059] text-sm font-black text-slate-950">
                  {index + 1}
                </span>
                <span className="font-bold text-slate-800">{step}</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="border-y border-slate-200 bg-slate-100 px-5 py-16">
        <div className="mx-auto grid max-w-7xl gap-5 lg:grid-cols-3">
          <Trust title="GDPR-ready" body="הכנה להסכמה, מחיקה, ייצוא מידע, מינימיזציה והפרדת הרשאות." icon={BadgeCheck} />
          <Trust title="Google-ready" body="מטא לאימות Google, sitemap, robots, canonical ונתוני Organization." icon={Scale} />
          <Trust title="Evidence-ready" body="תכנון לשמירת ראיות והקלטות עם הקשר ברור, בלי לערבב מידע רגיש." icon={FileSignature} />
        </div>
      </section>

      <section className="px-5 py-16">
        <div className="mx-auto max-w-7xl">
          <div className="flex flex-col justify-between gap-5 md:flex-row md:items-end">
            <div>
              <p className="text-xs font-black tracking-[0.22em] text-[#8a6d35]">PRICING</p>
              <h2 className="mt-3 font-frank text-4xl font-black text-slate-950">מנוי שמתחבר לדרך העבודה</h2>
            </div>
            <Link href="/pricing" className="inline-flex items-center gap-2 rounded-xl border border-[#C5A059]/45 px-5 py-3 text-sm font-black text-[#D8B867] hover:bg-[#C5A059]/10">
              לכל המסלולים
              <ArrowLeft className="h-4 w-4" aria-hidden />
            </Link>
          </div>
          <div className="mt-8 grid gap-4 md:grid-cols-3">
            <Plan title="Demo" price="₪0" body="התנסות מבוקרת לפני הפעלה מלאה." />
            <Plan title="Standard" price="₪19.90" body="SOS, כספת ומסמכים למשתמש יחיד." featured />
            <Plan title="Family" price="₪199.99" body="עד 4 מושבים וניהול בני משפחה." />
          </div>
        </div>
      </section>

      <section className="border-t border-slate-200 px-5 py-16">
        <div className="mx-auto max-w-4xl">
          <h2 className="font-frank text-3xl font-black text-slate-950">שאלות נפוצות</h2>
          <div className="mt-6 grid gap-3">
            {faqs.map(([q, a]) => (
              <details key={q} className="rounded-lg border border-slate-200 bg-white/75 p-4 shadow-sm">
                <summary className="flex cursor-pointer list-none items-center gap-3 font-bold text-slate-950">
                  <HelpCircle className="h-5 w-5 text-[#D8B867]" aria-hidden />
                  {q}
                </summary>
                <p className="mt-3 text-sm leading-6 text-slate-600">{a}</p>
              </details>
            ))}
          </div>
        </div>
      </section>
    </main>
  );
}

function HeroMobileMockups() {
  return (
    <div className="relative mx-auto w-full max-w-2xl lg:me-0" aria-label="הדמיית מסכי מובייל של VETO">
      <div className="absolute inset-x-8 top-12 h-64 rounded-full bg-[#C5A059]/20 blur-3xl" aria-hidden />
      <div className="relative grid items-center gap-5 sm:grid-cols-2">
        <PhoneFrame title="דף אזרח" subtitle="VETO Citizen">
          <CitizenMobileScreen />
        </PhoneFrame>
        <PhoneFrame title="שיחה פעילה" subtitle="Live legal call" featured>
          <ActiveCallMobileScreen />
        </PhoneFrame>
      </div>
    </div>
  );
}

function PhoneFrame({
  title,
  subtitle,
  featured = false,
  children,
}: {
  title: string;
  subtitle: string;
  featured?: boolean;
  children: ReactNode;
}) {
  return (
    <figure className={`relative mx-auto w-full max-w-[285px] rounded-[2.2rem] border p-2 shadow-2xl ${featured ? "border-[#C5A059]/70 bg-[#C5A059]/15 shadow-[#C5A059]/20 sm:-ms-6 sm:mt-16" : "border-white/15 bg-white/[0.08]"}`}>
      <div className="absolute left-1/2 top-3 z-10 h-1.5 w-16 -translate-x-1/2 rounded-full bg-slate-700" aria-hidden />
      <div className="overflow-hidden rounded-[1.8rem] border border-white/10 bg-slate-950">
        <figcaption className="border-b border-white/10 px-4 pb-3 pt-7">
          <p className="text-[10px] font-black tracking-[0.18em] text-[#D8B867]">{subtitle}</p>
          <p className="mt-1 text-sm font-black text-white">{title}</p>
        </figcaption>
        {children}
      </div>
    </figure>
  );
}

function CitizenMobileScreen() {
  return (
    <div className="space-y-3 p-4">
      <div className="rounded-2xl border border-red-400/35 bg-red-500/15 p-4">
        <div className="flex items-center justify-between gap-3">
          <div>
            <p className="text-xs font-bold text-red-100">קריאת SOS מוכנה</p>
            <p className="mt-1 text-[11px] text-red-200/80">עורך דין תורן תוך שניות</p>
          </div>
          <PhoneCall className="h-8 w-8 text-red-200" aria-hidden />
        </div>
        <button className="mt-4 w-full rounded-xl bg-red-500 px-4 py-2 text-xs font-black text-white">
          הפעל SOS
        </button>
      </div>

      <div className="grid grid-cols-2 gap-2">
        <MiniCitizenCard icon={FolderLock} title="כספת" value="12 ראיות" />
        <MiniCitizenCard icon={FileSignature} title="מסמכים" value="3 טיוטות" />
      </div>

      <div className="rounded-2xl border border-white/10 bg-white/[0.05] p-3">
        <div className="flex items-center justify-between">
          <p className="text-xs font-black text-white">מנוי Standard</p>
          <BadgeCheck className="h-4 w-4 text-[#D8B867]" aria-hidden />
        </div>
        <div className="mt-3 h-2 overflow-hidden rounded-full bg-slate-800">
          <div className="h-full w-2/3 rounded-full bg-[#C5A059]" />
        </div>
        <p className="mt-2 text-[11px] text-slate-400">תוקף עד 10.06.2026</p>
      </div>
    </div>
  );
}

function ActiveCallMobileScreen() {
  return (
    <div className="p-4">
      <div className="relative overflow-hidden rounded-2xl border border-white/10 bg-slate-900">
        <div className="aspect-[9/12] bg-[radial-gradient(circle_at_50%_20%,rgba(216,184,103,0.28),transparent_38%),linear-gradient(160deg,#111827,#020617)] p-4">
          <div className="flex items-center justify-between">
            <span className="rounded-full bg-red-500 px-2 py-1 text-[10px] font-black text-white">REC</span>
            <span className="rounded-full bg-black/45 px-2 py-1 text-[10px] font-bold text-white">07:42</span>
          </div>
          <div className="mt-8 rounded-2xl border border-white/10 bg-white/[0.07] p-4 text-center">
            <div className="mx-auto flex h-20 w-20 items-center justify-center rounded-full bg-[#C5A059] text-2xl font-black text-slate-950">
              עו״ד
            </div>
            <p className="mt-3 text-sm font-black text-white">עו״ד דניאל כהן</p>
            <p className="mt-1 text-[11px] text-slate-300">פלילי · זמין עכשיו</p>
          </div>
          <div className="absolute bottom-4 left-4 w-24 rounded-2xl border border-white/15 bg-slate-950 p-2">
            <div className="aspect-square rounded-xl bg-slate-800" />
            <p className="mt-1 text-center text-[10px] font-bold text-slate-300">אזרח</p>
          </div>
        </div>
      </div>

      <div className="mt-3 grid grid-cols-4 gap-2">
        <CallButton icon={Mic} label="מיקרופון" />
        <CallButton icon={Video} label="וידאו" />
        <CallButton icon={MessageCircle} label="צ׳אט" />
        <CallButton icon={Lock} label="מאובטח" />
      </div>

      <div className="mt-3 rounded-2xl border border-[#C5A059]/25 bg-[#C5A059]/10 p-3">
        <div className="flex items-center gap-2 text-[11px] font-bold text-[#F1D58D]">
          <MapPin className="h-3.5 w-3.5" aria-hidden />
          מיקום שותף לעורך הדין
        </div>
        <div className="mt-2 flex items-center gap-2 text-[11px] text-slate-300">
          <Clock className="h-3.5 w-3.5" aria-hidden />
          15 דקות ראשונות כלולות
        </div>
      </div>
    </div>
  );
}

function MiniCitizenCard({ icon: Icon, title, value }: { icon: LucideIcon; title: string; value: string }) {
  return (
    <div className="rounded-2xl border border-white/10 bg-white/[0.05] p-3">
      <Icon className="h-5 w-5 text-[#D8B867]" aria-hidden />
      <p className="mt-3 text-[11px] font-bold text-slate-400">{title}</p>
      <p className="mt-1 text-sm font-black text-white">{value}</p>
    </div>
  );
}

function CallButton({ icon: Icon, label }: { icon: LucideIcon; label: string }) {
  return (
    <div className="flex min-h-14 flex-col items-center justify-center rounded-2xl border border-white/10 bg-white/[0.05] text-slate-200">
      <Icon className="h-4 w-4" aria-hidden />
      <span className="mt-1 text-[9px] font-bold">{label}</span>
    </div>
  );
}

function Trust({ title, body, icon: Icon }: { title: string; body: string; icon: LucideIcon }) {
  return (
    <article className="rounded-lg border border-slate-200 bg-white/75 p-5 shadow-sm">
      <Icon className="h-7 w-7 text-[#D8B867]" aria-hidden />
      <h3 className="mt-4 font-frank text-xl font-black text-slate-950">{title}</h3>
      <p className="mt-2 text-sm leading-6 text-slate-600">{body}</p>
    </article>
  );
}

function Plan({ title, price, body, featured = false }: { title: string; price: string; body: string; featured?: boolean }) {
  return (
    <article className={`rounded-lg border p-5 shadow-sm ${featured ? "border-[#C5A059]/70 bg-[#C5A059]/10" : "border-slate-200 bg-white/75"}`}>
      <h3 className="font-frank text-2xl font-black text-slate-950">{title}</h3>
      <p className="mt-3 text-3xl font-black text-[#D8B867]">{price}</p>
      <p className="mt-3 text-sm leading-6 text-slate-600">{body}</p>
    </article>
  );
}
