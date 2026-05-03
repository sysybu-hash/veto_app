import 'package:flutter/material.dart';

import '../../core/theme/veto_2026.dart';
import 'call_i18n.dart';

class V26CallSecurityBadge extends StatelessWidget {
  const V26CallSecurityBadge({
    super.key,
    required this.language,
  });

  final String language;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_rounded,
            size: 13,
            color: V26.gold.withValues(alpha: 0.86),
          ),
          const SizedBox(width: 6),
          Text(
            CallI18n.aes256Footer.t(language),
            style: TextStyle(
              color: V26.gold.withValues(alpha: 0.86),
              fontFamily: V26.sans,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
