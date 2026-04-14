// ============================================================
//  MapsScreen — Google Maps embedded in-app (no Waze / no new tab)
//  Web: iframe. iOS/Android: WebView.
// ============================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../core/theme/veto_theme.dart';
import '../platform/maps_embed_stub.dart';
import '../platform/maps_embed_web.dart' as maps_web;

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
      backgroundColor: VetoPalette.bg,
      appBar: AppBar(
        backgroundColor: VetoPalette.darkBg,
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: VetoPalette.text)),
              ),
            )
          : _embedUrl == null
              ? const Center(child: CircularProgressIndicator())
              : kIsWeb
                  ? maps_web.buildMapsEmbed(_webViewId!, _embedUrl!)
                  : MapsEmbed(embedUrl: _embedUrl!),
    );
  }
}
