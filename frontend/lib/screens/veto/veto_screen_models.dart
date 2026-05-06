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

// ── Scenarios (aligned with 2026/citizen.html — 6 tiles + detail + rich rights) ──
enum _Scenario {
  policeInquiry,
  trafficStop,
  civilDispute,
  labor,
  family,
  consumer,
}

IconData _scenarioIcon(_Scenario s) {
  switch (s) {
    case _Scenario.policeInquiry:
      return Icons.shield_rounded;
    case _Scenario.trafficStop:
      return Icons.directions_car_filled_rounded;
    case _Scenario.civilDispute:
      return Icons.balance_rounded;
    case _Scenario.labor:
      return Icons.work_rounded;
    case _Scenario.family:
      return Icons.family_restroom_rounded;
    case _Scenario.consumer:
      return Icons.shopping_bag_rounded;
  }
}

/// Numbered “rich” right row (mockup `.rights .rich`).
class _ScenarioRight {
  const _ScenarioRight({
    required this.tHe,
    required this.tRu,
    required this.tEn,
    required this.dHe,
    required this.dRu,
    required this.dEn,
    this.exHe,
    this.exRu,
    this.exEn,
  });

  final String tHe, tRu, tEn;
  final String dHe, dRu, dEn;
  final String? exHe, exRu, exEn;
}

class _SD {
  const _SD({
    required this.emoji,
    required this.he,
    required this.ru,
    required this.en,
    required this.tileDHe,
    required this.tileDRu,
    required this.tileDEn,
    required this.headSubHe,
    required this.headSubRu,
    required this.headSubEn,
    required this.knowHe,
    required this.knowRu,
    required this.knowEn,
    required this.firstHe,
    required this.firstRu,
    required this.firstEn,
    required this.warnHe,
    required this.warnRu,
    required this.warnEn,
    required this.rHe,
    required this.rRu,
    required this.rEn,
    this.rich,
  });

  final String emoji, he, ru, en;
  final String tileDHe, tileDRu, tileDEn;
  final String headSubHe, headSubRu, headSubEn;
  final List<String> knowHe, knowRu, knowEn;
  final List<String> firstHe, firstRu, firstEn;
  final String warnHe, warnRu, warnEn;
  final List<String> rHe, rRu, rEn;
  final List<_ScenarioRight>? rich;
}

const Map<_Scenario, _SD> _sdMap = {
  _Scenario.policeInquiry: _SD(
    emoji: '\u{1F46E}',
    he: 'חקירה במשטרה',
    ru: 'Допрос в полиции',
    en: 'Police inquiry',
    tileDHe: 'זימון, חקירה תחת אזהרה, מעצר',
    tileDRu: 'Вызов, допрос с предупреждением, арест',
    tileDEn: 'Summons, caution interview, custody',
    headSubHe: 'זימון לחקירה · חקירה תחת אזהרה · מעצר ראשוני',
    headSubRu: 'Вызов на допрос · допрос с предупреждением · задержание',
    headSubEn: 'Summons · caution interview · initial custody',
    knowHe: [
      'זימון לחקירה אינו "המלצה" — יש לך זכות להתייעץ עם עו"ד לפני שתגיע.',
      'בחקירה תחת אזהרה כל מילה שתאמר נרשמת ויכולה לשמש נגדך בבית המשפט.',
      'שתיקה אינה הפללה — זו זכות יסוד מוגנת בחוק.',
      'חוקר חייב לאפשר לך התייעצות עם עורך דין לפני תחילת החקירה.',
    ],
    knowRu: [
      'Повестка — не «совет»: вы имеете право проконсультироваться с адвокатом до визита.',
      'На допросе с предупреждением каждое слово фиксируется и может использоваться в суде.',
      'Молчание не равно признанию вины — это охраняемое право.',
      'Следователь обязан дать возможность связаться с адвокатом до начала.',
    ],
    knowEn: [
      'A summons is not optional advice — you can consult counsel before you go.',
      'In a caution interview, what you say is recorded and may be used in court.',
      'Silence is not an admission — it is a protected right.',
      'You should be allowed to speak to a lawyer before questioning starts.',
    ],
    firstHe: [
      'אל תענה לשאלות עד שיחה ראשונה עם עו"ד מטעמך.',
      'תעד את שעת ההגעה, שם החוקר, ומספר תיק החקירה.',
      'בקש בכתב את העילה לזימון ואת סעיף החוק הרלוונטי.',
    ],
    firstRu: [
      'Не отвечайте на вопросы до первой консультации с адвокатом.',
      'Зафиксируйте время прибытия, имя следователя и номер дела.',
      'Письменно запросите основание вызова и статью закона.',
    ],
    firstEn: [
      'Do not answer questions until you have spoken to your lawyer.',
      'Record arrival time, investigator name, and file reference.',
      'Ask in writing for the basis of the summons and the relevant offence.',
    ],
    warnHe:
        '60 הדקות הראשונות מקבלות משקל מכריע. הקש SOS עכשיו וקבל ייעוץ ראשוני לפני שתשיב לשאלה הראשונה.',
    warnRu:
        'Первые 60 минут решают многое. Нажмите SOS сейчас и получите первичную консультацию до первых ответов.',
    warnEn:
        'The first 60 minutes carry outsized weight. Press SOS now for guidance before you answer the first question.',
    rHe: [
      'זכות לעו"ד לפני ובמהלך חקירה',
      'זכות שתיקה מפורשת',
      'זכות לדעת את החשד והסעיף',
      'זכות לעותק מההודעה',
      'זכות לסרב לחיפוש בלי עילה',
    ],
    rRu: ['Право на адвоката', 'Право на молчание', 'Право знать обвинение', 'Копия протокола', 'Отказ от незаконного обыска'],
    rEn: ['Counsel before/during interview', 'Explicit silence right', 'Know the allegation', 'Copy of statement', 'Refuse unlawful search'],
    rich: [
      _ScenarioRight(
        tHe: 'הזכות להיוועץ עם עורך דין',
        tRu: 'Право на адвоката',
        tEn: 'Right to consult a lawyer',
        dHe:
            'זכות יסוד מעוגנת בחוק. זכותך לקבל ייעוץ משפטי לפני, במהלך, ואחרי החקירה — בכל שלב, בלי תלות בחומרת העבירה. אם נמנעת ממך — בקש לתעד זאת בפרוטוקול.',
        dRu:
            'Фундаментальное право на консультацию до, во время и после допроса. Если вам отказывают — просите зафиксировать это в протоколе.',
        dEn:
            'You can seek legal advice before, during, and after questioning. If this is denied, ask for it to be recorded in the log.',
        exHe:
            'דוגמה ישימה: גם בעצירה ברחוב — בקש "אני מבקש לדבר עם עורך דין לפני המשך השיחה". זה מספיק.',
        exRu: 'Пример: «Прошу связать меня с адвокатом перед продолжением беседы» — этого достаточно.',
        exEn: 'Example: “I want to speak to a lawyer before we continue.” That is enough.',
      ),
      _ScenarioRight(
        tHe: 'הזכות לשמור על שתיקה',
        tRu: 'Право хранить молчание',
        tEn: 'Right to remain silent',
        dHe:
            'אינך חייב להשיב לשאלה שעלולה להפליל אותך. שתיקה אינה מהווה הודאה בעובדות. ציין במפורש שאתה בוחר לשמור על שתיקה — ולא פשוט לשתוק.',
        dRu:
            'Вы не обязаны отвечать на вопросы, которые могут вас инкриминировать. Молчание — не признание. Заявите это явно.',
        dEn:
            'You need not answer self-incriminating questions. Silence is not an admission. State clearly that you are remaining silent.',
        exHe: 'נוסח מומלץ: "אני שומר על זכות השתיקה ומבקש להתייעץ עם עורך דיני לפני המשך החקירה."',
        exRu: 'Фраза: «Пользуюсь правом молчания и прошу адвоката до продолжения допроса.»',
        exEn: 'Suggested wording: “I am exercising my right to silence and want my lawyer before we continue.”',
      ),
      _ScenarioRight(
        tHe: 'הזכות לדעת על מה אתה נחקר',
        tRu: 'Право знать предмет допроса',
        tEn: 'Right to know what you are questioned about',
        dHe:
            'לפני תחילת החקירה — חוקר חייב להציג בפניך את החשד המיוחס לך, את סעיף החוק הרלוונטי, ולהזהירך אם החקירה תחת אזהרה. אל תוותר על שלב זה.',
        dRu:
            'Перед началом должны разъяснить подозрение, статью и предупредить о режиме допроса. Не пропускайте этот этап.',
        dEn:
            'Before questioning, you should hear the allegation, law reference, and whether it is a caution interview. Do not skip this step.',
        exHe: 'דוגמה ישימה: בסיום החקירה — בקש: "אני מבקש עותק של הודעתי בכתב."',
        exRu: 'В конце попросите письменную копию ваших показаний.',
        exEn: 'At the end, ask for a written copy of your statement.',
      ),
      _ScenarioRight(
        tHe: 'הזכות לקבל עותק מתועד של ההודעה',
        tRu: 'Право на копию показаний',
        tEn: 'Right to a documented copy',
        dHe:
            'לאחר חתימה על הודעתך — אתה רשאי לקבל עותק. ב-VETO, אם אישרת תיעוד, השיחה נשמרת בכספת המוצפנת שלך.',
        dRu: 'После подписания вы вправе получить копию. В VETO при согласии запись может храниться в вашем защищённом архиве.',
        dEn: 'After signing, you may receive a copy. In VETO, with consent, the session can be stored in your encrypted vault.',
      ),
      _ScenarioRight(
        tHe: 'הזכות לסירוב לבדיקה לא חוקית',
        tRu: 'Отказ от незаконного обыска',
        tEn: 'Refusing unlawful searches',
        dHe:
            'חיפוש בגוף, ברכב, או בטלפון — מותנה בעילה חוקית או צו. אם אינך בטוח, בקש להמתין עד הגעת עו"ד.',
        dRu: 'Обыск тела, авто или телефона — только при законном основании или ордере. При сомнении просите ждать адвоката.',
        dEn: 'Searches of person, car, or phone need lawful grounds or a warrant. If unsure, wait for counsel.',
      ),
    ],
  ),
  _Scenario.trafficStop: _SD(
    emoji: '\u{1F697}',
    he: 'עצירת תנועה',
    ru: 'Остановка транспорта',
    en: 'Traffic stop',
    tileDHe: 'מהירות, אלכוהול, רישיון',
    tileDRu: 'Скорость, алкоголь, права',
    tileDEn: 'Speed, alcohol, license',
    headSubHe: 'בדיקת זהות · דוח · חיפוש ברכב (רק בעילה)',
    headSubRu: 'Проверка документов · протокол · обыск (только по основанию)',
    headSubEn: 'ID check · citation · vehicle search (lawful basis only)',
    knowHe: [
      'חובה להציג רישיון נהיגה, רישיון רכב וביטוח חוקי — לא בהכרח לענות על שאלות חקירתיות.',
      'חיפוש ברכב דורש הסכמה או עילה חוקית; אפשר לציין שאינך מסכים.',
      'צילום השוטר והרכב אינו עבירה כשהדבר נעשה מבלי להפריע לתפקיד.',
      'במקרה של חשד לנהיגה בשכרות — בקשו הבהרה על הבדיקה והזכויות.',
    ],
    knowRu: [
      'Права, техпаспорт и страховка — да; на допросительные вопросы отвечать не обязаны.',
      'Обыск авто — только по закону или согласию.',
      'Съёмка на телефон законна, если не мешаете работе.',
      'При подозрении на опьянение уточните процедуру.',
    ],
    knowEn: [
      'You must show license, registration, and valid insurance — not necessarily answer investigative questions.',
      'Vehicle searches require consent or lawful grounds.',
      'Filming from a safe distance is generally allowed.',
      'If impairment is alleged, clarify the procedure.',
    ],
    firstHe: [
      'הצג מסמכים בלבד, שמור על נימוס ועל שפה ברורה.',
      'אל תחתום על מסמך שאינך מבין — בקש העתק או המתן לעו"ד.',
      'תעד מספר רכב שוטר ושם תחנת בסיס אם רלוונטי.',
    ],
    firstRu: [
      'Покажите документы, говорите спокойно.',
      'Не подписывайте непонятные бумаги — ждите адвоката.',
      'Зафиксируйте номер экипажа и подразделение.',
    ],
    firstEn: [
      'Provide documents calmly.',
      'Do not sign papers you do not understand.',
      'Note the unit or badge reference if safe to do so.',
    ],
    warnHe:
        'הודאה בשיחה קצרה יכולה לשמש בבית משפט. אם יש חשד לעבירה חמורה — עצור, התייעץ, ואז המשך.',
    warnRu: 'Случайная фраза может быть использована в суде. При серьёзном обвинении — стоп и адвокат.',
    warnEn: 'Casual admissions can be used in court. For serious allegations, pause and get counsel.',
    rHe: ['מסמכי רכב חובה', 'סירוב לחיפוש ללא עילה', 'תיעוד מקום העצירה', 'לא לחתום בלי הבנה'],
    rRu: ['Документы на авто', 'Отказ от незаконного обыска', 'Фиксация места', 'Без подписи вслепую'],
    rEn: ['Vehicle paperwork', 'Unlawful search refusal', 'Record the stop location', 'No blind signatures'],
    rich: [
      _ScenarioRight(
        tHe: 'חובת הצגת מסמכים',
        tRu: 'Обязанность предъявить документы',
        tEn: 'Duty to show documents',
        dHe: 'רישיון נהיגה, רישיון רכב ותעודת ביטוח חוקית — זה השלב הבסיסי. שאר השאלות — לשיקול דעתך מול עו"ד.',
        dRu: 'Водительские права, техпаспорт и страховка — минимум. Остальное — с адвокатом.',
        dEn: 'License, registration, and insurance are the baseline. Other questions — discuss with counsel.',
      ),
      _ScenarioRight(
        tHe: 'חיפוש ברכב',
        tRu: 'Обыск автомобиля',
        tEn: 'Vehicle search',
        dHe: 'ללא הסכמתך או ללא עילה — אפשר לציין סירוב מנומק. אל תשתמש באלימות; תעד את העובדות.',
        dRu: 'Без согласия или основания — вежливый отказ и фиксация фактов.',
        dEn: 'Without consent or grounds — state a polite refusal and document facts.',
      ),
      _ScenarioRight(
        tHe: 'דוח וחתימה',
        tRu: 'Протокол и подпись',
        tEn: 'Citation and signature',
        dHe: 'קרא לפני חתימה. אם יש טעות — בקש תיקון בכתב. שמור העתק לתיק ב-VETO.',
        dRu: 'Читайте перед подписью, требуйте исправления ошибок, храните копию.',
        dEn: 'Read before signing, ask for written corrections, keep a copy in VETO.',
      ),
      _ScenarioRight(
        tHe: 'איסוף ראיות ויזואליות',
        tRu: 'Визуальные доказательства',
        tEn: 'Visual evidence',
        dHe: 'צלם נזק, מיקום, תנאי דרך — בלי להסתכן ובלי להפריע לשוטרים.',
        dRu: 'Снимайте повреждения и обстановку безопасно.',
        dEn: 'Photograph damage and scene safely without interference.',
      ),
    ],
  ),
  _Scenario.civilDispute: _SD(
    emoji: '\u2696',
    he: 'סכסוך אזרחי',
    ru: 'Гражданский спор',
    en: 'Civil dispute',
    tileDHe: 'חוזה, נדל"ן, נזיקין',
    tileDRu: 'Договор, недвижимость, вред',
    tileDEn: 'Contract, property, tort',
    headSubHe: 'מכתבים · מו״מ · הליכים',
    headSubRu: 'Переписка · переговоры · процедуры',
    headSubEn: 'Correspondence · negotiation · procedure',
    knowHe: [
      'שימור ראיות: חוזים, הודעות, הקלטות מותרות — לפי דין.',
      'מועדי תגובה בכתב חשובים; פספוס עלול לפגוע בעמדה.',
      'פנייה מוקדמת לעו"ד מונעת טעויות בניסוח.',
    ],
    knowRu: [
      'Сохраняйте переписку и документы.',
      'Сроки ответов критичны.',
      'Ранний адвокат снижает риски формулировок.',
    ],
    knowEn: [
      'Preserve contracts and messages lawfully.',
      'Written deadlines matter.',
      'Early counsel prevents bad admissions.',
    ],
    firstHe: [
      'ארוז מסמכים בסדר כרונולוגי והעלה עותק מוצפן לכספת.',
      'הימנע מהודאות בווטסאפ — רק עובדות ותאריכים.',
      'בקשו חוות דעת לפני חתימה על הסכם פשרה.',
    ],
    firstRu: ['Соберите хронологию', 'Не делайте признаний в мессенджере', 'Проверьте мировую до подписи'],
    firstEn: ['Build a timeline', 'Avoid chat admissions', 'Review any settlement draft'],
    warnHe: 'חתימה מהירה על סעיף "סופי" יכולה לסגור זכויות. עצור לבדיקה משפטית.',
    warnRu: 'Быстрая подпись «окончательного» текста закрывает права — проверьте с адвокатом.',
    warnEn: 'Rushing a “final” signature can waive rights — get review.',
    rHe: ['שימור ראיות', 'בדיקת תקנות צרכנות', 'בוררות מול בית משפט'],
    rRu: ['Доказательства', 'Потребительское право', 'Арбитраж или суд'],
    rEn: ['Evidence hygiene', 'Consumer rules', 'Arbitration vs court'],
    rich: [
      _ScenarioRight(
        tHe: 'תיעוד החוזה וההתכתבות',
        tRu: 'Договор и переписка',
        tEn: 'Contract trail',
        dHe: 'כל סטייה מהסכם צריכה מסמך או הודעה מתועדת. צלם מסך או שמור PDF לכספת.',
        dRu: 'Любое отклонение фиксируйте документально.',
        dEn: 'Document any departure from the agreement.',
      ),
      _ScenarioRight(
        tHe: 'נזקים ושווי תביעה',
        tRu: 'Убытки и оценка',
        tEn: 'Damages framing',
        dHe: 'פרט נזק ישיר, עקיף וממושכן — עם חשבוניות ואומדנים.',
        dRu: 'Прямой и косвенный ущерб — с чеками и оценкой.',
        dEn: 'List direct and consequential losses with invoices.',
      ),
      _ScenarioRight(
        tHe: 'מועדי התיישנות',
        tRu: 'Сроки исковой давности',
        tEn: 'Limitation periods',
        dHe: 'בדוק מועד אחרון להגשה — איחור עלול לסגור דלת.',
        dRu: 'Проверьте сроки подачи иска.',
        dEn: 'Check filing deadlines early.',
      ),
      _ScenarioRight(
        tHe: 'גישור לפני הליך',
        tRu: 'Медиация',
        tEn: 'Mediation first',
        dHe: 'בחלק מהמסלולים חובת גישור — שקול עלות־תועלת מול הליך מלא.',
        dRu: 'Иногда медиация обязательна — оцените с адвокатом.',
        dEn: 'Some tracks require mediation — weigh cost/benefit.',
      ),
    ],
  ),
  _Scenario.labor: _SD(
    emoji: '\u{1F4BC}',
    he: 'דיני עבודה',
    ru: 'Трудовое право',
    en: 'Labor law',
    tileDHe: 'פיטורין, זכויות, הטרדה',
    tileDRu: 'Увольнение, права, домогательства',
    tileDEn: 'Termination, rights, harassment',
    headSubHe: 'חוזה · שכר · שימוע',
    headSubRu: 'Контракт · зарплата · слушание',
    headSubEn: 'Contract · pay · hearing',
    knowHe: [
      'מכתב פיטורים בכתב ומועדי תשלום פיצויים — לבדוק מול חוק.',
      'יומן שעות ושכר שומרים על זכויות בפועל.',
      'הטרדה מינית או מעשה לוואי — תיעוד מוקדם חשוב.',
    ],
    knowRu: ['Письменное увольнение и расчёты', 'Учёт часов', 'Документируйте домогательства'],
    knowEn: ['Written termination and payouts', 'Time records matter', 'Document harassment early'],
    firstHe: [
      'שמור כל מייל/ווטסאפ מהמעסיק — העלה לכספת.',
      'בקש פרוטוקול שימוע אם חלה חובה.',
      'פנה לייעוץ לפני חתימה על נסיגה או סעיף שקט.',
    ],
    firstRu: ['Архивируйте переписку', 'Требуйте протокол', 'Не подписывайте молчание без адвоката'],
    firstEn: ['Archive employer messages', 'Request hearing minutes', 'No silence agreement blind-signed'],
    warnHe: 'חתימה על "התנתקות בהסכמה" ללא בדיקה — עלולה לוותר על סכומים משמעותיים.',
    warnRu: 'Подпись «по соглашению» без проверки — риск потери выплат.',
    warnEn: 'Signing a severance without review can waive major sums.',
    rHe: ['שכר מינימום והפרשות', 'דמי הבראה והחזר נסיעות', 'זכות שימוע'],
    rRu: ['Минимальная оплата', 'Отпускные', 'Право на слушание'],
    rEn: ['Minimum pay rules', 'Benefits accrual', 'Hearing rights'],
    rich: [
      _ScenarioRight(
        tHe: 'בדיקת חוזה ותקן',
        tRu: 'Контракт и колдоговор',
        tEn: 'Contract & policies',
        dHe: 'סעיפי ניסיון, הודעה מוקדמת ותנאי שינוי תפקיד — יש לפרש מול חוק הגנת העבודה.',
        dRu: 'Испытательный срок, уведомление и перевод — сверяйте с законом.',
        dEn: 'Probation, notice, and role changes — check against statute.',
      ),
      _ScenarioRight(
        tHe: 'פיטורין מיידיים',
        tRu: 'Немедленное увольнение',
        tEn: 'Summary dismissal',
        dHe: 'נדרשת עילה חמורה ופרוצדורה — אל תוותר על עיון משפטי.',
        dRu: 'Нужны тяжёлые основания и процедура.',
        dEn: 'Serious cause and process are required.',
      ),
      _ScenarioRight(
        tHe: 'תלונות פנימיות',
        tRu: 'Внутренние жалобы',
        tEn: 'Internal complaints',
        dHe: 'תיעוד תלונה ל-HR או גורם ממונה שומר על קו זמן ברור.',
        dRu: 'Письменная жалоба фиксирует временную линию.',
        dEn: 'A written complaint preserves a timeline.',
      ),
      _ScenarioRight(
        tHe: 'הליכים חיצוניים',
        tRu: 'Внешние инстанции',
        tEn: 'External forums',
        dHe: 'בהתאם למקרה — בית דין לעבודה או גורמים ממונים; ייעוץ קובע מסלול.',
        dRu: 'Трудовой суд или инспекции — выбор с адвокатом.',
        dEn: 'Labor court or agencies — route with counsel.',
      ),
    ],
  ),
  _Scenario.family: _SD(
    emoji: '\u{1F46A}',
    he: 'דיני משפחה',
    ru: 'Семейное право',
    en: 'Family law',
    tileDHe: 'גירושין, ילדים, מזונות',
    tileDRu: 'Развод, дети, алименты',
    tileDEn: 'Divorce, children, support',
    headSubHe: 'הסכמים · צווי ביניים · רווחת הילד',
    headSubRu: 'Соглашения · временные решения · благо детей',
    headSubEn: 'Agreements · interim orders · child welfare',
    knowHe: [
      'רווחת הילדים במרכז — תיעדו הסכמות זמניות בכתב.',
      'נכסים משותפים דורשים גילוי נאות מלא.',
      'אל תשתמשו בילדים כמנוף במסרים — זה פוגע בתיק.',
    ],
    knowRu: ['Интересы детей прежде всего', 'Полное раскрытие активов', 'Не используйте детей в переписке'],
    knowEn: ['Child welfare first', 'Full financial disclosure', 'Do not weaponise kids in messages'],
    firstHe: [
      'אספו מסמכי הכנסה, חשבונות בנק ותשלומי מזונות קודמים.',
      'שמרו יומן מגורים וזמני שהות.',
      'כל פגישה עם עו"ד — עם רשימת שאלות מסודרת.',
    ],
    firstRu: ['Соберите финансы', 'Дневник проживания', 'Готовьте вопросы к адвокату'],
    firstEn: ['Gather income docs', 'Parenting time log', 'Prepare questions for counsel'],
    warnHe: 'הסכמי פשרה בלחץ — עלולים להיות בלתי הפיכים. קבלו ליווי.',
    warnRu: 'Соглашения под давлением трудно отменить — нужен адвокат.',
    warnEn: 'Pressured settlements are hard to unwind — get advice.',
    rHe: ['מזונות ילדים', 'משמורת וסידורי שהות', 'חלוקת רכוש'],
    rRu: ['Алименты', 'Опека и график', 'Раздел имущества'],
    rEn: ['Child support', 'Custody & access', 'Asset division'],
    rich: [
      _ScenarioRight(
        tHe: 'סדרי שהות',
        tRu: 'График общения',
        tEn: 'Parenting schedule',
        dHe: 'מיפוי שבועי/חגים מפחית סכסוך; עדיף נוסח מדויק מאשר "בהסכמה כללית".',
        dRu: 'Детальный график снижает конфликт.',
        dEn: 'Specific schedules beat vague “mutual agreement”.',
      ),
      _ScenarioRight(
        tHe: 'מזונות',
        tRu: 'Алименты',
        tEn: 'Support',
        dHe: 'הצגת הכנסות אמיתיות, הוצאות מיוחדות וצרכי הילד — מסמכים מעודכנים.',
        dRu: 'Доходы, особые расходы, потребности ребёнка — актуальные документы.',
        dEn: 'Income, special expenses, child needs — keep docs current.',
      ),
      _ScenarioRight(
        tHe: 'רכוש וחובות',
        tRu: 'Имущество и долги',
        tEn: 'Property & debts',
        dHe: 'רישום בטאבו, משכנתאות והלוואות משותפות — מיפוי מלא לפני פשרה.',
        dRu: 'Недвижимость и кредиты — полная карта.',
        dEn: 'Map mortgages and joint loans before settling.',
      ),
      _ScenarioRight(
        tHe: 'הגנה מפני אלימות',
        tRu: 'Защита от насилия',
        tEn: 'Safety planning',
        dHe: 'במצבי סיכון — פנייה לגורמי חירום וצווי הגנה; VETO מחבר עו"ד רלוונטי.',
        dRu: 'При угрозе — экстренные службы и защитные ордера.',
        dEn: 'If unsafe — emergency services and protective orders; VETO can connect counsel.',
      ),
    ],
  ),
  _Scenario.consumer: _SD(
    emoji: '\u{1F6D2}',
    he: 'צרכנות',
    ru: 'Потребительское право',
    en: 'Consumer',
    tileDHe: 'החזר, אחריות, הונאה',
    tileDRu: 'Возврат, гарантия, мошенничество',
    tileDEn: 'Refund, warranty, fraud',
    headSubHe: 'חשבונית · אחריות יצרן · ערוצי תלונה',
    headSubRu: 'Чек · гарантия · жалобы',
    headSubEn: 'Receipt · warranty · complaints',
    knowHe: [
      'שמירת חשבונית דיגיטלית מקצרת הוכחה.',
      'אחריות משתנה לפי סוג מוצר — בדקו תקנות צרכנות.',
      'עסקאות מרחוק מעניקות זמני ביטול מוגדרים.',
    ],
    knowRu: ['Цифровой чек', 'Гарантийные сроки', 'Отмена дистанционной сделки'],
    knowEn: ['Keep digital receipts', 'Warranty rules vary', 'Cooling-off on remote deals'],
    firstHe: [
      'שלחו בקשת החזר בכתב (מייל/טופס) והעתיקו לכספת.',
      'תעדו שיחות שירות — תאריך ושם נציג.',
      'אם יש חשד להונאה — שמרו הוכחות תשלום וחסמו כרטיס.',
    ],
    firstRu: ['Письменный запрос возврата', 'Лог звонков', 'При мошенничестве — блок карты'],
    firstEn: ['Written refund request', 'Log support calls', 'If fraud — preserve payment proof, block card'],
    warnHe: 'לחץ "לחתום עכשיו" עם הנחה חריגה — לעיתים מסתיר תנאי דרסטי. עצרו לבדיקה.',
    warnRu: '«Подпиши сейчас» со скидкой может скрывать условия — проверьте.',
    warnEn: 'Flash discounts can hide harsh terms — pause and review.',
    rHe: ['החזר כספי', 'תיקון או החלפה', 'תביעה קטנה / הוצאה לפועל'],
    rRu: ['Возврат денег', 'Ремонт/замена', 'Мелкий иск'],
    rEn: ['Cash refund', 'Repair/replace', 'Small claims path'],
    rich: [
      _ScenarioRight(
        tHe: 'מסמכי רכישה',
        tRu: 'Документы покупки',
        tEn: 'Purchase proof',
        dHe: 'חשבונית מס, אישור הזמנה והודעות ספק — מגדירים זכות החזר.',
        dRu: 'Счёт и переписка с продавцом.',
        dEn: 'Invoice and vendor messages define remedies.',
      ),
      _ScenarioRight(
        tHe: 'אחריות יצרן מול ספק',
        tRu: 'Гарантия',
        tEn: 'Warranty routing',
        dHe: 'לפעמים הספק מחויב גם אם היצרן מתעכב — בדיקה משפטית קצרה חוסכת זמן.',
        dRu: 'Иногда ответственен продавец, даже если завод тянет.',
        dEn: 'Retailers may owe a remedy even if the brand delays.',
      ),
      _ScenarioRight(
        tHe: 'ערוצי תלונה',
        tRu: 'Жалобы',
        tEn: 'Complaint ladders',
        dHe: 'שירות → ממונה → גוף ציבורי רלוונטי; תיעוד כל שלב.',
        dRu: 'Эскалация по ступеням с доказательствами.',
        dEn: 'Escalate with evidence at each tier.',
      ),
      _ScenarioRight(
        tHe: 'הונאה מקוונת',
        tRu: 'Онлайн-мошенничество',
        tEn: 'Online fraud',
        dHe: 'שמירת צילומי מסך, כתובת אתר ופרטי העברה — לבקשת החזר מהבנק או רשות.',
        dRu: 'Скриншоты и реквизиты — для банка и жалобы.',
        dEn: 'Screenshots and transfer details for bank chargeback and reports.',
      ),
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
  /// True when assistant text came from Gemini Multimodal Live with native audio playback.
  final bool hadNativeAudio;
  _Msg({
    required this.text,
    required this.isUser,
    this.isSystem = false,
    this.hadNativeAudio = false,
  });
}
