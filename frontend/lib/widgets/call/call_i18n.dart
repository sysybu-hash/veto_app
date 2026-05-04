// ============================================================
//  call_i18n.dart — Hebrew / English / Russian copy for the call UI.
//  Keys mirror `2026/communication.html` text labels (Hebrew source).
// ============================================================

/// Three-language string, picked with [CallCopy.t].
class CallCopy {
  const CallCopy({required this.he, required this.en, required this.ru});
  final String he;
  final String en;
  final String ru;

  String t(String lang) {
    switch (lang) {
      case 'he':
        return he;
      case 'ru':
        return ru;
      default:
        return en;
    }
  }
}

/// Top-level keys used by the call stack. Group by UI region.
class CallI18n {
  CallI18n._();

  // ── Connecting screen (citizen waiting) ─────────────────────
  static const badgeConnecting = CallCopy(
    he: 'מתחבר לעורך דין...',
    en: 'Connecting to a lawyer…',
    ru: 'Подключение к адвокату…',
  );
  static const findingLawyer = CallCopy(
    he: 'מחפש עו״ד פלילי',
    en: 'Finding a criminal lawyer',
    ru: 'Поиск адвоката',
  );
  static const connectingNearby = CallCopy(
    he: 'בקרבת מקום',
    en: 'Nearby',
    ru: 'Поблизости',
  );
  static const connectingDetails = CallCopy(
    he: '3 עורכי דין בקרבת מקום קיבלו את הקריאה. מחבר לראשון שיגיב.',
    en: '3 lawyers nearby received the request. Connecting to the first to respond.',
    ru: 'Запрос получили 3 адвоката поблизости. Соединяем с первым ответившим.',
  );
  static const cancelRequest =
      CallCopy(he: 'בטל בקשה', en: 'Cancel request', ru: 'Отменить запрос');

  // ── Incoming (lawyer side) ──────────────────────────────────
  static const incomingBadge = CallCopy(
    he: 'קריאת חירום נכנסת · LIVE',
    en: 'Incoming emergency · LIVE',
    ru: 'Входящий экстренный · LIVE',
  );
  static const incomingUnknown = CallCopy(
    he: 'משתמש אנונימי',
    en: 'Anonymous user',
    ru: 'Анонимный пользователь',
  );
  static const incomingCaseDetails = CallCopy(
    he: 'פרטי האירוע',
    en: 'Case details',
    ru: 'Детали ситуации',
  );
  static const incomingDecline =
      CallCopy(he: 'דחה', en: 'Decline', ru: 'Отклонить');
  static const incomingChatFirst =
      CallCopy(he: 'צ׳אט קודם', en: 'Chat first', ru: 'Сначала чат');
  static const incomingAccept =
      CallCopy(he: 'קבל שיחה', en: 'Accept', ru: 'Принять');

  // ── Active call / control bar ────────────────────────────────
  static const encryptedBadge = CallCopy(
    he: 'שיחה מוצפנת',
    en: 'Encrypted call',
    ru: 'Зашифрованный звонок',
  );
  static const connectedEncrypted = CallCopy(
    he: 'מחוברים · שיחה מוצפנת',
    en: 'Connected · encrypted call',
    ru: 'Подключено · зашифрованный звонок',
  );
  static const aes256Footer = CallCopy(
    he: 'קצה-לקצה · AES-256',
    en: 'End-to-end · AES-256',
    ru: 'Сквозное · AES-256',
  );
  static const recordingShort = CallCopy(
    he: 'מוקלט',
    en: 'REC',
    ru: 'Запись',
  );
  static const recordingPill = CallCopy(
    he: 'מוקלט · נשמר בכספת המוצפנת שלך',
    en: 'Recording · saved to your encrypted vault',
    ru: 'Запись · сохраняется в вашем зашифрованном хранилище',
  );
  static const muteMic = CallCopy(he: 'השתק', en: 'Mute', ru: 'Заглушить');
  static const unmuteMic =
      CallCopy(he: 'הפעל מיקרופון', en: 'Unmute', ru: 'Включить микрофон');
  static const speaker = CallCopy(he: 'רמקול', en: 'Speaker', ru: 'Динамик');
  static const camera = CallCopy(he: 'מצלמה', en: 'Camera', ru: 'Камера');
  static const cameraOff =
      CallCopy(he: 'כבה מצלמה', en: 'Camera off', ru: 'Выключить камеру');
  static const flipCamera =
      CallCopy(he: 'החלפת מצלמה', en: 'Flip camera', ru: 'Сменить камеру');
  static const screenShare =
      CallCopy(he: 'שיתוף מסך', en: 'Share screen', ru: 'Показ экрана');
  static const stopScreenShare =
      CallCopy(he: 'עצור שיתוף', en: 'Stop sharing', ru: 'Остановить показ');
  static const noiseSuppression = CallCopy(
      he: 'דיכוי רעשים', en: 'Noise suppression', ru: 'Шумоподавление');
  static const openChat = CallCopy(he: 'צ׳אט', en: 'Chat', ru: 'Чат');
  static const endCall =
      CallCopy(he: 'סיים שיחה', en: 'End call', ru: 'Завершить');

  // ── Video placeholders ──────────────────────────────────────
  static const waitingForPeer = CallCopy(
    he: 'ממתין לצד השני…',
    en: 'Waiting for the other side…',
    ru: 'Ожидание собеседника…',
  );
  static const waitingForPeerVideo = CallCopy(
    he: 'ממתין לווידאו מרוחק…',
    en: 'Waiting for remote video…',
    ru: 'Ждём удалённое видео…',
  );
  static const cameraLabel =
      CallCopy(he: 'המצלמה שלך', en: 'Your camera', ru: 'Ваша камера');
  static const cameraOffLabel = CallCopy(
    he: 'מצלמה כבויה',
    en: 'Camera is off',
    ru: 'Камера выключена',
  );

  // ── Voice stage ─────────────────────────────────────────────
  static const voiceHeader = CallCopy(
    he: 'שיחת אודיו · מוצפנת',
    en: 'Voice call · encrypted',
    ru: 'Голосовой вызов · зашифрован',
  );

  // ── Side panel ─────────────────────────────────────────────
  static const tabChat = CallCopy(he: 'צ׳אט', en: 'Chat', ru: 'Чат');
  static const tabCaption =
      CallCopy(he: 'כיתוב חי', en: 'Live caption', ru: 'Субтитры');
  static const sendMessage = CallCopy(he: 'שלח', en: 'Send', ru: 'Отправить');
  static const messagePlaceholder = CallCopy(
    he: 'הקלד הודעה…',
    en: 'Type a message…',
    ru: 'Сообщение…',
  );
  static const chatEmpty = CallCopy(
    he: 'אין הודעות. כתוב למטה.',
    en: 'No messages yet. Type below.',
    ru: 'Пока нет сообщений. Введите текст ниже.',
  );
  static const captionWebNotice = CallCopy(
    he: 'כיתוב חי זמין במובייל בלבד. בדפדפן — תמלול שרת לאחר השיחה.',
    en: 'Live captions are mobile-only; the browser uses post-call server transcription.',
    ru: 'Субтитры в реальном времени — только на мобильных; в браузере — после звонка.',
  );
  static const captionStart =
      CallCopy(he: 'התחל כיתוב', en: 'Start caption', ru: 'Запустить субтитры');
  static const captionStop =
      CallCopy(he: 'עצור כיתוב', en: 'Stop caption', ru: 'Остановить субтитры');

  // ── Errors ──────────────────────────────────────────────────
  static const errorTitle =
      CallCopy(he: 'שגיאת שיחה', en: 'Call error', ru: 'Ошибка звонка');
  static const errorPermission = CallCopy(
    he: 'לא הוענקו הרשאות מצלמה / מיקרופון. אשר בהגדרות הדפדפן/המכשיר ונסה שוב.',
    en: 'Camera / microphone permission denied. Allow access in browser or device settings and retry.',
    ru: 'Нет доступа к камере/микрофону. Разрешите в настройках и попробуйте снова.',
  );
  static const errorTokenInvalid = CallCopy(
    he: 'הטוקן של Agora אינו תקין. מרענן ומנסה שוב.',
    en: 'Invalid Agora token — refreshing and retrying.',
    ru: 'Недействительный токен Agora — обновление и повторная попытка.',
  );
  static const errorTokenExpired = CallCopy(
    he: 'הטוקן פג תוקף — מחדש ומחבר מחדש.',
    en: 'Token expired — renewing and reconnecting.',
    ru: 'Срок токена истёк — обновляем и переподключаемся.',
  );
  static const errorNetwork = CallCopy(
    he: 'החיבור אבד. מנסה לחדש אוטומטית.',
    en: 'Connection lost — attempting to recover.',
    ru: 'Связь потеряна — пробуем восстановить.',
  );
  static const errorMedia = CallCopy(
    he: 'מדיה (מצלמה/מיקרופון) לא זמינה. אפשר להמשיך בצ׳אט.',
    en: 'Media (camera/microphone) unavailable. You can continue in chat.',
    ru: 'Медиа недоступно (камера/микрофон). Можно продолжить в чате.',
  );
  static const errorGeneric = CallCopy(
    he: 'אירעה שגיאה בלתי צפויה. נסה להיכנס שוב.',
    en: 'Something went wrong. Please rejoin the call.',
    ru: 'Произошла ошибка. Попробуйте войти заново.',
  );
  static const errorUidConflict = CallCopy(
    he: 'מזהה משתמש כפול או הצטרפות נדחתה. נסה שוב — אם זה נמשך, רענן את הדף.',
    en: 'Duplicate user ID or join was rejected. Retry — if it persists, refresh the page.',
    ru: 'Конфликт ID или вход отклонён. Повторите; при повторении обновите страницу.',
  );
  static const webStartCall = CallCopy(
    he: 'התחל שיחת וידאו',
    en: 'Start video call',
    ru: 'Начать видеозвонок',
  );
  static const webStartCallHint = CallCopy(
    he: 'בדפדפן יש ללחוץ כדי לאפשר מצלמה ומיקרופון.',
    en: 'Browsers require a tap before camera and microphone can start.',
    ru: 'Браузеру нужно нажатие, чтобы включить камеру и микрофон.',
  );
  static const webInsecureContext = CallCopy(
    he: 'שיחת וידאו זמינה רק ב־HTTPS (או localhost). פתח את האתר בכתובת מאובטחת.',
    en: 'Video calls need HTTPS (or localhost). Open the app on a secure URL.',
    ru: 'Видеозвонок доступен только по HTTPS или localhost.',
  );
  static const errorRetry =
      CallCopy(he: 'נסה שוב', en: 'Retry', ru: 'Повторить');
  static const errorExit = CallCopy(he: 'יציאה', en: 'Exit', ru: 'Выйти');

  // ── Post-call vault save dialog ─────────────────────────────
  static const vaultSaveTitle = CallCopy(
    he: 'לשמור בכספת?',
    en: 'Save to vault?',
    ru: 'Сохранить в сейф?',
  );
  static const vaultSaveSubtitle = CallCopy(
    he: 'בחר מה לשמור לפני סגירת המסך.',
    en: 'Choose what to save before closing.',
    ru: 'Выберите, что сохранить перед закрытием.',
  );
  static const vaultSaveMediaOnly = CallCopy(
    he: 'שמור הקלטה בלבד (ללא תמלול)',
    en: 'Save recording only (no transcription)',
    ru: 'Только запись (без расшифровки)',
  );
  static const vaultSaveMediaAndTranscript = CallCopy(
    he: 'שמור הקלטה + תמלול (מומלץ)',
    en: 'Save recording + transcription (recommended)',
    ru: 'Запись + расшифровка (рекомендуется)',
  );
  static const vaultSaveChatOnly = CallCopy(
    he: 'שמור צ׳אט בלבד',
    en: 'Save chat only',
    ru: 'Только чат',
  );
  static const vaultSaveSkip = CallCopy(
    he: 'לא עכשיו',
    en: 'Not now',
    ru: 'Не сейчас',
  );
  static const vaultWebNoLocalRecording = CallCopy(
    he:
        'בדפדפן אין כרגע הקלטת קובץ מקומית מהשיחה. אפשר לשמור את הצ׳אט אם כתבת הודעות. במובייל נשמרת גם הקלטת האודיו/וידאו.',
    en:
        'The browser cannot save a local call file yet. You can save chat if you typed messages. On mobile, audio/video recording is saved.',
    ru:
        'В браузере пока нет локальной записи звонка. Можно сохранить чат. На мобильных запись сохраняется.',
  );
  static const vaultNothingToSave = CallCopy(
    he: 'אין הקלטה או צ׳אט לשמירה.',
    en: 'Nothing to save (no recording or chat).',
    ru: 'Нечего сохранить.',
  );

  // ── Network quality chip ────────────────────────────────────
  static const qualityExcellent =
      CallCopy(he: 'מעולה', en: 'Excellent', ru: 'Отлично');
  static const qualityGood = CallCopy(he: 'טובה', en: 'Good', ru: 'Хорошо');
  static const qualityFair = CallCopy(he: 'בינונית', en: 'Fair', ru: 'Средне');
  static const qualityPoor = CallCopy(he: 'גרועה', en: 'Poor', ru: 'Плохо');
  static const qualityVeryPoor =
      CallCopy(he: 'נוראית', en: 'Very poor', ru: 'Очень плохо');
}
