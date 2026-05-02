import 'package:flutter/material.dart';
import '../core/theme/veto_tokens_2026.dart';
import 'package:flutter/services.dart';

/// Keys must match backend `SPEC_MAP` in `dispatch.socket.js` (Hebrew).
const kDispatchSpecializationsHe = <String>[
  'פלילי',
  'משפחה',
  'נדל"ן',
  'עבודה',
  'מסחרי',
  'תעבורה',
];

String _specRu(String he) {
  switch (he) {
    case 'פלילי':
      return 'Уголовное';
    case 'משפחה':
      return 'Семейное';
    case 'נדל"ן':
      return 'Недвижимость';
    case 'עבודה':
      return 'Трудовое';
    case 'מסחרי':
      return 'Коммерч.';
    case 'תעבורה':
      return 'ДТП / Дорожн.';
    default:
      return he;
  }
}

String _specEn(String he) {
  switch (he) {
    case 'פלילי':
      return 'Criminal';
    case 'משפחה':
      return 'Family';
    case 'נדל"ן':
      return 'Real estate';
    case 'עבודה':
      return 'Labor';
    case 'מסחרי':
      return 'Commercial';
    case 'תעבורה':
      return 'Traffic';
    default:
      return he;
  }
}

Future<String?> showDispatchSpecialtySheet(
  BuildContext context, {
  required String langKey,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: VetoTokens.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: VetoTokens.hairline),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.45), blurRadius: 24),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: VetoTokens.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              langKey == 'he'
                  ? 'בחר תחום עיסוק'
                  : langKey == 'ru'
                      ? 'Выберите область права'
                      : 'Choose legal practice area',
              style: const TextStyle(
                color: VetoTokens.ink900,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              langKey == 'he'
                  ? 'נאתר עורך דין זמין בתחום שנבחר'
                  : langKey == 'ru'
                      ? 'Мы найдём доступного адвоката'
                      : 'We will find an available lawyer in this field',
              style: const TextStyle(color: VetoTokens.ink500, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.55,
              ),
              itemCount: kDispatchSpecializationsHe.length,
              itemBuilder: (_, i) {
                final he = kDispatchSpecializationsHe[i];
                final label = langKey == 'he'
                    ? he
                    : langKey == 'ru'
                        ? _specRu(he)
                        : _specEn(he);
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(ctx, he);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: VetoTokens.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: VetoTokens.navy600.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: VetoTokens.ink900,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text(
                langKey == 'he'
                    ? 'ביטול'
                    : langKey == 'ru'
                        ? 'Отмена'
                        : 'Cancel',
                style: const TextStyle(color: VetoTokens.ink500),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<String?> showCitizenSessionModeSheet(
  BuildContext context, {
  required String langKey,
  String? lawyerName,
}) {
  final name = lawyerName ??
      (langKey == 'he'
          ? 'עורך דין'
          : langKey == 'ru'
              ? 'Адвокат'
              : 'Lawyer');
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: VetoTokens.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: VetoTokens.hairline),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.45), blurRadius: 24),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: VetoTokens.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              langKey == 'he'
                  ? '$name קיבל את הקריאה'
                  : langKey == 'ru'
                      ? '$name принял запрос'
                      : '$name accepted your request',
              style: const TextStyle(
                color: VetoTokens.ink900,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              langKey == 'he'
                  ? 'איך תרצה ליצור קשר?'
                  : langKey == 'ru'
                      ? 'Как связаться?'
                      : 'How would you like to connect?',
              style: const TextStyle(color: VetoTokens.ink500, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _sessionModeTile(
                    ctx,
                    Icons.phone_rounded,
                    langKey == 'he'
                        ? 'אודיו'
                        : langKey == 'ru'
                            ? 'Аудио'
                            : 'Audio',
                    VetoTokens.navy600,
                    'audio',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _sessionModeTile(
                    ctx,
                    Icons.videocam_rounded,
                    langKey == 'he'
                        ? 'וידאו'
                        : langKey == 'ru'
                            ? 'Видео'
                            : 'Video',
                    const Color(0xFF00C9B1),
                    'video',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _sessionModeTile(
                    ctx,
                    Icons.chat_rounded,
                    langKey == 'he'
                        ? 'צ\'ט'
                        : langKey == 'ru'
                            ? 'Чат'
                            : 'Chat',
                    const Color(0xFF8B5CF6),
                    'chat',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text(
                langKey == 'he'
                    ? 'ביטול'
                    : langKey == 'ru'
                        ? 'Отмена'
                        : 'Cancel',
                style: const TextStyle(color: VetoTokens.ink500),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _sessionModeTile(
  BuildContext ctx,
  IconData icon,
  String label,
  Color color,
  String value,
) {
  return GestureDetector(
    onTap: () {
      HapticFeedback.selectionClick();
      Navigator.pop(ctx, value);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: VetoTokens.ink900,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );
}
