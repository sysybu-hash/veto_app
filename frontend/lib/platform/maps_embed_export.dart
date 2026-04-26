// ============================================================
//  Conditional export — avoids pulling package:web on VM/tests.
// ============================================================

export 'maps_embed_export_stub.dart'
    if (dart.library.html) 'maps_embed_export_web.dart';
