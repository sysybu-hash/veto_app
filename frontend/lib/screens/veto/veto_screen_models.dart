// Split from veto_screen.dart — scenario wizard copy, languages, chat row model.
part of '../veto_screen.dart';

String? _mongoEventId(dynamic ev) {
  final id = ev['_id'];
  if (id == null) return null;
  if (id is String) return id.isEmpty ? null : id;
  if (id is Map) {
    final o = id[r'$oid'] ?? id['oid'];
    if (o != null) return o.toString();
  }
  final t = id.toString();
  return (t.isEmpty || t == 'null') ? null : t;
}

// ── Scenarios ─────────────────────────────────────────────
enum _Scenario { traffic, interrogation, arrest, accident, other }

IconData _scenarioIcon(_Scenario s) {
  switch (s) {
    case _Scenario.traffic:
      return Icons.directions_car_filled_rounded;
    case _Scenario.interrogation:
      return Icons.local_police_rounded;
    case _Scenario.arrest:
      return Icons.gavel_rounded;
    case _Scenario.accident:
      return Icons.medical_services_rounded;
    case _Scenario.other:
      return Icons.balance;
  }
}

class _SD {
  final String emoji, he, ru, en;
  final List<String> rHe, rRu, rEn;
  const _SD({
    required this.emoji,
    required this.he,
    required this.ru,
    required this.en,
    required this.rHe,
    required this.rRu,
    required this.rEn,
  });
}

const Map<_Scenario, _SD> _sdMap = {
  _Scenario.traffic: _SD(
    emoji: '\u{1F697}',
    he: 'עצירת תנועה',
    ru: 'Остановка авто',
    en: 'Traffic Stop',
    rHe: [
      'הצג תעודת זהות ורישיון נהיגה בלבד',
      'אינך חייב להסכים לחיפוש ברכב',
      'שמור על שתיקה מעבר לנתוני זיהוי',
      'צלם את רכב המשטרה ולוחית הרישוי',
      'בקש שם ומספר עטרה של השוטר',
    ],
    rRu: [
      'Предъявите только документы',
      'Не обязаны соглашаться на обыск авто',
      'Храните молчание сверх идентификации',
      'Сфотографируйте полицейскую машину',
      'Запросите имя и жетон офицера',
    ],
    rEn: [
      'Present ID and driving license only',
      'Not required to consent to vehicle search',
      'Remain silent beyond identification data',
      'Photograph the police vehicle and its plate',
      'Request the officer name and badge number',
    ],
  ),
  _Scenario.interrogation: _SD(
    emoji: '\u{1F46E}',
    he: 'חקירת משטרה',
    ru: 'Допрос',
    en: 'Police Questioning',
    rHe: [
      'יש לך זכות חוקתית לשתוק — אל תענה על שאלות',
      'דרוש עורך דין לפני תחילת כל חקירה',
      'כל דבר שתאמר יכול לשמש נגדך בבית משפט',
      'אינך חייב לחתום על מסמכים ללא ייעוץ משפטי',
      'הצהר: "שומר אני על זכות השתיקה"',
    ],
    rRu: [
      'Конституционное право хранить молчание',
      'Требуйте адвоката до начала допроса',
      'Всё сказанное может быть использовано против вас',
      'Не подписывайте документы без адвоката',
      'Заявите: "Я пользуюсь правом на молчание"',
    ],
    rEn: [
      'Constitutional right to remain silent — do not answer',
      'Demand a lawyer before any interrogation begins',
      'Anything you say can be used against you in court',
      'Do not sign documents without legal counsel',
      'State clearly: "I am exercising my right to silence"',
    ],
  ),
  _Scenario.arrest: _SD(
    emoji: '\u26D3',
    he: 'מעצר',
    ru: 'Арест',
    en: 'Arrest',
    rHe: [
      'יש לך זכות לעורך דין מיידי — דרוש זאת בקול',
      'יש לך זכות להודיע לבן משפחה על עצרתך',
      'שמור שתיקה מוחלטת לפני הגעת עורך הדין',
      'המשטרה חייבת לציין מהי עילת המעצר',
      'בקש עותק מצו המעצר',
    ],
    rRu: [
      'Право на немедленного адвоката',
      'Право сообщить родственнику об аресте',
      'Полное молчание до прибытия адвоката',
      'Полиция обязана назвать причину ареста',
      'Требуйте копию ордера на арест',
    ],
    rEn: [
      'Right to an immediate attorney — demand it aloud',
      'Right to notify a family member of your arrest',
      'Complete silence until your lawyer arrives',
      'Police must state the reason for your arrest',
      'Request a copy of the arrest warrant',
    ],
  ),
  _Scenario.accident: _SD(
    emoji: '\u{1F691}',
    he: 'תאונה',
    ru: 'ДТП',
    en: 'Accident',
    rHe: [
      'תעד נזקים לרכב מכל זווית — מיידית',
      'אסוף שמות ופרטי קשר של עדים',
      'אל תודה באחריות — לא לפני שדיברת עם עורך דין',
      'צלם לוחיות רישוי של כל הרכבים המעורבים',
      'הייוועץ עם עורך דין לפני שמוסר מידע לביטוח',
    ],
    rRu: [
      'Сфотографируйте все повреждения немедленно',
      'Соберите данные свидетелей',
      'Не признавайте вину без адвоката',
      'Сфотографируйте все номерные знаки',
      'Проконсультируйтесь с адвокатом перед страховой',
    ],
    rEn: [
      'Document all vehicle damage from every angle immediately',
      'Collect witness names and contact information',
      'Do not admit fault before consulting a lawyer',
      'Photograph all license plates involved',
      'Consult a lawyer before speaking to insurance',
    ],
  ),
  _Scenario.other: _SD(
    emoji: '\u2696',
    he: 'אחר',
    ru: 'Другое',
    en: 'Other',
    rHe: [
      'יש לך זכות לייצוג משפטי בכל הליך',
      'שמור על זכות השתיקה תמיד',
      'תעד הכל: צלם, הקלט, כתוב',
      'אל תחתום על שום מסמך ללא עורך דין',
      'VETO ישגר עורך דין לעמדתך בהקדם',
    ],
    rRu: [
      'Право на юридическое представительство',
      'Всегда пользуйтесь правом на молчание',
      'Документируйте всё: фото, аудио, запись',
      'Не подписывайте ничего без адвоката',
      'VETO направит адвоката к вам',
    ],
    rEn: [
      'Right to legal representation in any proceeding',
      'Always exercise your right to remain silent',
      'Document everything: photos, audio, written notes',
      'Do not sign anything without a lawyer present',
      'VETO will dispatch a lawyer to your location',
    ],
  ),
};

// ── Language labels ───────────────────────────────────────
class _LL {
  final String label,
      code,
      greeting,
      hint,
      processing,
      dispatching,
      protected,
      broadcasting;
  const _LL({
    required this.label,
    required this.code,
    required this.greeting,
    required this.hint,
    required this.processing,
    required this.dispatching,
    required this.protected,
    required this.broadcasting,
  });
}

const Map<String, _LL> _langs = {
  'he': _LL(
    label: 'עברית',
    code: 'he-IL',
    greeting:
        'שלום! אני העוזר המשפטי של VETO.\nתאר את הבעיה המשפטית שלך ואמצא עבורך עורך דין זמין.',
    hint: 'תאר את הבעיה...',
    processing: 'מעבד...',
    dispatching: 'בתהליך שיגור...',
    protected: 'מוגן',
    broadcasting: 'שידור פעיל',
  ),
  'ru': _LL(
    label: 'Русский',
    code: 'ru-RU',
    greeting:
        'Здравствуйте! Я юридический помощник VETO.\nОпишите вашу проблему — я найду адвоката.',
    hint: 'Опишите проблему...',
    processing: 'Обработка...',
    dispatching: 'Отправка...',
    protected: 'Защищён',
    broadcasting: 'Трансляция',
  ),
  'en': _LL(
    label: 'English',
    code: 'en-US',
    greeting:
        "Hello! I'm the VETO legal assistant.\nDescribe your legal issue and I'll find you an available lawyer.",
    hint: 'Describe your issue...',
    processing: 'Processing...',
    dispatching: 'Dispatching...',
    protected: 'Protected',
    broadcasting: 'Live broadcast',
  ),
};

// ── Chat message ──────────────────────────────────────────
class _Msg {
  final String text;
  final bool isUser, isSystem;
  _Msg({required this.text, required this.isUser, this.isSystem = false});
}
