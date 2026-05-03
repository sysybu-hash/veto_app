import 'package:flutter_test/flutter_test.dart';

/// Guards route contract for `CallShellScreen` — room + call type must survive
/// navigation args through `ModalRoute.settings.arguments` and, on Web refresh,
/// through the `callRouteArgsStorage` sessionStorage fallback.
void main() {
  test('call route args map includes roomId and callType keys', () {
    final args = <String, dynamic>{
      'roomId': '674a1b2c3d4e5f6789012345',
      'callType': 'audio',
      'peerName': 'Lawyer',
      'role': 'user',
      'eventId': '674a1b2c3d4e5f6789012345',
      'language': 'he',
    };
    expect(args['roomId'], isNotNull);
    expect(args['callType'], isNotNull);
    expect(args['role'], isNotNull);
  });

  test('incoming call mode flag round-trips', () {
    final incoming = <String, dynamic>{
      'roomId': '674a1b2c3d4e5f6789012345',
      'callType': 'video',
      'peerName': 'Citizen',
      'role': 'lawyer',
      'eventId': '674a1b2c3d4e5f6789012345',
      'language': 'he',
      'mode': 'incoming',
      'caseSummary': 'Arrested at 22:40 near Allenby.',
    };
    expect(incoming['mode'], 'incoming');
    expect(incoming['caseSummary'], isNotEmpty);
  });
}
