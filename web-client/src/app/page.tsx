"use client";

import Link from "next/link";
import { motion } from "framer-motion";
import { LivePreviewMockup } from "@/components/ui/LivePreviewMockup";
import {
  Shield,
  Zap,
  Scale,
  Clock,
  ChevronDown,
  ArrowLeft,
  type LucideIcon,
} from "lucide-react";

// --- Data ---
const faqs = [
  {
    q: "איך המערכת עובדת בזמן אמת?",
    a: "ברגע לחיצה על כפתור ה-SOS, המערכת מאתרת תוך שניות את עורך הדין הפנוי והמתאים ביותר באזורך, ומקימה חדר וידאו מאובטח ומוצפן.",
  },
  {
    q: "האם השיחה חסויה?",
    a: "לחלוטין. כל השיחות מוצפנות מקצה לקצה (E2EE) ואף גורם צד שלישי אינו יכול לגשת אליהן. החומרים נשמרים ב'כספת' אישית ופרטית.",
  },
  {
    q: "מי עורכי הדין בפלטפורמה?",
    a: "רק עורכי דין מוסמכים שעברו תהליך אימות קפדני מורשים לקבל קריאות חירום במערכת VETO.",
  },
];

const features: { icon: LucideIcon; title: string; desc: string }[] = [
  {
    icon: Clock,
    title: "תגובה בשניות",
    desc: "אין זמן להמתנה. אלגוריתם ה-Race-to-accept שלנו מבטיח מענה מיידי.",
  },
  {
    icon: Shield,
    title: "הצפנה צבאית",
    desc: "וידאו, אודיו וצ'אט מוצפנים מקצה לקצה (E2EE) לחיסיון עו״ד-לקוח מוחלט.",
  },
  {
    icon: Zap,
    title: "כספת ראיות ענן",
    desc: "הקלטות ושיתוף קבצים מגובים בזמן אמת לכספת דיגיטלית בלתי ניתנת לשינוי.",
  },
];

// --- Animation Variants ---
const fadeUp = {
  hidden: { opacity: 0, y: 30 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.6, ease: "easeOut" as const },
  },
};

const staggerContainer = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.2 } },
};

const faqJsonLd = {
  "@context": "https://schema.org",
  "@type": "FAQPage",
  mainEntity: faqs.map((f) => ({
    "@type": "Question",
    name: f.q,
    acceptedAnswer: { "@type": "Answer", text: f.a },
  })),
};

export default function Home() {
  return (
    <main
      dir="rtl"
      className="min-h-screen overflow-hidden bg-veto-ink text-white selection:bg-veto-gold selection:text-veto-ink"
    >
      {/* JSON-LD SEO Script */}
      <script
        type="application/ld+json"
        suppressHydrationWarning
        dangerouslySetInnerHTML={{ __html: JSON.stringify(faqJsonLd) }}
      />

      {/* --- HERO SECTION --- */}
      <section className="relative flex min-h-[90vh] w-full flex-col items-center justify-center px-6 pt-20">
        {/* Background Radar Animation */}
        <div className="pointer-events-none absolute inset-0 flex items-center justify-center opacity-20">
          <motion.div
            animate={{ scale: [1, 2, 3], opacity: [0.5, 0.1, 0] }}
            transition={{ duration: 3, repeat: Infinity, ease: "linear" }}
            className="absolute h-64 w-64 rounded-full border-2 border-veto-gold"
          />
          <motion.div
            animate={{ scale: [1, 2, 3], opacity: [0.5, 0.1, 0] }}
            transition={{
              duration: 3,
              repeat: Infinity,
              ease: "linear",
              delay: 1,
            }}
            className="absolute h-64 w-64 rounded-full border-2 border-veto-gold"
          />
        </div>

        <motion.div
          initial="hidden"
          animate="visible"
          variants={staggerContainer}
          className="relative z-10 mx-auto flex max-w-4xl flex-col items-center text-center"
        >
          <motion.div
            variants={fadeUp}
            className="mb-8 inline-flex items-center gap-2 rounded-full border border-veto-gold/30 bg-veto-gold/10 px-4 py-2 text-sm font-medium text-veto-gold backdrop-blur-md"
          >
            <span className="relative flex h-3 w-3">
              <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-veto-gold opacity-75" />
              <span className="relative inline-flex h-3 w-3 rounded-full bg-veto-gold" />
            </span>
            מערכת החירום המשפטית זמינה
          </motion.div>

          <motion.h1
            variants={fadeUp}
            className="mb-6 bg-gradient-to-br from-white via-gray-200 to-gray-500 bg-clip-text text-5xl font-bold tracking-tight text-transparent md:text-7xl"
          >
            עורך דין לצידך,
            <br />
            בדיוק בשנייה הקריטית.
          </motion.h1>

          <motion.p
            variants={fadeUp}
            className="mb-10 max-w-2xl text-lg leading-relaxed text-gray-400 md:text-xl"
          >
            הפלטפורמה המתקדמת בישראל לחיבור מיידי בווידאו בין אזרחים בחירום
            לבין עורכי דין מומחים. מוצפן, מהיר ומתועד.
          </motion.p>

          <motion.div
            variants={fadeUp}
            className="flex w-full flex-col gap-4 sm:w-auto sm:flex-row"
          >
            <Link
              href="/login"
              className="flex items-center justify-center gap-2 rounded-2xl bg-veto-gold px-8 py-4 text-lg font-bold text-veto-ink shadow-[0_0_20px_rgba(197,160,89,0.4)] transition-all hover:bg-veto-gold-light active:scale-95"
            >
              כניסה לאזור האישי <ArrowLeft size={20} />
            </Link>
            <Link
              href="/register/lawyer"
              className="flex items-center justify-center rounded-2xl border border-white/10 bg-white/5 px-8 py-4 font-medium text-white backdrop-blur-md transition-all hover:bg-white/10 active:scale-95"
            >
              הצטרפות עורכי דין
            </Link>
          </motion.div>
        </motion.div>
      </section>

      {/* --- FEATURES SECTION --- */}
      <section className="relative w-full bg-gradient-to-b from-veto-ink to-[#0a0a0f] px-6 py-24">
        <div className="mx-auto max-w-6xl">
          <div className="mb-16 text-center">
            <h2 className="mb-4 text-3xl font-bold text-white md:text-4xl">
              טכנולוגיה שמשנה את כללי המשחק
            </h2>
            <div className="mx-auto h-1 w-20 rounded-full bg-veto-gold" />
          </div>

          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-100px" }}
            variants={staggerContainer}
            className="grid grid-cols-1 gap-6 md:grid-cols-3"
          >
            {features.map((feat) => {
              const Icon = feat.icon;
              return (
                <motion.div
                  key={feat.title}
                  variants={fadeUp}
                  className="group flex flex-col rounded-3xl border border-white/10 bg-white/5 p-8 backdrop-blur-xl transition-colors hover:bg-white/10"
                >
                  <div className="mb-6 flex h-14 w-14 items-center justify-center rounded-2xl bg-veto-gold/20 text-veto-gold transition-transform group-hover:scale-110">
                    <Icon size={28} />
                  </div>
                  <h3 className="mb-3 text-xl font-bold text-white">
                    {feat.title}
                  </h3>
                  <p className="leading-relaxed text-gray-400">{feat.desc}</p>
                </motion.div>
              );
            })}
          </motion.div>
        </div>
      </section>

      {/* --- THE EXPERIENCE — interactive preview --- */}
      <section className="bg-black px-6 py-24">
        <div className="mx-auto grid max-w-6xl grid-cols-1 items-center gap-12 md:grid-cols-2">
          <motion.div
            initial={{ opacity: 0, x: -50 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.55, ease: "easeOut" }}
          >
            <p className="mb-2 text-xs font-black tracking-[0.22em] text-veto-gold">
              החוויה
            </p>
            <h2 className="mb-6 text-4xl font-bold text-white">
              העוצמה שביד שלך
            </h2>
            <p className="mb-6 text-lg leading-relaxed text-gray-400">
              כשכל שנייה קובעת, הממשק של VETO הופך את הטלפון שלך לכלי הגנה משפטי
              עוצמתי. חיבור מיידי, הצפנה מלאה וגיבוי אוטומטי.
            </p>
            <ul className="space-y-4">
              <li className="flex items-center gap-3 text-veto-gold">
                <span className="h-1.5 w-1.5 shrink-0 rounded-full bg-veto-gold" />
                זיהוי ביומטרי מאובטח
              </li>
              <li className="flex items-center gap-3 text-veto-gold">
                <span className="h-1.5 w-1.5 shrink-0 rounded-full bg-veto-gold" />
                תמלול מבוסס AI בזמן אמת
              </li>
            </ul>
          </motion.div>

          <div className="flex justify-center">
            <LivePreviewMockup />
          </div>
        </div>
      </section>

      {/* --- PRICING TEASER --- */}
      <section className="border-t border-white/5 px-6 py-24">
        <div className="mx-auto max-w-4xl text-center">
          <Scale size={48} className="mx-auto mb-6 text-veto-gold opacity-80" />
          <h2 className="mb-6 text-3xl font-bold text-white md:text-4xl">
            הגנה משפטית שקופה ונגישה
          </h2>
          <p className="mb-8 text-lg text-gray-400">
            בחר את המסלול המתאים לך וקבל שקט נפשי. ללא אותיות קטנות.
          </p>
          <Link
            href="/pricing"
            className="inline-flex rounded-full border border-veto-gold px-8 py-3 font-medium text-veto-gold transition-colors hover:bg-veto-gold/10"
          >
            לכל המסלולים והמחירים
          </Link>
        </div>
      </section>

      {/* --- FAQ SECTION --- */}
      <section className="bg-black/30 px-6 py-24">
        <div className="mx-auto max-w-3xl">
          <div className="mb-12 text-center">
            <h2 className="mb-4 text-3xl font-bold text-white">שאלות נפוצות</h2>
          </div>
          <div className="space-y-4">
            {faqs.map((faq) => (
              <details
                key={faq.q}
                className="group cursor-pointer rounded-2xl border border-white/10 bg-white/5 p-6 transition-colors hover:bg-white/10"
              >
                <summary className="flex list-none items-center justify-between text-lg font-medium text-white">
                  {faq.q}
                  <span className="transition group-open:rotate-180">
                    <ChevronDown size={20} className="text-veto-gold" />
                  </span>
                </summary>
                <div className="mt-4 border-r-2 border-veto-gold/30 pr-2 leading-relaxed text-gray-400">
                  {faq.a}
                </div>
              </details>
            ))}
          </div>
        </div>
      </section>
    </main>
  );
}
