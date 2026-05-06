// ============================================================
//  legal_document_screen.dart — Privacy & Terms (template;
//  legal review is the operator's responsibility).
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_2026.dart';
import '../core/theme/veto_mockup_tokens.dart';

/// Which legal document to show.
enum LegalDocKind {
  privacy,
  terms,
}

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.kind});

  final LegalDocKind kind;

  static const _titles = <String, Map<LegalDocKind, String>>{
    'he': {
      LegalDocKind.privacy: 'מדיניות פרטיות',
      LegalDocKind.terms: 'תנאי שימוש',
    },
    'en': {
      LegalDocKind.privacy: 'Privacy Policy',
      LegalDocKind.terms: 'Terms of Service',
    },
    'ru': {
      LegalDocKind.privacy: 'Политика конфиденциальности',
      LegalDocKind.terms: 'Условия использования',
    },
  };

  static const _bodies = <String, Map<LegalDocKind, String>>{
    'he': {
      LegalDocKind.privacy: _kPrivacyHe,
      LegalDocKind.terms: _kTermsHe,
    },
    'en': {
      LegalDocKind.privacy: _kPrivacyEn,
      LegalDocKind.terms: _kTermsEn,
    },
    'ru': {
      LegalDocKind.privacy: _kPrivacyRu,
      LegalDocKind.terms: _kTermsRu,
    },
  };

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final lang = AppLanguage.normalize(code);
    final title = _titles[lang]?[kind] ?? _titles['en']![kind]!;
    final body = _bodies[lang]?[kind] ?? _bodies['en']![kind]!;
    final privacyLbl = _titles[lang]?[LegalDocKind.privacy] ??
        _titles['en']![LegalDocKind.privacy]!;
    final termsLbl =
        _titles[lang]?[LegalDocKind.terms] ?? _titles['en']![LegalDocKind.terms]!;

    return Scaffold(
      backgroundColor: VetoMockup.pageBackground,
      appBar: AppBar(
        backgroundColor: VetoMockup.surfaceCard,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: V26.serif,
            color: VetoMockup.ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: VetoMockup.ink),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: VetoMockup.hairline),
        ),
      ),
      body: V26Backdrop(
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: V26.paper2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: V26.hairline),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _DocTab(
                              label: privacyLbl,
                              active: kind == LegalDocKind.privacy,
                              onTap: () => Navigator.of(context)
                                  .pushReplacementNamed('/privacy'),
                            ),
                          ),
                          Expanded(
                            child: _DocTab(
                              label: termsLbl,
                              active: kind == LegalDocKind.terms,
                              onTap: () => Navigator.of(context)
                                  .pushReplacementNamed('/terms'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: V26.serif,
                        color: V26.ink900,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SelectableText(
                      body,
                      style: const TextStyle(
                        fontFamily: V26.serif,
                        color: V26.ink900,
                        fontSize: 16,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DocTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _DocTab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: active ? V26.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: active ? V26.shadow1 : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: V26.sans,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? V26.navy700 : V26.ink500,
            ),
          ),
        ),
      ),
    );
  }
}

// --- Template text (Hebrew) — replace/extend after legal review ----------------

const _kPrivacyHe = '''
VETO — מדיניות פרטיות (טיוטה)

1. מטרה
שירות VETO (“השירות”) מיועד לתגובה משפטית בזמן אמת, כולל התאמת אירוע, צ’אט, חיבור לנציג, ויומנים. מסמך זה מסביר בקצרה אילו נתונים עשויים להיאסף.

2. נתונים שאנו עשויים לעבד
- פרטי חשבון: טלפון, שם, דוא״ל (אם נמסר), ותפקיד (אזרח, עו״ד, אדמין).
- נתוני שימוש: בקשות API, יומנים תפעוליים, והודעות אבטחה.
- אירועי חירום, צ’אט, והקלטות/מסמכים שתעלו (כמפורט במוצר).
- נתוני מיקום או מפה אם המשתמש מפעיל תכונות אלה.
- Web Push/התראות, אם הופעל.

3. אחסון ומיקום
האפליקציה משתמשת בבסיסי נתונים בענן (למשל MongoDB Atlas) ובאחסון מדיה/ראיות (לפי מימוש, למשל Cloudinary). אחסון API עשוי להתבצע בפלטפורמות הוסטינג (למשל Render) ובאתר סטטי (למשל Vercel) ל־web.

4. אבטחה
העברת נתונים לרוב ב־TLS. אין “אבטחה מוחלטת” — אנו פועלים לצמצם סיכונים ומעדכנים שירותים. יש לשמור מכשיר וסיסמאות/אימותים.

5. שיתוף
לא נמכרים נתונים אישיים לשיווק. ספקים טכניים (אחסון, SMS, אנליטיקה) עשויים לעבד לפי צורך להפעלת השירות, בכפוף לחוזים ולדין.

6. שמירה
נשמרים לפי צורך בפעילות, חשבונאות, בטיחות ורגולציה, ולפי בקשה למחיקה כשהדין והמימוש מאפשרים.

7. זכויות
בהתאם לדין החל, אפשר לבקש גישה, תיקון או מחיקה, במגבלות (למשל חובות שמירה). פנייה: דרך הערוץ שתקצינו (מייל / תמיכה) — **יש להשלים כתובת בפועל**.

8. הערה משפטית
מסמך זה הוא **תבנית** ואינו ייעוץ משפטי. אימות אצל עו״ד לפי מדינה ותחום.
''';

const _kTermsHe = '''
VETO — תנאי שימוש (טיוטה)

1. השירות
VETO מספקת כלים לתמיכה בזרימה משפטית ושיגור/תיאום; **אינה תחליף לייעוץ, ייצוג בבית משפט או חוות דעת מחייבת**.

2. שימוש מותר
השימות לצרכים חוקיים בלבד. אסור לבצע ניסיונות פריצה, הטרדה, או ניצול לרעה של אחרים/שירות.

3. חשבון
אתם אחראים לנכונות פרטי הכניסה ולפעולות בחשבונכם. יש לעדכן אם הטלפון/האימייל מסתיימים בידי גורם אחר.

4. תוכן והעלאות
העלאת חומרים (ראיות, הקלטות) באחריותכם. אין לפגוע בזכויות של צד ג׳.

5. שינויים והפסקה
ייתכנו שינויים, השבתות תחזוקה, או הפסקת שירות לפי דין או אספקה.

6. אחריות
השירות **כפי שהוא (AS IS)**. במלוא המותר בדין, אחריות אצל המפעיל/הישות — לפי מה שיוגדר משפטית. יש **להשלים** הפרטים ברמת החברה.

7. שינויים לתנאים
ייתכןו עדכונים. המשך שימוש אחרי פרסום שינוי מהווה, ככל שהדין מאפשר, הסכה.

8. יצירת קשר
**[השלם כאן: מייל / פרטי מפעיל]**
''';

const _kPrivacyEn = '''
VETO — Privacy Policy (draft)

1. Purpose
VETO helps you respond in legal-urgency scenarios (AI chat, dispatch, calls, calendar features). This notice summarizes categories of data that may be processed.

2. Data we may process
- Account: phone, name, email (if provided), and role.
- Service data: events, messages, files/evidence, optional location/maps if you use those features, operational logs, security signals.
- Push: Web Push/FCM subject to your settings, when enabled.
- Vendors: hosting, DB, media, SMS/messaging, analytics — as required to run the product.

3. Storage
We use industry-standard cloud providers (e.g., MongoDB Atlas, optional Cloudinary, Render, Vercel) — your operator configures regions and retention.

4. Security
Data is generally encrypted in transit (TLS). You must also protect your device and account.

5. Sharing
No sale of personal data for ad profiling. Vendors may process on our instructions.

6. Retention
Driven by operations, law, and deletion requests you send through **your published support channel (fill in)**.

7. Rights
Depending on applicable law, you may have access, correction, or deletion rights.

8. Not legal advice; template only — have counsel review.
''';

const _kTermsEn = '''
VETO — Terms of Service (draft)

1. The service
VETO offers tools; it is **not** a substitute for legal advice, representation, or a guaranteed outcome in court.

2. Acceptable use
Lawful, respectful use. No attacks on the service or on people.

3. Your account
You are responsible for credentials and activity in your account.

4. Your content
You are responsible for what you upload and for respecting third-party rights.

5. Changes, downtime
The service may change, maintain, or be interrupted.

6. Disclaimer
As far as law allows, services are “AS IS”. The operating entity and liability limits must be set by your counsel.

7. Changes to these terms
We may update them; your continued use may mean acceptance, where the law says so.

8. Contact: **[add operator contact]**
''';

const _kPrivacyRu = '''
VETO — политика конфиденциальности (черновик)

1. Цель
VETO обрабатывает данные, необходимые для срочной правовой поддержки (события, чат, диспетчер, звонки, календарь). Здесь кратко, какие категории данных возможны.

2. Какие данные
Телефон, имя, e-mail, роль, аудио/доказательства, гео — если вы включаете карты, журналы, push.

3. Хостинг
Mongo/облачные поставщики, Render, Vercel, медиа-хранение — согласно настройкам.

4. Безопасность
TLS, но вы также защищаете устройство и учётные данные.

5. Права
Согласно применимому праву, возможны запросы на доступ/исправление/удаление через **контакт оператора (добавьте)**.

6. Не юридическая консультация; требуется рецензия юриста.
''';

const _kTermsRu = '''
VETO — условия использования (черновик)

1. Сервис не заменяет адвоката/представительства в суде.
2. Запрещены взлом, злоупотребления, незаконные действия.
3. Доступ и действия в аккаунте — ваша ответственность.
4. Контент, который вы загружаете, — ваша ответственность; учитывайте права третьих лиц.
5. Сервис может обновляться, останавливаться, изменяться.
6. “Как есть” — в пределах, разрешённых законом. Уточните лицо оператора.
7. Обновления: продолжение использования — при принятии, где требуется.
8. Контакт: **[укажите]**
''';
