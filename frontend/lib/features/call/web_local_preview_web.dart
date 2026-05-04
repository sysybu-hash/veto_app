import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

class WebLocalPreview extends StatefulWidget {
  const WebLocalPreview({super.key, required this.fallback});

  final Widget fallback;

  @override
  State<WebLocalPreview> createState() => _WebLocalPreviewState();
}

class _WebLocalPreviewState extends State<WebLocalPreview> {
  late final String _viewType;
  web.HTMLVideoElement? _video;
  web.MediaStream? _stream;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'veto-call-local-pip-${DateTime.now().microsecondsSinceEpoch}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) {
      final video = web.HTMLVideoElement()
        ..autoplay = true
        ..muted = true
        ..playsInline = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.backgroundColor = '#13284A';
      _video = video;
      unawaited(_attachCamera(video));
      return video;
    });
  }

  Future<void> _attachCamera(web.HTMLVideoElement video) async {
    try {
      final stream = await web.window.navigator.mediaDevices
          .getUserMedia(
            web.MediaStreamConstraints(audio: false.toJS, video: true.toJS),
          )
          .toDart;
      if (!mounted) {
        _stop(stream);
        return;
      }
      _stream = stream;
      video.srcObject = stream;
      try {
        await video.play().toDart;
      } catch (_) {}
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _ready = false);
    }
  }

  void _stop(web.MediaStream? stream) {
    if (stream == null) return;
    for (final track in stream.getTracks().toDart) {
      try {
        track.stop();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    final video = _video;
    if (video != null) {
      try {
        video.pause();
        video.srcObject = null;
        video.removeAttribute('src');
      } catch (_) {}
    }
    _stop(_stream);
    _stream = null;
    _video = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.fallback,
        HtmlElementView(viewType: _viewType),
        if (!_ready) widget.fallback,
      ],
    );
  }
}
