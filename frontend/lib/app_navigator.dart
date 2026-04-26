// ============================================================
//  app_navigator.dart — root [NavigatorState] for tests / deep links
// ============================================================

import 'package:flutter/material.dart';

/// Key wired to [MaterialApp.navigatorKey] in [VetoApp].
/// Used by integration tests to [pushNamed] every route without UI scraping.
final GlobalKey<NavigatorState> vetoRootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'veto_root');
