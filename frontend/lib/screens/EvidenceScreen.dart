// ============================================================
//  EvidenceScreen.dart — Evidence Collection Module
//  VETO Legal Emergency App
//  Camera preview → One-tap capture → GPS metadata → Upload
// ============================================================

import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../services/upload_service.dart';

// ── Brand palette (shared across the app) ─────────────────
class _C {
  static const bg        = Color(0xFF001F3F);
  static const silver    = Color(0xFFC0C2C9);
  static const silverDim = Color(0xFF8A8C93);
  static const white     = Color(0xFFFFFFFF);
  static const accept    = Color(0xFF2ECC71);
  static const cardBg    = Color(0xFF012A52);
  static const uploading = Color(0xFFC0C2C9); // silver progress bar
}

// ── i18n strings ──────────────────────────────────────────
enum _Lang { en, he, ar }

class _L {
  static const Map<_Lang, Map<String, String>> _d = {
    _Lang.en: {
      'capture':    'CAPTURE',
      'uploading':  'Uploading Evidence...',
      'saved':      'Evidence Saved',
      'error':      'Upload Failed',
      'evidence':   'EVIDENCE',
      'noGps':      'Acquiring GPS...',
      'camError':   'Camera unavailable',
      'empty':      'No evidence captured yet',
    },
    _Lang.he: {
      'capture':    'צלם',
      'uploading':  'מעלה ראיות...',
      'saved':      'ראיה נשמרה',
      'error':      'העלאה נכשלה',
      'evidence':   'ראיות',
      'noGps':      'מאתר GPS...',
      'camError':   'המצלמה אינה זמינה',
      'empty':      'טרם נלכדו ראיות',
    },
    _Lang.ar: {
      'capture':    'التقط',
      'uploading':  'جارٍ رفع الأدلة...',
      'saved':      'تم حفظ الدليل',
      'error':      'فشل الرفع',
      'evidence':   'الأدلة',
      'noGps':      'جارٍ تحديد الموقع...',
      'camError':   'الكاميرا غير متاحة',
      'empty':      'لا توجد أدلة حتى الآن',
    },
  };

  static String get(_Lang lang, String key) => _d[lang]?[key] ?? key;

  static TextDirection dir(_Lang lang) =>
      lang == _Lang.en ? TextDirection.ltr : TextDirection.rtl;
}

// ── Evidence item model ────────────────────────────────────
class _EvidenceItem {
  final File   file;
  final String cloudUrl;
  final double lat;
  final double lng;
  final DateTime capturedAt;
  _EvidenceItem({
    required this.file,
    required this.cloudUrl,
    required this.lat,
    required this.lng,
    required this.capturedAt,
  });
}

// ══════════════════════════════════════════════════════════════
//  EvidenceScreen
// ══════════════════════════════════════════════════════════════
class EvidenceScreen extends StatefulWidget {
  final String eventId;
  final String token;
  final _Lang  language;

  const EvidenceScreen({
    super.key,
    required this.eventId,
    required this.token,
    this.language = _Lang.en,
  });

  @override
  State<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends State<EvidenceScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {

  // ── Camera ─────────────────────────────────────────────────
  List<CameraDescription> _cameras     = [];
  CameraController?        _camCtrl;
  bool                     _camReady   = false;
  bool                     _camError   = false;
  int                      _camIndex   = 0; // 0 = rear

  // ── GPS ────────────────────────────────────────────────────
  Position? _position;
  bool      _gpsReady = false;

  // ── Upload state ───────────────────────────────────────────
  bool   _uploading    = false;
  double _uploadProg   = 0.0;
  String _uploadStatus = ''; // 'saved' | 'error' | ''
  Timer? _statusTimer;

  // ── Capture animation ──────────────────────────────────────
  late final AnimationController _flashCtrl;
  late Animation<double>         _flashOpacity;
  bool _capturing = false;

  // ── Evidence gallery ───────────────────────────────────────
  final List<_EvidenceItem> _gallery = [];

  // ── Upload service ─────────────────────────────────────────
  final _uploader = UploadService();

  _Lang get _lang => widget.language;
  String _t(String k) => _L.get(_lang, k);
  TextDirection get _dir => _L.dir(_lang);

  // ══════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ══════════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _buildFlashAnimation();
    _initCamera();
    _initGPS();
  }

  void _buildFlashAnimation() {
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _flashOpacity = Tween<double>(begin: 0, end: 0.75).animate(
      CurvedAnimation(parent: _flashCtrl, curve: Curves.easeIn),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_camCtrl == null || !_camCtrl!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _camCtrl!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCameraController(_cameras[_camIndex]);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camCtrl?.dispose();
    _flashCtrl.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════
  //  INIT
  // ══════════════════════════════════════════════════════════
  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _camError = true);
        return;
      }
      await _initCameraController(_cameras[_camIndex]);
    } catch (_) {
      setState(() => _camError = true);
    }
  }

  Future<void> _initCameraController(CameraDescription cam) async {
    final ctrl = CameraController(
      cam,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _camCtrl = ctrl;
    try {
      await ctrl.initialize();
      if (mounted) setState(() => _camReady = true);
    } catch (_) {
      if (mounted) setState(() => _camError = true);
    }
  }

  Future<void> _initGPS() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return;
    }
    if (perm == LocationPermission.deniedForever) return;

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) setState(() { _position = pos; _gpsReady = true; });
    } catch (_) {/* GPS unavailable – proceed without */ }
  }

  // ══════════════════════════════════════════════════════════
  //  CAPTURE
  // ══════════════════════════════════════════════════════════
  Future<void> _capture() async {
    if (_camCtrl == null ||
        !_camCtrl!.value.isInitialized ||
        _capturing ||
        _uploading) return;

    HapticFeedback.mediumImpact();
    setState(() => _capturing = true);

    // White flash
    _flashCtrl.forward().then((_) => _flashCtrl.reverse());

    try {
      final xFile = await _camCtrl!.takePicture();
      final file  = File(xFile.path);

      // Refresh GPS if available
      if (_gpsReady) {
        try {
          _position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 3),
          );
        } catch (_) { /* keep last known */ }
      }

      final lat = _position?.latitude  ?? 0.0;
      final lng = _position?.longitude ?? 0.0;

      await _uploadFile(file: file, type: 'photo', lat: lat, lng: lng);
    } catch (e) {
      _setStatus('error');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  // ══════════════════════════════════════════════════════════
  //  UPLOAD
  // ══════════════════════════════════════════════════════════
  Future<void> _uploadFile({
    required File   file,
    required String type,
    required double lat,
    required double lng,
  }) async {
    setState(() {
      _uploading    = true;
      _uploadProg   = 0.0;
      _uploadStatus = '';
    });

    final result = await _uploader.uploadEvidence(
      file:     file,
      type:     type,
      eventId:  widget.eventId,
      lat:      lat,
      lng:      lng,
      token:    widget.token,
      onProgress: (p) {
        if (mounted) setState(() => _uploadProg = p);
      },
    );

    if (mounted) {
      if (result.success) {
        _gallery.add(_EvidenceItem(
          file:       file,
          cloudUrl:   result.cloudUrl ?? '',
          lat:        lat,
          lng:        lng,
          capturedAt: DateTime.now(),
        ));
        _setStatus('saved');
      } else {
        _setStatus('error');
      }
      setState(() { _uploading = false; _uploadProg = 0.0; });
    }
  }

  void _setStatus(String status) {
    setState(() => _uploadStatus = status);
    _statusTimer?.cancel();
    _statusTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _uploadStatus = '');
    });
  }

  // ── Flip camera ────────────────────────────────────────────
  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    setState(() { _camReady = false; _camIndex = (_camIndex + 1) % _cameras.length; });
    await _initCameraController(_cameras[_camIndex]);
  }

  // ══════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _dir,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── 1. Camera preview (full screen) ─────────────
            _buildCameraLayer(),

            // ── 2. Top HUD (status + GPS) ────────────────────
            Positioned(top: 0, left: 0, right: 0, child: _buildTopHUD()),

            // ── 3. Upload progress bar ───────────────────────
            if (_uploading)
              Positioned(
                top: MediaQuery.of(context).padding.top + 56,
                left: 0, right: 0,
                child: _buildProgressBar(),
              ),

            // ── 4. Status toast ──────────────────────────────
            if (_uploadStatus.isNotEmpty)
              Positioned(
                top: MediaQuery.of(context).padding.top + 68,
                left: 0, right: 0,
                child: _buildStatusToast(),
              ),

            // ── 5. Camera flash overlay ───────────────────────
            AnimatedBuilder(
              animation: _flashOpacity,
              builder: (_, __) => IgnorePointer(
                child: Container(
                  color: Colors.white.withOpacity(_flashOpacity.value),
                ),
              ),
            ),

            // ── 6. Bottom controls ───────────────────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _buildBottomControls(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Camera layer ───────────────────────────────────────────
  Widget _buildCameraLayer() {
    if (_camError) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.videocam_off_outlined, color: _C.silverDim, size: 48),
            const SizedBox(height: 16),
            Text(_t('camError'),
                style: const TextStyle(color: _C.silverDim, fontSize: 14)),
          ]),
        ),
      );
    }
    if (!_camReady || _camCtrl == null) {
      return const Center(
        child: CircularProgressIndicator(
            strokeWidth: 1.5, color: _C.silverDim),
      );
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width:  _camCtrl!.value.previewSize!.height,
          height: _camCtrl!.value.previewSize!.width,
          child:  CameraPreview(_camCtrl!),
        ),
      ),
    );
  }

  // ── Top HUD ────────────────────────────────────────────────
  Widget _buildTopHUD() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end:   Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.75), Colors.transparent],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              // Back
              _HUDButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),

              const Spacer(),

              // VETO badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _C.bg.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _C.silver.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _C.accept,
                        boxShadow: [
                          BoxShadow(color: _C.accept.withOpacity(0.7), blurRadius: 4)
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('VETO  EVIDENCE',
                        style: TextStyle(
                            color: _C.silver,
                            fontSize: 10,
                            letterSpacing: 2.0)),
                  ],
                ),
              ),

              const Spacer(),

              // GPS status
              _HUDButton(
                icon: _gpsReady
                    ? Icons.gps_fixed_rounded
                    : Icons.gps_not_fixed_rounded,
                color: _gpsReady ? _C.accept : _C.silverDim,
                onTap: _initGPS,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Upload progress bar ────────────────────────────────────
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('uploading'),
            style: const TextStyle(
              color: _C.silver,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _uploadProg > 0 ? _uploadProg : null,
              backgroundColor: _C.silver.withOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation(_C.uploading),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Status toast ───────────────────────────────────────────
  Widget _buildStatusToast() {
    final isSaved = _uploadStatus == 'saved';
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: (isSaved ? _C.accept : Colors.redAccent).withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (isSaved ? _C.accept : Colors.redAccent).withOpacity(0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSaved ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              color: isSaved ? _C.accept : Colors.redAccent,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              _t(isSaved ? 'saved' : 'error'),
              style: TextStyle(
                color: isSaved ? _C.accept : Colors.redAccent,
                fontSize: 11,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom controls (capture + gallery) ───────────────────
  Widget _buildBottomControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end:   Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.88), Colors.transparent],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gallery row
              _buildGalleryRow(),
              const SizedBox(height: 24),

              // Capture row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // GPS coordinates
                  SizedBox(
                    width: 80,
                    child: _gpsReady && _position != null
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_position!.latitude.toStringAsFixed(4)}',
                                style: const TextStyle(
                                    color: _C.silverDim, fontSize: 10),
                              ),
                              Text(
                                '${_position!.longitude.toStringAsFixed(4)}',
                                style: const TextStyle(
                                    color: _C.silverDim, fontSize: 10),
                              ),
                            ],
                          )
                        : Text(
                            _t('noGps'),
                            style: const TextStyle(
                                color: _C.silverDim, fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                  ),

                  // Shutter button
                  _ShutterButton(
                    isCapturing: _capturing,
                    isUploading: _uploading,
                    onTap:       _capture,
                    label:       _t('capture'),
                  ),

                  // Flip camera
                  SizedBox(
                    width: 80,
                    child: Center(
                      child: _HUDButton(
                        icon: Icons.flip_camera_ios_outlined,
                        onTap: _flipCamera,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Gallery row ────────────────────────────────────────────
  Widget _buildGalleryRow() {
    if (_gallery.isEmpty) {
      return Row(
        children: [
          Text(
            _t('empty'),
            style: TextStyle(
              color: _C.silverDim.withOpacity(0.4),
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_t('evidence')}  (${_gallery.length})',
          style: const TextStyle(
            color: _C.silverDim,
            fontSize: 10,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 64,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true,     // newest on left
            itemCount: _gallery.length,
            itemBuilder: (ctx, i) => _GalleryThumb(item: _gallery[i]),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Reusable Sub-Widgets
// ══════════════════════════════════════════════════════════════

// ── Shutter Button ─────────────────────────────────────────
class _ShutterButton extends StatelessWidget {
  final bool     isCapturing;
  final bool     isUploading;
  final VoidCallback onTap;
  final String   label;

  const _ShutterButton({
    required this.isCapturing,
    required this.isUploading,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final bool locked = isCapturing || isUploading;

    return GestureDetector(
      onTap: locked ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width:  84,
            height: 84,
            decoration: BoxDecoration(
              shape:  BoxShape.circle,
              color:  locked
                  ? _C.silver.withOpacity(0.08)
                  : _C.silver.withOpacity(0.15),
              border: Border.all(
                color: locked ? _C.silverDim : _C.silver,
                width: locked ? 1.5 : 2.5,
              ),
              boxShadow: locked
                  ? []
                  : [
                      BoxShadow(
                        color: _C.silver.withOpacity(0.25),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width:  locked ? 28 : 56,
                height: locked ? 28 : 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: locked
                      ? _C.silverDim.withOpacity(0.3)
                      : _C.silver,
                ),
                child: locked
                    ? const Center(
                        child: SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: _C.white,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: locked ? _C.silverDim : _C.silver,
              fontSize: 10,
              letterSpacing: 2.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── HUD icon button ────────────────────────────────────────
class _HUDButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const _HUDButton({
    required this.icon,
    this.onTap,
    this.color = _C.silver,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.35),
          border: Border.all(color: _C.silver.withOpacity(0.2)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

// ── Gallery thumbnail ──────────────────────────────────────
class _GalleryThumb extends StatelessWidget {
  final _EvidenceItem item;
  const _GalleryThumb({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.silver.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(item.file, fit: BoxFit.cover),
            // GPS dot overlay
            Positioned(
              bottom: 4, right: 4,
              child: Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _C.accept,
                  border: Border.all(color: Colors.black, width: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
