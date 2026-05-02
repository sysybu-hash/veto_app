// ============================================================
//  MapsScreen — VETO 2026
//  Tokens-aligned. Embedded Google Maps (iframe / WebView).
//  Behaviour preserved: Geolocator + maps_embed_export.
// ============================================================
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../core/theme/veto_tokens_2026.dart';
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
        _webViewId = 'google-maps-embed-${hashCode}_${DateTime.now().millisecondsSinceEpoch}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isHe = Localizations.localeOf(context).languageCode == 'he';
    final title = isHe ? 'מפה' : 'Map';

    return Scaffold(
      backgroundColor: VetoTokens.paper,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(title, style: VetoTokens.titleLg),
      ),
      body: _error != null
          ? Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(20),
                decoration: VetoTokens.cardDecoration(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 28, color: VetoTokens.emerg),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center, style: VetoTokens.bodyMd.copyWith(color: VetoTokens.ink700)),
                  ],
                ),
              ),
            )
          : _embedUrl == null
              ? const Center(child: CircularProgressIndicator(color: VetoTokens.navy600))
              : buildPlatformMapsEmbed(kIsWeb ? _webViewId : null, _embedUrl!),
    );
  }
}
