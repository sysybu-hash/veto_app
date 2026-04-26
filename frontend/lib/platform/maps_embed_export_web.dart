import 'package:flutter/material.dart';

import 'maps_embed_web.dart' as maps_web;

/// Flutter Web: iframe via [HtmlElementView].
Widget buildPlatformMapsEmbed(String? webViewId, String embedUrl) {
  return maps_web.buildMapsEmbed(webViewId!, embedUrl);
}
