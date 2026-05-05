import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, "../lib/l10n");

const keys = {
  chatScrTitle: { he: "שיחות", en: "Conversations", ru: "Беседы" },
  chatScrNewChat: { he: "שיחה חדשה", en: "New Chat", ru: "Новый чат" },
  chatScrNoConversations: {
    he: "אין שיחות עדיין",
    en: "No conversations yet",
    ru: "Нет разговоров",
  },
  chatScrTypeMessage: {
    he: "הקלד הודעה...",
    en: "Type a message...",
    ru: "Введите сообщение...",
  },
  chatScrSend: { he: "שלח", en: "Send", ru: "Отправить" },
  chatScrToday: { he: "היום", en: "Today", ru: "Сегодня" },
  chatScrYesterday: { he: "אתמול", en: "Yesterday", ru: "Вчера" },
  chatScrLoadingMore: { he: "טוען...", en: "Loading...", ru: "Загрузка..." },
  chatScrDeleteMsg: {
    he: "מחק הודעה",
    en: "Delete message",
    ru: "Удалить сообщение",
  },
  chatScrYou: { he: "אתה", en: "You", ru: "Вы" },
  chatScrSelectPartner: {
    he: "בחר שותף לשיחה",
    en: "Select a partner to chat with",
    ru: "Выберите собеседника",
  },
  chatScrNoPartners: {
    he: "אין גורמים זמינים לשיחה",
    en: "No available partners",
    ru: "Нет доступных собеседников",
  },
  chatScrBack: { he: "חזור", en: "Back", ru: "Назад" },
  chatScrUnread: {
    he: "הודעות שלא נקראו",
    en: "Unread messages",
    ru: "Непрочитанные",
  },
};

function esc(s) {
  return s.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

function merge(locale, lang) {
  const p = path.join(root, `app_${locale}.arb`);
  let raw = fs.readFileSync(p, "utf8").trimEnd();
  if (!raw.endsWith("}")) throw new Error(p);
  raw = raw.slice(0, -1).trimEnd();
  if (!raw.endsWith(",")) raw += ",";
  const lines = Object.keys(keys).map(
    (k) => `  "${k}": "${esc(keys[k][lang])}"`
  );
  fs.writeFileSync(p, raw + "\n" + lines.join(",\n") + "\n}\n");
}

merge("he", "he");
merge("en", "en");
merge("ru", "ru");
console.log("chat ARB merged");
