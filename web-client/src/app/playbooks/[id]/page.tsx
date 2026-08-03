import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";
import { isLegalCommerciallyApproved } from "@/lib/legalMode";
import { getPlaybook, PLAYBOOKS } from "@/lib/playbooks";

type Props = { params: Promise<{ id: string }> };

export function generateStaticParams() {
  return PLAYBOOKS.map((p) => ({ id: p.id }));
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const pb = getPlaybook(id);
  return {
    title: pb ? `${pb.titleHe} | VETO` : "מדריך | VETO",
  };
}

export default async function PlaybookDetailPage({ params }: Props) {
  const { id } = await params;
  const pb = getPlaybook(id);
  if (!pb) notFound();
  const approved = isLegalCommerciallyApproved();

  return (
    <div className="min-h-screen text-primary">
      <main
        className="mx-auto w-full max-w-3xl px-4 py-8 md:px-6 md:py-12"
        dir="rtl"
      >
        <div className="mb-8 flex flex-wrap gap-3">
          <Link
            href="/playbooks"
            className="inline-flex rounded-xl border border-subtle bg-surface-raised px-4 py-2 text-sm font-bold transition hover:border-veto-gold"
          >
            כל המדריכים
          </Link>
          <Link
            href="/login?redirect=%2Fhub"
            className="inline-flex rounded-xl bg-veto-gold px-4 py-2 text-sm font-bold text-primary"
          >
            התחברות ל־SOS
          </Link>
        </div>

        <header className="mb-6 text-center md:text-right">
          <div className="mb-4 flex justify-center md:justify-end">
            <VetoBrandLogo className="h-9 w-auto sm:h-10" />
          </div>
          <h1 className="font-display text-3xl font-bold md:text-4xl">{pb.titleHe}</h1>
          <p className="mt-2 text-secondary">{pb.subtitleHe}</p>
          {!approved && (
            <p className="mt-3 rounded-xl border border-amber-500/40 bg-amber-500/10 px-4 py-3 text-sm text-amber-900 dark:text-amber-100">
              טיוטת מוצר — מידע כללי בלבד, ממתין לאישור משפטי סופי.
            </p>
          )}
        </header>

        <article className="space-y-8 rounded-2xl border border-subtle bg-surface-raised-2 p-6 shadow-sm md:p-8">
          <section>
            <h2 className="text-lg font-bold">חשוב לדעת</h2>
            <ul className="mt-3 list-disc space-y-2 pe-5 text-sm leading-7 text-secondary md:text-base">
              {pb.knowHe.map((line) => (
                <li key={line}>{line}</li>
              ))}
            </ul>
          </section>
          <section>
            <h2 className="text-lg font-bold">צעדים ראשונים</h2>
            <ol className="mt-3 list-decimal space-y-2 pe-5 text-sm leading-7 text-secondary md:text-base">
              {pb.firstHe.map((line) => (
                <li key={line}>{line}</li>
              ))}
            </ol>
          </section>
          <p className="rounded-xl border border-veto-gold/40 bg-veto-gold/10 px-4 py-3 text-sm font-semibold text-primary">
            {pb.warnHe}
          </p>
          <p className="text-xs text-muted">
            המידע כללי ואינו תחליף לייעוץ משפטי אישי. ראו גם{" "}
            <Link href="/terms" className="underline">
              תנאי שימוש
            </Link>
            .
          </p>
        </article>
      </main>
    </div>
  );
}
