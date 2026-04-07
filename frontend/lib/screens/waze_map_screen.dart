import 'dart:async';
import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import '../core/theme/veto_theme.dart';
import '../core/i18n/app_language.dart';
import 'package:provider/provider.dart';

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
  final String _viewID = 'waze-map-view-v2';
  late String _wazeUrl;

  @override
  void initState() {
    super.initState();
    
    // Default to Tel Aviv center if not provided
    final double lat = widget.lat ?? 32.0853;
    final double lon = widget.lon ?? 34.7818;
    final int zoom = widget.zoom ?? 14;

    _wazeUrl = 'https://embed.waze.com/he/iframe?zoom=$zoom&lat=$lat&lon=$lon&pin=1&mode=livemap';

    // Register the iframe factory for Flutter Web using ui_web
    ui_web.platformViewRegistry.registerViewFactory(
      _viewID,
      (int viewId) => html.IFrameElement()
        ..src = _wazeUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true,
    );
  }

  void _openWazeApp() {
    final double lat = widget.lat ?? 32.0853;
    final double lon = widget.lon ?? 34.7818;
    // Waze deep link
    final url = 'https://waze.com/ul?ll=$lat,$lon&navigate=yes';
    if (Theme.of(context).platform == TargetPlatform.iOS || Theme.of(context).platform == TargetPlatform.android) {
        // Run mobile native intent
        html.window.open(url, '_top');
    } else {
        // Desktop Web: do not throw to a new tab. Update iframe if possible, or show a dialog.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
               context.read<AppLanguageController>().code == 'he' 
                 ? 'ניווט בזמן אמת נתמך במכשירים ניידים בלבד דרך אפליקציית Waze. עקוב במפה זו.'
                 : 'Real-time navigation is only supported natively on Mobile via the Waze app.'
            ),
            backgroundColor: VetoPalette.primary,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageController>().code;
    final isHe = lang == 'he';

    return Scaffold(
      appBar: AppBar(
        title: Text(isHe ? 'ניווט Waze' : 'Waze Navigation'),
        backgroundColor: VetoPalette.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: VetoPalette.primary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [],
      ),
      body: Stack(
        children: [
          HtmlElementView(viewType: _viewID),
        ],
      ),
    );
  }
}
