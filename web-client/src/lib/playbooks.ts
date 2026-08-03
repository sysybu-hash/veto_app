/**
 * Israeli emergency playbooks — product copy ported from legacy Flutter scenarios.
 * Not legal advice. Keep draft disclaimer until counsel review.
 */

export type PlaybookId = "police" | "traffic" | "family";

export type Playbook = {
  id: PlaybookId;
  titleHe: string;
  subtitleHe: string;
  knowHe: string[];
  firstHe: string[];
  warnHe: string;
  specializationHint?: string;
};

export const PLAYBOOKS: Playbook[] = [
  {
    id: "police",
    titleHe: "חקירה במשטרה / מעצר",
    subtitleHe: "זימון לחקירה · חקירה תחת אזהרה · מעצר ראשוני",
    specializationHint: "criminal",
    knowHe: [
      "זימון לחקירה אינו \"המלצה\" — יש זכות להתייעץ עם עו״ד לפני ההגעה.",
      "בחקירה תחת אזהרה כל מילה נרשמת ויכולה לשמש בבית המשפט.",
      "שתיקה אינה הפללה — זו זכות יסוד.",
      "יש לאפשר התייעצות עם עורך דין לפני תחילת החקירה.",
    ],
    firstHe: [
      "אל תענה לשאלות עד שיחה ראשונה עם עו״ד.",
      "תעד שעת הגעה, שם החוקר ומספר תיק.",
      "בקש בכתב את העילה לזימון ואת סעיף החוק.",
    ],
    warnHe:
      "הדקות הראשונות חשובות. לחץ SOS לקבלת ייעוץ ראשוני לפני שתשיב לשאלה הראשונה.",
  },
  {
    id: "traffic",
    titleHe: "עצירת תנועה",
    subtitleHe: "דוח · בדיקת נשיפה · תפיסת רכב",
    specializationHint: "traffic",
    knowHe: [
      "חובה להזדהות; אין חובה להודות בעבירה או לספר סיפור מלא בצד הדרך.",
      "סירוב לבדיקת נשיפה/דם עלול לשאת סנקציות — התייעץ מייד עם עו״ד.",
      "תעד תנאי הכביש, מזג אוויר ומיקום GPS אם אפשר.",
    ],
    firstHe: [
      "שמור על קור רוח; אל תתווכח עם השוטר בזירה.",
      "צלם את הדוח / מספר ניידת כשזה בטוח.",
      "הפעל SOS אם נדרש ייעוץ לפני הודאה או בדיקה.",
    ],
    warnHe:
      "הודאה בזירה או חתימה על מסמך בלי הבנה עלולה להקשות בהמשך. בקש ייעוץ לפני שאתה מסכים.",
  },
  {
    id: "family",
    titleHe: "סכסוך משפחתי / אלימות במשפחה",
    subtitleHe: "צו הגנה · פינוי · תלונה",
    specializationHint: "family",
    knowHe: [
      "במצבי סכנה מיידית — התקשר ל־100; VETO אינו תחליף למשטרה.",
      "ניתן לבקש צו הגנה דחוף בבית משפט לענייני משפחה.",
      "תיעוד (הודעות, הקלטות חוקיות, פציעות) חשוב להמשך ההליך.",
    ],
    firstHe: [
      "דאג קודם לבטיחות — מקום בטוח, קרובים, מוקד חירום.",
      "שמור ראיות דיגיטליות בכספת VETO אחרי ייצוב המצב.",
      "הפעל SOS לעו״ד משפחה לליווי ראשוני.",
    ],
    warnHe:
      "אל תישאר במקום מסוכן כדי \"לאסוף ראיות\". בטיחות קודמת לכל תיעוד.",
  },
];

export function getPlaybook(id: string): Playbook | undefined {
  return PLAYBOOKS.find((p) => p.id === id);
}
