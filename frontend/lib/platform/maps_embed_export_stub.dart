import 'package:flutter/material.dart';

import 'maps_embed_stub.dart';

/// Non-web / test VM: WebView-based embed (same as mobile).
Widget buildPlatformMapsEmbed(String? webViewId, String embedUrl) {
  return MapsEmbed(embedUrl: embedUrl);
}
