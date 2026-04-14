import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_theme.dart';
import '../platform/waze_embed_stub.dart'
    if (dart.library.html) '../platform/waze_embed_web.dart' as waze_embed;

class WazeMapScreen extends StatefulWidget {
  final double? lat;
  final double? lon;
  final int? zoom;

  const WazeMapScreen({
    super.key,
    this.lat,
    this.lon,
    this.zoom,
  });

  @override
  State<WazeMapScreen> createState() => _WazeMapScreenState();
}

class _WazeMapScreenState extends State<WazeMapScreen> {
  final String _viewID = 'waze-map-view-v3';
  late final String _wazeUrl;

  @override
  void initState() {
    super.initState();
    final double lat = widget.lat ?? 32.0853;
    final double lon = widget.lon ?? 34.7818;
    final int zoom = widget.zoom ?? 14;
    _wazeUrl =
        'https://embed.waze.com/he/iframe?zoom=$zoom&lat=$lat&lon=$lon&pin=1&routing_mode=1';
    waze_embed.registerWazeEmbed(_viewID, _wazeUrl);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageController>().code;
    final isHe = lang == 'he';

    return Scaffold(
      backgroundColor: VetoPalette.bg,
      appBar: AppBar(
        title: Text(
          isHe ? 'מפת Waze' : 'Waze map',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: VetoPalette.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: VetoPalette.primary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(_wazeUrl),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 20),
            label: Text(
              isHe ? 'בחלון חדש' : 'Open',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: waze_embed.buildWazeEmbed(_viewID, _wazeUrl),
    );
  }
}
