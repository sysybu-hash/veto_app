import Link from "next/link";

type Props = { params: Promise<{ id: string }> };

export default async function AdminUserDetailPage({ params }: Props) {
  const { id } = await params;
  return (
    <div className="min-h-screen bg-slate-50 p-8" dir="rtl">
      <div className="mx-auto max-w-lg rounded-2xl border border-slate-200 bg-white p-8 shadow-sm">
        <h1 className="font-serif text-2xl font-bold text-slate-900">
          ניהול משתמש
        </h1>
        <p className="mt-2 text-sm text-slate-600">
          מזהה פנימי (Prisma):{" "}
          <code className="rounded bg-slate-100 px-1 text-xs">{id}</code>
        </p>
        <p className="mt-4 text-sm text-slate-500">
          דף פעולות מנהל יורחב בהמשך (מנוי, הרשאות, היסטוריה).
        </p>
        <Link
          href="/admin/dashboard"
          className="mt-6 inline-block text-sm font-bold text-[#C5A059] hover:underline"
        >
          חזרה למרכז שליטה
        </Link>
      </div>
    </div>
  );
}
