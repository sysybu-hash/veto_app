/**
 * Israeli emergency playbooks — product copy ported from legacy Flutter scenarios.
 * Not legal advice. Keep draft disclaimer until counsel review.
 */

import type { Locale } from "@/lib/i18n/types";

export type PlaybookId = "police" | "traffic" | "family";

export type LocalizedText = Record<Locale, string>;
export type LocalizedList = Record<Locale, string[]>;

export type Playbook = {
  id: PlaybookId;
  title: LocalizedText;
  subtitle: LocalizedText;
  know: LocalizedList;
  first: LocalizedList;
  warn: LocalizedText;
  specializationHint?: string;
};

export function pickText(locale: Locale, text: LocalizedText): string {
  return text[locale] ?? text.he;
}

export function pickList(locale: Locale, list: LocalizedList): string[] {
  return list[locale] ?? list.he;
}

export const PLAYBOOKS: Playbook[] = [
  {
    id: "police",
    specializationHint: "criminal",
    title: {
      he: "חקירה במשטרה / מעצר",
      en: "Police investigation / arrest",
      ru: "Допрос в полиции / арест",
    },
    subtitle: {
      he: "זימון לחקירה · חקירה תחת אזהרה · מעצר ראשוני",
      en: "Summons · cautioned interview · initial arrest",
      ru: "Вызов на допрос · допрос под предупреждением · первичный арест",
    },
    know: {
      he: [
        "זימון לחקירה אינו \"המלצה\" — יש זכות להתייעץ עם עו״ד לפני ההגעה.",
        "בחקירה תחת אזהרה כל מילה נרשמת ויכולה לשמש בבית המשפט.",
        "שתיקה אינה הפללה — זו זכות יסוד.",
        "יש לאפשר התייעצות עם עורך דין לפני תחילת החקירה.",
      ],
      en: [
        "A summons to investigation is not a “suggestion” — you have the right to consult a lawyer before arriving.",
        "In a cautioned interview every word is recorded and may be used in court.",
        "Silence is not guilt — it is a fundamental right.",
        "You should be allowed to consult a lawyer before questioning begins.",
      ],
      ru: [
        "Вызов на допрос — не «рекомендация»: есть право проконсультироваться с адвокатом до явки.",
        "На допросе под предупреждением каждое слово фиксируется и может использоваться в суде.",
        "Молчание — не признание вины, а фундаментальное право.",
        "Должна быть возможность проконсультироваться с адвокатом до начала допроса.",
      ],
    },
    first: {
      he: [
        "אל תענה לשאלות עד שיחה ראשונה עם עו״ד.",
        "תעד שעת הגעה, שם החוקר ומספר תיק.",
        "בקש בכתב את העילה לזימון ואת סעיף החוק.",
      ],
      en: [
        "Do not answer questions until a first call with a lawyer.",
        "Note arrival time, investigator name, and case number.",
        "Ask in writing for the grounds of the summons and the legal provision.",
      ],
      ru: [
        "Не отвечайте на вопросы до первого разговора с адвокатом.",
        "Зафиксируйте время прибытия, имя следователя и номер дела.",
        "Попросите письменно основание вызова и статью закона.",
      ],
    },
    warn: {
      he: "הדקות הראשונות חשובות. לחץ SOS לקבלת ייעוץ ראשוני לפני שתשיב לשאלה הראשונה.",
      en: "The first minutes matter. Tap SOS for initial advice before answering the first question.",
      ru: "Первые минуты важны. Нажмите SOS для первичной консультации до ответа на первый вопрос.",
    },
  },
  {
    id: "traffic",
    specializationHint: "traffic",
    title: {
      he: "עצירת תנועה",
      en: "Traffic stop",
      ru: "Остановка на дороге",
    },
    subtitle: {
      he: "דוח · בדיקת נשיפה · תפיסת רכב",
      en: "Ticket · breath test · vehicle seizure",
      ru: "Штраф · алкотест · изъятие автомобиля",
    },
    know: {
      he: [
        "חובה להזדהות; אין חובה להודות בעבירה או לספר סיפור מלא בצד הדרך.",
        "סירוב לבדיקת נשיפה/דם עלול לשאת סנקציות — התייעץ מייד עם עו״ד.",
        "תעד תנאי הכביש, מזג אוויר ומיקום GPS אם אפשר.",
      ],
      en: [
        "You must identify yourself; you are not required to admit an offense or tell a full roadside story.",
        "Refusing a breath/blood test may carry sanctions — consult a lawyer immediately.",
        "Document road conditions, weather, and GPS location if possible.",
      ],
      ru: [
        "Обязаны предъявить личность; не обязаны признавать нарушение или рассказывать полную историю на обочине.",
        "Отказ от алкотеста/анализа крови может повлечь санкции — сразу проконсультируйтесь с адвокатом.",
        "Зафиксируйте условия дороги, погоду и GPS, если возможно.",
      ],
    },
    first: {
      he: [
        "שמור על קור רוח; אל תתווכח עם השוטר בזירה.",
        "צלם את הדוח / מספר ניידת כשזה בטוח.",
        "הפעל SOS אם נדרש ייעוץ לפני הודאה או בדיקה.",
      ],
      en: [
        "Stay calm; do not argue with the officer at the scene.",
        "Photograph the ticket / patrol number when safe.",
        "Activate SOS if you need advice before an admission or test.",
      ],
      ru: [
        "Сохраняйте спокойствие; не спорьте с полицейским на месте.",
        "Сфотографируйте протокол / номер патруля, когда безопасно.",
        "Активируйте SOS, если нужен совет до признания или теста.",
      ],
    },
    warn: {
      he: "הודאה בזירה או חתימה על מסמך בלי הבנה עלולה להקשות בהמשך. בקש ייעוץ לפני שאתה מסכים.",
      en: "A roadside admission or signing a document without understanding can hurt later. Get advice before you agree.",
      ru: "Признание на месте или подпись без понимания могут усложнить дело. Получите совет до согласия.",
    },
  },
  {
    id: "family",
    specializationHint: "family",
    title: {
      he: "סכסוך משפחתי / אלימות במשפחה",
      en: "Family dispute / domestic violence",
      ru: "Семейный конфликт / насилие в семье",
    },
    subtitle: {
      he: "צו הגנה · פינוי · תלונה",
      en: "Protection order · evacuation · complaint",
      ru: "Охранный ордер · выселение · жалоба",
    },
    know: {
      he: [
        "במצבי סכנה מיידית — התקשר ל־100; VETO אינו תחליף למשטרה.",
        "ניתן לבקש צו הגנה דחוף בבית משפט לענייני משפחה.",
        "תיעוד (הודעות, הקלטות חוקיות, פציעות) חשוב להמשך ההליך.",
      ],
      en: [
        "In immediate danger — call 100; VETO is not a substitute for police.",
        "You can seek an urgent protection order in family court.",
        "Documentation (messages, lawful recordings, injuries) matters for later proceedings.",
      ],
      ru: [
        "При непосредственной опасности — звоните 100; VETO не заменяет полицию.",
        "Можно запросить срочный охранный ордер в семейном суде.",
        "Документация (сообщения, законные записи, травмы) важна для дальнейшего процесса.",
      ],
    },
    first: {
      he: [
        "דאג קודם לבטיחות — מקום בטוח, קרובים, מוקד חירום.",
        "שמור ראיות דיגיטליות בכספת VETO אחרי ייצוב המצב.",
        "הפעל SOS לעו״ד משפחה לליווי ראשוני.",
      ],
      en: [
        "Prioritize safety first — safe place, relatives, emergency hotline.",
        "Store digital evidence in the VETO vault after the situation stabilizes.",
        "Activate SOS for a family lawyer for initial guidance.",
      ],
      ru: [
        "Сначала безопасность — безопасное место, близкие, служба экстренной помощи.",
        "Сохраните цифровые доказательства в сейфе VETO после стабилизации ситуации.",
        "Активируйте SOS к семейному адвокату для первичного сопровождения.",
      ],
    },
    warn: {
      he: "אל תישאר במקום מסוכן כדי \"לאסוף ראיות\". בטיחות קודמת לכל תיעוד.",
      en: "Do not stay in a dangerous place to “collect evidence”. Safety comes before documentation.",
      ru: "Не оставайтесь в опасном месте, чтобы «собрать доказательства». Безопасность важнее любой фиксации.",
    },
  },
];

export function getPlaybook(id: string): Playbook | undefined {
  return PLAYBOOKS.find((p) => p.id === id);
}
