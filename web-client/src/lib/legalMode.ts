/**
 * Whether the public legal pages (/terms, /privacy, /accessibility) are shown
 * as final rather than as drafts.
 *
 * Defaults to TRUE — the site owner has taken these live and is running them
 * past counsel in parallel. To put them back into draft (e.g. counsel asks for
 * changes), set `NEXT_PUBLIC_LEGAL_APPROVED=false` on Vercel and redeploy; the
 * amber "draft" banner returns on all three pages with no code change.
 */
export function isLegalCommerciallyApproved(): boolean {
  return process.env.NEXT_PUBLIC_LEGAL_APPROVED !== "false";
}
