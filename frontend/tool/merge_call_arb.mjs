import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, "../lib/l10n");

/** Mirrors `widgets/call/call_i18n.dart` — keys become `callUi*` in ARB. */
const keys = {
  callUiBadgeConnecting: {
    he: "מתחבר לעורך דין...",
    en: "Connecting to a lawyer…",
    ru: "Подключение к адвокату…",
  },
  callUiFindingLawyer: {
    he: "מחפש עו״ד פלילי",
    en: "Finding a criminal lawyer",
    ru: "Поиск адвоката",
  },
  callUiConnectingNearby: {
    he: "בקרבת מקום",
    en: "Nearby",
    ru: "Поблизости",
  },
  callUiConnectingDetails: {
    he: "3 עורכי דין בקרבת מקום קיבלו את הקריאה. מחבר לראשון שיגיב.",
    en: "3 lawyers nearby received the request. Connecting to the first to respond.",
    ru: "Запрос получили 3 адвоката поблизости. Соединяем с первым ответившим.",
  },
  callUiCancelRequest: {
    he: "בטל בקשה",
    en: "Cancel request",
    ru: "Отменить запрос",
  },
  callUiIncomingBadge: {
    he: "קריאת חירום נכנסת · LIVE",
    en: "Incoming emergency · LIVE",
    ru: "Входящий экстренный · LIVE",
  },
  callUiIncomingUnknown: {
    he: "משתמש אנונימי",
    en: "Anonymous user",
    ru: "Анонимный пользователь",
  },
  callUiIncomingCaseDetails: {
    he: "פרטי האירוע",
    en: "Case details",
    ru: "Детали ситуации",
  },
  callUiIncomingDecline: {
    he: "דחה",
    en: "Decline",
    ru: "Отклонить",
  },
  callUiIncomingChatFirst: {
    he: "צ׳אט קודם",
    en: "Chat first",
    ru: "Сначала чат",
  },
  callUiIncomingAccept: {
    he: "קבל שיחה",
    en: "Accept",
    ru: "Принять",
  },
  callUiEncryptedBadge: {
    he: "שיחה מוצפנת",
    en: "Encrypted call",
    ru: "Зашифрованный звонок",
  },
  callUiConnectedEncrypted: {
    he: "מחוברים · שיחה מוצפנת",
    en: "Connected · encrypted call",
    ru: "Подключено · зашифрованный звонок",
  },
  callUiAes256Footer: {
    he: "קצה-לקצה · AES-256",
    en: "End-to-end · AES-256",
    ru: "Сквозное · AES-256",
  },
  callUiRecordingShort: {
    he: "מוקלט",
    en: "REC",
    ru: "Запись",
  },
  callUiRecordingPill: {
    he: "מוקלט · נשמר בכספת המוצפנת שלך",
    en: "Recording · saved to your encrypted vault",
    ru: "Запись · сохраняется в вашем зашифрованном хранилище",
  },
  callUiMuteMic: { he: "השתק", en: "Mute", ru: "Заглушить" },
  callUiUnmuteMic: {
    he: "הפעל מיקרופון",
    en: "Unmute",
    ru: "Включить микрофон",
  },
  callUiSpeaker: { he: "רמקול", en: "Speaker", ru: "Динамик" },
  callUiCamera: { he: "מצלמה", en: "Camera", ru: "Камера" },
  callUiCameraOff: {
    he: "כבה מצלמה",
    en: "Camera off",
    ru: "Выключить камеру",
  },
  callUiFlipCamera: {
    he: "החלפת מצלמה",
    en: "Flip camera",
    ru: "Сменить камеру",
  },
  callUiScreenShare: {
    he: "שיתוף מסך",
    en: "Share screen",
    ru: "Показ экрана",
  },
  callUiStopScreenShare: {
    he: "עצור שיתוף",
    en: "Stop sharing",
    ru: "Остановить показ",
  },
  callUiNoiseSuppression: {
    he: "דיכוי רעשים",
    en: "Noise suppression",
    ru: "Шумоподавление",
  },
  callUiOpenChat: { he: "צ׳אט", en: "Chat", ru: "Чат" },
  callUiEndCall: {
    he: "סיים שיחה",
    en: "End call",
    ru: "Завершить",
  },
  callUiWaitingForPeer: {
    he: "ממתין לצד השני…",
    en: "Waiting for the other side…",
    ru: "Ожидание собеседника…",
  },
  callUiWaitingForPeerVideo: {
    he: "ממתין לווידאו מרוחק…",
    en: "Waiting for remote video…",
    ru: "Ждём удалённое видео…",
  },
  callUiCameraLabel: {
    he: "המצלמה שלך",
    en: "Your camera",
    ru: "Ваша камера",
  },
  callUiCameraOffLabel: {
    he: "מצלמה כבויה",
    en: "Camera is off",
    ru: "Камера выключена",
  },
  callUiVoiceHeader: {
    he: "שיחת אודיו · מוצפנת",
    en: "Voice call · encrypted",
    ru: "Голосовой вызов · зашифрован",
  },
  callUiTabChat: { he: "צ׳אט", en: "Chat", ru: "Чат" },
  callUiTabCaption: {
    he: "כיתוב חי",
    en: "Live caption",
    ru: "Субтитры",
  },
  callUiSendMessage: { he: "שלח", en: "Send", ru: "Отправить" },
  callUiMessagePlaceholder: {
    he: "הקלד הודעה…",
    en: "Type a message…",
    ru: "Сообщение…",
  },
  callUiChatEmpty: {
    he: "אין הודעות. כתוב למטה.",
    en: "No messages yet. Type below.",
    ru: "Пока нет сообщений. Введите текст ниже.",
  },
  callUiCaptionWebNotice: {
    he: "כיתוב חי זמין במובייל בלבד. בדפדפן — תמלול שרת לאחר השיחה.",
    en: "Live captions are mobile-only; the browser uses post-call server transcription.",
    ru: "Субтитры в реальном времени — только на мобильных; в браузере — после звонка.",
  },
  callUiCaptionStart: {
    he: "התחל כיתוב",
    en: "Start caption",
    ru: "Запустить субтитры",
  },
  callUiCaptionStop: {
    he: "עצור כיתוב",
    en: "Stop caption",
    ru: "Остановить субтитры",
  },
  callUiErrorTitle: {
    he: "שגיאת שיחה",
    en: "Call error",
    ru: "Ошибка звонка",
  },
  callUiErrorPermission: {
    he: "לא הוענקו הרשאות מצלמה / מיקרופון. אשר בהגדרות הדפדפן/המכשיר ונסה שוב.",
    en: "Camera / microphone permission denied. Allow access in browser or device settings and retry.",
    ru: "Нет доступа к камере/микрофону. Разрешите в настройках и попробуйте снова.",
  },
  callUiErrorTokenInvalid: {
    he: "הטוקן של Agora אינו תקין. מרענן ומנסה שוב.",
    en: "Invalid Agora token — refreshing and retrying.",
    ru: "Недействительный токен Agora — обновление и повторная попытка.",
  },
  callUiErrorTokenExpired: {
    he: "הטוקן פג תוקף — מחדש ומחבר מחדש.",
    en: "Token expired — renewing and reconnecting.",
    ru: "Срок токена истёк — обновляем и переподключаемся.",
  },
  callUiErrorNetwork: {
    he: "החיבור אבד. מנסה לחדש אוטומטית.",
    en: "Connection lost — attempting to recover.",
    ru: "Связь потеряна — пробуем восстановить.",
  },
  callUiErrorMedia: {
    he: "מדיה (מצלמה/מיקרופון) לא זמינה. אפשר להמשיך בצ׳אט.",
    en: "Media (camera/microphone) unavailable. You can continue in chat.",
    ru: "Медиа недоступно (камера/микрофон). Можно продолжить в чате.",
  },
  callUiErrorGeneric: {
    he: "אירעה שגיאה בלתי צפויה. נסה להיכנס שוב.",
    en: "Something went wrong. Please rejoin the call.",
    ru: "Произошла ошибка. Попробуйте войти заново.",
  },
  callUiErrorUidConflict: {
    he: "מזהה משתמש כפול או הצטרפות נדחתה. נסה שוב — אם זה נמשך, רענן את הדף.",
    en: "Duplicate user ID or join was rejected. Retry — if it persists, refresh the page.",
    ru: "Конфликт ID или вход отклонён. Повторите; при повторении обновите страницу.",
  },
  callUiWebStartCall: {
    he: "התחל שיחת וידאו",
    en: "Start video call",
    ru: "Начать видеозвонок",
  },
  callUiWebStartCallHint: {
    he: "בדפדפן יש ללחוץ כדי לאפשר מצלמה ומיקרופון.",
    en: "Browsers require a tap before camera and microphone can start.",
    ru: "Браузеру нужно нажатие, чтобы включить камеру и микрофон.",
  },
  callUiWebInsecureContext: {
    he: "שיחת וידאו זמינה רק ב־HTTPS (או localhost). פתח את האתר בכתובת מאובטחת.",
    en: "Video calls need HTTPS (or localhost). Open the app on a secure URL.",
    ru: "Видеозвонок доступен только по HTTPS или localhost.",
  },
  callUiErrorRetry: { he: "נסה שוב", en: "Retry", ru: "Повторить" },
  callUiErrorExit: { he: "יציאה", en: "Exit", ru: "Выйти" },
  callUiVaultSaveTitle: {
    he: "לשמור בכספת?",
    en: "Save to vault?",
    ru: "Сохранить в сейф?",
  },
  callUiVaultSaveSubtitle: {
    he: "בחר מה לשמור לפני סגירת המסך.",
    en: "Choose what to save before closing.",
    ru: "Выберите, что сохранить перед закрытием.",
  },
  callUiVaultSaveMediaOnly: {
    he: "שמור הקלטה בלבד (ללא תמלול)",
    en: "Save recording only (no transcription)",
    ru: "Только запись (без расшифровки)",
  },
  callUiVaultSaveMediaAndTranscript: {
    he: "שמור הקלטה + תמלול (מומלץ)",
    en: "Save recording + transcription (recommended)",
    ru: "Запись + расшифровка (рекомендуется)",
  },
  callUiVaultSaveChatOnly: {
    he: "שמור צ׳אט בלבד",
    en: "Save chat only",
    ru: "Только чат",
  },
  callUiVaultSaveSkip: {
    he: "לא עכשיו",
    en: "Not now",
    ru: "Не сейчас",
  },
  callUiVaultWebNoLocalRecording: {
    he: "בדפדפן: אם השרת מוגדר עם Agora Cloud Recording + אחסון S3, נשמרת הקלטת ערוץ מלאה (אודיו/וידאו) בענן ותמלול אפשרי. אחרת נשמרת רק הקלטת מיקרופון מקומי (WebM). במובייל: הקלטת Agora מקומית כמו קודם.",
    en: "Browser: with Agora Cloud Recording + S3 on the server, a full mixed recording is saved in the cloud (audio/video) with optional transcript. Otherwise only your local mic (WebM) is captured. Mobile: unchanged on-device Agora recording.",
    ru: "Браузер: при Agora Cloud Recording + S3 на сервере — полная запись в облаке и расшифровка. Иначе только локальный микрофон (WebM). Мобильный — как раньше.",
  },
  callUiVaultNothingToSave: {
    he: "אין הקלטה או צ׳אט לשמירה.",
    en: "Nothing to save (no recording or chat).",
    ru: "Нечего сохранить.",
  },
  callUiQualityExcellent: {
    he: "מעולה",
    en: "Excellent",
    ru: "Отлично",
  },
  callUiQualityGood: { he: "טובה", en: "Good", ru: "Хорошо" },
  callUiQualityFair: { he: "בינונית", en: "Fair", ru: "Средне" },
  callUiQualityPoor: { he: "גרועה", en: "Poor", ru: "Плохо" },
  callUiQualityVeryPoor: {
    he: "נוראית",
    en: "Very poor",
    ru: "Очень плохо",
  },
  callUiLeaveCallTitle: {
    he: "לצאת מהשיחה?",
    en: "Leave call?",
    ru: "Покинуть звонок?",
  },
  callUiLeaveCallBody: {
    he: "השיחה תיסגר לשני הצדדים.",
    en: "The session will end for both sides.",
    ru: "Сессия завершится для обеих сторон.",
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
console.log("call UI ARB merged");
