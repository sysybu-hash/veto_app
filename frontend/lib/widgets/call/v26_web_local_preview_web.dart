import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

class V26WebLocalPreview extends StatefulWidget {
  const V26WebLocalPreview({
    super.key,
    required this.fallback,
  });

  final Widget fallback;

  @override
  State<V26WebLocalPreview> createState() => _V26WebLocalPreviewState();
}

class _V26WebLocalPreviewState extends State<V26WebLocalPreview> {
  late final String _viewType;
  web.HTMLVideoElement? _video;
  web.MediaStream? _stream;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'veto-local-pip-${DateTime.now().microsecondsSinceEpoch}';
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
      final mediaDevices = web.window.navigator.mediaDevices;
      final stream = await mediaDevices
          .getUserMedia(
            web.MediaStreamConstraints(
              audio: false.toJS,
              video: true.toJS,
            ),
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

  void _stop(web.MediaStream stream) {
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
      } catch (_) {}
    }
    final stream = _stream;
    if (stream != null) _stop(stream);
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
