import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' hide Navigator, Text;
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

    _wazeUrl = 'https://embed.waze.com/he/iframe?zoom=$zoom&lat=$lat&lon=$lon&pin=1&routing_mode=1';

    // Register the iframe factory for Flutter Web using ui_web
    ui_web.platformViewRegistry.registerViewFactory(
      _viewID,
      (int viewId) {
        final iframe = HTMLIFrameElement()
          ..src = _wazeUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allowFullscreen = true;
        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageController>().code;
    final isHe = lang == 'he';

    return Scaffold(
      appBar: AppBar(
        title: Text(isHe ? 'מפת Waze' : 'Waze Navigation'),
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
