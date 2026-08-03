/**
 * After counsel signs off, set NEXT_PUBLIC_LEGAL_APPROVED=true on Vercel and redeploy.
 * Until then, /terms and /privacy keep their existing draft banners (no new legal text invented).
 */
export function isLegalCommerciallyApproved(): boolean {
  return process.env.NEXT_PUBLIC_LEGAL_APPROVED === "true";
}
