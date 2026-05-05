// ============================================================
//  main.dart — VETO app entry + named routes
// ============================================================

import 'dart:async' show runZonedGuarded, unawaited;
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart' as provider;

import 'app_navigator.dart';
import 'config/app_config.dart';
import 'core/accessibility/accessibility_settings.dart';
import 'core/i18n/app_language.dart';
import 'core/theme/veto_theme.dart';
import 'core/theme/veto_2026.dart';
import 'screens/login_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/lawyer_dashboard.dart';
import 'screens/splash_screen.dart';
import 'screens/veto_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_settings_screen.dart';
import 'screens/wizard/onboarding_wizard_screen.dart';
import 'screens/wizard/wizard_shell_screen.dart';
import 'screens/files_vault_screen.dart';
import 'screens/legal_calendar_screen.dart';
import 'screens/legal_notebook_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/subscription_admin_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/admin/all_lawyers_screen.dart';
import 'screens/admin/all_users_screen.dart';
import 'screens/admin/pending_lawyers_screen.dart';
import 'screens/admin/emergency_logs_screen.dart';
import 'screens/lawyer_settings_screen.dart';
import 'screens/chat_screen.dart';
import 'features/call/call_screen.dart';
import 'screens/maps_screen.dart';
import 'screens/shared_vault_screen.dart';
import 'screens/citizen/citizen_contracts_screen.dart';
import 'screens/citizen/citizen_tasks_screen.dart';
import 'screens/citizen/citizen_contacts_screen.dart';
import 'screens/citizen/citizen_notifications_screen.dart';
import 'screens/citizen/citizen_reports_screen.dart';
import 'screens/citizen/citizen_tools_screen.dart';
import 'screens/citizen/security_center_screen.dart';
import 'screens/legal_document_screen.dart';
import 'navigation/call_route_args_observer.dart';
import 'services/socket_service.dart';
import 'services/vault_save_queue.dart';

void _installGlobalErrorLogging() {
  final previousHandler = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kIsWeb) {
      // Web release: debugPrint is a no-op; use print so DevTools shows the real error.
      // ignore: avoid_print
      print('[VETO][FlutterError] ${details.exceptionAsString()}');
      final s = details.stack;
      if (s != null) {
        // ignore: avoid_print
        print(s);
      }
    } else {
      debugPrint('[VETO][FlutterError] ${details.exceptionAsString()}');
      if (details.stack != null) {
        debugPrintStack(stackTrace: details.stack);
      }
    }
    previousHandler?.call(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (kIsWeb) {
      // ignore: avoid_print
      print('[VETO][async] $error');
      // ignore: avoid_print
      print(stack);
    } else {
      debugPrint('[VETO][async] $error');
      debugPrintStack(stackTrace: stack);
    }
    return false;
  };
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installGlobalErrorLogging();

  // 2026 design system uses Frank Ruhl Libre for headlines. Preload via
  // google_fonts so any TextStyle with `fontFamily: 'Frank Ruhl Libre'`
  // resolves once the font is cached. This is fire-and-forget so the
  // first frame is never blocked by font fetching.
  GoogleFonts.config.allowRuntimeFetching = true;
  unawaited(() async {
    try {
      // Warm the font cache — the returned TextStyle is discarded; this
      // is only for the side-effect of registering the family name.
      GoogleFonts.frankRuhlLibre();
      GoogleFonts.frankRuhlLibre(fontWeight: FontWeight.w700);
      GoogleFonts.frankRuhlLibre(fontWeight: FontWeight.w800);
      GoogleFonts.frankRuhlLibre(fontWeight: FontWeight.w900);
    } catch (_) {}
  }());

  // Mobile web: optional frame timing log (build vs raster).
  if (kIsWeb) {
    // #region agent log (frame timings)
    // Runtime evidence for "silent freeze": logs slow frames to console (no PII).
    // This lets us tell if freezes are build-bound vs raster-bound.
    SchedulerBinding.instance.addTimingsCallback((List<FrameTiming> timings) {
      for (final t in timings) {
        final buildMs = t.buildDuration.inMilliseconds;
        final rasterMs = t.rasterDuration.inMilliseconds;
        final totalMs = buildMs + rasterMs;
        if (totalMs >= 40) {
          // ignore: avoid_print
          print('[VETO][perf] slow_frame build=${buildMs}ms raster=${rasterMs}ms total=${totalMs}ms');
        }
      }
    });
    // #endregion agent log (frame timings)
  }

  // Global Error Boundary to prevent Red Screen of Death
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: V26.paper,
      child: Container(
        color: V26.paper,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFD6243A), size: 56),
            const SizedBox(height: 24),
            const Text(
              'משהו השתבש',
              style: TextStyle(
                fontFamily: 'Frank Ruhl Libre',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: V26.ink900,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'אנחנו עובדים על זה. נסה לרענן את העמוד.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Heebo',
                fontSize: 14,
                color: V26.ink500,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              details.exceptionAsString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Heebo',
                color: V26.ink300,
                fontSize: 11,
              ),
              maxLines: kIsWeb ? 14 : 5,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  };

  final languageController = AppLanguageController();
  final accessibilitySettings = AccessibilitySettings();
  // Load language + a11y — do *not* block the first frame on /health (can hang ~10s if API/tunnel is down).
  await Future.wait([
    languageController.load(),
    accessibilitySettings.hydrate(),
  ]);
  unawaited(_warmUpBackend());
  runZonedGuarded(
    () {
      runApp(
        provider.MultiProvider(
          providers: [
            provider.ChangeNotifierProvider.value(value: languageController),
            provider.ChangeNotifierProvider.value(value: accessibilitySettings),
            provider.ChangeNotifierProvider<VaultSaveQueue>(
              create: (_) => VaultSaveQueue(),
            ),
            provider.Provider<SocketService>(
              create: (_) => SocketService(),
              lazy: true,
            ),
          ],
          child: const VetoApp(),
        ),
      );
    },
    (Object error, StackTrace stack) {
      if (kIsWeb) {
        // ignore: avoid_print
        print('[VETO][zone] $error');
        // ignore: avoid_print
        print(stack);
      } else {
        debugPrint('[VETO][zone] $error\n$stack');
      }
    },
  );
}

/// Fire a lightweight /health GET to wake Render (or verify localhost). Runs in the
/// background so startup never waits on a dead tunnel or slow network.
/// Uses [AppConfig.httpGetHeaders] so localtunnel requests are not stuck on the reminder page.
Future<void> _warmUpBackend() async {
  try {
    await http
        .get(
          Uri.parse(AppConfig.healthCheckUrl),
          headers: AppConfig.httpGetHeaders,
        )
        .timeout(const Duration(seconds: 3));
  } catch (_) {}
}

/// Route table for [VetoApp] and tests (single source of truth).
final Map<String, WidgetBuilder> vetoAppRoutes = <String, WidgetBuilder>{
  '/': (_) => const SplashScreen(),
  '/landing': (_) => const LandingScreen(),
  '/login': (_) => const LoginScreen(),
  '/wizard_home': (_) => const OnboardingWizardScreen(),
  '/emergency_wizard': (_) => const WizardShellScreen(),
  '/veto_screen': (ctx) {
    final args = ModalRoute.of(ctx)?.settings.arguments;
    final wizard = args is Map && args['wizard'] == true;
    return VetoScreen(initialShowWizard: wizard);
  },
  '/lawyer_dashboard': (_) => const LawyerDashboard(),
  '/profile': (_) => const ProfileScreen(),
  '/admin_settings': (_) => const AdminSettingsScreen(),
  '/files_vault': (_) => const FilesVaultScreen(),
  '/legal_calendar': (_) => const LegalCalendarScreen(),
  '/legal_notebook': (_) => const LegalNotebookScreen(),
  '/admin_dashboard': (_) => const AdminDashboard(),
  '/admin_subscriptions': (_) => const SubscriptionAdminScreen(),
  '/settings': (_) => const SettingsScreen(),
  '/admin_users': (_) => const AllUsersScreen(),
  '/admin_lawyers': (_) => const AllLawyersScreen(),
  '/admin_pending': (_) => const PendingLawyersScreen(),
  '/admin_logs': (_) => const EmergencyLogsScreen(),
  '/lawyer_settings': (_) => const LawyerSettingsScreen(),
  '/chat': (_) => const ChatScreen(),
  '/call': (_) => const CallScreen(),
  '/maps': (_) => const MapsScreen(),
  '/shared_vault': (_) => const SharedVaultScreen(),
  '/privacy': (_) => const LegalDocumentScreen(kind: LegalDocKind.privacy),
  '/terms': (_) => const LegalDocumentScreen(kind: LegalDocKind.terms),
  '/citizen_contracts': (_) => const CitizenContractsScreen(),
  '/citizen_tasks': (_) => const CitizenTasksScreen(),
  '/citizen_contacts': (_) => const CitizenContactsScreen(),
  '/citizen_notifications': (_) => const CitizenNotificationsScreen(),
  '/citizen_reports': (_) => const CitizenReportsScreen(),
  '/citizen_tools': (_) => const CitizenToolsScreen(),
  '/security_center': (_) => const SecurityCenterScreen(),
};

class VetoApp extends StatelessWidget {
  /// Production uses `'/'` (splash). Tests may start at `/landing` to avoid splash timers under fake async.
  final String initialRoute;

  const VetoApp({super.key, this.initialRoute = '/'});

  @override
  Widget build(BuildContext context) {
    final language = provider.Provider.of<AppLanguageController>(context);
    final a11y = provider.Provider.of<AccessibilitySettings>(context);
    final baseTheme = VetoTheme.luxury2026();

    return MaterialApp(
      navigatorKey: vetoRootNavigatorKey,
      navigatorObservers: <NavigatorObserver>[CallRouteArgsObserver()],
      debugShowCheckedModeBanner: false,
      title: 'VETO',
      theme: a11y.mergeTheme(baseTheme),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
        },
      ),
      locale: language.locale,
      supportedLocales: const [Locale('he'), Locale('en'), Locale('ru')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final navigatorChild = child ?? const SizedBox.shrink();
        final mq = MediaQuery.of(context);
        // Respect OS font scaling, then apply in-app size steps.
        final os = mq.textScaler.scale(1.0);
        final combined = (os * a11y.textScale).clamp(0.75, 2.25);
        // Floating accessibility FAB + bottom sheet removed: on Web it could leave a
        // full-screen modal barrier with no usable sheet. Preferences still load via
        // [AccessibilitySettings] (theme + text scaler). Re-introduce as a dedicated
        // route (/accessibility) when needed — do not wrap the navigator in a Stack FAB.
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(combined),
            boldText: a11y.boldBody,
            highContrast: a11y.highContrast,
            disableAnimations: a11y.reduceMotion,
          ),
          child: navigatorChild,
        );
      },
      initialRoute: initialRoute,
      routes: vetoAppRoutes,
    );
  }
}
