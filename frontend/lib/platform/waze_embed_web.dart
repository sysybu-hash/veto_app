import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' hide Navigator, Text;

final _registered = <String>{};

void registerWazeEmbed(String viewId, String wazeUrl) {
  if (_registered.contains(viewId)) return;
  _registered.add(viewId);
  ui_web.platformViewRegistry.registerViewFactory(
    viewId,
    (int _) {
      final iframe = HTMLIFrameElement()
        ..src = wazeUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true;
      return iframe;
    },
  );
}

Widget buildWazeEmbed(String viewId, String _) {
  return HtmlElementView(viewType: viewId);
}
