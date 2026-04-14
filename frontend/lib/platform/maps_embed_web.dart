import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' hide Navigator, Text;

final _registered = <String>{};

void registerMapsEmbed(String viewId, String embedUrl) {
  if (_registered.contains(viewId)) return;
  _registered.add(viewId);
  ui_web.platformViewRegistry.registerViewFactory(
    viewId,
    (int _) {
      final iframe = HTMLIFrameElement()
        ..src = embedUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true;
      return iframe;
    },
  );
}

Widget buildMapsEmbed(String viewId, String embedUrl) {
  registerMapsEmbed(viewId, embedUrl);
  return HtmlElementView(viewType: viewId);
}
