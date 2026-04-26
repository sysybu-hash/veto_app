// ============================================================
//  MapsScreen — Google Maps embedded in-app (no Waze / no new tab)
//  Web: iframe. iOS/Android: WebView.
// ============================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../core/theme/veto_glass_system.dart';
import '../platform/maps_embed_export.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
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
    final hl = Localizations.localeOf(context).languageCode;

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
    final isHe = Localizations.localeOf(context).languageCode == 'he';
    final title = isHe ? 'מפת Google' : 'Google Maps';

    return Scaffold(
      backgroundColor: VetoGlassTokens.bgBase,
      appBar: AppBar(
        backgroundColor: const Color(0x18FFFFFF),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: VetoGlassTokens.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(title, style: const TextStyle(color: VetoGlassTokens.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: VetoGlassTokens.glassBorder),
        ),
      ),
      body: VetoGlassAuroraBackground(
        child: _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: VetoGlassTokens.textPrimary)),
                ),
              )
            : _embedUrl == null
                ? const Center(child: CircularProgressIndicator(color: VetoGlassTokens.neonCyan))
                : buildPlatformMapsEmbed(
                    kIsWeb ? _webViewId : null,
                    _embedUrl!,
                  ),
      ),
    );
  }
}
