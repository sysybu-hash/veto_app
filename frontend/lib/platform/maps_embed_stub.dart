import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Non-web: full-screen Google Maps embed inside the app WebView.
class MapsEmbed extends StatefulWidget {
  final String embedUrl;

  const MapsEmbed({super.key, required this.embedUrl});

  @override
  State<MapsEmbed> createState() => _MapsEmbedState();
}

class _MapsEmbedState extends State<MapsEmbed> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.embedUrl));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
