// ============================================================
//  MapsScreen — Google Maps embedded in-app (no Waze / no new tab)
//  Web: iframe. iOS/Android: WebView.
// ============================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_2026.dart';
import '../core/theme/veto_mockup_tokens.dart';
import '../services/auth_service.dart';
import '../platform/maps_embed_export.dart';
import '../widgets/citizen_mockup_shell.dart';
import '../widgets/app_language_menu.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final _auth = AuthService();
  late final Future<String?> _citizenChromeFuture = _auth.getStoredRole();

  String? _embedUrl;
  String? _webViewId;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initMap());
  }

  Future<void> _initMap() async {
    if (!mounted) return;
    // Use app language (he/en/ru) instead of OS locale so Russian users
    // get Russian labels on the embed.
    final hl = context.read<AppLanguageController>().code;

    double lat = 32.0853;
    double lng = 34.7818;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final la = args['lat'];
      final ln = args['lng'];
      if (la is num) lat = la.toDouble();
      if (ln is num) lng = ln.toDouble();
    } else {
      try {
        final p = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
        lat = p.latitude;
        lng = p.longitude;
      } catch (_) {}
    }

    final url =
        'https://www.google.com/maps?q=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}&z=16&output=embed&hl=$hl';

    if (!mounted) return;
    setState(() {
      _embedUrl = url;
      if (kIsWeb) {
        _webViewId =
            'google-maps-embed-${hashCode}_${DateTime.now().millisecondsSinceEpoch}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final title = code == 'he'
        ? 'מפת Google'
        : (code == 'ru' ? 'Карты Google' : 'Google Maps');
    final isWide =
        MediaQuery.sizeOf(context).width >= V26AppShell.desktopBreakpoint;

    final mapChild = _error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: V26.sans,
                  color: V26.ink700,
                ),
              ),
            ),
          )
        : _embedUrl == null
            ? const Center(
                child: CircularProgressIndicator(color: V26.navy600))
            : buildPlatformMapsEmbed(
                kIsWeb ? _webViewId : null,
                _embedUrl!,
              );

    return FutureBuilder<String?>(
      future: _citizenChromeFuture,
      builder: (context, snap) {
        final citizen = snap.data == 'user';
        if (citizen) {
          return Directionality(
            textDirection: AppLanguage.directionOf(code),
            child: CitizenMockupShell(
              currentRoute: '/maps',
              mobileNavIndex: citizenMobileNavIndexForRoute('/maps'),
              desktopTrailing: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Center(child: AppLanguageMenu(compact: true)),
                ),
              ],
              mobileAppBar: AppBar(
                backgroundColor: VetoMockup.surfaceCard,
                elevation: 0,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: VetoMockup.ink, size: 20),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                title: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: V26.serif,
                    color: VetoMockup.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.2,
                  ),
                ),
                centerTitle: true,
                bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(1),
                  child: Divider(height: 1, color: VetoMockup.hairline),
                ),
              ),
              child: mapChild,
            ),
          );
        }
        return Directionality(
          textDirection: AppLanguage.directionOf(code),
          child: V26AppShell(
            destinations: isWide
                ? V26CitizenNav.destinations(code)
                : V26CitizenNav.bottomDestinations(code),
            currentIndex: isWide ? 5 /* מפה */ : 3 /* Map in bottom */,
            onDestinationSelected: (i) {
              final routes =
                  isWide ? V26CitizenNav.routes : V26CitizenNav.bottomRoutes;
              V26CitizenNav.go(context, routes[i], current: '/maps');
            },
            desktopStatusText: title,
            desktopTrailing: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Center(child: AppLanguageMenu(compact: true)),
              ),
            ],
            mobileAppBar: AppBar(
              backgroundColor: V26.surface,
              elevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: V26.ink900, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: Text(
                title,
                style: const TextStyle(
                  fontFamily: V26.serif,
                  color: V26.ink900,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: -0.2,
                ),
              ),
              centerTitle: true,
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(height: 1, color: V26.hairline),
              ),
            ),
            child: mapChild,
          ),
        );
      },
    );
  }
}
