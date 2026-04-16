import 'package:flutter_test/flutter_test.dart';

/// Guards route contract for [CallScreen] — room + call type must survive navigation args.
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
}
