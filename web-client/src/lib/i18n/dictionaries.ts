import type { Dict } from "./types";
import type { Locale } from "./types";
import { en } from "./locales/en";
import { he } from "./locales/he";
import { ru } from "./locales/ru";

const rescueCopy = {
  he: {
    navCitizen: { chat: "צ׳אט" },
    hub: { quickChat: "צ׳אט", quickProductivity: "משימות וחוזים" },
    chat: {
      title: "צ׳אט משפטי",
      subtitle: "שיחות עם עורכי דין ומשתמשים מאושרים.",
      loadFailed: "לא ניתן לטעון שיחות.",
      messagesFailed: "לא ניתן לטעון הודעות.",
      sendFailed: "שליחת ההודעה נכשלה.",
      deleteFailed: "מחיקת ההודעה נכשלה.",
      emptyThreads: "אין עדיין שיחות. כאשר יהיו עורכי דין זמינים הם יופיעו כאן.",
      emptyMessages: "אין עדיין הודעות בשיחה הזו.",
      noMessages: "אין הודעות עדיין",
      pickThread: "בחרו שיחה כדי להתחיל.",
      placeholder: "כתבו הודעה...",
      send: "שליחה",
      lawyer: "עורך דין",
      member: "משתמש",
    },
    call: {
      chatTitle: "צ׳אט חירום",
      chatEmpty: "החדר מוכן. הודעות שיוחלפו כאן הן חלק משיחת החירום.",
      chatPlaceholder: "כתבו הודעה לחדר החירום...",
      chatReady: "שני הצדדים בחדר.",
      peerTimeout: "הצד השני לא הצטרף בזמן.",
      peerEnded: "השיחה הסתיימה.",
      callError: "שגיאה בחיבור לחדר.",
    },
  },
  en: {
    navCitizen: { chat: "Chat" },
    hub: { quickChat: "Chat", quickProductivity: "Tasks & contracts" },
    chat: {
      title: "Legal chat",
      subtitle: "Conversations with lawyers and approved members.",
      loadFailed: "Could not load conversations.",
      messagesFailed: "Could not load messages.",
      sendFailed: "Could not send the message.",
      deleteFailed: "Could not delete the message.",
      emptyThreads: "No conversations yet. Available lawyers will appear here.",
      emptyMessages: "No messages in this conversation yet.",
      noMessages: "No messages yet",
      pickThread: "Choose a conversation to start.",
      placeholder: "Write a message...",
      send: "Send",
      lawyer: "Lawyer",
      member: "Member",
    },
    call: {
      chatTitle: "Emergency chat",
      chatEmpty: "The room is ready. Messages here are part of the emergency session.",
      chatPlaceholder: "Write a message to the emergency room...",
      chatReady: "Both sides are in the room.",
      peerTimeout: "The other side did not join in time.",
      peerEnded: "The session ended.",
      callError: "Could not connect to the room.",
    },
  },
  ru: {
    navCitizen: { chat: "Чат" },
    hub: { quickChat: "Чат", quickProductivity: "Задачи и договоры" },
    chat: {
      title: "Юридический чат",
      subtitle: "Диалоги с юристами и подтвержденными пользователями.",
      loadFailed: "Не удалось загрузить диалоги.",
      messagesFailed: "Не удалось загрузить сообщения.",
      sendFailed: "Не удалось отправить сообщение.",
      deleteFailed: "Не удалось удалить сообщение.",
      emptyThreads: "Пока нет диалогов. Доступные юристы появятся здесь.",
      emptyMessages: "В этом диалоге пока нет сообщений.",
      noMessages: "Пока нет сообщений",
      pickThread: "Выберите диалог, чтобы начать.",
      placeholder: "Напишите сообщение...",
      send: "Отправить",
      lawyer: "Юрист",
      member: "Пользователь",
    },
    call: {
      chatTitle: "Экстренный чат",
      chatEmpty: "Комната готова. Сообщения здесь относятся к экстренной сессии.",
      chatPlaceholder: "Напишите сообщение в экстренную комнату...",
      chatReady: "Обе стороны в комнате.",
      peerTimeout: "Вторая сторона не подключилась вовремя.",
      peerEnded: "Сессия завершена.",
      callError: "Не удалось подключиться к комнате.",
    },
  },
} satisfies Record<Locale, Dict>;

const onboardingCopy = {
  he: {
    badge: "הגדרה ראשונה",
    heroTitle: "נכנסים ל-VETO כמו שצריך",
    heroSubtitle:
      "נגדיר את השפה, נאשר את סביבת המשתמש ונפתח לך את מוקד החירום, הכספת והיומן בלי לאבד את הזרימה.",
    step: "שלב 1 מתוך 1",
    promiseSos: "מוקד SOS מוכן להפעלה",
    promiseVault: "כספת מסמכים נשארת מחוברת",
    promiseLanguage: "עברית, אנגלית ורוסית זמינות",
    readyTitle: "מה יקרה אחרי ההמשך?",
  },
  en: {
    badge: "First setup",
    heroTitle: "Enter VETO the right way",
    heroSubtitle:
      "Set your language, confirm the member workspace, and open the emergency hub, vault, and calendar without losing the flow.",
    step: "Step 1 of 1",
    promiseSos: "SOS hub ready",
    promiseVault: "Document vault stays connected",
    promiseLanguage: "Hebrew, English, and Russian available",
    readyTitle: "What happens next?",
  },
  ru: {
    badge: "Первичная настройка",
    heroTitle: "Войдите в VETO правильно",
    heroSubtitle:
      "Настроим язык, подтвердим рабочее пространство и откроем SOS, хранилище и календарь без потери потока.",
    step: "Шаг 1 из 1",
    promiseSos: "SOS-центр готов",
    promiseVault: "Хранилище документов подключено",
    promiseLanguage: "Доступны иврит, английский и русский",
    readyTitle: "Что будет дальше?",
  },
} satisfies Record<Locale, Dict>;

function withRescueCopy(base: Dict, locale: Locale): Dict {
  const extra = rescueCopy[locale];
  return {
    ...base,
    navCitizen: {
      ...((base.navCitizen as Dict | undefined) ?? {}),
      ...(extra.navCitizen as Dict),
    },
    hub: {
      ...((base.hub as Dict | undefined) ?? {}),
      ...(extra.hub as Dict),
    },
    onboarding: {
      ...((base.onboarding as Dict | undefined) ?? {}),
      ...onboardingCopy[locale],
    },
    call: {
      ...((base.call as Dict | undefined) ?? {}),
      ...(extra.call as Dict),
    },
    chat: extra.chat,
  };
}

export const dictionaries: Record<Locale, Dict> = {
  he: withRescueCopy(he, "he"),
  en: withRescueCopy(en, "en"),
  ru: withRescueCopy(ru, "ru"),
};
