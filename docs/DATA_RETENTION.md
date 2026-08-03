# VETO — מדיניות שמירת נתונים (Evidence / Vault)

מסמך תפעולי קצר. נוסח משפטי סופי דורש אישור עו״ד / DPO — ראו [LEGAL_REVIEW_PACKAGE.md](LEGAL_REVIEW_PACKAGE.md).

## Evidence (Prisma / Neon)

| פעולה | התנהגות |
|--------|---------|
| מחיקה בידי משתמש | **Soft-delete**: `Evidence.deletedAt` מסומן; הרשימה בכספת מסתירה את השורה |
| קובץ מרוחק | נמחק מ-Cloudinary דרך `POST /api/vault/delete-remote` לפני הסימון |
| מפתח SOS | `sourceEmergencyEventId` משונה ב-soft-delete כדי לאפשר סנכרון מחדש |

## Mongo VaultFile

מחיקה ב-`DELETE /api/vault/files/:id` מוחקת גם את נכס ה-Cloudinary (אם רלוונטי) ואז את מסמך ה-Mongo.

## Retention מומלץ (מפעיל)

- **Soft-deleted Evidence:** מומלץ hard-purge אחרי **90 יום** (cron / סקריפט מפעיל — לא מובנה כרגע).
- בקשות מחיקה לפי חוק: זרימת `PrivacyRequest` באפליקציה (`/privacy-rights`).
- גיבויי Neon / Atlas: לפי תוכנית הספק.

## Hard purge (ידני)

```sql
-- דוגמה: מחיקה סופית של Evidence שנמחק לפני 90 יום
DELETE FROM "Evidence"
WHERE "deletedAt" IS NOT NULL
  AND "deletedAt" < NOW() - INTERVAL '90 days';
```
