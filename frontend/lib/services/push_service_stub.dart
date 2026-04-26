// ============================================================
//  push_service_stub.dart — VM / mobile: no browser push API
// ============================================================

class PushService {
  static final PushService _i = PushService._();
  factory PushService() => _i;
  PushService._();

  Future<void> registerLawyerPush() async {}
}
